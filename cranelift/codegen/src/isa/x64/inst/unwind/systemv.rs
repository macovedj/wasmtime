//! Unwind information for System V ABI (x86-64).

use crate::isa::unwind::systemv::RegisterMappingError;
use crate::machinst::{Reg, RegClass};
use gimli::{Encoding, Format, Register, X86_64, write::CommonInformationEntry};

/// Creates a new x86-64 common information entry (CIE).
pub fn create_cie() -> CommonInformationEntry {
    use gimli::write::CallFrameInstruction;

    let mut entry = CommonInformationEntry::new(
        Encoding {
            address_size: 8,
            format: Format::Dwarf32,
            version: 1,
        },
        1,  // Code alignment factor
        -8, // Data alignment factor
        X86_64::RA,
    );

    // Every frame will start with the call frame address (CFA) at RSP+8
    // It is +8 to account for the push of the return address by the call instruction
    entry.add_instruction(CallFrameInstruction::Cfa(X86_64::RSP, 8));

    // Every frame will start with the return address at RSP (CFA-8 = RSP+8-8 = RSP)
    entry.add_instruction(CallFrameInstruction::Offset(X86_64::RA, -8));

    entry
}

/// Map Cranelift registers to their corresponding Gimli registers.
pub fn map_reg(reg: Reg) -> Result<Register, RegisterMappingError> {
    // Mapping from https://github.com/bytecodealliance/cranelift/pull/902 by @iximeow
    const X86_GP_REG_MAP: [gimli::Register; 16] = [
        X86_64::RAX,
        X86_64::RCX,
        X86_64::RDX,
        X86_64::RBX,
        X86_64::RSP,
        X86_64::RBP,
        X86_64::RSI,
        X86_64::RDI,
        X86_64::R8,
        X86_64::R9,
        X86_64::R10,
        X86_64::R11,
        X86_64::R12,
        X86_64::R13,
        X86_64::R14,
        X86_64::R15,
    ];
    const X86_XMM_REG_MAP: [gimli::Register; 16] = [
        X86_64::XMM0,
        X86_64::XMM1,
        X86_64::XMM2,
        X86_64::XMM3,
        X86_64::XMM4,
        X86_64::XMM5,
        X86_64::XMM6,
        X86_64::XMM7,
        X86_64::XMM8,
        X86_64::XMM9,
        X86_64::XMM10,
        X86_64::XMM11,
        X86_64::XMM12,
        X86_64::XMM13,
        X86_64::XMM14,
        X86_64::XMM15,
    ];

    match reg.class() {
        RegClass::Int => {
            // x86 GP registers have a weird mapping to DWARF registers, so we use a
            // lookup table.
            Ok(X86_GP_REG_MAP[reg.to_real_reg().unwrap().hw_enc() as usize])
        }
        RegClass::Float => Ok(X86_XMM_REG_MAP[reg.to_real_reg().unwrap().hw_enc() as usize]),
        RegClass::Vector => unreachable!(),
    }
}

pub(crate) struct RegisterMapper;

impl crate::isa::unwind::systemv::RegisterMapper<Reg> for RegisterMapper {
    fn map(&self, reg: Reg) -> Result<u16, RegisterMappingError> {
        Ok(map_reg(reg)?.0)
    }
    fn fp(&self) -> Option<u16> {
        Some(X86_64::RBP.0)
    }
}

#[cfg(test)]
mod tests {
    use crate::Context;
    use crate::cursor::{Cursor, FuncCursor};
    use crate::ir::{
        AbiParam, Function, InstBuilder, Signature, StackSlotData, StackSlotKind, types,
    };
    use crate::isa::unwind::{SystemVUnwindInst, UnwindInst};
    use crate::isa::{CallConv, lookup};
    use crate::settings::{Configurable, Flags, builder};
    use alloc::vec::Vec;
    use gimli::write::{Address, EndianVec, FrameDescriptionEntry, FrameTable};
    use gimli::{CfaRule, LittleEndian, RegisterRule, UnwindSection, UnwindTableRow, X86_64};
    use target_lexicon::triple;

