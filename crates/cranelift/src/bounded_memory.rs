//! Reuse a checked Wasm32 memory span as a native addressing base.
//!
//! A bulk-memory bounds check such as `memory.fill(base, ..., len)` proves
//! that `[base, base + len)` is in bounds. Later scalar accesses into that
//! same span are normally formed as
//!
//! ```text
//! heap_base + uextend.i64(iadd.i32(base, byte_offset))
//! ```
//!
//! Keeping the addition in `i32` is required in the general case because Wasm
//! addresses wrap. Once `byte_offset + access_size <= len` is proven, however,
//! the earlier whole-span check also proves that the addition cannot wrap. We
//! can then reassociate it as
//!
//! ```text
//! (heap_base + uextend.i64(base)) + uextend.i64(byte_offset)
//! ```
//!
//! This is particularly useful on AArch64, where a scaled offset can fold into
//! the load/store addressing mode.

use cranelift_codegen::cursor::{Cursor, FuncCursor};
use cranelift_codegen::dominator_tree::DominatorTree;
use cranelift_codegen::flowgraph::ControlFlowGraph;
use cranelift_codegen::ir::condcodes::{CondCode, IntCC};
use cranelift_codegen::ir::{self, Block, BlockArg, Function, Inst, InstBuilder, Opcode, Value};
use std::collections::{HashMap, HashSet};
use wasmtime_environ::MemoryIndex;

#[derive(Clone, Copy)]
struct CheckedSpan {
    memory: MemoryIndex,
    wasm_base: Value,
    native_base: Value,
    len: u32,
    spectre_mask: bool,
}

#[derive(Clone, Copy)]
struct MemoryAccess {
    memory: MemoryIndex,
    wasm_addr: Value,
    native_addr: Value,
    static_offset: u32,
    access_size: u8,
}

/// Translation-time information used by [`State::optimize`].
#[derive(Default)]
pub(crate) struct State {
    spans: Vec<CheckedSpan>,
    accesses: Vec<MemoryAccess>,
}

impl State {
    pub(crate) fn record_span(
        &mut self,
        memory: MemoryIndex,
        wasm_base: Value,
        native_base: Value,
        len: u32,
        spectre_mask: bool,
    ) {
        if len != 0 {
            self.spans.push(CheckedSpan {
                memory,
                wasm_base,
                native_base,
                len,
                spectre_mask,
            });
        }
    }

    pub(crate) fn record_access(
        &mut self,
        memory: MemoryIndex,
        wasm_addr: Value,
        native_addr: Value,
        static_offset: u32,
        access_size: u8,
    ) {
        self.accesses.push(MemoryAccess {
            memory,
            wasm_addr,
            native_addr,
            static_offset,
            access_size,
        });
    }

    /// Reassociate accesses that are proven to remain within an earlier,
    /// dominating checked span.
    pub(crate) fn optimize(self, func: &mut Function) -> usize {
        if self.spans.is_empty() || self.accesses.is_empty() {
            return 0;
        }

        let cfg = ControlFlowGraph::with_function(func);
        let domtree = DominatorTree::with_function(func, &cfg);
        let mut rewrites = Vec::new();
        let mut rewritten_insts = HashSet::new();

        {
            let mut ranges = RangeAnalysis::new(func, &cfg, &domtree);
            for access in self.accesses {
                let Some(native_addr_inst) = func.dfg.value_def(access.native_addr).inst() else {
                    continue;
                };
                let Some(access_block) = func.layout.inst_block(native_addr_inst) else {
                    continue;
                };

                for span in self.spans.iter().copied() {
                    if span.memory != access.memory {
                        continue;
                    }
                    let Some(native_base_inst) = func.dfg.value_def(span.native_base).inst() else {
                        continue;
                    };
                    if !domtree.dominates(native_base_inst, native_addr_inst, &func.layout) {
                        continue;
                    }

                    let Some(dynamic_offset) =
                        offset_from_base(func, access.wasm_addr, span.wasm_base)
                    else {
                        continue;
                    };
                    let dynamic_max = dynamic_offset
                        .map(|offset| ranges.range_at(offset, access_block).max)
                        .unwrap_or(0);
                    let end = dynamic_max
                        .checked_add(u64::from(access.static_offset))
                        .and_then(|n| n.checked_add(u64::from(access.access_size)));
                    if !end.is_some_and(|end| end <= u64::from(span.len)) {
                        continue;
                    }

                    // In Spectre-mitigated configurations, control-flow range
                    // facts cannot constrain speculative execution. Only use
                    // this transform when a cheap mask can keep speculative
                    // offsets inside the checked span as well.
                    let mask = if span.spectre_mask && dynamic_offset.is_some() {
                        let Some(available) = span
                            .len
                            .checked_sub(access.static_offset)
                            .and_then(|n| n.checked_sub(u32::from(access.access_size)))
                        else {
                            continue;
                        };
                        let mask_unit = dynamic_offset
                            .and_then(|offset| scaled_offset(func, offset))
                            .map_or(available, |(_, shift)| available >> shift);
                        if mask_unit & mask_unit.wrapping_add(1) != 0 {
                            continue;
                        }
                        Some(available)
                    } else {
                        None
                    };

                    if !rewritten_insts.insert(native_addr_inst) {
                        break;
                    }
                    rewrites.push(Rewrite {
                        old_addr_inst: native_addr_inst,
                        native_base: span.native_base,
                        dynamic_offset,
                        static_offset: access.static_offset,
                        mask,
                    });
                    break;
                }
            }
        }

        let count = rewrites.len();
        for rewrite in rewrites {
            apply_rewrite(func, rewrite);
        }
        count
    }
}

