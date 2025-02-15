//===-- X86InstrVMX.td - TSX Instruction Set Extension -----*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file describes the instructions that make up the Intel TSX instruction
// set.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// TSX instructions

def X86xtest: SDNode<"X86ISD::XTEST", SDTypeProfile<1, 0, [SDTCisVT<0, i32>]>,
                     [SDNPHasChain, SDNPSideEffect]>;

let SchedRW = [WriteSystem] in {

let usesCustomInserter = 1 in
def XBEGIN : I<0, Pseudo, (outs GR32:$dst), (ins),
               "# XBEGIN", [(set GR32:$dst, (int_x86_xbegin))]>,
             Requires<[HasRTM]>;

let isBranch = 1, isTerminator = 1, Defs = [EAX] in {
def XBEGIN_2 : Ii16PCRel<0xc7, MRM_F8, (outs), (ins brtarget16:$dst),
                         "xbegin\t$dst", []>, OpSize16;
def XBEGIN_4 : Ii32PCRel<0xc7, MRM_F8, (outs), (ins brtarget32:$dst),
                         "xbegin\t$dst", []>, OpSize32;
}

// Pseudo instruction to fake the definition of EAX on the fallback code path.
let isPseudo = 1, Defs = [EAX] in {
def XABORT_DEF : I<0, Pseudo, (outs), (ins), "# XABORT DEF", []>;
}

def XEND : I<0x01, MRM_D5, (outs), (ins),
             "xend", [(int_x86_xend)]>, TB, PS, Requires<[HasRTM]>;

let Defs = [EFLAGS] in
def XTEST : I<0x01, MRM_D6, (outs), (ins),
              "xtest", [(set EFLAGS, (X86xtest))]>, TB, PS, Requires<[HasRTM]>;

def XABORT : Ii8<0xc6, MRM_F8, (outs), (ins i8imm:$imm),
                 "xabort\t$imm",
                 [(int_x86_xabort timm:$imm)]>, Requires<[HasRTM]>;
} // SchedRW

// HLE prefixes
let SchedRW = [WriteSystem] in {

// XACQUIRE and XRELEASE reuse REPNE and REP respectively.
// For now, just prefer the REP versions.
let isAsmParserOnly = 1 in {
def XACQUIRE_PREFIX : I<0xF2, PrefixByte, (outs), (ins), "xacquire", []>;
def XRELEASE_PREFIX : I<0xF3, PrefixByte, (outs), (ins), "xrelease", []>;
}

} // SchedRW