    // Test the serialized metadata through an independent DWARF interpreter,
    // rather than only comparing the pseudo-instructions that produced it.
    fn unwind_rows(fde: FrameDescriptionEntry) -> Vec<UnwindTableRow<usize>> {
        let mut table = FrameTable::default();
        let cie = table.add_cie(super::create_cie());
        table.add_fde(cie, fde);
        let mut bytes = gimli::write::EhFrame(EndianVec::new(LittleEndian));
        table.write_eh_frame(&mut bytes).unwrap();

        let mut section = gimli::EhFrame::new(bytes.0.slice(), LittleEndian);
        section.set_address_size(8);
        let bases = gimli::BaseAddresses::default();
        let fde = section
            .fde_for_address(&bases, 0, gimli::EhFrame::cie_from_offset)
            .unwrap();
        let mut context = gimli::UnwindContext::new();
        let mut table = fde.rows(&section, &bases, &mut context).unwrap();
        let mut rows = Vec::new();
        while let Some(row) = table.next_row().unwrap() {
            rows.push(row.clone());
        }
        rows
    }

    fn row_at(rows: &[UnwindTableRow<usize>], offset: u32) -> &UnwindTableRow<usize> {
        rows.iter()
            .find(|row| {
                row.start_address() <= u64::from(offset) && u64::from(offset) < row.end_address()
            })
            .unwrap()
    }

    fn check_frame_rule(row: &UnwindTableRow<usize>, in_epilogue: bool) {
        assert_eq!(
            row.cfa(),
            &CfaRule::RegisterAndOffset {
                register: if in_epilogue {
                    X86_64::RSP
                } else {
                    X86_64::RBP
                },
                offset: if in_epilogue { 8 } else { 16 },
            }
        );
        assert_eq!(
            row.register(X86_64::RBP),
            Some(if in_epilogue {
                RegisterRule::SameValue
            } else {
                RegisterRule::Offset(-16)
            })
        );
        assert_eq!(row.register(X86_64::RA), Some(RegisterRule::Offset(-8)));
    }

    #[test]
    fn test_simple_func() {
        let isa = lookup(triple!("x86_64"))
            .expect("expect x86 ISA")
            .finish(Flags::new(builder()))
            .expect("expect backend creation to succeed");

        let mut context = Context::for_function(create_function(
            CallConv::SystemV,
            Some(StackSlotData::new(StackSlotKind::ExplicitSlot, 64, 0)),
        ));

        let code = context
            .compile(&*isa, &mut Default::default())
            .expect("expected compilation");

        let fde = match code
            .create_unwind_info(isa.as_ref())
            .expect("can create unwind info")
        {
            Some(crate::isa::unwind::UnwindInfo::SystemV(info)) => {
                info.to_fde(Address::Constant(1234))
            }
            _ => panic!("expected unwind information"),
        };

        assert_eq!(
            format!("{fde:?}"),
            "FrameDescriptionEntry { address: Constant(1234), length: 17, lsda: None, instructions: [(1, CfaOffset(16)), (1, Offset(Register(6), -16)), (4, CfaRegister(Register(6))), (8, RememberState), (16, Cfa(Register(7), 8)), (16, SameValue(Register(6))), (17, RestoreState)] }"
        );
    }

    fn create_function(call_conv: CallConv, stack_slot: Option<StackSlotData>) -> Function {
        let mut func = Function::with_name_signature(Default::default(), Signature::new(call_conv));

        let block0 = func.dfg.make_block();
        let mut pos = FuncCursor::new(&mut func);
        pos.insert_block(block0);
        pos.ins().return_(&[]);

        if let Some(stack_slot) = stack_slot {
            func.sized_stack_slots.push(stack_slot);
        }

        func
    }