#[derive(Clone, Copy)]
struct Rewrite {
    old_addr_inst: Inst,
    native_base: Value,
    dynamic_offset: Option<Value>,
    static_offset: u32,
    mask: Option<u32>,
}

fn offset_from_base(func: &Function, addr: Value, base: Value) -> Option<Option<Value>> {
    let addr = func.dfg.resolve_aliases(addr);
    let base = func.dfg.resolve_aliases(base);
    if addr == base {
        return Some(None);
    }
    let inst = func.dfg.value_def(addr).inst()?;
    if func.dfg.insts[inst].opcode() != Opcode::Iadd {
        return None;
    }
    let args = func.dfg.inst_args(inst);
    if func.dfg.resolve_aliases(args[0]) == base {
        Some(Some(args[1]))
    } else if func.dfg.resolve_aliases(args[1]) == base {
        Some(Some(args[0]))
    } else {
        None
    }
}

fn apply_rewrite(func: &mut Function, rewrite: Rewrite) {
    if func.layout.inst_block(rewrite.old_addr_inst).is_none() {
        return;
    }

    let mut pos = FuncCursor::new(func);
    pos.goto_inst(rewrite.old_addr_inst);

    let offset64 = match rewrite.dynamic_offset {
        Some(offset) => {
            // Put an extend before a scale so AArch64 can select
            // `[base, index, uxtw #scale]` directly.
            if let Some((index, shift)) = scaled_offset(pos.func, offset) {
                let index = if let Some(mask) = rewrite.mask {
                    let index_mask = mask >> shift;
                    pos.ins().band_imm_u(index, i64::from(index_mask))
                } else {
                    index
                };
                let index = pos.ins().uextend(ir::types::I64, index);
                pos.ins().ishl_imm_u(index, i64::from(shift))
            } else {
                let offset = if let Some(mask) = rewrite.mask {
                    pos.ins().band_imm_u(offset, i64::from(mask))
                } else {
                    offset
                };
                pos.ins().uextend(ir::types::I64, offset)
            }
        }
        None => pos.ins().iconst(ir::types::I64, 0),
    };

    let mut new_addr = pos.ins().iadd(rewrite.native_base, offset64);
    if rewrite.static_offset != 0 {
        new_addr = pos
            .ins()
            .iadd_imm_u(new_addr, i64::from(rewrite.static_offset));
    }
    let new_addr_inst = pos.func.dfg.value_def(new_addr).unwrap_inst();
    pos.func
        .dfg
        .replace_with_aliases(rewrite.old_addr_inst, new_addr_inst);
    pos.remove_inst();
}

fn scaled_offset(func: &Function, value: Value) -> Option<(Value, u8)> {
    let value = func.dfg.resolve_aliases(value);
    let inst = func.dfg.value_def(value).inst()?;
    if func.dfg.insts[inst].opcode() != Opcode::Ishl {
        return None;
    }
    let args = func.dfg.inst_args(inst);
    let shift = iconst_u32(func, args[1])?;
    let shift = u8::try_from(shift).ok()?;
    (shift < 32).then_some((args[0], shift))
}

