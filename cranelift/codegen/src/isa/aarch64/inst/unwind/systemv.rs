//! Unwind information for System V ABI (Aarch64).

use crate::isa::aarch64::inst::regs;
use crate::isa::unwind::systemv::RegisterMappingError;
use crate::machinst::{Reg, RegClass};
use gimli::{Encoding, Format, Register, write::CommonInformationEntry};

/// Creates a new aarch64 common information entry (CIE).
pub fn create_cie() -> CommonInformationEntry {
    use gimli::write::CallFrameInstruction;

    let mut entry = CommonInformationEntry::new(
        Encoding {
            address_size: 8,
            format: Format::Dwarf32,
            version: 1,
        },
        4,  // Code alignment factor
        -8, // Data alignment factor
        Register(regs::link_reg().to_real_reg().unwrap().hw_enc().into()),
    );

    // Every frame will start with the call frame address (CFA) at SP
    let sp = Register((regs::stack_reg().to_real_reg().unwrap().hw_enc() & 31).into());
    entry.add_instruction(CallFrameInstruction::Cfa(sp, 0));

    entry
}

/// Map Cranelift registers to their corresponding Gimli registers.
pub fn map_reg(reg: Reg) -> Result<Register, RegisterMappingError> {
    // For AArch64 DWARF register mappings, see:
    //
    // https://developer.arm.com/documentation/ihi0057/e/?lang=en#dwarf-register-names
    //
    // X0--X31 is 0--31; V0--V31 is 64--95.
    match reg.class() {
        RegClass::Int => {
            let reg = (reg.to_real_reg().unwrap().hw_enc() & 31) as u16;
            Ok(Register(reg))
        }
        RegClass::Float => {
            let reg = reg.to_real_reg().unwrap().hw_enc() as u16;
            Ok(Register(64 + reg))
        }
        RegClass::Vector => unreachable!(),
    }
}

pub(crate) struct RegisterMapper;

impl crate::isa::unwind::systemv::RegisterMapper<Reg> for RegisterMapper {
    fn map(&self, reg: Reg) -> Result<u16, RegisterMappingError> {
        Ok(map_reg(reg)?.0)
    }
    fn fp(&self) -> Option<u16> {
        Some(regs::fp_reg().to_real_reg().unwrap().hw_enc().into())
    }
    fn lr(&self) -> Option<u16> {
        Some(regs::link_reg().to_real_reg().unwrap().hw_enc().into())
    }
    fn lr_offset(&self) -> Option<u32> {
        Some(8)
    }
}

#[cfg(test)]
mod tests {
    use super::{RegisterMapper, create_cie};
    use crate::Context;
    use crate::cursor::{Cursor, FuncCursor};
    use crate::ir::{
        AbiParam, Function, InstBuilder, Signature, StackSlotData, StackSlotKind, types,
    };
    use crate::isa::aarch64::{abi::AArch64MachineDeps, inst::*, settings as aarch64_settings};
    use crate::isa::unwind::{SystemVUnwindInst, UnwindInst, systemv, winarm64};
    use crate::isa::{CallConv, lookup};
    use crate::machinst::{ABIMachineSpec, FrameLayout, MachBufferFinalized, MachInstEmit};
    use crate::settings::{Configurable, Flags, builder};
    use gimli::write::{Address, EhFrame, EndianVec, FrameDescriptionEntry, FrameTable};
    use gimli::{CfaRule, LittleEndian, Register, RegisterRule, UnwindSection, UnwindTableRow};
    use target_lexicon::triple;

    #[test]
    fn test_simple_func() {
        let isa = lookup(triple!("aarch64"))
            .expect("expect aarch64 ISA")
            .finish(Flags::new(builder()))
            .expect("Creating compiler backend");

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
            "FrameDescriptionEntry { address: Constant(1234), length: 24, lsda: None, instructions: [(4, CfaOffset(16)), (4, Offset(Register(29), -16)), (4, Offset(Register(30), -8)), (8, CfaRegister(Register(29))), (12, RememberState), (20, SameValue(Register(29))), (20, SameValue(Register(30))), (20, Cfa(Register(31), 0)), (24, RestoreState)] }"
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
        let isa = lookup(triple!("aarch64"))
            .expect("expect aarch64 ISA")
            .finish(Flags::new(builder()))
            .expect("Creating compiler backend");

        let mut context = Context::for_function(create_multi_return_function(CallConv::SystemV));

        let code = context
            .compile(&*isa, &mut Default::default())
            .expect("expected compilation");

        let fde = match code
            .create_unwind_info(isa.as_ref())
            .expect("can create unwind info")
        {
            Some(crate::isa::unwind::UnwindInfo::SystemV(info)) => {
                info.to_fde(Address::Constant(0))
            }
            _ => panic!("expected unwind information"),
        };

        let (_, rows) = serialized_rows(fde);
        for row in rows {
            assert_cfa(&row, 31, 0);
            assert_eq!(row.register(Register(29)), None);
            assert_eq!(row.register(Register(30)), None);
        }
    }