    #[test]
    fn test_multi_return_func() {
        let isa = lookup(triple!("x86_64"))
            .expect("expect x86 ISA")
            .finish(Flags::new(builder()))
            .expect("expect backend creation to succeed");

        let mut context = Context::for_function(create_multi_return_function(CallConv::SystemV));

        let code = context
            .compile(&*isa, &mut Default::default())
            .expect("expected compilation");

        let fde = match code
            .create_unwind_info(isa.as_ref())
            .expect("can create unwind info")
        {
            Some(crate::isa::unwind::UnwindInfo::SystemV(info)) => {
                info.to_fde(Address::Constant(4321))
            }
            _ => panic!("expected unwind information"),
        };

        assert_eq!(
            format!("{fde:?}"),
            "FrameDescriptionEntry { address: Constant(4321), length: 22, lsda: None, instructions: [(1, CfaOffset(16)), (1, Offset(Register(6), -16)), (4, CfaRegister(Register(6))), (12, RememberState), (16, Cfa(Register(7), 8)), (16, SameValue(Register(6))), (17, RestoreState), (17, RememberState), (21, Cfa(Register(7), 8)), (21, SameValue(Register(6))), (22, RestoreState)] }"
        );
    }

    #[test]
    fn test_return_epilogue_rows() {
        for call_conv in [CallConv::SystemV, CallConv::Tail, CallConv::Winch] {
            let mut func = create_multi_return_function(call_conv);
            // Force stack arguments, including a nonzero `ret imm16` pop for
            // Tail. Winch uses the ordinary caller-pop `ret` instruction.
            let block0 = func.layout.entry_block().unwrap();
            for _ in 0..8 {
                func.signature.params.push(AbiParam::new(types::I64));
                func.dfg.append_block_param(block0, types::I64);
            }
            let mut machine_bytes = None;
            for enabled in [true, false] {
                let mut flags = builder();
                flags
                    .set("unwind_info", if enabled { "true" } else { "false" })
                    .unwrap();
                let isa = lookup(triple!("x86_64"))
                    .unwrap()
                    .finish(Flags::new(flags))
                    .unwrap();
                let mut context = Context::for_function(func.clone());
                let code = context.compile(&*isa, &mut Default::default()).unwrap();
                if let Some(bytes) = &machine_bytes {
                    assert_eq!(code.code_buffer(), bytes);
                } else {
                    machine_bytes = Some(code.code_buffer().to_vec());
                }
                if !enabled {
                    assert!(code.buffer.unwind_info.is_empty());
                    continue;
                }

                let Some(crate::isa::unwind::UnwindInfo::SystemV(info)) =
                    code.create_unwind_info(isa.as_ref()).unwrap()
                else {
                    panic!("expected System V unwind information");
                };
                let rows = unwind_rows(info.to_fde(Address::Constant(0)));
                let mut returns = 0;
                for &(offset, ref inst) in &code.buffer.unwind_info {
                    match inst {
                        UnwindInst::SystemV(SystemVUnwindInst::DefineCfa { .. }) => {
                            returns += 1;
                            // POP RBP is one byte, and the row changes only
                            // after it has actually restored the register.
                            assert_eq!(code.code_buffer()[offset as usize - 1], 0x5d);
                            check_frame_rule(row_at(&rows, offset - 1), false);
                            check_frame_rule(row_at(&rows, offset), true);
                            assert_eq!(
                                code.code_buffer()[offset as usize],
                                if call_conv == CallConv::Tail {
                                    0xc2
                                } else {
                                    0xc3
                                }
                            );
                            if call_conv == CallConv::Tail {
                                check_frame_rule(row_at(&rows, offset + 1), true);
                                check_frame_rule(row_at(&rows, offset + 2), true);
                            }
                        }
                        UnwindInst::SystemV(SystemVUnwindInst::RestoreState)
                            if (offset as usize) < code.code_buffer().len() =>
                        {
                            // A later block starts with the function body's
                            // frame state, not the preceding return's state.
                            check_frame_rule(row_at(&rows, offset), false);
                        }
                        _ => {}
                    }
                }
                assert_eq!(returns, 2);
            }
        }
    }