#[derive(Clone, Copy, Debug)]
struct Range {
    min: u64,
    max: u64,
}

impl Range {
    const I32_FULL: Self = Self {
        min: 0,
        max: u32::MAX as u64,
    };

    fn intersect(self, other: Self) -> Self {
        let min = self.min.max(other.min);
        let max = self.max.min(other.max);
        if min <= max { Self { min, max } } else { self }
    }

    fn union(self, other: Self) -> Self {
        Self {
            min: self.min.min(other.min),
            max: self.max.max(other.max),
        }
    }
}

struct RangeAnalysis<'a> {
    func: &'a Function,
    cfg: &'a ControlFlowGraph,
    domtree: &'a DominatorTree,
    active: HashSet<(Value, Block)>,
    cache: HashMap<(Value, Block), Range>,
}

impl<'a> RangeAnalysis<'a> {
    fn new(func: &'a Function, cfg: &'a ControlFlowGraph, domtree: &'a DominatorTree) -> Self {
        Self {
            func,
            cfg,
            domtree,
            active: HashSet::new(),
            cache: HashMap::new(),
        }
    }

    fn range_at(&mut self, value: Value, block: Block) -> Range {
        let value = self.func.dfg.resolve_aliases(value);
        if let Some(range) = self.cache.get(&(value, block)) {
            return *range;
        }
        if !self.active.insert((value, block)) {
            return Range::I32_FULL;
        }

        // Dominating control-flow facts are considered before the value's
        // structural range so a loop-carried value with a local bounds check
        // can be useful without solving the entire loop recurrence.
        let constraint = self.dominating_constraint(value, block);
        let structural = self.structural_range(value, block);
        self.active.remove(&(value, block));
        let result = constraint.map_or(structural, |c| structural.intersect(c));
        self.cache.insert((value, block), result);
        result
    }

    fn structural_range(&mut self, value: Value, block: Block) -> Range {
        match self.func.dfg.value_def(value) {
            ir::ValueDef::Param(param_block, index) => {
                self.block_param_range(value, param_block, index, block)
            }
            ir::ValueDef::Union(_, _) => Range::I32_FULL,
            ir::ValueDef::Result(inst, _) => {
                let opcode = self.func.dfg.insts[inst].opcode();
                let args = self.func.dfg.inst_args(inst);
                match opcode {
                    Opcode::Iconst => iconst_u32(self.func, value)
                        .map(|n| Range {
                            min: u64::from(n),
                            max: u64::from(n),
                        })
                        .unwrap_or(Range::I32_FULL),
                    Opcode::Uextend => self.range_at(args[0], block),
                    Opcode::Ireduce => {
                        let bits = self.func.dfg.value_type(value).bits();
                        let max = (1_u64 << bits) - 1;
                        let input = self.range_at(args[0], block);
                        if input.max <= max {
                            input
                        } else {
                            Range { min: 0, max }
                        }
                    }
                    Opcode::Iadd => self.add_range(args[0], args[1], block),
                    Opcode::Isub => self.sub_range(args[0], args[1], block),
                    Opcode::Band => {
                        if let Some(mask) = iconst_u32(self.func, args[0])
                            .or_else(|| iconst_u32(self.func, args[1]))
                        {
                            Range {
                                min: 0,
                                max: u64::from(mask),
                            }
                        } else {
                            Range::I32_FULL
                        }
                    }
                    Opcode::Bor => {
                        let (other, constant) = if let Some(c) = iconst_u32(self.func, args[0]) {
                            (args[1], c)
                        } else if let Some(c) = iconst_u32(self.func, args[1]) {
                            (args[0], c)
                        } else {
                            return Range::I32_FULL;
                        };
                        let other = self.range_at(other, block);
                        let envelope = if other.max == 0 {
                            0
                        } else {
                            other
                                .max
                                .checked_add(1)
                                .and_then(u64::checked_next_power_of_two)
                                .map_or(u64::from(u32::MAX), |n| n - 1)
                        };
                        Range {
                            min: 0,
                            max: (envelope | u64::from(constant)).min(u64::from(u32::MAX)),
                        }
                    }
                    Opcode::Ishl => {
                        let Some(shift) = iconst_u32(self.func, args[1]) else {
                            return Range::I32_FULL;
                        };
                        let shift = shift & 31;
                        let input = self.range_at(args[0], block);
                        if input.max <= (u64::from(u32::MAX) >> shift) {
                            Range {
                                min: input.min << shift,
                                max: input.max << shift,
                            }
                        } else {
                            Range::I32_FULL
                        }
                    }
                    Opcode::Ushr => {
                        let Some(shift) = iconst_u32(self.func, args[1]) else {
                            return Range::I32_FULL;
                        };
                        let shift = shift & 31;
                        let input = self.range_at(args[0], block);
                        Range {
                            min: input.min >> shift,
                            max: input.max >> shift,
                        }
                    }
                    Opcode::Select | Opcode::SelectSpectreGuard => {
                        let a = self.range_at(args[args.len() - 2], block);
                        let b = self.range_at(args[args.len() - 1], block);
                        a.union(b)
                    }
                    _ => Range::I32_FULL,
                }
            }
        }
    }