    fn serialized_rows(fde: FrameDescriptionEntry) -> (Vec<u8>, Vec<UnwindTableRow<usize>>) {
        let mut table = FrameTable::default();
        let cie = table.add_cie(create_cie());
        table.add_fde(cie, fde);
        let mut section = EhFrame(EndianVec::new(LittleEndian));
        table.write_eh_frame(&mut section).unwrap();
        let bytes = section.0.into_vec();
        let section = gimli::EhFrame::new(&bytes, LittleEndian);
        let bases = gimli::BaseAddresses::default();
        let fde = section
            .fde_for_address(&bases, 0, gimli::EhFrame::cie_from_offset)
            .unwrap();
        let mut context = gimli::UnwindContext::new();
        let mut table = fde.rows(&section, &bases, &mut context).unwrap();
        let mut rows = vec![];
        while let Some(row) = table.next_row().unwrap() {
            rows.push(row.clone());
        }
        (bytes, rows)
    }

    fn row_at(rows: &[UnwindTableRow<usize>], offset: usize) -> &UnwindTableRow<usize> {
        rows.iter().find(|row| row.contains(offset as u64)).unwrap()
    }

    fn assert_cfa(row: &UnwindTableRow<usize>, register: u16, offset: i64) {
        assert_eq!(
            *row.cfa(),
            CfaRule::RegisterAndOffset {
                register: Register(register),
                offset,
            }
        );
    }

    fn emit_frame(
        frame: &FrameLayout,
        call_conv: CallConv,
        unwind: bool,
        sign: bool,
        pauth: bool,
    ) -> MachBufferFinalized {
        let mut flag_builder = builder();
        flag_builder
            .set("unwind_info", if unwind { "true" } else { "false" })
            .unwrap();
        let flags = Flags::new(flag_builder);
        let mut isa_builder = aarch64_settings::builder();
        isa_builder
            .set("sign_return_address", if sign { "true" } else { "false" })
            .unwrap();
        isa_builder.set("sign_return_address_all", "true").unwrap();
        isa_builder
            .set("has_pauth", if pauth { "true" } else { "false" })
            .unwrap();
        let isa_flags = aarch64_settings::Flags::new(&flags, &isa_builder);
        let mut insts =
            AArch64MachineDeps::gen_prologue_frame_setup(call_conv, &flags, &isa_flags, frame);
        insts.extend(AArch64MachineDeps::gen_clobber_save(
            call_conv, &flags, frame,
        ));
        if unwind {
            insts.extend(AArch64MachineDeps::gen_dwarf_unwind(
                SystemVUnwindInst::RememberState,
            ));
        }
        insts.extend(AArch64MachineDeps::gen_clobber_restore(
            call_conv, &flags, frame,
        ));
        insts.extend(AArch64MachineDeps::gen_epilogue_frame_restore(
            call_conv, &flags, &isa_flags, frame,
        ));
        insts.extend(AArch64MachineDeps::gen_return(call_conv, &isa_flags, frame));
        if unwind {
            insts.extend(AArch64MachineDeps::gen_dwarf_unwind(
                SystemVUnwindInst::RestoreState,
            ));
        }
        // A later block must retain the body rules, not this epilogue's rules.
        insts.push(Inst::Nop4);
        let mut buffer = MachBuffer::new();
        let info = EmitInfo::new(flags, isa_flags);
        let mut state = EmitState::default();
        for inst in insts {
            inst.emit(&mut buffer, &info, &mut state);
        }
        buffer.finish(&Default::default(), &mut Default::default())
    }