    #[test]
    fn test_tail_transfer_does_not_leak_epilogue_rows() {
        use crate::ir::{ExtFuncData, ExternalName};

        let mut sig = Signature::new(CallConv::Tail);
        sig.params.push(AbiParam::new(types::I32));
        let mut func = Function::with_name_signature(Default::default(), sig);
        let callee_sig = func.import_signature(Signature::new(CallConv::Tail));
        let callee = func.import_function(ExtFuncData {
            name: ExternalName::testcase("callee"),
            signature: callee_sig,
            colocated: false,
            patchable: false,
        });
        let entry = func.dfg.make_block();
        let condition = func.dfg.append_block_param(entry, types::I32);
        let tail = func.dfg.make_block();
        let normal = func.dfg.make_block();
        let mut pos = FuncCursor::new(&mut func);
        pos.insert_block(entry);
        pos.ins().brif(condition, normal, &[], tail, &[]);
        pos.insert_block(tail);
        pos.ins().return_call(callee, &[]);
        pos.insert_block(normal);
        pos.ins().return_(&[]);

        let mut flags = builder();
        flags.enable("preserve_frame_pointers").unwrap();
        let isa = lookup(triple!("x86_64"))
            .unwrap()
            .finish(Flags::new(flags))
            .unwrap();
        let mut context = Context::for_function(func);
        let code = context.compile(&*isa, &mut Default::default()).unwrap();
        let Some(crate::isa::unwind::UnwindInfo::SystemV(info)) =
            code.create_unwind_info(isa.as_ref()).unwrap()
        else {
            panic!("expected System V unwind information");
        };
        let rows = unwind_rows(info.to_fde(Address::Constant(0)));
        let mut epilogues = 0;
        for &(offset, ref inst) in &code.buffer.unwind_info {
            match inst {
                UnwindInst::SystemV(SystemVUnwindInst::RememberState) => {
                    check_frame_rule(row_at(&rows, offset), false);
                    epilogues += 1;
                }
                UnwindInst::SystemV(SystemVUnwindInst::DefineCfa { .. }) => {
                    // Only the normal return gets new epilogue rows. In
                    // particular a tail jump must not receive an unscoped
                    // RSP-based rule from the shared frame-restore helper.
                    assert_eq!(code.code_buffer()[offset as usize], 0xc3);
                }
                _ => {}
            }
        }
        assert_eq!(epilogues, 1);
    }