    fn add_range(&mut self, a: Value, b: Value, block: Block) -> Range {
        // Cranelift represents subtraction by a constant as addition of its
        // two's-complement value in several frontend paths.
        if let Some(c) = iconst_u32(self.func, b)
            && c > i32::MAX.cast_unsigned()
        {
            return self.sub_constant_range(a, c.wrapping_neg(), block);
        }
        if let Some(c) = iconst_u32(self.func, a)
            && c > i32::MAX.cast_unsigned()
        {
            return self.sub_constant_range(b, c.wrapping_neg(), block);
        }

        let a = self.range_at(a, block);
        let b = self.range_at(b, block);
        let max = a.max.checked_add(b.max);
        if max.is_some_and(|max| max <= u64::from(u32::MAX)) {
            Range {
                min: a.min + b.min,
                max: max.unwrap(),
            }
        } else {
            Range::I32_FULL
        }
    }

    fn sub_range(&mut self, a: Value, b: Value, block: Block) -> Range {
        if let Some(c) = iconst_u32(self.func, b) {
            self.sub_constant_range(a, c, block)
        } else {
            let a = self.range_at(a, block);
            let b = self.range_at(b, block);
            if a.min >= b.max {
                Range {
                    min: a.min - b.max,
                    max: a.max - b.min,
                }
            } else {
                Range::I32_FULL
            }
        }
    }

    fn sub_constant_range(&mut self, value: Value, c: u32, block: Block) -> Range {
        let value = self.range_at(value, block);
        let c = u64::from(c);
        if value.min >= c {
            Range {
                min: value.min - c,
                max: value.max - c,
            }
        } else {
            Range::I32_FULL
        }
    }

    fn block_param_range(
        &mut self,
        value: Value,
        param_block: Block,
        index: usize,
        _at_block: Block,
    ) -> Range {
        if self.func.layout.entry_block() == Some(param_block) {
            return Range::I32_FULL;
        }

        if let Some(range) = self.decreasing_induction_range(value, param_block, index) {
            return range;
        }

        let mut result = None;
        for pred in self.cfg.pred_iter(param_block) {
            for destination in self.func.dfg.insts[pred.inst]
                .branch_destination(&self.func.dfg.jump_tables, &self.func.dfg.exception_tables)
                .iter()
                .filter(|call| call.block(&self.func.dfg.value_lists) == param_block)
            {
                let Some(BlockArg::Value(actual)) =
                    destination.args(&self.func.dfg.value_lists).nth(index)
                else {
                    return Range::I32_FULL;
                };
                let range = self
                    .range_at(actual, pred.block)
                    .intersect(self.edge_constraint(actual, pred.inst, param_block));
                result = Some(result.map_or(range, |old: Range| old.union(range)));
            }
        }
        result.unwrap_or(Range::I32_FULL)
    }