    fn rows_for_buffer(buffer: &MachBufferFinalized) -> (Vec<u8>, Vec<UnwindTableRow<usize>>) {
        let info = systemv::create_unwind_info_from_insts(
            &buffer.unwind_info,
            buffer.data().len(),
            &RegisterMapper,
        )
        .unwrap();
        serialized_rows(info.to_fde(Address::Constant(0)))
    }

    #[test]
    fn test_epilogue_saved_register_rows() {
        let frame = FrameLayout {
            setup_area_size: 16,
            clobber_size: 64,
            fixed_frame_storage_size: 64,
            clobbered_callee_saves: [xreg(19), xreg(20), xreg(21), vreg(8), vreg(9), vreg(10)]
                .map(|reg| Writable::from_reg(reg.to_real_reg().unwrap()))
                .to_vec(),
            ..FrameLayout::default()
        };
        let buffer = emit_frame(&frame, CallConv::SystemV, true, false, false);
        let (_, rows) = rows_for_buffer(&buffer);
        // Pair and singleton loads each restore their rules exactly after the
        // corresponding instruction, with the CFA still based on FP.
        for (offset, registers) in [
            (36, &[72, 73][..]),
            (40, &[74][..]),
            (44, &[19, 20][..]),
            (48, &[21][..]),
        ] {
            for &reg in registers {
                assert!(matches!(
                    row_at(&rows, offset - 4).register(Register(reg)),
                    Some(RegisterRule::Offset(_))
                ));
                assert_eq!(
                    row_at(&rows, offset).register(Register(reg)),
                    Some(RegisterRule::SameValue)
                );
            }
            assert_cfa(row_at(&rows, offset), 29, 16);
        }
        let ret = row_at(&rows, 52);
        assert_cfa(ret, 31, 0);
        for reg in [19, 20, 21, 29, 30, 72, 73, 74] {
            assert_eq!(ret.register(Register(reg)), Some(RegisterRule::SameValue));
            assert!(matches!(
                row_at(&rows, 56).register(Register(reg)),
                Some(RegisterRule::Offset(_))
            ));
        }
        assert_cfa(row_at(&rows, 56), 29, 16);

        let no_unwind = emit_frame(&frame, CallConv::SystemV, false, false, false);
        assert_eq!(buffer.data(), no_unwind.data());
        assert!(no_unwind.unwind_info.is_empty());
        let prologue_only: Vec<_> = buffer
            .unwind_info
            .iter()
            .filter(|(_, inst)| !matches!(inst, UnwindInst::SystemV(_)))
            .cloned()
            .collect();
        assert_eq!(
            winarm64::create_unwind_info_from_insts(&buffer.unwind_info).unwrap(),
            winarm64::create_unwind_info_from_insts(&prologue_only).unwrap(),
        );
        assert!(
            AArch64MachineDeps::gen_clobber_restore_impl(CallConv::Tail, &frame, false)
                .iter()
                .all(|inst| !matches!(inst, Inst::Unwind { .. }))
        );
    }

    #[test]
    fn test_epilogue_stack_args_rows() {
        for call_conv in [CallConv::SystemV, CallConv::Tail] {
            for tail_args_size in [16, 32] {
                let frame = FrameLayout {
                    setup_area_size: 16,
                    incoming_args_size: 16,
                    tail_args_size,
                    ..FrameLayout::default()
                };
                let buffer = emit_frame(&frame, call_conv, true, false, false);
                let (_, rows) = rows_for_buffer(&buffer);
                let ret_offset = buffer.data().len() - 8;
                let popped = if call_conv == CallConv::Tail { 4 } else { 0 };
                assert_cfa(
                    row_at(&rows, ret_offset - popped),
                    31,
                    i64::from(tail_args_size - 16),
                );
                assert_cfa(
                    row_at(&rows, ret_offset),
                    31,
                    if popped == 0 {
                        i64::from(tail_args_size - 16)
                    } else {
                        -16
                    },
                );
                assert_eq!(
                    row_at(&rows, ret_offset).register(Register(30)),
                    Some(RegisterRule::SameValue)
                );
                // Expanded-tail prologue/body CFA coverage is deliberately not
                // asserted here; these checks describe the return instructions.
            }
        }
    }