    #[test]
    fn test_callee_save_epilogue_rows() {
        use crate::isa::x64::abi::X64ABIMachineSpec as Abi;
        use crate::isa::x64::inst::{EmitInfo, EmitState, Inst, regs};
        use crate::machinst::{ABIMachineSpec, FrameLayout, MachBuffer, MachInstEmit, Writable};

        let flags = Flags::new(builder());
        let isa_flags =
            crate::isa::x64::settings::Flags::new(&flags, &crate::isa::x64::settings::builder());
        let emit_info = EmitInfo::new(flags.clone(), isa_flags.clone());
        let frame = FrameLayout {
            word_bytes: 8,
            setup_area_size: 16,
            clobber_size: 32,
            fixed_frame_storage_size: 32,
            clobbered_callee_saves: [regs::rbx(), regs::r12(), regs::xmm6()]
                .map(|reg| Writable::from_reg(reg.to_real_reg().unwrap()))
                .into(),
            ..FrameLayout::default()
        };
        let mut insts =
            Abi::gen_prologue_frame_setup(CallConv::WindowsFastcall, &flags, &isa_flags, &frame);
        insts.extend(Abi::gen_clobber_save(
            CallConv::WindowsFastcall,
            &flags,
            &frame,
        ));
        // Keep epilogue offsets beyond Windows' one-byte prologue-offset
        // limit. Ignored DWARF-only operations must not trip that limit.
        insts.extend((0..32).map(|_| Inst::nop(9)));
        // Two copies make it possible to check that SameValue rules from one
        // epilogue do not leak into a later block's saved-register rules.
        for _ in 0..2 {
            insts.extend(Abi::gen_dwarf_unwind(SystemVUnwindInst::RememberState));
            insts.extend(Abi::gen_clobber_restore(
                CallConv::WindowsFastcall,
                &flags,
                &frame,
            ));
            insts.extend(Abi::gen_epilogue_frame_restore(
                CallConv::WindowsFastcall,
                &flags,
                &isa_flags,
                &frame,
            ));
            insts.extend(Abi::gen_return(
                CallConv::WindowsFastcall,
                &isa_flags,
                &frame,
            ));
            insts.extend(Abi::gen_dwarf_unwind(SystemVUnwindInst::RestoreState));
        }
        let mut buffer = MachBuffer::<Inst>::new();
        let mut state = EmitState::default();
        for inst in insts {
            inst.emit(&mut buffer, &emit_info, &mut state);
        }
        let buffer = buffer.finish(&Default::default(), &mut Default::default());
        let info = crate::isa::unwind::systemv::create_unwind_info_from_insts(
            &buffer.unwind_info,
            buffer.data().len(),
            &super::RegisterMapper,
        )
        .unwrap();
        let rows = unwind_rows(info.to_fde(Address::Constant(0)));
        let mut restored = 0;
        for &(offset, ref inst) in &buffer.unwind_info {
            match inst {
                UnwindInst::SystemV(SystemVUnwindInst::SameValue { reg }) => {
                    let reg = super::map_reg((*reg).into()).unwrap();
                    assert!(matches!(
                        row_at(&rows, offset - 1).register(reg),
                        Some(RegisterRule::Offset(_))
                    ));
                    assert_eq!(
                        row_at(&rows, offset).register(reg),
                        Some(RegisterRule::SameValue)
                    );
                    restored += 1;
                }
                UnwindInst::SystemV(SystemVUnwindInst::RestoreState)
                    if (offset as usize) < buffer.data().len() =>
                {
                    let row = row_at(&rows, offset);
                    check_frame_rule(row, false);
                    for reg in [X86_64::RBX, X86_64::R12, X86_64::XMM6] {
                        assert!(matches!(row.register(reg), Some(RegisterRule::Offset(_))));
                    }
                }
                _ => {}
            }
        }
        assert_eq!(restored, 8);

        // SystemV-only epilogue operations must leave native Windows metadata
        // byte-for-byte identical to metadata made from just the prologue.
        let prologue = buffer
            .unwind_info
            .iter()
            .filter(|(_, inst)| !matches!(inst, UnwindInst::SystemV(_)))
            .cloned()
            .collect::<Vec<_>>();
        let windows_bytes = |insts: &[(u32, UnwindInst)]| {
            let info = crate::isa::unwind::winx64::create_unwind_info_from_insts::<
                super::super::winx64::RegisterMapper,
            >(insts)
            .unwrap();
            let mut bytes = vec![0; info.emit_size()];
            info.emit(&mut bytes);
            bytes
        };
        assert_eq!(windows_bytes(&buffer.unwind_info), windows_bytes(&prologue));
    }

    fn create_multi_return_function(call_conv: CallConv) -> Function {
        let mut sig = Signature::new(call_conv);
        sig.params.push(AbiParam::new(types::I32));
        let mut func = Function::with_name_signature(Default::default(), sig);

        let block0 = func.dfg.make_block();
        let v0 = func.dfg.append_block_param(block0, types::I32);
        let block1 = func.dfg.make_block();
        let block2 = func.dfg.make_block();

        let mut pos = FuncCursor::new(&mut func);
        pos.insert_block(block0);
        pos.ins().brif(v0, block2, &[], block1, &[]);

        pos.insert_block(block1);
        pos.ins().return_(&[]);

        pos.insert_block(block2);
        pos.ins().return_(&[]);

        func
    }
}