    /// Prove the common `p = p - 1` loop induction without iterating once per
    /// loop trip. The incoming non-backedge values establish the upper bound;
    /// each backedge must exclude the wrapping case.
    fn decreasing_induction_range(
        &mut self,
        value: Value,
        block: Block,
        index: usize,
    ) -> Option<Range> {
        let mut initial = None;
        let mut saw_backedge = false;
        for pred in self.cfg.pred_iter(block) {
            let mut destinations = self.func.dfg.insts[pred.inst]
                .branch_destination(&self.func.dfg.jump_tables, &self.func.dfg.exception_tables)
                .iter()
                .filter(|call| call.block(&self.func.dfg.value_lists) == block);
            let destination = destinations.next()?;
            // A branch can name the same block twice with different arguments.
            // Do not let the specialized recurrence proof silently ignore one
            // of those incoming values.
            if destinations.next().is_some() {
                return None;
            }
            let actual = destination
                .args(&self.func.dfg.value_lists)
                .nth(index)?
                .as_value()?;

            if self.domtree.block_dominates(block, pred.block) {
                saw_backedge = true;
                if !is_decrement_by_one(self.func, actual, value) {
                    return None;
                }
                let edge = self.edge_constraint(actual, pred.inst, block);
                let value_constraint = self.dominating_constraint(value, pred.block);
                let excludes_wrap =
                    edge.min >= 1 || value_constraint.is_some_and(|range| range.min >= 2);
                if !excludes_wrap {
                    return None;
                }
            } else {
                let range = self.range_at(actual, pred.block);
                initial = Some(initial.map_or(range, |old: Range| old.union(range)));
            }
        }
        let initial = initial?;
        if !saw_backedge || initial.min < 1 {
            return None;
        }
        Some(Range {
            min: 1,
            max: initial.max,
        })
    }

    fn dominating_constraint(&mut self, value: Value, block: Block) -> Option<Range> {
        let mut result: Option<Range> = None;
        for dom_block in self.func.layout.blocks() {
            if dom_block == block || !self.domtree.block_dominates(dom_block, block) {
                continue;
            }
            let Some(inst) = self.func.layout.last_inst(dom_block) else {
                continue;
            };
            let ir::InstructionData::Brif {
                arg,
                blocks: [then_block, else_block],
                ..
            } = self.func.dfg.insts[inst]
            else {
                continue;
            };
            let then_dominates = self
                .domtree
                .block_dominates(then_block.block(&self.func.dfg.value_lists), block);
            let else_dominates = self
                .domtree
                .block_dominates(else_block.block(&self.func.dfg.value_lists), block);
            let truth = match (then_dominates, else_dominates) {
                (true, false) => true,
                (false, true) => false,
                _ => continue,
            };
            let constraint = self.condition_constraint(value, arg, truth, dom_block);
            result = Some(result.map_or(constraint, |old| old.intersect(constraint)));
        }
        result
    }

    fn edge_constraint(&mut self, value: Value, branch: Inst, destination: Block) -> Range {
        let ir::InstructionData::Brif {
            arg,
            blocks: [then_block, else_block],
            ..
        } = self.func.dfg.insts[branch]
        else {
            return Range::I32_FULL;
        };
        let truth = match (
            then_block.block(&self.func.dfg.value_lists) == destination,
            else_block.block(&self.func.dfg.value_lists) == destination,
        ) {
            (true, false) => true,
            (false, true) => false,
            _ => return Range::I32_FULL,
        };
        let block = self.func.layout.inst_block(branch).unwrap();
        self.condition_constraint(value, arg, truth, block)
    }

    fn condition_constraint(
        &mut self,
        value: Value,
        condition: Value,
        truth: bool,
        block: Block,
    ) -> Range {
        let condition = strip_boolean_casts(self.func, condition);
        let Some(inst) = self.func.dfg.value_def(condition).inst() else {
            return if condition == value {
                if truth {
                    Range {
                        min: 1,
                        max: u64::from(u32::MAX),
                    }
                } else {
                    Range { min: 0, max: 0 }
                }
            } else {
                Range::I32_FULL
            };
        };
        if self.func.dfg.insts[inst].opcode() != Opcode::Icmp {
            return if condition == value {
                if truth {
                    Range {
                        min: 1,
                        max: u64::from(u32::MAX),
                    }
                } else {
                    Range { min: 0, max: 0 }
                }
            } else {
                Range::I32_FULL
            };
        }

        let ir::InstructionData::IntCompare { cond, args, .. } = self.func.dfg.insts[inst] else {
            unreachable!()
        };
        let cond = if truth { cond } else { cond.complement() };
        if self.func.dfg.resolve_aliases(args[0]) == self.func.dfg.resolve_aliases(value) {
            self.constraint_from_compare(cond, args[1], block)
        } else if self.func.dfg.resolve_aliases(args[1]) == self.func.dfg.resolve_aliases(value) {
            self.constraint_from_compare(cond.swap_args(), args[0], block)
        } else if matches!(
            cond,
            IntCC::UnsignedLessThan | IntCC::UnsignedLessThanOrEqual
        ) && expression_contains_monotonically(self.func, args[0], value)
        {
            self.constraint_from_compare(cond, args[1], block)
        } else if matches!(
            cond,
            IntCC::UnsignedGreaterThan | IntCC::UnsignedGreaterThanOrEqual
        ) && expression_contains_monotonically(self.func, args[1], value)
        {
            self.constraint_from_compare(cond.swap_args(), args[0], block)
        } else {
            Range::I32_FULL
        }
    }