    #[test]
    fn test_authenticated_return_rows() {
        for setup_area_size in [0, 16] {
            for pauth in [false, true] {
                let frame = FrameLayout {
                    setup_area_size,
                    ..FrameLayout::default()
                };
                let buffer = emit_frame(&frame, CallConv::SystemV, true, true, pauth);
                let (bytes, rows) = rows_for_buffer(&buffer);
                let ret_offset = buffer.data().len() - 8;
                let expected_sign = if pauth {
                    gimli::DW_OP_lit1
                } else {
                    gimli::DW_OP_lit0
                };
                let Some(RegisterRule::ValExpression(expr)) =
                    row_at(&rows, ret_offset).register(Register(34))
                else {
                    panic!("missing return-address signing state");
                };
                assert_eq!(
                    &bytes[expr.offset..expr.offset + expr.length],
                    &[expected_sign.0]
                );
                let Some(RegisterRule::ValExpression(expr)) =
                    row_at(&rows, ret_offset + 4).register(Register(34))
                else {
                    panic!("missing restored return-address signing state");
                };
                assert_eq!(
                    &bytes[expr.offset..expr.offset + expr.length],
                    &[gimli::DW_OP_lit1.0]
                );
                assert_cfa(row_at(&rows, ret_offset), 31, 0);

                let prologue_only: Vec<_> = buffer
                    .unwind_info
                    .iter()
                    .filter(|(_, inst)| !matches!(inst, UnwindInst::SystemV(_)))
                    .cloned()
                    .collect();
                assert_eq!(
                    winarm64::create_unwind_info_from_insts(&buffer.unwind_info).unwrap(),
                    winarm64::create_unwind_info_from_insts(&prologue_only).unwrap(),
                );
            }
        }
    }

    #[test]
    fn test_framed_multi_return_rows() {
        let isa = lookup(triple!("aarch64"))
            .unwrap()
            .finish(Flags::new(builder()))
            .unwrap();
        let mut function = create_multi_return_function(CallConv::SystemV);
        function
            .sized_stack_slots
            .push(StackSlotData::new(StackSlotKind::ExplicitSlot, 64, 0));
        let mut context = Context::for_function(function);
        let code = context.compile(&*isa, &mut Default::default()).unwrap();
        let (_, rows) = rows_for_buffer(&code.buffer);
        let mut returns = 0;
        for (index, insn) in code.code_buffer().chunks_exact(4).enumerate() {
            if insn == 0xd65f03c0u32.to_le_bytes() {
                let offset = index * 4;
                assert_cfa(row_at(&rows, offset - 4), 29, 16);
                assert_cfa(row_at(&rows, offset), 31, 0);
                assert_eq!(
                    row_at(&rows, offset).register(Register(29)),
                    Some(RegisterRule::SameValue)
                );
                assert_eq!(
                    row_at(&rows, offset).register(Register(30)),
                    Some(RegisterRule::SameValue)
                );
                returns += 1;
            }
        }
        assert_eq!(returns, 2);
    }

    #[test]
    fn test_frameless_signed_multi_return_rows() {
        let mut isa = lookup(triple!("aarch64")).unwrap();
        isa.set("sign_return_address", "true").unwrap();
        isa.set("sign_return_address_all", "true").unwrap();
        isa.set("has_pauth", "false").unwrap();
        let isa = isa.finish(Flags::new(builder())).unwrap();
        let mut context = Context::for_function(create_multi_return_function(CallConv::SystemV));
        let code = context.compile(&*isa, &mut Default::default()).unwrap();
        let (bytes, rows) = rows_for_buffer(&code.buffer);
        let mut returns = 0;
        for (index, insn) in code.code_buffer().chunks_exact(4).enumerate() {
            if insn == 0xd65f03c0u32.to_le_bytes() {
                let ret = index * 4;
                // The second epilogue must start signed again, even though the
                // first epilogue changed the LR rule without popping a frame.
                for (offset, sign) in [(ret - 4, gimli::DW_OP_lit1), (ret, gimli::DW_OP_lit0)] {
                    let row = row_at(&rows, offset);
                    assert_cfa(row, 31, 0);
                    let Some(RegisterRule::ValExpression(expr)) = row.register(Register(34)) else {
                        panic!("missing return-address signing state");
                    };
                    assert_eq!(&bytes[expr.offset..expr.offset + expr.length], &[sign.0]);
                }
                returns += 1;
            }
        }
        assert_eq!(returns, 2);
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