    fn constraint_from_compare(&mut self, cond: IntCC, other: Value, block: Block) -> Range {
        let other = self.range_at(other, block);
        match cond {
            IntCC::Equal => other,
            IntCC::NotEqual => {
                if other.min == 0 && other.max == 0 {
                    Range {
                        min: 1,
                        max: u64::from(u32::MAX),
                    }
                } else {
                    Range::I32_FULL
                }
            }
            IntCC::UnsignedLessThan => Range {
                min: 0,
                max: other.max.saturating_sub(1),
            },
            IntCC::UnsignedLessThanOrEqual => Range {
                min: 0,
                max: other.max,
            },
            IntCC::UnsignedGreaterThan => Range {
                min: other.min.saturating_add(1),
                max: u64::from(u32::MAX),
            },
            IntCC::UnsignedGreaterThanOrEqual => Range {
                min: other.min,
                max: u64::from(u32::MAX),
            },
            _ => Range::I32_FULL,
        }
    }
}

fn strip_boolean_casts(func: &Function, mut value: Value) -> Value {
    loop {
        let Some(inst) = func.dfg.value_def(value).inst() else {
            return value;
        };
        match func.dfg.insts[inst].opcode() {
            // Zero-extension preserves whether an integer is zero. Reduction
            // does not: for example, reducing 256 to i8 produces zero.
            Opcode::Uextend => value = func.dfg.inst_args(inst)[0],
            _ => return value,
        }
    }
}

/// Return true only for expressions that are never less than `needle` when
/// interpreted as an unsigned integer. This lets a bound on `x | constant`
/// safely imply the same bound on `x`.
fn expression_contains_monotonically(func: &Function, expression: Value, needle: Value) -> bool {
    let expression = func.dfg.resolve_aliases(expression);
    let needle = func.dfg.resolve_aliases(needle);
    if expression == needle {
        return true;
    }
    let Some(inst) = func.dfg.value_def(expression).inst() else {
        return false;
    };
    if func.dfg.insts[inst].opcode() != Opcode::Bor {
        return false;
    }
    let args = func.dfg.inst_args(inst);
    (iconst_u32(func, args[0]).is_some()
        && expression_contains_monotonically(func, args[1], needle))
        || (iconst_u32(func, args[1]).is_some()
            && expression_contains_monotonically(func, args[0], needle))
}

fn is_decrement_by_one(func: &Function, value: Value, induction: Value) -> bool {
    let value = func.dfg.resolve_aliases(value);
    let Some(inst) = func.dfg.value_def(value).inst() else {
        return false;
    };
    let args = func.dfg.inst_args(inst);
    match func.dfg.insts[inst].opcode() {
        Opcode::Isub => {
            func.dfg.resolve_aliases(args[0]) == induction && iconst_u32(func, args[1]) == Some(1)
        }
        Opcode::Iadd => {
            (func.dfg.resolve_aliases(args[0]) == induction
                && iconst_u32(func, args[1]) == Some(u32::MAX))
                || (func.dfg.resolve_aliases(args[1]) == induction
                    && iconst_u32(func, args[0]) == Some(u32::MAX))
        }
        _ => false,
    }
}

fn iconst_u32(func: &Function, value: Value) -> Option<u32> {
    let value = func.dfg.resolve_aliases(value);
    if func.dfg.value_type(value) != ir::types::I32 {
        return None;
    }
    let inst = func.dfg.value_def(value).inst()?;
    let ir::InstructionData::UnaryImm {
        opcode: Opcode::Iconst,
        imm,
    } = func.dfg.insts[inst]
    else {
        return None;
    };
    Some(
        u32::try_from(imm.bits().cast_unsigned() & u64::from(u32::MAX))
            .expect("an i32 immediate fits in u32"),
    )
}
