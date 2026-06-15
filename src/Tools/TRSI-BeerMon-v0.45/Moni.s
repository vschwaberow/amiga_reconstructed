; ============================================================================
; Source  : Moni.s
; Reconstructed source for BeerMon V0.45 (aka "Moni"),
; a standalone low-level 680x0 machine code monitor and debugger.
; (C) Carnivore/BeerMacht, published by TRSI (1990-1993).
;
; Reverse engineering by Volker Schwaberow <volker@schwaberow.de>
;
; What this program is:
;   BeerMon is a great Amiga debug monitor once running it uses zero Kickstart, 
;   library or device calls. It can survive with the Kickstart ROM physically removed. 
;   It takes over the entire machine (display via direct bitplanes+copper, keyboard
;   via CIA, disk via raw MFM, exceptions via its own vectors).
; ============================================================================
ADKCON                         EQU     $09e           ; Audio, disk, and UART control register (write)
BLTADAT                        EQU     $074           ; Blitter source A data register
BLTAFWM                        EQU     $044           ; Blitter source A first word mask
BLTALWM                        EQU     $046           ; Blitter source A last word mask
BLTAMOD                        EQU     $064           ; Blitter source A modulo
BLTAPTH                        EQU     $04c           ; Blitter source A pointer (high 3 bits)
BLTBDAT                        EQU     $072           ; Blitter source B data register
BLTBMOD                        EQU     $062           ; Blitter source B modulo
BLTBPTH                        EQU     $050           ; Blitter source B pointer (high 3 bits)
BLTCDAT                        EQU     $070           ; Blitter source C data register
BLTCMOD                        EQU     $060           ; Blitter source C modulo
BLTCON0                        EQU     $040           ; Blitter control register 0
BLTCON1                        EQU     $042           ; Blitter control register 1
BLTDMOD                        EQU     $066           ; Blitter destination D modulo
BLTDPTH                        EQU     $054           ; Blitter destination D pointer (high 3 bits)
BLTSIZE                        EQU     $058           ; Blitter size / start blit
BPL1PTH                        EQU     $0e0           ; Bitplane 1 pointer (high 3 bits)
BPL1PTL                        EQU     $0e2           ; Bitplane 1 pointer (low 16 bits)
BPLCON0                        EQU     $100           ; Bitplane control register 0
BPLCON1                        EQU     $102           ; Bitplane control register 1
BPLCON2                        EQU     $104           ; Bitplane control register 2
CIAA                           EQU     $bfe000        ; CIA-A chip base address ($bfe000)
CIAA_PRA                       EQU     $bfe001
CIAA_PRB                       EQU     $bfe101
CIAB                           EQU     $bfd000        ; CIA-B chip base address ($bfd000)
CIAB_PRB                       EQU     $bfd100
CLXCON                         EQU     $094           ; Collision control register
COLOR00                        EQU     $180           ; Color palette register 0 (background)
COP1LC                         EQU     $080           ; Copper list 1 pointer
COP1LCH                        EQU     $080           ; Copper list 1 pointer (high 3 bits)
COP1LCL                        EQU     $082           ; Copper list 1 pointer (low 16 bits)
COP2LCH                        EQU     $084           ; Copper list 2 pointer (high 3 bits)
COP2LCL                        EQU     $086           ; Copper list 2 pointer (low 16 bits)
COPJMP1                        EQU     $088           ; Copper list 1 strobe trigger
CUSTOM                         EQU     $dff000        ; Amiga Custom Chip register base address ($dff000)
Decrypted_CommandEntry        EQU     Console_Callback_ModifyRegs+$a2
DENISEID                       EQU     $07c           ; Denise chip ID register
DMACON                         EQU     $096           ; DMA control write register
DMACONR                        EQU     $002           ; DMA control read register
DSKDIER                        EQU     $17e           ; Disk interrupt enable register
ExecBase                       EQU     $00000004      ; Exec library base pointer at address 4
FMODE                          EQU     $1fc           ; FMODE AGA fetch mode control register
GfxBase_ActiView               EQU     $26
INTENA                         EQU     $09a           ; Interrupt enable register (write)
INTREQ                         EQU     $09c           ; Interrupt request register (write)
LVO_CloseLibrary               EQU     -414
LVO_LoadView                   EQU     -270
LVO_OldOpenLibrary             EQU     -408
LVO_Supervisor                 EQU     -30
LVO_WaitTOF                    EQU     -222
POTGOR                         EQU     $016           ; Potentiometer port control register
POTGPTR                        EQU     $034           ; Potentiometer port status register
VHPOSR                         EQU     $006           ; Beam vertical/horizontal position read register
Var_Bitplane1                  EQU     $13ca
Var_Bitplane2                  EQU     $13ce
Var_Breakpoints                EQU     $1960
Var_BufferLength               EQU     $162c
Var_CaarSaved                  EQU     $142e
Var_CacrSaved                  EQU     $142a
Var_CharTranslationTable       EQU     $c7a
Var_CommandLine                EQU     $1d04
Var_ConsoleBuffer              EQU     $1e94
Var_CopHeight                  EQU     $13b8
Var_CopWidth                   EQU     $13b4
Var_CopperData                 EQU     $133e
Var_CopperList                 EQU     $13d2
Var_CpuStatus                  EQU     $1436
Var_CpuType                    EQU     $1657
Var_CursorX                    EQU     $165d
Var_CursorY                    EQU     $165c
Var_DelayCounter               EQU     $168c
Var_DeniseId                   EQU     $16cb
Var_DfcSaved                   EQU     $143b
Var_DisasmBuffer               EQU     $199c
Var_DisasmFlag                 EQU     $1668
Var_DisasmSize                 EQU     $1666
Var_ExceptionAddr              EQU     $164a
Var_ExceptionBkp               EQU     $1860
Var_ExceptionPC                EQU     $1652
Var_ExceptionSR                EQU     $1650
Var_ExceptionType              EQU     $1656
Var_ExceptionVO                EQU     $164c
Var_FKeyDefs                   EQU     $16d2
Var_EntryFlag                  EQU     $17fe
Var_FontData                   EQU     $4894
Var_FpuModel                   EQU     $1659
Var_FpuType                    EQU     $1658
Var_HardwareConfig             EQU     $161a
Var_HexChar_X                  EQU     $1680
Var_HexChar_Y                  EQU     $167f
Var_HexFormatFlag              EQU     $1681
Var_InputBuffer                EQU     $168e
Var_InputLength                EQU     $168d
Var_LockFlag                   EQU     $1688
Var_MemEnd                     EQU     $1824
Var_MemStart                   EQU     $1820
Var_MemoryAddr                 EQU     $1800
Var_MemoryBase                 EQU     $1808
Var_MemoryLayout               EQU     $167a
Var_MemoryLimit                EQU     $1804
Var_MenuIndex                  EQU     $1660
Var_MenuItem                   EQU     $1661
Var_MenuOpenFlag               EQU     $166b
Var_MenuSubItem                EQU     $1662
Var_MonitorActive              EQU     $167b
Var_MonitorBufferOffset        EQU     $3494
Var_MonitorFlag_166c EQU     $166c          
Var_MonitorFlag_166f EQU     $166f          
Var_MonitorFlag_1670 EQU     $1670          
Var_MonitorFlag_1679 EQU     $1679          
Var_MonitorLockState           EQU     $1685
Var_MonitorStackOffset_3768 EQU     $3768          
Var_MonitorStackOffset_376a EQU     $376a          
Var_MspSaved                   EQU     $1422
Var_NoSelfModifyFlag           EQU     $130e
Var_RegsSaved                  EQU     $13da
Var_SavedCursorPos             EQU     $165e
Var_SavedSSP                   EQU     $141e
Var_SavedUSP                   EQU     $141a
Var_ScreenBuf                  EQU     $13d6
Var_ScreenConfig               EQU     $1398
Var_ScreenDepth                EQU     $13b0
Var_ScreenFlags                EQU     $1663
Var_ScreenHeight               EQU     $16d0
Var_ScreenInfo                 EQU     $138a
Var_ScreenRefreshFlag          EQU     $168b
Var_ScreenRowPointer           EQU     $180c
Var_ScreenTimeout              EQU     $17fa
Var_ScreenWidth                EQU     $16ce
Var_ScreenX                    EQU     $139c
Var_ScreenY                    EQU     $13a0
Var_SfcSaved                   EQU     $143a
Var_SrpSaved                   EQU     $1432
Var_TaskFlag                   EQU     $1689
Var_TempMemPtr                 EQU     $1828
Var_UserA0                     EQU     $1412
Var_UserCAAR                   EQU     $160a
Var_UserCACR                   EQU     $1606
Var_UserDFC                    EQU     $1611
Var_UserMSP                    EQU     $15fe
Var_UserSFC                    EQU     $1610
Var_UserSP                     EQU     $1416
Var_UserSR                     EQU     $160e
Var_UserSSP                    EQU     $15fa
Var_UserUSP                    EQU     $15f6
Var_UserVBR                    EQU     $1602
Var_VblankFlag                 EQU     $165a
Var_VbrPointer                 EQU     $1426
Var_WindowFlags                EQU     $1664
Var_WindowPtr                  EQU     $163a

	SECTION Hunk_0_Code, CODE
	mc68030
	fpu

; ============================================================================
; ============================================================================
; Function: Start
; Purpose : Normal entry point when the monitor is started via JMP or from CLI.
;           Builds the monitor's private 32K context (a6 points near the end),
;           saves the caller's registers, marks this as non-exception entry,
;           and jumps into the common hardware takeover / CPU detection path.
; ============================================================================
Start:
	movem.l  a6,-(a7)                                    ; Move multiple registers a6 to -(a7)
	lea.l    Val_MonitorBaseOffset(pc),a6                ; Load address of Val_MonitorBaseOffset(pc) into monitor context base (a6)
	lea.l    $7ffe(a6),a6                                ; Offset base pointer to middle of 64KB variables space (for signed 16-bit access)
	movem.l  d0-d7/a0-a5,Var_RegsSaved(a6)               ; Save registers d0-d7/a0-a5 to context storage area
	suba.l   a1,a1                                       ; Subtract pointer a1 from pointer a1
	bra.b    CommonEntrySetup                            ; Unconditional branch to CommonEntrySetup
; ============================================================================
; Function: ExceptionEntry
; Purpose : Alternate entry point (placed 16 bytes after the normal one). Used by
;           the hardware "magic button", manually set vectors, or when we reroute
;           exceptions (illegal, trap, bus error, etc.) to the monitor. Pulls the
;           fault PC/SR from the stack frame into a4 and the context.
; ============================================================================
ExceptionEntry:
	movem.l  a6,-(a7)                                    ; Move multiple registers a6 to -(a7)
	lea.l    Val_MonitorBaseOffset(pc),a6                ; Load address of Val_MonitorBaseOffset(pc) into monitor context base (a6)
	lea.l    $7ffe(a6),a6                                ; Offset base pointer to middle of 64KB variables space (for signed 16-bit access)
	movem.l  d0-d7/a0-a5,Var_RegsSaved(a6)               ; Save registers d0-d7/a0-a5 to context storage area
	movem.l  $6(a7),a4                                   ; Move multiple registers $6(a7) to a4
	lea.l    -$1.w,a1                                    ; Load address of -$1.w into pointer a1
CommonEntrySetup:
	movem.w  a1,Var_EntryFlag(a6)                        ; Move multiple registers a1 to Var_EntryFlag(a6)
	movem.l  (a7)+,a0                                    ; Move multiple registers (a7)+ to a0
	movem.l  a0/a7,Var_UserA0(a6)                        ; Move multiple registers a0/a7 to Var_UserA0(a6)
	lea.l    $bfe000.l,a1                                ; Load address of $bfe000.l into pointer a1
	lea.l    $3.w,a3                                     ; Load address of $3.w into pointer a3
	lea.l    DMACONR.w,a2                                ; Load address of DMACON (DMA control write register) into pointer a2
	movem.w  a3,$200(a1)                                 ; Move multiple registers a3 to $200(a1)
	movem.w  a2,(a1)                                     ; Move multiple registers a2 to (a1)
	lea.l    -Var_MonitorStackOffset_376a(a6),a3         ; Load address of -Var_MonitorStackOffset_376a(a6) into pointer a3
	lea.l    $7ffe(a3),a7                                ; Initialize stack pointer to the top of the monitor's private stack
	bsr.w    GetVBR                                      ; Call subroutine to GetVBR
	move.l   a5,Var_VbrPointer(a6)                       ; Store pointer a5 into active Vector Base Register (VBR) pointer
	movea.l  a7,a3                                       ; Move stack pointer (a7) to pointer a3
	lea.l    $10.w,a0                                    ; Load address of $10.w into pointer a0
	adda.l   Var_VbrPointer(a6),a0                       ; Add active Vector Base Register (VBR) pointer to pointer a0
	movea.l  (a0),a1                                     ; Move (a0) to pointer a1
	lea.l    Handler_SupervisorTrick(pc),a2                            ; Load address of Handler_SupervisorTrick(pc) into pointer a2
	movem.l  a2,(a0)                                     ; Move multiple registers a2 to (a0)
	illegal  #$4afc                                      ; Trigger exception (illegal instruction)
	move.l   a7,Var_SavedSSP(a6)                         ; Store stack pointer (a7) into saved supervisor stack pointer
	move     usp,a7                                      ; Read User Stack Pointer (USP) into stack pointer (a7)
	move.l   a7,Var_SavedUSP(a6)                         ; Store stack pointer (a7) into saved user stack pointer
	movea.l  a3,a7                                       ; Move pointer a3 to stack pointer (a7)
	tst.b    Var_EntryFlag(a6)                     ; Check if entering via cold start or warm start/re-entry
	bne.b    SkipSrpClear                                ; Branch to SkipSrpClear if non-zero / not equal
	suba.l   a4,a4                                       ; Subtract pointer a4 from pointer a4
SkipSrpClear:
	movem.l  a4,Var_SrpSaved(a6)                         ; Save registers a4 to context storage area
	lea.l    $de0000.l,a2                                ; Load address of $de0000.l into pointer a2
	move.w   (a2),Var_HardwareConfig(a6)                 ; Store (a2) into Gary/hardware configuration status
	andi.w   #$7f7f,(a2)                                 ; Logical AND (a2) with constant $7f7f
	lea.l    CpuTypeDetectionDone(pc),a2                 ; Load address of CpuTypeDetectionDone(pc) into pointer a2
	move.l   a2,(a0)                                     ; Move pointer a2 to (a0)
	moveq    #$0,d6                                      ; Initialize register d6 to 0
	movec    vbr,a5                                      ; Read control register VBR into pointer a5
	move.l   a5,Var_VbrPointer(a6)                       ; Store pointer a5 into active Vector Base Register (VBR) pointer
	movec    sfc,d0                                      ; Read control register SFC into register d0
	move.b   d0,Var_SfcSaved(a6)                         ; Store register d0 into saved Source Function Code (SFC) state
	movec    dfc,d0                                      ; Read control register DFC into register d0
	move.b   d0,Var_DfcSaved(a6)                         ; Store register d0 into saved Destination Function Code (DFC) state
	moveq    #$1,d6                                      ; Initialize register d6 to 1
	movec    msp,a5                                      ; Read control register MSP into pointer a5
	move.l   a5,Var_MspSaved(a6)                         ; Store pointer a5 into saved Master Stack Pointer (MSP) state
	movec    cacr,a5                                     ; Read control register CACR into pointer a5
	move.l   a5,Var_CacrSaved(a6)                        ; Store pointer a5 into saved Cache Control Register (CACR) state
	move.l   a5,d7                                       ; Move pointer a5 to register d7
	bset     #$4,d7                                      ; Set bit #$4 of register d7
	bclr     #$0,d7                                      ; Clear bit #$0 of register d7
	movec    d7,cacr                                     ; Write control register CACR from register d7
	movec    cacr,d7                                     ; Read control register CACR into register d7
	movec    a5,cacr                                     ; Write control register CACR from pointer a5
	moveq    #$2,d6                                      ; Initialize register d6 to constant $2
	btst     #$4,d7                                      ; Test bit #$4 of register d7
	beq.b    CpuIs68000_010                              ; Branch to CpuIs68000_010 if zero / equal
	moveq    #$3,d6                                      ; Initialize register d6 to constant $3
CpuIs68000_010:
CpuIs040_MMUProbe:
	mc68040
	movec    urp,a5                                      ; Move urp to pointer a5
	mc68030
	moveq    #$4,d6                                      ; Initialize register d6 to constant $4
CpuTypeDetectionDone:
	movea.l  a3,a7                                       ; Move pointer a3 to stack pointer (a7)
	move.l   a1,(a0)                                     ; Move pointer a1 to (a0)
	move.b   d6,Var_CpuType(a6)                          ; Store register d6 into detected CPU type
	subq.b   #$2,d6                                      ; Subtract constant $2 from register d6
	beq.b    CpuIs020                                    ; Branch to CpuIs020 if zero / equal
	subq.b   #$1,d6                                      ; Subtract 1 from register d6
	bne.b    CpuIs010OrLess                              ; Branch to CpuIs010OrLess if non-zero / not equal
CpuIs020:
	movec    caar,a5                                     ; Read control register CAAR into pointer a5
	move.l   a5,Var_CaarSaved(a6)                        ; Store pointer a5 into saved Cache Address Register (CAAR) state
CpuIs010OrLess:
	move.w   Var_CpuStatus(a6),d0                        ; Load Var_CpuStatus(a6) into register d0
	lea.l    Var_UserSP(a6),a1                           ; Load address of Var_UserSP(a6) into pointer a1
	movea.l  (a1)+,a0                                    ; Move (a1)+ to pointer a0
	btst     #$d,d0                                      ; Test bit #$d of register d0
	beq.b    AfterUserSPAdjust                           ; Branch to AfterUserSPAdjust if zero / equal
	addq.w   #$4,a1                                      ; Add constant $4 to pointer a1
	btst     #$c,d0                                      ; Test bit #$c of register d0
	beq.b    AfterUserSPAdjust                           ; Branch to AfterUserSPAdjust if zero / equal
	addq.w   #$4,a1                                      ; Add constant $4 to pointer a1
AfterUserSPAdjust:
	move.l   a0,(a1)                                     ; Move pointer a0 to (a1)
	moveq    #$0,d6                                      ; Initialize register d6 to 0
	lea.l    $2c.w,a0                                    ; Load address of $2c.w into pointer a0
	adda.l   Var_VbrPointer(a6),a0                       ; Add active Vector Base Register (VBR) pointer to pointer a0
	movea.l  (a0),a1                                     ; Move (a0) to pointer a1
	lea.l    FpuProbe_ContinueAfterFsave(pc),a2          ; Load address of FpuProbe_ContinueAfterFsave(pc) into pointer a2
	move.l   a2,(a0)                                     ; Move pointer a2 to (a0)
	fsave    -(a7)                                       ; FPU operation: fsave -(a7)
	cmpi.b   #$4,Var_CpuType(a6)                         ; Compare detected CPU type against constant $4
	bne.b    FpuProbe_AssumeNoFpu                        ; Branch to FpuProbe_AssumeNoFpu if non-zero / not equal
	moveq    #$3,d6                                      ; Initialize register d6 to constant $3
	bra.b    FpuProbe_RestoreFrame                       ; Unconditional branch to FpuProbe_RestoreFrame
FpuProbe_AssumeNoFpu:
	moveq    #$1,d6                                      ; Initialize register d6 to 1
	cmpi.b   #$18,$1(a7)                                 ; Compare $1(a7) against constant $18
	beq.b    FpuProbe_RestoreFrame                       ; Branch to FpuProbe_RestoreFrame if zero / equal
	moveq    #$2,d6                                      ; Initialize register d6 to constant $2
FpuProbe_RestoreFrame:
	frestore (a7)+                                       ; FPU operation: frestore (a7)+
FpuProbe_ContinueAfterFsave:
	movea.l  a3,a7                                       ; Move pointer a3 to stack pointer (a7)
	move.b   d6,Var_FpuType(a6)                          ; Store register d6 into detected FPU type
	moveq    #$0,d6                                      ; Initialize register d6 to 0
	tst.b    $16ca(a6)                             ; Check if $16ca is set / active
	bne.b    FpuModel_Done                               ; Branch to FpuModel_Done if non-zero / not equal
	lea.l    FpuModel_Done(pc),a2                        ; Load address of FpuModel_Done(pc) into pointer a2
	move.l   a2,(a0)                                     ; Move pointer a2 to (a0)
	cmpi.b   #$4,Var_CpuType(a6)                         ; Compare detected CPU type against constant $4
	bne.b    FpuModel_Probe68030                         ; Branch to FpuModel_Probe68030 if non-zero / not equal
	moveq    #$3,d6                                      ; Initialize register d6 to constant $3
	bra.b    FpuModel_Done                               ; Unconditional branch to FpuModel_Done
FpuModel_Probe68030:
	lea.l    $15c8(a6),a2                                ; Load address of $15c8(a6) into pointer a2
	dc.w     $F012,$4200                           ; fmove.l (a2),fp4 (using coprocessor ID 0) - this can reveal which FPU responds
	moveq    #$1,d6                                      ; Initialize register d6 to 1
	dc.w     $F012,$0A00                           ; fmove fp2,fp4 (using coprocessor ID 0) - second probe instruction
	moveq    #$2,d6                                      ; Initialize register d6 to constant $2
FpuModel_Done:
	movea.l  a3,a7                                       ; Move pointer a3 to stack pointer (a7)
	move.l   a1,(a0)                                     ; Move pointer a1 to (a0)
	move.b   d6,Var_FpuModel(a6)                         ; Store register d6 into detected FPU model
	bsr.w    ConvertFPURegisters                         ; Call subroutine to ConvertFPURegisters
	bsr.w    SaveFPURegisters                            ; Call subroutine to SaveFPURegisters
	move.l   Var_SavedUSP(a6),Var_UserUSP(a6)            ; Store saved user stack pointer into saved user USP register state
	move.l   Var_SavedSSP(a6),Var_UserSSP(a6)            ; Store saved supervisor stack pointer into saved user SSP register state
	move.l   Var_MspSaved(a6),Var_UserMSP(a6)            ; Store saved Master Stack Pointer (MSP) state into saved user MSP register state
	move.l   Var_VbrPointer(a6),Var_UserVBR(a6)          ; Store active Vector Base Register (VBR) pointer into saved user VBR register state
	move.l   Var_CacrSaved(a6),Var_UserCACR(a6)          ; Store saved Cache Control Register (CACR) state into saved user CACR register state
	move.l   Var_CaarSaved(a6),Var_UserCAAR(a6)          ; Store saved Cache Address Register (CAAR) state into saved user CAAR register state
	move.w   Var_CpuStatus(a6),Var_UserSR(a6)            ; Store Var_CpuStatus(a6) into saved user status register (SR) state
	move.w   Var_SfcSaved(a6),Var_UserSFC(a6)            ; Store saved Source Function Code (SFC) state into saved user SFC register state
	lea.l    CUSTOM+2,a1                                 ; Load address of Amiga custom chip register base address ($dff000) into pointer a1
WaitBlitterIdle:
	btst     #$6,(a1)                                    ; Test bit #$6 of (a1)
	bne.b    WaitBlitterIdle                             ; Branch to WaitBlitterIdle if non-zero / not equal
	; === Save key custom chip registers with the classic $7fff set/clear dance ===
	; The $1612 area in the context block is the shadow for later restore on 'g'. We use set/clr form so we don't disturb bits we don't own.
	lea.l    $1612(a6),a0                                ; Load address of $1612(a6) into pointer a0
	moveq    #$7,d0                                      ; Initialize register d0 to constant $7
	move.w   (a1),(a0)+                                  ; Move (a1) to (a0)+
	bset     d0,-DMACONR(a0)                             ; Set bit d0 of DMACON (DMA control write register)
	move.w   $e(a1),(a0)+                                ; Move $e(a1) to (a0)+
	bset     d0,-DMACONR(a0)                             ; Set bit d0 of DMACON (DMA control write register)
	move.w   $1a(a1),(a0)+                               ; Move $1a(a1) to (a0)+
	bset     d0,-DMACONR(a0)                             ; Set bit d0 of DMACON (DMA control write register)
	move.w   $1c(a1),(a0)+                               ; Move $1c(a1) to (a0)+
	bset     d0,-DMACONR(a0)                             ; Set bit d0 of DMACON (DMA control write register)
	; Now issue the big "turn everything off" writes (the $7fff masks are the standard nasty-monitor way to clear without knowing previous enables)
	move.l   #$7fff7fff,$98(a1)                          ; Move constant $7fff7fff to $98(a1)
	move.w   #$7fff,CLXCON(a1)                           ; Move disable all / mask to CLXCON(a1)
	moveq    #$0,d0                                      ; Initialize register d0 to 0
	move.w   d0,POTGPTR(a1)                              ; Move register d0 to POTGPTR (potentiometer port status register)
	move.w   d0,DSKDIER(a1)                              ; Move register d0 to DSKDIER (disk interrupt enable register)
	; Denise ID tells us OCS vs ECS vs AGA for proper vblank timing and screen setup later
	move.w   DENISEID(a1),d0                             ; Move DENISEID (Denise chip ID register) to register d0
	cmpi.b   #$f8,d0                                     ; Compare register d0 against constant $f8
	bne.b    DeniseIdCheck                               ; Branch to DeniseIdCheck if non-zero / not equal
	move.w   #$0,FMODE(a1)                               ; Move 0 to FMODE (AGA fetch mode control register)
DeniseIdCheck:
	moveq    #$2c,d1                                     ; Initialize register d1 to constant $2c
	moveq    #$20,d0                                     ; Initialize register d0 to constant $20
	move.b   Var_DeniseId(a6),d2                         ; Load Var_DeniseId(a6) into register d2
	cmpi.b   #$2,d2                                      ; Compare register d2 against constant $2
	bls.b    DeniseId_SetVblankMethod
	subq.b   #$3,d2                                      ; Subtract constant $3 from register d2
DeniseId_SetVblankMethod:
	tst.b    d2                                          ; Test status of register d2 (for zero or negative)
	beq.b    DeniseId_UseBlitterBusy                     ; Branch to DeniseId_UseBlitterBusy if zero / equal
	subq.b   #$1,d2                                      ; Subtract 1 from register d2
	seq.b    Var_VblankFlag(a6)                    ; Remember which vblank detection method we will use in the copper / refresh loop
	beq.b    DeniseId_SetPotForVblank                    ; Branch to DeniseId_SetPotForVblank if zero / equal
	move.w   #$0,$1da(a1)                                ; Move 0 to $1da(a1)
	bra.b    DeniseId_SaveScreenConfig                   ; Unconditional branch to DeniseId_SaveScreenConfig
DeniseId_SetPotForVblank:
	move.w   #$20,$1da(a1)                               ; Move constant $20 to $1da(a1)
	bra.b    DeniseId_SaveMenuDefaults                   ; Unconditional branch to DeniseId_SaveMenuDefaults
DeniseId_UseBlitterBusy:
	btst     #$4,DMACONR(a1)                             ; Test bit #$4 of DMACON (DMA control write register)
	seq.b    Var_VblankFlag(a6)
	beq.b    DeniseId_SaveMenuDefaults                   ; Branch to DeniseId_SaveMenuDefaults if zero / equal
DeniseId_SaveScreenConfig:
	moveq    #-12,d1                                     ; Initialize register d1 to constant -12
	moveq    #$19,d0                                     ; Initialize register d0 to constant $19
DeniseId_SaveMenuDefaults:
	move.b   d1,Var_ScreenConfig(a6)                     ; Store register d1 into Var_ScreenConfig(a6)
	move.b   d0,Var_MenuIndex(a6)                        ; Store register d0 into active menu header index
	subq.b   #$1,d0                                      ; Subtract 1 from register d0
	move.b   d0,Var_MenuItem(a6)                         ; Store register d0 into active menu item index
	subq.b   #$1,d0                                      ; Subtract 1 from register d0
	move.b   d0,Var_MenuSubItem(a6)                      ; Store register d0 into Var_MenuSubItem(a6)
	moveq    #$8,d3                                      ; Initialize register d3 to constant $8
	swap     d3
	move.l   d3,Var_MemoryLimit(a6)                      ; Store register d3 into upper bound of monitored memory
	move.l   #$74000,Var_MemoryBase(a6)                  ; Store constant $74000 into base address of monitored memory
	btst     #$5,DMACONR(a1)                             ; Test bit #$5 of DMACON (DMA control write register)
	beq.b    MemoryProbe_ChipOnly                        ; Branch to MemoryProbe_ChipOnly if zero / equal
	bsr.w    TestMemoryWritable                          ; Call subroutine to TestMemoryWritable
	beq.b    MemoryProbe_ChipOnly                        ; Branch to MemoryProbe_ChipOnly if zero / equal
	moveq    #$10,d3                                     ; Initialize register d3 to constant $10
	swap     d3
	move.l   d3,Var_MemoryLimit(a6)                      ; Store register d3 into upper bound of monitored memory
	move.l   #$f4000,Var_MemoryBase(a6)                  ; Store constant $f4000 into base address of monitored memory
	bsr.w    TestMemoryWritable                          ; Call subroutine to TestMemoryWritable
	beq.b    MemoryProbe_ChipOnly                        ; Branch to MemoryProbe_ChipOnly if zero / equal
	moveq    #$18,d3                                     ; Initialize register d3 to constant $18
	swap     d3
	move.l   d3,Var_MemoryLimit(a6)                      ; Store register d3 into upper bound of monitored memory
	move.l   #$174000,Var_MemoryBase(a6)                 ; Store constant $174000 into base address of monitored memory
	bsr.w    TestMemoryWritable                          ; Call subroutine to TestMemoryWritable
	beq.b    MemoryProbe_ChipOnly                        ; Branch to MemoryProbe_ChipOnly if zero / equal
	move.l   #$200000,Var_MemoryLimit(a6)                ; Store constant $200000 into upper bound of monitored memory
	move.l   #$1f4000,Var_MemoryBase(a6)                 ; Store constant $1f4000 into base address of monitored memory
MemoryProbe_ChipOnly:
	movea.l  Var_MemoryBase(a6),a0                       ; Load base address of monitored memory into pointer a0
	lea.l    $7494.l,a1                                  ; Load address of $7494.l into pointer a1
	cmpa.l   a0,a1                                       ; Compare pointer a1 against pointer a0
	bls.b    MemoryProbe_CheckKickstartOverlap
	adda.l   #$b40c,a0                                   ; Add constant $b40c to pointer a0
	lea.l    Start(pc),a1                                ; Load address of Start(pc) into pointer a1
	cmpa.l   a0,a1                                       ; Compare pointer a1 against pointer a0
	bcc.b    MemoryProbe_CheckKickstartOverlap           ; Branch to MemoryProbe_CheckKickstartOverlap if carry clear (greater or equal)
	suba.l   #$b40c,a1                                   ; Subtract constant $b40c from pointer a1
	move.l   a1,Var_MemoryBase(a6)                       ; Store pointer a1 into base address of monitored memory
MemoryProbe_CheckKickstartOverlap:
	st.b     Var_MemoryLayout(a6)                  ; Mark that we are using the "standard" layout for now
	bsr.w    VerifyExecBase                              ; Call subroutine to VerifyExecBase
	bne.b    MemoryProbe_Done                            ; Branch to MemoryProbe_Done if non-zero / not equal
	movea.l  $142(a0),a1                                 ; Move $142(a0) to pointer a1
	moveq    #$1,d1                                      ; Initialize register d1 to 1
	bsr.w    VerifyLibraryNode                           ; Call subroutine to VerifyLibraryNode
	beq.b    MemoryProbe_SaveExecBase                    ; Branch to MemoryProbe_SaveExecBase if zero / equal
	move.l   Var_MemoryLimit(a6),d0                      ; Load upper bound of monitored memory into register d0
	subi.l   #$b40c,d0                                   ; Subtract constant $b40c from register d0
	cmpa.l   d0,a1                                       ; Compare pointer a1 against register d0
	bhi.b    MemoryProbe_SaveExecBase
	move.l   a1,Var_MemoryBase(a6)                       ; Store pointer a1 into base address of monitored memory
	sf.b     Var_MemoryLayout(a6)
MemoryProbe_SaveExecBase:
	clr.l    Var_MemoryAddr(a6)                          ; Clear / reset active memory view pointer
	movea.l  $142(a0),a1                                 ; Move $142(a0) to pointer a1
	moveq    #$2,d1                                      ; Initialize register d1 to constant $2
	bsr.w    VerifyLibraryNode                           ; Call subroutine to VerifyLibraryNode
	beq.b    MemoryProbe_Done                            ; Branch to MemoryProbe_Done if zero / equal
	move.l   a1,Var_MemoryAddr(a6)                       ; Store pointer a1 into active memory view pointer
MemoryProbe_Done:
	st.b     Var_MonitorActive(a6)                 ; We are now fully in control; main monitor flag
	move.l   Var_MemoryAddr(a6),d4                       ; Load active memory view pointer into register d4
	move.l   #$f13496,d3                                 ; Move constant $f13496 to register d3
	bsr.b    TestMemoryWritable                          ; Call subroutine to TestMemoryWritable
	bne.w    WaitForLeftMouseButton                      ; Branch to WaitForLeftMouseButton if non-zero / not equal
	move.l   d4,Var_MemoryAddr(a6)                       ; Store register d4 into active memory view pointer
	lea.l    CIAA_PRA.l,a0                               ; Load address of CIAA_PRA (CIA-A Port A status register) into pointer a0
	btst     #$6,(a0)                                    ; Test bit #$6 of (a0)
	bne.b    MemoryTest_Failed                           ; Branch to MemoryTest_Failed if non-zero / not equal
	clr.l    Var_MemoryAddr(a6)                          ; Clear / reset active memory view pointer
	lea.l    $dff006.l,a1                                ; Load address of $dff006.l into pointer a1
	lea.l    $17a(a1),a2                                 ; Load address of $17a(a1) into pointer a2
WaitForRasterPulse:
	move.b   (a1),(a2)                                   ; Move (a1) to (a2)
	btst     #$6,(a0)                                    ; Test bit #$6 of (a0)
	beq.b    WaitForRasterPulse                          ; Branch to WaitForRasterPulse if zero / equal
	bra.b    WaitForLeftMouseButton                      ; Unconditional branch to WaitForLeftMouseButton
MemoryTest_Failed:
	tst.l    Var_MemoryAddr(a6)                          ; Test status of active memory view pointer (for zero or negative)
	seq.b    Var_MonitorActive(a6)
	bne.b    WaitForLeftMouseButton                      ; Branch to WaitForLeftMouseButton if non-zero / not equal
	move.l   #$274000,d3                                 ; Move constant $274000 to register d3
	bsr.b    TestMemoryWritable                          ; Call subroutine to TestMemoryWritable
	bne.b    WaitForLeftMouseButton                      ; Branch to WaitForLeftMouseButton if non-zero / not equal
	move.l   #$c74000,d3                                 ; Move constant $c74000 to register d3
	bsr.b    TestMemoryWritable                          ; Call subroutine to TestMemoryWritable
	bne.b    WaitForLeftMouseButton                      ; Branch to WaitForLeftMouseButton if non-zero / not equal
	cmpi.w   #$8,Var_MemoryLimit(a6)                     ; Compare upper bound of monitored memory against constant $8
	bne.b    WaitForLeftMouseButton                      ; Branch to WaitForLeftMouseButton if non-zero / not equal
	move.l   #$f4000,d3                                  ; Move constant $f4000 to register d3
	pea.l    WaitForLeftMouseButton(pc)
; ============ TestMemoryWritable
; Purpose: Non-destructive probe for presence of RAM at a candidate address (d3). Writes two magic longwords
;   ("beer" / "gore"), does 040/020 cache flushes so Agnus sees them, compares, then restores original contents.
;   Sets Var_MemoryAddr on success. Used repeatedly during entry to size Chip + any Fast RAM while the
;   machine is in an unknown state (no OS, possible MMU, caches on).
TestMemoryWritable:
	movea.l  d3,a2                                       ; Move register d3 to pointer a2
	andi.l   #$f80000,d3                                 ; Logical AND register d3 with constant $f80000
	clr.l    Var_MemoryAddr(a6)                          ; Clear / reset active memory view pointer
	suba.l   a1,a1                                       ; Subtract pointer a1 from pointer a1
	movea.l  d3,a0                                       ; Move register d3 to pointer a0
	move.l   (a0),d6                                     ; Move (a0) to register d6
	move.l   (a1),d7                                     ; Move (a1) to register d7
	move.l   #$62656572,d3                               ; Move constant $62656572 to register d3
	move.l   #$676f7265,d1                               ; Move constant $676f7265 to register d1
	move.l   d3,(a1)                                     ; Move register d3 to (a1)
	move.l   d1,(a0)                                     ; Move register d1 to (a0)
	bsr.w    CacheFlush_040                              ; Call subroutine to CacheFlush_040
	bsr.w    CacheFlush_020_030                          ; Call subroutine to CacheFlush_020_030
	cmp.l    (a0),d1                                     ; Compare register d1 against (a0)
	bne.b    MemoryTest_NotWritable                      ; Branch to MemoryTest_NotWritable if non-zero / not equal
	cmp.l    (a1),d3                                     ; Compare register d3 against (a1)
	bne.b    MemoryTest_NotWritable                      ; Branch to MemoryTest_NotWritable if non-zero / not equal
	move.l   a2,Var_MemoryAddr(a6)                       ; Store pointer a2 into active memory view pointer
MemoryTest_NotWritable:
	move.l   d6,(a0)                                     ; Move register d6 to (a0)
	move.l   d7,(a1)                                     ; Move register d7 to (a1)
	bsr.w    CacheFlush_040                              ; Call subroutine to CacheFlush_040
	bsr.w    CacheFlush_020_030                          ; Call subroutine to CacheFlush_020_030
	tst.l    Var_MemoryAddr(a6)                          ; Test status of active memory view pointer (for zero or negative)
	rts                                                  ; Return from subroutine
WaitForLeftMouseButton:
	move.l   Var_MemoryAddr(a6),Var_TempMemPtr(a6)       ; Store active memory view pointer into temporary memory workspace pointer
	beq.b    AfterMemoryProbe                            ; Branch to AfterMemoryProbe if zero / equal
	movea.l  Var_MemoryBase(a6),a0                       ; Load base address of monitored memory into pointer a0
	move.l   a0,Var_MemStart(a6)                         ; Store pointer a0 into monitored memory start offset
	adda.l   #$b40c,a0                                   ; Add constant $b40c to pointer a0
	move.l   a0,Var_MemEnd(a6)                           ; Store pointer a0 into monitored memory end offset
	moveq    #$3,d3                                      ; Initialize register d3 to constant $3
	bsr.w    Memory_MoveOverlapSafe                      ; Call subroutine to Memory_MoveOverlapSafe
AfterMemoryProbe:
	movea.l  Var_VbrPointer(a6),a0                       ; Load active Vector Base Register (VBR) pointer into pointer a0
	lea.l    Var_ExceptionBkp(a6),a1                     ; Load address of Var_ExceptionBkp(a6) into pointer a1
	moveq    #$3f,d0                                     ; Initialize register d0 to constant $3f
SaveOriginalVectors:
	move.l   (a0)+,(a1)+                                 ; Copy word/byte data from source pointer a0 to destination a1
	dbra     d0,SaveOriginalVectors                      ; Decrement loop counter d0 and loop back to SaveOriginalVectors if not exhausted
	lea.l    CIAB_PRB.l,a0                               ; Load address of CIAB_PRB (CIA-B Port B data/control register) into pointer a0
	st.b     $200(a0)
	st.b     (a0)
	nop                                                  ; No operation (timing delay)
	move.b   #$87,(a0)                                   ; Move constant $87 to (a0)
	nop                                                  ; No operation (timing delay)
	st.b     (a0)
	moveq    #-1,d0                                      ; Initialize register d0 to constant -1
	move.l   d0,Var_ScreenTimeout(a6)                    ; Store register d0 into screen inactivity/dim timer
	lea.l    Var_CommandLine(a6),a0                      ; Load address of console command line input buffer into pointer a0
	move.w   #$63,d0                                     ; Move constant $63 to register d0
ClearCommandLineBuffer:
	clr.l    (a0)+                                       ; Clear / reset (a0)+
	dbra     d0,ClearCommandLineBuffer                   ; Decrement loop counter d0 and loop back to ClearCommandLineBuffer if not exhausted
	lea.l    SectorVerify_BranchOffset(pc),a1                            ; Load address of SectorVerify_BranchOffset(pc) into pointer a1
	lea.l    $7ffe(a1),a1                                ; Offset pointer to target main menu template string (bypasses 32KB PC-relative limit)
	move.l   a1,Var_WindowPtr(a6)                        ; Store pointer a1 into pointer to active window context
	sf.b     Var_WindowFlags(a6)
	sf.b     Var_ScreenFlags(a6)
	sf.b     Var_CursorY(a6)
	move.l   Var_MemoryBase(a6),d0                       ; Load base address of monitored memory into register d0
	bra.w    SetupScreenResources                        ; Unconditional branch to SetupScreenResources
Monitor_WarmStart:  ; Path used on certain re-entries or after a Go that needs to re-initialize the monitor UI without full cold start
	lea.l    -Var_MonitorStackOffset_3768(a6),a2         ; Load address of -Var_MonitorStackOffset_3768(a6) into pointer a2
	lea.l    $7ff8(a2),a7                                ; Load address of $7ff8(a2) into stack pointer (a7)
	move.l   Var_SrpSaved(a6),Var_MemStart(a6)           ; Store saved exception instruction PC (SRP) into monitored memory start offset
	lea.l    CUSTOM.l,a2                                 ; Load address of Amiga custom chip register base address ($dff000) into pointer a2
	move.l   #$7fff7fff,INTENA(a2)                 ; Disable all interrupts and DMA channels
	move.w   #$c00,POTGPTR(a2)                           ; Move constant $c00 to POTGPTR (potentiometer port status register)
	lea.l    $bfd000.l,a0                                ; Load address of $bfd000.l into pointer a0
	move.b   #$3,$1201(a0)                               ; Move constant $3 to $1201(a0)
	st.b     $1301(a0)
	st.b     $300(a0)
	sf.b     $1c01(a0)
	move.b   #COP1LC,$1e01(a0)                     ; Trigger custom Copper list to display monitor screen
	move.b   #COPJMP1,$1d01(a0)                          ; Move COPJMP1 (copper list 1 strobe trigger) to $1d01(a0)
	tst.b    $1d01(a0)                                   ; Test status of $1d01(a0) (for zero or negative)
	sf.b     $e00(a0)
	move.b   #$7f,$d00(a0)                               ; Move constant $7f to $d00(a0)
	tst.b    $d00(a0)                                    ; Test status of $d00(a0) (for zero or negative)
	lea.l    Exception_VectorBranchTable(pc),a0                            ; Load address of Exception_VectorBranchTable(pc) into pointer a0
	lea.l    $8.w,a1                                     ; Load address of $8.w into pointer a1
	adda.l   Var_VbrPointer(a6),a1                       ; Add active Vector Base Register (VBR) pointer to pointer a1
	moveq    #$3d,d0                                     ; Initialize register d0 to constant $3d
InstallOurExceptionVectors:
	move.l   a0,(a1)+                                    ; Move pointer a0 to (a1)+
	adda.w   #$2,a0                                      ; Add constant $2 to pointer a0
	dbra     d0,InstallOurExceptionVectors               ; Decrement loop counter d0 and loop back to InstallOurExceptionVectors if not exhausted
	sf.b     Var_LockFlag(a6)
	sf.b     Var_TaskFlag(a6)
	lea.l    $68.w,a1                                    ; Load address of $68.w into pointer a1
	adda.l   Var_VbrPointer(a6),a1                       ; Add active Vector Base Register (VBR) pointer to pointer a1
	lea.l    Level2InterruptHandler(pc),a3               ; Load address of Level2InterruptHandler(pc) into pointer a3
	lea.l    Level3InterruptHandler(pc),a4               ; Load address of Level3InterruptHandler(pc) into pointer a4
	lea.l    Level4InterruptHandler(pc),a5               ; Load address of Level4InterruptHandler(pc) into pointer a5
	movem.l  a3-a5,(a1)                                  ; Move multiple registers a3-a5 to (a1)
	lea.l    ExceptionEntry(pc),a0                       ; Load address of ExceptionEntry(pc) into pointer a0
	move.l   a0,$14(a1)                                  ; Move pointer a0 to $14(a1)
	lea.l    Var_CopperData(a6),a0                       ; Load address of Var_CopperData(a6) into pointer a0
	movea.l  Var_CopperList(a6),a1                       ; Load Var_CopperList(a6) into pointer a1
	moveq    #$25,d0                                     ; Initialize register d0 to constant $25
CopyCopperListLoop:
	move.w   (a0)+,(a1)+                                 ; Copy word/byte data from source pointer a0 to destination a1
	dbra     d0,CopyCopperListLoop                       ; Decrement loop counter d0 and loop back to CopyCopperListLoop if not exhausted
	movem.w  Var_ScreenWidth(a6),d0-d1                   ; Move multiple registers Var_ScreenWidth(a6) to d0-d1
	move.w   d0,Var_CopWidth(a6)                         ; Store register d0 into copper display width (pixels)
	move.w   d1,Var_CopHeight(a6)                        ; Store register d1 into copper display height (pixels)
	move.l   #$38003c,d0                                 ; Move constant $38003c to register d0
	move.l   #$d800d4,d1                                 ; Move constant $d800d4 to register d1
	move.l   #$fff80000,d2                               ; Move constant $fff80000 to register d2
	move.w   d0,Var_ScreenX(a6)                          ; Store register d0 into screen horizontal display offset
	move.w   d1,Var_ScreenY(a6)                          ; Store register d1 into screen vertical display offset
	move.w   d2,Var_ScreenDepth(a6)                      ; Store register d2 into screen bitplane depth
	lea.l    Var_ScreenInfo(a6),a1                       ; Load address of Var_ScreenInfo(a6) into pointer a1
	move.l   Var_Bitplane1(a6),d0                        ; Load first bitplane memory pointer into register d0
	move.w   d0,VHPOSR(a1)                               ; Move register d0 to VHPOSR (beam vertical/horizontal position read)
	swap     d0
	move.w   d0,DMACONR(a1)                              ; Set DMA control (DMACON) bits to register d0
	movea.l  Var_ScreenBuf(a6),a0                        ; Load screen character buffer pointer into pointer a0
	moveq    #$3f,d0                                     ; Initialize register d0 to constant $3f
CopyScreenInfoLoop:
	move.b   (a1)+,(a0)+                                 ; Copy word/byte data from source pointer a1 to destination a0
	dbra     d0,CopyScreenInfoLoop                       ; Decrement loop counter d0 and loop back to CopyScreenInfoLoop if not exhausted
	bsr.w    CacheFlush_040                              ; Call subroutine to CacheFlush_040
	move.w   #$c028,INTENA(a2)                           ; Enable VBlank, Keyboard Ports, and Master interrupts
Monitor_WaitVBlank:
	btst     #$5,$1f(a2)                           ; Wait for vertical blanking active state
	beq.w    Monitor_WaitVBlank                          ; Branch to Monitor_WaitVBlank if zero / equal
	tst.b    Var_EntryFlag(a6)                     ; Check if entering via cold start or warm start/re-entry
	bne.b    Monitor_InitDisplayDMA                      ; Branch to Monitor_InitDisplayDMA if non-zero / not equal
	move.l   Var_ScreenBuf(a6),COP1LC(a2)                ; Load screen character buffer pointer into COP1LC (copper list 1 pointer high/low)
	tst.w    COPJMP1(a2)                           ; Check if COPJMP1 is set / active
	move.w   #$8080,DMACON(a2)                     ; Enable screen display and Copper DMA
Monitor_InitDisplayDMA:
	move.w   #$8340,DMACON(a2)                     ; Enable screen display and Copper DMA
	move.w   #$2000,sr                                   ; Switch CPU to supervisor mode, enabling interrupts
	sf.b     Var_ScreenFlags(a6)                   ; Clear screen display mode flags flag (false).
	sf.b     Var_CursorX(a6)                       ; Clear cursor X coordinate flag (false).
	moveq    #$0,d3                                      ; Initialize register d3 to 0
	bsr.w    Command_ModifyRegister                      ; Call subroutine to Command_ModifyRegister
	bsr.b    CalculateSelfChecksum                       ; Call subroutine to CalculateSelfChecksum
	lea.l    Monitor_DecryptCode_Continue(pc),a0         ; Load address of Monitor_DecryptCode_Continue(pc) into pointer a0
	lea.l    $7ffe(a0),a0                                ; Offset pointer to target self-checksum reference value (bypasses 32KB PC-relative limit)
	cmp.l    (a0),d0                                     ; Compare register d0 against (a0)
	beq.b    MainMonitorInputLoop_Start                  ; Branch to MainMonitorInputLoop_Start if zero / equal
	lea.l    Str_WarningCorrupted(pc),a1                            ; Load address of Str_WarningCorrupted(pc) into pointer a1
	bsr.w    PrintString                                 ; Call subroutine to PrintString
MainMonitorInputLoop_Start:
	bsr.w    Console_DrawCursor                          ; Call subroutine to Console_DrawCursor
	bsr.w    UnlockMonitor                               ; Call subroutine to UnlockMonitor
	clr.w    Var_BufferLength(a6)                        ; Clear / reset keyboard input buffer character count
MainMonitorInputLoop_Wait:
	tst.w    Var_BufferLength(a6)                  ; Check if Var_BufferLength is set / active
	beq.b    MainMonitorInputLoop_Wait                   ; Branch to MainMonitorInputLoop_Wait if zero / equal
	bsr.w    LockMonitor                                 ; Call subroutine to LockMonitor
	clr.w    d1                                          ; Clear / reset register d1
	lea.l    Var_InputBuffer(a6),a0                      ; Load address of keyboard input buffer into pointer a0
MainMonitorInputLoop_Process:
	move.b   (a0,d1.w),d0                                ; Move (a0,d1.w) to register d0
	bsr.w    ProcessInputChar                            ; Call subroutine to ProcessInputChar
	addq.w   #$1,d1                                      ; Add 1 to register d1
	cmp.w    Var_BufferLength(a6),d1                     ; Compare register d1 against keyboard input buffer character count
	bcs.b    MainMonitorInputLoop_Process                ; Branch to MainMonitorInputLoop_Process if carry set (less than)
	clr.w    Var_BufferLength(a6)                        ; Clear / reset keyboard input buffer character count
	bsr.w    UnlockMonitor                               ; Call subroutine to UnlockMonitor
	bra.b    MainMonitorInputLoop_Wait                   ; Unconditional branch to MainMonitorInputLoop_Wait
; ============================================================================
; Function: CalculateSelfChecksum
; Purpose : Computes additive checksum over monitor code to detect self-modification.
; ============================================================================
CalculateSelfChecksum:
	moveq    #$0,d0                                      ; Initialize register d0 to 0
	lea.l    Start(pc),a0                                ; Load address of Start(pc) into pointer a0
	move.w   #$349d,d1                                   ; Move constant $349d to register d1
CalculateSelfChecksum_Loop:
	add.l    (a0)+,d0                                    ; Add (a0)+ to register d0
	dbra     d1,CalculateSelfChecksum_Loop               ; Decrement loop counter d1 and loop back to CalculateSelfChecksum_Loop if not exhausted
	rts                                                  ; Return from subroutine
; ============================================================================
; Data Block: Str_WarningCorrupted
; Purpose   : Warning string printed when BeerMon self-checksum fails.
; ============================================================================
Str_WarningCorrupted:
	dc.b     "Warning:BeerMon is corrupte",$E4     ; String literal data
; ============================================================================
; Function: ExitMonitor
; Purpose : Restores the user program's registers, stack pointers, caches, and resumes execution.
; ============================================================================
ExitMonitor:	moveq    #$3,d2
	move.l   Var_ScreenTimeout(a6),d3                    ; Load screen inactivity/dim timer into register d3
ExitMonitor_Loc_061E:	tst.b    d3
	bmi.b    ExitMonitor_Loc_0640                        ; Branch to ExitMonitor_Loc_0640 if negative / minus
	moveq    #$3,d0                                      ; Initialize register d0 to constant $3
	add.b    d2,d0                                       ; Add register d2 to register d0
	move.b   d0,Var_MonitorFlag_166c(a6)                 ; Store register d0 into Var_MonitorFlag_166c(a6)
	bsr.w    Disk_SelectDriveAndMotorOn                  ; Call subroutine to Disk_SelectDriveAndMotorOn
	bsr.w    Disk_SeekTrack0                             ; Call subroutine to Disk_SeekTrack0
ExitMonitor_Loc_0632:	subq.b   #$1,d3
	bmi.b    ExitMonitor_Loc_063C                        ; Branch to ExitMonitor_Loc_063C if negative / minus
	bsr.w    Disk_StepOut                                ; Call subroutine to Disk_StepOut
	bra.b    ExitMonitor_Loc_0632                        ; Unconditional branch to ExitMonitor_Loc_0632
ExitMonitor_Loc_063C:	bsr.w    Disk_MotorOff
ExitMonitor_Loc_0640:	ror.l    #$8,d3
	dbra     d2,ExitMonitor_Loc_061E                     ; Decrement loop counter d2 and loop back to ExitMonitor_Loc_061E if not exhausted
	move.w   #$7fff,DMACON+CUSTOM.l                      ; Disable all custom chip DMA channels
	move.w   #$4000,INTENA+CUSTOM.l                      ; Set INTENA interrupt enable bits to constant $4000
	move.w   Var_HardwareConfig(a6),$de0000.l            ; Load Gary/hardware configuration status into $de0000.l
	move.l   Var_MemoryAddr(a6),d0                       ; Load active memory view pointer into register d0
	beq.b    ExitMonitor_RestoreExceptionVectors         ; Branch to ExitMonitor_RestoreExceptionVectors if zero / equal
	move.l   d0,Var_MemStart(a6)                         ; Store register d0 into monitored memory start offset
	addi.l   #$b40c,d0                                   ; Add constant $b40c to register d0
	move.l   d0,Var_MemEnd(a6)                           ; Store register d0 into monitored memory end offset
	move.l   Var_Bitplane1(a6),Var_TempMemPtr(a6)        ; Store first bitplane memory pointer into temporary memory workspace pointer
	moveq    #$3,d3                                      ; Initialize register d3 to constant $3
	bsr.w    Memory_MoveOverlapSafe                      ; Call subroutine to Memory_MoveOverlapSafe
ExitMonitor_RestoreExceptionVectors:	lea.l    Var_ExceptionBkp(a6),a0               ; Load address of Var_ExceptionBkp into a0
	movea.l  Var_UserVBR(a6),a1                          ; Load saved user VBR register state into pointer a1
	moveq    #$3f,d0                                     ; Initialize register d0 to constant $3f
ExitMonitor_RestoreExceptionVectors_Loop:	move.l   (a0)+,(a1)+
	dbra     d0,ExitMonitor_RestoreExceptionVectors_Loop ; Decrement loop counter d0 and loop back to ExitMonitor_RestoreExceptionVectors_Loop if not exhausted
	bsr.w    SetupFPUSafetyHandler                       ; Call subroutine to SetupFPUSafetyHandler
	bsr.w    RestoreFPURegisters                         ; Call subroutine to RestoreFPURegisters
	tst.b    Var_EntryFlag(a6)                     ; Check if entering via cold start or warm start/re-entry
	bne.w    RestoreUserContextAndRte                    ; Branch to RestoreUserContextAndRte if non-zero / not equal
	lea.l    Start(pc),a0                                ; Load address of Start(pc) into pointer a0
	cmpa.l   #$f00002,a0                                 ; Compare pointer a0 against constant $f00002
	beq.w    Decrypted_CommandEntry                      ; Branch to Decrypted_CommandEntry if zero / equal
	move.w   #$3700,sr                             ; Disable interrupts and set supervisor mode
	movea.l  Var_UserMSP(a6),a7                          ; Load saved user MSP register state into stack pointer (a7)
	move.w   #$2700,sr                             ; Disable interrupts and set supervisor mode
	movea.l  Var_UserSSP(a6),a7                          ; Load saved user SSP register state into stack pointer (a7)
	tst.b    Var_CpuType(a6)                       ; Check if Var_CpuType is set / active
	beq.b    ExitMonitor_RestoreGraphicsState            ; Branch to ExitMonitor_RestoreGraphicsState if zero / equal
	movea.l  Var_UserVBR(a6),a5                          ; Load saved user VBR register state into pointer a5
	movec    a5,vbr                                      ; Write control register VBR from pointer a5
	move.b   Var_UserSFC(a6),d0                          ; Load saved user SFC register state into register d0
	movec    d0,sfc                                      ; Write control register SFC from register d0
	move.b   Var_UserDFC(a6),d0                          ; Load saved user DFC register state into register d0
	movec    d0,dfc                                      ; Write control register DFC from register d0
	cmpi.b   #$2,Var_CpuType(a6)                         ; Compare detected CPU type against constant $2
	bcs.b    ExitMonitor_RestoreGraphicsState            ; Branch to ExitMonitor_RestoreGraphicsState if carry set (less than)
	movea.l  Var_UserCACR(a6),a5                         ; Load saved user CACR register state into pointer a5
	movec    a5,cacr                                     ; Write control register CACR from pointer a5
	cmpi.b   #$4,Var_CpuType(a6)                         ; Compare detected CPU type against constant $4
	beq.b    ExitMonitor_RestoreGraphicsState            ; Branch to ExitMonitor_RestoreGraphicsState if zero / equal
	movea.l  Var_UserCAAR(a6),a5                         ; Load saved user CAAR register state into pointer a5
	movec    a5,caar                                     ; Write control register CAAR from pointer a5
ExitMonitor_RestoreGraphicsState:	movea.l  Var_UserUSP(a6),a0                    ; Copy Var_UserUSP to a0
	move     a0,usp                                      ; Write User Stack Pointer (USP) from pointer a0
	lea.l    CUSTOM.l,a4                                 ; Load address of Amiga custom chip register base address ($dff000) into pointer a4
	move.w   #$80,DMACON(a4)                             ; Set DMA control (DMACON) bits to constant $80
	bsr.w    RestoreGraphics                             ; Call subroutine to RestoreGraphics
	move.w   #$8080,DMACON(a4)                           ; Enable Copper DMA and Master DMA
	move.w   #$83f0,DMACON(a4)                           ; Set DMA control (DMACON) bits to constant $83f0
	move.w   #$e02c,INTENA(a4)                           ; Set INTENA interrupt enable bits to constant $e02c
	bclr     #$1,CIAA_PRA.l                              ; Clear bit #$1 of CIAA_PRA (CIA-A Port A status register)
	move.l   Var_RegsSaved(a6),d0                        ; Load saved user registers area into register d0
	subq.l   #$1,d0                                      ; Subtract 1 from register d0
	beq.b    RestoreGraphics_Exit                        ; Branch to RestoreGraphics_Exit if zero / equal
	addq.l   #$1,d0                                      ; Add 1 to register d0
RestoreGraphics_Exit:	move.w   Var_UserSR(a6),sr                     ; Copy Var_UserSR to sr
	movem.l  $13de(a6),d1-d7/a0-a6                       ; Move multiple registers $13de(a6) to d1-d7/a0-a6
	rts                                                  ; Return from subroutine
RestoreGraphics:	move.l   a6,-(a7)
	movea.l  ExecBase.w,a6                               ; Move ExecBase.w to monitor context base (a6)
	lea.l    RestoreGraphics_Rts_Loc_0788(pc),a1         ; Load address of RestoreGraphics_Rts_Loc_0788(pc) into pointer a1
	jsr      -$198(a6)                                   ; Call subroutine -$198(a6)
	movea.l  d0,a6                                       ; Move register d0 to monitor context base (a6)
	tst.l    d0                                          ; Test status of register d0 (for zero or negative)
	beq.b    RestoreGraphics_Rts                         ; Branch to RestoreGraphics_Rts if zero / equal
	move.l   $22(a6),d2                                  ; Move $22(a6) to register d2
	suba.l   a1,a1                                       ; Subtract pointer a1 from pointer a1
	jsr      -$de(a6)                                    ; Call subroutine -$de(a6)
	jsr      -$10e(a6)                                   ; Call subroutine -$10e(a6)
	jsr      -$10e(a6)                                   ; Call subroutine -$10e(a6)
	movea.l  d2,a1                                       ; Move register d2 to pointer a1
	jsr      -$de(a6)                                    ; Call subroutine -$de(a6)
	move.l   GfxBase_ActiView(a6),COP1LCH+CUSTOM.l       ; Move GfxBase_ActiView(a6) to Amiga custom chip register base address ($dff000)
	move.w   d0,COPJMP1+CUSTOM.l                         ; Move register d0 to Amiga custom chip register base address ($dff000)
	movea.l  a6,a1                                       ; Move monitor context base (a6) to pointer a1
	movea.l  ExecBase.w,a6                               ; Move ExecBase.w to monitor context base (a6)
	jsr      -$19e(a6)                                   ; Call subroutine -$19e(a6)
RestoreGraphics_Rts:	movea.l  (a7)+,a6
	rts                                                  ; Return from subroutine
	RestoreGraphics_Rts_Loc_0788:
	dc.b     "graphics.library",0,0
VerifyExecBase:
	movea.l  ExecBase.w,a0                               ; Move ExecBase.w to pointer a0
	move.l   a0,d1                                       ; Move pointer a0 to register d1
	btst     #$0,d1                                      ; Test bit #$0 of register d1
	bne.b    VerifyExecBase_Exit                         ; Branch to VerifyExecBase_Exit if non-zero / not equal
	add.l    GfxBase_ActiView(a0),d1                     ; Add GfxBase_ActiView(a0) to register d1
	not.l    d1
	bne.b    VerifyExecBase_Exit                         ; Branch to VerifyExecBase_Exit if non-zero / not equal
	lea.l    $22(a0),a1                                  ; Load address of $22(a0) into pointer a1
	moveq    #$18,d0                                     ; Initialize register d0 to constant $18
VerifyExecBase_ChecksumLoop:
	add.w    (a1)+,d1                                    ; Add (a1)+ to register d1
	dbra     d0,VerifyExecBase_ChecksumLoop              ; Decrement loop counter d0 and loop back to VerifyExecBase_ChecksumLoop if not exhausted
	not.w    d1
VerifyExecBase_Exit:
	rts                                                  ; Return from subroutine
; ============================================================================
; Function: VerifyLibraryNode
; Purpose : Checks a library node's structure and computes checksum of its jump vectors.
; ============================================================================
VerifyLibraryNode:
	move.l   a1,d0                                       ; Move pointer a1 to register d0
VerifyLibraryNode_CheckOpen:
	btst     #$0,d0                                      ; Test bit #$0 of register d0
	bne.b    VerifyLibraryNode_Failure                   ; Branch to VerifyLibraryNode_Failure if non-zero / not equal
	move.w   $e(a1),d0                                   ; Move $e(a1) to register d0
	btst     d1,d0                                       ; Test bit d1 of register d0
	bne.b    VerifyLibraryNode_GetNext                   ; Branch to VerifyLibraryNode_GetNext if non-zero / not equal
	movea.l  (a1),a1                                     ; Move (a1) to pointer a1
	move.l   a1,d0                                       ; Move pointer a1 to register d0
	bne.b    VerifyLibraryNode_CheckOpen                 ; Branch to VerifyLibraryNode_CheckOpen if non-zero / not equal
	bra.w    VerifyLibraryNode_Failure                   ; Unconditional branch to VerifyLibraryNode_Failure
VerifyLibraryNode_GetNext:
	movea.l  $10(a1),a1                                  ; Move $10(a1) to pointer a1
	move.l   a1,d0                                       ; Move pointer a1 to register d0
	beq.b    VerifyLibraryNode_Failure                   ; Branch to VerifyLibraryNode_Failure if zero / equal
VerifyLibraryNode_CheckName:
	btst     #$0,d0                                      ; Test bit #$0 of register d0
	bne.b    VerifyLibraryNode_Failure                   ; Branch to VerifyLibraryNode_Failure if non-zero / not equal
	btst     #$0,$7(a1)                                  ; Test bit #$0 of $7(a1)
	bne.b    VerifyLibraryNode_Failure                   ; Branch to VerifyLibraryNode_Failure if non-zero / not equal
	cmpi.l   #$b414,$4(a1)                               ; Compare $4(a1) against constant $b414
	bcc.b    VerifyLibraryNode_Success                   ; Branch to VerifyLibraryNode_Success if carry clear (greater or equal)
	movea.l  (a1),a1                                     ; Move (a1) to pointer a1
	move.l   a1,d0                                       ; Move pointer a1 to register d0
	bne.b    VerifyLibraryNode_CheckName                 ; Branch to VerifyLibraryNode_CheckName if non-zero / not equal
	bra.b    VerifyLibraryNode_Failure                   ; Unconditional branch to VerifyLibraryNode_Failure
VerifyLibraryNode_Success:
	adda.l   $4(a1),a1                                   ; Add $4(a1) to pointer a1
	suba.l   #$b40c,a1                                   ; Subtract constant $b40c from pointer a1
	moveq    #-1,d0                                      ; Initialize register d0 to constant -1
	rts                                                  ; Return from subroutine
VerifyLibraryNode_Failure:
	moveq    #$0,d0                                      ; Initialize register d0 to 0
	rts                                                  ; Return from subroutine
RestoreUserContextAndRte:
	move.w   #$3700,sr                             ; Disable interrupts and set supervisor mode
	movea.l  Var_UserMSP(a6),a7                          ; Load saved user MSP register state into stack pointer (a7)
	move.w   #$2700,sr                             ; Disable interrupts and set supervisor mode
	movea.l  Var_UserSSP(a6),a7                          ; Load saved user SSP register state into stack pointer (a7)
	tst.b    Var_CpuType(a6)                       ; Check if Var_CpuType is set / active
	beq.b    RestoreContext_Common                       ; Branch to RestoreContext_Common if zero / equal
	movea.l  Var_UserVBR(a6),a5                          ; Load saved user VBR register state into pointer a5
	movec    a5,vbr                                      ; Write control register VBR from pointer a5
	move.b   Var_UserSFC(a6),d0                          ; Load saved user SFC register state into register d0
	movec    d0,sfc                                      ; Write control register SFC from register d0
	move.b   Var_UserDFC(a6),d0                          ; Load saved user DFC register state into register d0
	movec    d0,dfc                                      ; Write control register DFC from register d0
	cmpi.b   #$2,Var_CpuType(a6)                         ; Compare detected CPU type against constant $2
	bcs.b    RestoreContext_Common                       ; Branch to RestoreContext_Common if carry set (less than)
	movea.l  Var_UserCACR(a6),a5                         ; Load saved user CACR register state into pointer a5
	movec    a5,cacr                                     ; Write control register CACR from pointer a5
	cmpi.b   #$4,Var_CpuType(a6)                         ; Compare detected CPU type against constant $4
	beq.b    RestoreContext_Common                       ; Branch to RestoreContext_Common if zero / equal
	movea.l  Var_UserCAAR(a6),a5                         ; Load saved user CAAR register state into pointer a5
	movec    a5,caar                                     ; Write control register CAAR from pointer a5
RestoreContext_Common:
	movea.l  Var_UserUSP(a6),a0                          ; Load saved user USP register state into pointer a0
	move     a0,usp                                      ; Write User Stack Pointer (USP) from pointer a0
	lea.l    CUSTOM.l,a2                                 ; Load address of Amiga custom chip register base address ($dff000) into pointer a2
	move.w   #$7fff,d0                                   ; Move disable all / mask to register d0
	move.w   d0,DMACON(a2)                               ; Set DMA control (DMACON) bits to register d0
	move.w   d0,ADKCON(a2)                               ; Move register d0 to ADKCON(a2)
	move.w   d0,INTENA(a2)                               ; Write interrupt enable (INTENA) from register d0
	move.w   d0,INTREQ(a2)                               ; Acknowledge interrupt request flags (register d0)
RestoreContext_WaitBeam:
	move.w   VHPOSR(a2),COLOR00(a2)                      ; Move VHPOSR (beam vertical/horizontal position read) to COLOR00 (screen background color register)
	dbra     d0,RestoreContext_WaitBeam                  ; Decrement loop counter d0 and loop back to RestoreContext_WaitBeam if not exhausted
	move.w   $1612(a6),DMACON(a2)                        ; Set DMA control (DMACON) bits to $1612(a6)
	move.w   $1614(a6),ADKCON(a2)                        ; Move $1614(a6) to ADKCON(a2)
	move.w   $1616(a6),INTENA(a2)                        ; Write interrupt enable (INTENA) from $1616(a6)
	move.w   $1618(a6),INTREQ(a2)                        ; Acknowledge interrupt request flags ($1618(a6))
	movem.l  Var_RegsSaved(a6),d0-d7/a0-a6               ; Restore registers d0-d7/a0-a6 from context storage area
	rte                                                  ; Return from Exception (RTE) handler
; ============================================================================
; Data Block: Handler_SupervisorTrick
; Purpose   : Illegal instruction vector handler to capture supervisor state.
; ============================================================================
Handler_SupervisorTrick:  ; Temporary handler installed via the illegal vector for the initial supervisor entry trick
	move.w   (a7),d0                                     ; Move (a7) to register d0
	move.w   #$2700,(a7)                                 ; Move Supervisor mode with interrupts disabled to (a7)
	move.w   d0,Var_CpuStatus(a6)                        ; Store register d0 into Var_CpuStatus(a6)
	move.l   $2(a7),Var_SrpSaved(a6)                     ; Store $2(a7) into saved exception instruction PC (SRP)
	addq.l   #$2,$2(a7)                                  ; Add constant $2 to $2(a7)
	rte                                                  ; Return from Exception (RTE) handler
; ============ SaveFPURegisters
; Purpose: If an FPU was detected during entry, save the full user-visible FP regs + control regs into the
;   private context area. Called from the FPU probe path and also available for the 'r' display / single-step.
SaveFPURegisters:
	tst.b    Var_FpuType(a6)                             ; Test status of detected FPU type (for zero or negative)
	beq.b    SaveFPURegisters_Done                       ; Branch to SaveFPURegisters_Done if zero / equal
	lea.l    $143c(a6),a2                                ; Load address of $143c(a6) into pointer a2
	fmovem   fp0-fp7,(a2)                                ; FPU operation: fmovem fp0-fp7,(a2)
	lea.l    $15bc(a6),a2                                ; Load address of $15bc(a6) into pointer a2
	fmovem.l fpcr/fpsr/fpiar,(a2)                        ; FPU operation: fmovem.l fpcr/fpsr/fpiar,(a2)
SaveFPURegisters_Done:
	rts                                                  ; Return from subroutine
; ============ RestoreFPURegisters
; Purpose: Opposite of above. Used on 'g' (Go) to put the saved FPU state back before rte to the debugged program.
RestoreFPURegisters:
	tst.b    Var_FpuType(a6)                             ; Test status of detected FPU type (for zero or negative)
	beq.b    RestoreFPURegisters_Done                    ; Branch to RestoreFPURegisters_Done if zero / equal
	lea.l    $143c(a6),a2                                ; Load address of $143c(a6) into pointer a2
	fmovem   (a2),fp0-fp7                                ; FPU operation: fmovem (a2),fp0-fp7
	lea.l    $15bc(a6),a2                                ; Load address of $15bc(a6) into pointer a2
	fmovem.l (a2),fpcr/fpsr/fpiar                        ; FPU operation: fmovem.l (a2),fpcr/fpsr/fpiar
RestoreFPURegisters_Done:
	rts                                                  ; Return from subroutine
; ============ ConvertFPURegisters
; Purpose: After the raw fsave during entry, massage the FPU state into a form that is easy to display
;   in the register view (and consistent across 68881/882 vs 040). Uses a couple of fmove coprocessor
;   instructions (hence the dc.w) to transfer between the probe scratch area and the saved context.
ConvertFPURegisters:
	tst.b    Var_FpuModel(a6)                            ; Test status of detected FPU model (for zero or negative)
	beq.b    ConvertFPURegisters_Done                    ; Branch to ConvertFPURegisters_Done if zero / equal
	cmpi.b   #$3,Var_FpuModel(a6)                        ; Compare detected FPU model against constant $3
	beq.b    ConvertFPURegisters_Done                    ; Branch to ConvertFPURegisters_Done if zero / equal
	cmpi.b   #$1,Var_FpuModel(a6)                        ; Compare detected FPU model against 1
	beq.b    ConvertFPURegisters_68881Path               ; Branch to ConvertFPURegisters_68881Path if zero / equal
	lea.l    $15c8(a6),a2                                ; Load address of $15c8(a6) into pointer a2
	dc.w     $F012,$0A00                           ; fmove fp2,fp4 (copro ID 0)
	addq.w   #$4,a2                                      ; Add constant $4 to pointer a2
	dc.w     $F012,$0E00                           ; fmove fp3,fp4
	bra.b    ConvertFPURegisters_Store                   ; Unconditional branch to ConvertFPURegisters_Store
ConvertFPURegisters_68881Path:
	lea.l    $15e6(a6),a2                                ; Load address of $15e6(a6) into pointer a2
	dc.w     $F012,$4600                           ; fmove.s (a2),fp4
ConvertFPURegisters_Store:
	lea.l    $15d0(a6),a2                                ; Load address of $15d0(a6) into pointer a2
	dc.w     $F012,$4200
	addq.w   #$4,a2                                      ; Add constant $4 to pointer a2
	dc.w     $F012
	tst.b    d0                                          ; Test status of register d0 (for zero or negative)
	addq.w   #$8,a2                                      ; Add constant $8 to pointer a2
	dc.w     $F012
	dc.w     $4E00
	addq.w   #$8,a2                                      ; Add constant $8 to pointer a2
	dc.w     $F012,$6200                           ; fmove.l fp4,(a2)
ConvertFPURegisters_Done:
	rts                                                  ; Return from subroutine
; ============================================================================
; Function: SetupFPUSafetyHandler
; Purpose : Temporarily redirects Line-F exception handler for safety during FPU operations.
; ============================================================================
SetupFPUSafetyHandler:
	dc.b     $4A,$2E,$16,$59,$67,$54,$0C,$2E,$00,$03,$16,$59,$67,$4C,$43,$F8; Table data bytes
	dc.b     $00,$E0,$D3,$EE,$14,$26,$2F,$11,$45,$FA,$00,$42,$22,$8A,$0C,$2E; Table data bytes
	dc.b     $00,$01,$16,$59,$67,$10,$45,$EE,$15,$C8,$F0,$12,$08,$00,$58,$4A; Table data bytes
	dc.b     $F0,$12,$0C,$00,$60,$08,$45,$EE,$15,$E6,$F0,$12,$44,$00,$45,$EE; Table data bytes
	dc.b     $15,$D0,$F0,$12,$40,$00,$58,$4A,$F0,$12,$48,$00,$50,$4A,$F0,$12; Table data bytes
	dc.b     $4C,$00,$50,$4A,$F0,$12,$60,$00,$22,$9F,$4E,$75,$4E,$73; Table data bytes
; ============================================================================
; Function: GetVBR
; Purpose : Retrieves the Vector Base Register (VBR) by entering Supervisor mode.
; ============================================================================
GetVBR:
	suba.l   a5,a5                                       ; Subtract pointer a5 from pointer a5
	bsr.w    VerifyExecBase                              ; Call subroutine to VerifyExecBase
	bne.b    GetVBR_Done                                 ; Branch to GetVBR_Done if non-zero / not equal
	move.l   a6,d0                                       ; Move monitor context base (a6) to register d0
	movea.l  ExecBase.w,a6                               ; Move ExecBase.w to monitor context base (a6)
	btst     #$0,$129(a6)                                ; Test bit #$0 of $129(a6)
	beq.b    GetVBR_RestoreA6                            ; Branch to GetVBR_RestoreA6 if zero / equal
	lea.l    GetVBR_SuperBody(pc),a5                     ; Load address of GetVBR_SuperBody(pc) into pointer a5
	jsr      LVO_Supervisor(a6)                          ; Call subroutine LVO_Supervisor(a6)
GetVBR_RestoreA6:
	movea.l  d0,a6                                       ; Move register d0 to monitor context base (a6)
GetVBR_Done:
	rts                                                  ; Return from subroutine
; ============ GetVBR_SuperBody
; Purpose: The actual supervisor-mode fragment that does "movec vbr,d1 ; rte". Stored as dc.b so the
;   exact bytes (including the rte) match the original. Exec's Supervisor() will run this in sup mode
;   and return the VBR value in the way the caller expects.
GetVBR_SuperBody:
	dc.b     $4E,$7A,$D8,$01,$4E,$73               ; movec vbr,d1 ; rte   (the bytes that read VBR while in supervisor)
; ============================================================================
; Data Block: Exception_VectorBranchTable
; Purpose   : Vector table of branch entry points for CPU exceptions.
; ============================================================================
Exception_VectorBranchTable:
	dc.b     "a|azaxavatarapanalajahafadaba`a^a\aZaXaVaTaRaPaNaLaJaHaFaDaBa@a>a<a:a8a6a4a2a0a.a,a*a(a&a$a"; String literal data
	dc.b     $22,$61,$20,$61,$1E,$61,$1C,$61,$1A,$61,$18,$61,$16,$61,$14,$61; Table data bytes
	dc.b     $12,$61,$10,$61,$0E,$61,$0C,$61,$0A,$61,$08,$61,$06,$61,$04,$61; Table data bytes
	dc.b     $02,$4E,$71,$2F,$0E,$4D,$FA,$35,$C0,$4D,$EE,$7F,$FE,$2D,$5F,$13; Table data bytes
	dc.b     $E2,$48,$EE,$00,$03,$13,$DA,$22,$1F,$4D,$FA,$FF,$6A,$92,$8E,$4D; Table data bytes
	dc.b     $FA,$35,$A6,$4D,$EE,$7F,$FE,$E2,$09,$1D,$41,$16,$56,$32,$17,$4A; Table data bytes
	dc.b     $2E,$16,$57,$66,$3C,$0C,$2E,$00,$02,$16,$56,$62,$24,$2D,$6F,$00; Table data bytes
	dc.b     $02,$16,$4C,$3D,$6F,$00,$06,$16,$4A,$3D,$6F,$00,$08,$16,$50,$2D; Table data bytes
	dc.b     $6F,$00,$0A,$16,$52,$32,$2F,$00,$08,$4F,$EF,$00,$0E,$60,$00,$01; Table data bytes
	dc.b     $06,$3D,$57,$16,$50                   ; Table data bytes
	move.l   $2(a7),Var_ExceptionPC(a6)                  ; Store $2(a7) into Var_ExceptionPC(a6)
	addq.w   #$6,a7                                      ; Add constant $6 to stack pointer (a7)
	bra.w    Exception_ParseFrame_Done                   ; Unconditional branch to Exception_ParseFrame_Done
	move.w   $6(a7),d0                                   ; Move $6(a7) to register d0
	andi.w   #$f000,d0                                   ; Logical AND register d0 with constant $f000
	beq.b    Exception_ParseFrame_FormatDefault          ; Branch to Exception_ParseFrame_FormatDefault if zero / equal
	cmpi.w   #$1000,d0                                   ; Compare register d0 against constant $1000
	bne.b    Exception_ParseFrame_Format2                ; Branch to Exception_ParseFrame_Format2 if non-zero / not equal
Exception_ParseFrame_FormatDefault:
	move.w   (a7),Var_ExceptionSR(a6)                    ; Store (a7) into Var_ExceptionSR(a6)
	move.l   $2(a7),Var_ExceptionPC(a6)                  ; Store $2(a7) into Var_ExceptionPC(a6)
	addq.w   #$8,a7                                      ; Add constant $8 to stack pointer (a7)
Exception_ParseFrame_Format2:
	cmpi.w   #$2000,d0                                   ; Compare register d0 against Supervisor mode with interrupts enabled
	bne.b    Exception_ParseFrame_Format3                ; Branch to Exception_ParseFrame_Format3 if non-zero / not equal
	move.w   (a7),Var_ExceptionSR(a6)                    ; Store (a7) into Var_ExceptionSR(a6)
	move.l   $8(a7),Var_ExceptionPC(a6)                  ; Store $8(a7) into Var_ExceptionPC(a6)
	cmpi.b   #$9,Var_ExceptionType(a6)                   ; Compare Var_ExceptionType(a6) against constant $9
	beq.b    Exception_ParseFrame_Format0                ; Branch to Exception_ParseFrame_Format0 if zero / equal
	cmpi.b   #$2,Var_ExceptionType(a6)                   ; Compare Var_ExceptionType(a6) against constant $2
	bne.b    Exception_ParseFrame_Format0_Exit           ; Branch to Exception_ParseFrame_Format0_Exit if non-zero / not equal
Exception_ParseFrame_Format0:
	move.l   $2(a7),Var_ExceptionPC(a6)                  ; Store $2(a7) into Var_ExceptionPC(a6)
	move.l   $8(a7),Var_ExceptionVO(a6)                  ; Store $8(a7) into Var_ExceptionVO(a6)
Exception_ParseFrame_Format0_Exit:
	lea.l    $c(a7),a7                                   ; Load address of $c(a7) into stack pointer (a7)
Exception_ParseFrame_Format3:
	cmpi.w   #$3000,d0                                   ; Compare register d0 against constant $3000
	bne.b    Exception_ParseFrame_Format7                ; Branch to Exception_ParseFrame_Format7 if non-zero / not equal
	move.w   (a7),Var_ExceptionSR(a6)                    ; Store (a7) into Var_ExceptionSR(a6)
	move.l   $2(a7),Var_ExceptionPC(a6)                  ; Store $2(a7) into Var_ExceptionPC(a6)
	move.l   $8(a7),Var_ExceptionVO(a6)                  ; Store $8(a7) into Var_ExceptionVO(a6)
	lea.l    $c(a7),a7                                   ; Load address of $c(a7) into stack pointer (a7)
Exception_ParseFrame_Format7:
	cmpi.w   #$7000,d0                                   ; Compare register d0 against constant $7000
	bne.b    Exception_ParseFrame_Format8                ; Branch to Exception_ParseFrame_Format8 if non-zero / not equal
	move.w   (a7),Var_ExceptionSR(a6)                    ; Store (a7) into Var_ExceptionSR(a6)
	move.l   $2(a7),Var_ExceptionPC(a6)                  ; Store $2(a7) into Var_ExceptionPC(a6)
	move.l   $14(a7),Var_ExceptionVO(a6)                 ; Store $14(a7) into Var_ExceptionVO(a6)
	lea.l    $3c(a7),a7                                  ; Load address of $3c(a7) into stack pointer (a7)
Exception_ParseFrame_Format8:
	cmpi.w   #$8000,d0                                   ; Compare register d0 against constant $8000
	bne.b    Exception_ParseFrame_Format9                ; Branch to Exception_ParseFrame_Format9 if non-zero / not equal
	move.l   $a(a7),Var_ExceptionVO(a6)                  ; Store $a(a7) into Var_ExceptionVO(a6)
	move.w   $18(a7),Var_ExceptionAddr(a6)               ; Store $18(a7) into Var_ExceptionAddr(a6)
	move.w   (a7),Var_ExceptionSR(a6)                    ; Store (a7) into Var_ExceptionSR(a6)
	move.l   $2(a7),Var_ExceptionPC(a6)                  ; Store $2(a7) into Var_ExceptionPC(a6)
	lea.l    $3a(a7),a7                                  ; Load address of $3a(a7) into stack pointer (a7)
Exception_ParseFrame_Format9:
	cmpi.w   #$9000,d0                                   ; Compare register d0 against constant $9000
	bne.b    Exception_ParseFrame_FormatA                ; Branch to Exception_ParseFrame_FormatA if non-zero / not equal
	move.w   (a7),Var_ExceptionSR(a6)                    ; Store (a7) into Var_ExceptionSR(a6)
	move.l   $2(a7),Var_ExceptionVO(a6)                  ; Store $2(a7) into Var_ExceptionVO(a6)
	move.l   $8(a7),Var_ExceptionPC(a6)                  ; Store $8(a7) into Var_ExceptionPC(a6)
	lea.l    $14(a7),a7                                  ; Load address of $14(a7) into stack pointer (a7)
Exception_ParseFrame_FormatA:
	cmpi.w   #$a000,d0                                   ; Compare register d0 against constant $a000
	bne.b    Exception_ParseFrame_FormatB                ; Branch to Exception_ParseFrame_FormatB if non-zero / not equal
	move.l   $14(a7),Var_ExceptionVO(a6)                 ; Store $14(a7) into Var_ExceptionVO(a6)
	move.w   (a7),Var_ExceptionSR(a6)                    ; Store (a7) into Var_ExceptionSR(a6)
	move.l   $2(a7),Var_ExceptionPC(a6)                  ; Store $2(a7) into Var_ExceptionPC(a6)
	lea.l    $20(a7),a7                                  ; Load address of $20(a7) into stack pointer (a7)
Exception_ParseFrame_FormatB:
	cmpi.w   #$b000,d0                                   ; Compare register d0 against constant $b000
	bne.b    Exception_ParseFrame_Done                   ; Branch to Exception_ParseFrame_Done if non-zero / not equal
	move.l   $24(a7),Var_ExceptionVO(a6)                 ; Store $24(a7) into Var_ExceptionVO(a6)
	move.w   $1e(a7),Var_ExceptionAddr(a6)               ; Store $1e(a7) into Var_ExceptionAddr(a6)
	move.w   (a7),Var_ExceptionSR(a6)                    ; Store (a7) into Var_ExceptionSR(a6)
	move.l   $2(a7),Var_ExceptionPC(a6)                  ; Store $2(a7) into Var_ExceptionPC(a6)
	lea.l    $5c(a7),a7                                  ; Load address of $5c(a7) into stack pointer (a7)
Exception_ParseFrame_Done:
	andi.w   #$3fff,d1                                   ; Logical AND register d1 with constant $3fff
	move.w   d1,sr                                       ; Set Status Register (SR) value to register d1
	lea.l    Breakpoint_Entry(pc),a6                     ; Load address of Breakpoint_Entry(pc) into monitor context base (a6)
	cmpa.l   (a7),a6                                     ; Compare monitor context base (a6) against (a7)
	lea.l    Val_MonitorBaseOffset(pc),a6                ; Load address of Val_MonitorBaseOffset(pc) into monitor context base (a6)
	lea.l    $7ffe(a6),a6                                ; Offset base pointer to middle of 64KB variables space (for signed 16-bit access)
	bne.b    Exception_ReturnToMonitor                   ; Branch to Exception_ReturnToMonitor if non-zero / not equal
	addq.w   #$4,a7                                      ; Add constant $4 to stack pointer (a7)
Exception_ReturnToMonitor:
	move.w   d1,ccr                                      ; Move register d1 to ccr
	movem.l  Var_RegsSaved(a6),d0-d1/a6                  ; Restore registers d0-d1/a6 from context storage area
	bra.w    Breakpoint_Entry                            ; Unconditional branch to Breakpoint_Entry
; ============================================================================
; Function: ProcessInputChar
; Purpose : Process a single keyboard character from the monitor command input.
; ============================================================================
ProcessInputChar:
	bsr.b    ParseControlChar                            ; Call subroutine to ParseControlChar
	tst.b    d7                                          ; Test status of register d7 (for zero or negative)
	beq.b    ProcessInputChar_Exit                       ; Branch to ProcessInputChar_Exit if zero / equal
	tst.b    Var_WindowFlags(a6)                   ; Check if Var_WindowFlags is set / active
	beq.b    ProcessInputChar_Draw                       ; Branch to ProcessInputChar_Draw if zero / equal
	bsr.w    Console_InsertSpaceAtCursor                 ; Call subroutine to Console_InsertSpaceAtCursor
ProcessInputChar_Draw:
	bra.w    Console_DrawChar                            ; Unconditional branch to Console_DrawChar
ProcessInputChar_Exit:
	rts                                                  ; Return from subroutine
; ============================================================================
; Function: ParseControlChar
; Purpose : Parse and execute keyboard control character hotkeys.
; ============================================================================
ParseControlChar:
	sf.b     d7
	cmpi.b   #$13,d0                                     ; Compare register d0 against constant $13
	beq.w    Console_CursorNextChar                      ; Branch to Console_CursorNextChar if zero / equal
	cmpi.b   #$12,d0                                     ; Compare register d0 against constant $12
	beq.w    Console_CursorPrevChar                      ; Branch to Console_CursorPrevChar if zero / equal
	cmpi.b   #$11,d0                                     ; Compare register d0 against constant $11
	beq.w    Console_CursorNextLine_MenuCheck            ; Branch to Console_CursorNextLine_MenuCheck if zero / equal
	cmpi.b   #$10,d0                                     ; Compare register d0 against constant $10
	beq.w    Console_OpenMenu                            ; Branch to Console_OpenMenu if zero / equal
	cmpi.b   #$1,d0                                      ; Compare register d0 against 1
	beq.w    Console_MenuCheck                           ; Branch to Console_MenuCheck if zero / equal
	cmpi.b   #$2,d0                                      ; Compare register d0 against constant $2
	beq.w    Console_MenuUpdateItem_Body                 ; Branch to Console_MenuUpdateItem_Body if zero / equal
	cmpi.b   #$3,d0                                      ; Compare register d0 against constant $3
	beq.w    ParseControlChar_Step_Loc_0D66              ; Branch to ParseControlChar_Step_Loc_0D66 if zero / equal
	cmpi.b   #$4,d0                                      ; Compare register d0 against constant $4
	beq.w    Console_OpenMenu_Loc_0F9C                   ; Branch to Console_OpenMenu_Loc_0F9C if zero / equal
	cmpi.b   #$d,d0                                      ; Compare register d0 against constant $d
	beq.w    ProcessCommand_Entry                        ; Branch to ProcessCommand_Entry if zero / equal
	cmpi.b   #$e,d0                                      ; Compare register d0 against constant $e
	beq.w    ProcessCommand_Abort                        ; Branch to ProcessCommand_Abort if zero / equal
	cmpi.b   #$7,d0                                      ; Compare register d0 against constant $7
	beq.w    Console_ClearScreen                         ; Branch to Console_ClearScreen if zero / equal
	cmpi.b   #$8,d0                                      ; Compare register d0 against constant $8
	beq.w    Console_DeletePrevChar                      ; Branch to Console_DeletePrevChar if zero / equal
	cmpi.b   #$9,d0                                      ; Compare register d0 against constant $9
	beq.w    Console_DeleteCharAtCursor                  ; Branch to Console_DeleteCharAtCursor if zero / equal
	cmpi.b   #$a,d0                                      ; Compare register d0 against constant $a
	beq.w    Console_InsertSpaceAtCursor                 ; Branch to Console_InsertSpaceAtCursor if zero / equal
	cmpi.b   #$6,d0                                      ; Compare register d0 against constant $6
	beq.w    Console_DrawMenuPage                        ; Branch to Console_DrawMenuPage if zero / equal
	cmpi.b   #$b,d0                                      ; Compare register d0 against constant $b
	beq.w    Console_ScrollOrSwap                        ; Branch to Console_ScrollOrSwap if zero / equal
	cmpi.b   #$5,d0                                      ; Compare register d0 against constant $5
	beq.b    ParseControlChar_FindNextWord               ; Branch to ParseControlChar_FindNextWord if zero / equal
	cmpi.b   #$14,d0                                     ; Compare register d0 against constant $14
	beq.w    ParseControlChar_Step_Loc_0D00              ; Branch to ParseControlChar_Step_Loc_0D00 if zero / equal
	cmpi.b   #$15,d0                                     ; Compare register d0 against constant $15
	beq.w    ParseControlChar_Step_Loc_0D1A              ; Branch to ParseControlChar_Step_Loc_0D1A if zero / equal
	cmpi.b   #$16,d0                                     ; Compare register d0 against constant $16
	beq.w    ParseControlChar_Step_Loc_0D16              ; Branch to ParseControlChar_Step_Loc_0D16 if zero / equal
	cmpi.b   #$19,d0                                     ; Compare register d0 against constant $19
	beq.w    ParseControlChar_Step_Loc_0D64              ; Branch to ParseControlChar_Step_Loc_0D64 if zero / equal
	cmpi.b   #$1a,d0                                     ; Compare register d0 against constant $1a
	beq.w    Console_MenuUpdateItem                      ; Branch to Console_MenuUpdateItem if zero / equal
	cmpi.b   #$c,d0                                      ; Compare register d0 against constant $c
	beq.b    ParseControlChar_ToggleWindow               ; Branch to ParseControlChar_ToggleWindow if zero / equal
	cmpi.b   #COP1LC,d0                                  ; Compare register d0 against COP1LC (copper list 1 pointer high/low)
	bcs.b    ParseControlChar_Ignore                     ; Branch to ParseControlChar_Ignore if carry set (less than)
	cmpi.b   #$89,d0                                     ; Compare register d0 against constant $89
	bls.b    ParseControlChar_HandleFKey                              ; Branch to ParseControlChar_HandleFKey if lower or same.
ParseControlChar_Ignore:
	st.b     d7
	rts                                                  ; Return from subroutine
ParseControlChar_ToggleWindow:
	not.b    Var_WindowFlags(a6)                   ; Execute not.b instruction
	rts                                                  ; Return from subroutine
ParseControlChar_HandleFKey:
	move.w   #$1,Var_BufferLength(a6)                    ; Store 1 into keyboard input buffer character count
	lea.l    Var_FKeyDefs(a6),a5                         ; Load address of function key definitions into pointer a5
	subi.b   #COP1LC,d0                                  ; Subtract COP1LC (copper list 1 pointer high/low) from register d0
	ext.w    d0
	mulu.w   #$14,d0
	lea.l    (a5,d0.w),a5                                ; Load address of (a5,d0.w) into pointer a5
	moveq    #$13,d2                                     ; Initialize register d2 to constant $13
ParseControlChar_FKeyLoop:
	move.b   (a5)+,d0                                    ; Move (a5)+ to register d0
	beq.b    ParseControlChar_Done                       ; Branch to ParseControlChar_Done if zero / equal
	cmpi.b   #DENISEID,d0                                ; Compare register d0 against DENISEID (Denise chip ID register)
	bne.b    ParseControlChar_Send                       ; Branch to ParseControlChar_Send if non-zero / not equal
	moveq    #$d,d0                                      ; Initialize register d0 to constant $d
ParseControlChar_Send:
	bsr.w    Console_PushInputBuffer                     ; Call subroutine to Console_PushInputBuffer
	dbra     d2,ParseControlChar_FKeyLoop                ; Decrement loop counter d2 and loop back to ParseControlChar_FKeyLoop if not exhausted
ParseControlChar_Done:
	rts                                                  ; Return from subroutine
ParseControlChar_FindNextWord:
	bsr.b    ParseControlChar_Step                       ; Call subroutine to ParseControlChar_Step
	bne.b    ParseControlChar_FindNextWord               ; Branch to ParseControlChar_FindNextWord if non-zero / not equal
ParseControlChar_Loop:
	cmpi.b   #$4f,Var_CursorX(a6)                        ; Compare cursor horizontal column coordinate against constant $4f
	beq.b    ParseControlChar_End                        ; Branch to ParseControlChar_End if zero / equal
	bsr.b    ParseControlChar_Step                       ; Call subroutine to ParseControlChar_Step
	beq.b    ParseControlChar_Loop                       ; Branch to ParseControlChar_Loop if zero / equal
	cmpi.b   #$27,(a5)                                   ; Compare (a5) against constant $27
	beq.b    ParseControlChar_Loop                       ; Branch to ParseControlChar_Loop if zero / equal
	rts                                                  ; Return from subroutine
ParseControlChar_End:
	sf.b     Var_CursorX(a6)                       ; Clear cursor X coordinate flag (false).
ParseControlChar_Step:
	bsr.w    Console_CursorNextChar                      ; Call subroutine to Console_CursorNextChar
	bsr.w    Console_GetBufferPtr                        ; Call subroutine to Console_GetBufferPtr
	cmpi.b   #$20,(a5)                                   ; Compare (a5) against constant $20
	rts                                                  ; Return from subroutine
ParseControlChar_Step_Loc_0D00:
	move.w   Var_CursorY(a6),d3                          ; Load cursor vertical row coordinate into register d3
	moveq    #$4f,d4                                     ; Initialize register d4 to constant $4f
	sub.b    d3,d4                                       ; Subtract register d3 from register d4
ParseControlChar_Step_Loc_0D08:
	bsr.w    Console_DeleteCharAtCursor                  ; Call subroutine to Console_DeleteCharAtCursor
	dbra     d4,ParseControlChar_Step_Loc_0D08           ; Decrement loop counter d4 and loop back to ParseControlChar_Step_Loc_0D08 if not exhausted
	move.w   d3,Var_CursorY(a6)                          ; Store register d3 into cursor vertical row coordinate
	rts                                                  ; Return from subroutine
ParseControlChar_Step_Loc_0D16:
	moveq    #$1,d2                                      ; Initialize register d2 to 1
	bra.b    ParseControlChar_Step_Loc_0D1C              ; Unconditional branch to ParseControlChar_Step_Loc_0D1C
ParseControlChar_Step_Loc_0D1A:
	moveq    #-1,d2                                      ; Initialize register d2 to constant -1
ParseControlChar_Step_Loc_0D1C:
	lea.l    Var_DelayCounter(a6),a1                     ; Load address of timing delay loop counter into pointer a1
	move.b   (a1),d3                                     ; Move (a1) to register d3
	moveq    #$9,d0                                      ; Initialize register d0 to constant $9
	add.b    d2,(a1)                                     ; Add register d2 to (a1)
	bmi.b    ParseControlChar_Step_Loc_0D30              ; Branch to ParseControlChar_Step_Loc_0D30 if negative / minus
	move.b   (a1),d0                                     ; Move (a1) to register d0
	divu.w   #$a,d0
	swap     d0
ParseControlChar_Step_Loc_0D30:
	move.b   d0,(a1)                                     ; Move register d0 to (a1)
	movem.l  d1/a0,-(a7)                                 ; Move multiple registers d1/a0 to -(a7)
	lea.l    Var_DisasmBuffer+81(a6),a0                  ; Load address of disassembler output text buffer into pointer a0
	ext.w    d0
	mulu.w   #$4f,d0
	adda.l   d0,a0                                       ; Add register d0 to pointer a0
	tst.b    (a0)                                        ; Test status of (a0) (for zero or negative)
	bne.b    ParseControlChar_Step_Loc_0D4A              ; Branch to ParseControlChar_Step_Loc_0D4A if non-zero / not equal
	move.b   d3,(a1)                                     ; Move register d3 to (a1)
	bra.b    ParseControlChar_Step_Loc_0D5E              ; Unconditional branch to ParseControlChar_Step_Loc_0D5E
ParseControlChar_Step_Loc_0D4A:
	lea.l    Var_DisasmBuffer(a6),a1                     ; Load address of disassembler output text buffer into pointer a1
	move.b   #$3e,(a1)+                                  ; Move constant $3e to (a1)+
	moveq    #$4e,d1                                     ; Initialize register d1 to constant $4e
ParseControlChar_Step_Loc_0D54:
	move.b   (a0)+,(a1)+                                 ; Copy word/byte data from source pointer a0 to destination a1
	dbra     d1,ParseControlChar_Step_Loc_0D54           ; Decrement loop counter d1 and loop back to ParseControlChar_Step_Loc_0D54 if not exhausted
	bsr.w    DrawConsoleLine                             ; Call subroutine to DrawConsoleLine
ParseControlChar_Step_Loc_0D5E:
	movem.l  (a7)+,d1/a0                                 ; Move multiple registers (a7)+ to d1/a0
	rts                                                  ; Return from subroutine
ParseControlChar_Step_Loc_0D64:
	bsr.b    Console_MenuCheck                           ; Call subroutine to Console_MenuCheck
ParseControlChar_Step_Loc_0D66:
	move.b   #$1,Var_CursorX(a6)                         ; Store 1 into cursor horizontal column coordinate
	rts                                                  ; Return from subroutine
Console_MenuCheck:
	tst.b    Var_CursorY(a6)                       ; Check if Var_CursorY is set / active
	beq.b    Console_ParseHexAtCursor                    ; Branch to Console_ParseHexAtCursor if zero / equal
	sf.b     Var_CursorY(a6)                       ; Clear cursor Y coordinate flag (false).
	rts                                                  ; Return from subroutine
Console_MenuUpdateItem:
	bsr.b    ParseControlChar_Step_Loc_0D66              ; Call subroutine to ParseControlChar_Step_Loc_0D66
Console_MenuUpdateItem_Body:
	move.b   Var_MenuItem(a6),d2                         ; Load active menu item index into register d2
	cmp.b    Var_CursorY(a6),d2                          ; Compare register d2 against cursor vertical row coordinate
	beq.w    Console_ParseHexAtCursor_Variant            ; Branch to Console_ParseHexAtCursor_Variant if zero / equal
	move.b   d2,Var_CursorY(a6)                          ; Store register d2 into cursor vertical row coordinate
Console_MenuUpdateItem_Rts:
	rts                                                  ; Return from subroutine
Console_ParseHexAtCursor:
	move.b   Var_CursorX(a6),d2                          ; Load cursor horizontal column coordinate into register d2
	movem.l  d1-d2/d7/a0,-(a7)                           ; Move multiple registers d1-d2/d7/a0 to -(a7)
	lea.l    Var_ConsoleBuffer(a6),a5                    ; Load address of console character buffer into pointer a5
	lea.l    DMACONR(a5),a3                              ; Load address of DMACON (DMA control write register) into pointer a3
	bsr.w    ParseHexNumber                              ; Call subroutine to ParseHexNumber
	moveq    #BLTCON0,d1                                 ; Initialize register d1 to constant BLTCON0
	cmpi.w   #$3e3b,(a5)                                 ; Compare (a5) against constant $3e3b
	lea.l    Console_Callback_ModifyRegs(pc),a4                            ; Load address of Console_Callback_ModifyRegs(pc) into pointer a4
	beq.w    Console_ParseHexAtCursor_Loc_0E32           ; Branch to Console_ParseHexAtCursor_Loc_0E32 if zero / equal
	moveq    #$10,d1                                     ; Initialize register d1 to constant $10
	cmpi.w   #$3e3a,(a5)                                 ; Compare (a5) against constant $3e3a
	lea.l    Console_Callback_ModifyMemory(pc),a4                            ; Load address of Console_Callback_ModifyMemory(pc) into pointer a4
	beq.w    Console_ParseHexAtCursor_Loc_0E32           ; Branch to Console_ParseHexAtCursor_Loc_0E32 if zero / equal
	cmpi.b   #$3e,(a5)                                   ; Compare (a5) against constant $3e
	bne.b    Console_ParseHexAtCursor_Loc_0DD4           ; Branch to Console_ParseHexAtCursor_Loc_0DD4 if non-zero / not equal
	move.b   $1(a5),d2                                   ; Move $1(a5) to register d2
	bsr.w    MatchSpecialDisplayItemType                 ; Call subroutine to MatchSpecialDisplayItemType
	beq.b    Console_ParseHexAtCursor_Loc_0DD4           ; Branch to Console_ParseHexAtCursor_Loc_0DD4 if zero / equal
	lea.l    Console_Callback_SpecialItem(pc),a4                            ; Load address of Console_Callback_SpecialItem(pc) into pointer a4
	bra.b    Console_ParseHexAtCursor_Loc_0E32           ; Unconditional branch to Console_ParseHexAtCursor_Loc_0E32
Console_ParseHexAtCursor_Loc_0DD4:
	moveq    #$4,d1                                      ; Initialize register d1 to constant $4
	cmpi.w   #$3e2e,(a5)                                 ; Compare (a5) against constant $3e2e
	lea.l    Console_Callback_SingleStep(pc),a4                            ; Load address of Console_Callback_SingleStep(pc) into pointer a4
	beq.b    Console_ParseHexAtCursor_Loc_0E32           ; Branch to Console_ParseHexAtCursor_Loc_0E32 if zero / equal
	cmpi.w   #$3e5f,(a5)                                 ; Compare (a5) against constant $3e5f
	lea.l    Disasm_FormatOneLine(pc),a3                 ; Load address of Disasm_FormatOneLine(pc) into pointer a3
	lea.l    Console_Parser_Disasm(pc),a4                            ; Load address of Console_Parser_Disasm(pc) into pointer a4
	beq.b    Console_ParseHexAtCursor_Loc_0E02           ; Branch to Console_ParseHexAtCursor_Loc_0E02 if zero / equal
	lea.l    Disasm_DisassembleInstruction(pc),a3        ; Load address of Disasm_DisassembleInstruction(pc) into pointer a3
	lea.l    Console_Parser_DisasmInst(pc),a4                            ; Load address of Console_Parser_DisasmInst(pc) into pointer a4
	cmpi.w   #$3e2c,(a5)                                 ; Compare (a5) against constant $3e2c
	bne.b    Console_ParseHexAtCursor_Exit               ; Branch to Console_ParseHexAtCursor_Exit if non-zero / not equal
	btst     #$0,d0                                      ; Test bit #$0 of register d0
	bne.b    Console_ParseHexAtCursor_Exit               ; Branch to Console_ParseHexAtCursor_Exit if non-zero / not equal
Console_ParseHexAtCursor_Loc_0E02:
	lea.l    Var_FontData(a6),a0                         ; Load address of font glyph data pointer into pointer a0
	move.l   a0,-(a7)                                    ; Move pointer a0 to -(a7)
	movea.l  d0,a5                                       ; Move register d0 to pointer a5
	suba.w   #$190,a5                                    ; Subtract constant $190 from pointer a5
	move.l   a5,d1                                       ; Move pointer a5 to register d1
	bpl.b    Console_ParseHexAtCursor_Loc_0E14           ; Branch to Console_ParseHexAtCursor_Loc_0E14 if positive / plus
	suba.l   a5,a5                                       ; Subtract pointer a5 from pointer a5
Console_ParseHexAtCursor_Loc_0E14:
	move.l   a5,(a0)+                                    ; Move pointer a5 to (a0)+
	jsr      (a3)                                        ; Jump to subroutine via pointer (a3)
	cmp.l    a5,d0                                       ; Compare register d0 against pointer a5
	bhi.b    Console_ParseHexAtCursor_Loc_0E14                              ; Branch to Console_ParseHexAtCursor_Loc_0E14 if higher.
	moveq    #$0,d0                                      ; Initialize register d0 to 0
	move.b   Var_MenuSubItem(a6),d0                      ; Load Var_MenuSubItem(a6) into register d0
	lsl.w    #$2,d0
	suba.l   d0,a0                                       ; Subtract register d0 from pointer a0
	movea.l  (a7)+,a1                                    ; Move (a7)+ to pointer a1
	cmpa.l   a0,a1                                       ; Compare pointer a1 against pointer a0
	bls.b    Console_ParseHexAtCursor_Loc_0E2E                              ; Branch to Console_ParseHexAtCursor_Loc_0E2E if lower or same.
	movea.l  a1,a0                                       ; Move pointer a1 to pointer a0
Console_ParseHexAtCursor_Loc_0E2E:
	move.l   (a0),d0                                     ; Move (a0) to register d0
	moveq    #$0,d1                                      ; Initialize register d1 to 0
Console_ParseHexAtCursor_Loc_0E32:
	sf.b     Var_CursorY(a6)                       ; Clear cursor Y coordinate flag (false).
	moveq    #$0,d6                                      ; Initialize register d6 to 0
	move.b   Var_MenuSubItem(a6),d6                      ; Load Var_MenuSubItem(a6) into register d6
	move.w   d6,-(a7)                                    ; Move register d6 to -(a7)
	mulu.w   d1,d6
	sub.l    d6,d0                                       ; Subtract register d6 from register d0
	bpl.b    Console_ParseHexAtCursor_Loc_0E46           ; Branch to Console_ParseHexAtCursor_Loc_0E46 if positive / plus
	moveq    #$0,d0                                      ; Initialize register d0 to 0
Console_ParseHexAtCursor_Loc_0E46:
	movea.l  d0,a5                                       ; Move register d0 to pointer a5
	move.l   d0,Var_MemStart(a6)                         ; Store register d0 into monitored memory start offset
	move.w   (a7)+,d6                                    ; Move (a7)+ to register d6
Console_ParseHexAtCursor_Loc_0E4E:
	jsr      (a4)                                        ; Jump to subroutine via pointer (a4)
	dbra     d6,Console_ParseHexAtCursor_Loc_0E4E        ; Decrement loop counter d6 and loop back to Console_ParseHexAtCursor_Loc_0E4E if not exhausted
	moveq    #$3e,d0                                     ; Initialize register d0 to constant $3e
	bsr.w    Console_DrawChar                            ; Call subroutine to Console_DrawChar
Console_ParseHexAtCursor_Exit:
	movem.l  (a7)+,d1-d2/d7/a0                           ; Move multiple registers (a7)+ to d1-d2/d7/a0
	move.b   d2,Var_CursorX(a6)                          ; Store register d2 into cursor horizontal column coordinate
	sf.b     Var_CursorY(a6)                       ; Clear cursor Y coordinate flag (false).
	rts                                                  ; Return from subroutine
Console_ParseHexAtCursor_Variant:
	lea.l    $25c4(a6),a5                                ; Load address of $25c4(a6) into pointer a5
	tst.b    Var_VblankFlag(a6)                    ; Check if Var_VblankFlag is set / active
	beq.b    Console_ParseHexAtCursor_Variant_Loc_0E76   ; Branch to Console_ParseHexAtCursor_Variant_Loc_0E76 if zero / equal
	lea.l    $230(a5),a5                                 ; Load address of $230(a5) into pointer a5
Console_ParseHexAtCursor_Variant_Loc_0E76:
	move.b   Var_CursorX(a6),d2                          ; Load cursor horizontal column coordinate into register d2
	movem.l  d1-d2/d7/a0,-(a7)                           ; Move multiple registers d1-d2/d7/a0 to -(a7)
	lea.l    DMACONR(a5),a3                              ; Load address of DMACON (DMA control write register) into pointer a3
	bsr.w    ParseHexNumber                              ; Call subroutine to ParseHexNumber
	cmpi.w   #$3e3b,(a5)                                 ; Compare (a5) against constant $3e3b
	lea.l    Console_Callback_ModifyRegs(pc),a4                            ; Load address of Console_Callback_ModifyRegs(pc) into pointer a4
	beq.b    Console_ParseHexAtCursor_Variant_Loc_0ED4   ; Branch to Console_ParseHexAtCursor_Variant_Loc_0ED4 if zero / equal
	cmpi.w   #$3e3a,(a5)                                 ; Compare (a5) against constant $3e3a
	lea.l    Console_Callback_ModifyMemory(pc),a4                            ; Load address of Console_Callback_ModifyMemory(pc) into pointer a4
	beq.b    Console_ParseHexAtCursor_Variant_Loc_0ED4   ; Branch to Console_ParseHexAtCursor_Variant_Loc_0ED4 if zero / equal
	cmpi.b   #$3e,(a5)                                   ; Compare (a5) against constant $3e
	bne.b    Console_ParseHexAtCursor_Variant_Loc_0EB0   ; Branch to Console_ParseHexAtCursor_Variant_Loc_0EB0 if non-zero / not equal
	move.b   $1(a5),d2                                   ; Move $1(a5) to register d2
	bsr.w    MatchSpecialDisplayItemType                 ; Call subroutine to MatchSpecialDisplayItemType
	beq.b    Console_ParseHexAtCursor_Variant_Loc_0EB0   ; Branch to Console_ParseHexAtCursor_Variant_Loc_0EB0 if zero / equal
	lea.l    Console_Callback_SpecialItem(pc),a4                            ; Load address of Console_Callback_SpecialItem(pc) into pointer a4
	bra.b    Console_ParseHexAtCursor_Variant_Loc_0ED4   ; Unconditional branch to Console_ParseHexAtCursor_Variant_Loc_0ED4
Console_ParseHexAtCursor_Variant_Loc_0EB0:
	cmpi.w   #$3e2e,(a5)                                 ; Compare (a5) against constant $3e2e
	lea.l    Console_Callback_SingleStep(pc),a4                            ; Load address of Console_Callback_SingleStep(pc) into pointer a4
	beq.b    Console_ParseHexAtCursor_Variant_Loc_0ED4   ; Branch to Console_ParseHexAtCursor_Variant_Loc_0ED4 if zero / equal
	cmpi.w   #$3e5f,(a5)                                 ; Compare (a5) against constant $3e5f
	lea.l    Console_Parser_Disasm(pc),a4                            ; Load address of Console_Parser_Disasm(pc) into pointer a4
	beq.b    Console_ParseHexAtCursor_Variant_Loc_0ED4   ; Branch to Console_ParseHexAtCursor_Variant_Loc_0ED4 if zero / equal
	btst     #$0,d0                                      ; Test bit #$0 of register d0
	bne.b    Console_ParseHexAtCursor_Variant_Loc_0EFE   ; Branch to Console_ParseHexAtCursor_Variant_Loc_0EFE if non-zero / not equal
	lea.l    Console_Parser_DisasmInst(pc),a4                            ; Load address of Console_Parser_DisasmInst(pc) into pointer a4
	cmpi.w   #$3e2c,(a5)                                 ; Compare (a5) against constant $3e2c
	bne.b    Console_ParseHexAtCursor_Variant_Loc_0EFE   ; Branch to Console_ParseHexAtCursor_Variant_Loc_0EFE if non-zero / not equal
Console_ParseHexAtCursor_Variant_Loc_0ED4:
	move.l   d0,Var_MemStart(a6)                         ; Store register d0 into monitored memory start offset
	movea.l  d0,a5                                       ; Move register d0 to pointer a5
	move.b   #$3e,Var_DisasmBuffer(a6)                   ; Store constant $3e into disassembler output text buffer
	bsr.w    DrawConsoleLine                             ; Call subroutine to DrawConsoleLine
	sf.b     Var_CursorY(a6)                       ; Clear cursor Y coordinate flag (false).
	moveq    #$0,d6                                      ; Initialize register d6 to 0
	move.b   Var_MenuSubItem(a6),d6                      ; Load Var_MenuSubItem(a6) into register d6
Console_ParseHexAtCursor_Variant_Loc_0EEE:
	move.b   Var_MenuItem(a6),d0                         ; Load active menu item index into register d0
	cmp.b    Var_CursorY(a6),d0                          ; Compare register d0 against cursor vertical row coordinate
	beq.b    Console_ParseHexAtCursor_Variant_Loc_0EFA   ; Branch to Console_ParseHexAtCursor_Variant_Loc_0EFA if zero / equal
	jsr      (a4)                                        ; Jump to subroutine via pointer (a4)
Console_ParseHexAtCursor_Variant_Loc_0EFA:
	dbra     d6,Console_ParseHexAtCursor_Variant_Loc_0EEE	; Decrement loop counter d6 and loop back to Console_ParseHexAtCursor_Variant_Loc_0EEE if not exhausted
Console_ParseHexAtCursor_Variant_Loc_0EFE:
	movem.l  (a7)+,d1-d2/d7/a0                           ; Move multiple registers (a7)+ to d1-d2/d7/a0
	move.b   d2,Var_CursorX(a6)                          ; Store register d2 into cursor horizontal column coordinate
	rts                                                  ; Return from subroutine
; ============================================================================
; Data Block: Console_Parser_DisasmInst
; Purpose   : Keyboard command parser callback for disassembler instruction command (>,).
; ============================================================================
Console_Parser_DisasmInst:
	dc.w     $6100,$6BDA ; bsr.w $6bdc (external)
	dc.w     $6100,$6B2E ; bsr.w $6b34 (external)
	dc.w     $6100,$05BA ; bsr.w $5c4 (external)
	dc.w     $6100,$4BBA ; bsr.w $4bc8 (external)
	move.l   a5,$1820(a6)
	rts      
; ============================================================================
; Data Block: Console_Parser_Disasm
; Purpose   : Keyboard command parser callback for disassembler mode command (>_).
; ============================================================================
Console_Parser_Disasm:
	dc.w     $6100,$68A2 ; bsr.w $68a4 (external)
	move.l   a5,$1820(a6)
	dc.w     $6000,$05A4 ; bra.w $5ae (external)
Console_CursorNextChar:
	addq.b   #$1,Var_CursorX(a6)                         ; Add 1 to cursor horizontal column coordinate
	cmpi.b   #BLTBPTH,Var_CursorX(a6)                    ; Compare cursor horizontal column coordinate against constant BLTBPTH
	bne.w    Console_MenuUpdateItem_Rts                  ; Branch to Console_MenuUpdateItem_Rts if non-zero / not equal
	sf.b     Var_CursorX(a6)                       ; Clear cursor X coordinate flag (false).
Console_CursorNextLine:
	addq.b   #$1,Var_CursorY(a6)                         ; Add 1 to cursor vertical row coordinate
	move.b   Var_MenuIndex(a6),d0                        ; Load active menu header index into register d0
	cmp.b    Var_CursorY(a6),d0                          ; Compare register d0 against cursor vertical row coordinate
	bne.w    Console_MenuUpdateItem_Rts                  ; Branch to Console_MenuUpdateItem_Rts if non-zero / not equal
	subq.b   #$1,Var_CursorY(a6)                         ; Subtract 1 from cursor vertical row coordinate
	bra.w    Console_ScrollTextUp                        ; Unconditional branch to Console_ScrollTextUp
Console_CursorNextLine_MenuCheck:
	addq.b   #$1,Var_CursorY(a6)                         ; Add 1 to cursor vertical row coordinate
	move.b   Var_MenuIndex(a6),d0                        ; Load active menu header index into register d0
	cmp.b    Var_CursorY(a6),d0                          ; Compare register d0 against cursor vertical row coordinate
	bne.w    Console_MenuUpdateItem_Rts                  ; Branch to Console_MenuUpdateItem_Rts if non-zero / not equal
	subq.b   #$1,Var_CursorY(a6)                         ; Subtract 1 from cursor vertical row coordinate
	sf.b     Var_MenuOpenFlag(a6)                  ; Clear menu visibility flag flag (false).
	bra.b    Console_OpenMenu_Loc_0FD4                   ; Unconditional branch to Console_OpenMenu_Loc_0FD4
Console_CursorPrevChar:
	tst.b    Var_CursorX(a6)                       ; Check if Var_CursorX is set / active
	beq.b    Console_CursorPrevLine                      ; Branch to Console_CursorPrevLine if zero / equal
	subq.b   #$1,Var_CursorX(a6)                         ; Subtract 1 from cursor horizontal column coordinate
	rts                                                  ; Return from subroutine
Console_CursorPrevLine:
	tst.b    Var_CursorY(a6)                       ; Check if Var_CursorY is set / active
	beq.b    Console_CursorPrevLine_Loc_0F8A             ; Branch to Console_CursorPrevLine_Loc_0F8A if zero / equal
	subq.b   #$1,Var_CursorY(a6)                         ; Subtract 1 from cursor vertical row coordinate
	move.b   #$4f,Var_CursorX(a6)                        ; Store constant $4f into cursor horizontal column coordinate
Console_CursorPrevLine_Loc_0F8A:
	rts                                                  ; Return from subroutine
Console_OpenMenu:
	st.b     Var_MenuOpenFlag(a6)                  ; Set menu visibility flag flag (true).
	tst.b    Var_CursorY(a6)                       ; Check if Var_CursorY is set / active
	beq.b    Console_OpenMenu_Loc_0FD4                   ; Branch to Console_OpenMenu_Loc_0FD4 if zero / equal
	subq.b   #$1,Var_CursorY(a6)                         ; Subtract 1 from cursor vertical row coordinate
	rts                                                  ; Return from subroutine
Console_OpenMenu_Loc_0F9C:
	move.b   #BLTBPTH,Var_CursorX(a6)                    ; Store constant BLTBPTH into cursor horizontal column coordinate
	bsr.w    Console_GetBufferPtr                        ; Call subroutine to Console_GetBufferPtr
	movea.l  a5,a4                                       ; Move pointer a5 to pointer a4
	moveq    #$4d,d0                                     ; Initialize register d0 to constant $4d
Console_OpenMenu_Loc_0FAA:
	cmpi.b   #$3b,-(a4)                                  ; Compare -(a4) against constant $3b
	bne.b    Console_OpenMenu_Loc_0FB4                   ; Branch to Console_OpenMenu_Loc_0FB4 if non-zero / not equal
	movea.l  a4,a5                                       ; Move pointer a4 to pointer a5
	bra.b    Console_OpenMenu_Loc_0FC6                   ; Unconditional branch to Console_OpenMenu_Loc_0FC6
Console_OpenMenu_Loc_0FB4:
	subq.b   #$1,Var_CursorX(a6)                         ; Subtract 1 from cursor horizontal column coordinate
	dbra     d0,Console_OpenMenu_Loc_0FAA                ; Decrement loop counter d0 and loop back to Console_OpenMenu_Loc_0FAA if not exhausted
	move.b   #BLTBPTH,Var_CursorX(a6)                    ; Store constant BLTBPTH into cursor horizontal column coordinate
	subq.w   #$1,a5                                      ; Subtract 1 from pointer a5
	moveq    #$4d,d0                                     ; Initialize register d0 to constant $4d
Console_OpenMenu_Loc_0FC6:
	subq.b   #$1,Var_CursorX(a6)                         ; Subtract 1 from cursor horizontal column coordinate
	cmpi.b   #$20,-(a5)                                  ; Compare -(a5) against constant $20
	dbne     d0,Console_OpenMenu_Loc_0FC6                           ; Execute dbne instruction
	rts                                                  ; Return from subroutine
Console_OpenMenu_Loc_0FD4:
	tst.b    Var_MenuOpenFlag(a6)                  ; Check if Var_MenuOpenFlag is set / active
	beq.b    Console_OpenMenu_Loc_0FE4                   ; Branch to Console_OpenMenu_Loc_0FE4 if zero / equal
	bsr.w    Console_ScrollTextDown                      ; Call subroutine to Console_ScrollTextDown
	lea.l    Var_ConsoleBuffer+80(a6),a5                 ; Load address of console character buffer into pointer a5
	bra.b    Console_OpenMenu_Loc_0FFC                   ; Unconditional branch to Console_OpenMenu_Loc_0FFC
Console_OpenMenu_Loc_0FE4:
	bsr.w    Console_ScrollTextUp                        ; Call subroutine to Console_ScrollTextUp
	move.b   Var_MenuSubItem(a6),Var_CursorY(a6)         ; Store Var_MenuSubItem(a6) into cursor vertical row coordinate
	lea.l    $2574(a6),a5                                ; Load address of $2574(a6) into pointer a5
	tst.b    Var_VblankFlag(a6)                    ; Check if Var_VblankFlag is set / active
	beq.b    Console_OpenMenu_Loc_0FFC                   ; Branch to Console_OpenMenu_Loc_0FFC if zero / equal
	lea.l    $230(a5),a5                                 ; Load address of $230(a5) into pointer a5
Console_OpenMenu_Loc_0FFC:
	move.b   Var_CursorX(a6),d2                          ; Load cursor horizontal column coordinate into register d2
	movem.l  d1-d2/d7/a0,-(a7)                           ; Move multiple registers d1-d2/d7/a0 to -(a7)
	lea.l    DMACONR(a5),a3                              ; Load address of DMACON (DMA control write register) into pointer a3
	bsr.w    ParseHexNumber                              ; Call subroutine to ParseHexNumber
	pea.l    Console_OpenMenu_Loc_1060(pc)                          ; Push effective address of Console_OpenMenu_Loc_1060(pc) onto stack.
	cmpi.w   #$3e3b,(a5)                                 ; Compare (a5) against constant $3e3b
	beq.w    Console_OpenMenu_Loc_10BA                   ; Branch to Console_OpenMenu_Loc_10BA if zero / equal
	cmpi.w   #$3e3a,(a5)                                 ; Compare (a5) against constant $3e3a
	beq.w    Console_OpenMenu_Loc_10B2                   ; Branch to Console_OpenMenu_Loc_10B2 if zero / equal
	cmpi.w   #$3e7c,(a5)                                 ; Compare (a5) against constant $3e7c
	beq.w    Console_OpenMenu_Loc_10A2                   ; Branch to Console_OpenMenu_Loc_10A2 if zero / equal
	cmpi.w   #$3e5d,(a5)                                 ; Compare (a5) against constant $3e5d
	beq.b    Console_OpenMenu_Loc_109A                   ; Branch to Console_OpenMenu_Loc_109A if zero / equal
	cmpi.w   #$3e5b,(a5)                                 ; Compare (a5) against constant $3e5b
	beq.b    Console_OpenMenu_Loc_1092                   ; Branch to Console_OpenMenu_Loc_1092 if zero / equal
	cmpi.w   #$3e7d,(a5)                                 ; Compare (a5) against constant $3e7d
	beq.b    Console_OpenMenu_Loc_108A                   ; Branch to Console_OpenMenu_Loc_108A if zero / equal
	cmpi.w   #$3e7b,(a5)                                 ; Compare (a5) against constant $3e7b
	beq.b    Console_OpenMenu_Loc_1082                   ; Branch to Console_OpenMenu_Loc_1082 if zero / equal
	cmpi.w   #$3e2e,(a5)                                 ; Compare (a5) against constant $3e2e
	beq.b    Console_OpenMenu_Loc_10AA                   ; Branch to Console_OpenMenu_Loc_10AA if zero / equal
	cmpi.w   #$3e5f,(a5)                                 ; Compare (a5) against constant $3e5f
	beq.w    Console_OpenMenu_Loc_10DC                   ; Branch to Console_OpenMenu_Loc_10DC if zero / equal
	btst     #$0,d0                                      ; Test bit #$0 of register d0
	bne.b    Console_OpenMenu_Loc_105C                   ; Branch to Console_OpenMenu_Loc_105C if non-zero / not equal
	cmpi.w   #$3e2c,(a5)                                 ; Compare (a5) against constant $3e2c
	beq.w    Console_OpenMenu_Loc_111E                   ; Branch to Console_OpenMenu_Loc_111E if zero / equal
Console_OpenMenu_Loc_105C:
	subq.w   #$4,a7                                      ; Subtract constant $4 from stack pointer (a7)
Console_OpenMenu_Loc_105E:
	addq.w   #$8,a7                                      ; Add constant $8 to stack pointer (a7)
Console_OpenMenu_Loc_1060:
	sf.b     Var_CursorY(a6)                       ; Clear cursor Y coordinate flag (false).
	tst.b    Var_MenuOpenFlag(a6)                  ; Check if Var_MenuOpenFlag is set / active
	bne.b    Console_OpenMenu_Loc_1070                   ; Branch to Console_OpenMenu_Loc_1070 if non-zero / not equal
	move.b   Var_MenuItem(a6),Var_CursorY(a6)            ; Store active menu item index into cursor vertical row coordinate
Console_OpenMenu_Loc_1070:
	sf.b     Var_CursorX(a6)                       ; Clear cursor X coordinate flag (false).
	bsr.w    Console_DrawCursor                          ; Call subroutine to Console_DrawCursor
	movem.l  (a7)+,d1-d2/d7/a0                           ; Move multiple registers (a7)+ to d1-d2/d7/a0
	move.b   d2,Var_CursorX(a6)                          ; Store register d2 into cursor horizontal column coordinate
	rts                                                  ; Return from subroutine
Console_OpenMenu_Loc_1082:
	moveq    #$8,d1                                      ; Initialize register d1 to constant $8
	pea.l    Console_Draw_MenuOption8(pc)                         ; Push effective address of Console_Draw_MenuOption8(pc) onto stack.
	bra.b    Console_OpenMenu_Loc_10C0                   ; Unconditional branch to Console_OpenMenu_Loc_10C0
Console_OpenMenu_Loc_108A:
	moveq    #$6,d1                                      ; Initialize register d1 to constant $6
	pea.l    Console_Draw_MenuOption6(pc)                         ; Push effective address of Console_Draw_MenuOption6(pc) onto stack.
	bra.b    Console_OpenMenu_Loc_10C0                   ; Unconditional branch to Console_OpenMenu_Loc_10C0
Console_OpenMenu_Loc_1092:
	moveq    #$4,d1                                      ; Initialize register d1 to constant $4
	pea.l    Console_Draw_MenuOption4(pc)                         ; Push effective address of Console_Draw_MenuOption4(pc) onto stack.
	bra.b    Console_OpenMenu_Loc_10C0                   ; Unconditional branch to Console_OpenMenu_Loc_10C0
Console_OpenMenu_Loc_109A:
	moveq    #$2,d1                                      ; Initialize register d1 to constant $2
	pea.l    Console_Draw_MenuOption2(pc)                         ; Push effective address of Console_Draw_MenuOption2(pc) onto stack.
	bra.b    Console_OpenMenu_Loc_10C0                   ; Unconditional branch to Console_OpenMenu_Loc_10C0
Console_OpenMenu_Loc_10A2:
	moveq    #$1,d1                                      ; Initialize register d1 to 1
	pea.l    Console_Draw_MenuOption1(pc)                         ; Push effective address of Console_Draw_MenuOption1(pc) onto stack.
	bra.b    Console_OpenMenu_Loc_10C0                   ; Unconditional branch to Console_OpenMenu_Loc_10C0
Console_OpenMenu_Loc_10AA:
	moveq    #$4,d1                                      ; Initialize register d1 to constant $4
	pea.l    Console_Draw_SingleStep(pc)                         ; Push effective address of Console_Draw_SingleStep(pc) onto stack.
	bra.b    Console_OpenMenu_Loc_10C0                   ; Unconditional branch to Console_OpenMenu_Loc_10C0
Console_OpenMenu_Loc_10B2:
	moveq    #$10,d1                                     ; Initialize register d1 to constant $10
	pea.l    Console_Draw_Memory(pc)                         ; Push effective address of Console_Draw_Memory(pc) onto stack.
	bra.b    Console_OpenMenu_Loc_10C0                   ; Unconditional branch to Console_OpenMenu_Loc_10C0
Console_OpenMenu_Loc_10BA:
	moveq    #BLTCON0,d1                                 ; Initialize register d1 to constant BLTCON0
	pea.l    Console_Draw_Registers(pc)                         ; Push effective address of Console_Draw_Registers(pc) onto stack.
Console_OpenMenu_Loc_10C0:
	add.l    d1,d0                                       ; Add register d1 to register d0
	tst.b    Var_MenuOpenFlag(a6)                  ; Check if Var_MenuOpenFlag is set / active
	beq.b    Console_OpenMenu_Loc_10CE                   ; Branch to Console_OpenMenu_Loc_10CE if zero / equal
	sub.l    d1,d0                                       ; Subtract register d1 from register d0
	sub.l    d1,d0                                       ; Subtract register d1 from register d0
	bmi.b    Console_OpenMenu_Loc_105E                   ; Branch to Console_OpenMenu_Loc_105E if negative / minus
Console_OpenMenu_Loc_10CE:
	move.l   d0,Var_MemStart(a6)                         ; Store register d0 into monitored memory start offset
	add.l    d1,d0                                       ; Add register d1 to register d0
	move.l   d0,Var_MemEnd(a6)                           ; Store register d0 into monitored memory end offset
	moveq    #$2,d3                                      ; Initialize register d3 to constant $2
	rts                                                  ; Return from subroutine
Console_OpenMenu_Loc_10DC:
	tst.b    Var_MenuOpenFlag(a6)                  ; Check if Var_MenuOpenFlag is set / active
	beq.b    Console_OpenMenu_Loc_110C                   ; Branch to Console_OpenMenu_Loc_110C if zero / equal
	moveq    #$12,d1                                     ; Initialize register d1 to constant $12
Console_OpenMenu_Loc_10E4:
	subq.w   #$1,d1                                      ; Subtract 1 from register d1
	beq.b    Console_OpenMenu_Loc_110A                   ; Branch to Console_OpenMenu_Loc_110A if zero / equal
	movea.l  d0,a5                                       ; Move register d0 to pointer a5
	suba.l   d1,a5                                       ; Subtract register d1 from pointer a5
	move.l   a5,d4                                       ; Move pointer a5 to register d4
	bpl.b    Console_OpenMenu_Loc_10F2                   ; Branch to Console_OpenMenu_Loc_10F2 if positive / plus
	suba.l   a5,a5                                       ; Subtract pointer a5 from pointer a5
Console_OpenMenu_Loc_10F2:
	moveq    #$e,d4                                      ; Initialize register d4 to constant $e
Console_OpenMenu_Loc_10F4:
	bsr.w    Disasm_FormatOneLine                        ; Call subroutine to Disasm_FormatOneLine
	cmpa.l   d0,a5                                       ; Compare pointer a5 against register d0
	beq.b    Console_OpenMenu_Loc_1104                   ; Branch to Console_OpenMenu_Loc_1104 if zero / equal
	bhi.b    Console_OpenMenu_Loc_1102                              ; Branch to Console_OpenMenu_Loc_1102 if higher.
	dbra     d4,Console_OpenMenu_Loc_10F4                ; Decrement loop counter d4 and loop back to Console_OpenMenu_Loc_10F4 if not exhausted
Console_OpenMenu_Loc_1102:
	bra.b    Console_OpenMenu_Loc_10E4                   ; Unconditional branch to Console_OpenMenu_Loc_10E4
Console_OpenMenu_Loc_1104:
	bsr.b    Console_OpenMenu_Loc_111A                   ; Call subroutine to Console_OpenMenu_Loc_111A
	sf.b     Var_CursorY(a6)                       ; Clear cursor Y coordinate flag (false).
Console_OpenMenu_Loc_110A:
	rts                                                  ; Return from subroutine
Console_OpenMenu_Loc_110C:
	movea.l  d0,a5                                       ; Move register d0 to pointer a5
	bsr.w    Disasm_FormatOneLine                        ; Call subroutine to Disasm_FormatOneLine
	bsr.w    Disasm_FormatOneLine                        ; Call subroutine to Disasm_FormatOneLine
	move.l   a5,Var_MemStart(a6)                         ; Store pointer a5 into monitored memory start offset
Console_OpenMenu_Loc_111A:
	bra.w    RefreshAndDrawConsoleLine                   ; Unconditional branch to RefreshAndDrawConsoleLine
Console_OpenMenu_Loc_111E:
	tst.b    Var_MenuOpenFlag(a6)                  ; Check if Var_MenuOpenFlag is set / active
	beq.b    Console_OpenMenu_Loc_1166                   ; Branch to Console_OpenMenu_Loc_1166 if zero / equal
	moveq    #$34,d1                                     ; Initialize register d1 to constant $34
Console_OpenMenu_Loc_1126:
	subq.w   #$2,d1                                      ; Subtract constant $2 from register d1
	beq.b    Console_OpenMenu_Loc_1164                   ; Branch to Console_OpenMenu_Loc_1164 if zero / equal
	movea.l  d0,a5                                       ; Move register d0 to pointer a5
	suba.l   d1,a5                                       ; Subtract register d1 from pointer a5
	move.l   a5,d4                                       ; Move pointer a5 to register d4
	bpl.b    Console_OpenMenu_Loc_1134                   ; Branch to Console_OpenMenu_Loc_1134 if positive / plus
	suba.l   a5,a5                                       ; Subtract pointer a5 from pointer a5
Console_OpenMenu_Loc_1134:
	moveq    #$18,d4                                     ; Initialize register d4 to constant $18
Console_OpenMenu_Loc_1136:
	move.l   a5,Var_MemStart(a6)                         ; Store pointer a5 into monitored memory start offset
	bsr.w    Disasm_DisassembleInstruction               ; Call subroutine to Disasm_DisassembleInstruction
	cmpa.l   d0,a5                                       ; Compare pointer a5 against register d0
	beq.b    Console_OpenMenu_Loc_114A                   ; Branch to Console_OpenMenu_Loc_114A if zero / equal
	bhi.b    Console_OpenMenu_Loc_1148                              ; Branch to Console_OpenMenu_Loc_1148 if higher.
	dbra     d4,Console_OpenMenu_Loc_1136                ; Decrement loop counter d4 and loop back to Console_OpenMenu_Loc_1136 if not exhausted
Console_OpenMenu_Loc_1148:
	bra.b    Console_OpenMenu_Loc_1126                   ; Unconditional branch to Console_OpenMenu_Loc_1126
Console_OpenMenu_Loc_114A:
	bsr.w    Disasm_CheckBreakpoint                      ; Call subroutine to Disasm_CheckBreakpoint
	bsr.w    IsSpecialVectorOrJump                       ; Call subroutine to IsSpecialVectorOrJump
	bne.b    Console_OpenMenu_Loc_1158                   ; Branch to Console_OpenMenu_Loc_1158 if non-zero / not equal
	bsr.w    Console_ScrollTextDown                      ; Call subroutine to Console_ScrollTextDown
Console_OpenMenu_Loc_1158:
	bsr.w    RefreshAndDrawConsoleLine                   ; Call subroutine to RefreshAndDrawConsoleLine
	bsr.w    ShowSpecialVectorPlaceholder                ; Call subroutine to ShowSpecialVectorPlaceholder
	sf.b     Var_CursorY(a6)                       ; Clear cursor Y coordinate flag (false).
Console_OpenMenu_Loc_1164:
	rts                                                  ; Return from subroutine
Console_OpenMenu_Loc_1166:
	movea.l  d0,a5                                       ; Move register d0 to pointer a5
	bsr.w    Disasm_DisassembleInstruction               ; Call subroutine to Disasm_DisassembleInstruction
	move.l   a5,Var_MemStart(a6)                         ; Store pointer a5 into monitored memory start offset
	bsr.w    Disasm_DisassembleInstruction               ; Call subroutine to Disasm_DisassembleInstruction
	bsr.w    Disasm_CheckBreakpoint                      ; Call subroutine to Disasm_CheckBreakpoint
	bsr.w    RefreshAndDrawConsoleLine                   ; Call subroutine to RefreshAndDrawConsoleLine
	bsr.w    ShowSpecialVectorPlaceholder                ; Call subroutine to ShowSpecialVectorPlaceholder
	move.l   a5,Var_MemStart(a6)                         ; Store pointer a5 into monitored memory start offset
	rts                                                  ; Return from subroutine
Console_ClearScreen:
	pea.l    Console_DrawCursor(pc)                          ; Push effective address of Console_DrawCursor(pc) onto stack.
Console_ClearScreen_Body:
	movea.l  Var_Bitplane1(a6),a5                        ; Load first bitplane memory pointer into pointer a5
	moveq    #$0,d0                                      ; Initialize register d0 to 0
	move.w   #$13ff,d5                                   ; Move constant $13ff to register d5
Console_ClearScreen_PlaneLoop:
	move.l   d0,(a5)+                                    ; Move register d0 to (a5)+
	dbra     d5,Console_ClearScreen_PlaneLoop            ; Decrement loop counter d5 and loop back to Console_ClearScreen_PlaneLoop if not exhausted
	lea.l    Var_ConsoleBuffer(a6),a5                    ; Load address of console character buffer into pointer a5
	moveq    #$20,d0                                     ; Initialize register d0 to constant $20
	move.w   #$9ff,d5                                    ; Move constant $9ff to register d5
Console_ClearScreen_BufferLoop:
	move.b   d0,(a5)+                                    ; Move register d0 to (a5)+
	dbra     d5,Console_ClearScreen_BufferLoop           ; Decrement loop counter d5 and loop back to Console_ClearScreen_BufferLoop if not exhausted
	lea.l    Var_DisasmBuffer(a6),a5                     ; Load address of disassembler output text buffer into pointer a5
	moveq    #$4f,d5                                     ; Initialize register d5 to constant $4f
Console_ClearScreen_DisasmLoop:
	move.b   d0,(a5)+                                    ; Move register d0 to (a5)+
	dbra     d5,Console_ClearScreen_DisasmLoop           ; Decrement loop counter d5 and loop back to Console_ClearScreen_DisasmLoop if not exhausted
	sf.b     Var_CursorY(a6)                       ; Clear cursor Y coordinate flag (false).
	sf.b     Var_CursorX(a6)                       ; Clear cursor X coordinate flag (false).
	rts                                                  ; Return from subroutine
Console_InsertSpaceAtCursor:
	bsr.w    Console_GetBufferPtr                        ; Call subroutine to Console_GetBufferPtr
	movea.l  a5,a4                                       ; Move pointer a5 to pointer a4
	bsr.w    Console_GetScreenBitplanePtr                ; Call subroutine to Console_GetScreenBitplanePtr
	moveq    #$4e,d2                                     ; Initialize register d2 to constant $4e
	move.b   Var_CursorX(a6),d3                          ; Load cursor horizontal column coordinate into register d3
	ext.w    d3
	sub.w    d3,d2                                       ; Subtract register d3 from register d2
	lea.l    (a5,d2.w),a5                                ; Load address of (a5,d2.w) into pointer a5
	lea.l    (a4,d2.w),a4                                ; Load address of (a4,d2.w) into pointer a4
	bcs.b    Console_InsertSpace_ShiftLoop_Loc_11F8      ; Branch to Console_InsertSpace_ShiftLoop_Loc_11F8 if carry set (less than)
Console_InsertSpace_ShiftLoop:
	moveq    #$7,d3                                      ; Initialize register d3 to constant $7
Console_InsertSpace_ShiftLoop_Loc_11E0:
	move.b   (a5),$1(a5)                                 ; Move (a5) to $1(a5)
	lea.l    BLTBPTH(a5),a5                              ; Load address of BLTBPTH(a5) into pointer a5
	dbra     d3,Console_InsertSpace_ShiftLoop_Loc_11E0   ; Decrement loop counter d3 and loop back to Console_InsertSpace_ShiftLoop_Loc_11E0 if not exhausted
	lea.l    -$281(a5),a5                                ; Load address of -$281(a5) into pointer a5
	move.b   (a4)+,(a4)                                  ; Move (a4)+ to (a4)
	subq.w   #$2,a4                                      ; Subtract constant $2 from pointer a4
	dbra     d2,Console_InsertSpace_ShiftLoop            ; Decrement loop counter d2 and loop back to Console_InsertSpace_ShiftLoop if not exhausted
Console_InsertSpace_ShiftLoop_Loc_11F8:
	moveq    #$7,d5                                      ; Initialize register d5 to constant $7
Console_InsertSpace_ClearLoop:
	sf.b     $1(a5)                                ; Clear $1(a5) flag (false).
	lea.l    BLTBPTH(a5),a5                              ; Load address of BLTBPTH(a5) into pointer a5
	dbra     d5,Console_InsertSpace_ClearLoop            ; Decrement loop counter d5 and loop back to Console_InsertSpace_ClearLoop if not exhausted
	move.b   #$20,$1(a4)                                 ; Move constant $20 to $1(a4)
Console_InsertSpace_Exit:
	rts                                                  ; Return from subroutine
Console_DeletePrevChar:
	cmpi.b   #$1,Var_CursorX(a6)                         ; Compare cursor horizontal column coordinate against 1
	bls.b    Console_InsertSpace_Exit                              ; Branch to Console_InsertSpace_Exit if lower or same.
	bsr.w    Console_CursorPrevChar                      ; Call subroutine to Console_CursorPrevChar
Console_DeleteCharAtCursor:
	bsr.w    Console_GetBufferPtr                        ; Call subroutine to Console_GetBufferPtr
	movea.l  a5,a4                                       ; Move pointer a5 to pointer a4
	bsr.w    Console_GetScreenBitplanePtr                ; Call subroutine to Console_GetScreenBitplanePtr
	moveq    #$4e,d2                                     ; Initialize register d2 to constant $4e
	sub.b    Var_CursorX(a6),d2                          ; Subtract cursor horizontal column coordinate from register d2
	bcs.b    Console_DeleteChar_ShiftSubLoop_Loc_1246    ; Branch to Console_DeleteChar_ShiftSubLoop_Loc_1246 if carry set (less than)
Console_DeleteChar_ShiftLoop:
	moveq    #$7,d5                                      ; Initialize register d5 to constant $7
Console_DeleteChar_ShiftSubLoop:
	move.b   $1(a5),(a5)                                 ; Move $1(a5) to (a5)
	lea.l    BLTBPTH(a5),a5                              ; Load address of BLTBPTH(a5) into pointer a5
	dbra     d5,Console_DeleteChar_ShiftSubLoop          ; Decrement loop counter d5 and loop back to Console_DeleteChar_ShiftSubLoop if not exhausted
	lea.l    -$27f(a5),a5                                ; Load address of -$27f(a5) into pointer a5
	move.b   $1(a4),(a4)+                                ; Move $1(a4) to (a4)+
	dbra     d2,Console_DeleteChar_ShiftLoop             ; Decrement loop counter d2 and loop back to Console_DeleteChar_ShiftLoop if not exhausted
Console_DeleteChar_ShiftSubLoop_Loc_1246:
	moveq    #$7,d5                                      ; Initialize register d5 to constant $7
Console_DeleteChar_ClearLoop:
	sf.b     (a5)
	lea.l    BLTBPTH(a5),a5                              ; Load address of BLTBPTH(a5) into pointer a5
	dbra     d5,Console_DeleteChar_ClearLoop             ; Decrement loop counter d5 and loop back to Console_DeleteChar_ClearLoop if not exhausted
	move.b   #$20,(a4)                                   ; Move constant $20 to (a4)
	rts                                                  ; Return from subroutine
Console_ScrollOrSwap:
	movem.l  d1/a0,-(a7)                                 ; Move multiple registers d1/a0 to -(a7)
	move.w   Var_CursorY(a6),-(a7)                       ; Load cursor vertical row coordinate into -(a7)
	lea.l    Var_ConsoleBuffer(a6),a1                    ; Load address of console character buffer into pointer a1
	move.w   #$27f,d2                                    ; Move constant $27f to register d2
Console_ScrollOrSwap_Loop:
	move.l   $a00(a1),d3                                 ; Move $a00(a1) to register d3
	move.l   (a1),$a00(a1)                               ; Move (a1) to $a00(a1)
	move.l   d3,(a1)+                                    ; Move register d3 to (a1)+
	dbra     d2,Console_ScrollOrSwap_Loop                ; Decrement loop counter d2 and loop back to Console_ScrollOrSwap_Loop if not exhausted
	sf.b     Var_CursorY(a6)                       ; Clear cursor Y coordinate flag (false).
	lea.l    Var_ConsoleBuffer(a6),a1                    ; Load address of console character buffer into pointer a1
	moveq    #$1f,d2                                     ; Initialize register d2 to constant $1f
Console_ScrollOrSwap_DrawLoop:
	lea.l    Var_DisasmBuffer(a6),a0                     ; Load address of disassembler output text buffer into pointer a0
	moveq    #$4f,d0                                     ; Initialize register d0 to constant $4f
Console_ScrollOrSwap_DrawSubLoop:
	move.b   (a1)+,(a0)+                                 ; Copy word/byte data from source pointer a1 to destination a0
	dbra     d0,Console_ScrollOrSwap_DrawSubLoop         ; Decrement loop counter d0 and loop back to Console_ScrollOrSwap_DrawSubLoop if not exhausted
	bsr.w    DrawConsoleLine                             ; Call subroutine to DrawConsoleLine
	addq.b   #$1,Var_CursorY(a6)                         ; Add 1 to cursor vertical row coordinate
	dbra     d2,Console_ScrollOrSwap_DrawLoop            ; Decrement loop counter d2 and loop back to Console_ScrollOrSwap_DrawLoop if not exhausted
	move.w   Var_SavedCursorPos(a6),Var_CursorY(a6)      ; Store Var_SavedCursorPos(a6) into cursor vertical row coordinate
	move.w   (a7)+,Var_SavedCursorPos(a6)                ; Store (a7)+ into Var_SavedCursorPos(a6)
	movem.l  (a7)+,d1/a0                                 ; Move multiple registers (a7)+ to d1/a0
	rts                                                  ; Return from subroutine
Console_DrawMenuPage:
	movem.l  d1/a0,-(a7)                                 ; Move multiple registers d1/a0 to -(a7)
	bsr.w    Console_ClearScreen                         ; Call subroutine to Console_ClearScreen
	sf.b     Var_CursorX(a6)                       ; Clear cursor X coordinate flag (false).
	move.b   Var_MenuSubItem(a6),d2                      ; Load Var_MenuSubItem(a6) into register d2
	ext.w    d2
	movea.l  Var_WindowPtr(a6),a1                        ; Load pointer to active window context into pointer a1
Console_DrawMenuPage_Loop:
	tst.b    (a1)                                        ; Test status of (a1) (for zero or negative)
	beq.b    Console_DrawMenuPage_Empty                  ; Branch to Console_DrawMenuPage_Empty if zero / equal
	lea.l    Var_DisasmBuffer(a6),a0                     ; Load address of disassembler output text buffer into pointer a0
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	lea.l    Var_DisasmBuffer+22(a6),a0                  ; Load address of disassembler output text buffer into pointer a0
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	tst.b    (a1)                                        ; Test status of (a1) (for zero or negative)
	beq.b    Console_DrawMenuPage_Next                   ; Branch to Console_DrawMenuPage_Next if zero / equal
	lea.l    Var_DisasmBuffer+39(a6),a0                  ; Load address of disassembler output text buffer into pointer a0
	move.b   #DENISEID,(a0)+                             ; Move DENISEID (Denise chip ID register) to (a0)+
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	lea.l    Var_DisasmBuffer+62(a6),a0                  ; Load address of disassembler output text buffer into pointer a0
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
Console_DrawMenuPage_Next:
	bsr.w    RefreshAndDrawConsoleLine                   ; Call subroutine to RefreshAndDrawConsoleLine
	dbra     d2,Console_DrawMenuPage_Loop                ; Decrement loop counter d2 and loop back to Console_DrawMenuPage_Loop if not exhausted
	tst.b    (a1)                                        ; Test status of (a1) (for zero or negative)
	bne.b    Console_DrawMenuPage_Exit                   ; Branch to Console_DrawMenuPage_Exit if non-zero / not equal
Console_DrawMenuPage_Empty:
	lea.l    SectorVerify_BranchOffset(pc),a1                            ; Load address of SectorVerify_BranchOffset(pc) into pointer a1
	lea.l    $7ffe(a1),a1                                ; Offset pointer to target main menu template string (bypasses 32KB PC-relative limit)
Console_DrawMenuPage_Exit:
	move.l   a1,Var_WindowPtr(a6)                        ; Store pointer a1 into pointer to active window context
	bsr.w    Console_DrawCursor                          ; Call subroutine to Console_DrawCursor
	movem.l  (a7)+,d1/a0                                 ; Move multiple registers (a7)+ to d1/a0
	rts                                                  ; Return from subroutine
ProcessCommand_Entry:
	movem.l  d1/d7/a0,-(a7)                              ; Move multiple registers d1/d7/a0 to -(a7)
	move.b   Var_CursorX(a6),d6                          ; Load cursor horizontal column coordinate into register d6
	sf.b     Var_CursorX(a6)                       ; Clear cursor X coordinate flag (false).
	bsr.w    Console_CursorNextLine                      ; Call subroutine to Console_CursorNextLine
	bsr.w    Console_GetBufferPtr                        ; Call subroutine to Console_GetBufferPtr
	lea.l    -BLTBPTH(a5),a5                             ; Load address of -BLTBPTH(a5) into pointer a5
	cmpi.b   #$3e,(a5)                                   ; Compare (a5) against constant $3e
	bne.w    ProcessCommand_Error                        ; Branch to ProcessCommand_Error if non-zero / not equal
	lea.l    Command_NamesTable(pc),a3                            ; Load address of Command_NamesTable(pc) into pointer a3
	lea.l    Command_OffsetsTable(pc),a4                            ; Load address of Command_OffsetsTable(pc) into pointer a4
MatchCommand_Loop:
	sf.b     d2
	lea.l    $1(a5),a0                                   ; Load address of $1(a5) into pointer a0
	cmpi.b   #$20,(a0)                                   ; Compare (a0) against constant $20
	beq.b    MatchCommand_CheckChar                      ; Branch to MatchCommand_CheckChar if zero / equal
	lea.l    $162e(a6),a1                                ; Load address of $162e(a6) into pointer a1
	move.b   (a0)+,(a1)+                                 ; Copy word/byte data from source pointer a0 to destination a1
	move.b   (a0)+,(a1)+                                 ; Copy word/byte data from source pointer a0 to destination a1
	move.b   (a0)+,(a1)+                                 ; Copy word/byte data from source pointer a0 to destination a1
	move.b   (a0),(a1)                                   ; Move (a0) to (a1)
	subq.w   #$3,a0                                      ; Subtract constant $3 from pointer a0
MatchCommand_CheckChar:
	move.b   (a3),d0                                     ; Move (a3) to register d0
	beq.w    ProcessCommand_Error                        ; Branch to ProcessCommand_Error if zero / equal
	move.b   (a0)+,d1                                    ; Move (a0)+ to register d1
	tst.b    d2                                          ; Test status of register d2 (for zero or negative)
	bne.b    MatchCommand_NextChar                       ; Branch to MatchCommand_NextChar if non-zero / not equal
	bclr     #$7,d0                                      ; Clear bit #$7 of register d0
	cmp.b    d0,d1                                       ; Compare register d1 against register d0
	sne.b    d2
MatchCommand_NextChar:
	btst     #$7,(a3)+                                   ; Test bit #$7 of (a3)+
	beq.b    MatchCommand_CheckChar                      ; Branch to MatchCommand_CheckChar if zero / equal
	addq.w   #$2,a4                                      ; Add constant $2 to pointer a4
	tst.b    d2                                          ; Test status of register d2 (for zero or negative)
	bne.b    MatchCommand_Loop                           ; Branch to MatchCommand_Loop if non-zero / not equal
	move.w   (a4),d3                                     ; Move (a4) to register d3
	lea.l    Command_OffsetsTable_Base(pc),a4                            ; Load address of Command_OffsetsTable_Base(pc) into pointer a4
	adda.w   d3,a4                                       ; Add register d3 to pointer a4
	cmpi.b   #$20,$1(a5)                                 ; Compare $1(a5) against constant $20
	beq.b    ParseArguments_Start                        ; Branch to ParseArguments_Start if zero / equal
	lea.l    Var_InputLength(a6),a1                      ; Load address of Var_InputLength(a6) into pointer a1
	lea.l    Var_DisasmBuffer+81(a6),a2                  ; Load address of disassembler output text buffer into pointer a2
	moveq    #$0,d3                                      ; Initialize register d3 to 0
	move.b   (a1),d3                                     ; Move (a1) to register d3
	divu.w   #$a,d3
	swap     d3
	mulu.w   #$4f,d3
	adda.l   d3,a2                                       ; Add register d3 to pointer a2
	moveq    #$4e,d2                                     ; Initialize register d2 to constant $4e
SaveCommandHistory_Loop:
	move.b   $1(a5,d2.w),(a2,d2.w)                       ; Move $1(a5,d2.w) to (a2,d2.w)
	dbra     d2,SaveCommandHistory_Loop                  ; Decrement loop counter d2 and loop back to SaveCommandHistory_Loop if not exhausted
	addi.b   #$1,(a1)                                    ; Add 1 to (a1)
	cmpi.b   #$a,(a1)                                    ; Compare (a1) against constant $a
	bne.b    SaveCommandHistory_Next                     ; Branch to SaveCommandHistory_Next if non-zero / not equal
	sf.b     (a1)
SaveCommandHistory_Next:
	move.b   (a1),-$1(a1)                                ; Move (a1) to -$1(a1)
ParseArguments_Start:
	lea.l    Var_MemStart(a6),a3                         ; Load address of monitored memory start offset into pointer a3
	suba.l   a2,a2                                       ; Subtract pointer a2 from pointer a2
	moveq    #$0,d3                                      ; Initialize register d3 to 0
	lea.l    $4f(a5),a1                                  ; Load address of $4f(a5) into pointer a1
ParseArguments_SkipSpaces:
	cmpi.b   #$27,(a0)                                   ; Compare (a0) against constant $27
	beq.b    ParseArguments_CheckQuote                   ; Branch to ParseArguments_CheckQuote if zero / equal
	cmpi.b   #$20,(a0)                                   ; Compare (a0) against constant $20
	bne.b    ParseArguments_ReadHex                      ; Branch to ParseArguments_ReadHex if non-zero / not equal
	addq.w   #$1,a0                                      ; Add 1 to pointer a0
	cmpa.l   a0,a1                                       ; Compare pointer a1 against pointer a0
	bne.b    ParseArguments_SkipSpaces                   ; Branch to ParseArguments_SkipSpaces if non-zero / not equal
ParseArguments_ReadHex:
	moveq    #$7,d2                                      ; Initialize register d2 to constant $7
	moveq    #$0,d0                                      ; Initialize register d0 to 0
ParseArguments_HexDigitLoop:
	cmpa.l   a0,a1                                       ; Compare pointer a1 against pointer a0
	beq.b    ProcessCommand_Dispatch                     ; Branch to ProcessCommand_Dispatch if zero / equal
	move.b   (a0)+,d1                                    ; Move (a0)+ to register d1
	cmpi.b   #$20,d1                                     ; Compare register d1 against constant $20
	beq.b    ParseArguments_StoreArg                     ; Branch to ParseArguments_StoreArg if zero / equal
	subi.b   #$30,d1                                     ; Subtract constant $30 from register d1
	bcs.b    ParseArguments_CheckQuote                   ; Branch to ParseArguments_CheckQuote if carry set (less than)
	cmpi.b   #$9,d1                                      ; Compare register d1 against constant $9
	ble.b    ParseArguments_HexDigitShift                ; Branch to ParseArguments_HexDigitShift if less or equal
	bclr     #$5,d1                                      ; Clear bit #$5 of register d1
	cmpi.b   #$11,d1                                     ; Compare register d1 against constant $11
	blt.b    ParseArguments_CheckQuote                   ; Branch to ParseArguments_CheckQuote if less than
	cmpi.b   #$16,d1                                     ; Compare register d1 against constant $16
	bgt.b    ParseArguments_CheckQuote                   ; Branch to ParseArguments_CheckQuote if greater than
	subq.b   #$7,d1                                      ; Subtract constant $7 from register d1
ParseArguments_HexDigitShift:
	lsl.l    #$4,d0
	or.b     d1,d0                                       ; Logical OR register d0 with register d1
	dbra     d2,ParseArguments_HexDigitLoop              ; Decrement loop counter d2 and loop back to ParseArguments_HexDigitLoop if not exhausted
ParseArguments_StoreArg:
	move.l   d0,(a3)+                                    ; Move register d0 to (a3)+
	addq.b   #$1,d3                                      ; Add 1 to register d3
	cmpi.b   #$10,d3                                     ; Compare register d3 against constant $10
	bne.b    ParseArguments_SkipSpaces                   ; Branch to ParseArguments_SkipSpaces if non-zero / not equal
ParseArguments_CheckQuote:
	sf.b     d7
	subq.w   #$1,a0                                      ; Subtract 1 from pointer a0
	movea.l  a5,a2                                       ; Move pointer a5 to pointer a2
ParseArguments_QuoteLoop:
	cmpi.b   #$22,(a2)+                                  ; Compare (a2)+ against constant $22
	beq.b    ProcessCommand_Dispatch                     ; Branch to ProcessCommand_Dispatch if zero / equal
	cmpa.l   a2,a1                                       ; Compare pointer a1 against pointer a2
	bne.b    ParseArguments_QuoteLoop                    ; Branch to ParseArguments_QuoteLoop if non-zero / not equal
	suba.l   a2,a2                                       ; Subtract pointer a2 from pointer a2
ProcessCommand_Dispatch:
	move.l   a5,Var_ScreenRowPointer(a6)                 ; Store pointer a5 into pointer to active screen row
	moveq    #BLTBPTH,d0                                 ; Initialize register d0 to constant BLTBPTH
	add.l    d0,Var_ScreenRowPointer(a6)                 ; Add register d0 to pointer to active screen row
	jsr      (a4)                                        ; Jump to subroutine via pointer (a4)
	tst.b    d7                                          ; Test status of register d7 (for zero or negative)
	bne.b    ProcessCommand_RedrawCursor                 ; Branch to ProcessCommand_RedrawCursor if non-zero / not equal
	moveq    #$3f,d0                                     ; Initialize register d0 to constant $3f
	bsr.w    Console_DrawChar                            ; Call subroutine to Console_DrawChar
ProcessCommand_Error:
	moveq    #$3f,d0                                     ; Initialize register d0 to constant $3f
	bsr.w    Console_DrawChar                            ; Call subroutine to Console_DrawChar
ProcessCommand_Exit:
	bsr.w    Console_CursorNextLine                      ; Call subroutine to Console_CursorNextLine
	sf.b     Var_CursorX(a6)                       ; Clear cursor X coordinate flag (false).
ProcessCommand_RedrawCursor:
	tst.b    Var_CursorX(a6)                       ; Check if Var_CursorX is set / active
	bne.b    ProcessCommand_Done                         ; Branch to ProcessCommand_Done if non-zero / not equal
	bsr.w    Console_DrawCursor                          ; Call subroutine to Console_DrawCursor
ProcessCommand_Done:
	movem.l  (a7)+,d1/d7/a0                              ; Move multiple registers (a7)+ to d1/d7/a0
	rts                                                  ; Return from subroutine
ProcessCommand_Abort:
	movem.l  d1/d7/a0,-(a7)                              ; Move multiple registers d1/d7/a0 to -(a7)
	bra.b    ProcessCommand_Exit                         ; Unconditional branch to ProcessCommand_Exit
; ============================================================================
; Function: LockMonitor
; Purpose : Enters critical section and updates monitor status flags.
; ============================================================================
LockMonitor:
	bset     #$0,Var_MonitorLockState(a6)                ; Set bit #$0 of Var_MonitorLockState(a6)
	btst     #$1,Var_MonitorLockState(a6)                ; Test bit #$1 of Var_MonitorLockState(a6)
	beq.b    UnlockMonitor_Loc_147E                      ; Branch to UnlockMonitor_Loc_147E if zero / equal
UnlockMonitor_Blink:
	bra.w    Console_ToggleCursorBlink                   ; Unconditional branch to Console_ToggleCursorBlink
; ============================================================================
; Function: UnlockMonitor
; Purpose : Exits critical section and updates monitor status flags.
; ============================================================================
UnlockMonitor:
	btst     #$1,Var_MonitorLockState(a6)                ; Test bit #$1 of Var_MonitorLockState(a6)
	bne.b    UnlockMonitor_Loc_1478                      ; Branch to UnlockMonitor_Loc_1478 if non-zero / not equal
	bsr.b    UnlockMonitor_Blink                         ; Call subroutine to UnlockMonitor_Blink
UnlockMonitor_Loc_1478:
	bclr     #$0,Var_MonitorLockState(a6)                ; Clear bit #$0 of Var_MonitorLockState(a6)
UnlockMonitor_Loc_147E:
	rts                                                  ; Return from subroutine
Printer_PrintBufferLine:
	move.l   d1,-(a7)                                    ; Move register d1 to -(a7)
	moveq    #$4f,d1                                     ; Initialize register d1 to constant $4f
	lea.l    Var_DisasmBuffer(a6),a0                     ; Load address of disassembler output text buffer into pointer a0
Printer_PrintBufferLine_CharLoop:
	btst     #$0,$bfd000.l                               ; Test bit #$0 of $bfd000.l
	bne.b    Printer_WriteChar_Exit                      ; Branch to Printer_WriteChar_Exit if non-zero / not equal
	move.b   (a0)+,d0                                    ; Move (a0)+ to register d0
	bsr.b    Printer_WriteChar                           ; Call subroutine to Printer_WriteChar
	dbra     d1,Printer_PrintBufferLine_CharLoop         ; Decrement loop counter d1 and loop back to Printer_PrintBufferLine_CharLoop if not exhausted
	moveq    #$d,d0                                      ; Initialize register d0 to constant $d
	bsr.b    Printer_WriteChar                           ; Call subroutine to Printer_WriteChar
	moveq    #$b,d0                                      ; Initialize register d0 to constant $b
	bsr.b    Printer_WriteChar                           ; Call subroutine to Printer_WriteChar
	move.l   (a7)+,d1                                    ; Move (a7)+ to register d1
	rts                                                  ; Return from subroutine
Printer_WriteChar:
	move.b   d0,CIAA_PRB.l                         ; Send byte to CIA-A Port B (Parallel Port)
	moveq    #BLTAMOD,d0                                 ; Initialize register d0 to constant BLTAMOD
Printer_WriteChar_DelayLoop:
	tst.b    ExecBase.w                            ; Check if ExecBase.w is set / active
	dbra     d0,Printer_WriteChar_DelayLoop              ; Decrement loop counter d0 and loop back to Printer_WriteChar_DelayLoop if not exhausted
Printer_WriteChar_WaitBusy:
	btst     #$0,$bfd000.l                               ; Test bit #$0 of $bfd000.l
	beq.b    Printer_WriteChar_Exit                      ; Branch to Printer_WriteChar_Exit if zero / equal
	btst     #$2,$dff016.l                               ; Test bit #$2 of $dff016.l
	bne.b    Printer_WriteChar_WaitBusy                  ; Branch to Printer_WriteChar_WaitBusy if non-zero / not equal
Printer_WriteChar_Exit:
	rts                                                  ; Return from subroutine
RefreshAndDrawConsoleLine:
	tst.b    Var_ScreenRefreshFlag(a6)             ; Check if Var_ScreenRefreshFlag is set / active
	beq.b    RefreshAndDrawConsoleLine_Loc_14D4          ; Branch to RefreshAndDrawConsoleLine_Loc_14D4 if zero / equal
	bsr.b    Printer_PrintBufferLine                     ; Call subroutine to Printer_PrintBufferLine
RefreshAndDrawConsoleLine_Loc_14D4:
	bsr.b    DrawConsoleLine                             ; Call subroutine to DrawConsoleLine
	lea.l    Var_DisasmBuffer(a6),a0                     ; Load address of disassembler output text buffer into pointer a0
	sf.b     Var_CursorX(a6)                       ; Clear cursor X coordinate flag (false).
	bra.w    Console_CursorNextLine                      ; Unconditional branch to Console_CursorNextLine
DrawConsoleLine:
	movem.l  d1-d3/a1-a5,-(a7)                           ; Move multiple registers d1-d3/a1-a5 to -(a7)
	move.l   a6,-(a7)                                    ; Move monitor context base (a6) to -(a7)
	lea.l    Var_DisasmBuffer(a6),a0                     ; Load address of disassembler output text buffer into pointer a0
	lea.l    Var_CharTranslationTable(a6),a1             ; Load address of Var_CharTranslationTable(a6) into pointer a1
	movea.l  Var_Bitplane1(a6),a2                        ; Load first bitplane memory pointer into pointer a2
	move.l   a1,d3                                       ; Move pointer a1 to register d3
	moveq    #$0,d0                                      ; Initialize register d0 to 0
	move.b   Var_CursorY(a6),d0                          ; Load cursor vertical row coordinate into register d0
	mulu.w   #BLTBPTH,d0                           ; Multiply d0 by blitter source B pointer (high word).
	lea.l    Var_ConsoleBuffer(a6),a6                    ; Load address of console character buffer into monitor context base (a6)
	adda.w   d0,a6                                       ; Add register d0 to monitor context base (a6)
	lsl.w    #$3,d0
	adda.w   d0,a2                                       ; Add register d0 to pointer a2
	lea.l    BLTBPTH(a2),a3                              ; Load address of BLTBPTH(a2) into pointer a3
	lea.l    BLTBPTH(a3),a4                              ; Load address of BLTBPTH(a3) into pointer a4
	lea.l    BLTBPTH(a4),a5                              ; Load address of BLTBPTH(a4) into pointer a5
	moveq    #$4f,d2                                     ; Initialize register d2 to constant $4f
DrawConsoleLine_Loc_1518:
	moveq    #$0,d0                                      ; Initialize register d0 to 0
	move.b   (a0),d0                                     ; Move (a0) to register d0
	moveq    #BLTCMOD,d1                                 ; Initialize register d1 to constant BLTCMOD
	and.b    d0,d1                                       ; Logical AND register d1 with register d0
	bne.b    DrawConsoleLine_Loc_1524                    ; Branch to DrawConsoleLine_Loc_1524 if non-zero / not equal
	moveq    #$20,d0                                     ; Initialize register d0 to constant $20
DrawConsoleLine_Loc_1524:
	moveq    #$20,d1                                     ; Initialize register d1 to constant $20
	move.b   d0,(a6)+                                    ; Move register d0 to (a6)+
	bpl.b    DrawConsoleLine_Loc_152C                    ; Branch to DrawConsoleLine_Loc_152C if positive / plus
	sub.b    d1,d0                                       ; Subtract register d1 from register d0
DrawConsoleLine_Loc_152C:
	sub.b    d1,d0                                       ; Subtract register d1 from register d0
	move.b   d1,(a0)+                                    ; Move register d1 to (a0)+
	lsl.w    #$3,d0
	movea.l  d3,a1                                       ; Move register d3 to pointer a1
	adda.w   d0,a1                                       ; Add register d0 to pointer a1
	move.b   (a1)+,(a2)+                                 ; Move (a1)+ to (a2)+
	move.b   (a1)+,(a3)+                                 ; Move (a1)+ to (a3)+
	move.b   (a1)+,(a4)+                                 ; Move (a1)+ to (a4)+
	move.b   (a1)+,(a5)+                                 ; Move (a1)+ to (a5)+
	move.b   (a1)+,$13f(a2)                              ; Move (a1)+ to $13f(a2)
	move.b   (a1)+,$13f(a3)                              ; Move (a1)+ to $13f(a3)
	move.b   (a1)+,$13f(a4)                              ; Move (a1)+ to $13f(a4)
	move.b   (a1),$13f(a5)                               ; Move (a1) to $13f(a5)
	dbra     d2,DrawConsoleLine_Loc_1518                 ; Decrement loop counter d2 and loop back to DrawConsoleLine_Loc_1518 if not exhausted
	movea.l  (a7)+,a6                                    ; Move (a7)+ to monitor context base (a6)
	tst.b    Var_ScreenFlags(a6)                   ; Check if Var_ScreenFlags is set / active
	beq.b    DrawConsoleLine_Loc_1572                    ; Branch to DrawConsoleLine_Loc_1572 if zero / equal
	moveq    #$7,d2                                      ; Initialize register d2 to constant $7
	lea.l    -$4e(a2),a2                                 ; Load address of -$4e(a2) into pointer a2
DrawConsoleLine_Loc_1560:
	not.l    (a2)
	not.l    $4(a2)                                ; Execute not.l instruction
	lea.l    BLTBPTH(a2),a2                              ; Load address of BLTBPTH(a2) into pointer a2
	dbra     d2,DrawConsoleLine_Loc_1560                 ; Decrement loop counter d2 and loop back to DrawConsoleLine_Loc_1560 if not exhausted
	sf.b     Var_ScreenFlags(a6)                   ; Clear screen display mode flags flag (false).
DrawConsoleLine_Loc_1572:
	movem.l  (a7)+,d1-d3/a1-a5                           ; Move multiple registers (a7)+ to d1-d3/a1-a5
	bra.w    CacheFlush_040                              ; Unconditional branch to CacheFlush_040
Console_GetBufferPtr:
	lea.l    Var_ConsoleBuffer(a6),a5                    ; Load address of console character buffer into pointer a5
	moveq    #$0,d5                                      ; Initialize register d5 to 0
	move.b   Var_CursorX(a6),d5                          ; Load cursor horizontal column coordinate into register d5
	adda.l   d5,a5                                       ; Add register d5 to pointer a5
	move.b   Var_CursorY(a6),d5                          ; Load cursor vertical row coordinate into register d5
	mulu.w   #BLTBPTH,d5                           ; Multiply d5 by blitter source B pointer (high word).
	adda.l   d5,a5                                       ; Add register d5 to pointer a5
	rts                                                  ; Return from subroutine
Console_DrawCursor:
	moveq    #$3e,d0                                     ; Initialize register d0 to constant $3e
Console_DrawChar:
	movem.l  d0-d1/d5/a2/a5,-(a7)                        ; Move multiple registers d0-d1/d5/a2/a5 to -(a7)
	bsr.b    Console_GetBufferPtr                        ; Call subroutine to Console_GetBufferPtr
	moveq    #BLTCMOD,d1                                 ; Initialize register d1 to constant BLTCMOD
	and.b    d0,d1                                       ; Logical AND register d1 with register d0
	bne.b    Console_DrawChar_Loc_15A2                   ; Branch to Console_DrawChar_Loc_15A2 if non-zero / not equal
	moveq    #$20,d0                                     ; Initialize register d0 to constant $20
Console_DrawChar_Loc_15A2:
	moveq    #$20,d1                                     ; Initialize register d1 to constant $20
	move.b   d0,(a5)                                     ; Move register d0 to (a5)
	bpl.b    Console_DrawChar_Loc_15AA                   ; Branch to Console_DrawChar_Loc_15AA if positive / plus
	sub.b    d1,d0                                       ; Subtract register d1 from register d0
Console_DrawChar_Loc_15AA:
	sub.b    d1,d0                                       ; Subtract register d1 from register d0
	andi.w   #$ff,d0                                     ; Logical AND register d0 with constant $ff
	bsr.b    Console_GetScreenBitplanePtr                ; Call subroutine to Console_GetScreenBitplanePtr
	lea.l    Var_CharTranslationTable(a6),a2             ; Load address of Var_CharTranslationTable(a6) into pointer a2
	lsl.w    #$3,d0
	adda.w   d0,a2                                       ; Add register d0 to pointer a2
	moveq    #BLTBPTH,d5                                 ; Initialize register d5 to constant BLTBPTH
	move.b   (a2)+,(a5)                                  ; Move (a2)+ to (a5)
	adda.w   d5,a5                                       ; Add register d5 to pointer a5
	move.b   (a2)+,(a5)                                  ; Move (a2)+ to (a5)
	adda.w   d5,a5                                       ; Add register d5 to pointer a5
	move.b   (a2)+,(a5)                                  ; Move (a2)+ to (a5)
	adda.w   d5,a5                                       ; Add register d5 to pointer a5
	move.b   (a2)+,(a5)                                  ; Move (a2)+ to (a5)
	adda.w   d5,a5                                       ; Add register d5 to pointer a5
	move.b   (a2)+,(a5)                                  ; Move (a2)+ to (a5)
	adda.w   d5,a5                                       ; Add register d5 to pointer a5
	move.b   (a2)+,(a5)                                  ; Move (a2)+ to (a5)
	adda.w   d5,a5                                       ; Add register d5 to pointer a5
	move.b   (a2)+,(a5)                                  ; Move (a2)+ to (a5)
	adda.w   d5,a5                                       ; Add register d5 to pointer a5
	move.b   (a2),(a5)                                   ; Move (a2) to (a5)
	bsr.w    Console_CursorNextChar                      ; Call subroutine to Console_CursorNextChar
	movem.l  (a7)+,d0-d1/d5/a2/a5                        ; Move multiple registers (a7)+ to d0-d1/d5/a2/a5
	bra.w    CacheFlush_040                              ; Unconditional branch to CacheFlush_040
Console_GetScreenBitplanePtr:
	movea.l  Var_Bitplane1(a6),a5                        ; Load first bitplane memory pointer into pointer a5
	moveq    #$0,d5                                      ; Initialize register d5 to 0
	move.b   Var_CursorX(a6),d5                          ; Load cursor horizontal column coordinate into register d5
	adda.l   d5,a5                                       ; Add register d5 to pointer a5
	move.b   Var_CursorY(a6),d5                          ; Load cursor vertical row coordinate into register d5
	ror.w    #$7,d5
	adda.w   d5,a5                                       ; Add register d5 to pointer a5
	ror.w    #$2,d5
	adda.w   d5,a5                                       ; Add register d5 to pointer a5
	rts                                                  ; Return from subroutine
Console_ScrollTextUp:
	movem.l  d0/a1-a3,-(a7)                              ; Move multiple registers d0/a1-a3 to -(a7)
	lea.l    Blitter_ScrollUpParams(pc),a3                            ; Load address of Blitter_ScrollUpParams(pc) into pointer a3
	tst.b    Var_VblankFlag(a6)                    ; Check if Var_VblankFlag is set / active
	bne.b    Console_ScrollTextUp_Start                  ; Branch to Console_ScrollTextUp_Start if non-zero / not equal
	addq.w   #$6,a3                                      ; Add constant $6 to pointer a3
Console_ScrollTextUp_Start:
	lea.l    CUSTOM.l,a2                                 ; Load address of Amiga custom chip register base address ($dff000) into pointer a2
	bsr.w    WaitForBlitter                              ; Call subroutine to WaitForBlitter
Console_ScrollTextUp_WaitBlit:
	btst     #$0,$5(a2)                                  ; Test bit #$0 of $5(a2)
	bne.b    Console_ScrollTextUp_WaitBlit               ; Branch to Console_ScrollTextUp_WaitBlit if non-zero / not equal
	move.l   #$9f00000,BLTCON0(a2)                       ; Move constant $9f00000 to BLTCON0(a2)
	moveq    #-1,d0                                      ; Initialize register d0 to constant -1
	move.l   d0,BLTAFWM(a2)                              ; Move register d0 to BLTAFWM(a2)
	moveq    #$0,d0                                      ; Initialize register d0 to 0
	move.l   d0,BLTAMOD(a2)                              ; Move register d0 to BLTAMOD(a2)
	movea.l  Var_Bitplane1(a6),a1                        ; Load first bitplane memory pointer into pointer a1
	move.l   a1,BLTDPTH(a2)                              ; Move pointer a1 to BLTDPTH(a2)
	lea.l    $280(a1),a1                                 ; Load address of $280(a1) into pointer a1
	move.l   a1,BLTBPTH(a2)                              ; Move pointer a1 to BLTBPTH(a2)
	move.w   (a3)+,BLTSIZE(a2)                           ; Move (a3)+ to BLTSIZE(a2)
	lea.l    Var_ConsoleBuffer(a6),a1                    ; Load address of console character buffer into pointer a1
	move.w   (a3)+,d0                                    ; Move (a3)+ to register d0
Console_ScrollTextUp_ClearBufferLoop:
	move.l   BLTBPTH(a1),(a1)+                           ; Move BLTBPTH(a1) to (a1)+
	dbra     d0,Console_ScrollTextUp_ClearBufferLoop     ; Decrement loop counter d0 and loop back to Console_ScrollTextUp_ClearBufferLoop if not exhausted
	moveq    #$4f,d0                                     ; Initialize register d0 to constant $4f
Console_ScrollTextUp_SpaceFillLoop:
	move.b   #$20,(a1)+                                  ; Move constant $20 to (a1)+
	dbra     d0,Console_ScrollTextUp_SpaceFillLoop       ; Decrement loop counter d0 and loop back to Console_ScrollTextUp_SpaceFillLoop if not exhausted
	bsr.w    WaitForBlitter                              ; Call subroutine to WaitForBlitter
	moveq    #$0,d0                                      ; Initialize register d0 to 0
	move.w   d0,BLTADAT(a2)                              ; Move register d0 to BLTADAT(a2)
	move.l   #$1f00000,BLTCON0(a2)                       ; Move constant $1f00000 to BLTCON0(a2)
	movea.l  Var_Bitplane1(a6),a1                        ; Load first bitplane memory pointer into pointer a1
	adda.w   (a3)+,a1                                    ; Add (a3)+ to pointer a1
	move.l   a1,BLTDPTH(a2)                              ; Move pointer a1 to BLTDPTH(a2)
	move.w   #$228,BLTSIZE(a2)                           ; Move constant $228 to BLTSIZE(a2)
	bsr.w    WaitForBlitter                              ; Call subroutine to WaitForBlitter
	movem.l  (a7)+,d0/a1-a3                              ; Move multiple registers (a7)+ to d0/a1-a3
	rts                                                  ; Return from subroutine
WaitForBlitter:
	move.w   #$8400,DMACON(a2)                           ; Set DMA control (DMACON) bits to constant $8400
WaitForBlitter_Loc_1694:
	btst     #$e,DMACONR(a2)                             ; Test bit #$e of DMACON (DMA control write register)
	bne.b    WaitForBlitter_Loc_1694                     ; Branch to WaitForBlitter_Loc_1694 if non-zero / not equal
	move.w   #$400,DMACON(a2)                            ; Set DMA control (DMACON) bits to constant $400
	rts                                                  ; Return from subroutine
; ============================================================================
; Data Block: Blitter_ScrollUpParams
; Purpose   : Blitter control register setup parameters for console scroll up.
; ============================================================================
Blitter_ScrollUpParams:
	dc.b     $3E,$28,$02,$6B,$4D,$80,$30,$28,$01,$DF,$3C,$00; Table data bytes
; ============================================================================
; Data Block: Blitter_ScrollDownParams
; Purpose   : Blitter control register setup parameters for console scroll down.
; ============================================================================
Blitter_ScrollDownParams:
	dc.b     "M~>("                                ; String literal data
	dc.b     $09,$B0,$02,$6B,$3B,$FE,$30,$28,$07,$80,$01,$DF; Table data bytes
Console_ScrollTextDown:
	movem.l  d0/a1-a3,-(a7)                              ; Move multiple registers d0/a1-a3 to -(a7)
	lea.l    Blitter_ScrollDownParams(pc),a3                            ; Load address of Blitter_ScrollDownParams(pc) into pointer a3
	tst.b    Var_VblankFlag(a6)                    ; Check if Var_VblankFlag is set / active
	bne.b    Console_ScrollTextDown_Start                ; Branch to Console_ScrollTextDown_Start if non-zero / not equal
	addq.w   #$8,a3                                      ; Add constant $8 to pointer a3
Console_ScrollTextDown_Start:
	lea.l    CUSTOM.l,a2                                 ; Load address of Amiga custom chip register base address ($dff000) into pointer a2
	bsr.b    WaitForBlitter                              ; Call subroutine to WaitForBlitter
Console_ScrollTextDown_WaitBlit:
	btst     #$0,$5(a2)                                  ; Test bit #$0 of $5(a2)
	bne.b    Console_ScrollTextDown_WaitBlit             ; Branch to Console_ScrollTextDown_WaitBlit if non-zero / not equal
	move.l   #$9f00002,BLTCON0(a2)                       ; Move constant $9f00002 to BLTCON0(a2)
	moveq    #-1,d0                                      ; Initialize register d0 to constant -1
	move.l   d0,BLTAFWM(a2)                              ; Move register d0 to BLTAFWM(a2)
	moveq    #$0,d0                                      ; Initialize register d0 to 0
	move.l   d0,BLTAMOD(a2)                              ; Move register d0 to BLTAMOD(a2)
	movea.l  Var_Bitplane1(a6),a1                        ; Load first bitplane memory pointer into pointer a1
	adda.w   (a3)+,a1                                    ; Add (a3)+ to pointer a1
	move.l   a1,BLTBPTH(a2)                              ; Move pointer a1 to BLTBPTH(a2)
	lea.l    $280(a1),a1                                 ; Load address of $280(a1) into pointer a1
	move.l   a1,BLTDPTH(a2)                              ; Move pointer a1 to BLTDPTH(a2)
	move.w   (a3)+,BLTSIZE(a2)                           ; Move (a3)+ to BLTSIZE(a2)
	lea.l    Var_ConsoleBuffer(a6),a1                    ; Load address of console character buffer into pointer a1
	adda.w   (a3)+,a1                                    ; Add (a3)+ to pointer a1
	move.w   (a3)+,d0                                    ; Move (a3)+ to register d0
Console_ScrollTextDown_WaitBlit_Loc_1712:
	move.l   -(a1),BLTBPTH(a1)                           ; Move -(a1) to BLTBPTH(a1)
	dbra     d0,Console_ScrollTextDown_WaitBlit_Loc_1712 ; Decrement loop counter d0 and loop back to Console_ScrollTextDown_WaitBlit_Loc_1712 if not exhausted
	moveq    #$4f,d0                                     ; Initialize register d0 to constant $4f
Console_ScrollTextDown_WaitBlit_Loc_171C:
	move.b   #$20,(a1)+                                  ; Move constant $20 to (a1)+
	dbra     d0,Console_ScrollTextDown_WaitBlit_Loc_171C ; Decrement loop counter d0 and loop back to Console_ScrollTextDown_WaitBlit_Loc_171C if not exhausted
	bsr.w    WaitForBlitter                              ; Call subroutine to WaitForBlitter
	moveq    #$0,d0                                      ; Initialize register d0 to 0
	move.w   d0,BLTADAT(a2)                              ; Move register d0 to BLTADAT(a2)
	move.l   #$1f00000,BLTCON0(a2)                       ; Move constant $1f00000 to BLTCON0(a2)
	movea.l  Var_Bitplane1(a6),a1                        ; Load first bitplane memory pointer into pointer a1
	move.l   a1,BLTDPTH(a2)                              ; Move pointer a1 to BLTDPTH(a2)
	move.w   #$228,BLTSIZE(a2)                           ; Move constant $228 to BLTSIZE(a2)
	bsr.w    WaitForBlitter                              ; Call subroutine to WaitForBlitter
	movem.l  (a7)+,d0/a1-a3                              ; Move multiple registers (a7)+ to d0/a1-a3
	rts                                                  ; Return from subroutine
Level4InterruptHandler:	movem.l  d0-d1/a0-a1,-(a7)                     ; Copy d0-d1/a0-a1 to -(a7)
	lea.l    Val_MonitorBaseOffset(pc),a6                ; Load address of Val_MonitorBaseOffset(pc) into monitor context base (a6)
	lea.l    $7ffe(a6),a6                                ; Offset base pointer to middle of 64KB variables space (for signed 16-bit access)
	lea.l    CUSTOM.l,a0                                 ; Load address of Amiga custom chip register base address ($dff000) into pointer a0
	moveq    #$7f,d0                                     ; Initialize register d0 to constant $7f
Level4InterruptHandler_Loc_1762:	tst.b    ExecBase.w                            ; Check if ExecBase.w is set / active
	dbra     d0,Level4InterruptHandler_Loc_1762          ; Decrement loop counter d0 and loop back to Level4InterruptHandler_Loc_1762 if not exhausted
	move.l   Var_MemEnd(a6),d1                           ; Load monitored memory end offset into register d1
	move.l   Var_MemStart(a6),d0                         ; Load monitored memory start offset into register d0
	sub.l    d0,d1                                       ; Subtract register d0 from register d1
	bls.b    Level4InterruptHandler_Loc_17BE                              ; Branch to Level4InterruptHandler_Loc_17BE if lower or same.
	moveq    #$10,d0                                     ; Initialize register d0 to constant $10
	cmp.l    d0,d1                                       ; Compare register d1 against register d0
	bls.b    Level4InterruptHandler_Loc_177E                              ; Branch to Level4InterruptHandler_Loc_177E if lower or same.
	move.l   d0,d1                                       ; Move register d0 to register d1
Level4InterruptHandler_Loc_177E:	move.l   Var_MemStart(a6),$a0(a0)              ; Copy Var_MemStart to $a0(a0)
	move.l   Var_MemStart(a6),$b0(a0)                    ; Load monitored memory start offset into $b0(a0)
	add.l    d1,Var_MemStart(a6)                         ; Add register d1 to monitored memory start offset
	lsr.l    #$1,d1
	move.w   d1,$a4(a0)                                  ; Move register d1 to $a4(a0)
	move.w   d1,$b4(a0)                                  ; Move register d1 to $b4(a0)
	move.w   $182a(a6),d0                                ; Move $182a(a6) to register d0
	moveq    #$7c,d1                                     ; Initialize register d1 to constant $7c
	cmp.w    d1,d0                                       ; Compare register d0 against register d1
	bcc.b    Level4InterruptHandler_Loc_17A4             ; Branch to Level4InterruptHandler_Loc_17A4 if carry clear (greater or equal)
	move.w   d1,d0                                       ; Move register d1 to register d0
Level4InterruptHandler_Loc_17A4:	move.w   d0,$a6(a0)                            ; Copy d0 to $a6(a0)
	move.w   d0,$b6(a0)                                  ; Move register d0 to $b6(a0)
	moveq    #$40,d0                                     ; Initialize register d0 to constant $40
	move.w   d0,$a8(a0)                                  ; Move register d0 to $a8(a0)
	move.w   d0,$b8(a0)                                  ; Move register d0 to $b8(a0)
	move.w   #$8003,DMACON(a0)                           ; Set DMA control (DMACON) bits to constant $8003
	bra.b    Level4InterruptHandler_Loc_17C8             ; Unconditional branch to Level4InterruptHandler_Loc_17C8
Level4InterruptHandler_Loc_17BE:	clr.l    Var_MemEnd(a6)                        ; Clear Var_MemEnd
	move.w   #$80,INTENA(a0)                             ; Set INTENA interrupt enable bits to constant $80
Level4InterruptHandler_Loc_17C8:	move.w   #$80,INTREQ(a0)                       ; Set INTREQ(a0) to 0x80
	movem.l  (a7)+,d0-d1/a0-a1                           ; Move multiple registers (a7)+ to d0-d1/a0-a1
	rte                                                  ; Return from Exception (RTE) handler
Level3InterruptHandler:	movem.l  d0-d7/a0-a6,-(a7)                     ; Copy d0-d7/a0-a6 to -(a7)
	lea.l    Val_MonitorBaseOffset(pc),a6                ; Load address of Val_MonitorBaseOffset(pc) into monitor context base (a6)
	lea.l    $7ffe(a6),a6                                ; Offset base pointer to middle of 64KB variables space (for signed 16-bit access)
	lea.l    CUSTOM.l,a5                                 ; Load address of Amiga custom chip register base address ($dff000) into pointer a5
	tst.b    Var_EntryFlag(a6)                     ; Check if entering via cold start or warm start/re-entry
	beq.b    Level3InterruptHandler_Loc_183E             ; Branch to Level3InterruptHandler_Loc_183E if zero / equal
	move.l   Var_Bitplane1(a6),BPL1PTH(a5)               ; Load first bitplane memory pointer into BPL1PTH(a5)
	move.w   #$2c81,$8e(a5)                              ; Move constant $2c81 to $8e(a5)
	move.w   Var_ScreenConfig(a6),$90(a5)                ; Load Var_ScreenConfig(a6) into $90(a5)
	movea.l  Var_ScreenBuf(a6),a0                        ; Load screen character buffer pointer into pointer a0
	move.w   $12(a0),$92(a5)                             ; Move $12(a0) to $92(a5)
	move.w   POTGOR(a0),CLXCON(a5)                       ; Move POTGOR (potentiometer port control register) to CLXCON(a5)
	move.w   $1a(a0),BPLCON0(a5)                         ; Move $1a(a0) to BPLCON0 (bitplane control register 0)
	moveq    #$0,d0                                      ; Initialize register d0 to 0
	move.w   d0,BPLCON1(a5)                              ; Move register d0 to BPLCON1 (bitplane control register 1)
	move.w   d0,$108(a5)                                 ; Move register d0 to $108(a5)
	move.w   d0,FMODE(a5)                                ; Move register d0 to FMODE (AGA fetch mode control register)
	move.w   Var_ScreenWidth(a6),COLOR00(a5)             ; Load screen horizontal character resolution into COLOR00 (screen background color register)
	move.w   Var_ScreenHeight(a6),$182(a5)               ; Load console screen height (rows) into $182(a5)
	move.w   #$ff0,$1a2(a5)                              ; Move constant $ff0 to $1a2(a5)
	move.w   d0,$1a4(a5)                                 ; Move register d0 to $1a4(a5)
	move.w   #$f0,$1a6(a5)                               ; Move constant $f0 to $1a6(a5)
Level3InterruptHandler_Loc_183E:	lea.l    CIAA_PRA.l,a4                         ; Load address of CIAA_PRA.l into a4
	movea.l  Var_CopperList(a6),a0                       ; Load Var_CopperList(a6) into pointer a0
	lea.l    $120(a5),a1                                 ; Load address of $120(a5) into pointer a1
	move.l   a0,(a1)+                                    ; Move pointer a0 to (a1)+
	lea.l    $48(a0),a0                                  ; Load address of $48(a0) into pointer a0
	moveq    #$6,d0                                      ; Initialize register d0 to constant $6
Level3InterruptHandler_Loc_1854:	move.l   a0,(a1)+
	dbra     d0,Level3InterruptHandler_Loc_1854          ; Decrement loop counter d0 and loop back to Level3InterruptHandler_Loc_1854 if not exhausted
	move.b   $a(a5),d0                                   ; Move $a(a5) to register d0
	move.b   $161f(a6),d1                                ; Move $161f(a6) to register d1
	move.b   d0,$161f(a6)                                ; Move register d0 to $161f(a6)
	sub.b    d1,d0                                       ; Subtract register d1 from register d0
	ext.w    d0
	add.w    d0,$1622(a6)                                ; Add register d0 to $1622(a6)
	move.w   d0,d1                                       ; Move register d0 to register d1
	muls.w   d0,d0
	cmpi.w   #$19,d0                                     ; Compare register d0 against constant $19
	bhi.b    Level3InterruptHandler_Loc_1880                              ; Branch to Level3InterruptHandler_Loc_1880 if higher.
	tst.w    d1                                          ; Test status of register d1 (for zero or negative)
	bpl.b    Level3InterruptHandler_Loc_1886             ; Branch to Level3InterruptHandler_Loc_1886 if positive / plus
	neg.w    d0
	bra.b    Level3InterruptHandler_Loc_1886             ; Unconditional branch to Level3InterruptHandler_Loc_1886
Level3InterruptHandler_Loc_1880:	move.w   d1,d0
	muls.w   #$5,d0
Level3InterruptHandler_Loc_1886:	muls.w   #$50,d0
	sub.l    d0,$1624(a6)                                ; Subtract register d0 from $1624(a6)
	move.b   $b(a5),d0                                   ; Move $b(a5) to register d0
	move.b   $161e(a6),d1                                ; Move $161e(a6) to register d1
	move.b   d0,$161e(a6)                                ; Move register d0 to $161e(a6)
	sub.b    d1,d0                                       ; Subtract register d1 from register d0
	ext.w    d0
	ext.l    d0
	move.l   d0,d1                                       ; Move register d0 to register d1
	add.w    d0,$1620(a6)                                ; Add register d0 to $1620(a6)
	sub.l    d1,$1624(a6)                                ; Subtract register d1 from $1624(a6)
	bpl.b    Level3InterruptHandler_Loc_18B0             ; Branch to Level3InterruptHandler_Loc_18B0 if positive / plus
	clr.l    $1624(a6)                                   ; Clear / reset $1624(a6)
Level3InterruptHandler_Loc_18B0:	move.w   $1622(a6),d0                          ; Copy $1622 to d0
	cmpi.w   #$28,d0                                     ; Compare register d0 against constant $28
	bhi.b    Level3InterruptHandler_Loc_18BC                              ; Branch to Level3InterruptHandler_Loc_18BC if higher.
	moveq    #$28,d0                                     ; Initialize register d0 to constant $28
Level3InterruptHandler_Loc_18BC:	moveq    #$5,d1
	add.b    Var_MenuIndex(a6),d1                        ; Add active menu header index to register d1
	lsl.w    #$3,d1
	subq.b   #$1,d1                                      ; Subtract 1 from register d1
	cmp.w    d1,d0                                       ; Compare register d0 against register d1
	bls.b    Level3InterruptHandler_Loc_18CC                              ; Branch to Level3InterruptHandler_Loc_18CC if lower or same.
	move.w   d1,d0                                       ; Move register d1 to register d0
Level3InterruptHandler_Loc_18CC:	move.w   d0,$1622(a6)                          ; Copy d0 to $1622
	move.w   $1620(a6),d1                                ; Move $1620(a6) to register d1
	cmpi.w   #$3c,d1                                     ; Compare register d1 against constant $3c
	bhi.b    Level3InterruptHandler_Loc_18DC                              ; Branch to Level3InterruptHandler_Loc_18DC if higher.
	moveq    #$3c,d1                                     ; Initialize register d1 to constant $3c
Level3InterruptHandler_Loc_18DC:	cmpi.w   #$db,d1
	bls.b    Level3InterruptHandler_Loc_18E6                              ; Branch to Level3InterruptHandler_Loc_18E6 if lower or same.
	move.w   #$db,d1                                     ; Move constant $db to register d1
Level3InterruptHandler_Loc_18E6:	move.w   d1,$1620(a6)                          ; Copy d1 to $1620
	btst     #$0,Var_MonitorLockState(a6)                ; Test bit #$0 of Var_MonitorLockState(a6)
	bne.w    Level3InterruptHandler_Loc_19A8             ; Branch to Level3InterruptHandler_Loc_19A8 if non-zero / not equal
	move.w   #$20,DMACON(a5)                             ; Set DMA control (DMACON) bits to constant $20
	moveq    #$0,d0                                      ; Initialize register d0 to 0
	move.l   d0,$144(a5)                                 ; Move register d0 to $144(a5)
	move.w   $a(a5),d0                                   ; Move $a(a5) to register d0
	cmp.w    $161c(a6),d0                                ; Compare register d0 against $161c(a6)
	beq.b    Level3InterruptHandler_Loc_1914             ; Branch to Level3InterruptHandler_Loc_1914 if zero / equal
	move.w   d0,$161c(a6)                                ; Move register d0 to $161c(a6)
	move.b   #$64,$1686(a6)                              ; Move constant $64 to $1686(a6)
Level3InterruptHandler_Loc_1914:	tst.b    $1686(a6)                             ; Check if $1686 is set / active
	beq.w    Level3InterruptHandler_Loc_19A8             ; Branch to Level3InterruptHandler_Loc_19A8 if zero / equal
	subq.b   #$1,$1686(a6)                               ; Subtract 1 from $1686(a6)
	move.w   #$8020,DMACON(a5)                           ; Set DMA control (DMACON) bits to constant $8020
	moveq    #-$3c,d1                                    ; Initialize register d1 to constant -$3c
	add.w    $1620(a6),d1                                ; Add $1620(a6) to register d1
	lsr.b    #$1,d1
	moveq    #-$28,d2                                    ; Initialize register d2 to constant -$28
	add.w    $1622(a6),d2                                ; Add $1622(a6) to register d2
	lsr.w    #$3,d2
	btst     #$0,Var_MonitorLockState(a6)                ; Test bit #$0 of Var_MonitorLockState(a6)
	bne.b    Level3InterruptHandler_Loc_1992             ; Branch to Level3InterruptHandler_Loc_1992 if non-zero / not equal
	btst     #$a,POTGOR(a5)                              ; Test bit #$a of POTGOR (potentiometer port control register)
	bne.b    Level3InterruptHandler_Loc_194C             ; Branch to Level3InterruptHandler_Loc_194C if non-zero / not equal
	st.b     $1669(a6)                             ; Set $1669(a6) flag (true).
	bra.b    Level3InterruptHandler_Loc_1992             ; Unconditional branch to Level3InterruptHandler_Loc_1992
Level3InterruptHandler_Loc_194C:	tst.b    $1669(a6)                             ; Check if $1669 is set / active
	beq.b    Level3InterruptHandler_Loc_1992             ; Branch to Level3InterruptHandler_Loc_1992 if zero / equal
	bsr.w    LockMonitor                                 ; Call subroutine to LockMonitor
	sf.b     $1669(a6)                             ; Clear $1669(a6) flag (false).
	mulu.w   #$50,d2
Level3InterruptHandler_Loc_195E:	lea.l    Var_ConsoleBuffer(a6),a0              ; Load address of Var_ConsoleBuffer into a0
	adda.w   d1,a0                                       ; Add register d1 to pointer a0
	adda.w   d2,a0                                       ; Add register d2 to pointer a0
	move.b   (a0),d0                                     ; Move (a0) to register d0
	cmpi.b   #$20,d0                                     ; Compare register d0 against constant $20
	beq.b    Level3InterruptHandler_Loc_19A4             ; Branch to Level3InterruptHandler_Loc_19A4 if zero / equal
	cmpi.b   #$3a,d0                                     ; Compare register d0 against constant $3a
	beq.b    Level3InterruptHandler_Loc_1986             ; Branch to Level3InterruptHandler_Loc_1986 if zero / equal
	cmpi.b   #$24,d0                                     ; Compare register d0 against constant $24
	beq.b    Level3InterruptHandler_Loc_1986             ; Branch to Level3InterruptHandler_Loc_1986 if zero / equal
	cmpi.b   #$2d,d0                                     ; Compare register d0 against constant $2d
	bne.b    Level3InterruptHandler_Loc_1982             ; Branch to Level3InterruptHandler_Loc_1982 if non-zero / not equal
	moveq    #$20,d0                                     ; Initialize register d0 to constant $20
Level3InterruptHandler_Loc_1982:	bsr.w    Console_DrawChar
Level3InterruptHandler_Loc_1986:	addq.b   #$1,d1
	cmpi.b   #$4f,d1                                     ; Compare register d1 against constant $4f
	bls.b    Level3InterruptHandler_Loc_195E                              ; Branch to Level3InterruptHandler_Loc_195E if lower or same.
	bsr.w    UnlockMonitor                               ; Call subroutine to UnlockMonitor
Level3InterruptHandler_Loc_1992:	btst     #$6,(a4)
	bne.b    Level3InterruptHandler_Loc_19A8             ; Branch to Level3InterruptHandler_Loc_19A8 if non-zero / not equal
	bsr.w    LockMonitor                                 ; Call subroutine to LockMonitor
	move.b   d1,Var_CursorX(a6)                          ; Store register d1 into cursor horizontal column coordinate
	move.b   d2,Var_CursorY(a6)                          ; Store register d2 into cursor vertical row coordinate
Level3InterruptHandler_Loc_19A4:	bsr.w    UnlockMonitor
Level3InterruptHandler_Loc_19A8:	movea.l  Var_CopperList(a6),a0                 ; Copy Var_CopperList to a0
	move.w   $1622(a6),d0                                ; Move $1622(a6) to register d0
	sf.b     $3(a0)                                ; Clear $3(a0) flag (false).
	btst     #$8,d0                                      ; Test bit #$8 of register d0
	beq.b    Level3InterruptHandler_Loc_19C0             ; Branch to Level3InterruptHandler_Loc_19C0 if zero / equal
	bset     #$2,$3(a0)                                  ; Set bit #$2 of $3(a0)
Level3InterruptHandler_Loc_19C0:	move.b   d0,(a0)
	addi.w   #$11,d0                                     ; Add constant $11 to register d0
	btst     #$8,d0                                      ; Test bit #$8 of register d0
	beq.b    Level3InterruptHandler_Loc_19D2             ; Branch to Level3InterruptHandler_Loc_19D2 if zero / equal
	bset     #$1,$3(a0)                                  ; Set bit #$1 of $3(a0)
Level3InterruptHandler_Loc_19D2:	move.b   d0,DMACONR(a0)                        ; Copy d0 to DMACONR(a0)
	move.b   $1621(a6),$1(a0)                            ; Move $1621(a6) to $1(a0)
	move.b   Var_LockFlag(a6),d0                         ; Load monitor lock status into register d0
	beq.b    Level3InterruptHandler_Loc_1A34             ; Branch to Level3InterruptHandler_Loc_1A34 if zero / equal
	cmpi.b   #$1b,d0                                     ; Compare register d0 against constant $1b
	beq.b    Level3InterruptHandler_Loc_1A34             ; Branch to Level3InterruptHandler_Loc_1A34 if zero / equal
	cmp.b    $1687(a6),d0                                ; Compare register d0 against $1687(a6)
	bne.b    Level3InterruptHandler_Loc_1A30             ; Branch to Level3InterruptHandler_Loc_1A30 if non-zero / not equal
	cmpi.b   #$14,$1683(a6)                              ; Compare $1683(a6) against constant $14
	beq.b    Level3InterruptHandler_Loc_19FC             ; Branch to Level3InterruptHandler_Loc_19FC if zero / equal
	addq.b   #$1,$1683(a6)                               ; Add 1 to $1683(a6)
	bra.b    VblankInterruptHandler                      ; Unconditional branch to VblankInterruptHandler
Level3InterruptHandler_Loc_19FC:	cmpi.b   #$1,d0
	beq.b    Level3InterruptHandler_Loc_1A28             ; Branch to Level3InterruptHandler_Loc_1A28 if zero / equal
	cmpi.b   #$2,d0                                      ; Compare register d0 against constant $2
	beq.b    Level3InterruptHandler_Loc_1A28             ; Branch to Level3InterruptHandler_Loc_1A28 if zero / equal
	cmpi.b   #$10,d0                                     ; Compare register d0 against constant $10
	beq.b    Level3InterruptHandler_Loc_1A28             ; Branch to Level3InterruptHandler_Loc_1A28 if zero / equal
	cmpi.b   #$11,d0                                     ; Compare register d0 against constant $11
	beq.b    Level3InterruptHandler_Loc_1A28             ; Branch to Level3InterruptHandler_Loc_1A28 if zero / equal
	cmpi.b   #$d,d0                                      ; Compare register d0 against constant $d
	beq.b    Level3InterruptHandler_Loc_1A28             ; Branch to Level3InterruptHandler_Loc_1A28 if zero / equal
	addq.b   #$1,$1682(a6)                               ; Add 1 to $1682(a6)
	move.b   $16cd(a6),d1                                ; Move $16cd(a6) to register d1
	cmp.b    $1682(a6),d1                                ; Compare register d1 against $1682(a6)
	bcc.b    VblankInterruptHandler                      ; Branch to VblankInterruptHandler if carry clear (greater or equal)
Level3InterruptHandler_Loc_1A28:	sf.b     $1682(a6)                             ; Clear $1682(a6) flag (false).
	bsr.b    Console_PushInputBuffer                     ; Call subroutine to Console_PushInputBuffer
	bra.b    VblankInterruptHandler                      ; Unconditional branch to VblankInterruptHandler
Level3InterruptHandler_Loc_1A30:	move.b   d0,$1687(a6)                          ; Copy d0 to $1687
Level3InterruptHandler_Loc_1A34:	sf.b     $1683(a6)                             ; Clear $1683(a6) flag (false).
VblankInterruptHandler:	bsr.b    Console_UpdateCursorBlinkTimer
	tst.w    $1628(a6)                             ; Check if $1628 is set / active
	beq.b    VblankInterruptHandler_Ack                  ; Branch to VblankInterruptHandler_Ack if zero / equal
	subq.w   #$1,$1628(a6)                               ; Subtract 1 from $1628(a6)
VblankInterruptHandler_Ack:	move.w   #$70,INTREQ(a5)                       ; Set INTREQ to 0x70
	movem.l  (a7)+,d0-d7/a0-a6                           ; Move multiple registers (a7)+ to d0-d7/a0-a6
	rte                                                  ; Return from Exception (RTE) handler
Console_UpdateCursorBlinkTimer:	btst     #$0,Var_MonitorLockState(a6)          ; Test bit $0 in Var_MonitorLockState
	bne.b    Console_UpdateCursorBlinkTimer_Exit         ; Branch to Console_UpdateCursorBlinkTimer_Exit if non-zero / not equal
	subq.b   #$1,$1684(a6)                               ; Subtract 1 from $1684(a6)
	bne.b    Console_UpdateCursorBlinkTimer_Exit         ; Branch to Console_UpdateCursorBlinkTimer_Exit if non-zero / not equal
	move.b   #$a,$1684(a6)                               ; Move constant $a to $1684(a6)
Console_ToggleCursorBlink:
	movem.l  d5/a5,-(a7)                                 ; Move multiple registers d5/a5 to -(a7)
	bsr.w    Console_GetScreenBitplanePtr                ; Call subroutine to Console_GetScreenBitplanePtr
	moveq    #$7,d5                                      ; Initialize register d5 to constant $7
Console_ToggleCursorBlink_Loop:
	not.b    (a5)
	lea.l    BLTBPTH(a5),a5                              ; Load address of BLTBPTH(a5) into pointer a5
	dbra     d5,Console_ToggleCursorBlink_Loop           ; Decrement loop counter d5 and loop back to Console_ToggleCursorBlink_Loop if not exhausted
	bchg     #$1,Var_MonitorLockState(a6)          ; Toggle bit $1 in Var_MonitorLockState
	movem.l  (a7)+,d5/a5                                 ; Move multiple registers (a7)+ to d5/a5
Console_UpdateCursorBlinkTimer_Exit:
	rts                                                  ; Return from subroutine
Console_PushInputBuffer:
	movem.l  d0-d1/a0,-(a7)                              ; Move multiple registers d0-d1/a0 to -(a7)
	tst.b    Var_TaskFlag(a6)                      ; Check if Var_TaskFlag is set / active
	bne.b    Console_PushInputBuffer_Exit                ; Branch to Console_PushInputBuffer_Exit if non-zero / not equal
	lea.l    Var_InputBuffer(a6),a0                      ; Load address of keyboard input buffer into pointer a0
	move.w   Var_BufferLength(a6),d1                     ; Load keyboard input buffer character count into register d1
	beq.b    Console_PushInputBuffer_Store               ; Branch to Console_PushInputBuffer_Store if zero / equal
	cmpi.w   #$28,d1                                     ; Compare register d1 against constant $28
	bge.b    Console_PushInputBuffer_Exit                ; Branch to Console_PushInputBuffer_Exit if greater or equal
	cmpi.b   #$1,d0                                      ; Compare register d0 against 1
	beq.b    Console_PushInputBuffer_CheckRepeat         ; Branch to Console_PushInputBuffer_CheckRepeat if zero / equal
	cmpi.b   #$2,d0                                      ; Compare register d0 against constant $2
	beq.b    Console_PushInputBuffer_CheckRepeat         ; Branch to Console_PushInputBuffer_CheckRepeat if zero / equal
	cmpi.b   #$d,d0                                      ; Compare register d0 against constant $d
	bne.b    Console_PushInputBuffer_Store               ; Branch to Console_PushInputBuffer_Store if non-zero / not equal
Console_PushInputBuffer_CheckRepeat:
	cmp.b    -$1(a0,d1.w),d0                             ; Compare register d0 against -$1(a0,d1.w)
	beq.b    Console_PushInputBuffer_Exit                ; Branch to Console_PushInputBuffer_Exit if zero / equal
Console_PushInputBuffer_Store:
	move.b   d0,(a0,d1.w)                                ; Move register d0 to (a0,d1.w)
	addq.w   #$1,Var_BufferLength(a6)                    ; Add 1 to keyboard input buffer character count
Console_PushInputBuffer_Exit:
	movem.l  (a7)+,d0-d1/a0                              ; Move multiple registers (a7)+ to d0-d1/a0
	rts                                                  ; Return from subroutine
Level2InterruptHandler:	movem.l  d0-d1/a0/a4/a6,-(a7)                  ; Copy d0-d1/a0/a4/a6 to -(a7)
	lea.l    VHPOSR+CUSTOM.l,a4                          ; Load address of Amiga custom chip register base address ($dff000) into pointer a4
	move.w   #$8,CLXCON(a4)                              ; Move constant $8 to CLXCON(a4)
	lea.l    Val_MonitorBaseOffset(pc),a6                ; Load address of Val_MonitorBaseOffset(pc) into monitor context base (a6)
	lea.l    $7ffe(a6),a6                                ; Offset base pointer to middle of 64KB variables space (for signed 16-bit access)
	btst     #$3,$bfed01.l                               ; Test bit #$3 of $bfed01.l
	beq.w    Level2InterruptHandler_Exit                 ; Branch to Level2InterruptHandler_Exit if zero / equal
	moveq    #$0,d0                                      ; Initialize register d0 to 0
	move.b   $bfec01.l,d0                                ; Move $bfec01.l to register d0
	bset     #$6,$bfee01.l                               ; Set bit #$6 of $bfee01.l
	st.b     $bfec01.l                             ; Set $bfec01.l flag (true).
	not.b    d0
	lsr.w    #$1,d0
	bcs.b    Level2InterruptHandler_KeyReleased          ; Branch to Level2InterruptHandler_KeyReleased if carry set (less than)
	cmpi.b   #$60,d0                                     ; Compare register d0 against constant $60
	blt.b    Level2InterruptHandler_NormalKey            ; Branch to Level2InterruptHandler_NormalKey if less than
	cmpi.b   #$67,d0                                     ; Compare register d0 against constant $67
	bhi.b    Level2InterruptHandler_WaitHandshake                              ; Branch to Level2InterruptHandler_WaitHandshake if higher.
	bset     d0,$168a(a6)                                ; Set bit d0 of $168a(a6)
	bra.b    Level2InterruptHandler_WaitHandshake        ; Unconditional branch to Level2InterruptHandler_WaitHandshake
Level2InterruptHandler_NormalKey:	moveq    #$7,d1
	and.b    $168a(a6),d1                                ; Logical AND register d1 with $168a(a6)
	beq.b    Level2InterruptHandler_Translate            ; Branch to Level2InterruptHandler_Translate if zero / equal
	addi.w   #$60,d0                                     ; Add constant $60 to register d0
Level2InterruptHandler_Translate:	lea.l    $127e(a6),a0                          ; Load address of $127e into a0
	move.b   (a0,d0.w),d0                                ; Move (a0,d0.w) to register d0
	beq.b    Level2InterruptHandler_WaitHandshake        ; Branch to Level2InterruptHandler_WaitHandshake if zero / equal
	move.b   d0,Var_LockFlag(a6)                         ; Store register d0 into monitor lock status
	cmpi.b   #$1b,d0                                     ; Compare register d0 against constant $1b
	beq.b    Level2InterruptHandler_WaitHandshake        ; Branch to Level2InterruptHandler_WaitHandshake if zero / equal
	bsr.w    Console_PushInputBuffer                     ; Call subroutine to Console_PushInputBuffer
	bra.b    Level2InterruptHandler_WaitHandshake        ; Unconditional branch to Level2InterruptHandler_WaitHandshake
Level2InterruptHandler_KeyReleased:	cmpi.b   #$60,d0
	blt.b    Level2InterruptHandler_ClearLock            ; Branch to Level2InterruptHandler_ClearLock if less than
	cmpi.b   #$67,d0                                     ; Compare register d0 against constant $67
	bhi.b    Level2InterruptHandler_WaitHandshake                              ; Branch to Level2InterruptHandler_WaitHandshake if higher.
	bclr     d0,$168a(a6)                                ; Clear bit d0 of $168a(a6)
	bra.b    Level2InterruptHandler_WaitHandshake        ; Unconditional branch to Level2InterruptHandler_WaitHandshake
Level2InterruptHandler_ClearLock:	sf.b     Var_LockFlag(a6)                      ; Clear monitor lock state flag flag (false).
Level2InterruptHandler_WaitHandshake:	moveq    #$3,d0
Level2InterruptHandler_Loop:	move.b   (a4),d1
Level2InterruptHandler_SubLoop:	cmp.b    (a4),d1
	beq.b    Level2InterruptHandler_SubLoop              ; Branch to Level2InterruptHandler_SubLoop if zero / equal
	dbra     d0,Level2InterruptHandler_Loop              ; Decrement loop counter d0 and loop back to Level2InterruptHandler_Loop if not exhausted
	bclr     #$6,$bfee01.l                               ; Clear bit #$6 of $bfee01.l
Level2InterruptHandler_Exit:	move.w   #$8,DMACON(a4)                        ; Set DMACON(a4) to 0x8
	move.w   #$8008,CLXCON(a4)                           ; Move constant $8008 to CLXCON(a4)
	movem.l  (a7)+,d0-d1/a0/a4/a6                        ; Move multiple registers (a7)+ to d0-d1/a0/a4/a6
	rte                                                  ; Return from Exception (RTE) handler
	dc.b     $24,"VER:BeerMon 0.45",0
; ============================================================================
; Data Block: Command_NamesTable
; Purpose   : High-bit terminated packed strings table of monitor command names.
; ============================================================================
Command_NamesTable:
	dc.b     $D3,$CC,$76,$65,$72,$69,$66,$F9,$76,$E3,$F6,$73,$6D,$64,$32,$72; Table data bytes
	dc.b     $61,$F7,$66,$61,$6D,$69,$70,$6C,$61,$F9,$72,$61,$77,$70,$6C,$61; Table data bytes
	dc.b     $F9,$73,$6D,$64,$70,$6C,$61,$F9,$73,$65,$74,$74,$74,$B0,$73,$65; Table data bytes
	dc.b     "ttt",$B1                             ; String literal data
	dc.b     "sett",$E3                            ; String literal data
	dc.b     "setsr",$F0                           ; String literal data
	dc.b     "setcr",$F0                           ; String literal data
	dc.b     "setdr",$F0                           ; String literal data
	dc.b     "setmmus",$F2                         ; String literal data
	dc.b     $F3,$EC,$C4,$61,$63,$63,$F5,$69,$6E,$64,$65,$F8,$61,$75,$74,$EF; Table data bytes
	dc.b     "instal",$EC                          ; String literal data
	dc.b     "inf",$EF                             ; String literal data
	dc.b     $69,$6D,$F0,$E9,$F0,$67,$61,$72,$F9,$E7,$E8,$BF,$72,$61,$6D,$73; Table data bytes
	dc.b     $65,$F9,$F2,$D2,$6D,$61,$74,$63,$E8,$6D,$6D,$75,$6F,$EE,$6D,$6D; Table data bytes
	dc.b     "uof",$E6                             ; String literal data
	dc.b     $6D,$6D,$F5,$6D,$EB,$6D,$65,$67,$61,$73,$75,$ED,$66,$61,$6D,$69; Table data bytes
	dc.b     $73,$75,$ED,$ED,$BA,$E1,$BB,$F8,$D8,$6F,$F7,$6F,$EC,$EF,$65,$78; Table data bytes
	dc.b     $F0,$65,$F7,$65,$EC,$E5,$63,$E4,$63,$6C,$F3,$63,$6F,$F0,$63,$6F; Table data bytes
	dc.b     "nfi",$E7                             ; String literal data
	dc.b     "custo",$ED                           ; String literal data
	dc.b     $E3,$66,$6F,$72,$6D,$61,$F4,$66,$E9,$66,$6D,$6F,$64,$E5,$E6,$C6; Table data bytes
	dc.b     "tim",$E5                             ; String literal data
	dc.b     "typ",$E5                             ; String literal data
	dc.b     $F4,$AF,$D6,$AE,$D7,$64,$61,$74,$61,$73,$75,$ED,$64,$65,$EC,$64; Table data bytes
	dc.b     $69,$F2,$64,$F3,$64,$ED,$64,$F6,$E4,$F5,$DF,$CE,$6E,$6F,$F0,$AC; Table data bytes
	dc.b     $EE,$CB,$C2,$62,$6F,$6F,$74,$73,$75,$ED,$62,$69,$74,$73,$75,$ED; Table data bytes
	dc.b     "bin",$F7                             ; String literal data
	dc.b     $DD,$62,$69,$6E,$EC,$DB,$62,$69,$6E,$F4,$FD,$62,$69,$6E,$F1,$FB; Table data bytes
	dc.b     $62,$69,$EE,$FC,$62,$E3,$62,$F3,$62,$EC,$E2,$CD,$D0,$6B,$69,$63; Table data bytes
	dc.b     "ksu",$ED                             ; String literal data
	dc.b     $EB,$A0                               ; Table data bytes
; ============================================================================
; Data Block: Command_OffsetsTable
; Purpose   : Table of word offsets for monitor command handlers.
; ============================================================================
Command_OffsetsTable:
	dc.b     $00,$00                               ; Table data bytes
; ============================================================================
; Data Block: Command_OffsetsTable_Base
; Purpose   : Starting entries for monitor command handler word offsets.
; ============================================================================
Command_OffsetsTable_Base:
	dc.b     $00,$DC,$04,$AC,$35,$5C,$07,$EA,$07,$7C,$23,$28,$24,$04,$23,$C2; Table data bytes
	dc.b     $24,$0A,$31,$AA,$31,$AE,$31,$B2,$31,$BC,$31,$C0,$31,$C4,$31,$B6; Table data bytes
	dc.b     $0B,$06,$0B,$0C,$1C,$08,$40,$66,$40,$6C,$40,$8E,$20,$FA,$16,$4E; Table data bytes
	dc.b     "P$%",$DC                             ; String literal data
	dc.b     "&r4,"                                ; String literal data
	dc.b     $27,$0E,$28,$FC,$2A,$0C,$33,$CA,$2B,$10,$30,$18,$5D,$CE,$33,$6E; Table data bytes
	dc.b     "3t2*"                                ; String literal data
	dc.b     $15,$12,$08,$FE,$09,$72,$38,$52,$38,$DE,$39,$26,$39,$98,$00,$D8; Table data bytes
	dc.b     $39,$C6,$4F,$4C,$4F,$50,$4F,$48,$56,$DE,$4F,$58,$4F,$5C,$4F,$54; Table data bytes
	dc.b     $12,$CC,$36,$00,$4A,$D4,$21,$DC,$4A,$1C,$43,$6C,$1E,$84,$43,$E2; Table data bytes
	dc.b     $45,$0E,$45,$24,$46,$0A,$46,$9A,$04,$A2,$46,$E0,$47,$10,$4B,$78; Table data bytes
	dc.b     $4C,$F0,$3B,$8C,$0A,$36,$13,$3E,$17,$C6,$3E,$2A,$3E,$2E,$3E,$32; Table data bytes
	dc.b     $3D,$8C,$40,$9E,$40,$F4,$40,$DA,$50,$06,$3E,$5C,$3E,$3C,$34,$7E; Table data bytes
	dc.b     $35,$22,$0A,$30,$0A,$3C,$37,$52,$37,$FC,$37,$4E,$37,$F8,$37,$4A; Table data bytes
	dc.b     $37,$F4,$37,$46,$37,$F0,$37,$56,$38,$00,$36,$AA,$36,$22,$36,$06; Table data bytes
	dc.b     $3A,$3E,$16,$52,$35,$4A,$0A,$42,$35,$7A,$36,$E0; Table data bytes
Command_x:
	dc.b     $60,$00,$E8,$74                       ; Table data bytes
Command_S:
	lea.l    DMACONR(a5),a0                              ; Load address of DMACON (DMA control write register) into pointer a0
	bsr.w    Parser_GetNextArg                           ; Call subroutine to Parser_GetNextArg
	move.w   d4,$182c(a6)                                ; Move register d4 to $182c(a6)
	beq.w    Command_S_Loc_20AA                          ; Branch to Command_S_Loc_20AA if zero / equal
	cmpi.w   #$1e,d4                                     ; Compare register d4 against constant $1e
	bhi.w    Command_S_Loc_20AA                              ; Execute bhi.w instruction
	bsr.w    Parser_SkipSpaces                           ; Call subroutine to Parser_SkipSpaces
	bhi.w    Command_S_Loc_20AA                              ; Execute bhi.w instruction
	movea.l  a0,a3                                       ; Move pointer a0 to pointer a3
	bsr.w    ParseHexNumber                              ; Call subroutine to ParseHexNumber
	move.l   d0,Var_MemStart(a6)                         ; Store register d0 into monitored memory start offset
	movea.l  a3,a0                                       ; Move pointer a3 to pointer a0
	bsr.w    Parser_SkipSpaces                           ; Call subroutine to Parser_SkipSpaces
	bhi.w    Command_S_Loc_20AA                              ; Execute bhi.w instruction
	movea.l  a0,a3                                       ; Move pointer a0 to pointer a3
	bsr.w    ParseHexNumber                              ; Call subroutine to ParseHexNumber
	move.l   d0,Var_MemEnd(a6)                           ; Store register d0 into monitored memory end offset
	beq.w    Command_S_Loc_20AA                          ; Branch to Command_S_Loc_20AA if zero / equal
	move.l   Var_MemStart(a6),d1                         ; Load monitored memory start offset into register d1
	cmp.l    d0,d1                                       ; Compare register d1 against register d0
	bhi.w    Command_S_Loc_20AA                              ; Execute bhi.w instruction
	move.l   d1,Var_TempMemPtr(a6)                       ; Store register d1 into temporary memory workspace pointer
	st.b     $1673(a6)                             ; Execute st.b instruction
	st.b     $1672(a6)                             ; Execute st.b instruction
	bsr.w    Disk_PrepareDriveAndReadTrack               ; Call subroutine to Disk_PrepareDriveAndReadTrack
	bne.w    Command_S_Loc_20A4                          ; Branch to Command_S_Loc_20A4 if non-zero / not equal
	movea.l  a2,a0                                       ; Move pointer a2 to pointer a0
	bsr.w    Afs_HashFilename                            ; Call subroutine to Afs_HashFilename
	beq.b    Command_S_Loc_1E1C                          ; Branch to Command_S_Loc_1E1C if zero / equal
	bsr.w    Afs_FindFileInDirectory                     ; Call subroutine to Afs_FindFileInDirectory
	beq.b    Command_S_Loc_1E1C                          ; Branch to Command_S_Loc_1E1C if zero / equal
	bsr.w    Print_FileExistsError                       ; Call subroutine to Print_FileExistsError
	bra.w    Command_S_Loc_20A4                          ; Unconditional branch to Command_S_Loc_20A4
Command_S_Loc_1E1C:
	tst.b    $1671(a6)                             ; Check if $1671 is set / active
	bne.w    Command_S_Loc_20A4                          ; Branch to Command_S_Loc_20A4 if non-zero / not equal
	bsr.w    Disk_CountFreeSectors                       ; Call subroutine to Disk_CountFreeSectors
	beq.w    Command_S_Loc_20AC                          ; Branch to Command_S_Loc_20AC if zero / equal
	movem.l  Var_MemStart(a6),d0-d1                      ; Move multiple registers Var_MemStart(a6) to d0-d1
	sub.l    d0,d1                                       ; Subtract register d0 from register d1
	beq.b    Command_S_Loc_1E46                          ; Branch to Command_S_Loc_1E46 if zero / equal
	bsr.w    Afs_BlockToCylinder                         ; Call subroutine to Afs_BlockToCylinder
	cmp.l    d0,d1                                       ; Compare register d1 against register d0
	bls.b    Command_S_Loc_1E46                              ; Execute bls.b instruction
	bsr.w    Print_NotEnoughFreeSpaceError               ; Call subroutine to Print_NotEnoughFreeSpaceError
	bra.w    Command_S_Loc_20A4                          ; Unconditional branch to Command_S_Loc_20A4
Command_S_Loc_1E46:
	bsr.w    Afs_AllocateBlock                           ; Call subroutine to Afs_AllocateBlock
	beq.w    Command_S_Loc_20AC                          ; Branch to Command_S_Loc_20AC if zero / equal
	movea.l  d0,a3                                       ; Move register d0 to pointer a3
	move.l   d0,$17ce(a6)                                ; Move register d0 to $17ce(a6)
	clr.w    $17e2(a6)                                   ; Clear / reset $17e2(a6)
	lea.l    Var_MonitorBufferOffset(a6),a5              ; Load address of Var_MonitorBufferOffset(a6) into pointer a5
	movea.l  a5,a0                                       ; Move pointer a5 to pointer a0
	moveq    #$7f,d6                                     ; Initialize register d6 to constant $7f
Command_S_Loc_1E60:
	clr.l    (a0)+                                       ; Clear / reset (a0)+
	dbra     d6,Command_S_Loc_1E60                       ; Decrement loop counter d6 and loop back to Command_S_Loc_1E60 if not exhausted
	lea.l    $149(a5),a1                                 ; Load address of $149(a5) into pointer a1
	movea.l  a1,a0                                       ; Move pointer a1 to pointer a0
	move.l   Var_MemStart(a6),d0                         ; Load monitored memory start offset into register d0
	bsr.w    PrintHex8                                   ; Call subroutine to PrintHex8
	move.b   #$2d,(a0)+                                  ; Move constant $2d to (a0)+
	move.l   Var_MemEnd(a6),d0                           ; Load monitored memory end offset into register d0
	bsr.w    PrintHex8                                   ; Call subroutine to PrintHex8
	suba.l   a1,a0                                       ; Subtract pointer a1 from pointer a0
	move.w   a0,d0                                       ; Move pointer a0 to register d0
	move.b   d0,-(a1)                                    ; Move register d0 to -(a1)
	bsr.w    Rtc_InitAndTest                             ; Call subroutine to Rtc_InitAndTest
	move.l   $1814(a6),$1a4(a5)                          ; Move $1814(a6) to $1a4(a5)
	move.l   $1818(a6),$1a8(a5)                          ; Move $1818(a6) to $1a8(a5)
	move.l   $181c(a6),$1ac(a5)                          ; Move $181c(a6) to $1ac(a5)
	lea.l    Var_DisasmBuffer+1(a6),a0                   ; Load address of disassembler output text buffer into pointer a0
	lea.l    -$1d4a(a6),a1                               ; Load address of -$1d4a(a6) into pointer a1
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	move.w   $182c(a6),d0                                ; Move $182c(a6) to register d0
	subq.w   #$1,d0                                      ; Subtract 1 from register d0
	lea.l    $1b1(a5),a1                                 ; Load address of $1b1(a5) into pointer a1
Command_S_Loc_1EB2:
	move.b   (a2),(a1)+                                  ; Move (a2) to (a1)+
	move.b   (a2)+,(a0)+                                 ; Move (a2)+ to (a0)+
	addq.b   #$1,$1b0(a5)                                ; Add 1 to $1b0(a5)
	dbra     d0,Command_S_Loc_1EB2                       ; Decrement loop counter d0 and loop back to Command_S_Loc_1EB2 if not exhausted
	move.b   #$22,(a0)+                                  ; Move constant $22 to (a0)+
	bsr.w    RefreshAndDrawConsoleLine                   ; Call subroutine to RefreshAndDrawConsoleLine
	bsr.w    Console_CursorNextLine                      ; Call subroutine to Console_CursorNextLine
	movea.l  $17da(a6),a1                                ; Move $17da(a6) to pointer a1
	clr.l    $17de(a6)                                   ; Clear / reset $17de(a6)
	move.l   (a1),d5                                     ; Move (a1) to register d5
	beq.b    Command_S_Loc_1EF8                          ; Branch to Command_S_Loc_1EF8 if zero / equal
Command_S_Loc_1ED6:
	cmp.l    $17ce(a6),d5                                ; Compare register d5 against $17ce(a6)
	bhi.b    Command_S_Loc_1EF8                              ; Execute bhi.b instruction
	move.l   d5,$17de(a6)                                ; Move register d5 to $17de(a6)
	lea.l    $3294(a6),a4                                ; Load address of $3294(a6) into pointer a4
	move.l   a4,d6                                       ; Move pointer a4 to register d6
	bsr.w    Disk_ReadWriteSector                        ; Call subroutine to Disk_ReadWriteSector
	tst.b    $1671(a6)                             ; Check if $1671 is set / active
	bne.w    Command_S_Loc_20A4                          ; Branch to Command_S_Loc_20A4 if non-zero / not equal
	move.l   $1f0(a4),d5                                 ; Move $1f0(a4) to register d5
	bne.b    Command_S_Loc_1ED6                          ; Branch to Command_S_Loc_1ED6 if non-zero / not equal
Command_S_Loc_1EF8:
	move.l   d5,$1f0(a5)                                 ; Move register d5 to $1f0(a5)
	move.l   $17d2(a6),$1f4(a5)                          ; Move $17d2(a6) to $1f4(a5)
	move.l   Var_MemEnd(a6),d0                           ; Load monitored memory end offset into register d0
	sub.l    Var_MemStart(a6),d0                         ; Subtract monitored memory start offset from register d0
	move.l   d0,$144(a5)                                 ; Move register d0 to $144(a5)
	move.l   d0,$17e6(a6)                                ; Move register d0 to $17e6(a6)
	beq.b    Command_S_Loc_1F1E                          ; Branch to Command_S_Loc_1F1E if zero / equal
	bsr.w    Afs_AllocateBlockFromStart                  ; Call subroutine to Afs_AllocateBlockFromStart
	beq.w    Command_S_Loc_20AC                          ; Branch to Command_S_Loc_20AC if zero / equal
	move.l   d0,d4                                       ; Move register d0 to register d4
Command_S_Loc_1F1E:
	moveq    #$2,d6                                      ; Initialize register d6 to constant $2
Command_S_Loc_1F20:
	move.l   d6,(a5)                                     ; Move register d6 to (a5)
	moveq    #-3,d6                                      ; Initialize register d6 to constant -3
	move.l   d6,FMODE(a5)                                ; Move register d6 to FMODE (AGA fetch mode control register)
	move.l   a3,$4(a5)                                   ; Move pointer a3 to $4(a5)
	lea.l    $138(a5),a4                                 ; Load address of $138(a5) into pointer a4
	tst.l    $17e6(a6)                             ; Check if $17e6 is set / active
	movea.l  Var_MemEnd(a6),a1                           ; Load monitored memory end offset into pointer a1
	beq.w    Command_S_Loc_1FCE                          ; Branch to Command_S_Loc_1FCE if zero / equal
Command_S_Loc_1F3C:
	move.l   d4,-(a4)                                    ; Move register d4 to -(a4)
	addq.l   #$1,$8(a5)                                  ; Add 1 to $8(a5)
	lea.l    Var_MonitorBufferOffset(a6),a0              ; Load address of Var_MonitorBufferOffset(a6) into pointer a0
	moveq    #$7f,d6                                     ; Initialize register d6 to constant $7f
Command_S_Loc_1F48:
	clr.l    -(a0)                                       ; Clear / reset -(a0)
	dbra     d6,Command_S_Loc_1F48                       ; Decrement loop counter d6 and loop back to Command_S_Loc_1F48 if not exhausted
	move.l   Var_MemEnd(a6),d0                           ; Load monitored memory end offset into register d0
	sub.l    Var_TempMemPtr(a6),d0                       ; Subtract temporary memory workspace pointer from register d0
	subq.l   #$1,d0                                      ; Subtract 1 from register d0
	divu.w   $17e4(a6),d0                          ; Execute divu.w instruction
	tst.w    d0                                          ; Test status of register d0 (for zero or negative)
	beq.b    Command_S_Loc_1F6E                          ; Branch to Command_S_Loc_1F6E if zero / equal
	bsr.w    Afs_AllocateBlockFromStart                  ; Call subroutine to Afs_AllocateBlockFromStart
	beq.w    Command_S_Loc_20AC                          ; Branch to Command_S_Loc_20AC if zero / equal
	move.l   d0,d4                                       ; Move register d0 to register d4
	move.l   d4,$10(a0)                                  ; Move register d4 to $10(a0)
Command_S_Loc_1F6E:
	movea.l  Var_TempMemPtr(a6),a1                       ; Load temporary memory workspace pointer into pointer a1
	movea.l  a0,a2                                       ; Move pointer a0 to pointer a2
	moveq    #$0,d0                                      ; Initialize register d0 to 0
	tst.b    $1676(a6)                             ; Check if $1676 is set / active
	bne.b    Command_S_Loc_1F80                          ; Branch to Command_S_Loc_1F80 if non-zero / not equal
	lea.l    $18(a0),a2                                  ; Load address of $18(a0) into pointer a2
Command_S_Loc_1F80:
	cmpa.l   Var_MemEnd(a6),a1                           ; Compare pointer a1 against monitored memory end offset
	bcc.b    Command_S_Loc_1F90                          ; Branch to Command_S_Loc_1F90 if carry clear (greater or equal)
	move.b   (a1)+,(a2)+                                 ; Move (a1)+ to (a2)+
	addq.w   #$1,d0                                      ; Add 1 to register d0
	cmp.w    $17e4(a6),d0                                ; Compare register d0 against $17e4(a6)
	bne.b    Command_S_Loc_1F80                          ; Branch to Command_S_Loc_1F80 if non-zero / not equal
Command_S_Loc_1F90:
	move.l   a1,Var_TempMemPtr(a6)                       ; Store pointer a1 into temporary memory workspace pointer
	pea.l    $3294(a6)                             ; Execute pea.l instruction
	move.l   (a7)+,d6                                    ; Move (a7)+ to register d6
	move.l   (a4),d5                                     ; Move (a4) to register d5
	tst.b    $1676(a6)                             ; Check if $1676 is set / active
	bne.b    Command_S_Loc_1FC2                          ; Branch to Command_S_Loc_1FC2 if non-zero / not equal
	move.l   d0,$c(a0)                                   ; Move register d0 to $c(a0)
	moveq    #$8,d0                                      ; Initialize register d0 to constant $8
	move.l   d0,(a0)                                     ; Move register d0 to (a0)
	addq.w   #$1,$17e2(a6)                               ; Add 1 to $17e2(a6)
	move.w   $17e2(a6),$a(a0)                            ; Move $17e2(a6) to $a(a0)
	move.l   $17ce(a6),$4(a0)                            ; Move $17ce(a6) to $4(a0)
	bsr.w    Disk_CalculateBootblockChecksum             ; Call subroutine to Disk_CalculateBootblockChecksum
	move.l   d3,$14(a0)                                  ; Move register d3 to $14(a0)
Command_S_Loc_1FC2:
	bsr.w    Disk_WriteSector                            ; Call subroutine to Disk_WriteSector
	tst.b    $1671(a6)                             ; Check if $1671 is set / active
	bne.w    Command_S_Loc_20A4                          ; Branch to Command_S_Loc_20A4 if non-zero / not equal
Command_S_Loc_1FCE:
	lea.l    Var_DisasmBuffer+1(a6),a0                   ; Load address of disassembler output text buffer into pointer a0
	move.l   Var_MemStart(a6),d0                         ; Load monitored memory start offset into register d0
	move.l   Var_TempMemPtr(a6),d1                       ; Load temporary memory workspace pointer into register d1
	bsr.w    Console_OpenMenu                            ; Call subroutine to Console_OpenMenu
	bsr.w    FormatAddressRange8                         ; Call subroutine to FormatAddressRange8
	bsr.w    RefreshAndDrawConsoleLine                   ; Call subroutine to RefreshAndDrawConsoleLine
	bsr.w    WaitInputOrButton                           ; Call subroutine to WaitInputOrButton
	beq.w    Command_S_Loc_20A4                          ; Branch to Command_S_Loc_20A4 if zero / equal
	cmpa.l   Var_MemEnd(a6),a1                           ; Compare pointer a1 against monitored memory end offset
	beq.b    Command_S_Loc_200A                          ; Branch to Command_S_Loc_200A if zero / equal
	moveq    #$48,d6                                     ; Initialize register d6 to constant $48
	cmp.l    $8(a5),d6                                   ; Compare register d6 against $8(a5)
	bne.b    Command_S_Loc_2044                          ; Branch to Command_S_Loc_2044 if non-zero / not equal
	bsr.w    Afs_AllocateBlockFromStart                  ; Call subroutine to Afs_AllocateBlockFromStart
	beq.w    Command_S_Loc_20AC                          ; Branch to Command_S_Loc_20AC if zero / equal
	movea.l  d0,a3                                       ; Move register d0 to pointer a3
	move.l   d0,$1f8(a5)                                 ; Move register d0 to $1f8(a5)
Command_S_Loc_200A:
	movea.l  a5,a0                                       ; Move pointer a5 to pointer a0
	move.l   $134(a0),$10(a0)                            ; Move $134(a0) to $10(a0)
	bsr.w    Disk_CalculateBootblockChecksum             ; Call subroutine to Disk_CalculateBootblockChecksum
	move.l   d3,$14(a0)                                  ; Move register d3 to $14(a0)
	move.l   $4(a0),d5                                   ; Move $4(a0) to register d5
	move.l   a0,d6                                       ; Move pointer a0 to register d6
	bsr.w    Disk_WriteSector                            ; Call subroutine to Disk_WriteSector
	tst.b    $1671(a6)                             ; Check if $1671 is set / active
	bne.b    Command_S_Loc_20A4                          ; Branch to Command_S_Loc_20A4 if non-zero / not equal
	cmpa.l   Var_MemEnd(a6),a1                           ; Compare pointer a1 against monitored memory end offset
	beq.b    Command_S_Loc_204C                          ; Branch to Command_S_Loc_204C if zero / equal
	moveq    #$7f,d6                                     ; Initialize register d6 to constant $7f
Command_S_Loc_2032:
	clr.l    (a0)+                                       ; Clear / reset (a0)+
	dbra     d6,Command_S_Loc_2032                       ; Decrement loop counter d6 and loop back to Command_S_Loc_2032 if not exhausted
	move.l   $17ce(a6),$1f4(a5)                          ; Move $17ce(a6) to $1f4(a5)
	moveq    #$10,d6                                     ; Initialize register d6 to constant $10
	bra.w    Command_S_Loc_1F20                          ; Unconditional branch to Command_S_Loc_1F20
Command_S_Loc_2044:
	cmpa.l   Var_MemEnd(a6),a1                           ; Compare pointer a1 against monitored memory end offset
	bcs.w    Command_S_Loc_1F3C                          ; Branch to Command_S_Loc_1F3C if carry set (less than)
Command_S_Loc_204C:
	lea.l    $3294(a6),a2                                ; Load address of $3294(a6) into pointer a2
	move.l   a2,d6                                       ; Move pointer a2 to register d6
	lea.l    $3484(a6),a2                                ; Load address of $3484(a6) into pointer a2
	move.l   $17de(a6),d5                                ; Move $17de(a6) to register d5
	bne.b    Command_S_Loc_2064                          ; Branch to Command_S_Loc_2064 if non-zero / not equal
	movea.l  $17da(a6),a2                                ; Move $17da(a6) to pointer a2
	move.l   $17d2(a6),d5                                ; Move $17d2(a6) to register d5
Command_S_Loc_2064:
	bsr.w    Disk_ReadWriteSector                        ; Call subroutine to Disk_ReadWriteSector
	tst.b    $1671(a6)                             ; Check if $1671 is set / active
	bne.b    Command_S_Loc_20A4                          ; Branch to Command_S_Loc_20A4 if non-zero / not equal
	move.l   $17ce(a6),(a2)                              ; Move $17ce(a6) to (a2)
	lea.l    $3294(a6),a0                                ; Load address of $3294(a6) into pointer a0
	bsr.w    Disk_CalculateBootblockChecksum             ; Call subroutine to Disk_CalculateBootblockChecksum
	move.l   d3,$14(a0)                                  ; Move register d3 to $14(a0)
	bsr.w    Disk_WriteSector                            ; Call subroutine to Disk_WriteSector
	tst.b    $1671(a6)                             ; Check if $1671 is set / active
	bne.b    Command_S_Loc_20A4                          ; Branch to Command_S_Loc_20A4 if non-zero / not equal
	bsr.w    Afs_UpdateBitmapChecksum                    ; Call subroutine to Afs_UpdateBitmapChecksum
	lea.l    $3694(a6),a0                                ; Load address of $3694(a6) into pointer a0
	move.l   a0,d6                                       ; Move pointer a0 to register d6
	move.l   $17ca(a6),d5                                ; Move $17ca(a6) to register d5
	bsr.w    Disk_WriteSector                            ; Call subroutine to Disk_WriteSector
	tst.b    $1671(a6)                             ; Check if $1671 is set / active
	bne.b    Command_S_Loc_20A4                          ; Branch to Command_S_Loc_20A4 if non-zero / not equal
	bsr.w    Disk_FlushTrackWriteBuffer                  ; Call subroutine to Disk_FlushTrackWriteBuffer
Command_S_Loc_20A4:
	bsr.w    Disk_MotorOff                               ; Call subroutine to Disk_MotorOff
	st.b     d7
Command_S_Loc_20AA:
	rts                                                  ; Return from subroutine
Command_S_Loc_20AC:
	bsr.w    Print_DiskFullError                         ; Call subroutine to Print_DiskFullError
	bra.b    Command_S_Loc_20A4                          ; Unconditional branch to Command_S_Loc_20A4
; ============================================================================
; Function: Afs_FreeBlock
; Purpose : Frees a block in the filesystem bitmap by setting its corresponding bit to 1.
; ============================================================================
Afs_FreeBlock:
	cmp.l    $17ba(a6),d0                                ; Compare register d0 against $17ba(a6)
	bhi.b    Afs_FreeBlock_Loc_20D8                              ; Execute bhi.b instruction
	lea.l    $3694(a6),a0                                ; Load address of $3694(a6) into pointer a0
	subq.l   #$2,d0                                      ; Subtract constant $2 from register d0
	bmi.b    Afs_FreeBlock_Loc_20D8                      ; Branch to Afs_FreeBlock_Loc_20D8 if negative / minus
	move.l   d0,d1                                       ; Move register d0 to register d1
	lsr.w    #$5,d1
	add.w    d1,d1                                       ; Add register d1 to register d1
	add.w    d1,d1                                       ; Add register d1 to register d1
	move.l   $4(a0,d1.w),d2                              ; Move $4(a0,d1.w) to register d2
	bset     d0,d2                                       ; Set bit d0 of register d2
	bne.b    Afs_FreeBlock_Loc_20D8                      ; Branch to Afs_FreeBlock_Loc_20D8 if non-zero / not equal
	move.l   d2,$4(a0,d1.w)                              ; Move register d2 to $4(a0,d1.w)
	moveq    #-1,d0                                      ; Initialize register d0 to constant -1
	rts                                                  ; Return from subroutine
Afs_FreeBlock_Loc_20D8:
	moveq    #$0,d0                                      ; Initialize register d0 to 0
	rts                                                  ; Return from subroutine
; ============================================================================
; Function: Afs_AllocateBlock
; Purpose : Finds and allocates a free block from the bitmap starting from Var_AfsSearchStart and clearing its bit to 0.
; ============================================================================
Afs_AllocateBlock:
	move.l   $17b6(a6),d0                                ; Move $17b6(a6) to register d0
	bsr.b    Afs_FindAndAllocateFreeBlock                ; Call subroutine to Afs_FindAndAllocateFreeBlock
	beq.b    Afs_AllocateBlockFromStart                  ; Branch to Afs_AllocateBlockFromStart if zero / equal
	rts                                                  ; Return from subroutine
Afs_AllocateBlockFromStart:
	moveq    #$0,d0                                      ; Initialize register d0 to 0
; ============================================================================
; Function: Afs_FindAndAllocateFreeBlock
; Purpose : Core bitmap search and clear loop that allocates a free block and returns its index.
; ============================================================================
Afs_FindAndAllocateFreeBlock:
	move.l   a0,-(a7)                                    ; Move pointer a0 to -(a7)
	lea.l    $3694(a6),a0                                ; Load address of $3694(a6) into pointer a0
Afs_FindAndAllocateFreeBlock_Loc_20EE:
	move.w   d0,d1                                       ; Move register d0 to register d1
	lsr.w    #$5,d1
	add.w    d1,d1                                       ; Add register d1 to register d1
	add.w    d1,d1                                       ; Add register d1 to register d1
	move.l   $4(a0,d1.w),d2                              ; Move $4(a0,d1.w) to register d2
	bclr     d0,d2                                       ; Clear bit d0 of register d2
	bne.b    Afs_FindAndAllocateFreeBlock_Loc_2108       ; Branch to Afs_FindAndAllocateFreeBlock_Loc_2108 if non-zero / not equal
	addq.l   #$1,d0                                      ; Add 1 to register d0
	cmp.l    $17be(a6),d0                                ; Compare register d0 against $17be(a6)
	bne.b    Afs_FindAndAllocateFreeBlock_Loc_20EE       ; Branch to Afs_FindAndAllocateFreeBlock_Loc_20EE if non-zero / not equal
	moveq    #-2,d0                                      ; Initialize register d0 to constant -2
Afs_FindAndAllocateFreeBlock_Loc_2108:
	move.l   d2,$4(a0,d1.w)                              ; Move register d2 to $4(a0,d1.w)
	movea.l  (a7)+,a0                                    ; Move (a7)+ to pointer a0
	addq.l   #$2,d0                                      ; Add constant $2 to register d0
	rts                                                  ; Return from subroutine
; ============================================================================
; Function: Afs_UpdateBitmapChecksum
; Purpose : Calculates and updates the standard checksum of the filesystem bitmap block.
; ============================================================================
Afs_UpdateBitmapChecksum:
	lea.l    $3694(a6),a0                                ; Load address of $3694(a6) into pointer a0
; ============================================================================
; Data Block: Afs_AccumulateBitmapChecksum
; Purpose   : Subroutine entry point to accumulate directory bitmap block checksum.
; ============================================================================
Afs_AccumulateBitmapChecksum:
	lea.l    $4(a0),a1                                   ; Load address of $4(a0) into pointer a1
	moveq    #$0,d1                                      ; Initialize register d1 to 0
	moveq    #$7e,d0                                     ; Initialize register d0 to constant $7e
Afs_UpdateBitmapChecksum_Loc_211E:
	sub.l    (a1)+,d1                                    ; Subtract (a1)+ from register d1
	dbra     d0,Afs_UpdateBitmapChecksum_Loc_211E        ; Decrement loop counter d0 and loop back to Afs_UpdateBitmapChecksum_Loc_211E if not exhausted
	move.l   d1,(a0)                                     ; Move register d1 to (a0)
	rts                                                  ; Return from subroutine
; ============================================================================
; Function: Parser_GetNextArg
; Purpose : Parses the next argument from the command line, handling quoted strings and raw words.
; ============================================================================
Parser_GetNextArg:
	clr.w    d4                                          ; Clear / reset register d4
	bsr.b    Parser_SkipSpaces                           ; Call subroutine to Parser_SkipSpaces
	bhi.b    Parser_GetNextArg_Loc_214E                              ; Execute bhi.b instruction
	movea.l  a0,a2                                       ; Move pointer a0 to pointer a2
	cmpi.b   #$22,(a0)                                   ; Compare (a0) against constant $22
	bne.b    Parser_GetNextArg_Loc_2146                  ; Branch to Parser_GetNextArg_Loc_2146 if non-zero / not equal
	clr.w    d4                                          ; Clear / reset register d4
	addq.w   #$1,a2                                      ; Add 1 to pointer a2
	addq.w   #$1,a0                                      ; Add 1 to pointer a0
Parser_GetNextArg_Loc_213C:
	cmpi.b   #$22,(a0)+                                  ; Compare (a0)+ against constant $22
	beq.b    Parser_GetNextArg_Loc_214E                  ; Branch to Parser_GetNextArg_Loc_214E if zero / equal
	addq.w   #$1,d4                                      ; Add 1 to register d4
	bra.b    Parser_GetNextArg_Loc_213C                  ; Unconditional branch to Parser_GetNextArg_Loc_213C
Parser_GetNextArg_Loc_2146:
	bsr.b    Parser_FindEndOfWord                        ; Call subroutine to Parser_FindEndOfWord
	bhi.b    Parser_GetNextArg_Loc_214E                              ; Execute bhi.b instruction
	move.l   a0,d4                                       ; Move pointer a0 to register d4
	sub.l    a2,d4                                       ; Subtract pointer a2 from register d4
Parser_GetNextArg_Loc_214E:
	tst.w    d4                                          ; Test status of register d4 (for zero or negative)
	rts                                                  ; Return from subroutine
; ============================================================================
; Function: Parser_SkipSpaces
; Purpose : Advances the parse pointer past spaces.
; ============================================================================
Parser_SkipSpaces:
	cmpi.b   #$20,(a0)                                   ; Compare (a0) against constant $20
	bne.b    Parser_CheckEnd                             ; Branch to Parser_CheckEnd if non-zero / not equal
	addq.w   #$1,a0                                      ; Add 1 to pointer a0
	bra.b    Parser_SkipSpaces                           ; Unconditional branch to Parser_SkipSpaces
; ============================================================================
; Function: Parser_FindEndOfWord
; Purpose : Advances the parse pointer to the next space character.
; ============================================================================
Parser_FindEndOfWord:
	cmpi.b   #$20,(a0)                                   ; Compare (a0) against constant $20
	beq.b    Parser_CheckEnd                             ; Branch to Parser_CheckEnd if zero / equal
	addq.w   #$1,a0                                      ; Add 1 to pointer a0
	bra.b    Parser_FindEndOfWord                        ; Unconditional branch to Parser_FindEndOfWord
; ============================================================================
; Function: Parser_CheckEnd
; Purpose : Checks if the parse pointer has reached the end of the input buffer.
; ============================================================================
Parser_CheckEnd:
	cmpa.l   Var_ScreenRowPointer(a6),a0                 ; Compare pointer a0 against pointer to active screen row
	rts                                                  ; Return from subroutine
Command_type:
	st.b     $1674(a6)                             ; Execute st.b instruction
	lea.l    $5(a5),a0                                   ; Load address of $5(a5) into pointer a0
	bra.b    Command_L_Loc_217E                          ; Unconditional branch to Command_L_Loc_217E
Command_L:
	sf.b     $1674(a6)                             ; Execute sf.b instruction
	lea.l    DMACONR(a5),a0                              ; Load address of DMACON (DMA control write register) into pointer a0
Command_L_Loc_217E:
	bsr.b    Parser_GetNextArg                           ; Call subroutine to Parser_GetNextArg
	move.w   d4,$182c(a6)                                ; Move register d4 to $182c(a6)
	beq.w    ProcessCommand_Loc_233C                     ; Branch to ProcessCommand_Loc_233C if zero / equal
	cmpi.w   #$1e,d4                                     ; Compare register d4 against constant $1e
	bhi.w    ProcessCommand_Loc_233C                              ; Execute bhi.w instruction
	moveq    #$1,d0                                      ; Initialize register d0 to 1
	tst.b    $1674(a6)                             ; Check if $1674 is set / active
	bne.b    Command_L_Loc_21A4                          ; Branch to Command_L_Loc_21A4 if non-zero / not equal
	bsr.b    Parser_SkipSpaces                           ; Call subroutine to Parser_SkipSpaces
	bhi.w    ProcessCommand_Loc_233C                              ; Execute bhi.w instruction
	movea.l  a0,a3                                       ; Move pointer a0 to pointer a3
	bsr.w    ParseHexNumber                              ; Call subroutine to ParseHexNumber
Command_L_Loc_21A4:
	move.l   d0,Var_MemStart(a6)                         ; Store register d0 into monitored memory start offset
	move.l   d0,Var_MemEnd(a6)                           ; Store register d0 into monitored memory end offset
	beq.w    ProcessCommand_Loc_233C                     ; Branch to ProcessCommand_Loc_233C if zero / equal
	sf.b     $1673(a6)                             ; Execute sf.b instruction
	sf.b     $1672(a6)                             ; Execute sf.b instruction
	bsr.w    Disk_PrepareDriveAndReadTrack               ; Call subroutine to Disk_PrepareDriveAndReadTrack
	bne.w    ProcessCommand_Loc_2328                     ; Branch to ProcessCommand_Loc_2328 if non-zero / not equal
	movea.l  a2,a0                                       ; Move pointer a2 to pointer a0
	bsr.w    Afs_HashFilename                            ; Call subroutine to Afs_HashFilename
	beq.b    Command_L_Loc_21CE                          ; Branch to Command_L_Loc_21CE if zero / equal
	bsr.w    Afs_FindFileInDirectory                     ; Call subroutine to Afs_FindFileInDirectory
	bne.b    Command_L_Loc_21D6                          ; Branch to Command_L_Loc_21D6 if non-zero / not equal
Command_L_Loc_21CE:
	bsr.w    Print_FileNotFoundError                     ; Call subroutine to Print_FileNotFoundError
	bra.w    ProcessCommand_Loc_2328                     ; Unconditional branch to ProcessCommand_Loc_2328
Command_L_Loc_21D6:
	tst.b    $1671(a6)                             ; Check if $1671 is set / active
	bne.w    ProcessCommand_Loc_2328                     ; Branch to ProcessCommand_Loc_2328 if non-zero / not equal
	move.l   FMODE(a4),d0                                ; Move FMODE (AGA fetch mode control register) to register d0
	subq.l   #$2,d0                                      ; Subtract constant $2 from register d0
	beq.b    Command_L_Loc_2208                          ; Branch to Command_L_Loc_2208 if zero / equal
	subq.l   #$2,d0                                      ; Subtract constant $2 from register d0
	beq.b    Command_L_Loc_2208                          ; Branch to Command_L_Loc_2208 if zero / equal
	addq.l   #$7,d0                                      ; Add constant $7 to register d0
	beq.b    Command_L_Loc_2210                          ; Branch to Command_L_Loc_2210 if zero / equal
	addq.l   #$1,d0                                      ; Add 1 to register d0
	bne.w    ProcessCommand_Loc_2328                     ; Branch to ProcessCommand_Loc_2328 if non-zero / not equal
	move.w   a4,d6                                       ; Move pointer a4 to register d6
	move.l   $1d4(a4),d5                                 ; Move $1d4(a4) to register d5
	bsr.w    Disk_ReadWriteSector                        ; Call subroutine to Disk_ReadWriteSector
	tst.b    $1671(a6)                             ; Check if $1671 is set / active
	bne.w    ProcessCommand_Loc_2328                     ; Branch to ProcessCommand_Loc_2328 if non-zero / not equal
	bra.b    Command_L_Loc_2210                          ; Unconditional branch to Command_L_Loc_2210
Command_L_Loc_2208:
	bsr.w    Print_FileIsADirectoryError                 ; Call subroutine to Print_FileIsADirectoryError
	bra.w    ProcessCommand_Loc_2328                     ; Unconditional branch to ProcessCommand_Loc_2328
Command_L_Loc_2210:
	lea.l    Var_DisasmBuffer+1(a6),a0                   ; Load address of disassembler output text buffer into pointer a0
	lea.l    -$1d37(a6),a1                               ; Load address of -$1d37(a6) into pointer a1
	tst.b    $1674(a6)                             ; Check if $1674 is set / active
	bne.b    Command_L_Loc_2222                          ; Branch to Command_L_Loc_2222 if non-zero / not equal
	lea.l    -$1d41(a6),a1                               ; Load address of -$1d41(a6) into pointer a1
Command_L_Loc_2222:
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	move.w   $182c(a6),d0                                ; Move $182c(a6) to register d0
	subq.w   #$1,d0                                      ; Subtract 1 from register d0
	movea.l  a2,a1                                       ; Move pointer a2 to pointer a1
Command_L_Loc_222E:
	move.b   (a1)+,(a0)+                                 ; Copy word/byte data from source pointer a1 to destination a0
	dbra     d0,Command_L_Loc_222E                       ; Decrement loop counter d0 and loop back to Command_L_Loc_222E if not exhausted
	move.b   #$22,(a0)+                                  ; Move constant $22 to (a0)+
	bsr.w    RefreshAndDrawConsoleLine                   ; Call subroutine to RefreshAndDrawConsoleLine
	bsr.w    Console_CursorNextLine                      ; Call subroutine to Console_CursorNextLine
	move.l   $144(a4),$17e6(a6)                          ; Move $144(a4) to $17e6(a6)
Command_Loop_Start:
	moveq    #$48,d3                                     ; Initialize register d3 to constant $48
	lea.l    $138(a4),a3                                 ; Load address of $138(a4) into pointer a3
Command_Loop_Start_Loc_224C:
	tst.b    $1674(a6)                             ; Check if $1674 is set / active
	bne.b    Command_Loop_Start_Loc_226A                 ; Branch to Command_Loop_Start_Loc_226A if non-zero / not equal
	lea.l    Var_DisasmBuffer+1(a6),a0                   ; Load address of disassembler output text buffer into pointer a0
	move.l   Var_MemStart(a6),d0                         ; Load monitored memory start offset into register d0
	move.l   Var_MemEnd(a6),d1                           ; Load monitored memory end offset into register d1
	bsr.w    FormatAddressRange8                         ; Call subroutine to FormatAddressRange8
	bsr.w    Console_OpenMenu                            ; Call subroutine to Console_OpenMenu
	bsr.w    RefreshAndDrawConsoleLine                   ; Call subroutine to RefreshAndDrawConsoleLine
Command_Loop_Start_Loc_226A:
	bsr.w    WaitInputOrButton                           ; Call subroutine to WaitInputOrButton
	beq.w    ProcessCommand_Loc_2328                     ; Branch to ProcessCommand_Loc_2328 if zero / equal
	subq.l   #$1,d3                                      ; Subtract 1 from register d3
	bmi.w    Command_Loop_Start_Loc_2312                 ; Branch to Command_Loop_Start_Loc_2312 if negative / minus
	move.l   -(a3),d5                                    ; Move -(a3) to register d5
	lea.l    $3294(a6),a0                                ; Load address of $3294(a6) into pointer a0
	move.l   a0,d6                                       ; Move pointer a0 to register d6
	bsr.w    Disk_ReadWriteSector                        ; Call subroutine to Disk_ReadWriteSector
	tst.b    $1671(a6)                             ; Check if $1671 is set / active
	bne.w    ProcessCommand_Loc_2328                     ; Branch to ProcessCommand_Loc_2328 if non-zero / not equal
	move.l   $17e6(a6),d0                                ; Move $17e6(a6) to register d0
	beq.w    ProcessCommand_Loc_2328                     ; Branch to ProcessCommand_Loc_2328 if zero / equal
	sub.l    Var_MemEnd(a6),d0                           ; Subtract monitored memory end offset from register d0
	add.l    Var_MemStart(a6),d0                         ; Add monitored memory start offset to register d0
	beq.w    ProcessCommand_Loc_2328                     ; Branch to ProcessCommand_Loc_2328 if zero / equal
	subq.l   #$1,d0                                      ; Subtract 1 from register d0
	divu.w   $17e4(a6),d0                          ; Execute divu.w instruction
	tst.w    d0                                          ; Test status of register d0 (for zero or negative)
	bne.b    Command_Loop_Start_Loc_22B0                 ; Branch to Command_Loop_Start_Loc_22B0 if non-zero / not equal
	swap     d0
	addq.w   #$1,d0                                      ; Add 1 to register d0
	bra.b    Command_Loop_Start_Loc_22B4                 ; Unconditional branch to Command_Loop_Start_Loc_22B4
Command_Loop_Start_Loc_22B0:
	move.w   $17e4(a6),d0                                ; Move $17e4(a6) to register d0
Command_Loop_Start_Loc_22B4:
	tst.b    $1676(a6)                             ; Check if $1676 is set / active
	bne.b    Command_Loop_Start_Loc_22BE                 ; Branch to Command_Loop_Start_Loc_22BE if non-zero / not equal
	lea.l    $18(a0),a0                                  ; Load address of $18(a0) into pointer a0
Command_Loop_Start_Loc_22BE:
	tst.b    $1674(a6)                             ; Check if $1674 is set / active
	beq.b    Command_Loop_Start_Loc_22FE                 ; Branch to Command_Loop_Start_Loc_22FE if zero / equal
	ext.l    d0
	add.l    d0,Var_MemEnd(a6)                           ; Add register d0 to monitored memory end offset
	move.l   d0,d1                                       ; Move register d0 to register d1
Command_Loop_Start_Loc_22CC:
	subq.w   #$1,d1                                      ; Subtract 1 from register d1
	bmi.b    Command_Loop_Start_Loc_22FA                 ; Branch to Command_Loop_Start_Loc_22FA if negative / minus
	bsr.w    WaitInputOrButton                           ; Call subroutine to WaitInputOrButton
	beq.b    ProcessCommand_Loc_2328                     ; Branch to ProcessCommand_Loc_2328 if zero / equal
	cmpi.b   #BLTBPTH,Var_CursorX(a6)                    ; Compare cursor horizontal column coordinate against constant BLTBPTH
	bne.b    Command_Loop_Start_Loc_22E2                 ; Branch to Command_Loop_Start_Loc_22E2 if non-zero / not equal
	addq.w   #$1,d1                                      ; Add 1 to register d1
	bra.b    Command_Loop_Start_Loc_22EA                 ; Unconditional branch to Command_Loop_Start_Loc_22EA
Command_Loop_Start_Loc_22E2:
	move.b   (a0)+,d0                                    ; Move (a0)+ to register d0
	cmpi.b   #$a,d0                                      ; Compare register d0 against constant $a
	bne.b    Command_Loop_Start_Loc_22F4                 ; Branch to Command_Loop_Start_Loc_22F4 if non-zero / not equal
Command_Loop_Start_Loc_22EA:
	sf.b     Var_CursorX(a6)                       ; Execute sf.b instruction
	bsr.w    Console_CursorNextLine                      ; Call subroutine to Console_CursorNextLine
	bra.b    Command_Loop_Start_Loc_22F8                 ; Unconditional branch to Command_Loop_Start_Loc_22F8
Command_Loop_Start_Loc_22F4:
	bsr.w    Console_DrawChar                            ; Call subroutine to Console_DrawChar
Command_Loop_Start_Loc_22F8:
	bra.b    Command_Loop_Start_Loc_22CC                 ; Unconditional branch to Command_Loop_Start_Loc_22CC
Command_Loop_Start_Loc_22FA:
	bra.w    Command_Loop_Start_Loc_224C                 ; Unconditional branch to Command_Loop_Start_Loc_224C
Command_Loop_Start_Loc_22FE:
	movea.l  Var_MemEnd(a6),a1                           ; Load monitored memory end offset into pointer a1
Command_Loop_Start_Loc_2302:
	subq.w   #$1,d0                                      ; Subtract 1 from register d0
	bmi.b    Command_Loop_Start_Loc_230A                 ; Branch to Command_Loop_Start_Loc_230A if negative / minus
	move.b   (a0)+,(a1)+                                 ; Copy word/byte data from source pointer a0 to destination a1
	bra.b    Command_Loop_Start_Loc_2302                 ; Unconditional branch to Command_Loop_Start_Loc_2302
Command_Loop_Start_Loc_230A:
	move.l   a1,Var_MemEnd(a6)                           ; Store pointer a1 into monitored memory end offset
	bra.w    Command_Loop_Start_Loc_224C                 ; Unconditional branch to Command_Loop_Start_Loc_224C
Command_Loop_Start_Loc_2312:
	move.l   $1f8(a4),d5                                 ; Move $1f8(a4) to register d5
	beq.b    ProcessCommand_Loc_2328                     ; Branch to ProcessCommand_Loc_2328 if zero / equal
	move.l   a4,d6                                       ; Move pointer a4 to register d6
	bsr.w    Disk_ReadWriteSector                        ; Call subroutine to Disk_ReadWriteSector
	tst.b    $1671(a6)                             ; Check if $1671 is set / active
; ============================================================================
; Function: ProcessCommand
; Purpose : Parses and executes user commands typed into the monitor command line. Matches the entered command character, validates its parameters, and dispatches to the corresponding command handler.
; ============================================================================
ProcessCommand:
	bne.b    ProcessCommand_Loc_2328                     ; Branch to ProcessCommand_Loc_2328 if non-zero / not equal
	bra.w    Command_Loop_Start                          ; Unconditional branch to Command_Loop_Start
ProcessCommand_Loc_2328:
	tst.b    $1674(a6)                             ; Check if $1674 is set / active
	beq.b    ProcessCommand_Loc_2336                     ; Branch to ProcessCommand_Loc_2336 if zero / equal
	sf.b     Var_CursorX(a6)                       ; Clear cursor X coordinate flag (false).
	bsr.w    Console_CursorNextLine                      ; Call subroutine to Console_CursorNextLine
ProcessCommand_Loc_2336:
	bsr.w    Disk_MotorOff                               ; Call subroutine to Disk_MotorOff
	st.b     d7
ProcessCommand_Loc_233C:
	rts                                                  ; Return from subroutine
Afs_FindFileInDirectory:
	lea.l    Var_MonitorBufferOffset(a6),a4              ; Load address of Var_MonitorBufferOffset(a6) into pointer a4
	move.l   a4,d6                                       ; Move pointer a4 to register d6
	clr.l    $17d6(a6)                                   ; Clear / reset $17d6(a6)
Afs_FindFileInDirectory_Loc_2348:
	bsr.w    Disk_ReadWriteSector                        ; Call subroutine to Disk_ReadWriteSector
	tst.b    $1671(a6)                             ; Check if $1671 is set / active
	bne.b    Afs_FindFileInDirectory_Loc_237C            ; Branch to Afs_FindFileInDirectory_Loc_237C if non-zero / not equal
	lea.l    $1b0(a4),a0                                 ; Load address of $1b0(a4) into pointer a0
	move.b   (a0)+,d0                                    ; Move (a0)+ to register d0
	movea.l  a2,a1                                       ; Move pointer a2 to pointer a1
Afs_FindFileInDirectory_Loc_235A:
	subq.b   #$1,d0                                      ; Subtract 1 from register d0
	bmi.b    Afs_FindFileInDirectory_Loc_2380            ; Branch to Afs_FindFileInDirectory_Loc_2380 if negative / minus
	move.b   (a0)+,d2                                    ; Move (a0)+ to register d2
	bsr.w    Afs_ToUpper_AsciiOnly                       ; Call subroutine to Afs_ToUpper_AsciiOnly
	move.b   d2,d3                                       ; Move register d2 to register d3
	move.b   (a1)+,d2                                    ; Move (a1)+ to register d2
	bsr.w    Afs_ToUpper_AsciiOnly                       ; Call subroutine to Afs_ToUpper_AsciiOnly
	cmp.b    d2,d3                                       ; Compare register d3 against register d2
	beq.b    Afs_FindFileInDirectory_Loc_235A            ; Branch to Afs_FindFileInDirectory_Loc_235A if zero / equal
	move.l   $4(a4),$17d6(a6)                            ; Move $4(a4) to $17d6(a6)
	move.l   $1f0(a4),d5                                 ; Move $1f0(a4) to register d5
	bne.b    Afs_FindFileInDirectory_Loc_2348            ; Branch to Afs_FindFileInDirectory_Loc_2348 if non-zero / not equal
Afs_FindFileInDirectory_Loc_237C:
	moveq    #$0,d0                                      ; Initialize register d0 to 0
	rts                                                  ; Return from subroutine
Afs_FindFileInDirectory_Loc_2380:
	moveq    #-1,d0                                      ; Initialize register d0 to constant -1
	rts                                                  ; Return from subroutine
Print_BadBitmapError:
	lea.l    -$1cd8(a6),a1                               ; Load address of -$1cd8(a6) into pointer a1
	bra.b    PrintString                                 ; Unconditional branch to PrintString
Print_NotEnoughFreeSpaceError:
	lea.l    -$1cc5(a6),a1                               ; Load address of -$1cc5(a6) into pointer a1
	bra.b    PrintString                                 ; Unconditional branch to PrintString
Print_DiskFullError:
	lea.l    -$1cce(a6),a1                               ; Load address of -$1cce(a6) into pointer a1
	bra.b    PrintString                                 ; Unconditional branch to PrintString
Print_DirectoryNotEmptyError:
	lea.l    -$1cb0(a6),a1                               ; Load address of -$1cb0(a6) into pointer a1
	bra.b    PrintString                                 ; Unconditional branch to PrintString
Print_DirectoryExistsError:
	lea.l    -$1c9d(a6),a1                               ; Load address of -$1c9d(a6) into pointer a1
	bra.b    PrintString                                 ; Unconditional branch to PrintString
Print_DirectoryIsAFileError:
	lea.l    -$1c8d(a6),a1                               ; Load address of -$1c8d(a6) into pointer a1
	bra.b    PrintString                                 ; Unconditional branch to PrintString
Print_DirectoryNotFoundError:
	lea.l    -$1c7a(a6),a1                               ; Load address of -$1c7a(a6) into pointer a1
	bra.b    PrintString                                 ; Unconditional branch to PrintString
Print_FileExistsError:
	lea.l    -$1c67(a6),a1                               ; Load address of -$1c67(a6) into pointer a1
	bra.b    PrintString                                 ; Unconditional branch to PrintString
Print_FileIsADirectoryError:
	lea.l    -$1c5c(a6),a1                               ; Load address of -$1c5c(a6) into pointer a1
	bra.b    PrintString                                 ; Unconditional branch to PrintString
Print_FileNotFoundError:
	lea.l    -$1c49(a6),a1                               ; Load address of -$1c49(a6) into pointer a1
; ============================================================================
; Function: PrintString
; Purpose : Helper to print a null-terminated string to the monitor terminal.
; ============================================================================
PrintString:
	lea.l    Var_DisasmBuffer+1(a6),a0                   ; Load address of disassembler output text buffer into pointer a0
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	bra.w    RefreshAndDrawConsoleLine                   ; Unconditional branch to RefreshAndDrawConsoleLine
Afs_HashFilename:
	move.l   d4,d0                                       ; Move register d4 to register d0
	clr.w    d2                                          ; Clear / reset register d2
	subq.w   #$1,d0                                      ; Subtract 1 from register d0
Afs_HashFilename_Loc_23D0:
	mulu.w   #$d,d4
	move.b   (a0)+,d2                                    ; Move (a0)+ to register d2
	bsr.b    Afs_ToUpper_International                   ; Call subroutine to Afs_ToUpper_International
	add.w    d2,d4                                       ; Add register d2 to register d4
	andi.w   #$7ff,d4                                    ; Logical AND register d4 with constant $7ff
	dbra     d0,Afs_HashFilename_Loc_23D0                ; Decrement loop counter d0 and loop back to Afs_HashFilename_Loc_23D0 if not exhausted
	divu.w   #$48,d4
	swap     d4
	addq.w   #$6,d4                                      ; Add constant $6 to register d4
	add.w    d4,d4                                       ; Add register d4 to register d4
	add.w    d4,d4                                       ; Add register d4 to register d4
	lea.l    $3294(a6),a0                                ; Load address of $3294(a6) into pointer a0
	lea.l    (a0,d4.w),a0                                ; Load address of (a0,d4.w) into pointer a0
	move.l   a0,$17da(a6)                                ; Move pointer a0 to $17da(a6)
	move.l   (a0),d5                                     ; Move (a0) to register d5
	rts                                                  ; Return from subroutine
Afs_ToUpper_International:
	tst.b    $1677(a6)                             ; Check if $1677 is set / active
	beq.b    Afs_ToUpper_AsciiOnly                       ; Branch to Afs_ToUpper_AsciiOnly if zero / equal
	cmpi.b   #$f7,d2                                     ; Compare register d2 against constant $f7
	beq.b    Afs_ToUpper_International_Loc_2432          ; Branch to Afs_ToUpper_International_Loc_2432 if zero / equal
	movem.l  d0-d1,-(a7)                                 ; Move multiple registers d0-d1 to -(a7)
	move.b   d2,d0                                       ; Move register d2 to register d0
	move.l   #$7e607a61,d1                               ; Move constant $7e607a61 to register d1
	bclr     #$7,d2                                      ; Clear bit #$7 of register d2
	beq.b    Afs_ToUpper_International_Loc_241E          ; Branch to Afs_ToUpper_International_Loc_241E if zero / equal
	swap     d1
Afs_ToUpper_International_Loc_241E:
	cmp.b    d1,d2                                       ; Compare register d2 against register d1
	blt.b    Afs_ToUpper_International_Loc_242C          ; Branch to Afs_ToUpper_International_Loc_242C if less than
	lsr.l    #$8,d1
	cmp.b    d1,d2                                       ; Compare register d2 against register d1
	bgt.b    Afs_ToUpper_International_Loc_242C          ; Branch to Afs_ToUpper_International_Loc_242C if greater than
	bclr     #$5,d0                                      ; Clear bit #$5 of register d0
Afs_ToUpper_International_Loc_242C:
	move.b   d0,d2                                       ; Move register d0 to register d2
	movem.l  (a7)+,d0-d1                                 ; Move multiple registers (a7)+ to d0-d1
Afs_ToUpper_International_Loc_2432:
	rts                                                  ; Return from subroutine
Afs_ToUpper_AsciiOnly:
	cmpi.b   #$61,d2                                     ; Compare register d2 against constant $61
	bcs.b    Afs_ToUpper_AsciiOnly_Loc_2444              ; Branch to Afs_ToUpper_AsciiOnly_Loc_2444 if carry set (less than)
	cmpi.b   #$7a,d2                                     ; Compare register d2 against constant $7a
	bhi.b    Afs_ToUpper_AsciiOnly_Loc_2444                              ; Branch to Afs_ToUpper_AsciiOnly_Loc_2444 if higher.
	bclr     #$5,d2                                      ; Clear bit #$5 of register d2
Afs_ToUpper_AsciiOnly_Loc_2444:
	rts                                                  ; Return from subroutine
	cmpi.b   #$1,d3                                      ; Compare register d3 against 1
	bhi.b    Afs_ToUpper_AsciiOnly_Loc_24B2                              ; Branch to Afs_ToUpper_AsciiOnly_Loc_24B2 if higher.
	tst.b    d3                                          ; Test status of register d3 (for zero or negative)
	beq.b    Afs_ToUpper_AsciiOnly_Loc_2456              ; Branch to Afs_ToUpper_AsciiOnly_Loc_2456 if zero / equal
	move.w   $1822(a6),$17b2(a6)                         ; Move $1822(a6) to $17b2(a6)
Afs_ToUpper_AsciiOnly_Loc_2456:
	lea.l    Var_DisasmBuffer+1(a6),a0                   ; Load address of disassembler output text buffer into pointer a0
	lea.l    Str_Sync(pc),a1                            ; Load address of Str_Sync(pc) into pointer a1
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	move.w   $17b2(a6),d0                                ; Move $17b2(a6) to register d0
	move.w   d0,d4                                       ; Move register d0 to register d4
	bsr.w    PrintHex4_Entry                             ; Call subroutine to PrintHex4_Entry
	moveq    #$e,d0                                      ; Initialize register d0 to constant $e
	moveq    #$3,d2                                      ; Initialize register d2 to constant $3
	bra.b    Afs_ToUpper_AsciiOnly_Loc_2474              ; Unconditional branch to Afs_ToUpper_AsciiOnly_Loc_2474
Afs_ToUpper_AsciiOnly_Loc_2472:
	add.w    d2,d2                                       ; Add register d2 to register d2
Afs_ToUpper_AsciiOnly_Loc_2474:
	move.w   d4,d1                                       ; Move register d4 to register d1
	not.w    d1
	and.w    d2,d1                                       ; Logical AND register d1 with register d2
	dbeq     d0,Afs_ToUpper_AsciiOnly_Loc_2472                           ; Execute dbeq instruction
	beq.b    Afs_ToUpper_AsciiOnly_Loc_24A4              ; Branch to Afs_ToUpper_AsciiOnly_Loc_24A4 if zero / equal
	moveq    #$c,d0                                      ; Initialize register d0 to constant $c
	moveq    #$f,d2                                      ; Initialize register d2 to constant $f
	bra.b    Afs_ToUpper_AsciiOnly_Loc_2488              ; Unconditional branch to Afs_ToUpper_AsciiOnly_Loc_2488
Afs_ToUpper_AsciiOnly_Loc_2486:
	add.w    d2,d2                                       ; Add register d2 to register d2
Afs_ToUpper_AsciiOnly_Loc_2488:
	move.w   d4,d1                                       ; Move register d4 to register d1
	and.w    d2,d1                                       ; Logical AND register d1 with register d2
	dbeq     d0,Afs_ToUpper_AsciiOnly_Loc_2486                           ; Execute dbeq instruction
	beq.b    Afs_ToUpper_AsciiOnly_Loc_24A4              ; Branch to Afs_ToUpper_AsciiOnly_Loc_24A4 if zero / equal
	moveq    #$d,d0                                      ; Initialize register d0 to constant $d
	moveq    #$7,d2                                      ; Initialize register d2 to constant $7
	bra.b    Afs_ToUpper_AsciiOnly_Loc_249A              ; Unconditional branch to Afs_ToUpper_AsciiOnly_Loc_249A
Afs_ToUpper_AsciiOnly_Loc_2498:
	add.w    d2,d2                                       ; Add register d2 to register d2
Afs_ToUpper_AsciiOnly_Loc_249A:
	move.w   d4,d1                                       ; Move register d4 to register d1
	and.w    d2,d1                                       ; Logical AND register d1 with register d2
	dbeq     d0,Afs_ToUpper_AsciiOnly_Loc_2498                           ; Execute dbeq instruction
	beq.b    Afs_ToUpper_AsciiOnly_Loc_24AC              ; Branch to Afs_ToUpper_AsciiOnly_Loc_24AC if zero / equal
Afs_ToUpper_AsciiOnly_Loc_24A4:
	lea.l    Str_Invalid(pc),a1                            ; Load address of Str_Invalid(pc) into pointer a1
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
Afs_ToUpper_AsciiOnly_Loc_24AC:
	bsr.w    RefreshAndDrawConsoleLine                   ; Call subroutine to RefreshAndDrawConsoleLine
	st.b     d7
Afs_ToUpper_AsciiOnly_Loc_24B2:
	rts                                                  ; Return from subroutine
	moveq    #$0,d5                                      ; Initialize register d5 to 0
	subq.b   #$1,d3                                      ; Subtract 1 from register d3
	bmi.b    Afs_ToUpper_AsciiOnly_Loc_24CC              ; Branch to Afs_ToUpper_AsciiOnly_Loc_24CC if negative / minus
	bhi.w    Afs_ToUpper_AsciiOnly_Loc_24B2                              ; Branch to Afs_ToUpper_AsciiOnly_Loc_24B2 if higher.
	move.l   Var_MemStart(a6),d5                         ; Load monitored memory start offset into register d5
	cmpi.l   #$a3,d5                                     ; Compare register d5 against constant $a3
	bhi.w    Afs_ToUpper_AsciiOnly_Loc_24B2                              ; Branch to Afs_ToUpper_AsciiOnly_Loc_24B2 if higher.
Afs_ToUpper_AsciiOnly_Loc_24CC:
	bsr.w    Disk_SelectDriveAndMotorOn                  ; Call subroutine to Disk_SelectDriveAndMotorOn
	bsr.w    Disk_StepOut                                ; Call subroutine to Disk_StepOut
	bsr.w    Disk_StepIn                                 ; Call subroutine to Disk_StepIn
	sf.b     $1671(a6)                             ; Clear $1671(a6) flag (false).
	bsr.w    Disk_SeekTrack0                             ; Call subroutine to Disk_SeekTrack0
	tst.b    $1671(a6)                             ; Check if $1671 is set / active
	bne.w    Afs_ToUpper_AsciiOnly_Loc_25AE              ; Branch to Afs_ToUpper_AsciiOnly_Loc_25AE if non-zero / not equal
	sf.b     $1672(a6)                             ; Clear $1672(a6) flag (false).
	bsr.w    Disk_CheckWriteProtectAndPresent            ; Call subroutine to Disk_CheckWriteProtectAndPresent
	bne.w    Afs_ToUpper_AsciiOnly_Loc_25AE              ; Branch to Afs_ToUpper_AsciiOnly_Loc_25AE if non-zero / not equal
	move.l   d5,d1                                       ; Move register d5 to register d1
	bsr.w    Disk_SeekTrack                              ; Call subroutine to Disk_SeekTrack
	movea.l  Var_Bitplane2(a6),a3                        ; Load second bitplane memory pointer into pointer a3
	moveq    #-1,d0                                      ; Initialize register d0 to constant -1
	move.w   $17b4(a6),d1                                ; Move $17b4(a6) to register d1
	lsr.w    #$1,d1
	bra.b    Afs_ToUpper_AsciiOnly_Loc_250A              ; Unconditional branch to Afs_ToUpper_AsciiOnly_Loc_250A
Afs_ToUpper_AsciiOnly_Loc_2508:
	move.l   d0,(a3)+                                    ; Move register d0 to (a3)+
Afs_ToUpper_AsciiOnly_Loc_250A:
	dbra     d1,Afs_ToUpper_AsciiOnly_Loc_2508           ; Decrement loop counter d1 and loop back to Afs_ToUpper_AsciiOnly_Loc_2508 if not exhausted
	bsr.w    DiskDma_WaitForIndex                        ; Call subroutine to DiskDma_WaitForIndex
	moveq    #$f,d5                                      ; Initialize register d5 to constant $f
Afs_ToUpper_AsciiOnly_Loc_2514:
	movea.l  Var_Bitplane2(a6),a3                        ; Load second bitplane memory pointer into pointer a3
	move.w   $17b4(a6),d0                                ; Move $17b4(a6) to register d0
	add.w    d0,d0                                       ; Add register d0 to register d0
	lea.l    (a3,d0.w),a4                                ; Load address of (a3,d0.w) into pointer a4
	lea.l    Var_DisasmBuffer(a6),a0                     ; Load address of disassembler output text buffer into pointer a0
	move.b   #$2d,(a0)+                                  ; Move constant $2d to (a0)+
Afs_ToUpper_AsciiOnly_Loc_252A:
	cmpa.l   a4,a3                                       ; Compare pointer a3 against pointer a4
	bcc.b    Afs_ToUpper_AsciiOnly_Loc_257E              ; Branch to Afs_ToUpper_AsciiOnly_Loc_257E if carry clear (greater or equal)
	cmpi.w   #$aaaa,(a3)+                                ; Compare (a3)+ against constant $aaaa
	bne.b    Afs_ToUpper_AsciiOnly_Loc_252A              ; Branch to Afs_ToUpper_AsciiOnly_Loc_252A if non-zero / not equal
Afs_ToUpper_AsciiOnly_Loc_2534:
	cmpi.w   #$aaaa,(a3)                                 ; Compare (a3) against constant $aaaa
	bne.w    Afs_ToUpper_AsciiOnly_Loc_2540              ; Branch to Afs_ToUpper_AsciiOnly_Loc_2540 if non-zero / not equal
	addq.w   #$2,a3                                      ; Add constant $2 to pointer a3
	bra.b    Afs_ToUpper_AsciiOnly_Loc_2534              ; Unconditional branch to Afs_ToUpper_AsciiOnly_Loc_2534
Afs_ToUpper_AsciiOnly_Loc_2540:
	move.w   (a3)+,d3                                    ; Move (a3)+ to register d3
	moveq    #$7,d2                                      ; Initialize register d2 to constant $7
	moveq    #$6,d1                                      ; Initialize register d1 to constant $6
Afs_ToUpper_AsciiOnly_Loc_2546:
	move.w   d3,d0                                       ; Move register d3 to register d0
	and.w    d2,d0                                       ; Logical AND register d0 with register d2
	beq.b    Afs_ToUpper_AsciiOnly_Loc_2556              ; Branch to Afs_ToUpper_AsciiOnly_Loc_2556 if zero / equal
	add.w    d2,d2                                       ; Add register d2 to register d2
	add.w    d2,d2                                       ; Add register d2 to register d2
	dbra     d1,Afs_ToUpper_AsciiOnly_Loc_2546           ; Decrement loop counter d1 and loop back to Afs_ToUpper_AsciiOnly_Loc_2546 if not exhausted
	bra.b    Afs_ToUpper_AsciiOnly_Loc_252A              ; Unconditional branch to Afs_ToUpper_AsciiOnly_Loc_252A
Afs_ToUpper_AsciiOnly_Loc_2556:
	tst.w    d1                                          ; Test status of register d1 (for zero or negative)
	beq.b    Afs_ToUpper_AsciiOnly_Loc_2568              ; Branch to Afs_ToUpper_AsciiOnly_Loc_2568 if zero / equal
Afs_ToUpper_AsciiOnly_Loc_255A:
	add.w    d2,d2                                       ; Add register d2 to register d2
	add.w    d2,d2                                       ; Add register d2 to register d2
	move.w   d3,d0                                       ; Move register d3 to register d0
	and.w    d2,d0                                       ; Logical AND register d0 with register d2
	beq.b    Afs_ToUpper_AsciiOnly_Loc_252A              ; Branch to Afs_ToUpper_AsciiOnly_Loc_252A if zero / equal
	dbra     d1,Afs_ToUpper_AsciiOnly_Loc_255A           ; Decrement loop counter d1 and loop back to Afs_ToUpper_AsciiOnly_Loc_255A if not exhausted
Afs_ToUpper_AsciiOnly_Loc_2568:
	cmpa.l   a4,a3                                       ; Compare pointer a3 against pointer a4
	bhi.b    Afs_ToUpper_AsciiOnly_Loc_257E                              ; Branch to Afs_ToUpper_AsciiOnly_Loc_257E if higher.
	lea.l    $19e6(a6),a1                                ; Load address of $19e6(a6) into pointer a1
	cmpa.l   a1,a0                                       ; Compare pointer a0 against pointer a1
	bhi.b    Afs_ToUpper_AsciiOnly_Loc_258A                              ; Branch to Afs_ToUpper_AsciiOnly_Loc_258A if higher.
	move.w   d3,d0                                       ; Move register d3 to register d0
	bsr.w    FormatHex4                                  ; Call subroutine to FormatHex4
	addq.w   #$1,a0                                      ; Add 1 to pointer a0
	bra.b    Afs_ToUpper_AsciiOnly_Loc_252A              ; Unconditional branch to Afs_ToUpper_AsciiOnly_Loc_252A
Afs_ToUpper_AsciiOnly_Loc_257E:
	lea.l    Var_DisasmBuffer+1(a6),a1                   ; Load address of disassembler output text buffer into pointer a1
	cmpa.l   a1,a0                                       ; Compare pointer a0 against pointer a1
	beq.b    Afs_ToUpper_AsciiOnly_Loc_2592              ; Branch to Afs_ToUpper_AsciiOnly_Loc_2592 if zero / equal
	bsr.w    RefreshAndDrawConsoleLine                   ; Call subroutine to RefreshAndDrawConsoleLine
Afs_ToUpper_AsciiOnly_Loc_258A:
	lea.l    Var_DisasmBuffer(a6),a0                     ; Load address of disassembler output text buffer into pointer a0
	move.b   #$2d,(a0)+                                  ; Move constant $2d to (a0)+
Afs_ToUpper_AsciiOnly_Loc_2592:
	movea.l  Var_Bitplane2(a6),a3                        ; Load second bitplane memory pointer into pointer a3
	move.w   $17b4(a6),d0                                ; Move $17b4(a6) to register d0
	move.w   -DMACONR(a4),d1                             ; Move DMACON (DMA control write register) to register d1
	lsr.w    #$1,d1
	bra.w    Afs_ToUpper_AsciiOnly_Loc_25A6              ; Unconditional branch to Afs_ToUpper_AsciiOnly_Loc_25A6
Afs_ToUpper_AsciiOnly_Loc_25A4:
	roxr.w   (a3)+
Afs_ToUpper_AsciiOnly_Loc_25A6:
	dbra     d0,Afs_ToUpper_AsciiOnly_Loc_25A4           ; Decrement loop counter d0 and loop back to Afs_ToUpper_AsciiOnly_Loc_25A4 if not exhausted
	dbra     d5,Afs_ToUpper_AsciiOnly_Loc_2514           ; Decrement loop counter d5 and loop back to Afs_ToUpper_AsciiOnly_Loc_2514 if not exhausted
Afs_ToUpper_AsciiOnly_Loc_25AE:
	bsr.w    Disk_MotorOff                               ; Call subroutine to Disk_MotorOff
	bsr.b    ClearDisasmBuffer                           ; Call subroutine to ClearDisasmBuffer
	st.b     d7
	rts                                                  ; Return from subroutine
; ============================================================================
; Function: ClearDisasmBuffer
; Purpose : Clears the disassembler's text output buffer to prepare for formatting the next instruction line. Fills the buffer with spaces.
; ============================================================================
ClearDisasmBuffer:
	lea.l    Var_DisasmBuffer(a6),a0                     ; Load address of disassembler output text buffer into pointer a0
	moveq    #$4f,d0                                     ; Initialize register d0 to constant $4f
; ============================================================================
; Function: ClearDisasmBuffer_Loop
; Purpose : Core loop that writes space characters into the disassembler output buffer.
; ============================================================================
ClearDisasmBuffer_Loop:
	move.b   #$20,(a0)+                                  ; Move constant $20 to (a0)+
	dbra     d0,ClearDisasmBuffer_Loop                   ; Decrement loop counter d0 and loop back to ClearDisasmBuffer_Loop if not exhausted
	rts                                                  ; Return from subroutine
; ============================================================================
; Function: VerifyLoadedChecksum
; Purpose : Computes and verifies the checksum of a loaded track buffer. Compares the computed sum against the stored header checksum to detect read corruption.
; ============================================================================
VerifyLoadedChecksum:
	; After a raw track read into the buffer at MemStart, verify the on-disk checksums match what we just
	; computed. This detects bad reads or intentional protection (bad checksums on some tracks).
	subq.l   #$1,d3                                      ; Subtract 1 from register d3
	bne.b    VerifyChecksum_Exit                         ; Branch to VerifyChecksum_Exit if non-zero / not equal
	move.l   Var_MemStart(a6),d4                         ; Load monitored memory start offset into register d4
	btst     #$0,d4                                      ; Test bit #$0 of register d4
	bne.b    VerifyChecksum_Exit                         ; Branch to VerifyChecksum_Exit if non-zero / not equal
	movea.l  d4,a0                                       ; Move register d4 to pointer a0
	move.l   $1a4(a0),d1                                 ; Move $1a4(a0) to register d1
	cmpi.l   #$1fffff,d1                                 ; Compare register d1 against constant $1fffff
	bhi.b    VerifyChecksum_BadSize
	addq.l   #$1,d1                                      ; Add 1 to register d1
	move.l   d1,d0                                       ; Move register d1 to register d0
	andi.w   #$1fff,d0                                   ; Logical AND register d0 with constant $1fff
	bne.b    VerifyChecksum_BadSize                      ; Branch to VerifyChecksum_BadSize if non-zero / not equal
	subi.l   #$200,d1                                    ; Subtract constant $200 from register d1
	moveq    #$0,d3                                      ; Initialize register d3 to 0
	lea.l    $200(a0),a1                                 ; Load address of $200(a0) into pointer a1
VerifyChecksum_SumLoop:
	add.w    (a1)+,d3                                    ; Add (a1)+ to register d3
	subq.l   #$2,d1                                      ; Subtract constant $2 from register d1
	bne.b    VerifyChecksum_SumLoop                      ; Branch to VerifyChecksum_SumLoop if non-zero / not equal
	move.w   $18e(a0),d2                                 ; Move $18e(a0) to register d2
	move.w   d3,$18e(a0)                                 ; Move register d3 to $18e(a0)
	lea.l    Var_DisasmBuffer+1(a6),a0                   ; Load address of disassembler output text buffer into pointer a0
	lea.l    Str_OldChksum(pc),a1                            ; Load address of Str_OldChksum(pc) into pointer a1
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	move.w   d2,d0                                       ; Move register d2 to register d0
	bsr.w    PrintHex4_Entry                             ; Call subroutine to PrintHex4_Entry
	lea.l    Str_NewChksum(pc),a1                            ; Load address of Str_NewChksum(pc) into pointer a1
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	move.w   d3,d0                                       ; Move register d3 to register d0
	bsr.w    PrintHex4_Entry                             ; Call subroutine to PrintHex4_Entry
	bsr.w    RefreshAndDrawConsoleLine                   ; Call subroutine to RefreshAndDrawConsoleLine
VerifyChecksum_Good:
	st.b     d7
VerifyChecksum_Exit:
	rts                                                  ; Return from subroutine
VerifyChecksum_BadSize:
	lea.l    Str_NoMegadriveRom(pc),a1                            ; Load address of Str_NoMegadriveRom(pc) into pointer a1
	bsr.w    PrintString                                 ; Call subroutine to PrintString
	bra.b    VerifyChecksum_Good                         ; Unconditional branch to VerifyChecksum_Good
VerifyFormat_Exit:
	rts                                                  ; Return from subroutine
; ============================================================================
; Function: VerifyFormatChecksum
; Purpose : Validates the checksum of a track format buffer. Ensures that structural layout, sync words, and sector headers are correct before disk write.
; ============================================================================
VerifyFormatChecksum:
	subq.l   #$1,d3                                      ; Subtract 1 from register d3
	bne.b    VerifyFormat_Exit                           ; Branch to VerifyFormat_Exit if non-zero / not equal
	move.l   Var_MemStart(a6),d0                         ; Load monitored memory start offset into register d0
	btst     #$0,d0                                      ; Test bit #$0 of register d0
	bne.b    VerifyFormat_Exit                           ; Branch to VerifyFormat_Exit if non-zero / not equal
	movea.l  d0,a2                                       ; Move register d0 to pointer a2
	cmpi.w   #$aabb,$8(a2)                               ; Compare $8(a2) against constant $aabb
	bne.b    VerifyFormat_BadHeader                      ; Branch to VerifyFormat_BadHeader if non-zero / not equal
	lea.l    $200(a2),a2                                 ; Load address of $200(a2) into pointer a2
VerifyFormat_BadHeader:
	lea.l    Var_DisasmBuffer+1(a6),a0                   ; Load address of disassembler output text buffer into pointer a0
	lea.l    Str_Name(pc),a1                            ; Load address of Str_Name(pc) into pointer a1
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	lea.l    $7fc0(a2),a3                                ; Load address of $7fc0(a2) into pointer a3
	moveq    #$15,d0                                     ; Initialize register d0 to constant $15
VerifyFormat_PrintHeader:
	move.b   (a3)+,(a0)+                                 ; Move (a3)+ to (a0)+
	dbra     d0,VerifyFormat_PrintHeader                 ; Decrement loop counter d0 and loop back to VerifyFormat_PrintHeader if not exhausted
	addq.w   #$1,a0                                      ; Add 1 to pointer a0
	move.b   (a3)+,d5                                    ; Move (a3)+ to register d5
	moveq    #$0,d1                                      ; Initialize register d1 to 0
	move.b   (a3)+,d1                                    ; Move (a3)+ to register d1
	moveq    #$a,d0                                      ; Initialize register d0 to constant $a
	add.b    d1,d0                                       ; Add register d1 to register d0
	moveq    #$0,d4                                      ; Initialize register d4 to 0
	bset     d0,d4                                       ; Set bit d0 of register d4
	moveq    #$0,d0                                      ; Initialize register d0 to 0
	bset     d1,d0                                       ; Set bit d1 of register d0
	bsr.w    FormatDecimal32Bit                          ; Call subroutine to FormatDecimal32Bit
	lea.l    Str_KbRom(pc),a1                            ; Load address of Str_KbRom(pc) into pointer a1
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	move.b   (a3)+,d1                                    ; Move (a3)+ to register d1
	subq.b   #$1,d5                                      ; Subtract 1 from register d5
	bmi.b    VerifyFormat_Done                           ; Branch to VerifyFormat_Done if negative / minus
	lea.l    Str_Ram(pc),a1                            ; Load address of Str_Ram(pc) into pointer a1
	beq.b    VerifyFormat_PrintSector                    ; Branch to VerifyFormat_PrintSector if zero / equal
	lea.l    Str_BackedUp(pc),a1                            ; Load address of Str_BackedUp(pc) into pointer a1
VerifyFormat_PrintSector:
	moveq    #$0,d0                                      ; Initialize register d0 to 0
	bset     d1,d0                                       ; Set bit d1 of register d0
	bsr.w    FormatDecimal32Bit                          ; Call subroutine to FormatDecimal32Bit
	move.b   #$4b,(a0)+                                  ; Move constant $4b to (a0)+
	move.b   #BLTCON1,(a0)+                              ; Move constant BLTCON1 to (a0)+
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
VerifyFormat_Done:
VerifyFormat_Done_Loc_26B4:
	lea.l    Str_Manufacturer(pc),a1                            ; Load address of Str_Manufacturer(pc) into pointer a1
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	move.b   (a3)+,d0                                    ; Move (a3)+ to register d0
	lsl.w    #$8,d0
	move.b   (a3)+,d0                                    ; Move (a3)+ to register d0
	bsr.w    PrintHex4_Entry                             ; Call subroutine to PrintHex4_Entry
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	move.b   (a3)+,d0                                    ; Move (a3)+ to register d0
	bsr.w    PrintHex2_Entry                             ; Call subroutine to PrintHex2_Entry
	bsr.w    RefreshAndDrawConsoleLine                   ; Call subroutine to RefreshAndDrawConsoleLine
	move.l   (a3),d2                                     ; Move (a3) to register d2
	clr.l    (a3)                                        ; Clear / reset (a3)
	not.w    (a3)
	moveq    #$0,d0                                      ; Initialize register d0 to 0
	moveq    #$0,d1                                      ; Initialize register d1 to 0
	movea.l  a2,a0                                       ; Move pointer a2 to pointer a0
VerifyFormat_Done_Loc_26E0:
	add.b    (a0)+,d0                                    ; Add (a0)+ to register d0
	bcc.b    VerifyFormat_Done_Loc_26E6                  ; Branch to VerifyFormat_Done_Loc_26E6 if carry clear (greater or equal)
	addq.b   #$1,d1                                      ; Add 1 to register d1
VerifyFormat_Done_Loc_26E6:
	subq.l   #$1,d4                                      ; Subtract 1 from register d4
	bne.b    VerifyFormat_Done_Loc_26E0                  ; Branch to VerifyFormat_Done_Loc_26E0 if non-zero / not equal
	lsl.w    #$8,d0
	move.b   d1,d0                                       ; Move register d1 to register d0
	move.w   d0,d3                                       ; Move register d0 to register d3
	not.w    d3
	swap     d3
	move.w   d0,d3                                       ; Move register d0 to register d3
	move.l   d3,(a3)                                     ; Move register d3 to (a3)
	bra.b    VerifyFormat_Done_Loc_2722                  ; Unconditional branch to VerifyFormat_Done_Loc_2722
	lea.l    Disk_ChecksumAndSaveBlock(pc),a2                            ; Load address of Disk_ChecksumAndSaveBlock(pc) into pointer a2
	bra.b    VerifyFormat_Done_Loc_2710                  ; Unconditional branch to VerifyFormat_Done_Loc_2710
	lea.l    Disk_ChecksumAndSaveBootblock(pc),a2                            ; Load address of Disk_ChecksumAndSaveBootblock(pc) into pointer a2
	bra.b    VerifyFormat_Done_Loc_2710                  ; Unconditional branch to VerifyFormat_Done_Loc_2710
	lea.l    Disk_ChecksumAndSaveBitmap(pc),a2                            ; Load address of Disk_ChecksumAndSaveBitmap(pc) into pointer a2
	bra.b    VerifyFormat_Done_Loc_2710                  ; Unconditional branch to VerifyFormat_Done_Loc_2710
	lea.l    Disk_VerifyFormatHeader(pc),a2                            ; Load address of Disk_VerifyFormatHeader(pc) into pointer a2
VerifyFormat_Done_Loc_2710:
	subq.l   #$1,d3                                      ; Subtract 1 from register d3
	bne.b    VerifyFormat_Done_Loc_2748                  ; Branch to VerifyFormat_Done_Loc_2748 if non-zero / not equal
	move.l   Var_MemStart(a6),d4                         ; Load monitored memory start offset into register d4
	btst     #$0,d4                                      ; Test bit #$0 of register d4
	bne.b    VerifyFormat_Done_Loc_2748                  ; Branch to VerifyFormat_Done_Loc_2748 if non-zero / not equal
	movea.l  d4,a0                                       ; Move register d4 to pointer a0
	jsr      (a2)                                        ; Jump to subroutine via pointer (a2)
VerifyFormat_Done_Loc_2722:
	lea.l    Var_DisasmBuffer+1(a6),a0                   ; Load address of disassembler output text buffer into pointer a0
	lea.l    Str_OldChksum(pc),a1                            ; Load address of Str_OldChksum(pc) into pointer a1
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	move.l   d2,d0                                       ; Move register d2 to register d0
	bsr.w    PrintHex8                                   ; Call subroutine to PrintHex8
	lea.l    Str_NewChksum(pc),a1                            ; Load address of Str_NewChksum(pc) into pointer a1
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	move.l   d3,d0                                       ; Move register d3 to register d0
	bsr.w    PrintHex8                                   ; Call subroutine to PrintHex8
	bsr.w    RefreshAndDrawConsoleLine                   ; Call subroutine to RefreshAndDrawConsoleLine
	st.b     d7
VerifyFormat_Done_Loc_2748:
	rts                                                  ; Return from subroutine
; ============================================================================
; Data Block: Disk_ChecksumAndSaveBlock
; Purpose   : Utility subroutine to calculate and write sector block checksum.
; ============================================================================
Disk_ChecksumAndSaveBlock:
	bsr.b    Afs_CalculateBlockChecksum                  ; Call subroutine to Afs_CalculateBlockChecksum
	move.l   d3,$4(a0)                                   ; Move register d3 to $4(a0)
	rts                                                  ; Return from subroutine
; ============================================================================
; Data Block: Disk_ChecksumAndSaveBootblock
; Purpose   : Utility subroutine to calculate and write bootblock checksum.
; ============================================================================
Disk_ChecksumAndSaveBootblock:
	bsr.w    Disk_CalculateBootblockChecksum             ; Call subroutine to Disk_CalculateBootblockChecksum
	move.l   d3,$14(a0)                                  ; Move register d3 to $14(a0)
	rts                                                  ; Return from subroutine
; ============================================================================
; Data Block: Disk_ChecksumAndSaveBitmap
; Purpose   : Utility subroutine to calculate and write bitmap block checksum.
; ============================================================================
Disk_ChecksumAndSaveBitmap:
	move.l   (a0),d2                                     ; Move (a0) to register d2
	bsr.w    Afs_AccumulateBitmapChecksum                                   ; Call subroutine to Afs_AccumulateBitmapChecksum
	move.l   d1,d3                                       ; Move register d1 to register d3
	rts                                                  ; Return from subroutine
; ============================================================================
; Data Block: Disk_VerifyFormatHeader
; Purpose   : Utility subroutine to verify formatting header signature.
; ============================================================================
Disk_VerifyFormatHeader:
	moveq    #-6,d0                                      ; Initialize register d0 to constant -6
	and.w    (a0),d0                                     ; Logical AND register d0 with (a0)
	cmpi.w   #$1110,d0                                   ; Compare register d0 against constant $1110
	bne.b    VerifyFormat_Done_Loc_2782                  ; Branch to VerifyFormat_Done_Loc_2782 if non-zero / not equal
	moveq    #$4,d3                                      ; Initialize register d3 to constant $4
	swap     d3
	cmp.l    -$14(a0,d3.l),d3                            ; Compare register d3 against -$14(a0,d3.l)
	beq.b    VerifyFormat_Done_Loc_278E                  ; Branch to VerifyFormat_Done_Loc_278E if zero / equal
	add.l    d3,d3                                       ; Add register d3 to register d3
	cmp.l    -$14(a0,d3.l),d3                            ; Compare register d3 against -$14(a0,d3.l)
	beq.b    VerifyFormat_Done_Loc_278E                  ; Branch to VerifyFormat_Done_Loc_278E if zero / equal
VerifyFormat_Done_Loc_2782:
	st.b     d7
	addq.w   #$4,a7                                      ; Add constant $4 to stack pointer (a7)
	lea.l    Str_NoKickstart(pc),a1                            ; Load address of Str_NoKickstart(pc) into pointer a1
	bra.w    PrintString                                 ; Unconditional branch to PrintString
VerifyFormat_Done_Loc_278E:
	move.l   -$18(a0,d3.l),d2                            ; Move -$18(a0,d3.l) to register d2
	moveq    #$18,d0                                     ; Initialize register d0 to constant $18
	moveq    #$0,d5                                      ; Initialize register d5 to 0
VerifyFormat_Done_Loc_2796:
	cmp.l    d0,d3                                       ; Compare register d3 against register d0
	beq.b    VerifyFormat_Done_Loc_27A0                  ; Branch to VerifyFormat_Done_Loc_27A0 if zero / equal
	sub.l    (a0),d5                                     ; Subtract (a0) from register d5
	bcc.b    VerifyFormat_Done_Loc_27A0                  ; Branch to VerifyFormat_Done_Loc_27A0 if carry clear (greater or equal)
	subq.l   #$1,d5                                      ; Subtract 1 from register d5
VerifyFormat_Done_Loc_27A0:
	addq.w   #$4,a0                                      ; Add constant $4 to pointer a0
	subq.l   #$4,d3                                      ; Subtract constant $4 from register d3
	bne.b    VerifyFormat_Done_Loc_2796                  ; Branch to VerifyFormat_Done_Loc_2796 if non-zero / not equal
	move.l   d5,d3                                       ; Move register d5 to register d3
	cmp.l    -$18(a0),d3                                 ; Compare register d3 against -$18(a0)
	beq.b    VerifyFormat_Done_Loc_27B2                  ; Branch to VerifyFormat_Done_Loc_27B2 if zero / equal
	move.l   d3,-$18(a0)                                 ; Move register d3 to -$18(a0)
VerifyFormat_Done_Loc_27B2:
	rts                                                  ; Return from subroutine
Afs_CalculateBlockChecksum:
	move.l   a0,-(a7)                                    ; Move pointer a0 to -(a7)
	move.l   (a0)+,d3                                    ; Move (a0)+ to register d3
	move.l   (a0),d2                                     ; Move (a0) to register d2
	clr.l    (a0)+                                       ; Clear / reset (a0)+
	move.w   #$fd,d1                                     ; Move constant $fd to register d1
Afs_CalculateBlockChecksum_Loop:
	add.l    (a0)+,d3                                    ; Add (a0)+ to register d3
	bcc.b    Afs_CalculateBlockChecksum_Next             ; Branch to Afs_CalculateBlockChecksum_Next if carry clear (greater or equal)
	addq.l   #$1,d3                                      ; Add 1 to register d3
Afs_CalculateBlockChecksum_Next:
	dbra     d1,Afs_CalculateBlockChecksum_Loop          ; Decrement loop counter d1 and loop back to Afs_CalculateBlockChecksum_Loop if not exhausted
	not.l    d3
	movea.l  (a7)+,a0                                    ; Move (a7)+ to pointer a0
	rts                                                  ; Return from subroutine
	st.b     $1673(a6)                             ; Set $1673(a6) flag (true).
	bra.b    Afs_CalculateBlockChecksum_Next_Loc_27DA    ; Unconditional branch to Afs_CalculateBlockChecksum_Next_Loc_27DA
	sf.b     $1673(a6)                             ; Clear $1673(a6) flag (false).
Afs_CalculateBlockChecksum_Next_Loc_27DA:
	cmpi.b   #$1,d3                                      ; Compare register d3 against 1
	bls.w    Afs_CalculateBlockChecksum_Next_Loc_2888                              ; Branch to Afs_CalculateBlockChecksum_Next_Loc_2888 if lower or same.
	cmpi.b   #$3,d3                                      ; Compare register d3 against constant $3
	bhi.w    Afs_CalculateBlockChecksum_Next_Loc_2888                              ; Branch to Afs_CalculateBlockChecksum_Next_Loc_2888 if higher.
	move.l   Var_MemStart(a6),d6                         ; Load monitored memory start offset into register d6
	btst     #$0,d6                                      ; Test bit #$0 of register d6
	bne.w    Afs_CalculateBlockChecksum_Next_Loc_2888    ; Branch to Afs_CalculateBlockChecksum_Next_Loc_2888 if non-zero / not equal
	move.l   Var_MemEnd(a6),d5                           ; Load monitored memory end offset into register d5
	moveq    #$1,d4                                      ; Initialize register d4 to 1
	cmpi.b   #$3,d3                                      ; Compare register d3 against constant $3
	bne.b    Afs_CalculateBlockChecksum_Next_Loc_2806    ; Branch to Afs_CalculateBlockChecksum_Next_Loc_2806 if non-zero / not equal
	move.l   Var_TempMemPtr(a6),d4                       ; Load temporary memory workspace pointer into register d4
Afs_CalculateBlockChecksum_Next_Loc_2806:
	move.w   $17c6(a6),d0                                ; Move $17c6(a6) to register d0
	cmpi.b   #$73,(a0)                                   ; Compare (a0) against constant $73
	beq.b    Afs_CalculateBlockChecksum_Next_Loc_2814    ; Branch to Afs_CalculateBlockChecksum_Next_Loc_2814 if zero / equal
	mulu.w   d0,d4
	mulu.w   d0,d5
Afs_CalculateBlockChecksum_Next_Loc_2814:
	moveq    #$53,d3                                     ; Initialize register d3 to constant $53
	mulu.w   d0,d3
	cmp.l    d3,d5                                       ; Compare register d5 against register d3
	bcc.b    Afs_CalculateBlockChecksum_Next_Loc_2888    ; Branch to Afs_CalculateBlockChecksum_Next_Loc_2888 if carry clear (greater or equal)
	add.l    d5,d4                                       ; Add register d5 to register d4
	cmp.l    d3,d4                                       ; Compare register d4 against register d3
	bls.b    Afs_CalculateBlockChecksum_Next_Loc_2824                              ; Branch to Afs_CalculateBlockChecksum_Next_Loc_2824 if lower or same.
	move.l   d3,d4                                       ; Move register d3 to register d4
Afs_CalculateBlockChecksum_Next_Loc_2824:
	bsr.w    Disk_SelectDriveAndMotorOn                  ; Call subroutine to Disk_SelectDriveAndMotorOn
	bsr.w    Disk_StepOut                                ; Call subroutine to Disk_StepOut
	bsr.w    Disk_StepIn                                 ; Call subroutine to Disk_StepIn
	sf.b     $1671(a6)                             ; Clear $1671(a6) flag (false).
	bsr.w    Disk_SeekTrack0                             ; Call subroutine to Disk_SeekTrack0
	tst.b    $1671(a6)                             ; Check if $1671 is set / active
	bne.b    Afs_CalculateBlockChecksum_Next_Loc_2882    ; Branch to Afs_CalculateBlockChecksum_Next_Loc_2882 if non-zero / not equal
	sf.b     Var_MonitorFlag_1670(a6)              ; Clear Var_MonitorFlag_1670(a6) flag (false).
	clr.l    $17f6(a6)                                   ; Clear / reset $17f6(a6)
	move.b   $1673(a6),$1672(a6)                         ; Move $1673(a6) to $1672(a6)
	bsr.w    Disk_CheckWriteProtectAndPresent            ; Call subroutine to Disk_CheckWriteProtectAndPresent
	bne.b    Afs_CalculateBlockChecksum_Next_Loc_2882    ; Branch to Afs_CalculateBlockChecksum_Next_Loc_2882 if non-zero / not equal
Afs_CalculateBlockChecksum_Next_Loc_2852:
	cmp.l    d5,d4                                       ; Compare register d4 against register d5
	bls.b    Afs_CalculateBlockChecksum_Next_Loc_287E                              ; Branch to Afs_CalculateBlockChecksum_Next_Loc_287E if lower or same.
	tst.b    $1673(a6)                             ; Check if $1673 is set / active
	bne.b    Afs_CalculateBlockChecksum_Next_Loc_2862    ; Branch to Afs_CalculateBlockChecksum_Next_Loc_2862 if non-zero / not equal
	bsr.w    Disk_ReadWriteSector                        ; Call subroutine to Disk_ReadWriteSector
	bra.b    Afs_CalculateBlockChecksum_Next_Loc_2866    ; Unconditional branch to Afs_CalculateBlockChecksum_Next_Loc_2866
Afs_CalculateBlockChecksum_Next_Loc_2862:
	bsr.w    Disk_WriteSector                            ; Call subroutine to Disk_WriteSector
Afs_CalculateBlockChecksum_Next_Loc_2866:
	tst.b    $1671(a6)                             ; Check if $1671 is set / active
	bne.b    Afs_CalculateBlockChecksum_Next_Loc_2882    ; Branch to Afs_CalculateBlockChecksum_Next_Loc_2882 if non-zero / not equal
	move.l   d6,d0                                       ; Move register d6 to register d0
	bsr.b    Disk_PrintTrackProgress                     ; Call subroutine to Disk_PrintTrackProgress
	lea.l    $200.w,a0                                   ; Load address of $200.w into pointer a0
	add.l    a0,d6                                       ; Add pointer a0 to register d6
	addq.l   #$1,d5                                      ; Add 1 to register d5
	bsr.w    WaitInputOrButton                           ; Call subroutine to WaitInputOrButton
	bne.b    Afs_CalculateBlockChecksum_Next_Loc_2852    ; Branch to Afs_CalculateBlockChecksum_Next_Loc_2852 if non-zero / not equal
Afs_CalculateBlockChecksum_Next_Loc_287E:
	bsr.w    Disk_FlushTrackWriteBuffer                  ; Call subroutine to Disk_FlushTrackWriteBuffer
Afs_CalculateBlockChecksum_Next_Loc_2882:
	bsr.w    Disk_MotorOff                               ; Call subroutine to Disk_MotorOff
	st.b     d7
Afs_CalculateBlockChecksum_Next_Loc_2888:
	rts                                                  ; Return from subroutine
Disk_PrintTrackProgress:
	move.l   d0,d1                                       ; Move register d0 to register d1
	lea.l    $200.w,a0                                   ; Load address of $200.w into pointer a0
	add.l    a0,d1                                       ; Add pointer a0 to register d1
	lea.l    Var_DisasmBuffer+1(a6),a0                   ; Load address of disassembler output text buffer into pointer a0
	bsr.w    FormatAddressRange8                         ; Call subroutine to FormatAddressRange8
	bsr.b    FormatTrackSidePrefix                       ; Call subroutine to FormatTrackSidePrefix
	lea.l    Str_Block(pc),a1                            ; Load address of Str_Block(pc) into pointer a1
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	move.w   d5,d0                                       ; Move register d5 to register d0
	bsr.w    PrintHex4_Entry                             ; Call subroutine to PrintHex4_Entry
	move.b   #$3d,(a0)+                                  ; Move constant $3d to (a0)+
	bsr.w    FormatDecimal3Digit                         ; Call subroutine to FormatDecimal3Digit
	bra.w    RefreshAndDrawConsoleLine                   ; Unconditional branch to RefreshAndDrawConsoleLine
FormatTrackSidePrefix:
	lea.l    Str_Track(pc),a1                            ; Load address of Str_Track(pc) into pointer a1
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	move.b   $166d(a6),d0                                ; Move $166d(a6) to register d0
	lsr.b    #$1,d0
	bsr.w    FormatDecimal2Digit                         ; Call subroutine to FormatDecimal2Digit
	lea.l    -$20a0(a6),a1                               ; Load address of -$20a0(a6) into pointer a1
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	move.b   $166d(a6),d0                                ; Move $166d(a6) to register d0
	andi.b   #$1,d0                                      ; Logical AND register d0 with 1
	addi.b   #$30,d0                                     ; Add constant $30 to register d0
	move.b   d0,(a0)+                                    ; Move register d0 to (a0)+
	lea.l    Str_Sector(pc),a1                            ; Load address of Str_Sector(pc) into pointer a1
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	move.b   $166e(a6),d0                                ; Move $166e(a6) to register d0
	bra.w    FormatDecimal2Digit                         ; Unconditional branch to FormatDecimal2Digit
Disk_CalculateTrackSector:
	move.l   d5,d0                                       ; Move register d5 to register d0
	divu.w   $17c2(a6),d0                          ; Divide d0 by $17c2(a6).
	move.b   d0,d1                                       ; Move register d0 to register d1
	cmp.b    $166d(a6),d1                                ; Compare register d1 against $166d(a6)
	beq.b    Disk_CalculateTrackSector_Done              ; Branch to Disk_CalculateTrackSector_Done if zero / equal
	sf.b     Var_MonitorFlag_1670(a6)              ; Clear Var_MonitorFlag_1670(a6) flag (false).
Disk_CalculateTrackSector_Done:
	swap     d0
	move.b   d0,$166e(a6)                                ; Move register d0 to $166e(a6)
	rts                                                  ; Return from subroutine
Disk_CheckWriteProtectAndPresent:
	btst     #$2,CIAA_PRA.l                              ; Test bit #$2 of CIAA_PRA (CIA-A Port A status register)
	bne.b    Disk_CheckWriteProtectAndPresent_NotProtected	; Branch to Disk_CheckWriteProtectAndPresent_NotProtected if non-zero / not equal
	lea.l    Str_NotPresent(pc),a1                            ; Load address of Str_NotPresent(pc) into pointer a1
Disk_CheckWriteProtectAndPresent_Error:
	lea.l    Var_DisasmBuffer(a6),a0                     ; Load address of disassembler output text buffer into pointer a0
	bsr.w    Print_LoadingPrefix                         ; Call subroutine to Print_LoadingPrefix
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	bsr.w    RefreshAndDrawConsoleLine                   ; Call subroutine to RefreshAndDrawConsoleLine
	moveq    #-1,d0                                      ; Initialize register d0 to constant -1
	rts                                                  ; Return from subroutine
Disk_CheckWriteProtectAndPresent_NotProtected:
	tst.b    $1672(a6)                             ; Check if $1672 is set / active
	beq.b    Disk_CheckWriteProtectAndPresent_Success    ; Branch to Disk_CheckWriteProtectAndPresent_Success if zero / equal
	lea.l    Str_WriteProtected(pc),a1                            ; Load address of Str_WriteProtected(pc) into pointer a1
	btst     #$3,CIAA_PRA.l                              ; Test bit #$3 of CIAA_PRA (CIA-A Port A status register)
	beq.b    Disk_CheckWriteProtectAndPresent_Error      ; Branch to Disk_CheckWriteProtectAndPresent_Error if zero / equal
Disk_CheckWriteProtectAndPresent_Success:
	moveq    #$0,d0                                      ; Initialize register d0 to 0
	rts                                                  ; Return from subroutine
Disk_ReadAndValidateBootblock:
	lea.l    $3294(a6),a0                                ; Load address of $3294(a6) into pointer a0
	move.l   a0,d6                                       ; Move pointer a0 to register d6
	moveq    #$0,d5                                      ; Initialize register d5 to 0
	bsr.w    Disk_ReadWriteSector                        ; Call subroutine to Disk_ReadWriteSector
	tst.b    $1671(a6)                             ; Check if $1671 is set / active
	bne.b    Disk_ReadAndValidateBootblock_Error         ; Branch to Disk_ReadAndValidateBootblock_Error if non-zero / not equal
	move.l   $3294(a6),d0                                ; Move $3294(a6) to register d0
	move.w   #$1e8,d5                                    ; Move constant $1e8 to register d5
	bclr     #$0,d0                                      ; Clear bit #$0 of register d0
	sne.b    $1676(a6)                             ; Execute sne.b instruction
	beq.b    Disk_ReadAndValidateBootblock_Loc_296A      ; Branch to Disk_ReadAndValidateBootblock_Loc_296A if zero / equal
	move.w   #$200,d5                                    ; Move constant $200 to register d5
Disk_ReadAndValidateBootblock_Loc_296A:
	bclr     #$1,d0                                      ; Clear bit #$1 of register d0
	sne.b    $1677(a6)                             ; Execute sne.b instruction
	cmp.l    $17ea(a6),d0                                ; Compare register d0 against $17ea(a6)
	beq.b    Disk_ReadAndValidateBootblock_Verify        ; Branch to Disk_ReadAndValidateBootblock_Verify if zero / equal
Disk_ReadAndValidateBootblock_Invalid:
	lea.l    Str_NotDosDisk(pc),a1                            ; Load address of Str_NotDosDisk(pc) into pointer a1
Disk_ReadAndValidateBootblock_Print:
	lea.l    Var_DisasmBuffer(a6),a0                     ; Load address of disassembler output text buffer into pointer a0
	bsr.w    Print_LoadingPrefix                         ; Call subroutine to Print_LoadingPrefix
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	bsr.w    RefreshAndDrawConsoleLine                   ; Call subroutine to RefreshAndDrawConsoleLine
Disk_ReadAndValidateBootblock_Error:
	moveq    #-1,d0                                      ; Initialize register d0 to constant -1
	rts                                                  ; Return from subroutine
Disk_ReadAndValidateBootblock_Verify:
	move.w   d5,$17e4(a6)                                ; Move register d5 to $17e4(a6)
	move.l   $17b6(a6),d5                                ; Move $17b6(a6) to register d5
	bsr.w    Disk_ReadWriteSector                        ; Call subroutine to Disk_ReadWriteSector
	tst.b    $1671(a6)                             ; Check if $1671 is set / active
	bne.b    Disk_ReadAndValidateBootblock_Error         ; Branch to Disk_ReadAndValidateBootblock_Error if non-zero / not equal
	move.b   $33cf(a6),$1678(a6)                         ; Move $33cf(a6) to $1678(a6)
	movea.l  d6,a0                                       ; Move register d6 to pointer a0
	bsr.b    Disk_CalculateBootblockChecksum             ; Call subroutine to Disk_CalculateBootblockChecksum
	cmp.l    d3,d2                                       ; Compare register d2 against register d3
	lea.l    Str_BadChecksum(pc),a1                            ; Load address of Str_BadChecksum(pc) into pointer a1
	bne.w    Disk_ReadAndValidateBootblock_Print         ; Branch to Disk_ReadAndValidateBootblock_Print if non-zero / not equal
	cmp.l    $17f2(a6),d2                                ; Compare register d2 against $17f2(a6)
	beq.b    Disk_ReadAndValidateBootblock_CheckFmode    ; Branch to Disk_ReadAndValidateBootblock_CheckFmode if zero / equal
	move.l   d2,$17f2(a6)                                ; Move register d2 to $17f2(a6)
	move.l   $17b6(a6),$17d2(a6)                         ; Move $17b6(a6) to $17d2(a6)
Disk_ReadAndValidateBootblock_CheckFmode:
	tst.b    $1673(a6)                             ; Check if $1673 is set / active
	beq.b    Disk_ReadAndValidateBootblock_CheckOffset   ; Branch to Disk_ReadAndValidateBootblock_CheckOffset if zero / equal
	tst.l    $138(a0)                              ; Check if $138(a0) is set / active
	lea.l    Str_NotValidated(pc),a1                            ; Load address of Str_NotValidated(pc) into pointer a1
	beq.b    Disk_ReadAndValidateBootblock_Print         ; Branch to Disk_ReadAndValidateBootblock_Print if zero / equal
Disk_ReadAndValidateBootblock_CheckOffset:
	move.l   $13c(a0),d5                                 ; Move $13c(a0) to register d5
	move.l   d5,$17ca(a6)                                ; Move register d5 to $17ca(a6)
	lea.l    $3694(a6),a1                                ; Load address of $3694(a6) into pointer a1
	move.l   a1,d6                                       ; Move pointer a1 to register d6
	bsr.w    Disk_ReadWriteSector                        ; Call subroutine to Disk_ReadWriteSector
	tst.b    $1671(a6)                             ; Check if $1671 is set / active
	bne.b    Disk_ReadAndValidateBootblock_Error         ; Branch to Disk_ReadAndValidateBootblock_Error if non-zero / not equal
	moveq    #$0,d0                                      ; Initialize register d0 to 0
	rts                                                  ; Return from subroutine
Disk_CalculateBootblockChecksum:
	move.l   a0,-(a7)                                    ; Move pointer a0 to -(a7)
	moveq    #$7f,d1                                     ; Initialize register d1 to constant $7f
	move.l   $14(a0),d2                                  ; Move $14(a0) to register d2
	clr.l    $14(a0)                                     ; Clear / reset $14(a0)
	moveq    #$0,d3                                      ; Initialize register d3 to 0
Disk_CalculateBootblockChecksum_Loop:
	sub.l    (a0)+,d3                                    ; Subtract (a0)+ from register d3
	dbra     d1,Disk_CalculateBootblockChecksum_Loop     ; Decrement loop counter d1 and loop back to Disk_CalculateBootblockChecksum_Loop if not exhausted
	movea.l  (a7)+,a0                                    ; Move (a7)+ to pointer a0
	rts                                                  ; Return from subroutine
Disk_WriteSector:
	movem.l  d0-d7/a0-a6,-(a7)                           ; Move multiple registers d0-d7/a0-a6 to -(a7)
	sf.b     $1671(a6)                             ; Clear $1671(a6) flag (false).
	st.b     $1672(a6)                             ; Set $1672(a6) flag (true).
	move.l   d5,d0                                       ; Move register d5 to register d0
	divu.w   $17c2(a6),d0                          ; Divide d0 by $17c2(a6).
	cmp.b    $166d(a6),d0                                ; Compare register d0 against $166d(a6)
	beq.b    Disk_WriteSector_MarkDirty                  ; Branch to Disk_WriteSector_MarkDirty if zero / equal
	tst.l    $17f6(a6)                             ; Check if $17f6 is set / active
	beq.b    Disk_WriteSector_MarkDirty                  ; Branch to Disk_WriteSector_MarkDirty if zero / equal
	bsr.w    Disk_FlushTrackWriteBuffer                  ; Call subroutine to Disk_FlushTrackWriteBuffer
	clr.l    $17f6(a6)                                   ; Clear / reset $17f6(a6)
Disk_WriteSector_MarkDirty:
	movea.l  d6,a0                                       ; Move register d6 to pointer a0
	move.l   d5,d4                                       ; Move register d5 to register d4
	divu.w   $17c2(a6),d4                          ; Divide d4 by $17c2(a6).
	swap     d4
	move.l   $17f6(a6),d0                                ; Move $17f6(a6) to register d0
	bset     d4,d0                                       ; Set bit d4 of register d0
	move.l   d0,$17f6(a6)                                ; Move register d0 to $17f6(a6)
	move.w   #$200,d0                                    ; Move constant $200 to register d0
	mulu.w   d4,d0
	lea.l    Var_FontData(a6),a1                         ; Load address of font glyph data pointer into pointer a1
	adda.l   d0,a1                                       ; Add register d0 to pointer a1
	moveq    #$7f,d0                                     ; Initialize register d0 to constant $7f
Disk_WriteSector_MarkDirty_Loc_2A52:
	move.l   (a0)+,(a1)+                                 ; Copy word/byte data from source pointer a0 to destination a1
	dbra     d0,Disk_WriteSector_MarkDirty_Loc_2A52      ; Decrement loop counter d0 and loop back to Disk_WriteSector_MarkDirty_Loc_2A52 if not exhausted
	bsr.w    Disk_CalculateTrackSector                   ; Call subroutine to Disk_CalculateTrackSector
	bsr.w    Disk_SeekTrack                              ; Call subroutine to Disk_SeekTrack
	movem.l  (a7)+,d0-d7/a0-a6                           ; Move multiple registers (a7)+ to d0-d7/a0-a6
	rts                                                  ; Return from subroutine
Disk_FlushTrackWriteBuffer:
	movem.l  d0-d7/a0-a6,-(a7)                           ; Move multiple registers d0-d7/a0-a6 to -(a7)
	st.b     $1672(a6)                             ; Set $1672(a6) flag (true).
	sf.b     Var_MonitorFlag_1670(a6)              ; Clear Var_MonitorFlag_1670(a6) flag (false).
	sf.b     $1671(a6)                             ; Clear $1671(a6) flag (false).
	tst.l    $17f6(a6)                             ; Check if $17f6 is set / active
	beq.b    Disk_FlushTrackWriteBuffer_Exit             ; Branch to Disk_FlushTrackWriteBuffer_Exit if zero / equal
	lea.l    Var_FontData(a6),a1                         ; Load address of font glyph data pointer into pointer a1
	move.l   a1,d6                                       ; Move pointer a1 to register d6
	moveq    #$0,d5                                      ; Initialize register d5 to 0
	move.b   $166d(a6),d5                                ; Move $166d(a6) to register d5
	mulu.w   $17c2(a6),d5                          ; Multiply d5 by $17c2(a6).
	moveq    #$0,d4                                      ; Initialize register d4 to 0
Disk_FlushTrackWriteBuffer_Loop:
	bsr.w    Disk_CalculateTrackSector                   ; Call subroutine to Disk_CalculateTrackSector
	bsr.w    Disk_SeekTrack                              ; Call subroutine to Disk_SeekTrack
	tst.b    $1671(a6)                             ; Check if $1671 is set / active
	bne.b    Disk_FlushTrackWriteBuffer_Exit             ; Branch to Disk_FlushTrackWriteBuffer_Exit if non-zero / not equal
	move.l   $17f6(a6),d0                                ; Move $17f6(a6) to register d0
	btst     d4,d0                                       ; Test bit d4 of register d0
	bne.b    Disk_FlushTrackWriteBuffer_Next             ; Branch to Disk_FlushTrackWriteBuffer_Next if non-zero / not equal
	bsr.w    VerifySectorWithRetry                       ; Call subroutine to VerifySectorWithRetry
	tst.b    $1671(a6)                             ; Check if $1671 is set / active
	bne.b    Disk_FlushTrackWriteBuffer_Exit             ; Branch to Disk_FlushTrackWriteBuffer_Exit if non-zero / not equal
Disk_FlushTrackWriteBuffer_Next:
	addq.l   #$1,d5                                      ; Add 1 to register d5
	lea.l    $200.w,a1                                   ; Load address of $200.w into pointer a1
	add.l    a1,d6                                       ; Add pointer a1 to register d6
	addq.w   #$1,d4                                      ; Add 1 to register d4
	cmp.w    $17c2(a6),d4                                ; Compare register d4 against $17c2(a6)
	bne.b    Disk_FlushTrackWriteBuffer_Loop             ; Branch to Disk_FlushTrackWriteBuffer_Loop if non-zero / not equal
	bsr.w    FormatTrackCopier                           ; Call subroutine to FormatTrackCopier
	bsr.w    Disk_DelayStep                              ; Call subroutine to Disk_DelayStep
Disk_FlushTrackWriteBuffer_Exit:
	movem.l  (a7)+,d0-d7/a0-a6                           ; Move multiple registers (a7)+ to d0-d7/a0-a6
	rts                                                  ; Return from subroutine
Disk_ReadWriteSector:
	tst.l    $17f6(a6)                             ; Check if $17f6 is set / active
	beq.b    Disk_ReadWriteSector_Seek                   ; Branch to Disk_ReadWriteSector_Seek if zero / equal
	bsr.w    Disk_FlushTrackWriteBuffer                  ; Call subroutine to Disk_FlushTrackWriteBuffer
	clr.l    $17f6(a6)                                   ; Clear / reset $17f6(a6)
Disk_ReadWriteSector_Seek:
	sf.b     $1672(a6)                             ; Clear $1672(a6) flag (false).
	bsr.w    Disk_CalculateTrackSector                   ; Call subroutine to Disk_CalculateTrackSector
	bsr.w    Disk_SeekTrack                              ; Call subroutine to Disk_SeekTrack
	tst.b    $1671(a6)                             ; Check if $1671 is set / active
	beq.b    VerifySectorWithRetry                       ; Branch to VerifySectorWithRetry if zero / equal
	rts                                                  ; Return from subroutine
VerifyDiskSector_VerifyOnly:
	movem.l  d0-d7/a0-a3,-(a7)                           ; Move multiple registers d0-d7/a0-a3 to -(a7)
	moveq    #$1,d5                                      ; Initialize register d5 to 1
	ror.l    #$1,d5
	bra.b    VerifyDiskSector_Start                      ; Unconditional branch to VerifyDiskSector_Start
VerifySectorWithRetry:
	cmpi.b   #$1e,$1671(a6)                              ; Compare $1671(a6) against constant $1e
	bne.b    VerifySectorWithRetry_Start                 ; Branch to VerifySectorWithRetry_Start if non-zero / not equal
	movem.l  d0-d3/a1,-(a7)                              ; Move multiple registers d0-d3/a1 to -(a7)
	move.b   $166d(a6),d3                                ; Move $166d(a6) to register d3
	sf.b     $1671(a6)                             ; Clear $1671(a6) flag (false).
	bsr.w    Disk_SeekTrack0                             ; Call subroutine to Disk_SeekTrack0
	move.b   d3,d1                                       ; Move register d3 to register d1
	bsr.w    Disk_SeekTrack                              ; Call subroutine to Disk_SeekTrack
	movem.l  (a7)+,d0-d3/a1                              ; Move multiple registers (a7)+ to d0-d3/a1
VerifySectorWithRetry_Start:
	bsr.w    VerifyDiskSector                            ; Call subroutine to VerifyDiskSector
	tst.b    $1671(a6)                             ; Check if $1671 is set / active
	beq.b    VerifyDiskSector_Rts                        ; Branch to VerifyDiskSector_Rts if zero / equal
	movem.l  d0/a0-a1,-(a7)                              ; Move multiple registers d0/a0-a1 to -(a7)
	lea.l    -$1d2e(a6),a1                               ; Load address of -$1d2e(a6) into pointer a1
	lea.l    Var_DisasmBuffer+1(a6),a0                   ; Load address of disassembler output text buffer into pointer a0
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	move.b   $1671(a6),d0                                ; Move $1671(a6) to register d0
	bsr.w    FormatDecimal2Digit                         ; Call subroutine to FormatDecimal2Digit
	move.b   #$29,(a0)+                                  ; Move constant $29 to (a0)+
	bsr.w    FormatTrackSidePrefix                       ; Call subroutine to FormatTrackSidePrefix
	addq.w   #$8,a0                                      ; Add constant $8 to pointer a0
	lea.l    Str_RetryIgnoreAbort(pc),a1                            ; Load address of Str_RetryIgnoreAbort(pc) into pointer a1
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	bsr.w    RefreshAndDrawConsoleLine                   ; Call subroutine to RefreshAndDrawConsoleLine
	movem.l  (a7)+,d0/a0-a1                              ; Move multiple registers (a7)+ to d0/a0-a1
	bsr.w    WaitForAbortOrKeyDuringDisk                 ; Call subroutine to WaitForAbortOrKeyDuringDisk
	beq.b    VerifySectorWithRetry                       ; Branch to VerifySectorWithRetry if zero / equal
	bpl.b    VerifyDiskSector_Rts                        ; Branch to VerifyDiskSector_Rts if positive / plus
	sf.b     $1671(a6)                             ; Clear $1671(a6) flag (false).
VerifyDiskSector_Rts:
	rts                                                  ; Return from subroutine
VerifyDiskSector:
	movem.l  d0-d7/a0-a3,-(a7)                           ; Move multiple registers d0-d7/a0-a3 to -(a7)
	moveq    #$3,d5                                      ; Initialize register d5 to constant $3
VerifyDiskSector_Start:
	move.l   $17aa(a6),d7                                ; Move $17aa(a6) to register d7
VerifyDiskSector_Loop:
	tst.b    $1670(a6)                             ; Check if $1670 is set / active
	bne.b    VerifySector_SkipWrite                      ; Branch to VerifySector_SkipWrite if non-zero / not equal
	bsr.w    DiskDma_VerifyWrite                         ; Call subroutine to DiskDma_VerifyWrite
	tst.b    $1670(a6)                             ; Check if $1670 is set / active
	beq.w    VerifySector_Exit                           ; Branch to VerifySector_Exit if zero / equal
VerifySector_SkipWrite:
	movea.l  Var_Bitplane2(a6),a2                        ; Load second bitplane memory pointer into pointer a2
	movea.w  $17b4(a6),a3                                ; Move $17b4(a6) to pointer a3
	adda.w   a3,a3                                       ; Add pointer a3 to pointer a3
	adda.l   a2,a3                                       ; Add pointer a2 to pointer a3
	move.w   $17c4(a6),d2                                ; Move $17c4(a6) to register d2
VerifySector_ScanLoop:
	move.w   $17b2(a6),d0                                ; Move $17b2(a6) to register d0
	cmpa.l   a3,a2                                       ; Compare pointer a2 against pointer a3
	bhi.w    VerifySector_ErrorSectorNotFound      ; Branch to error if not found in buffer
	cmp.w    (a2)+,d0                                    ; Compare register d0 against (a2)+
	bne.b    VerifySector_ScanLoop                       ; Branch to VerifySector_ScanLoop if non-zero / not equal
	cmp.w    (a2),d0                                     ; Compare register d0 against (a2)
	beq.b    VerifySector_ScanLoop                       ; Branch to VerifySector_ScanLoop if zero / equal
	bsr.w    DecodeMfmLongword                           ; Call subroutine to DecodeMfmLongword
	move.l   d0,d1                                       ; Move register d0 to register d1
	move.l   d0,d4                                       ; Move register d0 to register d4
	rol.l    #$8,d1
	not.b    d1
	beq.b    VerifySector_CylinderCheck                  ; Branch to VerifySector_CylinderCheck if zero / equal
	sf.b     $1670(a6)                             ; Set status to error
	move.b   #$17,$1671(a6)                              ; Move constant $17 to $1671(a6)
VerifySector_CylinderCheck:
	rol.l    #$8,d1
	cmp.b    $166d(a6),d1                                ; Compare register d1 against $166d(a6)
	dc.b     $67                                   ; opcode for beq.s (VerifySector_SectorCheck)
; ============================================================================
; Data Block: SectorVerify_BranchOffset
; Purpose   : Relative branch offset byte for sector check conditional branch.
; ============================================================================
SectorVerify_BranchOffset:
	dc.b     VerifySector_SectorCheck-*-1          ; displacement to VerifySector_SectorCheck at odd address 0x2bc1
	sf.b     $1670(a6)                             ; Set status to error
	move.b   #$1e,$1671(a6)                              ; Move constant $1e to $1671(a6)
VerifySector_SectorCheck:
	lsr.w    #$8,d0
	cmp.b    $166e(a6),d0                                ; Compare register d0 against $166e(a6)
	beq.b    VerifySector_HeaderChecksum                 ; Branch to VerifySector_HeaderChecksum if zero / equal
	lea.l    $434(a2),a2                                 ; Load address of $434(a2) into pointer a2
	bra.b    VerifySector_NextSector                     ; Unconditional branch to VerifySector_NextSector
VerifySector_HeaderChecksum:
	subq.w   #$8,a2                                      ; Subtract constant $8 from pointer a2
	moveq    #$0,d4                                      ; Initialize register d4 to 0
	moveq    #$9,d3                                      ; Initialize register d3 to constant $9
VerifySector_HeaderCheckLoop:
	move.l   (a2)+,d0                                    ; Move (a2)+ to register d0
	and.l    d7,d0                                       ; Logical AND register d0 with register d7
	eor.l    d0,d4                                       ; Logical XOR register d4 with register d0
	dbra     d3,VerifySector_HeaderCheckLoop             ; Decrement loop counter d3 and loop back to VerifySector_HeaderCheckLoop if not exhausted
	bsr.b    DecodeMfmLongword                           ; Call subroutine to DecodeMfmLongword
	cmp.l    d0,d4                                       ; Compare register d4 against register d0
	beq.b    VerifySector_DataChecksum                   ; Branch to VerifySector_DataChecksum if zero / equal
	sf.b     $1670(a6)                             ; Set status to error
	move.b   #$18,$1671(a6)                              ; Move constant $18 to $1671(a6)
VerifySector_DataChecksum:
	bsr.b    DecodeMfmLongword                           ; Call subroutine to DecodeMfmLongword
	move.l   d0,-(a7)                                    ; Move register d0 to -(a7)
	movea.l  d6,a0                                       ; Move register d6 to pointer a0
	moveq    #$7f,d3                                     ; Initialize register d3 to constant $7f
	moveq    #$0,d4                                      ; Initialize register d4 to 0
	lea.l    $200(a2),a1                                 ; Load address of $200(a2) into pointer a1
VerifySector_DataCheckLoop:
	tst.l    d5                                          ; Test status of register d5 (for zero or negative)
	bpl.b    VerifySector_WriteMode                      ; Branch to VerifySector_WriteMode if positive / plus
	tst.l    (a7)+                                       ; Test status of (a7)+ (for zero or negative)
VerifySector_DataCheckLoop_Start:
	move.l   (a1)+,d1                                    ; Move (a1)+ to register d1
	eor.l    d1,d4                                       ; Logical XOR register d4 with register d1
	and.l    d7,d1                                       ; Logical AND register d1 with register d7
	move.l   (a2)+,d0                                    ; Move (a2)+ to register d0
	eor.l    d0,d4                                       ; Logical XOR register d4 with register d0
	and.l    d7,d0                                       ; Logical AND register d0 with register d7
	add.l    d0,d0                                       ; Add register d0 to register d0
	or.l     d1,d0                                       ; Logical OR register d0 with register d1
	cmp.l    (a0)+,d0                                    ; Compare register d0 against (a0)+
	dbne     d3,VerifySector_DataCheckLoop_Start   ; Repeat until mismatch or 128 longwords
	beq.b    VerifySector_Exit                           ; Branch to VerifySector_Exit if zero / equal
	move.b   #$14,$1671(a6)                              ; Move constant $14 to $1671(a6)
	bra.b    VerifySector_FailExit                       ; Unconditional branch to VerifySector_FailExit
VerifySector_WriteMode:
	move.l   (a1)+,d1                                    ; Move (a1)+ to register d1
	eor.l    d1,d4                                       ; Logical XOR register d4 with register d1
	and.l    d7,d1                                       ; Logical AND register d1 with register d7
	move.l   (a2)+,d0                                    ; Move (a2)+ to register d0
	eor.l    d0,d4                                       ; Logical XOR register d4 with register d0
	and.l    d7,d0                                       ; Logical AND register d0 with register d7
	add.l    d0,d0                                       ; Add register d0 to register d0
	or.l     d1,d0                                       ; Logical OR register d0 with register d1
	move.l   d0,(a0)+                                    ; Move register d0 to (a0)+
	dbra     d3,VerifySector_WriteMode                   ; Decrement loop counter d3 and loop back to VerifySector_WriteMode if not exhausted
	and.l    d7,d4                                       ; Logical AND register d4 with register d7
	cmp.l    (a7)+,d4                                    ; Compare register d4 against (a7)+
	beq.b    VerifySector_Exit                           ; Branch to VerifySector_Exit if zero / equal
	move.b   #$19,$1671(a6)                              ; Move constant $19 to $1671(a6)
	bra.b    VerifySector_FailExit                       ; Unconditional branch to VerifySector_FailExit
VerifySector_NextSector:
	dbra     d2,VerifySector_ScanLoop                    ; Decrement loop counter d2 and loop back to VerifySector_ScanLoop if not exhausted
VerifySector_ErrorSectorNotFound:
	move.b   #$15,$1671(a6)                              ; Move constant $15 to $1671(a6)
VerifySector_FailExit:
	sf.b     $1670(a6)                             ; Clear active flag (operation complete)
	dbra     d5,VerifyDiskSector_Loop                    ; Decrement loop counter d5 and loop back to VerifyDiskSector_Loop if not exhausted
VerifySector_Exit:
	movem.l  (a7)+,d0-d7/a0-a3                           ; Move multiple registers (a7)+ to d0-d7/a0-a3
	rts                                                  ; Return from subroutine

; ============================================================================
; Function: DecodeMfmLongword
; Purpose : Decodes a single split MFM longword into standard data by masking
;           out clock bits and combining even and odd bits.
; Inputs  : a2 = even bits pointer
; Outputs : d0 = decoded longword
; Clobbers: d0-d1, a2
; ============================================================================
DecodeMfmLongword:
	movem.l  (a2)+,d0-d1                                 ; Move multiple registers (a2)+ to d0-d1
	and.l    d7,d0                                       ; Logical AND register d0 with register d7
	add.l    d0,d0                                       ; Add register d0 to register d0
	and.l    d7,d1                                       ; Logical AND register d1 with register d7
	or.l     d1,d0                                       ; Logical OR register d0 with register d1
	rts                                                  ; Return from subroutine
; ============================================================================
; Function: WriteTrack
; Purpose : Writes a raw track buffer to disk. Takes over Paula disk control registers, turns on the disk drive motor, steps to the correct cylinder/side, and writes the nibblized MFM data stream.
; ============================================================================
WriteTrack:
	; This is the low-level raw track writer. It prepares a full MFM-encoded track image in the monitor's
	; bitplane buffer (re-used as temp storage), then calls the low-level disk DMA starter (Loc_2E42 path).
	; Used by FormatTrackCopier for 'f' format and raw track copy/install tools. No DOS, direct Paula disk DMA.
	movem.l  d0-d7/a0-a4,-(a7)                           ; Move multiple registers d0-d7/a0-a4 to -(a7)
	movea.l  Var_Bitplane2(a6),a1                        ; Load second bitplane memory pointer into pointer a1
	move.w   #$440,d0                                    ; Move constant $440 to register d0
	mulu.w   $17c2(a6),d0                          ; Track size calculation (sectors * bytes + headers)
	addq.w   #$4,d0                                      ; Add constant $4 to register d0
	neg.w    d0
	add.w    $17b4(a6),d0                                ; Add $17b4(a6) to register d0
	add.w    $17b4(a6),d0                                ; Add $17b4(a6) to register d0
	lsr.w    #$2,d0
	move.l   $17ae(a6),d1                                ; Move $17ae(a6) to register d1
	bra.b    WriteTrack_FillBuffer                       ; Unconditional branch to WriteTrack_FillBuffer
WriteTrack_FillBufferLoop:
	move.l   d1,(a1)+                                    ; Move register d1 to (a1)+
WriteTrack_FillBuffer:
	dbra     d0,WriteTrack_FillBufferLoop                ; Decrement loop counter d0 and loop back to WriteTrack_FillBufferLoop if not exhausted
	clr.b    d1                                          ; Clear / reset register d1
	move.w   $17c4(a6),d3                                ; Move $17c4(a6) to register d3
	move.w   $17c2(a6),d2                                ; Move $17c2(a6) to register d2
WriteTrack_SectorLoop:
	; Write the Amiga MFM track header (sync, $ff, track, sector, eor, checksum etc.)
	move.l   $17ae(a6),(a1)+                             ; Move $17ae(a6) to (a1)+
	move.w   $17b2(a6),(a1)+                             ; Move $17b2(a6) to (a1)+
	move.w   $17b2(a6),(a1)+                             ; Move $17b2(a6) to (a1)+
	moveq    #-1,d7                                      ; Initialize register d7 to constant -1
	move.b   $166d(a6),d7                                ; Move $166d(a6) to register d7
	lsl.l    #$8,d7
	move.b   d1,d7                                       ; Move register d1 to register d7
	lsl.l    #$8,d7
	move.b   d2,d7                                       ; Move register d2 to register d7
	movea.l  a1,a2                                       ; Move pointer a1 to pointer a2
	bsr.b    FormatNibbleByte                            ; Call subroutine to FormatNibbleByte
	move.l   d6,(a1)+                                    ; Move register d6 to (a1)+
	move.l   d7,(a1)+                                    ; Move register d7 to (a1)+
	moveq    #$1,d5                                      ; Initialize register d5 to 1
	bsr.w    FormatTrackSector                           ; Call subroutine to FormatTrackSector
	eor.l    d6,d7                                       ; Logical XOR register d7 with register d6
	movea.l  a1,a2                                       ; Move pointer a1 to pointer a2
	; Clear space for the data checksum area (8 longwords? typical Amiga sector layout)
	clr.l    (a1)+                                       ; Clear / reset (a1)+
	clr.l    (a1)+                                       ; Clear / reset (a1)+
	clr.l    (a1)+                                       ; Clear / reset (a1)+
	clr.l    (a1)+                                       ; Clear / reset (a1)+
	clr.l    (a1)+                                       ; Clear / reset (a1)+
	clr.l    (a1)+                                       ; Clear / reset (a1)+
	clr.l    (a1)+                                       ; Clear / reset (a1)+
	clr.l    (a1)+                                       ; Clear / reset (a1)+
	bsr.b    FormatNibbleByte                            ; Call subroutine to FormatNibbleByte
	move.l   d6,(a1)+                                    ; Move register d6 to (a1)+
	move.l   d7,(a1)+                                    ; Move register d7 to (a1)+
	moveq    #$5,d5                                      ; Initialize register d5 to constant $5
	bsr.b    FormatTrackSector                           ; Call subroutine to FormatTrackSector
	movea.l  a1,a3                                       ; Move pointer a1 to pointer a3
	addq.w   #$8,a1                                      ; Add constant $8 to pointer a1
	movea.l  a1,a4                                       ; Move pointer a1 to pointer a4
	lea.l    $200(a1),a2                                 ; Load address of $200(a1) into pointer a2
	move.l   $17aa(a6),d0                                ; Move $17aa(a6) to register d0
	moveq    #$7f,d5                                     ; Initialize register d5 to constant $7f
	moveq    #$0,d4                                      ; Initialize register d4 to 0
WriteTrack_MfmDataEncode:
	move.l   (a0)+,d7                                    ; Move (a0)+ to register d7
	move.l   d7,d6                                       ; Move register d7 to register d6
	and.l    d0,d7                                       ; Logical AND register d7 with register d0
	move.l   d7,(a2)+                                    ; Move register d7 to (a2)+
	eor.l    d7,d4                                       ; Logical XOR register d4 with register d7
	lsr.l    #$1,d6
	and.l    d0,d6                                       ; Logical AND register d6 with register d0
	move.l   d6,(a1)+                                    ; Move register d6 to (a1)+
	eor.l    d6,d4                                       ; Logical XOR register d4 with register d6
	dbra     d5,WriteTrack_MfmDataEncode                 ; Decrement loop counter d5 and loop back to WriteTrack_MfmDataEncode if not exhausted
	move.l   d4,d7                                       ; Move register d4 to register d7
	bsr.w    FormatNibbleByte                            ; Call subroutine to FormatNibbleByte
	movea.l  a3,a2                                       ; Move pointer a3 to pointer a2
	move.l   d6,(a3)+                                    ; Move register d6 to (a3)+
	move.l   d7,(a3)                                     ; Move register d7 to (a3)
	moveq    #$1,d5                                      ; Initialize register d5 to 1
	bsr.b    FormatTrackSector                           ; Call subroutine to FormatTrackSector
	movea.l  a4,a2                                       ; Move pointer a4 to pointer a2
	move.w   #COP1LC,d5                                  ; Move COP1LC (copper list 1 pointer high/low) to register d5
	bsr.b    FormatTrackSector                           ; Call subroutine to FormatTrackSector
	addq.b   #$1,d1                                      ; Add 1 to register d1
	subq.b   #$1,d2                                      ; Subtract 1 from register d2
	lea.l    $200(a1),a1                                 ; Load address of $200(a1) into pointer a1
	dbra     d3,WriteTrack_SectorLoop                    ; Decrement loop counter d3 and loop back to WriteTrack_SectorLoop if not exhausted
	move.l   $17ae(a6),(a1)                              ; Move $17ae(a6) to (a1)
	movem.l  (a7)+,d0-d7/a0-a4                           ; Move multiple registers (a7)+ to d0-d7/a0-a4
	rts                                                  ; Return from subroutine
; ============================================================================
; Function: FormatNibbleByte
; Purpose : Helper routine that converts a raw data byte into its MFM nibble representation for disk writing.
; ============================================================================
FormatNibbleByte:
	; Core MFM encoding primitive. Takes a long in d7, splits it into data and clock bits using the mask
	; at $17aa (normally 0x55555555), and returns the properly interleaved MFM long in d6.
	; This is how raw Amiga track data is turned into the self-clocking MFM stream the drive expects.
	move.l   d7,d6                                       ; Move register d7 to register d6
	lsr.l    #$1,d6
	and.l    $17aa(a6),d6                                ; Logical AND register d6 with $17aa(a6)
	and.l    $17aa(a6),d7                                ; Logical AND register d7 with $17aa(a6)
	rts                                                  ; Return from subroutine
; ============================================================================
; Function: FormatTrackSector
; Purpose : Formats a single track sector, writing MFM headers, sync markers, and nibblized sector data into the track buffer.
; Notes: The roxr / not / and / eor dance is the classic way to insert the MFM clock bits between data bits
;        so the drive PLL can recover the clock without a separate clock track.
; ============================================================================
FormatTrackSector:
	movem.l  d0-d6/a2,-(a7)                              ; Move multiple registers d0-d6/a2 to -(a7)
	add.w    d5,d5                                       ; Add register d5 to register d5
	subq.w   #$1,d5                                      ; Subtract 1 from register d5
	move.l   $17aa(a6),d6                                ; Move $17aa(a6) to register d6
	move.b   -$1(a2),d0                                  ; Move -$1(a2) to register d0
MfmEncodeSectorLongwords:
	move.l   (a2),d4                                     ; Move (a2) to register d4
	move.l   d4,d1                                       ; Move register d4 to register d1
	move.l   d4,d2                                       ; Move register d4 to register d2
	not.l    d1
	and.l    d6,d1                                       ; Logical AND register d1 with register d6
	add.l    d1,d1                                       ; Add register d1 to register d1
	move.l   d1,d3                                       ; Move register d1 to register d3
	roxr.b   #$1,d0
	roxr.l   #$1,d4
	eor.l    d4,d1                                       ; Logical XOR register d1 with register d4
	and.l    d3,d1                                       ; Logical AND register d1 with register d3
	or.l     d1,d2                                       ; Logical OR register d2 with register d1
	move.l   d2,(a2)+                                    ; Move register d2 to (a2)+
	move.b   d2,d0                                       ; Move register d2 to register d0
	dbra     d5,MfmEncodeSectorLongwords                 ; Decrement loop counter d5 and loop back to MfmEncodeSectorLongwords if not exhausted
	movem.l  (a7)+,d0-d6/a2                              ; Move multiple registers (a7)+ to d0-d6/a2
	rts                                                  ; Return from subroutine
; ============================================================================
; Function: FormatTrackCopier
; Purpose : Formats and copies a complete floppy disk track. Integrates sector structuring, checksum calculation, and MFM encoding before writing the track to disk.
; ============================================================================
FormatTrackCopier:
	; High-level track formatter/copier. Loops over all tracks (or user-selected range), builds the MFM image
	; via WriteTrack + Format*Sector, writes it with the DMA starter, verifies, and shows progress in the
	; disasm buffer (so the font renderer can display "formatting track XX"). This is the heart of the
	; raw disk tools that made BeerMon famous for cracking and installing.
	movem.l  d6/a0-a1,-(a7)                              ; Move multiple registers d6/a0-a1 to -(a7)
FormatAndWriteAllTracks:
	lea.l    Var_FontData(a6),a0                         ; Load address of font glyph data pointer into pointer a0
	bsr.w    WriteTrack                                  ; Call subroutine to WriteTrack
	bsr.w    StartDiskDmaAndWait                         ; Call subroutine to StartDiskDmaAndWait
	tst.b    $1671(a6)                                   ; Test status of $1671(a6) (for zero or negative)
	bne.b    DiskFormatDone                              ; Branch to DiskFormatDone if non-zero / not equal
	btst     #$4,$16cc(a6)                               ; Test bit #$4 of $16cc(a6)
	bne.b    DiskFormatDone                              ; Branch to DiskFormatDone if non-zero / not equal
	sf.b     Var_MonitorFlag_1670(a6)
	move.w   $17c4(a6),d1                                ; Move $17c4(a6) to register d1
FormatTrackForCurrentSide:
	move.b   d1,$166e(a6)                                ; Move register d1 to $166e(a6)
	move.w   #$200,d6                                    ; Move constant $200 to register d6
	mulu.w   d1,d6
	lea.l    Var_FontData(a6),a0                         ; Load address of font glyph data pointer into pointer a0
	add.l    a0,d6                                       ; Add pointer a0 to register d6
	bsr.w    VerifyDiskSector_VerifyOnly                 ; Call subroutine to VerifyDiskSector_VerifyOnly
	tst.b    $1671(a6)                                   ; Test status of $1671(a6) (for zero or negative)
	beq.b    NextTrackOrSide                             ; Branch to NextTrackOrSide if zero / equal
	lea.l    -$1d22(a6),a1                               ; Load address of -$1d22(a6) into pointer a1
	lea.l    Var_DisasmBuffer+1(a6),a0                   ; Load address of disassembler output text buffer into pointer a0
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	move.b   $1671(a6),d0                                ; Move $1671(a6) to register d0
	bsr.w    FormatDecimal2Digit                         ; Call subroutine to FormatDecimal2Digit
	move.b   #$29,(a0)+                                  ; Move constant $29 to (a0)+
	bsr.w    FormatTrackSidePrefix                       ; Call subroutine to FormatTrackSidePrefix
	addq.w   #$8,a0                                      ; Add constant $8 to pointer a0
	lea.l    Str_RetryIgnoreAbort(pc),a1                            ; Load address of Str_RetryIgnoreAbort(pc) into pointer a1
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	bsr.w    RefreshAndDrawConsoleLine                   ; Call subroutine to RefreshAndDrawConsoleLine
	bsr.b    WaitForAbortOrKeyDuringDisk                 ; Call subroutine to WaitForAbortOrKeyDuringDisk
	beq.b    FormatAndWriteAllTracks                     ; Branch to FormatAndWriteAllTracks if zero / equal
	bpl.b    DiskFormatDone                              ; Branch to DiskFormatDone if positive / plus
NextTrackOrSide:
	sf.b     $1671(a6)
	dbra     d1,FormatTrackForCurrentSide                ; Decrement loop counter d1 and loop back to FormatTrackForCurrentSide if not exhausted
DiskFormatDone:
	movem.l  (a7)+,d6/a0-a1                              ; Move multiple registers (a7)+ to d6/a0-a1
	rts                                                  ; Return from subroutine
WaitForAbortOrKeyDuringDisk:
	st.b     Var_TaskFlag(a6)
	clr.w    Var_BufferLength(a6)                        ; Clear / reset keyboard input buffer character count
WaitDiskKeyLoop:
	cmpi.b   #BLTBDAT,Var_LockFlag(a6)                   ; Compare monitor lock status against constant BLTBDAT
	beq.b    DiskKey_ExitWithError                       ; Branch to DiskKey_ExitWithError if zero / equal
	cmpi.b   #$1b,Var_LockFlag(a6)                       ; Compare monitor lock status against constant $1b
	beq.b    DiskKey_Abort                               ; Branch to DiskKey_Abort if zero / equal
	cmpi.b   #$61,Var_LockFlag(a6)                       ; Compare monitor lock status against constant $61
	beq.b    DiskKey_Abort                               ; Branch to DiskKey_Abort if zero / equal
	cmpi.b   #$69,Var_LockFlag(a6)                       ; Compare monitor lock status against constant $69
	bne.b    WaitDiskKeyLoop                             ; Branch to WaitDiskKeyLoop if non-zero / not equal
	move.w   #$8,ccr                                     ; Move constant $8 to ccr
	bra.b    DiskKey_ExitWithError                       ; Unconditional branch to DiskKey_ExitWithError
DiskKey_Abort:
	move.w   #$0,ccr                                     ; Move 0 to ccr
DiskKey_ExitWithError:
	sf.b     Var_TaskFlag(a6)
	rts                                                  ; Return from subroutine
StartDiskDmaAndWait:
	; Low-level disk write sequencer. Sets up Paula disk DMA (using the MFM image we built in bitplane2),
	; controls the drive motor/step via CIA-B, waits for the write to complete or error, handles cache
	; flush so Agnus sees the data we just wrote from the CPU. Called after every track format/write.
	; This is pure "nasty" hardware access - no trackdisk.device.
	move.b   #$1d,$1671(a6)                              ; Move constant $1d to $1671(a6)
	lea.l    $dff09e.l,a2                                ; Load address of $dff09e.l into pointer a2
	bsr.w    Disk_WaitReady                              ; Call subroutine to Disk_WaitReady
	tst.w    d0                                          ; Test status of register d0 (for zero or negative)
	beq.w    DiskDmaWriteDone                            ; Branch to DiskDmaWriteDone if zero / equal
	move.w   #$4000,d0                                   ; Move constant $4000 to register d0
	move.w   #$7fff,(a2)                                 ; Move disable all / mask to (a2)
	move.w   #$9100,(a2)                                 ; Move constant $9100 to (a2)
	bra.b    DiskDma_StartWrite                          ; Unconditional branch to DiskDma_StartWrite
DiskDma_WaitForIndex:
	move.b   #$1d,$1671(a6)                              ; Move constant $1d to $1671(a6)
	lea.l    $dff09e.l,a2                                ; Load address of $dff09e.l into pointer a2
	bsr.w    Disk_WaitReady                              ; Call subroutine to Disk_WaitReady
	tst.w    d0                                          ; Test status of register d0 (for zero or negative)
	beq.w    DiskDmaWriteDone                            ; Branch to DiskDmaWriteDone if zero / equal
	clr.w    d0                                          ; Clear / reset register d0
	move.w   #$7fff,(a2)                                 ; Move disable all / mask to (a2)
	move.w   #$9100,(a2)                                 ; Move constant $9100 to (a2)
DiskDma_WaitIndexPulse:
	btst     #$4,$bfdd00.l                               ; Test bit #$4 of $bfdd00.l
	bne.b    DiskDma_WaitIndexPulse                      ; Branch to DiskDma_WaitIndexPulse if non-zero / not equal
	bra.b    DiskDma_StartWrite                          ; Unconditional branch to DiskDma_StartWrite
DiskDma_VerifyWrite:
	move.b   #$1d,$1671(a6)                              ; Move constant $1d to $1671(a6)
	lea.l    $dff09e.l,a2                                ; Load address of $dff09e.l into pointer a2
	bsr.w    Disk_WaitReady                              ; Call subroutine to Disk_WaitReady
	tst.w    d0                                          ; Test status of register d0 (for zero or negative)
	beq.b    DiskDmaWriteDone                            ; Branch to DiskDmaWriteDone if zero / equal
	clr.w    d0                                          ; Clear / reset register d0
	move.w   #$7fff,(a2)                                 ; Move disable all / mask to (a2)
	move.w   #$9500,(a2)                                 ; Move constant $9500 to (a2)
DiskDma_StartWrite:
	cmpi.b   #BLTBPTH,$166d(a6)                          ; Compare $166d(a6) against constant BLTBPTH
	bls.b    DiskDma_NoAgaHack
	move.w   #$a000,(a2)                                 ; Move constant $a000 to (a2)
DiskDma_NoAgaHack:
	bsr.w    CacheFlush_040                              ; Call subroutine to CacheFlush_040
	move.w   #$4000,-$7a(a2)                             ; Move constant $4000 to -$7a(a2)
	move.w   #$8010,-$8(a2)                              ; Move constant $8010 to -$8(a2)
	move.l   Var_Bitplane2(a6),-$7e(a2)                  ; Load second bitplane memory pointer into -$7e(a2)
	move.w   $17b2(a6),-$20(a2)                          ; Move $17b2(a6) to -$20(a2)
	move.w   #$2,-DMACONR(a2)                            ; Set DMA control (DMACON) bits to constant $2
	or.w     $17b4(a6),d0                                ; Logical OR register d0 with $17b4(a6)
	bset     #$f,d0                                      ; Set bit #$f of register d0
	move.w   d0,-$7a(a2)                                 ; Move register d0 to -$7a(a2)
	move.w   d0,-$7a(a2)                                 ; Move register d0 to -$7a(a2)
	move.b   #$1a,$1671(a6)                              ; Move constant $1a to $1671(a6)
	move.w   #$12c,d0                                    ; Move constant $12c to register d0
	tst.b    Var_MonitorFlag_166f(a6)                    ; Test status of Var_MonitorFlag_166f(a6) (for zero or negative)
	beq.b    DiskDma_WaitComplete                        ; Branch to DiskDma_WaitComplete if zero / equal
	add.w    d0,d0                                       ; Add register d0 to register d0
DiskDma_WaitComplete:
	bsr.b    DiskDma_WaitIndexOrTimeout                  ; Call subroutine to DiskDma_WaitIndexOrTimeout
	subq.w   #$1,d0                                      ; Subtract 1 from register d0
	beq.b    DiskDma_Finish                              ; Branch to DiskDma_Finish if zero / equal
	btst     #$1,-$7f(a2)                                ; Test bit #$1 of -$7f(a2)
	beq.b    DiskDma_WaitComplete                        ; Branch to DiskDma_WaitComplete if zero / equal
DiskDma_Finish:
	move.w   #$4000,-$7a(a2)                             ; Move constant $4000 to -$7a(a2)
	bsr.w    CacheFlush_020_030                          ; Call subroutine to CacheFlush_020_030
	tst.w    d0                                          ; Test status of register d0 (for zero or negative)
	beq.b    DiskDmaWriteDone                            ; Branch to DiskDmaWriteDone if zero / equal
	sf.b     $1671(a6)
	st.b     Var_MonitorFlag_1670(a6)
DiskDmaWriteDone:
	rts                                                  ; Return from subroutine
DiskDma_WaitIndexOrTimeout:
	move.l   a1,-(a7)                                    ; Move pointer a1 to -(a7)
	lea.l    $bfdd00.l,a1                                ; Load address of $bfdd00.l into pointer a1
	move.b   #$7f,(a1)                                   ; Move constant $7f to (a1)
	bclr     #$5,BPLCON0(a1)                             ; Clear bit #$5 of BPLCON0 (bitplane control register 0)
	bset     #$3,BPLCON0(a1)                             ; Set bit #$3 of BPLCON0 (bitplane control register 0)
	move.b   #$c5,-$900(a1)                              ; Move constant $c5 to -$900(a1)
	move.b   #$2,-$800(a1)                               ; Move constant $2 to -$800(a1)
DiskDma_IndexWaitLoop:
	btst     #$0,(a1)                                    ; Test bit #$0 of (a1)
	beq.b    DiskDma_IndexWaitLoop                       ; Branch to DiskDma_IndexWaitLoop if zero / equal
	movea.l  (a7)+,a1                                    ; Move (a7)+ to pointer a1
	rts                                                  ; Return from subroutine
; ============================================================================
; Function: Disk_PrepareDriveAndReadTrack
; Purpose : Prepares the floppy drive for reading by performing a step sequence
;           and seeking to track 0, checks if the disk is write-protected or
;           changed, reads/validates the bootblock, and finally reads the
;           requested track.
; Inputs  : a6 = BeerMon context base
; Outputs : $1671(a6) = error code (0 on success)
; Clobbers: d5-d6, a0-a1
; ============================================================================
Disk_PrepareDriveAndReadTrack:
	bsr.w    Disk_SelectDriveAndMotorOn                  ; Call subroutine to Disk_SelectDriveAndMotorOn
	bsr.w    Disk_StepOut                                ; Call subroutine to Disk_StepOut
	bsr.w    Disk_StepIn                                 ; Call subroutine to Disk_StepIn
	sf.b     $1671(a6)                             ; Reset disk error status
	bsr.w    Disk_SeekTrack0                             ; Call subroutine to Disk_SeekTrack0
	tst.b    $1671(a6)                             ; Check if $1671 is set / active
	bne.b    Disk_PrepareDriveAndReadTrack_Exit          ; Branch to Disk_PrepareDriveAndReadTrack_Exit if non-zero / not equal
	clr.l    $17f6(a6)                                   ; Clear / reset $17f6(a6)
	sf.b     Var_MonitorFlag_1670(a6)              ; Reset track change flag
	bsr.w    Disk_CheckWriteProtectAndPresent            ; Call subroutine to Disk_CheckWriteProtectAndPresent
	bne.b    Disk_PrepareDriveAndReadTrack_Exit          ; Branch to Disk_PrepareDriveAndReadTrack_Exit if non-zero / not equal
	bsr.w    Disk_ReadAndValidateBootblock               ; Call subroutine to Disk_ReadAndValidateBootblock
	bne.b    Disk_PrepareDriveAndReadTrack_Exit          ; Branch to Disk_PrepareDriveAndReadTrack_Exit if non-zero / not equal
	pea.l    $3294(a6)                             ; Load address of bootblock buffer onto stack
	move.l   (a7)+,d6                                    ; Move (a7)+ to register d6
	move.l   $17d2(a6),d5                                ; Move $17d2(a6) to register d5
	bsr.w    Disk_ReadWriteSector                        ; Call subroutine to Disk_ReadWriteSector
	tst.b    $1671(a6)                             ; Check if $1671 is set / active
Disk_PrepareDriveAndReadTrack_Exit:
	rts                                                  ; Return from subroutine
	lea.l    $3(a5),a0                                   ; Load address of $3(a5) into pointer a0
	bsr.w    Parser_GetNextArg                           ; Call subroutine to Parser_GetNextArg
	beq.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_3000 ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_3000 if zero / equal
	cmpi.w   #$1e,d4                                     ; Compare register d4 against constant $1e
	bhi.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_3000                              ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_3000 if higher.
	cmpi.b   #$3a,(a2)                                   ; Compare (a2) against constant $3a
	bne.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_2FB8 ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_2FB8 if non-zero / not equal
	move.l   $17b6(a6),$17d2(a6)                         ; Move $17b6(a6) to $17d2(a6)
	addq.w   #$1,a2                                      ; Add 1 to pointer a2
	subq.w   #$1,d4                                      ; Subtract 1 from register d4
	beq.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_2FFA ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_2FFA if zero / equal
Disk_PrepareDriveAndReadTrack_Exit_Loc_2FB8:
	sf.b     $1672(a6)                             ; Clear $1672(a6) flag (false).
	sf.b     $1673(a6)                             ; Clear $1673(a6) flag (false).
	bsr.b    Disk_PrepareDriveAndReadTrack               ; Call subroutine to Disk_PrepareDriveAndReadTrack
	bne.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_2FFA ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_2FFA if non-zero / not equal
	movea.l  a2,a0                                       ; Move pointer a2 to pointer a0
	bsr.w    Afs_HashFilename                            ; Call subroutine to Afs_HashFilename
	beq.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_3002 ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_3002 if zero / equal
	bsr.w    Afs_FindFileInDirectory                     ; Call subroutine to Afs_FindFileInDirectory
	beq.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_3002 ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_3002 if zero / equal
	move.l   FMODE(a4),d0                                ; Move FMODE (AGA fetch mode control register) to register d0
	addq.l   #$3,d0                                      ; Add constant $3 to register d0
	beq.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_2FF0 ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_2FF0 if zero / equal
	addq.l   #$1,d0                                      ; Add 1 to register d0
	beq.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_2FF0 ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_2FF0 if zero / equal
	move.l   $4(a4),d1                                   ; Move $4(a4) to register d1
	subq.l   #$6,d0                                      ; Subtract constant $6 from register d0
	beq.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_2FF6 ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_2FF6 if zero / equal
	move.l   $1d4(a4),d1                                 ; Move $1d4(a4) to register d1
	subq.l   #$2,d0                                      ; Subtract constant $2 from register d0
	beq.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_2FF6 ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_2FF6 if zero / equal
	bra.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_2FFA ; Unconditional branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_2FFA
Disk_PrepareDriveAndReadTrack_Exit_Loc_2FF0:
	bsr.w    Print_DirectoryIsAFileError                 ; Call subroutine to Print_DirectoryIsAFileError
	bra.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_2FFA ; Unconditional branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_2FFA
Disk_PrepareDriveAndReadTrack_Exit_Loc_2FF6:
	move.l   d1,$17d2(a6)                                ; Move register d1 to $17d2(a6)
Disk_PrepareDriveAndReadTrack_Exit_Loc_2FFA:
	bsr.w    Disk_MotorOff                               ; Call subroutine to Disk_MotorOff
	st.b     d7
Disk_PrepareDriveAndReadTrack_Exit_Loc_3000:
	rts                                                  ; Return from subroutine
Disk_PrepareDriveAndReadTrack_Exit_Loc_3002:
	bsr.w    Print_DirectoryNotFoundError                ; Call subroutine to Print_DirectoryNotFoundError
	bra.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_2FFA ; Unconditional branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_2FFA
	lea.l    $4(a5),a0                                   ; Load address of $4(a5) into pointer a0
	bsr.w    Parser_GetNextArg                           ; Call subroutine to Parser_GetNextArg
	move.w   d4,$182c(a6)                                ; Move register d4 to $182c(a6)
	beq.w    Disk_PrepareDriveAndReadTrack_Exit_Loc_31CE ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_31CE if zero / equal
	cmpi.w   #$1e,d4                                     ; Compare register d4 against constant $1e
	bhi.w    Disk_PrepareDriveAndReadTrack_Exit_Loc_31CE                              ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_31CE if higher.
	st.b     $1672(a6)                             ; Set $1672(a6) flag (true).
	st.b     $1673(a6)                             ; Set $1673(a6) flag (true).
	bsr.w    Disk_PrepareDriveAndReadTrack               ; Call subroutine to Disk_PrepareDriveAndReadTrack
	bne.w    Disk_PrepareDriveAndReadTrack_Exit_Loc_31C8 ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_31C8 if non-zero / not equal
	movea.l  a2,a0                                       ; Move pointer a2 to pointer a0
	clr.l    $17d6(a6)                                   ; Clear / reset $17d6(a6)
	bsr.w    Afs_HashFilename                            ; Call subroutine to Afs_HashFilename
	beq.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_3042 ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_3042 if zero / equal
	bsr.w    Afs_FindFileInDirectory                     ; Call subroutine to Afs_FindFileInDirectory
	bne.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_304A ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_304A if non-zero / not equal
Disk_PrepareDriveAndReadTrack_Exit_Loc_3042:
	bsr.w    Print_FileNotFoundError                     ; Call subroutine to Print_FileNotFoundError
	bra.w    Disk_PrepareDriveAndReadTrack_Exit_Loc_31C8 ; Unconditional branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_31C8
Disk_PrepareDriveAndReadTrack_Exit_Loc_304A:
	move.l   $4(a4),d0                                   ; Move $4(a4) to register d0
	bsr.w    Afs_FreeBlock                               ; Call subroutine to Afs_FreeBlock
	beq.w    Disk_PrepareDriveAndReadTrack_Exit_Loc_31D6 ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_31D6 if zero / equal
	move.l   FMODE(a4),d0                                ; Move FMODE (AGA fetch mode control register) to register d0
	subq.l   #$2,d0                                      ; Subtract constant $2 from register d0
	beq.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_30B2 ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_30B2 if zero / equal
	addq.l   #$5,d0                                      ; Add constant $5 to register d0
	beq.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_30B2 ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_30B2 if zero / equal
	subq.l   #$7,d0                                      ; Subtract constant $7 from register d0
	beq.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_306C ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_306C if zero / equal
	addq.l   #$8,d0                                      ; Add constant $8 to register d0
	bne.w    Disk_PrepareDriveAndReadTrack_Exit_Loc_31C8 ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_31C8 if non-zero / not equal
Disk_PrepareDriveAndReadTrack_Exit_Loc_306C:
	move.l   $4(a4),d4                                   ; Move $4(a4) to register d4
	lea.l    $3294(a6),a5                                ; Load address of $3294(a6) into pointer a5
	move.l   $1d4(a4),d5                                 ; Move $1d4(a4) to register d5
Disk_PrepareDriveAndReadTrack_Exit_Loc_3078:
	move.l   a5,d6                                       ; Move pointer a5 to register d6
	bsr.w    Disk_ReadWriteSector                        ; Call subroutine to Disk_ReadWriteSector
	tst.b    $1671(a6)                             ; Check if $1671 is set / active
	bne.w    Disk_PrepareDriveAndReadTrack_Exit_Loc_31C8 ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_31C8 if non-zero / not equal
	move.l   $1d8(a5),d0                                 ; Move $1d8(a5) to register d0
	cmp.l    d4,d0                                       ; Compare register d0 against register d4
	bne.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_30AE ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_30AE if non-zero / not equal
	move.l   $1d8(a4),$1d8(a5)                           ; Move $1d8(a4) to $1d8(a5)
	movea.l  a5,a0                                       ; Move pointer a5 to pointer a0
	bsr.w    Disk_CalculateBootblockChecksum             ; Call subroutine to Disk_CalculateBootblockChecksum
	move.l   d3,$14(a0)                                  ; Move register d3 to $14(a0)
	bsr.w    Disk_WriteSector                            ; Call subroutine to Disk_WriteSector
	tst.b    $1671(a6)                             ; Check if $1671 is set / active
	bne.w    Disk_PrepareDriveAndReadTrack_Exit_Loc_31C8 ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_31C8 if non-zero / not equal
	bra.w    Disk_PrepareDriveAndReadTrack_Exit_Loc_3176 ; Unconditional branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_3176
Disk_PrepareDriveAndReadTrack_Exit_Loc_30AE:
	move.l   d0,d5                                       ; Move register d0 to register d5
	bra.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_3078 ; Unconditional branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_3078
Disk_PrepareDriveAndReadTrack_Exit_Loc_30B2:
	move.l   $1d8(a4),d5                                 ; Move $1d8(a4) to register d5
	beq.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_311C ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_311C if zero / equal
	move.l   d5,d4                                       ; Move register d5 to register d4
	lea.l    $3294(a6),a5                                ; Load address of $3294(a6) into pointer a5
	move.l   a5,d6                                       ; Move pointer a5 to register d6
	bsr.w    Disk_ReadWriteSector                        ; Call subroutine to Disk_ReadWriteSector
	tst.b    $1671(a6)                             ; Check if $1671 is set / active
	bne.w    Disk_PrepareDriveAndReadTrack_Exit_Loc_31C8 ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_31C8 if non-zero / not equal
	lea.l    $8(a4),a0                                   ; Load address of $8(a4) into pointer a0
	lea.l    $8(a5),a1                                   ; Load address of $8(a5) into pointer a1
	moveq    #BLTDMOD,d0                                 ; Initialize register d0 to constant BLTDMOD
Disk_PrepareDriveAndReadTrack_Exit_Loc_30D6:
	move.l   (a0)+,(a1)+                                 ; Copy word/byte data from source pointer a0 to destination a1
	dbra     d0,Disk_PrepareDriveAndReadTrack_Exit_Loc_30D6	; Decrement loop counter d0 and loop back to Disk_PrepareDriveAndReadTrack_Exit_Loc_30D6 if not exhausted
	move.l   $1f8(a4),$1f8(a5)                           ; Move $1f8(a4) to $1f8(a5)
	move.l   FMODE(a4),FMODE(a5)                         ; Move FMODE (AGA fetch mode control register) to FMODE (AGA fetch mode control register)
	clr.l    $1d4(a5)                                    ; Clear / reset $1d4(a5)
	movea.l  a5,a0                                       ; Move pointer a5 to pointer a0
Disk_PrepareDriveAndReadTrack_Exit_Loc_30EE:
	bsr.w    Disk_CalculateBootblockChecksum             ; Call subroutine to Disk_CalculateBootblockChecksum
	move.l   d3,$14(a0)                                  ; Move register d3 to $14(a0)
	bsr.w    Disk_WriteSector                            ; Call subroutine to Disk_WriteSector
	tst.b    $1671(a6)                             ; Check if $1671 is set / active
	bne.w    Disk_PrepareDriveAndReadTrack_Exit_Loc_31C8 ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_31C8 if non-zero / not equal
	move.l   $1d8(a5),d5                                 ; Move $1d8(a5) to register d5
	beq.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_311A ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_311A if zero / equal
	bsr.w    Disk_ReadWriteSector                        ; Call subroutine to Disk_ReadWriteSector
	tst.b    $1671(a6)                             ; Check if $1671 is set / active
	bne.w    Disk_PrepareDriveAndReadTrack_Exit_Loc_31C8 ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_31C8 if non-zero / not equal
	move.l   d4,$1d4(a5)                                 ; Move register d4 to $1d4(a5)
	bra.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_30EE ; Unconditional branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_30EE
Disk_PrepareDriveAndReadTrack_Exit_Loc_311A:
	bra.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_3176 ; Unconditional branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_3176
Disk_PrepareDriveAndReadTrack_Exit_Loc_311C:
	move.l   FMODE(a4),d0                                ; Move FMODE (AGA fetch mode control register) to register d0
	subq.l   #$2,d0                                      ; Subtract constant $2 from register d0
	beq.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_3168 ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_3168 if zero / equal
	movea.l  a4,a5                                       ; Move pointer a4 to pointer a5
Disk_PrepareDriveAndReadTrack_Exit_Loc_3126:
	lea.l    $138(a5),a3                                 ; Load address of $138(a5) into pointer a3
	moveq    #$48,d3                                     ; Initialize register d3 to constant $48
	tst.b    $1676(a6)                             ; Check if $1676 is set / active
	bne.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_3136 ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_3136 if non-zero / not equal
	move.l   $8(a5),d3                                   ; Move $8(a5) to register d3
Disk_PrepareDriveAndReadTrack_Exit_Loc_3136:
	subq.l   #$1,d3                                      ; Subtract 1 from register d3
	bmi.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_3148 ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_3148 if negative / minus
	move.l   -(a3),d0                                    ; Move -(a3) to register d0
	beq.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_3136 ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_3136 if zero / equal
	bsr.w    Afs_FreeBlock                               ; Call subroutine to Afs_FreeBlock
	beq.w    Disk_PrepareDriveAndReadTrack_Exit_Loc_31D6 ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_31D6 if zero / equal
	bra.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_3136 ; Unconditional branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_3136
Disk_PrepareDriveAndReadTrack_Exit_Loc_3148:
	move.l   $1f8(a5),d5                                 ; Move $1f8(a5) to register d5
	beq.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_3176 ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_3176 if zero / equal
	lea.l    $3294(a6),a5                                ; Load address of $3294(a6) into pointer a5
	move.l   a5,d6                                       ; Move pointer a5 to register d6
	bsr.w    Disk_ReadWriteSector                        ; Call subroutine to Disk_ReadWriteSector
	tst.b    $1671(a6)                             ; Check if $1671 is set / active
	bne.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_31C8 ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_31C8 if non-zero / not equal
	move.l   d5,d0                                       ; Move register d5 to register d0
	bsr.w    Afs_FreeBlock                               ; Call subroutine to Afs_FreeBlock
	beq.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_31D6 ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_31D6 if zero / equal
	bra.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_3126 ; Unconditional branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_3126
Disk_PrepareDriveAndReadTrack_Exit_Loc_3168:
	lea.l    $18(a4),a0                                  ; Load address of $18(a4) into pointer a0
	moveq    #$47,d0                                     ; Initialize register d0 to constant $47
Disk_PrepareDriveAndReadTrack_Exit_Loc_316E:
	tst.l    (a0)+                                       ; Test status of (a0)+ (for zero or negative)
	bne.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_31D0 ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_31D0 if non-zero / not equal
	dbra     d0,Disk_PrepareDriveAndReadTrack_Exit_Loc_316E	; Decrement loop counter d0 and loop back to Disk_PrepareDriveAndReadTrack_Exit_Loc_316E if not exhausted
Disk_PrepareDriveAndReadTrack_Exit_Loc_3176:
	lea.l    $3294(a6),a0                                ; Load address of $3294(a6) into pointer a0
	move.l   a0,d6                                       ; Move pointer a0 to register d6
	lea.l    $1f0(a0),a3                                 ; Load address of $1f0(a0) into pointer a3
	move.l   $17d6(a6),d5                                ; Move $17d6(a6) to register d5
	bne.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_318E ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_318E if non-zero / not equal
	move.l   $17d2(a6),d5                                ; Move $17d2(a6) to register d5
	movea.l  $17da(a6),a3                                ; Move $17da(a6) to pointer a3
Disk_PrepareDriveAndReadTrack_Exit_Loc_318E:
	bsr.w    Disk_ReadWriteSector                        ; Call subroutine to Disk_ReadWriteSector
	tst.b    $1671(a6)                             ; Check if $1671 is set / active
	bne.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_31C8 ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_31C8 if non-zero / not equal
	move.l   $1f0(a4),(a3)                               ; Move $1f0(a4) to (a3)
	movea.l  d6,a0                                       ; Move register d6 to pointer a0
	bsr.w    Disk_CalculateBootblockChecksum             ; Call subroutine to Disk_CalculateBootblockChecksum
	move.l   d3,$14(a0)                                  ; Move register d3 to $14(a0)
	bsr.w    Disk_WriteSector                            ; Call subroutine to Disk_WriteSector
	tst.b    $1671(a6)                             ; Check if $1671 is set / active
	bne.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_31C8 ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_31C8 if non-zero / not equal
	bsr.w    Afs_UpdateBitmapChecksum                    ; Call subroutine to Afs_UpdateBitmapChecksum
	move.l   a0,d6                                       ; Move pointer a0 to register d6
	move.l   $17ca(a6),d5                                ; Move $17ca(a6) to register d5
	bsr.w    Disk_WriteSector                            ; Call subroutine to Disk_WriteSector
	tst.b    $1671(a6)                             ; Check if $1671 is set / active
	bne.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_31C8 ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_31C8 if non-zero / not equal
	bsr.w    Disk_FlushTrackWriteBuffer                  ; Call subroutine to Disk_FlushTrackWriteBuffer
Disk_PrepareDriveAndReadTrack_Exit_Loc_31C8:
	bsr.w    Disk_MotorOff                               ; Call subroutine to Disk_MotorOff
	st.b     d7
Disk_PrepareDriveAndReadTrack_Exit_Loc_31CE:
	rts                                                  ; Return from subroutine
Disk_PrepareDriveAndReadTrack_Exit_Loc_31D0:
	bsr.w    Print_DirectoryNotEmptyError                ; Call subroutine to Print_DirectoryNotEmptyError
	bra.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_31C8 ; Unconditional branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_31C8
Disk_PrepareDriveAndReadTrack_Exit_Loc_31D6:
	bsr.w    Print_BadBitmapError                        ; Call subroutine to Print_BadBitmapError
	bra.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_31C8 ; Unconditional branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_31C8
	lea.l    $3(a5),a0                                   ; Load address of $3(a5) into pointer a0
	bsr.w    Parser_GetNextArg                           ; Call subroutine to Parser_GetNextArg
	move.w   d4,$182c(a6)                                ; Move register d4 to $182c(a6)
	beq.w    Disk_PrepareDriveAndReadTrack_Exit_Loc_3310 ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_3310 if zero / equal
	cmpi.w   #$1e,d4                                     ; Compare register d4 against constant $1e
	bhi.w    Disk_PrepareDriveAndReadTrack_Exit_Loc_3310                              ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_3310 if higher.
	st.b     $1672(a6)                             ; Set $1672(a6) flag (true).
	st.b     $1673(a6)                             ; Set $1673(a6) flag (true).
	bsr.w    Disk_PrepareDriveAndReadTrack               ; Call subroutine to Disk_PrepareDriveAndReadTrack
	bne.w    Disk_PrepareDriveAndReadTrack_Exit_Loc_330A ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_330A if non-zero / not equal
	movea.l  a2,a0                                       ; Move pointer a2 to pointer a0
	bsr.w    Afs_HashFilename                            ; Call subroutine to Afs_HashFilename
	beq.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_321A ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_321A if zero / equal
	bsr.w    Afs_FindFileInDirectory                     ; Call subroutine to Afs_FindFileInDirectory
	beq.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_321A ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_321A if zero / equal
	bsr.w    Print_DirectoryExistsError                  ; Call subroutine to Print_DirectoryExistsError
	bra.w    Disk_PrepareDriveAndReadTrack_Exit_Loc_330A ; Unconditional branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_330A
Disk_PrepareDriveAndReadTrack_Exit_Loc_321A:
	bsr.w    Afs_AllocateBlock                           ; Call subroutine to Afs_AllocateBlock
	beq.w    Disk_PrepareDriveAndReadTrack_Exit_Loc_3312 ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_3312 if zero / equal
	move.l   d0,d4                                       ; Move register d0 to register d4
	lea.l    Var_MonitorBufferOffset(a6),a4              ; Load address of Var_MonitorBufferOffset(a6) into pointer a4
	movea.l  a4,a0                                       ; Move pointer a4 to pointer a0
	moveq    #$7f,d6                                     ; Initialize register d6 to constant $7f
Disk_PrepareDriveAndReadTrack_Exit_Loc_322C:
	clr.l    (a0)+                                       ; Clear / reset (a0)+
	dbra     d6,Disk_PrepareDriveAndReadTrack_Exit_Loc_322C	; Decrement loop counter d6 and loop back to Disk_PrepareDriveAndReadTrack_Exit_Loc_322C if not exhausted
	movea.l  $17da(a6),a1                                ; Move $17da(a6) to pointer a1
	clr.l    $17de(a6)                                   ; Clear / reset $17de(a6)
	move.l   (a1),d5                                     ; Move (a1) to register d5
	beq.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_325E ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_325E if zero / equal
Disk_PrepareDriveAndReadTrack_Exit_Loc_323E:
	cmp.l    d4,d5                                       ; Compare register d5 against register d4
	bhi.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_325E                              ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_325E if higher.
	move.l   d5,$17de(a6)                                ; Move register d5 to $17de(a6)
	lea.l    $3294(a6),a5                                ; Load address of $3294(a6) into pointer a5
	move.l   a5,d6                                       ; Move pointer a5 to register d6
	bsr.w    Disk_ReadWriteSector                        ; Call subroutine to Disk_ReadWriteSector
	tst.b    $1671(a6)                             ; Check if $1671 is set / active
	bne.w    Disk_PrepareDriveAndReadTrack_Exit_Loc_330A ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_330A if non-zero / not equal
	move.l   $1f0(a5),d5                                 ; Move $1f0(a5) to register d5
	bne.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_323E ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_323E if non-zero / not equal
Disk_PrepareDriveAndReadTrack_Exit_Loc_325E:
	move.l   d5,$1f0(a4)                                 ; Move register d5 to $1f0(a4)
	bsr.w    Rtc_InitAndTest                             ; Call subroutine to Rtc_InitAndTest
	move.l   $1814(a6),$1a4(a4)                          ; Move $1814(a6) to $1a4(a4)
	move.l   $1818(a6),$1a8(a4)                          ; Move $1818(a6) to $1a8(a4)
	move.l   $181c(a6),$1ac(a4)                          ; Move $181c(a6) to $1ac(a4)
	moveq    #$2,d6                                      ; Initialize register d6 to constant $2
	move.l   d6,(a4)                                     ; Move register d6 to (a4)
	move.l   (a4),FMODE(a4)                              ; Move (a4) to FMODE (AGA fetch mode control register)
	move.l   d4,$4(a4)                                   ; Move register d4 to $4(a4)
	move.l   $17d2(a6),$1f4(a4)                          ; Move $17d2(a6) to $1f4(a4)
	lea.l    $1b1(a4),a0                                 ; Load address of $1b1(a4) into pointer a0
	move.w   $182c(a6),d0                                ; Move $182c(a6) to register d0
	subq.w   #$1,d0                                      ; Subtract 1 from register d0
Disk_PrepareDriveAndReadTrack_Exit_Loc_3294:
	move.b   (a2)+,(a0)+                                 ; Move (a2)+ to (a0)+
	addq.b   #$1,$1b0(a4)                                ; Add 1 to $1b0(a4)
	dbra     d0,Disk_PrepareDriveAndReadTrack_Exit_Loc_3294	; Decrement loop counter d0 and loop back to Disk_PrepareDriveAndReadTrack_Exit_Loc_3294 if not exhausted
	movea.l  a4,a0                                       ; Move pointer a4 to pointer a0
	bsr.w    Disk_CalculateBootblockChecksum             ; Call subroutine to Disk_CalculateBootblockChecksum
	move.l   d3,$14(a0)                                  ; Move register d3 to $14(a0)
	move.l   $4(a4),d5                                   ; Move $4(a4) to register d5
	move.l   a4,d6                                       ; Move pointer a4 to register d6
	bsr.w    Disk_WriteSector                            ; Call subroutine to Disk_WriteSector
	tst.b    $1671(a6)                             ; Check if $1671 is set / active
	bne.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_330A ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_330A if non-zero / not equal
	lea.l    $3294(a6),a2                                ; Load address of $3294(a6) into pointer a2
	move.l   a2,d6                                       ; Move pointer a2 to register d6
	lea.l    $3484(a6),a2                                ; Load address of $3484(a6) into pointer a2
	move.l   $17de(a6),d5                                ; Move $17de(a6) to register d5
	bne.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_32D0 ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_32D0 if non-zero / not equal
	movea.l  $17da(a6),a2                                ; Move $17da(a6) to pointer a2
	move.l   $17d2(a6),d5                                ; Move $17d2(a6) to register d5
Disk_PrepareDriveAndReadTrack_Exit_Loc_32D0:
	bsr.w    Disk_ReadWriteSector                        ; Call subroutine to Disk_ReadWriteSector
	tst.b    $1671(a6)                             ; Check if $1671 is set / active
	bne.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_330A ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_330A if non-zero / not equal
	move.l   d4,(a2)                                     ; Move register d4 to (a2)
	lea.l    $3294(a6),a0                                ; Load address of $3294(a6) into pointer a0
	bsr.w    Disk_CalculateBootblockChecksum             ; Call subroutine to Disk_CalculateBootblockChecksum
	move.l   d3,$14(a0)                                  ; Move register d3 to $14(a0)
	bsr.w    Disk_WriteSector                            ; Call subroutine to Disk_WriteSector
	tst.b    $1671(a6)                             ; Check if $1671 is set / active
	bne.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_330A ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_330A if non-zero / not equal
	bsr.w    Afs_UpdateBitmapChecksum                    ; Call subroutine to Afs_UpdateBitmapChecksum
	move.l   a0,d6                                       ; Move pointer a0 to register d6
	move.l   $17ca(a6),d5                                ; Move $17ca(a6) to register d5
	bsr.w    Disk_WriteSector                            ; Call subroutine to Disk_WriteSector
	tst.b    $1671(a6)                             ; Check if $1671 is set / active
	bne.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_330A ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_330A if non-zero / not equal
	bsr.w    Disk_FlushTrackWriteBuffer                  ; Call subroutine to Disk_FlushTrackWriteBuffer
Disk_PrepareDriveAndReadTrack_Exit_Loc_330A:
	bsr.w    Disk_MotorOff                               ; Call subroutine to Disk_MotorOff
	st.b     d7
Disk_PrepareDriveAndReadTrack_Exit_Loc_3310:
	rts                                                  ; Return from subroutine
Disk_PrepareDriveAndReadTrack_Exit_Loc_3312:
	bsr.w    Print_DiskFullError                         ; Call subroutine to Print_DiskFullError
	bra.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_330A ; Unconditional branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_330A
	sf.b     d7
	bra.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_331E ; Unconditional branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_331E
	st.b     d7
Disk_PrepareDriveAndReadTrack_Exit_Loc_331E:
	sf.b     $1672(a6)                             ; Clear $1672(a6) flag (false).
	sf.b     $1673(a6)                             ; Clear $1673(a6) flag (false).
	bsr.w    Disk_PrepareDriveAndReadTrack               ; Call subroutine to Disk_PrepareDriveAndReadTrack
	bne.w    Console_FormatRulerLine_Write_Loc_344C      ; Branch to Console_FormatRulerLine_Write_Loc_344C if non-zero / not equal
	tst.b    d7                                          ; Test status of register d7 (for zero or negative)
	bne.w    Console_DrawColumnRuler                     ; Branch to Console_DrawColumnRuler if non-zero / not equal
	lea.l    Var_DisasmBuffer+1(a6),a0                   ; Load address of disassembler output text buffer into pointer a0
	lea.l    Str_ModeBitmapIs(pc),a1                            ; Load address of Str_ModeBitmapIs(pc) into pointer a1
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	moveq    #BLTAFWM,d0                                 ; Initialize register d0 to constant BLTAFWM
	tst.b    Var_MonitorFlag_166f(a6)              ; Check if Var_MonitorFlag_166f is set / active
	beq.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_334A ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_334A if zero / equal
	moveq    #$48,d0                                     ; Initialize register d0 to constant $48
Disk_PrepareDriveAndReadTrack_Exit_Loc_334A:
	move.b   d0,-$e(a0)                                  ; Move register d0 to -$e(a0)
	tst.b    $1678(a6)                             ; Check if $1678 is set / active
	beq.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_3356 ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_3356 if zero / equal
	addq.w   #$2,a1                                      ; Add constant $2 to pointer a1
Disk_PrepareDriveAndReadTrack_Exit_Loc_3356:
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	move.l   $17ca(a6),d0                                ; Move $17ca(a6) to register d0
	bsr.w    PrintHex4_Entry                             ; Call subroutine to PrintHex4_Entry
	move.b   #$3d,(a0)+                                  ; Move constant $3d to (a0)+
	bsr.w    FormatDecimal3Digit                         ; Call subroutine to FormatDecimal3Digit
	move.b   #$29,(a0)+                                  ; Move constant $29 to (a0)+
	move.b   #$2c,(a0)+                                  ; Move constant $2c to (a0)+
	bsr.w    Disk_PrintUsageInfo                         ; Call subroutine to Disk_PrintUsageInfo
	addq.w   #$1,a0                                      ; Add 1 to pointer a0
	lea.l    Str_Filesystem(pc),a1                            ; Load address of Str_Filesystem(pc) into pointer a1
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	tst.b    $1677(a6)                             ; Check if $1677 is set / active
	beq.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_3388 ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_3388 if zero / equal
	addq.w   #$4,a1                                      ; Add constant $4 to pointer a1
Disk_PrepareDriveAndReadTrack_Exit_Loc_3388:
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	moveq    #$4f,d0                                     ; Initialize register d0 to constant $4f
	tst.b    $1676(a6)                             ; Check if $1676 is set / active
	beq.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_3396 ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_3396 if zero / equal
	moveq    #BLTALWM,d0                                 ; Initialize register d0 to constant BLTALWM
Disk_PrepareDriveAndReadTrack_Exit_Loc_3396:
	move.b   d0,-$5(a0)                                  ; Move register d0 to -$5(a0)
	bsr.w    Afs_BlockToCylinder                         ; Call subroutine to Afs_BlockToCylinder
	lea.l    Str_DiskFull(pc),a1                            ; Load address of Str_DiskFull(pc) into pointer a1
	beq.b    Disk_PrepareDriveAndReadTrack_Exit_Loc_33B4 ; Branch to Disk_PrepareDriveAndReadTrack_Exit_Loc_33B4 if zero / equal
	bsr.w    FormatHexCompact                            ; Call subroutine to FormatHexCompact
	move.b   #$3d,(a0)+                                  ; Move constant $3d to (a0)+
	bsr.w    FormatDecimal32Bit                          ; Call subroutine to FormatDecimal32Bit
	lea.l    Str_FreeBytes(pc),a1                            ; Load address of Str_FreeBytes(pc) into pointer a1
Disk_PrepareDriveAndReadTrack_Exit_Loc_33B4:
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	bsr.w    RefreshAndDrawConsoleLine                   ; Call subroutine to RefreshAndDrawConsoleLine
	bra.w    Console_FormatRulerLine_Write_Loc_344C      ; Unconditional branch to Console_FormatRulerLine_Write_Loc_344C
Console_DrawColumnRuler:
	bsr.w    Console_ClearScreen_Body                    ; Call subroutine to Console_ClearScreen_Body
	lea.l    Var_DisasmBuffer(a6),a0                     ; Load address of disassembler output text buffer into pointer a0
	sf.b     d2
	bsr.b    Console_FormatRulerLine                     ; Call subroutine to Console_FormatRulerLine
	st.b     d2
	pea.l    Console_DrawColumnRuler_Part2(pc)                         ; Push effective address of Console_DrawColumnRuler_Part2(pc) onto stack.
Console_FormatRulerLine:
	moveq    #$4f,d1                                     ; Initialize register d1 to constant $4f
Console_FormatRulerLine_Loop:
	moveq    #$4f,d0                                     ; Initialize register d0 to constant $4f
	sub.l    d1,d0                                       ; Subtract register d1 from register d0
	divu.w   #$a,d0
	tst.b    d2                                          ; Test status of register d2 (for zero or negative)
	beq.b    Console_FormatRulerLine_Write               ; Branch to Console_FormatRulerLine_Write if zero / equal
	swap     d0
Console_FormatRulerLine_Write:
	addi.b   #$30,d0                                     ; Add constant $30 to register d0
	move.b   d0,(a0)+                                    ; Move register d0 to (a0)+
	dbra     d1,Console_FormatRulerLine_Loop             ; Decrement loop counter d1 and loop back to Console_FormatRulerLine_Loop if not exhausted
	bra.w    RefreshAndDrawConsoleLine                   ; Unconditional branch to RefreshAndDrawConsoleLine
; ============================================================================
; Data Block: Console_DrawColumnRuler_Part2
; Purpose   : Continuation routine for formatting and rendering the column ruler.
; ============================================================================
Console_DrawColumnRuler_Part2:
	movea.l  Var_Bitplane1(a6),a0                        ; Load first bitplane memory pointer into pointer a0
	lea.l    $500(a0),a0                                 ; Load address of $500(a0) into pointer a0
	move.w   $17c8(a6),d4                                ; Move $17c8(a6) to register d4
Console_FormatRulerLine_Write_Loc_33FC:
	moveq    #$4f,d3                                     ; Initialize register d3 to constant $4f
	move.w   $17c8(a6),d0                                ; Move $17c8(a6) to register d0
	ext.l    d0
	subq.w   #$2,d0                                      ; Subtract constant $2 from register d0
	sub.w    d4,d0                                       ; Subtract register d4 from register d0
	bpl.b    Console_FormatRulerLine_Write_Loc_3416      ; Branch to Console_FormatRulerLine_Write_Loc_3416 if positive / plus
	moveq    #$2a,d6                                     ; Initialize register d6 to constant $2a
	move.b   d6,(a0)+                                    ; Move register d6 to (a0)+
	move.b   d6,$9f(a0)                                  ; Move register d6 to $9f(a0)
	add.w    d6,d6                                       ; Add register d6 to register d6
	bra.b    Console_FormatRulerLine_Write_Loc_3424      ; Unconditional branch to Console_FormatRulerLine_Write_Loc_3424
Console_FormatRulerLine_Write_Loc_3416:
	moveq    #$7e,d6                                     ; Initialize register d6 to constant $7e
	move.b   d6,(a0)+                                    ; Move register d6 to (a0)+
	move.b   d6,$9f(a0)                                  ; Move register d6 to $9f(a0)
	bsr.b    Afs_TestBlockAllocated                      ; Call subroutine to Afs_TestBlockAllocated
	beq.b    Console_FormatRulerLine_Write_Loc_3424      ; Branch to Console_FormatRulerLine_Write_Loc_3424 if zero / equal
	moveq    #BLTCON1,d6                                 ; Initialize register d6 to constant BLTCON1
Console_FormatRulerLine_Write_Loc_3424:
	move.b   d6,$4f(a0)                                  ; Move register d6 to $4f(a0)
	add.w    $17c6(a6),d0                                ; Add $17c6(a6) to register d0
	dbra     d3,Console_FormatRulerLine_Write_Loc_3416   ; Decrement loop counter d3 and loop back to Console_FormatRulerLine_Write_Loc_3416 if not exhausted
	lea.l    $f0(a0),a0                                  ; Load address of $f0(a0) into pointer a0
	cmp.w    $17c2(a6),d4                                ; Compare register d4 against $17c2(a6)
	bne.w    Console_FormatRulerLine_Write_Loc_3440      ; Branch to Console_FormatRulerLine_Write_Loc_3440 if non-zero / not equal
	lea.l    BLTBPTH(a0),a0                              ; Load address of BLTBPTH(a0) into pointer a0
Console_FormatRulerLine_Write_Loc_3440:
	dbra     d4,Console_FormatRulerLine_Write_Loc_33FC   ; Decrement loop counter d4 and loop back to Console_FormatRulerLine_Write_Loc_33FC if not exhausted
	move.w   $17c2(a6),d0                                ; Move $17c2(a6) to register d0
	add.b    d0,Var_CursorY(a6)                          ; Add register d0 to cursor vertical row coordinate
Console_FormatRulerLine_Write_Loc_344C:
	bsr.w    Disk_MotorOff                               ; Call subroutine to Disk_MotorOff
	st.b     d7
	rts                                                  ; Return from subroutine
Afs_TestBlockAllocated:
	move.l   a0,-(a7)                                    ; Move pointer a0 to -(a7)
	lea.l    $3694(a6),a0                                ; Load address of $3694(a6) into pointer a0
	move.l   d0,d1                                       ; Move register d0 to register d1
	lsr.w    #$5,d1
	add.w    d1,d1                                       ; Add register d1 to register d1
	add.w    d1,d1                                       ; Add register d1 to register d1
	move.l   $4(a0,d1.w),d2                              ; Move $4(a0,d1.w) to register d2
	btst     d0,d2                                       ; Test bit d0 of register d2
	movea.l  (a7)+,a0                                    ; Move (a7)+ to pointer a0
	rts                                                  ; Return from subroutine
Afs_BlockToCylinder:
	movem.l  d1/d4,-(a7)                                 ; Move multiple registers d1/d4 to -(a7)
	moveq    #$0,d0                                      ; Initialize register d0 to 0
Afs_BlockToCylinder_Loop:
	subq.l   #$1,d4                                      ; Subtract 1 from register d4
	bmi.b    Afs_BlockToCylinder_Exit                    ; Branch to Afs_BlockToCylinder_Exit if negative / minus
	beq.b    Afs_BlockToCylinder_Exit                    ; Branch to Afs_BlockToCylinder_Exit if zero / equal
	moveq    #$47,d1                                     ; Initialize register d1 to constant $47
Afs_BlockToCylinder_SubLoop:
	addq.w   #$1,d0                                      ; Add 1 to register d0
	subq.l   #$1,d4                                      ; Subtract 1 from register d4
	beq.b    Afs_BlockToCylinder_Exit                    ; Branch to Afs_BlockToCylinder_Exit if zero / equal
	dbra     d1,Afs_BlockToCylinder_SubLoop              ; Decrement loop counter d1 and loop back to Afs_BlockToCylinder_SubLoop if not exhausted
	bra.b    Afs_BlockToCylinder_Loop                    ; Unconditional branch to Afs_BlockToCylinder_Loop
Afs_BlockToCylinder_Exit:
	movem.l  (a7)+,d1/d4                                 ; Move multiple registers (a7)+ to d1/d4
	mulu.w   $17e4(a6),d0                          ; Multiply d0 by $17e4(a6).
	rts                                                  ; Return from subroutine
	movea.l  a5,a0                                       ; Move pointer a5 to pointer a0
	move.w   #$4f,d0                                     ; Move constant $4f to register d0
Afs_BlockToCylinder_Exit_Loc_3496:
	cmpi.b   #BLTDMOD,(a0)+                              ; Compare (a0)+ against constant BLTDMOD
	dbeq     d0,Afs_BlockToCylinder_Exit_Loc_3496                           ; Execute dbeq instruction
	move.b   d0,$1675(a6)                                ; Move register d0 to $1675(a6)
	clr.l    $162e(a6)                                   ; Clear / reset $162e(a6)
	sf.b     $1672(a6)                             ; Clear $1672(a6) flag (false).
	sf.b     $1673(a6)                             ; Clear $1673(a6) flag (false).
	bsr.w    Disk_PrepareDriveAndReadTrack               ; Call subroutine to Disk_PrepareDriveAndReadTrack
	bne.w    Afs_BlockToCylinder_Exit_Loc_366A           ; Branch to Afs_BlockToCylinder_Exit_Loc_366A if non-zero / not equal
	lea.l    $3294(a6),a3                                ; Load address of $3294(a6) into pointer a3
	lea.l    $199e(a6),a0                                ; Load address of $199e(a6) into pointer a0
	lea.l    Str_Volume(pc),a1                            ; Load address of Str_Volume(pc) into pointer a1
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	lea.l    $1b0(a3),a1                                 ; Load address of $1b0(a3) into pointer a1
	bsr.w    CopyBoundedString                           ; Call subroutine to CopyBoundedString
	move.b   #$22,(a0)                                   ; Move constant $22 to (a0)
	lea.l    $19c5(a6),a0                                ; Load address of $19c5(a6) into pointer a0
	bsr.w    Disk_PrintUsageInfo                         ; Call subroutine to Disk_PrintUsageInfo
	lea.l    Var_MonitorBufferOffset(a6),a4              ; Load address of Var_MonitorBufferOffset(a6) into pointer a4
	lea.l    $18(a3),a2                                  ; Load address of $18(a3) into pointer a2
	moveq    #$47,d2                                     ; Initialize register d2 to constant $47
Afs_BlockToCylinder_Exit_Loc_34E4:
	move.l   (a2)+,d5                                    ; Move (a2)+ to register d5
	beq.w    Afs_BlockToCylinder_Exit_Loc_3666           ; Branch to Afs_BlockToCylinder_Exit_Loc_3666 if zero / equal
Afs_BlockToCylinder_Exit_Loc_34EA:
	move.l   a4,d6                                       ; Move pointer a4 to register d6
	bsr.w    Disk_ReadWriteSector                        ; Call subroutine to Disk_ReadWriteSector
	tst.b    $1671(a6)                             ; Check if $1671 is set / active
	bne.w    Afs_BlockToCylinder_Exit_Loc_366A           ; Branch to Afs_BlockToCylinder_Exit_Loc_366A if non-zero / not equal
	move.b   #$3e,(a0)+                                  ; Move constant $3e to (a0)+
	addq.w   #$4,a0                                      ; Add constant $4 to pointer a0
	move.b   #$22,(a0)+                                  ; Move constant $22 to (a0)+
	lea.l    $1b0(a4),a1                                 ; Load address of $1b0(a4) into pointer a1
	bsr.w    CopyBoundedString                           ; Call subroutine to CopyBoundedString
	move.b   #$22,(a0)+                                  ; Move constant $22 to (a0)+
	lea.l    $19c2(a6),a0                                ; Load address of $19c2(a6) into pointer a0
	move.l   FMODE(a4),d3                                ; Move FMODE (AGA fetch mode control register) to register d3
	subq.l   #$2,d3                                      ; Subtract constant $2 from register d3
	beq.b    Afs_BlockToCylinder_Exit_Loc_3560           ; Branch to Afs_BlockToCylinder_Exit_Loc_3560 if zero / equal
	addq.l   #$5,d3                                      ; Add constant $5 to register d3
	beq.b    Afs_BlockToCylinder_Exit_Loc_3560           ; Branch to Afs_BlockToCylinder_Exit_Loc_3560 if zero / equal
	subq.l   #$7,d3                                      ; Subtract constant $7 from register d3
	lea.l    Str_Dirlink(pc),a1                            ; Load address of Str_Dirlink(pc) into pointer a1
	beq.b    Afs_BlockToCylinder_Exit_Loc_3530           ; Branch to Afs_BlockToCylinder_Exit_Loc_3530 if zero / equal
	addq.l   #$8,d3                                      ; Add constant $8 to register d3
	lea.l    Str_Hardlink(pc),a1                            ; Load address of Str_Hardlink(pc) into pointer a1
	bne.w    Afs_BlockToCylinder_Exit_Loc_366A           ; Branch to Afs_BlockToCylinder_Exit_Loc_366A if non-zero / not equal
Afs_BlockToCylinder_Exit_Loc_3530:
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	lea.l    $3694(a6),a1                                ; Load address of $3694(a6) into pointer a1
	move.l   a1,d6                                       ; Move pointer a1 to register d6
	move.l   $1d4(a4),d5                                 ; Move $1d4(a4) to register d5
	bsr.w    Disk_ReadWriteSector                        ; Call subroutine to Disk_ReadWriteSector
	tst.b    $1671(a6)                             ; Check if $1671 is set / active
	bne.w    Afs_BlockToCylinder_Exit_Loc_366A           ; Branch to Afs_BlockToCylinder_Exit_Loc_366A if non-zero / not equal
	lea.l    $3844(a6),a1                                ; Load address of $3844(a6) into pointer a1
	bsr.w    CopyBoundedString                           ; Call subroutine to CopyBoundedString
	move.b   #$22,(a0)                                   ; Move constant $22 to (a0)
	move.b   $37d7(a6),$143(a4)                          ; Move $37d7(a6) to $143(a4)
	bra.w    Afs_BlockToCylinder_Exit_Loc_35CC           ; Unconditional branch to Afs_BlockToCylinder_Exit_Loc_35CC
Afs_BlockToCylinder_Exit_Loc_3560:
	lea.l    $148(a4),a1                                 ; Load address of $148(a4) into pointer a1
	bsr.w    CopyBoundedString                           ; Call subroutine to CopyBoundedString
	lea.l    $19c2(a6),a0                                ; Load address of $19c2(a6) into pointer a0
	cmpi.b   #$24,(a0)                                   ; Compare (a0) against constant $24
	bne.b    Afs_BlockToCylinder_Exit_Loc_357E           ; Branch to Afs_BlockToCylinder_Exit_Loc_357E if non-zero / not equal
	moveq    #$20,d0                                     ; Initialize register d0 to constant $20
	move.b   d0,(a0)                                     ; Move register d0 to (a0)
	move.b   d0,$9(a0)                                   ; Move register d0 to $9(a0)
	move.b   d0,$a(a0)                                   ; Move register d0 to $a(a0)
Afs_BlockToCylinder_Exit_Loc_357E:
	lea.l    $19d8(a6),a0                                ; Load address of $19d8(a6) into pointer a0
	move.l   FMODE(a4),d3                                ; Move FMODE (AGA fetch mode control register) to register d3
	moveq    #-3,d0                                      ; Initialize register d0 to constant -3
	cmp.l    d0,d3                                       ; Compare register d3 against register d0
	bne.b    Afs_BlockToCylinder_Exit_Loc_35BE           ; Branch to Afs_BlockToCylinder_Exit_Loc_35BE if non-zero / not equal
	move.l   $144(a4),d0                                 ; Move $144(a4) to register d0
	bsr.w    PrintHex6                                   ; Call subroutine to PrintHex6
	addq.w   #$1,a0                                      ; Add 1 to pointer a0
	bsr.w    FormatDecimal32Bit                          ; Call subroutine to FormatDecimal32Bit
	lea.l    $19e7(a6),a0                                ; Load address of $19e7(a6) into pointer a0
	tst.l    d0                                          ; Test status of register d0 (for zero or negative)
	beq.b    Afs_BlockToCylinder_Exit_Loc_35B6           ; Branch to Afs_BlockToCylinder_Exit_Loc_35B6 if zero / equal
	subq.l   #$1,d0                                      ; Subtract 1 from register d0
	divu.w   $17e4(a6),d0                          ; Divide d0 by $17e4(a6).
	move.w   d0,d3                                       ; Move register d0 to register d3
	ext.l    d3
	beq.b    Afs_BlockToCylinder_Exit_Loc_35B4           ; Branch to Afs_BlockToCylinder_Exit_Loc_35B4 if zero / equal
	divu.w   #$48,d3
	add.w    d3,d0                                       ; Add register d3 to register d0
Afs_BlockToCylinder_Exit_Loc_35B4:
	addq.w   #$1,d0                                      ; Add 1 to register d0
Afs_BlockToCylinder_Exit_Loc_35B6:
	addq.w   #$1,d0                                      ; Add 1 to register d0
	ext.l    d0
	bsr.w    FormatDecimal32Bit                          ; Call subroutine to FormatDecimal32Bit
Afs_BlockToCylinder_Exit_Loc_35BE:
	moveq    #$2,d0                                      ; Initialize register d0 to constant $2
	cmp.l    d0,d3                                       ; Compare register d3 against register d0
	bne.b    Afs_BlockToCylinder_Exit_Loc_35CC           ; Branch to Afs_BlockToCylinder_Exit_Loc_35CC if non-zero / not equal
	lea.l    Str_Dir(pc),a1                            ; Load address of Str_Dir(pc) into pointer a1
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
Afs_BlockToCylinder_Exit_Loc_35CC:
	bsr.w    RefreshAndDrawConsoleLine                   ; Call subroutine to RefreshAndDrawConsoleLine
	tst.b    $1675(a6)                             ; Check if $1675 is set / active
	bmi.w    Afs_BlockToCylinder_Exit_Loc_3658           ; Branch to Afs_BlockToCylinder_Exit_Loc_3658 if negative / minus
	lea.l    Var_DisasmBuffer+1(a6),a0                   ; Load address of disassembler output text buffer into pointer a0
	move.l   $1a4(a4),d0                                 ; Move $1a4(a4) to register d0
	bsr.w    Rtc_DecodeBcdByte_Loc_3824                  ; Call subroutine to Rtc_DecodeBcdByte_Loc_3824
	lea.l    Var_DisasmBuffer+25(a6),a0                  ; Load address of disassembler output text buffer into pointer a0
	move.l   $1a8(a4),d0                                 ; Move $1a8(a4) to register d0
	divu.w   #$3c,d0
	bsr.w    FormatDecimal2Digit                         ; Call subroutine to FormatDecimal2Digit
	swap     d0
	move.b   #$3a,(a0)+                                  ; Move constant $3a to (a0)+
	bsr.w    FormatDecimal2Digit                         ; Call subroutine to FormatDecimal2Digit
	move.l   $1ac(a4),d0                                 ; Move $1ac(a4) to register d0
	divu.w   #$32,d0
	move.b   #$3a,(a0)+                                  ; Move constant $3a to (a0)+
	bsr.w    FormatDecimal2Digit                         ; Call subroutine to FormatDecimal2Digit
	lea.l    $19be(a6),a0                                ; Load address of $19be(a6) into pointer a0
	move.b   $143(a4),d0                                 ; Move $143(a4) to register d0
	eori.b   #$f,d0                                      ; Logical XOR register d0 with constant $f
	move.l   #$68737061,d3                               ; Move constant $68737061 to register d3
	bsr.w    Afs_FormatProtectionBits                    ; Call subroutine to Afs_FormatProtectionBits
	move.l   #$72776564,d3                               ; Move constant $72776564 to register d3
	bsr.w    Afs_FormatProtectionBits                    ; Call subroutine to Afs_FormatProtectionBits
	lea.l    Var_DisasmBuffer+43(a6),a0                  ; Load address of disassembler output text buffer into pointer a0
	move.l   $4(a4),d0                                   ; Move $4(a4) to register d0
	bsr.w    PrintHex8                                   ; Call subroutine to PrintHex8
	addq.w   #$1,a0                                      ; Add 1 to pointer a0
	move.l   $1f8(a4),d0                                 ; Move $1f8(a4) to register d0
	beq.b    Afs_BlockToCylinder_Exit_Loc_3646           ; Branch to Afs_BlockToCylinder_Exit_Loc_3646 if zero / equal
	bsr.w    PrintHex8                                   ; Call subroutine to PrintHex8
Afs_BlockToCylinder_Exit_Loc_3646:
	move.l   $10(a4),d0                                  ; Move $10(a4) to register d0
	beq.b    Afs_BlockToCylinder_Exit_Loc_3654           ; Branch to Afs_BlockToCylinder_Exit_Loc_3654 if zero / equal
	lea.l    $19db(a6),a0                                ; Load address of $19db(a6) into pointer a0
	bsr.w    PrintHex8                                   ; Call subroutine to PrintHex8
Afs_BlockToCylinder_Exit_Loc_3654:
	bsr.w    RefreshAndDrawConsoleLine                   ; Call subroutine to RefreshAndDrawConsoleLine
Afs_BlockToCylinder_Exit_Loc_3658:
	bsr.w    WaitInputOrButton                           ; Call subroutine to WaitInputOrButton
	beq.b    Afs_BlockToCylinder_Exit_Loc_366A           ; Branch to Afs_BlockToCylinder_Exit_Loc_366A if zero / equal
	move.l   $1f0(a4),d5                                 ; Move $1f0(a4) to register d5
	bne.w    Afs_BlockToCylinder_Exit_Loc_34EA           ; Branch to Afs_BlockToCylinder_Exit_Loc_34EA if non-zero / not equal
Afs_BlockToCylinder_Exit_Loc_3666:
	dbra     d2,Afs_BlockToCylinder_Exit_Loc_34E4        ; Decrement loop counter d2 and loop back to Afs_BlockToCylinder_Exit_Loc_34E4 if not exhausted
Afs_BlockToCylinder_Exit_Loc_366A:
	bsr.w    Disk_MotorOff                               ; Call subroutine to Disk_MotorOff
	st.b     d7
	rts                                                  ; Return from subroutine
Disk_CountFreeSectors:
	lea.l    $3698(a6),a1                                ; Load address of $3698(a6) into pointer a1
	moveq    #$0,d0                                      ; Initialize register d0 to 0
	move.l   $17ba(a6),d2                                ; Move $17ba(a6) to register d2
	subq.l   #$2,d2                                      ; Subtract constant $2 from register d2
Disk_CountFreeSectors_WordLoop:
	move.l   (a1)+,d3                                    ; Move (a1)+ to register d3
	moveq    #$0,d1                                      ; Initialize register d1 to 0
Disk_CountFreeSectors_BitLoop:
	btst     d1,d3                                       ; Test bit d1 of register d3
	bne.b    Disk_CountFreeSectors_Next                  ; Branch to Disk_CountFreeSectors_Next if non-zero / not equal
	addq.l   #$1,d0                                      ; Add 1 to register d0
Disk_CountFreeSectors_Next:
	subq.l   #$1,d2                                      ; Subtract 1 from register d2
	bmi.b    Disk_CountFreeSectors_Exit                  ; Branch to Disk_CountFreeSectors_Exit if negative / minus
	addq.w   #$1,d1                                      ; Add 1 to register d1
	cmpi.b   #$20,d1                                     ; Compare register d1 against constant $20
	bne.b    Disk_CountFreeSectors_BitLoop               ; Branch to Disk_CountFreeSectors_BitLoop if non-zero / not equal
	bra.b    Disk_CountFreeSectors_WordLoop              ; Unconditional branch to Disk_CountFreeSectors_WordLoop
Disk_CountFreeSectors_Exit:
	move.l   $17ba(a6),d4                                ; Move $17ba(a6) to register d4
	subi.l   #$1,d4                                      ; Subtract 1 from register d4
	sub.l    d0,d4                                       ; Subtract register d0 from register d4
	rts                                                  ; Return from subroutine
Disk_PrintUsageInfo:
	bsr.b    Disk_CountFreeSectors                       ; Call subroutine to Disk_CountFreeSectors
	addq.w   #$2,a0                                      ; Add constant $2 to pointer a0
	bsr.w    FormatDecimal32Bit                          ; Call subroutine to FormatDecimal32Bit
	lea.l    Str_UsedBlocks(pc),a1                            ; Load address of Str_UsedBlocks(pc) into pointer a1
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	move.l   d4,d0                                       ; Move register d4 to register d0
	bsr.w    FormatDecimal32Bit                          ; Call subroutine to FormatDecimal32Bit
	lea.l    Str_FreeBlocks(pc),a1                            ; Load address of Str_FreeBlocks(pc) into pointer a1
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	bra.w    RefreshAndDrawConsoleLine                   ; Unconditional branch to RefreshAndDrawConsoleLine
Afs_FormatProtectionBits:
	moveq    #$3,d1                                      ; Initialize register d1 to constant $3
Afs_FormatProtectionBits_Loop:
	rol.l    #$8,d3
	add.b    d0,d0                                       ; Add register d0 to register d0
	bcs.b    Afs_FormatProtectionBits_Next               ; Branch to Afs_FormatProtectionBits_Next if carry set (less than)
	move.b   #$2d,d3                                     ; Move constant $2d to register d3
Afs_FormatProtectionBits_Next:
	move.b   d3,(a0)+                                    ; Move register d3 to (a0)+
	dbra     d1,Afs_FormatProtectionBits_Loop            ; Decrement loop counter d1 and loop back to Afs_FormatProtectionBits_Loop if not exhausted
	rts                                                  ; Return from subroutine
Rtc_InitAndTest:
	movem.l  d0-d3/a0-a1,-(a7)                           ; Move multiple registers d0-d3/a0-a1 to -(a7)
	clr.l    $1814(a6)                                   ; Clear / reset $1814(a6)
	clr.l    $1818(a6)                                   ; Clear / reset $1818(a6)
	clr.l    $181c(a6)                                   ; Clear / reset $181c(a6)
	lea.l    $dc0000.l,a0                                ; Load address of $dc0000.l into pointer a0
	moveq    #$f,d1                                      ; Initialize register d1 to constant $f
	move.b   $3f(a0),d0                                  ; Move $3f(a0) to register d0
	and.b    d1,d0                                       ; Logical AND register d0 with register d1
	subq.b   #$4,d0                                      ; Subtract constant $4 from register d0
	beq.b    Rtc_InitAndTest_Loc_3742                    ; Branch to Rtc_InitAndTest_Loc_3742 if zero / equal
	clr.b    $3f(a0)                                     ; Clear / reset $3f(a0)
	clr.b    $3b(a0)                                     ; Clear / reset $3b(a0)
	move.b   #$9,$37(a0)                                 ; Move constant $9 to $37(a0)
	move.b   #$5,$33(a0)                                 ; Move constant $5 to $33(a0)
	move.b   $33(a0),d0                                  ; Move $33(a0) to register d0
	and.b    d1,d0                                       ; Logical AND register d0 with register d1
	bne.b    Rtc_InitAndTest_Loc_3768                    ; Branch to Rtc_InitAndTest_Loc_3768 if non-zero / not equal
	move.b   $37(a0),d0                                  ; Move $37(a0) to register d0
	and.b    d1,d0                                       ; Logical AND register d0 with register d1
	cmpi.b   #$9,d0                                      ; Compare register d0 against constant $9
	bne.b    Rtc_InitAndTest_Loc_3768                    ; Branch to Rtc_InitAndTest_Loc_3768 if non-zero / not equal
	move.b   $2b(a0),d0                                  ; Move $2b(a0) to register d0
	btst     #$0,d0                                      ; Test bit #$0 of register d0
	beq.b    Rtc_InitAndTest_Loc_3768                    ; Branch to Rtc_InitAndTest_Loc_3768 if zero / equal
	sf.b     $37(a0)                               ; Clear $37(a0) flag (false).
	moveq    #$4,d0                                      ; Initialize register d0 to constant $4
	lea.l    POTGPTR(a0),a0                              ; Load address of POTGPTR (potentiometer port status register) into pointer a0
	bsr.b    Rtc_ReadDateTime                            ; Call subroutine to Rtc_ReadDateTime
	move.b   #$9,$37(a0)                                 ; Move constant $9 to $37(a0)
	bra.b    Rtc_InitAndTest_Loc_3768                    ; Unconditional branch to Rtc_InitAndTest_Loc_3768
Rtc_InitAndTest_Loc_3742:
	moveq    #$1,d0                                      ; Initialize register d0 to 1
	move.w   #$190,d1                                    ; Move constant $190 to register d1
Rtc_InitAndTest_Loc_3748:
	move.b   d0,$37(a0)                                  ; Move register d0 to $37(a0)
	btst     d0,$37(a0)                                  ; Test bit d0 of $37(a0)
	beq.b    Rtc_InitAndTest_Loc_375C                    ; Branch to Rtc_InitAndTest_Loc_375C if zero / equal
	sf.b     $37(a0)                               ; Clear $37(a0) flag (false).
	dbra     d1,Rtc_InitAndTest_Loc_3748                 ; Decrement loop counter d1 and loop back to Rtc_InitAndTest_Loc_3748 if not exhausted
	bra.b    Rtc_InitAndTest_Loc_3768                    ; Unconditional branch to Rtc_InitAndTest_Loc_3768
Rtc_InitAndTest_Loc_375C:
	moveq    #$0,d0                                      ; Initialize register d0 to 0
	lea.l    $30(a0),a0                                  ; Load address of $30(a0) into pointer a0
	bsr.b    Rtc_ReadDateTime                            ; Call subroutine to Rtc_ReadDateTime
	sf.b     $37(a0)                               ; Clear $37(a0) flag (false).
Rtc_InitAndTest_Loc_3768:
	movem.l  (a7)+,d0-d3/a0-a1                           ; Move multiple registers (a7)+ to d0-d3/a0-a1
	rts                                                  ; Return from subroutine
Rtc_ReadDateTime:
	bsr.b    Rtc_DecodeBcdByte                           ; Call subroutine to Rtc_DecodeBcdByte
	subi.w   #$4e,d2                                     ; Subtract constant $4e from register d2
	bcc.w    Rtc_ReadDateTime_YearOk                     ; Branch to Rtc_ReadDateTime_YearOk if carry clear (greater or equal)
	addi.w   #BLTAMOD,d2                                 ; Add constant BLTAMOD to register d2
Rtc_ReadDateTime_YearOk:
	move.l   d2,d3                                       ; Move register d2 to register d3
	mulu.w   #$16d,d3                              ; Multiply d3 by constant $16d.
	addq.l   #$1,d2                                      ; Add 1 to register d2
	divu.w   #$4,d2
	add.w    d2,d3                                       ; Add register d2 to register d3
	swap     d2
	move.b   #$1c,$16b7(a6)                              ; Move constant $1c to $16b7(a6)
	cmpi.b   #$3,d2                                      ; Compare register d2 against constant $3
	bne.b    Rtc_ReadDateTime_MonthLoopStart             ; Branch to Rtc_ReadDateTime_MonthLoopStart if non-zero / not equal
	addq.b   #$1,$16b7(a6)                               ; Add 1 to $16b7(a6)
Rtc_ReadDateTime_MonthLoopStart:
	lea.l    $16b6(a6),a1                                ; Load address of $16b6(a6) into pointer a1
	bsr.b    Rtc_DecodeBcdByte                           ; Call subroutine to Rtc_DecodeBcdByte
Rtc_ReadDateTime_MonthLoop:
	subq.b   #$1,d2                                      ; Subtract 1 from register d2
	beq.b    Rtc_ReadDateTime_HourMinSec                 ; Branch to Rtc_ReadDateTime_HourMinSec if zero / equal
	move.b   (a1)+,d1                                    ; Move (a1)+ to register d1
	add.w    d1,d3                                       ; Add register d1 to register d3
	bra.w    Rtc_ReadDateTime_MonthLoop                  ; Unconditional branch to Rtc_ReadDateTime_MonthLoop
Rtc_ReadDateTime_HourMinSec:
	bsr.b    Rtc_DecodeBcdByte                           ; Call subroutine to Rtc_DecodeBcdByte
	subq.l   #$1,d2                                      ; Subtract 1 from register d2
	add.w    d2,d3                                       ; Add register d2 to register d3
	move.l   d3,$1814(a6)                                ; Move register d3 to $1814(a6)
	suba.w   d0,a0                                       ; Subtract register d0 from pointer a0
	bsr.b    Rtc_DecodeBcdByte                           ; Call subroutine to Rtc_DecodeBcdByte
	divu.w   #$28,d2
	clr.w    d2                                          ; Clear / reset register d2
	swap     d2
	move.l   d2,d3                                       ; Move register d2 to register d3
	lsl.l    #$4,d3
	sub.l    d2,d3                                       ; Subtract register d2 from register d3
	lsl.l    #$2,d3
	bsr.b    Rtc_DecodeBcdByte                           ; Call subroutine to Rtc_DecodeBcdByte
	add.l    d2,d3                                       ; Add register d2 to register d3
	move.l   d3,$1818(a6)                                ; Move register d3 to $1818(a6)
	bsr.b    Rtc_DecodeBcdByte                           ; Call subroutine to Rtc_DecodeBcdByte
	mulu.w   #$32,d2
	move.l   d2,$181c(a6)                                ; Move register d2 to $181c(a6)
	rts                                                  ; Return from subroutine
Rtc_DecodeBcdByte:
	moveq    #$f,d1                                      ; Initialize register d1 to constant $f
	and.l    -(a0),d1                                    ; Logical AND register d1 with -(a0)
	moveq    #$f,d2                                      ; Initialize register d2 to constant $f
	and.l    -(a0),d2                                    ; Logical AND register d2 with -(a0)
	add.l    d1,d2                                       ; Add register d1 to register d2
	add.l    d1,d2                                       ; Add register d1 to register d2
	lsl.l    #$3,d1
	add.l    d1,d2                                       ; Add register d1 to register d2
	rts                                                  ; Return from subroutine
; ============================================================================
; Data Block: Str_WeekdaysTable
; Purpose   : String literal lookup table of weekdays.
; ============================================================================
Str_WeekdaysTable:
	dc.b     "Sunda",$F9                           ; String literal data
	dc.b     "Monda",$F9                           ; String literal data
	dc.b     "Tuesda",$F9                          ; String literal data
	dc.b     "Wednesda",$F9                        ; String literal data
	dc.b     "Thursda",$F9                         ; String literal data
	dc.b     "Frida",$F9                           ; String literal data
	dc.b     "Saturda",$F9                         ; String literal data
Rtc_DecodeBcdByte_Loc_3824:
	movem.l  d0-d4,-(a7)                                 ; Move multiple registers d0-d4 to -(a7)
	move.l   d0,d4                                       ; Move register d0 to register d4
	lea.l    $6f0f.w,a1                                  ; Load address of $6f0f.w into pointer a1
	add.l    a1,d0                                       ; Add pointer a1 to register d0
	lsl.l    #$2,d0
	move.l   d0,d2                                       ; Move register d0 to register d2
	subq.l   #$1,d2                                      ; Subtract 1 from register d2
	divu.w   #$5b5,d2                              ; Divide d2 by constant $5b5.
	andi.l   #$ffff,d2                                   ; Logical AND register d2 with constant $ffff
	addq.l   #$3,d0                                      ; Add constant $3 to register d0
	move.l   d2,d3                                       ; Move register d2 to register d3
	mulu.w   #$5b5,d3                              ; Multiply d3 by constant $5b5.
	sub.l    d3,d0                                       ; Subtract register d3 from register d0
	lsr.l    #$2,d0
	move.l   d0,d3                                       ; Move register d0 to register d3
	lsl.l    #$2,d0
	add.l    d3,d0                                       ; Add register d3 to register d0
	move.l   d0,d1                                       ; Move register d0 to register d1
	subq.l   #$3,d1                                      ; Subtract constant $3 from register d1
	divu.w   #$99,d1
	andi.l   #$ffff,d1                                   ; Logical AND register d1 with constant $ffff
	addq.l   #$2,d0                                      ; Add constant $2 to register d0
	move.l   d1,d3                                       ; Move register d1 to register d3
	mulu.w   #$99,d3
	sub.l    d3,d0                                       ; Subtract register d3 from register d0
	divu.w   #$5,d0
	andi.l   #$ffff,d0                                   ; Logical AND register d0 with constant $ffff
	moveq    #$a,d3                                      ; Initialize register d3 to constant $a
	cmp.l    d3,d1                                       ; Compare register d1 against register d3
	bge.b    Rtc_DecodeBcdByte_Loc_387E                  ; Branch to Rtc_DecodeBcdByte_Loc_387E if greater or equal
	addq.l   #$3,d1                                      ; Add constant $3 to register d1
	bra.b    Rtc_DecodeBcdByte_Loc_3884                  ; Unconditional branch to Rtc_DecodeBcdByte_Loc_3884
Rtc_DecodeBcdByte_Loc_387E:
	subq.l   #$8,d1                                      ; Subtract constant $8 from register d1
	subq.l   #$1,d1                                      ; Subtract 1 from register d1
	addq.l   #$1,d2                                      ; Add 1 to register d2
Rtc_DecodeBcdByte_Loc_3884:
	bsr.w    FormatDecimal2Digit                         ; Call subroutine to FormatDecimal2Digit
	lea.l    Str_MonthsTable(pc),a1                            ; Load address of Str_MonthsTable(pc) into pointer a1
	move.w   d1,d0                                       ; Move register d1 to register d0
	add.w    d0,d0                                       ; Add register d0 to register d0
	add.w    d1,d0                                       ; Add register d1 to register d0
	lea.l    -$3(a1,d0.w),a1                             ; Load address of -$3(a1,d0.w) into pointer a1
	move.b   #$2d,(a0)+                                  ; Move constant $2d to (a0)+
	move.b   (a1)+,(a0)+                                 ; Copy word/byte data from source pointer a1 to destination a0
	move.b   (a1)+,(a0)+                                 ; Copy word/byte data from source pointer a1 to destination a0
	move.b   (a1)+,(a0)+                                 ; Copy word/byte data from source pointer a1 to destination a0
	move.b   #$2d,(a0)+                                  ; Move constant $2d to (a0)+
	move.l   d2,d0                                       ; Move register d2 to register d0
	addi.w   #$76c,d0                                    ; Add constant $76c to register d0
	bsr.w    FormatDecimal3Digit                         ; Call subroutine to FormatDecimal3Digit
	addq.w   #$1,a0                                      ; Add 1 to pointer a0
	move.b   #$5b,(a0)+                                  ; Move constant $5b to (a0)+
	divu.w   #$7,d4
	swap     d4
	move.w   d4,d0                                       ; Move register d4 to register d0
	lea.l    Str_WeekdaysTable(pc),a1                            ; Load address of Str_WeekdaysTable(pc) into pointer a1
	cmpi.b   #$6,d0                                      ; Compare register d0 against constant $6
	bsr.w    StringTable_Lookup                          ; Call subroutine to StringTable_Lookup
	move.b   #$5d,(a0)+                                  ; Move constant $5d to (a0)+
	movem.l  (a7)+,d0-d4                                 ; Move multiple registers (a7)+ to d0-d4
	rts                                                  ; Return from subroutine
	cmpi.b   #$1,d3                                      ; Compare register d3 against 1
	bhi.w    Disk_CheckAndMount_Rts                              ; Branch to Disk_CheckAndMount_Rts if higher.
	tst.b    d3                                          ; Test status of register d3 (for zero or negative)
	beq.b    Disk_CheckAndMount_Retry                    ; Branch to Disk_CheckAndMount_Retry if zero / equal
	move.l   Var_MemStart(a6),d0                         ; Load monitored memory start offset into register d0
	moveq    #$3,d1                                      ; Initialize register d1 to constant $3
	cmp.l    d1,d0                                       ; Compare register d0 against register d1
	bhi.w    Disk_CheckAndMount_Rts                              ; Branch to Disk_CheckAndMount_Rts if higher.
	addq.b   #$3,d0                                      ; Add constant $3 to register d0
	move.b   d0,Var_MonitorFlag_166c(a6)                 ; Store register d0 into Var_MonitorFlag_166c(a6)
Disk_CheckAndMount_Retry:
	bsr.b    Disk_CheckAndMount                          ; Call subroutine to Disk_CheckAndMount
	st.b     d7
Disk_CheckAndMount_Rts:
	rts                                                  ; Return from subroutine
Disk_CheckAndMount_ChangeDrive:
	move.b   d0,Var_MonitorFlag_166c(a6)                 ; Store register d0 into Var_MonitorFlag_166c(a6)
Disk_CheckAndMount:
	lea.l    Var_DisasmBuffer(a6),a0                     ; Load address of disassembler output text buffer into pointer a0
	bsr.w    Print_SavingPrefix                          ; Call subroutine to Print_SavingPrefix
	bsr.b    Disk_SelectDrive                            ; Call subroutine to Disk_SelectDrive
	lea.l    Str_Logged(pc),a1                            ; Load address of Str_Logged(pc) into pointer a1
	not.l    d4
	bne.b    Disk_CheckAndMount_Print                    ; Branch to Disk_CheckAndMount_Print if non-zero / not equal
	cmpi.b   #$3,d1                                      ; Compare register d1 against constant $3
	seq.b    d4
	beq.b    Disk_CheckAndMount_Print                    ; Branch to Disk_CheckAndMount_Print if zero / equal
	lea.l    Str_NotMounted(pc),a1                            ; Load address of Str_NotMounted(pc) into pointer a1
Disk_CheckAndMount_Print:
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	bsr.w    RefreshAndDrawConsoleLine                   ; Call subroutine to RefreshAndDrawConsoleLine
	tst.l    d4                                          ; Test status of register d4 (for zero or negative)
	bne.b    Disk_CheckAndMount_Success                  ; Branch to Disk_CheckAndMount_Success if non-zero / not equal
	moveq    #$3,d0                                      ; Initialize register d0 to constant $3
	cmp.b    Var_MonitorFlag_166c(a6),d0                 ; Compare register d0 against Var_MonitorFlag_166c(a6)
	bne.b    Disk_CheckAndMount_ChangeDrive              ; Branch to Disk_CheckAndMount_ChangeDrive if non-zero / not equal
Disk_CheckAndMount_Success:
	clr.l    $17f6(a6)                                   ; Clear / reset $17f6(a6)
	move.l   $17b6(a6),$17d2(a6)                         ; Move $17b6(a6) to $17d2(a6)
	sf.b     Var_MonitorFlag_1670(a6)              ; Clear Var_MonitorFlag_1670(a6) flag (false).
	rts                                                  ; Return from subroutine
Disk_SelectDrive:
	lea.l    CIAB_PRB.l,a1                               ; Load address of CIAB_PRB (CIA-B Port B data/control register) into pointer a1
	st.b     (a1)
	move.b   Var_MonitorFlag_166c(a6),d1                 ; Load Var_MonitorFlag_166c(a6) into register d1
	moveq    #$7,d3                                      ; Initialize register d3 to constant $7
	bclr     d3,(a1)                                     ; Clear bit d3 of (a1)
	bsr.b    Disk_MicroDelay                             ; Call subroutine to Disk_MicroDelay
	bclr     d1,(a1)                                     ; Clear bit d1 of (a1)
	bsr.b    Disk_MicroDelay                             ; Call subroutine to Disk_MicroDelay
	bset     d1,(a1)                                     ; Set bit d1 of (a1)
	bsr.b    Disk_MicroDelay                             ; Call subroutine to Disk_MicroDelay
	bset     d3,(a1)                                     ; Set bit d3 of (a1)
	bsr.b    Disk_MicroDelay                             ; Call subroutine to Disk_MicroDelay
	bclr     d1,(a1)                                     ; Clear bit d1 of (a1)
	bsr.b    Disk_MicroDelay                             ; Call subroutine to Disk_MicroDelay
	bset     d1,(a1)                                     ; Set bit d1 of (a1)
	moveq    #$1f,d3                                     ; Initialize register d3 to constant $1f
Disk_SelectDrive_Loc_3962:
	bclr     d1,(a1)                                     ; Clear bit d1 of (a1)
	bsr.b    Disk_MicroDelay                             ; Call subroutine to Disk_MicroDelay
	move.b   $f01(a1),d2                                 ; Move $f01(a1) to register d2
	lsl.b    #$3,d2
	roxl.l   #$1,d4
	bset     d1,(a1)                                     ; Set bit d1 of (a1)
	dbra     d3,Disk_SelectDrive_Loc_3962                ; Decrement loop counter d3 and loop back to Disk_SelectDrive_Loc_3962 if not exhausted
	move.w   #$18d0,$17b4(a6)                            ; Move constant $18d0 to $17b4(a6)
	moveq    #$b,d3                                      ; Initialize register d3 to constant $b
	cmpi.l   #$aaaaaaaa,d4                               ; Compare register d4 against constant $aaaaaaaa
	seq.b    Var_MonitorFlag_166f(a6)              ; Execute seq.b instruction
	bne.b    Disk_SelectDrive_Loc_3990                   ; Branch to Disk_SelectDrive_Loc_3990 if non-zero / not equal
	move.w   #$31c0,$17b4(a6)                            ; Move constant $31c0 to $17b4(a6)
	add.l    d3,d3                                       ; Add register d3 to register d3
Disk_SelectDrive_Loc_3990:
	move.w   d3,$17c2(a6)                                ; Move register d3 to $17c2(a6)
	subq.w   #$1,d3                                      ; Subtract 1 from register d3
	move.w   d3,$17c4(a6)                                ; Move register d3 to $17c4(a6)
	addq.w   #$1,d3                                      ; Add 1 to register d3
	add.l    d3,d3                                       ; Add register d3 to register d3
	move.w   d3,$17c6(a6)                                ; Move register d3 to $17c6(a6)
	subq.w   #$1,d3                                      ; Subtract 1 from register d3
	move.w   d3,$17c8(a6)                                ; Move register d3 to $17c8(a6)
	addq.w   #$1,d3                                      ; Add 1 to register d3
	mulu.w   #$28,d3
	move.l   d3,$17b6(a6)                                ; Move register d3 to $17b6(a6)
	add.l    d3,d3                                       ; Add register d3 to register d3
	subq.l   #$1,d3                                      ; Subtract 1 from register d3
	move.l   d3,$17ba(a6)                                ; Move register d3 to $17ba(a6)
	subq.l   #$1,d3                                      ; Subtract 1 from register d3
	move.l   d3,$17be(a6)                                ; Move register d3 to $17be(a6)
	rts                                                  ; Return from subroutine
Disk_MicroDelay:
	nop                                                  ; No operation (timing delay)
	nop                                                  ; No operation (timing delay)
	rts                                                  ; Return from subroutine
Disk_SelectDriveAndMotorOn:
	movem.l  d1-d4,-(a7)                                 ; Move multiple registers d1-d4 to -(a7)
	bsr.w    Disk_SelectDrive                            ; Call subroutine to Disk_SelectDrive
	lea.l    CIAB_PRB.l,a1                               ; Load address of CIAB_PRB (CIA-B Port B data/control register) into pointer a1
	bclr     #$7,(a1)                                    ; Clear bit #$7 of (a1)
	bset     #$0,(a1)                                    ; Set bit #$0 of (a1)
	move.b   Var_MonitorFlag_166c(a6),d0                 ; Load Var_MonitorFlag_166c(a6) into register d0
	bclr     d0,(a1)                                     ; Clear bit d0 of (a1)
	movem.l  (a7)+,d1-d4                                 ; Move multiple registers (a7)+ to d1-d4
	rts                                                  ; Return from subroutine
Disk_MotorOff:
	lea.l    CIAB_PRB.l,a1                               ; Load address of CIAB_PRB (CIA-B Port B data/control register) into pointer a1
	bset     #$7,(a1)                                    ; Set bit #$7 of (a1)
	bsr.b    Disk_MicroDelay                             ; Call subroutine to Disk_MicroDelay
	ori.b    #$78,(a1)                                   ; Logical OR (a1) with constant $78
	bsr.b    Disk_MicroDelay                             ; Call subroutine to Disk_MicroDelay
	andi.b   #$87,(a1)                                   ; Logical AND (a1) with constant $87
	bsr.b    Disk_MicroDelay                             ; Call subroutine to Disk_MicroDelay
	ori.b    #$78,(a1)                                   ; Logical OR (a1) with constant $78
	rts                                                  ; Return from subroutine
Disk_WaitReady:
	move.w   #$5dc,d0                                    ; Move constant $5dc to register d0
Disk_WaitReady_Loc_3A0C:
	bsr.w    DiskDma_WaitIndexOrTimeout                  ; Call subroutine to DiskDma_WaitIndexOrTimeout
	subq.w   #$1,d0                                      ; Subtract 1 from register d0
	beq.b    Disk_WaitReady_Loc_3A1E                     ; Branch to Disk_WaitReady_Loc_3A1E if zero / equal
	btst     #$5,CIAA_PRA.l                              ; Test bit #$5 of CIAA_PRA (CIA-A Port A status register)
	bne.b    Disk_WaitReady_Loc_3A0C                     ; Branch to Disk_WaitReady_Loc_3A0C if non-zero / not equal
Disk_WaitReady_Loc_3A1E:
	rts                                                  ; Return from subroutine
Disk_SeekTrack0:
	movem.l  d0-d1/a0-a1,-(a7)                           ; Move multiple registers d0-d1/a0-a1 to -(a7)
	bsr.b    Disk_WaitReady                              ; Call subroutine to Disk_WaitReady
	moveq    #$65,d0                                     ; Initialize register d0 to constant $65
	moveq    #$0,d1                                      ; Initialize register d1 to 0
	lea.l    CIAB_PRB.l,a1                               ; Load address of CIAB_PRB (CIA-B Port B data/control register) into pointer a1
Disk_SeekTrack0_Loc_3A30:
	btst     #$4,$f01(a1)                                ; Test bit #$4 of $f01(a1)
	beq.b    Disk_SeekTrack0_Loc_3A4E                    ; Branch to Disk_SeekTrack0_Loc_3A4E if zero / equal
	addq.w   #$1,d1                                      ; Add 1 to register d1
	bsr.b    Disk_StepIn                                 ; Call subroutine to Disk_StepIn
	dbra     d0,Disk_SeekTrack0_Loc_3A30                 ; Decrement loop counter d0 and loop back to Disk_SeekTrack0_Loc_3A30 if not exhausted
	lea.l    Str_SeekError(pc),a1                            ; Load address of Str_SeekError(pc) into pointer a1
	bsr.w    PrintString                                 ; Call subroutine to PrintString
	move.b   #$1e,$1671(a6)                              ; Move constant $1e to $1671(a6)
Disk_SeekTrack0_Loc_3A4E:
	lea.l    $17f7(a6),a1                                ; Load address of $17f7(a6) into pointer a1
	move.b   Var_MonitorFlag_166c(a6),d0                 ; Load Var_MonitorFlag_166c(a6) into register d0
	ext.w    d0
	adda.w   d0,a1                                       ; Add register d0 to pointer a1
	tst.b    (a1)                                        ; Test status of (a1) (for zero or negative)
	bpl.b    Disk_SeekTrack0_Loc_3A60                    ; Branch to Disk_SeekTrack0_Loc_3A60 if positive / plus
	move.b   d1,(a1)                                     ; Move register d1 to (a1)
Disk_SeekTrack0_Loc_3A60:
	sf.b     $166d(a6)                             ; Clear $166d(a6) flag (false).
	movem.l  (a7)+,d0-d1/a0-a1                           ; Move multiple registers (a7)+ to d0-d1/a0-a1
	rts                                                  ; Return from subroutine
Disk_StepOut:
	bclr     #$1,(a1)                                    ; Clear bit #$1 of (a1)
	addq.b   #$2,$166d(a6)                               ; Add constant $2 to $166d(a6)
	bra.b    Disk_StepIn_Loc_3A7C                        ; Unconditional branch to Disk_StepIn_Loc_3A7C
Disk_StepIn:
	bset     #$1,(a1)                                    ; Set bit #$1 of (a1)
	subq.b   #$2,$166d(a6)                               ; Subtract constant $2 from $166d(a6)
Disk_StepIn_Loc_3A7C:
	sf.b     Var_MonitorFlag_1670(a6)              ; Clear Var_MonitorFlag_1670(a6) flag (false).
	bclr     #$0,(a1)                                    ; Clear bit #$0 of (a1)
	bsr.w    Disk_MicroDelay                             ; Call subroutine to Disk_MicroDelay
	bset     #$0,(a1)                                    ; Set bit #$0 of (a1)
Disk_DelayStep:
	movem.l  d2/a1,-(a7)                                 ; Move multiple registers d2/a1 to -(a7)
	move.w   #$84f,d2                                    ; Move constant $84f to register d2
	bra.b    Disk_DelaySettle_Loc_3A9E                   ; Unconditional branch to Disk_DelaySettle_Loc_3A9E
Disk_DelaySettle:
	movem.l  d2/a1,-(a7)                                 ; Move multiple registers d2/a1 to -(a7)
	move.w   #$298e,d2                                   ; Move constant $298e to register d2
Disk_DelaySettle_Loc_3A9E:
	lea.l    $bfdd00.l,a1                                ; Load address of $bfdd00.l into pointer a1
	move.b   #$7f,(a1)                                   ; Move constant $7f to (a1)
	bclr     #$5,BPLCON0(a1)                             ; Clear bit #$5 of BPLCON0 (bitplane control register 0)
	bset     #$3,BPLCON0(a1)                             ; Set bit #$3 of BPLCON0 (bitplane control register 0)
	move.b   d2,-$900(a1)                                ; Move register d2 to -$900(a1)
	lsr.w    #$8,d2
	move.b   d2,-$800(a1)                                ; Move register d2 to -$800(a1)
Disk_DelaySettle_Loc_3ABE:
	btst     #$0,(a1)                                    ; Test bit #$0 of (a1)
	beq.b    Disk_DelaySettle_Loc_3ABE                   ; Branch to Disk_DelaySettle_Loc_3ABE if zero / equal
	movem.l  (a7)+,d2/a1                                 ; Move multiple registers (a7)+ to d2/a1
	rts                                                  ; Return from subroutine
Disk_SeekTrack:
	lea.l    CIAB_PRB.l,a1                               ; Load address of CIAB_PRB (CIA-B Port B data/control register) into pointer a1
	moveq    #$0,d0                                      ; Initialize register d0 to 0
	btst     d0,d1                                       ; Test bit d0 of register d1
	beq.b    Disk_SeekTrack_Side0                        ; Branch to Disk_SeekTrack_Side0 if zero / equal
	bclr     #$2,(a1)                                    ; Clear bit #$2 of (a1)
	bset     d0,$166d(a6)                                ; Set bit d0 of $166d(a6)
	bra.b    Disk_SeekTrack_Compare                      ; Unconditional branch to Disk_SeekTrack_Compare
Disk_SeekTrack_Side0:
	bset     #$2,(a1)                                    ; Set bit #$2 of (a1)
	bclr     d0,$166d(a6)                                ; Clear bit d0 of $166d(a6)
Disk_SeekTrack_Compare:
	lsr.b    #$1,d1
	cmpi.b   #$52,d1                                     ; Compare register d1 against constant $52
	bls.b    Disk_SeekTrack_Loop                              ; Branch to Disk_SeekTrack_Loop if lower or same.
	move.b   #$52,d1                                     ; Move constant $52 to register d1
Disk_SeekTrack_Loop:
	moveq    #-1,d0                                      ; Initialize register d0 to constant -1
Disk_SeekTrack_Wait:
	move.b   $166d(a6),d0                                ; Move $166d(a6) to register d0
	lsr.b    #$1,d0
	cmp.b    d0,d1                                       ; Compare register d1 against register d0
	beq.b    Disk_SeekTrack_Delay                        ; Branch to Disk_SeekTrack_Delay if zero / equal
	bhi.b    Disk_SeekTrack_StepOut                              ; Branch to Disk_SeekTrack_StepOut if higher.
	bsr.w    Disk_StepIn                                 ; Call subroutine to Disk_StepIn
	bra.b    Disk_SeekTrack_Next                         ; Unconditional branch to Disk_SeekTrack_Next
Disk_SeekTrack_StepOut:
	bsr.w    Disk_StepOut                                ; Call subroutine to Disk_StepOut
Disk_SeekTrack_Next:
	moveq    #$0,d0                                      ; Initialize register d0 to 0
	bra.b    Disk_SeekTrack_Wait                         ; Unconditional branch to Disk_SeekTrack_Wait
Disk_SeekTrack_Delay:
	tst.w    d0                                          ; Test status of register d0 (for zero or negative)
	bpl.b    Disk_SeekTrack_Settle                       ; Branch to Disk_SeekTrack_Settle if positive / plus
	bsr.w    Disk_DelayStep                              ; Call subroutine to Disk_DelayStep
	bra.b    Disk_SeekTrack_CheckWriteProtect            ; Unconditional branch to Disk_SeekTrack_CheckWriteProtect
Disk_SeekTrack_Settle:
	bsr.w    Disk_DelaySettle                            ; Call subroutine to Disk_DelaySettle
Disk_SeekTrack_CheckWriteProtect:
	btst     #$2,$f01(a1)                                ; Test bit #$2 of $f01(a1)
	bne.b    Disk_SeekTrack_Exit                         ; Branch to Disk_SeekTrack_Exit if non-zero / not equal
	move.b   #$1d,$1671(a6)                              ; Move constant $1d to $1671(a6)
Disk_SeekTrack_Exit:
	rts                                                  ; Return from subroutine
Print_SavingPrefix:
	moveq    #$8,d1                                      ; Initialize register d1 to constant $8
	bra.b    Print_FileOperationPrefix                   ; Unconditional branch to Print_FileOperationPrefix
Print_LoadingPrefix:
	moveq    #$0,d1                                      ; Initialize register d1 to 0
Print_FileOperationPrefix:
	move.l   a1,-(a7)                                    ; Move pointer a1 to -(a7)
	lea.l    Str_DiskInDrive(pc),a1                            ; Load address of Str_DiskInDrive(pc) into pointer a1
	adda.l   d1,a1                                       ; Add register d1 to pointer a1
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	moveq    #$2d,d0                                     ; Initialize register d0 to constant $2d
	add.b    Var_MonitorFlag_166c(a6),d0                 ; Add Var_MonitorFlag_166c(a6) to register d0
	move.b   d0,-VHPOSR(a0)                              ; Move register d0 to VHPOSR (beam vertical/horizontal position read)
	movea.l  (a7)+,a1                                    ; Move (a7)+ to pointer a1
	rts                                                  ; Return from subroutine
	lea.l    $7(a5),a0                                   ; Load address of $7(a5) into pointer a0
	bsr.w    Parser_GetNextArg                           ; Call subroutine to Parser_GetNextArg
	beq.w    Print_FileOperationPrefix_Loc_3D1A          ; Branch to Print_FileOperationPrefix_Loc_3D1A if zero / equal
	cmpi.w   #$1e,d4                                     ; Compare register d4 against constant $1e
	bhi.w    Print_FileOperationPrefix_Loc_3D1A                              ; Branch to Print_FileOperationPrefix_Loc_3D1A if higher.
	sf.b     d6
	bsr.w    Parser_SkipSpaces                           ; Call subroutine to Parser_SkipSpaces
	cmpi.b   #$71,(a0)                                   ; Compare (a0) against constant $71
	bne.b    Print_FileOperationPrefix_Loc_3B76          ; Branch to Print_FileOperationPrefix_Loc_3B76 if non-zero / not equal
	st.b     d6
	addq.w   #$1,a0                                      ; Add 1 to pointer a0
	bsr.w    Parser_SkipSpaces                           ; Call subroutine to Parser_SkipSpaces
Print_FileOperationPrefix_Loc_3B76:
	move.l   $17ea(a6),d5                                ; Move $17ea(a6) to register d5
	moveq    #-48,d0                                     ; Initialize register d0 to constant -48
	add.b    (a0),d0                                     ; Add (a0) to register d0
	cmpi.b   #$3,d0                                      ; Compare register d0 against constant $3
	bhi.b    Print_FileOperationPrefix_Loc_3B86                              ; Branch to Print_FileOperationPrefix_Loc_3B86 if higher.
	move.b   d0,d5                                       ; Move register d0 to register d5
Print_FileOperationPrefix_Loc_3B86:
	move.l   d5,$17ee(a6)                                ; Move register d5 to $17ee(a6)
	lea.l    $3294(a6),a0                                ; Load address of $3294(a6) into pointer a0
	clr.l    $1b0(a0)                                    ; Clear / reset $1b0(a0)
	lea.l    $1b1(a0),a1                                 ; Load address of $1b1(a0) into pointer a1
	subq.w   #$1,d4                                      ; Subtract 1 from register d4
Print_FileOperationPrefix_Loc_3B98:
	move.b   (a2)+,(a1)+                                 ; Copy word/byte data from source pointer a2 to destination a1
	addq.b   #$1,$1b0(a0)                                ; Add 1 to $1b0(a0)
	dbra     d4,Print_FileOperationPrefix_Loc_3B98       ; Decrement loop counter d4 and loop back to Print_FileOperationPrefix_Loc_3B98 if not exhausted
	bsr.w    Disk_SelectDriveAndMotorOn                  ; Call subroutine to Disk_SelectDriveAndMotorOn
	bsr.w    Disk_StepOut                                ; Call subroutine to Disk_StepOut
	bsr.w    Disk_StepIn                                 ; Call subroutine to Disk_StepIn
	sf.b     $1671(a6)                             ; Clear $1671(a6) flag (false).
	bsr.w    Disk_SeekTrack0                             ; Call subroutine to Disk_SeekTrack0
	tst.b    $1671(a6)                             ; Check if $1671 is set / active
	bne.w    Print_FileOperationPrefix_Loc_3D14          ; Branch to Print_FileOperationPrefix_Loc_3D14 if non-zero / not equal
	st.b     $1672(a6)                             ; Set $1672(a6) flag (true).
	bsr.w    Disk_CheckWriteProtectAndPresent            ; Call subroutine to Disk_CheckWriteProtectAndPresent
	bne.w    Print_FileOperationPrefix_Loc_3D14          ; Branch to Print_FileOperationPrefix_Loc_3D14 if non-zero / not equal
	lea.l    Var_FontData(a6),a0                         ; Load address of font glyph data pointer into pointer a0
	move.w   #$aff,d0                                    ; Move constant $aff to register d0
	moveq    #$0,d1                                      ; Initialize register d1 to 0
Print_FileOperationPrefix_Loc_3BD4:
	move.l   d1,(a0)+                                    ; Move register d1 to (a0)+
	dbra     d0,Print_FileOperationPrefix_Loc_3BD4       ; Decrement loop counter d0 and loop back to Print_FileOperationPrefix_Loc_3BD4 if not exhausted
	moveq    #BLTBPTH,d5                                 ; Initialize register d5 to constant BLTBPTH
	tst.b    d6                                          ; Test status of register d6 (for zero or negative)
	bne.b    Print_FileOperationPrefix_Loc_3BE4          ; Branch to Print_FileOperationPrefix_Loc_3BE4 if non-zero / not equal
	move.w   #$9f,d5                                     ; Move constant $9f to register d5
Print_FileOperationPrefix_Loc_3BE4:
	move.w   d5,d1                                       ; Move register d5 to register d1
	bsr.w    Disk_SeekTrack                              ; Call subroutine to Disk_SeekTrack
	tst.b    $1671(a6)                             ; Check if $1671 is set / active
	lea.l    Str_FormattingAborted(pc),a1                            ; Load address of Str_FormattingAborted(pc) into pointer a1
	bne.w    Print_FileOperationPrefix_Loc_3D10          ; Branch to Print_FileOperationPrefix_Loc_3D10 if non-zero / not equal
	lea.l    Var_FontData(a6),a0                         ; Load address of font glyph data pointer into pointer a0
	tst.w    d5                                          ; Test status of register d5 (for zero or negative)
	bne.b    Print_FileOperationPrefix_Loc_3C02          ; Branch to Print_FileOperationPrefix_Loc_3C02 if non-zero / not equal
	move.l   $17ee(a6),(a0)                              ; Move $17ee(a6) to (a0)
Print_FileOperationPrefix_Loc_3C02:
	cmpi.w   #BLTBPTH,d5                                 ; Compare register d5 against constant BLTBPTH
	bne.w    Print_FileOperationPrefix_Loc_3CAC          ; Branch to Print_FileOperationPrefix_Loc_3CAC if non-zero / not equal
	moveq    #$2,d0                                      ; Initialize register d0 to constant $2
	move.l   d0,(a0)                                     ; Move register d0 to (a0)
	moveq    #$48,d0                                     ; Initialize register d0 to constant $48
	move.l   d0,$c(a0)                                   ; Move register d0 to $c(a0)
	moveq    #-1,d0                                      ; Initialize register d0 to constant -1
	move.l   d0,$138(a0)                                 ; Move register d0 to $138(a0)
	move.l   $17b6(a6),d0                                ; Move $17b6(a6) to register d0
	addq.l   #$1,d0                                      ; Add 1 to register d0
	move.l   d0,$13c(a0)                                 ; Move register d0 to $13c(a0)
	bsr.w    Rtc_InitAndTest                             ; Call subroutine to Rtc_InitAndTest
	move.l   $1814(a6),$1a4(a0)                          ; Move $1814(a6) to $1a4(a0)
	move.l   $1818(a6),$1a8(a0)                          ; Move $1818(a6) to $1a8(a0)
	move.l   $181c(a6),$1ac(a0)                          ; Move $181c(a6) to $1ac(a0)
	move.l   $1814(a6),$1e4(a0)                          ; Move $1814(a6) to $1e4(a0)
	move.l   $1818(a6),$1e8(a0)                          ; Move $1818(a6) to $1e8(a0)
	move.l   $181c(a6),$1ec(a0)                          ; Move $181c(a6) to $1ec(a0)
	move.l   a0,-(a7)                                    ; Move pointer a0 to -(a7)
	lea.l    $3444(a6),a1                                ; Load address of $3444(a6) into pointer a1
	lea.l    $1b0(a0),a0                                 ; Load address of $1b0(a0) into pointer a0
	move.b   (a1),(a0)+                                  ; Move (a1) to (a0)+
	bsr.w    CopyBoundedString                           ; Call subroutine to CopyBoundedString
	movea.l  (a7)+,a0                                    ; Move (a7)+ to pointer a0
	moveq    #$1,d0                                      ; Initialize register d0 to 1
	move.l   d0,FMODE(a0)                                ; Move register d0 to FMODE (AGA fetch mode control register)
	bsr.w    Disk_CalculateBootblockChecksum             ; Call subroutine to Disk_CalculateBootblockChecksum
	move.l   d3,$14(a0)                                  ; Move register d3 to $14(a0)
	lea.l    $200(a0),a1                                 ; Load address of $200(a0) into pointer a1
	move.l   #$3b990984,d1                               ; Move constant $3b990984 to register d1
	moveq    #$36,d0                                     ; Initialize register d0 to constant $36
	tst.b    Var_MonitorFlag_166f(a6)              ; Check if Var_MonitorFlag_166f is set / active
	beq.b    Print_FileOperationPrefix_Loc_3C86          ; Branch to Print_FileOperationPrefix_Loc_3C86 if zero / equal
	move.l   #$3b9849bb,d1                               ; Move constant $3b9849bb to register d1
	moveq    #$6d,d0                                     ; Initialize register d0 to constant $6d
Print_FileOperationPrefix_Loc_3C86:
	move.l   d1,(a1)+                                    ; Move register d1 to (a1)+
	moveq    #-1,d1                                      ; Initialize register d1 to constant -1
Print_FileOperationPrefix_Loc_3C8A:
	move.l   d1,(a1)+                                    ; Move register d1 to (a1)+
	dbra     d0,Print_FileOperationPrefix_Loc_3C8A       ; Decrement loop counter d0 and loop back to Print_FileOperationPrefix_Loc_3C8A if not exhausted
	moveq    #$3f,d0                                     ; Initialize register d0 to constant $3f
	tst.b    Var_MonitorFlag_166f(a6)              ; Check if Var_MonitorFlag_166f is set / active
	bne.b    Print_FileOperationPrefix_Loc_3C9C          ; Branch to Print_FileOperationPrefix_Loc_3C9C if non-zero / not equal
	move.b   d0,$272(a0)                                 ; Move register d0 to $272(a0)
Print_FileOperationPrefix_Loc_3C9C:
	move.b   d0,$2dc(a0)                                 ; Move register d0 to $2dc(a0)
	lea.l    Str_TrademarkInfo(pc),a1                            ; Load address of Str_TrademarkInfo(pc) into pointer a1
	lea.l    $3f0(a0),a0                                 ; Load address of $3f0(a0) into pointer a0
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
Print_FileOperationPrefix_Loc_3CAC:
	lea.l    Var_DisasmBuffer+1(a6),a0                   ; Load address of disassembler output text buffer into pointer a0
	lea.l    Str_FormattingTrack(pc),a1                            ; Load address of Str_FormattingTrack(pc) into pointer a1
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	btst     #$0,d5                                      ; Test bit #$0 of register d5
	beq.b    Print_FileOperationPrefix_Loc_3CC0          ; Branch to Print_FileOperationPrefix_Loc_3CC0 if zero / equal
	addq.b   #$1,-(a0)                                   ; Add 1 to -(a0)
Print_FileOperationPrefix_Loc_3CC0:
	move.b   d5,d0                                       ; Move register d5 to register d0
	lsr.b    #$1,d0
	lea.l    $19ae(a6),a0                                ; Load address of $19ae(a6) into pointer a0
	bsr.w    FormatDecimal2Digit                         ; Call subroutine to FormatDecimal2Digit
	bsr.w    RefreshAndDrawConsoleLine                   ; Call subroutine to RefreshAndDrawConsoleLine
	bsr.w    Console_OpenMenu                            ; Call subroutine to Console_OpenMenu
	bsr.w    FormatTrackCopier                           ; Call subroutine to FormatTrackCopier
	bsr.w    Disk_DelayStep                              ; Call subroutine to Disk_DelayStep
	lea.l    Str_FormattingAborted(pc),a1                            ; Load address of Str_FormattingAborted(pc) into pointer a1
	tst.b    $1671(a6)                             ; Check if $1671 is set / active
	bne.b    Print_FileOperationPrefix_Loc_3D10          ; Branch to Print_FileOperationPrefix_Loc_3D10 if non-zero / not equal
	cmpi.w   #BLTBPTH,d5                                 ; Compare register d5 against constant BLTBPTH
	bne.b    Print_FileOperationPrefix_Loc_3D02          ; Branch to Print_FileOperationPrefix_Loc_3D02 if non-zero / not equal
	lea.l    Var_FontData(a6),a0                         ; Load address of font glyph data pointer into pointer a0
	move.w   #$ff,d0                                     ; Move constant $ff to register d0
	moveq    #$0,d1                                      ; Initialize register d1 to 0
Print_FileOperationPrefix_Loc_3CF6:
	move.l   d1,(a0)+                                    ; Move register d1 to (a0)+
	dbra     d0,Print_FileOperationPrefix_Loc_3CF6       ; Decrement loop counter d0 and loop back to Print_FileOperationPrefix_Loc_3CF6 if not exhausted
	tst.b    d6                                          ; Test status of register d6 (for zero or negative)
	beq.b    Print_FileOperationPrefix_Loc_3D02          ; Branch to Print_FileOperationPrefix_Loc_3D02 if zero / equal
	moveq    #$1,d5                                      ; Initialize register d5 to 1
Print_FileOperationPrefix_Loc_3D02:
	bsr.w    WaitInputOrButton                           ; Call subroutine to WaitInputOrButton
	beq.b    Print_FileOperationPrefix_Loc_3D10          ; Branch to Print_FileOperationPrefix_Loc_3D10 if zero / equal
	dbra     d5,Print_FileOperationPrefix_Loc_3BE4       ; Decrement loop counter d5 and loop back to Print_FileOperationPrefix_Loc_3BE4 if not exhausted
	lea.l    Str_FormattingComplete(pc),a1                            ; Load address of Str_FormattingComplete(pc) into pointer a1
Print_FileOperationPrefix_Loc_3D10:
	bsr.w    PrintString                                 ; Call subroutine to PrintString
Print_FileOperationPrefix_Loc_3D14:
	bsr.w    Disk_MotorOff                               ; Call subroutine to Disk_MotorOff
	st.b     d7
Print_FileOperationPrefix_Loc_3D1A:
	rts                                                  ; Return from subroutine
; ============================================================================
; Data Block: Str_TrademarkInfo
; Purpose   : Trademark and author banner string (Carnivore/BeerMacht).
; ============================================================================
Str_TrademarkInfo:
	dc.b     "CarnivoreBeerMo",$EE                 ; String literal data
	dc.b     $00,$33                               ; Table data bytes
; ============================================================================
; Data Block: BoardCode_OpenDosLib
; Purpose   : Expansion board executable code block to open dos.library.
; ============================================================================
BoardCode_OpenDosLib:
	dc.b     $00,$00,$00,$00,$00,$00,$03,$70       ; Table data bytes
	lea.l    Str_DosLibrary(pc),a1                            ; Load address of Str_DosLibrary(pc) into pointer a1
	jsr      -BLTCMOD(a6)                                ; Call subroutine -BLTCMOD(a6)
	tst.l    d0                                          ; Test status of register d0 (for zero or negative)
	beq.b    Print_FileOperationPrefix_Loc_3D4C          ; Branch to Print_FileOperationPrefix_Loc_3D4C if zero / equal
	movea.l  d0,a0                                       ; Move register d0 to pointer a0
	movea.l  POTGOR(a0),a0                               ; Move POTGOR (potentiometer port control register) to pointer a0
	moveq    #$0,d0                                      ; Initialize register d0 to 0
Print_FileOperationPrefix_Loc_3D4A:
	rts                                                  ; Return from subroutine
Print_FileOperationPrefix_Loc_3D4C:
	moveq    #-1,d0                                      ; Initialize register d0 to constant -1
	bra.b    Print_FileOperationPrefix_Loc_3D4A          ; Unconditional branch to Print_FileOperationPrefix_Loc_3D4A
; ============================================================================
; Data Block: Str_DosLibrary
; Purpose   : String literal containing "dos.library".
; ============================================================================
Str_DosLibrary:
	dc.b     "dos.library"                         ; String literal data
	dc.b     $00,$00,$00,$42,$45,$45,$52,$00,$5F   ; Table data bytes
; ============================================================================
; Data Block: BoardCode_OpenExpansionLib
; Purpose   : Expansion board executable code block to open expansion.library.
; ============================================================================
BoardCode_OpenExpansionLib:
	dc.b     $00,$00,$00,$00,$00,$00,$03,$70       ; Table data bytes
	lea.l    Str_ExpansionLibrary(pc),a1                            ; Load address of Str_ExpansionLibrary(pc) into pointer a1
	moveq    #$25,d0                                     ; Initialize register d0 to constant $25
	jsr      -$228(a6)                                   ; Call subroutine -$228(a6)
	tst.l    d0                                          ; Test status of register d0 (for zero or negative)
	beq.b    Print_FileOperationPrefix_Loc_3D86          ; Branch to Print_FileOperationPrefix_Loc_3D86 if zero / equal
	movea.l  d0,a1                                       ; Move register d0 to pointer a1
	bset     #$6,$22(a1)                                 ; Set bit #$6 of $22(a1)
	jsr      LVO_CloseLibrary(a6)                        ; Call subroutine LVO_CloseLibrary(a6)
Print_FileOperationPrefix_Loc_3D86:
	lea.l    Str_DosLibrary_Duplicate(pc),a1                            ; Load address of Str_DosLibrary_Duplicate(pc) into pointer a1
	jsr      -BLTCMOD(a6)                                ; Call subroutine -BLTCMOD(a6)
	tst.l    d0                                          ; Test status of register d0 (for zero or negative)
	beq.b    Print_FileOperationPrefix_Loc_3D9C          ; Branch to Print_FileOperationPrefix_Loc_3D9C if zero / equal
	movea.l  d0,a0                                       ; Move register d0 to pointer a0
	movea.l  POTGOR(a0),a0                               ; Move POTGOR (potentiometer port control register) to pointer a0
	moveq    #$0,d0                                      ; Initialize register d0 to 0
	rts                                                  ; Return from subroutine
Print_FileOperationPrefix_Loc_3D9C:
	moveq    #-1,d0                                      ; Initialize register d0 to constant -1
	rts                                                  ; Return from subroutine
; ============================================================================
; Data Block: Str_DosLibrary_Duplicate
; Purpose   : String literal containing duplicate "dos.library" name.
; ============================================================================
Str_DosLibrary_Duplicate:
	dc.b     "dos.library"                         ; String literal data
	dc.b     $00                                   ; Table data bytes
; ============================================================================
; Data Block: Str_ExpansionLibrary
; Purpose   : String literal containing "expansion.library".
; ============================================================================
Str_ExpansionLibrary:
	dc.b     "expansion.library"                   ; String literal data
	dc.b     $00,$00,$00,$42,$45,$45,$52           ; Table data bytes
	subq.b   #$1,d3                                      ; Subtract 1 from register d3
	bmi.b    Print_FileOperationPrefix_Loc_3DE4          ; Branch to Print_FileOperationPrefix_Loc_3DE4 if negative / minus
	bne.w    Print_FileOperationPrefix_Loc_3EA4          ; Branch to Print_FileOperationPrefix_Loc_3EA4 if non-zero / not equal
	move.l   $17ea(a6),d4                                ; Move $17ea(a6) to register d4
	lea.l    BoardCode_OpenDosLib(pc),a5                            ; Load address of BoardCode_OpenDosLib(pc) into pointer a5
	move.l   Var_MemStart(a6),d0                         ; Load monitored memory start offset into register d0
	moveq    #$4,d1                                      ; Initialize register d1 to constant $4
	cmp.l    d1,d0                                       ; Compare register d0 against register d1
	bhi.w    Print_FileOperationPrefix_Loc_3EA4                              ; Branch to Print_FileOperationPrefix_Loc_3EA4 if higher.
	beq.b    Print_FileOperationPrefix_Loc_3DE8          ; Branch to Print_FileOperationPrefix_Loc_3DE8 if zero / equal
	move.b   d0,d4                                       ; Move register d0 to register d4
Print_FileOperationPrefix_Loc_3DE4:
	lea.l    BoardCode_OpenExpansionLib(pc),a5                            ; Load address of BoardCode_OpenExpansionLib(pc) into pointer a5
Print_FileOperationPrefix_Loc_3DE8:
	st.b     $1673(a6)                             ; Set $1673(a6) flag (true).
	bsr.w    Disk_SelectDriveAndMotorOn                  ; Call subroutine to Disk_SelectDriveAndMotorOn
	bsr.w    Disk_StepOut                                ; Call subroutine to Disk_StepOut
	bsr.w    Disk_StepIn                                 ; Call subroutine to Disk_StepIn
	sf.b     $1671(a6)                             ; Clear $1671(a6) flag (false).
	bsr.w    Disk_SeekTrack0                             ; Call subroutine to Disk_SeekTrack0
	tst.b    $1671(a6)                             ; Check if $1671 is set / active
	bne.w    Print_FileOperationPrefix_Loc_3E9E          ; Branch to Print_FileOperationPrefix_Loc_3E9E if non-zero / not equal
	sf.b     Var_MonitorFlag_1670(a6)              ; Clear Var_MonitorFlag_1670(a6) flag (false).
	clr.l    $17f6(a6)                                   ; Clear / reset $17f6(a6)
	move.b   $1673(a6),$1672(a6)                         ; Move $1673(a6) to $1672(a6)
	bsr.w    Disk_CheckWriteProtectAndPresent            ; Call subroutine to Disk_CheckWriteProtectAndPresent
	bne.w    Print_FileOperationPrefix_Loc_3E9E          ; Branch to Print_FileOperationPrefix_Loc_3E9E if non-zero / not equal
	lea.l    $3294(a6),a4                                ; Load address of $3294(a6) into pointer a4
	tst.b    d3                                          ; Test status of register d3 (for zero or negative)
	bpl.b    Print_FileOperationPrefix_Loc_3E46          ; Branch to Print_FileOperationPrefix_Loc_3E46 if positive / plus
	move.l   a4,d6                                       ; Move pointer a4 to register d6
	moveq    #$0,d5                                      ; Initialize register d5 to 0
	bsr.w    Disk_ReadWriteSector                        ; Call subroutine to Disk_ReadWriteSector
	tst.b    $1671(a6)                             ; Check if $1671 is set / active
	bne.b    Print_FileOperationPrefix_Loc_3E9E          ; Branch to Print_FileOperationPrefix_Loc_3E9E if non-zero / not equal
	move.l   (a4),d4                                     ; Move (a4) to register d4
	moveq    #-4,d0                                      ; Initialize register d0 to constant -4
	and.l    d4,d0                                       ; Logical AND register d0 with register d4
	cmp.l    $17ea(a6),d0                                ; Compare register d0 against $17ea(a6)
	beq.b    Print_FileOperationPrefix_Loc_3E46          ; Branch to Print_FileOperationPrefix_Loc_3E46 if zero / equal
	bsr.w    Disk_ReadAndValidateBootblock_Invalid       ; Call subroutine to Disk_ReadAndValidateBootblock_Invalid
	bra.b    Print_FileOperationPrefix_Loc_3E9E          ; Unconditional branch to Print_FileOperationPrefix_Loc_3E9E
Print_FileOperationPrefix_Loc_3E46:
	movea.l  a4,a0                                       ; Move pointer a4 to pointer a0
	moveq    #$7f,d0                                     ; Initialize register d0 to constant $7f
Print_FileOperationPrefix_Loc_3E4A:
	clr.l    (a0)+                                       ; Clear / reset (a0)+
	clr.l    (a0)+                                       ; Clear / reset (a0)+
	dbra     d0,Print_FileOperationPrefix_Loc_3E4A       ; Decrement loop counter d0 and loop back to Print_FileOperationPrefix_Loc_3E4A if not exhausted
	movea.l  a4,a1                                       ; Move pointer a4 to pointer a1
	move.l   d4,(a1)+                                    ; Move register d4 to (a1)+
	move.w   -DMACONR(a5),d0                             ; Move DMACON (DMA control write register) to register d0
Print_FileOperationPrefix_Loc_3E5A:
	move.b   (a5)+,(a1)+                                 ; Move (a5)+ to (a1)+
	dbra     d0,Print_FileOperationPrefix_Loc_3E5A       ; Decrement loop counter d0 and loop back to Print_FileOperationPrefix_Loc_3E5A if not exhausted
	movea.l  a4,a0                                       ; Move pointer a4 to pointer a0
	bsr.w    Afs_CalculateBlockChecksum                  ; Call subroutine to Afs_CalculateBlockChecksum
	move.l   -(a1),$4(a0)                                ; Move -(a1) to $4(a0)
	move.l   d3,(a1)                                     ; Move register d3 to (a1)
	move.l   a4,d6                                       ; Move pointer a4 to register d6
	moveq    #$0,d5                                      ; Initialize register d5 to 0
	bsr.w    Disk_WriteSector                            ; Call subroutine to Disk_WriteSector
	tst.b    $1671(a6)                             ; Check if $1671 is set / active
	bne.b    Print_FileOperationPrefix_Loc_3E9E          ; Branch to Print_FileOperationPrefix_Loc_3E9E if non-zero / not equal
	lea.l    $200(a4),a0                                 ; Load address of $200(a4) into pointer a0
	move.l   a0,d6                                       ; Move pointer a0 to register d6
	moveq    #$1,d5                                      ; Initialize register d5 to 1
	bsr.w    Disk_WriteSector                            ; Call subroutine to Disk_WriteSector
	tst.b    $1671(a6)                             ; Check if $1671 is set / active
	bne.b    Print_FileOperationPrefix_Loc_3E9E          ; Branch to Print_FileOperationPrefix_Loc_3E9E if non-zero / not equal
	bsr.w    Disk_FlushTrackWriteBuffer                  ; Call subroutine to Disk_FlushTrackWriteBuffer
	tst.b    $1671(a6)                             ; Check if $1671 is set / active
	bne.b    Print_FileOperationPrefix_Loc_3E9E          ; Branch to Print_FileOperationPrefix_Loc_3E9E if non-zero / not equal
	lea.l    Str_DiskInstalled(pc),a1                            ; Load address of Str_DiskInstalled(pc) into pointer a1
	bsr.w    PrintString                                 ; Call subroutine to PrintString
Print_FileOperationPrefix_Loc_3E9E:
	bsr.w    Disk_MotorOff                               ; Call subroutine to Disk_MotorOff
	st.b     d7
Print_FileOperationPrefix_Loc_3EA4:
	rts                                                  ; Return from subroutine
	lea.l    Str_BoardHeader(pc),a1                            ; Load address of Str_BoardHeader(pc) into pointer a1
	bsr.w    PrintString                                 ; Call subroutine to PrintString
	lea.l    $200000.l,a4                                ; Load address of $200000.l into pointer a4
	lea.l    $e90000.l,a5                                ; Load address of $e90000.l into pointer a5
	sf.b     d6
; ============================================================================
; Data Block: Autoconfig_LoopContinuation
; Purpose   : Continuation block for autoconfig loop after configuring a board.
; ============================================================================
Autoconfig_LoopContinuation:
	lea.l    $e8000c.l,a3                                ; Load address of $e8000c.l into pointer a3
	bsr.w    Autoconfig_ReadRegisterByte                 ; Call subroutine to Autoconfig_ReadRegisterByte
	bne.w    Print_FileOperationPrefix_Loc_3FB8          ; Branch to Print_FileOperationPrefix_Loc_3FB8 if non-zero / not equal
	lea.l    $e80010.l,a3                                ; Load address of $e80010.l into pointer a3
	bsr.w    Autoconfig_ReadRegisterLong                 ; Call subroutine to Autoconfig_ReadRegisterLong
	tst.l    d0                                          ; Test status of register d0 (for zero or negative)
	beq.w    Print_FileOperationPrefix_Loc_3FB8          ; Branch to Print_FileOperationPrefix_Loc_3FB8 if zero / equal
	lea.l    $e80000.l,a3                                ; Load address of $e80000.l into pointer a3
	bsr.w    Autoconfig_ReadRegisterByte                 ; Call subroutine to Autoconfig_ReadRegisterByte
	not.b    d0
	move.w   d0,d5                                       ; Move register d0 to register d5
	add.b    d5,d5                                       ; Add register d5 to register d5
	lea.l    Str_Unknown(pc),a1                            ; Load address of Str_Unknown(pc) into pointer a1
	bcc.b    Print_FileOperationPrefix_Loc_3EFC          ; Branch to Print_FileOperationPrefix_Loc_3EFC if carry clear (greater or equal)
	add.b    d5,d5                                       ; Add register d5 to register d5
	lea.l    Str_ZorroII(pc),a1                            ; Load address of Str_ZorroII(pc) into pointer a1
	bcc.b    Print_FileOperationPrefix_Loc_3EFC          ; Branch to Print_FileOperationPrefix_Loc_3EFC if carry clear (greater or equal)
	lea.l    Str_ZorroI(pc),a1                            ; Load address of Str_ZorroI(pc) into pointer a1
Print_FileOperationPrefix_Loc_3EFC:
	lea.l    Var_DisasmBuffer+1(a6),a0                   ; Load address of disassembler output text buffer into pointer a0
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	lea.l    $19bf(a6),a0                                ; Load address of $19bf(a6) into pointer a0
	andi.w   #$7,d0                                      ; Logical AND register d0 with constant $7
	bne.b    Print_FileOperationPrefix_Loc_3F10          ; Branch to Print_FileOperationPrefix_Loc_3F10 if non-zero / not equal
	moveq    #$8,d0                                      ; Initialize register d0 to constant $8
Print_FileOperationPrefix_Loc_3F10:
	moveq    #$5,d1                                      ; Initialize register d1 to constant $5
	add.w    d0,d1                                       ; Add register d0 to register d1
	moveq    #$0,d0                                      ; Initialize register d0 to 0
	bset     d1,d0                                       ; Set bit d1 of register d0
	move.l   d0,d2                                       ; Move register d0 to register d2
	mulu.w   #$400,d2                              ; Multiply d2 by constant $400.
	moveq    #$4b,d1                                     ; Initialize register d1 to constant $4b
	cmpi.w   #$200,d0                                    ; Compare register d0 against constant $200
	bls.b    Print_FileOperationPrefix_Loc_3F2A                              ; Branch to Print_FileOperationPrefix_Loc_3F2A if lower or same.
	moveq    #$4d,d1                                     ; Initialize register d1 to constant $4d
	rol.w    #$6,d0
Print_FileOperationPrefix_Loc_3F2A:
	bsr.w    FormatDecimal32Bit                          ; Call subroutine to FormatDecimal32Bit
	move.b   d1,(a0)+                                    ; Move register d1 to (a0)+
	lea.l    $19cc(a6),a0                                ; Load address of $19cc(a6) into pointer a0
	bsr.w    Autoconfig_ReadRegisterByte                 ; Call subroutine to Autoconfig_ReadRegisterByte
	bsr.w    PrintHex2_Entry                             ; Call subroutine to PrintHex2_Entry
	lea.l    $19c5(a6),a0                                ; Load address of $19c5(a6) into pointer a0
	bsr.w    Autoconfig_ReadRegisterByte                 ; Call subroutine to Autoconfig_ReadRegisterByte
	bsr.w    PrintHex2_Entry                             ; Call subroutine to PrintHex2_Entry
	move.l   #$2072616d,d3                               ; Move constant $2072616d to register d3
	btst     #$7,d0                                      ; Test bit #$7 of register d0
	bne.b    Print_FileOperationPrefix_Loc_3F62          ; Branch to Print_FileOperationPrefix_Loc_3F62 if non-zero / not equal
	move.l   #$20686420,d3                               ; Move constant $20686420 to register d3
	move.l   a5,d0                                       ; Move pointer a5 to register d0
	adda.l   d2,a5                                       ; Add register d2 to pointer a5
	move.l   a5,d1                                       ; Move pointer a5 to register d1
	bra.b    Print_FileOperationPrefix_Loc_3F68          ; Unconditional branch to Print_FileOperationPrefix_Loc_3F68
Print_FileOperationPrefix_Loc_3F62:
	move.l   a4,d0                                       ; Move pointer a4 to register d0
	adda.l   d2,a4                                       ; Add register d2 to pointer a4
	move.l   a4,d1                                       ; Move pointer a4 to register d1
Print_FileOperationPrefix_Loc_3F68:
	move.l   d0,d2                                       ; Move register d0 to register d2
	lea.l    $19a6(a6),a0                                ; Load address of $19a6(a6) into pointer a0
	move.l   d3,(a0)+                                    ; Move register d3 to (a0)+
	addq.w   #$1,a0                                      ; Add 1 to pointer a0
	subq.l   #$1,d1                                      ; Subtract 1 from register d1
	bsr.w    FormatAddressRange8                         ; Call subroutine to FormatAddressRange8
	swap     d2
	lsl.w    #$8,d2
	move.w   d2,d0                                       ; Move register d2 to register d0
	lsl.w    #$4,d0
	swap     d2
	move.w   d0,d2                                       ; Move register d0 to register d2
	addq.w   #$4,a3                                      ; Add constant $4 to pointer a3
	lea.l    $19d2(a6),a0                                ; Load address of $19d2(a6) into pointer a0
	bsr.b    Autoconfig_ReadRegisterWord                 ; Call subroutine to Autoconfig_ReadRegisterWord
	bsr.w    PrintHex4_Entry                             ; Call subroutine to PrintHex4_Entry
	addq.w   #$1,a0                                      ; Add 1 to pointer a0
	bsr.b    Autoconfig_ReadRegisterLong                 ; Call subroutine to Autoconfig_ReadRegisterLong
	bsr.w    PrintHex8                                   ; Call subroutine to PrintHex8
	addq.w   #$1,a0                                      ; Add 1 to pointer a0
	bsr.b    Autoconfig_ReadRegisterWord                 ; Call subroutine to Autoconfig_ReadRegisterWord
	bsr.w    PrintHex4_Entry                             ; Call subroutine to PrintHex4_Entry
	move.w   d2,$e8004a.l                                ; Move register d2 to $e8004a.l
	swap     d2
	move.w   d2,$e80048.l                                ; Move register d2 to $e80048.l
	st.b     d6
	pea.l    Autoconfig_LoopContinuation(pc)                         ; Push effective address of Autoconfig_LoopContinuation(pc) onto stack.
	bra.w    RefreshAndDrawConsoleLine                   ; Unconditional branch to RefreshAndDrawConsoleLine
Print_FileOperationPrefix_Loc_3FB8:
	tst.b    d6                                          ; Test status of register d6 (for zero or negative)
	bne.b    Print_FileOperationPrefix_Loc_3FC4          ; Branch to Print_FileOperationPrefix_Loc_3FC4 if non-zero / not equal
	lea.l    Str_NoBoardsFound(pc),a1                            ; Load address of Str_NoBoardsFound(pc) into pointer a1
	bsr.w    PrintString                                 ; Call subroutine to PrintString
Print_FileOperationPrefix_Loc_3FC4:
	st.b     d7
	rts                                                  ; Return from subroutine
; ============================================================================
; Function: Autoconfig_ReadRegisterLong
; Purpose : Reads a 32-bit longword from consecutive Zorro II Autoconfig registers.
; Inputs  : a3 = Pointer to consecutive Autoconfig register offsets.
; Outputs : d0 = 32-bit read value.
; Clobbers: None.
; Notes   : Recombines nibbles from four consecutive word registers on the bus.
; ============================================================================
Autoconfig_ReadRegisterLong:
	bsr.b    Autoconfig_ReadRegisterWord                 ; Call subroutine to Autoconfig_ReadRegisterWord
	swap     d0
; ============================================================================
; Function: Autoconfig_ReadRegisterWord
; Purpose : Reads a 16-bit word from consecutive Zorro II Autoconfig registers.
; Inputs  : a3 = Pointer to consecutive Autoconfig register offsets.
; Outputs : d0 = 16-bit read value.
; Clobbers: None.
; Notes   : Recombines nibbles from two consecutive word registers.
; ============================================================================
Autoconfig_ReadRegisterWord:
	bsr.b    Autoconfig_ReadRegisterByte                 ; Call subroutine to Autoconfig_ReadRegisterByte
	lsl.w    #$8,d0
	move.w   d0,-(a7)                                    ; Move register d0 to -(a7)
	bsr.b    Autoconfig_ReadRegisterByte                 ; Call subroutine to Autoconfig_ReadRegisterByte
	or.w     (a7)+,d0                                    ; Logical OR register d0 with (a7)+
	rts                                                  ; Return from subroutine
; ============================================================================
; Function: Autoconfig_ReadRegisterByte
; Purpose : Reads a single byte from consecutive Zorro II Autoconfig registers.
; Inputs  : a3 = Pointer to consecutive Autoconfig register offsets.
; Outputs : d0 = 8-bit read value.
; Clobbers: None.
; Notes   : Combines two active-low nibbles into a single byte.
; ============================================================================
Autoconfig_ReadRegisterByte:
	move.w   (a3)+,d0                                    ; Move (a3)+ to register d0
	andi.w   #$f000,d0                                   ; Logical AND register d0 with constant $f000
	lsr.w    #$8,d0
	move.w   d0,-(a7)                                    ; Move register d0 to -(a7)
	move.w   (a3)+,d0                                    ; Move (a3)+ to register d0
	andi.w   #$f000,d0                                   ; Logical AND register d0 with constant $f000
	rol.w    #$4,d0
	or.w     (a7)+,d0                                    ; Logical OR register d0 with (a7)+
	not.b    d0
	rts                                                  ; Return from subroutine
Autoconfig_ReadRegisterByte_Loc_3FF0:
	rts                                                  ; Return from subroutine
	subq.l   #$1,d3                                      ; Subtract 1 from register d3
	bne.b    Autoconfig_ReadRegisterByte_Loc_3FF0        ; Branch to Autoconfig_ReadRegisterByte_Loc_3FF0 if non-zero / not equal
	move.l   Var_MemStart(a6),d5                         ; Load monitored memory start offset into register d5
	btst     #$0,d5                                      ; Test bit #$0 of register d5
	bne.b    Autoconfig_ReadRegisterByte_Loc_3FF0        ; Branch to Autoconfig_ReadRegisterByte_Loc_3FF0 if non-zero / not equal
	dc.w     $51EE
Val_MonitorBaseOffset:
	dc.w     $167E
	movea.l  d5,a0                                       ; Move register d5 to pointer a0
	bsr.b    ValidateRomHeader                           ; Call subroutine to ValidateRomHeader
	beq.b    Autoconfig_ReadRegisterByte_Loc_3FF0        ; Branch to Autoconfig_ReadRegisterByte_Loc_3FF0 if zero / equal
	lea.l    $200(a0),a3                                 ; Load address of $200(a0) into pointer a3
	movea.l  d5,a5                                       ; Move register d5 to pointer a5
Val_MonitorBaseOffset_Loc_4010:
	lea.l    Var_DisasmBuffer+1(a6),a0                   ; Load address of disassembler output text buffer into pointer a0
	lea.l    Str_CurrentAddress(pc),a1                            ; Load address of Str_CurrentAddress(pc) into pointer a1
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	move.l   a5,d0                                       ; Move pointer a5 to register d0
	bsr.w    PrintHex8                                   ; Call subroutine to PrintHex8
	lea.l    Str_BlocksToGo(pc),a1                            ; Load address of Str_BlocksToGo(pc) into pointer a1
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	move.b   d6,d0                                       ; Move register d6 to register d0
	bsr.w    PrintHex2_Entry                             ; Call subroutine to PrintHex2_Entry
	bsr.w    RefreshAndDrawConsoleLine                   ; Call subroutine to RefreshAndDrawConsoleLine
	bsr.w    Console_OpenMenu                            ; Call subroutine to Console_OpenMenu
	lea.l    Var_FontData(a6),a4                         ; Load address of font glyph data pointer into pointer a4
	move.w   #$1ff,d4                                    ; Move constant $1ff to register d4
Val_MonitorBaseOffset_Loc_4040:
	movem.l  (a3)+,d0-d3                                 ; Move multiple registers (a3)+ to d0-d3
	movem.l  d0-d3,(a4)                                  ; Move multiple registers d0-d3 to (a4)
	lea.l    $10(a4),a4                                  ; Load address of $10(a4) into pointer a4
	dbra     d4,Val_MonitorBaseOffset_Loc_4040           ; Decrement loop counter d4 and loop back to Val_MonitorBaseOffset_Loc_4040 if not exhausted
	lea.l    Var_FontData(a6),a4                         ; Load address of font glyph data pointer into pointer a4
	move.w   #$1fff,d4                                   ; Move constant $1fff to register d4
Val_MonitorBaseOffset_Loc_4058:
	move.b   (a3)+,d0                                    ; Move (a3)+ to register d0
	lsl.w    #$8,d0
	move.b   (a4)+,d0                                    ; Move (a4)+ to register d0
	move.w   d0,(a5)+                                    ; Move register d0 to (a5)+
	dbra     d4,Val_MonitorBaseOffset_Loc_4058           ; Decrement loop counter d4 and loop back to Val_MonitorBaseOffset_Loc_4058 if not exhausted
	subq.b   #$1,d6                                      ; Subtract 1 from register d6
	bne.b    Val_MonitorBaseOffset_Loc_4010              ; Branch to Val_MonitorBaseOffset_Loc_4010 if non-zero / not equal
	moveq    #$7f,d0                                     ; Initialize register d0 to constant $7f
Val_MonitorBaseOffset_Loc_406A:
	move.l   $17aa(a6),(a5)+                             ; Move $17aa(a6) to (a5)+
	dbra     d0,Val_MonitorBaseOffset_Loc_406A           ; Decrement loop counter d0 and loop back to Val_MonitorBaseOffset_Loc_406A if not exhausted
	lea.l    Str_ConversionComplete(pc),a1                            ; Load address of Str_ConversionComplete(pc) into pointer a1
	bra.w    PrintString                                 ; Unconditional branch to PrintString
ValidateRomHeader:
	st.b     d7
	move.b   (a0),d6                                     ; Move (a0) to register d6
	bne.b    ValidateRomHeader_Exit                      ; Branch to ValidateRomHeader_Exit if non-zero / not equal
	lea.l    Str_InvalidHeader(pc),a1                            ; Load address of Str_InvalidHeader(pc) into pointer a1
	bsr.w    PrintString                                 ; Call subroutine to PrintString
	moveq    #$0,d0                                      ; Initialize register d0 to 0
ValidateRomHeader_Exit:
	rts                                                  ; Return from subroutine
	sf.b     $167e(a6)                             ; Clear $167e(a6) flag (false).
	st.b     $167d(a6)                             ; Set $167d(a6) flag (true).
	subq.l   #$1,d3                                      ; Subtract 1 from register d3
	bne.w    ParallelPort_Action_Rts                     ; Branch to ParallelPort_Action_Rts if non-zero / not equal
	move.l   Var_MemStart(a6),d5                         ; Load monitored memory start offset into register d5
	btst     #$0,d5                                      ; Test bit #$0 of register d5
	bne.w    ParallelPort_Action_Rts                     ; Branch to ParallelPort_Action_Rts if non-zero / not equal
	lea.l    Var_MonitorBufferOffset(a6),a0              ; Load address of Var_MonitorBufferOffset(a6) into pointer a0
	moveq    #$7f,d0                                     ; Initialize register d0 to constant $7f
Monitor_ClearBuffer_Loop:
	clr.l    -(a0)                                       ; Clear / reset -(a0)
	dbra     d0,Monitor_ClearBuffer_Loop                 ; Decrement loop counter d0 and loop back to Monitor_ClearBuffer_Loop if not exhausted
	move.w   #$3,(a0)                                    ; Move constant $3 to (a0)
	move.l   #$aabb0600,$8(a0)                           ; Move constant $aabb0600 to $8(a0)
	movea.l  d5,a1                                       ; Move register d5 to pointer a1
	move.l   $1a4(a1),d6                                 ; Move $1a4(a1) to register d6
	addq.l   #$1,d6                                      ; Add 1 to register d6
	moveq    #$e,d1                                      ; Initialize register d1 to constant $e
	lsr.l    d1,d6
	move.b   d6,(a0)                                     ; Move register d6 to (a0)
	bra.b    ParallelPort_WriteLoop_Start                ; Unconditional branch to ParallelPort_WriteLoop_Start
	st.b     $167e(a6)                             ; Set $167e(a6) flag (true).
	bra.b    ParallelPort_Action_FlagDone                ; Unconditional branch to ParallelPort_Action_FlagDone
	sf.b     $167e(a6)                             ; Clear $167e(a6) flag (false).
ParallelPort_Action_FlagDone:
	sf.b     $167d(a6)                             ; Clear $167d(a6) flag (false).
	subq.l   #$1,d3                                      ; Subtract 1 from register d3
	bne.w    ParallelPort_Action_Rts                     ; Branch to ParallelPort_Action_Rts if non-zero / not equal
	move.l   Var_MemStart(a6),d5                         ; Load monitored memory start offset into register d5
	btst     #$0,d5                                      ; Test bit #$0 of register d5
	bne.w    ParallelPort_Action_Rts                     ; Branch to ParallelPort_Action_Rts if non-zero / not equal
	movea.l  d5,a0                                       ; Move register d5 to pointer a0
	bsr.w    ValidateRomHeader                           ; Call subroutine to ValidateRomHeader
	beq.w    ParallelPort_Action_Rts                     ; Branch to ParallelPort_Action_Rts if zero / equal
ParallelPort_WriteLoop_Start:
	move.b   $bfd200.l,d0                                ; Move $bfd200.l to register d0
	andi.b   #$f8,d0                                     ; Logical AND register d0 with constant $f8
	ori.b    #$4,d0                                      ; Logical OR register d0 with constant $4
	move.b   d0,$bfd200.l                                ; Move register d0 to $bfd200.l
	st.b     $bfe301.l                             ; Set $bfe301.l flag (true).
	movea.l  a7,a5                                       ; Move stack pointer (a7) to pointer a5
	move.w   #$dc00,d1                                   ; Move constant $dc00 to register d1
	move.l   #$200,d2                                    ; Move constant $200 to register d2
	tst.b    $167d(a6)                             ; Check if $167d is set / active
	bne.b    ParallelPort_WriteLoop_Direct               ; Branch to ParallelPort_WriteLoop_Direct if non-zero / not equal
	add.l    d2,d5                                       ; Add register d2 to register d5
	tst.b    $167e(a6)                             ; Check if $167e is set / active
	bne.b    ParallelPort_WriteLoop_Next                 ; Branch to ParallelPort_WriteLoop_Next if non-zero / not equal
ParallelPort_WriteLoop_Direct:
	bsr.w    ParallelPort_WriteBlock_Direct              ; Call subroutine to ParallelPort_WriteBlock_Direct
	lea.l    $167c(a6),a0                                ; Load address of $167c(a6) into pointer a0
	sf.b     (a0)
	move.w   #$2001,d1                                   ; Move constant $2001 to register d1
	moveq    #$1,d2                                      ; Initialize register d2 to 1
	bsr.w    ParallelPort_WriteBlock_Direct              ; Call subroutine to ParallelPort_WriteBlock_Direct
ParallelPort_WriteLoop_Next:
	clr.w    $162a(a6)                                   ; Clear / reset $162a(a6)
ParallelPort_WriteLoop_Wait:
	bsr.w    WaitInputOrButton                           ; Call subroutine to WaitInputOrButton
	lea.l    Str_TransferAborted(pc),a1                            ; Load address of Str_TransferAborted(pc) into pointer a1
	beq.w    ParallelPort_Action_PrintDone               ; Branch to ParallelPort_Action_PrintDone if zero / equal
	lea.l    Var_DisasmBuffer+1(a6),a0                   ; Load address of disassembler output text buffer into pointer a0
	lea.l    Str_CurrentAddress(pc),a1                            ; Load address of Str_CurrentAddress(pc) into pointer a1
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	move.l   d5,d0                                       ; Move register d5 to register d0
	bsr.w    PrintHex8                                   ; Call subroutine to PrintHex8
	lea.l    Str_BlocksToGo(pc),a1                            ; Load address of Str_BlocksToGo(pc) into pointer a1
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	move.b   d6,d0                                       ; Move register d6 to register d0
	bsr.w    PrintHex2_Entry                             ; Call subroutine to PrintHex2_Entry
	bsr.w    RefreshAndDrawConsoleLine                   ; Call subroutine to RefreshAndDrawConsoleLine
	bsr.w    Console_OpenMenu                            ; Call subroutine to Console_OpenMenu
	move.w   $162a(a6),d0                                ; Move $162a(a6) to register d0
	bsr.b    ParallelPort_SendCommand5                   ; Call subroutine to ParallelPort_SendCommand5
	movea.l  d5,a0                                       ; Move register d5 to pointer a0
	move.w   #$8000,d1                                   ; Move constant $8000 to register d1
	move.l   #$2000,d2                                   ; Move Supervisor mode with interrupts enabled to register d2
	tst.b    $167e(a6)                             ; Check if $167e is set / active
	bne.b    ParallelPort_WriteLoop_Step                 ; Branch to ParallelPort_WriteLoop_Step if non-zero / not equal
	add.l    d2,d2                                       ; Add register d2 to register d2
ParallelPort_WriteLoop_Step:
	add.l    d2,d5                                       ; Add register d2 to register d5
	bsr.w    ParallelPort_WriteBlock                     ; Call subroutine to ParallelPort_WriteBlock
	addq.w   #$1,$162a(a6)                               ; Add 1 to $162a(a6)
	subq.b   #$1,d6                                      ; Subtract 1 from register d6
	bne.b    ParallelPort_WriteLoop_Wait                 ; Branch to ParallelPort_WriteLoop_Wait if non-zero / not equal
	tst.b    $167e(a6)                             ; Check if $167e is set / active
	beq.b    ParallelPort_WriteLoop_Done                 ; Branch to ParallelPort_WriteLoop_Done if zero / equal
	movea.l  Var_MemStart(a6),a0                         ; Load monitored memory start offset into pointer a0
	move.w   #$400,d1                                    ; Move constant $400 to register d1
	move.w   #$200,d2                                    ; Move constant $200 to register d2
	bsr.w    ParallelPort_WriteBlock_Direct              ; Call subroutine to ParallelPort_WriteBlock_Direct
	moveq    #$6,d0                                      ; Initialize register d0 to constant $6
	move.b   DMACONR(a0),d1                              ; Move DMACON (DMA control write register) to register d1
	lsl.w    #$8,d1
	ori.b    #$1,d1                                      ; Logical OR register d1 with 1
	moveq    #$0,d2                                      ; Initialize register d2 to 0
	bsr.b    ParallelPort_SendPacketHeader               ; Call subroutine to ParallelPort_SendPacketHeader
	bra.b    ParallelPort_Action_PrintSuccess            ; Unconditional branch to ParallelPort_Action_PrintSuccess
ParallelPort_WriteLoop_Done:
	lea.l    $167c(a6),a0                                ; Load address of $167c(a6) into pointer a0
	move.b   #$3,(a0)                                    ; Move constant $3 to (a0)
	move.w   #$2001,d1                                   ; Move constant $2001 to register d1
	move.w   #$1,d2                                      ; Move 1 to register d2
	bsr.w    ParallelPort_WriteBlock_Direct              ; Call subroutine to ParallelPort_WriteBlock_Direct
ParallelPort_Action_PrintSuccess:
	lea.l    Str_TransferComplete(pc),a1                            ; Load address of Str_TransferComplete(pc) into pointer a1
ParallelPort_Action_PrintDone:
	bsr.w    PrintString                                 ; Call subroutine to PrintString
	st.b     d7
ParallelPort_Action_Rts:
	rts                                                  ; Return from subroutine
; ============================================================================
; Function: ParallelPort_SendCommand5
; Purpose : Sends a command opcode 5 with a parameter byte in d0 to the parallel port cracker.
; Inputs  : d0.b = Parameter byte.
;           a5 = Stack frame/return pointer.
; Outputs : None.
; Clobbers: d1, d2.
; ============================================================================
ParallelPort_SendCommand5:
	movem.l  d0/d3-d4,-(a7)                              ; Move multiple registers d0/d3-d4 to -(a7)
	moveq    #$0,d1                                      ; Initialize register d1 to 0
	move.b   d0,d1                                       ; Move register d0 to register d1
	moveq    #$5,d0                                      ; Initialize register d0 to constant $5
	moveq    #$0,d2                                      ; Initialize register d2 to 0
	bsr.b    ParallelPort_SendPacketHeader               ; Call subroutine to ParallelPort_SendPacketHeader
	movem.l  (a7)+,d0/d3-d4                              ; Move multiple registers (a7)+ to d0/d3-d4
	rts                                                  ; Return from subroutine
; ============================================================================
; Function: ParallelPort_SendPacketHeader
; Purpose : Sends a standard packet command header (opcode, address, transfer size) to the parallel port cracker.
; Inputs  : d0.b = Opcode.
;           d1.l = Target address / offset.
;           d2.l = Transfer byte size.
;           a5 = Stack frame/return pointer.
; Outputs : None.
; Clobbers: d3, d4.
; ============================================================================
ParallelPort_SendPacketHeader:
	movem.l  d3-d4,-(a7)                                 ; Move multiple registers d3-d4 to -(a7)
	bsr.b    ParallelPort_SendInitSequence               ; Call subroutine to ParallelPort_SendInitSequence
	moveq    #-127,d3                                    ; Initialize register d3 to constant -127
	move.b   d0,d4                                       ; Move register d0 to register d4
	bsr.b    ParallelPort_WriteByte                      ; Call subroutine to ParallelPort_WriteByte
	move.w   d1,d4                                       ; Move register d1 to register d4
	bsr.b    ParallelPort_WriteByte                      ; Call subroutine to ParallelPort_WriteByte
	lsr.w    #$8,d4
	bsr.b    ParallelPort_WriteByte                      ; Call subroutine to ParallelPort_WriteByte
	move.w   d2,d4                                       ; Move register d2 to register d4
	bsr.b    ParallelPort_WriteByte                      ; Call subroutine to ParallelPort_WriteByte
	lsr.w    #$8,d4
	bsr.b    ParallelPort_WriteByte                      ; Call subroutine to ParallelPort_WriteByte
	move.b   d3,d4                                       ; Move register d3 to register d4
	bsr.b    ParallelPort_WriteByte                      ; Call subroutine to ParallelPort_WriteByte
	movem.l  (a7)+,d3-d4                                 ; Move multiple registers (a7)+ to d3-d4
	rts                                                  ; Return from subroutine
ParallelPort_SendInitSequence:
	moveq    #-43,d4                                     ; Initialize register d4 to constant -43
	bsr.b    ParallelPort_WriteByte                      ; Call subroutine to ParallelPort_WriteByte
	moveq    #-86,d4                                     ; Initialize register d4 to constant -86
	bsr.b    ParallelPort_WriteByte                      ; Call subroutine to ParallelPort_WriteByte
	moveq    #DMACON-256,d4                              ; Initialize register d4 to DMACON (DMA control write register)
ParallelPort_WriteByte:
	eor.b    d4,d3                                       ; Logical XOR register d3 with register d4
	move.l   #$400000,d7                                 ; Move constant $400000 to register d7
ParallelPort_WaitBusyLoop:
	subq.l   #$1,d7                                      ; Subtract 1 from register d7
	beq.b    ParallelPort_WriteTimeout                   ; Branch to ParallelPort_WriteTimeout if zero / equal
	btst     #$0,$bfd000.l                               ; Test bit #$0 of $bfd000.l
	bne.b    ParallelPort_WaitBusyLoop                   ; Branch to ParallelPort_WaitBusyLoop if non-zero / not equal
	move.b   d4,CIAA_PRB.l                               ; Move register d4 to CIAA_PRB (CIA-A Port B data/control register)
	eori.b   #$4,$bfd000.l                               ; Logical XOR $bfd000.l with constant $4
	rts                                                  ; Return from subroutine
ParallelPort_WriteTimeout:
	movea.l  a5,a7                                       ; Move pointer a5 to stack pointer (a7)
	lea.l    Str_TransferTimeout(pc),a1                            ; Load address of Str_TransferTimeout(pc) into pointer a1
	bra.w    ParallelPort_Action_PrintDone               ; Unconditional branch to ParallelPort_Action_PrintDone
; ============================================================================
; Function: ParallelPort_WriteBlock
; Purpose : Writes a block of memory of size d2 from a0 to the parallel port cracker device.
; Inputs  : a0 = Source memory address.
;           d2.l = Transfer size in bytes.
;           a6 = Monitor context base.
;           a5 = Stack frame/return pointer.
; Outputs : None.
; Clobbers: d0-d4, a0.
; ============================================================================
ParallelPort_WriteBlock:
	movem.l  d0-d4/a0,-(a7)                              ; Move multiple registers d0-d4/a0 to -(a7)
	moveq    #$0,d0                                      ; Initialize register d0 to 0
	tst.b    $167d(a6)                             ; Check if $167d is set / active
	beq.b    ParallelPort_WriteBlock_Direct_Header       ; Branch to ParallelPort_WriteBlock_Direct_Header if zero / equal
	bsr.b    ParallelPort_SendPacketHeader               ; Call subroutine to ParallelPort_SendPacketHeader
	moveq    #-127,d3                                    ; Initialize register d3 to constant -127
	bsr.b    ParallelPort_WriteBlock_Compressed          ; Call subroutine to ParallelPort_WriteBlock_Compressed
	lea.l    -$4001(a0),a0                               ; Load address of -$4001(a0) into pointer a0
	pea.l    ParallelPort_WriteBlock_Direct_Continuation(pc)                         ; Push effective address of ParallelPort_WriteBlock_Direct_Continuation(pc) onto stack.
ParallelPort_WriteBlock_Compressed:
	move.w   #$1fff,d2                                   ; Move constant $1fff to register d2
ParallelPort_WriteBlock_Compressed_Loop:
	addq.w   #$1,a0                                      ; Add 1 to pointer a0
	move.b   (a0)+,d4                                    ; Move (a0)+ to register d4
	bsr.b    ParallelPort_WriteByte                      ; Call subroutine to ParallelPort_WriteByte
	dbra     d2,ParallelPort_WriteBlock_Compressed_Loop  ; Decrement loop counter d2 and loop back to ParallelPort_WriteBlock_Compressed_Loop if not exhausted
	rts                                                  ; Return from subroutine
ParallelPort_WriteBlock_Direct:
	movem.l  d0-d4/a0,-(a7)                              ; Move multiple registers d0-d4/a0 to -(a7)
	moveq    #$0,d0                                      ; Initialize register d0 to 0
ParallelPort_WriteBlock_Direct_Header:
	bsr.w    ParallelPort_SendPacketHeader               ; Call subroutine to ParallelPort_SendPacketHeader
	subq.w   #$1,d2                                      ; Subtract 1 from register d2
	moveq    #-127,d3                                    ; Initialize register d3 to constant -127
ParallelPort_WriteBlock_Direct_Loop:
	move.b   (a0)+,d4                                    ; Move (a0)+ to register d4
	bsr.b    ParallelPort_WriteByte                      ; Call subroutine to ParallelPort_WriteByte
	dbra     d2,ParallelPort_WriteBlock_Direct_Loop      ; Decrement loop counter d2 and loop back to ParallelPort_WriteBlock_Direct_Loop if not exhausted
; ============================================================================
; Data Block: ParallelPort_WriteBlock_Direct_Continuation
; Purpose   : Continuation block for parallel port direct block write.
; ============================================================================
ParallelPort_WriteBlock_Direct_Continuation:
	move.b   d3,d4                                       ; Move register d3 to register d4
	bsr.b    ParallelPort_WriteByte                      ; Call subroutine to ParallelPort_WriteByte
	movem.l  (a7)+,d0-d4/a0                              ; Move multiple registers (a7)+ to d0-d4/a0
	rts                                                  ; Return from subroutine
	tst.b    d3                                          ; Test status of register d3 (for zero or negative)
	bne.w    Console_FormatExceptionDumps_Exit           ; Branch to Console_FormatExceptionDumps_Exit if non-zero / not equal
	lea.l    Var_DisasmBuffer+1(a6),a0                   ; Load address of disassembler output text buffer into pointer a0
	lea.l    $dff096.l,a1                                ; Load address of $dff096.l into pointer a1
	move.l   a1,d0                                       ; Move pointer a1 to register d0
	bsr.w    PrintHex6                                   ; Call subroutine to PrintHex6
	moveq    #$3a,d4                                     ; Initialize register d4 to constant $3a
	move.b   d4,(a0)+                                    ; Move register d4 to (a0)+
	move.w   $1612(a6),d0                                ; Move $1612(a6) to register d0
	bsr.w    PrintHex4_Entry                             ; Call subroutine to PrintHex4_Entry
	addq.w   #$2,a0                                      ; Add constant $2 to pointer a0
	addq.w   #$4,a1                                      ; Add constant $4 to pointer a1
	move.l   a1,d0                                       ; Move pointer a1 to register d0
	bsr.w    PrintHex6                                   ; Call subroutine to PrintHex6
	move.b   d4,(a0)+                                    ; Move register d4 to (a0)+
	move.w   $1616(a6),d0                                ; Move $1616(a6) to register d0
	bsr.w    PrintHex4_Entry                             ; Call subroutine to PrintHex4_Entry
	addq.w   #$2,a0                                      ; Add constant $2 to pointer a0
	addq.w   #$2,a1                                      ; Add constant $2 to pointer a1
	move.l   a1,d0                                       ; Move pointer a1 to register d0
	bsr.w    PrintHex6                                   ; Call subroutine to PrintHex6
	move.b   d4,(a0)+                                    ; Move register d4 to (a0)+
	move.w   $1618(a6),d0                                ; Move $1618(a6) to register d0
	bsr.w    PrintHex4_Entry                             ; Call subroutine to PrintHex4_Entry
	addq.w   #$2,a0                                      ; Add constant $2 to pointer a0
	addq.w   #$2,a1                                      ; Add constant $2 to pointer a1
	move.l   a1,d0                                       ; Move pointer a1 to register d0
	bsr.w    PrintHex6                                   ; Call subroutine to PrintHex6
	move.b   d4,(a0)+                                    ; Move register d4 to (a0)+
	move.w   $1614(a6),d0                                ; Move $1614(a6) to register d0
	bsr.w    PrintHex4_Entry                             ; Call subroutine to PrintHex4_Entry
	bsr.w    RefreshAndDrawConsoleLine                   ; Call subroutine to RefreshAndDrawConsoleLine
	bsr.w    Console_CursorNextLine                      ; Call subroutine to Console_CursorNextLine
	lea.l    Var_ExceptionBkp(a6),a1                     ; Load address of Var_ExceptionBkp(a6) into pointer a1
	moveq    #$7,d3                                      ; Initialize register d3 to constant $7
; ============================================================================
; Function: Console_FormatExceptionDumps
; Purpose : Formats and prints the saved CPU registers and exception vector context to the console screen.
; Inputs  : a0 = Console buffer cursor pointer.
;           a6 = Monitor context base.
; Outputs : None.
; Clobbers: d0-d3, a0-a1.
; ============================================================================
Console_FormatExceptionDumps:
	addq.w   #$1,a0                                      ; Add 1 to pointer a0
	moveq    #$7,d0                                      ; Initialize register d0 to constant $7
	sub.l    d3,d0                                       ; Subtract register d3 from register d0
	lsl.l    #$5,d0
	bsr.w    FormatHex4                                  ; Call subroutine to FormatHex4
	move.b   #$3a,(a0)+                                  ; Move constant $3a to (a0)+
	moveq    #$7,d2                                      ; Initialize register d2 to constant $7
Console_FormatExceptionDumps_Values:
	addq.w   #$1,a0                                      ; Add 1 to pointer a0
	move.l   (a1)+,d0                                    ; Move (a1)+ to register d0
	bsr.w    FormatHex8                                  ; Call subroutine to FormatHex8
	dbra     d2,Console_FormatExceptionDumps_Values      ; Decrement loop counter d2 and loop back to Console_FormatExceptionDumps_Values if not exhausted
	bsr.w    RefreshAndDrawConsoleLine                   ; Call subroutine to RefreshAndDrawConsoleLine
	dbra     d3,Console_FormatExceptionDumps             ; Decrement loop counter d3 and loop back to Console_FormatExceptionDumps if not exhausted
	st.b     d7
Console_FormatExceptionDumps_Exit:
	rts                                                  ; Return from subroutine
	cmpi.b   #$2,d3                                      ; Compare register d3 against constant $2
	bcs.w    SerialPort_Rts                              ; Branch to SerialPort_Rts if carry set (less than)
	cmpi.b   #$3,d3                                      ; Compare register d3 against constant $3
	bhi.w    SerialPort_Rts                              ; Branch to SerialPort_Rts if higher.
	beq.b    Console_FormatExceptionDumps_Exit_Loc_4354  ; Branch to Console_FormatExceptionDumps_Exit_Loc_4354 if zero / equal
	move.w   #BPLCON0,$182a(a6)                          ; Move BPLCON0 (bitplane control register 0) to $182a(a6)
Console_FormatExceptionDumps_Exit_Loc_4354:
	moveq    #$0,d0                                      ; Initialize register d0 to 0
	btst     d0,$1823(a6)                                ; Test bit d0 of $1823(a6)
	bne.b    SerialPort_Rts                              ; Branch to SerialPort_Rts if non-zero / not equal
	btst     d0,$1827(a6)                                ; Test bit d0 of $1827(a6)
	bne.b    SerialPort_Rts                              ; Branch to SerialPort_Rts if non-zero / not equal
	move.l   Var_MemStart(a6),d0                         ; Load monitored memory start offset into register d0
	cmp.l    Var_MemEnd(a6),d0                           ; Compare register d0 against monitored memory end offset
	bcc.b    SerialPort_Rts                              ; Branch to SerialPort_Rts if carry clear (greater or equal)
	cmp.l    Var_MemoryLimit(a6),d0                      ; Compare register d0 against upper bound of monitored memory
	bcc.b    SerialPort_Rts                              ; Branch to SerialPort_Rts if carry clear (greater or equal)
	move.l   Var_MemEnd(a6),d1                           ; Load monitored memory end offset into register d1
	cmp.l    Var_MemoryLimit(a6),d1                      ; Compare register d1 against upper bound of monitored memory
	bhi.b    SerialPort_Rts                              ; Branch to SerialPort_Rts if higher.
	move.l   #$80808080,$dff09a.l                        ; Move constant $80808080 to $dff09a.l
SerialPort_TransferLoop:
	bsr.b    SerialPort_UpdateProgress                   ; Call subroutine to SerialPort_UpdateProgress
	cmpi.b   #$1b,Var_LockFlag(a6)                       ; Compare monitor lock status against constant $1b
	beq.b    SerialPort_TransferExit                     ; Branch to SerialPort_TransferExit if zero / equal
	tst.l    Var_MemEnd(a6)                        ; Check if Var_MemEnd is set / active
	bne.b    SerialPort_TransferLoop                     ; Branch to SerialPort_TransferLoop if non-zero / not equal
	btst     #$7,$dff01f.l                               ; Test bit #$7 of $dff01f.l
	beq.b    SerialPort_TransferLoop                     ; Branch to SerialPort_TransferLoop if zero / equal
SerialPort_TransferExit:
	move.l   #$800080,$dff09a.l                          ; Move constant $800080 to $dff09a.l
	move.w   #$3,$dff096.l                               ; Move constant $3 to $dff096.l
	bsr.b    SerialPort_UpdateProgress                   ; Call subroutine to SerialPort_UpdateProgress
	bsr.w    Console_CursorNextLine                      ; Call subroutine to Console_CursorNextLine
	st.b     d7
SerialPort_Rts:
	rts                                                  ; Return from subroutine
SerialPort_UpdateProgress:
	lea.l    Var_DisasmBuffer+1(a6),a0                   ; Load address of disassembler output text buffer into pointer a0
	lea.l    Str_SoundAddress(pc),a1                            ; Load address of Str_SoundAddress(pc) into pointer a1
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	move.l   Var_MemStart(a6),d0                         ; Load monitored memory start offset into register d0
	bsr.w    PrintHex6                                   ; Call subroutine to PrintHex6
	bsr.w    RefreshAndDrawConsoleLine                   ; Call subroutine to RefreshAndDrawConsoleLine
	bra.w    Console_OpenMenu                            ; Unconditional branch to Console_OpenMenu
	cmpi.b   #$1,d3                                      ; Compare register d3 against 1
	bne.w    Exception_SaveContext_Exit                  ; Branch to Exception_SaveContext_Exit if non-zero / not equal
	move.l   Var_MemStart(a6),d0                         ; Load monitored memory start offset into register d0
	btst     #$0,d0                                      ; Test bit #$0 of register d0
	bne.w    Exception_SaveContext_Exit                  ; Branch to Exception_SaveContext_Exit if non-zero / not equal
	lea.l    Fpu_Helper_ReadReg(pc),a0                            ; Load address of Fpu_Helper_ReadReg(pc) into pointer a0
	bsr.w    Fpu_ExecuteHelperProtected                  ; Call subroutine to Fpu_ExecuteHelperProtected
	move.l   d0,$15ee(a6)                                ; Move register d0 to $15ee(a6)
	bsr.w    Breakpoints_SwapOpcodes                     ; Call subroutine to Breakpoints_SwapOpcodes
	bsr.w    SetupFPUSafetyHandler                       ; Call subroutine to SetupFPUSafetyHandler
	bsr.w    RestoreFPURegisters                         ; Call subroutine to RestoreFPURegisters
	move.w   #$3700,sr                             ; Disable interrupts and set supervisor mode
	movea.l  Var_MspSaved(a6),a7                         ; Load saved Master Stack Pointer (MSP) state into stack pointer (a7)
	move.w   #$2700,sr                             ; Disable interrupts and set supervisor mode
	movea.l  Var_SavedSSP(a6),a7                         ; Load saved supervisor stack pointer into stack pointer (a7)
	tst.b    Var_CpuType(a6)                       ; Check if Var_CpuType is set / active
	beq.b    ExitMonitor_RestoreUserContext              ; Branch to ExitMonitor_RestoreUserContext if zero / equal
	movea.l  Var_VbrPointer(a6),a5                       ; Load active Vector Base Register (VBR) pointer into pointer a5
	movec    a5,vbr                                      ; Write control register VBR from pointer a5
	move.b   Var_SfcSaved(a6),d0                         ; Load saved Source Function Code (SFC) state into register d0
	movec    d0,sfc                                      ; Write control register SFC from register d0
	move.b   Var_DfcSaved(a6),d0                         ; Load saved Destination Function Code (DFC) state into register d0
	movec    d0,dfc                                      ; Write control register DFC from register d0
	cmpi.b   #$2,Var_CpuType(a6)                         ; Compare detected CPU type against constant $2
	bcs.b    ExitMonitor_RestoreUserContext              ; Branch to ExitMonitor_RestoreUserContext if carry set (less than)
	movea.l  Var_CacrSaved(a6),a5                        ; Load saved Cache Control Register (CACR) state into pointer a5
	movec    a5,cacr                                     ; Write control register CACR from pointer a5
	bsr.w    CacheFlush_040                              ; Call subroutine to CacheFlush_040
	cmpi.b   #$4,Var_CpuType(a6)                         ; Compare detected CPU type against constant $4
	beq.b    ExitMonitor_RestoreUserContext              ; Branch to ExitMonitor_RestoreUserContext if zero / equal
	movea.l  Var_CaarSaved(a6),a5                        ; Load saved Cache Address Register (CAAR) state into pointer a5
	movec    a5,caar                                     ; Write control register CAAR from pointer a5
; ============================================================================
; Function: ExitMonitor_RestoreUserContext
; Purpose : Restores the user program registers, stack pointers, VBR, and cache state, returning CPU execution back to the user context.
; Inputs  : a6 = Monitor context base.
; Outputs : Resumes execution of the user program.
; Notes   : Exits Supervisor mode, restores CACR/CAAR/USP/SR, and pops registers.
; ============================================================================
ExitMonitor_RestoreUserContext:
	movea.l  Var_SavedUSP(a6),a0                         ; Load saved user stack pointer into pointer a0
	move     a0,usp                                      ; Write User Stack Pointer (USP) from pointer a0
	move.w   Var_CpuStatus(a6),d0                        ; Load Var_CpuStatus(a6) into register d0
	andi.w   #$3fff,d0                                   ; Logical AND register d0 with constant $3fff
	move.w   d0,sr                                       ; Set Status Register (SR) value to register d0
	pea.l    Breakpoint_Entry(pc)                         ; Push effective address of Breakpoint_Entry(pc) onto stack.
	move.l   Var_MemStart(a6),-(a7)                      ; Load monitored memory start offset into -(a7)
	move.w   Var_CpuStatus(a6),ccr                       ; Load Var_CpuStatus(a6) into ccr
	movem.l  Var_RegsSaved(a6),d0-d7/a0-a6               ; Restore registers d0-d7/a0-a6 from context storage area
	rts                                                  ; Return from subroutine
; ============================================================================
; Function: Breakpoint_Entry
; Purpose : Debugger breakpoint exception trap entry point.
; Notes   : Invoked by illegal instructions or exceptions. Saves full CPU context
;           and transfers control back to the monitor command loop.
; ============================================================================
Breakpoint_Entry:
	movem.l  a6,-(a7)                                    ; Move multiple registers a6 to -(a7)
	lea.l    Disasm_OpcodeMaskTable(pc),a6                            ; Load address of Disasm_OpcodeMaskTable(pc) into monitor context base (a6)
	movem.l  d0-d7/a0-a5,Var_RegsSaved(a6)               ; Save registers d0-d7/a0-a5 to context storage area
	movem.l  (a7)+,a0                                    ; Move multiple registers (a7)+ to a0
	movem.l  a0/a7,Var_UserA0(a6)                        ; Move multiple registers a0/a7 to Var_UserA0(a6)
	lea.l    Var_FontData(a6),a7                         ; Load address of font glyph data pointer into stack pointer (a7)
	movea.l  a7,a3                                       ; Move stack pointer (a7) to pointer a3
	lea.l    $10.w,a0                                    ; Load address of $10.w into pointer a0
	adda.l   Var_VbrPointer(a6),a0                       ; Add active Vector Base Register (VBR) pointer to pointer a0
	movea.l  (a0),a1                                     ; Move (a0) to pointer a1
	lea.l    Handler_SupervisorTrick(pc),a2                            ; Load address of Handler_SupervisorTrick(pc) into pointer a2
	movem.l  a2,(a0)                                     ; Move multiple registers a2 to (a0)
Breakpoint_Trigger:
	illegal  #$4afc                                      ; Trigger exception (illegal instruction)
	move.l   a1,(a0)                                     ; Move pointer a1 to (a0)
	move.l   a7,Var_SavedSSP(a6)                         ; Store stack pointer (a7) into saved supervisor stack pointer
	move     usp,a7                                      ; Read User Stack Pointer (USP) into stack pointer (a7)
	move.l   a7,Var_SavedUSP(a6)                         ; Store stack pointer (a7) into saved user stack pointer
	movea.l  a3,a7                                       ; Move pointer a3 to stack pointer (a7)
	tst.b    Var_CpuType(a6)                       ; Check if Var_CpuType is set / active
	beq.b    Exception_SaveContext_End                   ; Branch to Exception_SaveContext_End if zero / equal
	movec    vbr,a5                                      ; Read control register VBR into pointer a5
	move.l   a5,Var_VbrPointer(a6)                       ; Store pointer a5 into active Vector Base Register (VBR) pointer
	movec    dfc,d0                                      ; Read control register DFC into register d0
	move.w   d0,-(a7)                                    ; Move register d0 to -(a7)
	movec    sfc,d0                                      ; Read control register SFC into register d0
	lsl.w    #$8,d0
	or.w     (a7)+,d0                                    ; Logical OR register d0 with (a7)+
	move.w   d0,Var_SfcSaved(a6)                         ; Store register d0 into saved Source Function Code (SFC) state
	cmpi.b   #$2,Var_CpuType(a6)                         ; Compare detected CPU type against constant $2
	bcs.b    Exception_SaveContext_End                   ; Branch to Exception_SaveContext_End if carry set (less than)
	movec    msp,a5                                      ; Read control register MSP into pointer a5
	move.l   a5,Var_MspSaved(a6)                         ; Store pointer a5 into saved Master Stack Pointer (MSP) state
	movec    cacr,a5                                     ; Read control register CACR into pointer a5
	move.l   a5,Var_CacrSaved(a6)                        ; Store pointer a5 into saved Cache Control Register (CACR) state
	cmpi.b   #$4,Var_CpuType(a6)                         ; Compare detected CPU type against constant $4
	beq.b    Exception_SaveContext_End                   ; Branch to Exception_SaveContext_End if zero / equal
	movec    caar,a5                                     ; Read control register CAAR into pointer a5
	move.l   a5,Var_CaarSaved(a6)                        ; Store pointer a5 into saved Cache Address Register (CAAR) state
Exception_SaveContext_End:
	move.w   Var_CpuStatus(a6),d0                        ; Load Var_CpuStatus(a6) into register d0
	lea.l    Var_UserSP(a6),a1                           ; Load address of Var_UserSP(a6) into pointer a1
	movea.l  (a1)+,a0                                    ; Move (a1)+ to pointer a0
	btst     #$d,d0                                      ; Test bit #$d of register d0
	beq.b    Exception_SaveContext_SP                    ; Branch to Exception_SaveContext_SP if zero / equal
	addq.w   #$4,a1                                      ; Add constant $4 to pointer a1
	btst     #$c,d0                                      ; Test bit #$c of register d0
	beq.b    Exception_SaveContext_SP                    ; Branch to Exception_SaveContext_SP if zero / equal
	addq.w   #$4,a1                                      ; Add constant $4 to pointer a1
Exception_SaveContext_SP:
	move.l   a0,(a1)                                     ; Move pointer a0 to (a1)
	bsr.w    ConvertFPURegisters                         ; Call subroutine to ConvertFPURegisters
	bsr.w    SaveFPURegisters                            ; Call subroutine to SaveFPURegisters
	lea.l    Fpu_Helper_ClearBit(pc),a0                            ; Load address of Fpu_Helper_ClearBit(pc) into pointer a0
	bsr.b    Fpu_ExecuteHelperProtected                  ; Call subroutine to Fpu_ExecuteHelperProtected
	bsr.b    Breakpoints_SwapOpcodes                     ; Call subroutine to Breakpoints_SwapOpcodes
	move.l   $15ee(a6),d0                                ; Move $15ee(a6) to register d0
	lea.l    Fpu_Helper_WriteReg(pc),a0                            ; Load address of Fpu_Helper_WriteReg(pc) into pointer a0
	bsr.b    Fpu_ExecuteHelperProtected                  ; Call subroutine to Fpu_ExecuteHelperProtected
	lea.l    Breakpoint_Trigger(pc),a1                   ; Load address of Breakpoint_Trigger(pc) into pointer a1
	cmpa.l   Var_SrpSaved(a6),a1                         ; Compare pointer a1 against saved exception instruction PC (SRP)
	bne.b    Exception_SaveContext_CheckBreak            ; Branch to Exception_SaveContext_CheckBreak if non-zero / not equal
	clr.l    Var_SrpSaved(a6)                            ; Clear / reset saved exception instruction PC (SRP)
Exception_SaveContext_CheckBreak:
	bra.w    Monitor_WarmStart                           ; Unconditional branch to Monitor_WarmStart
Exception_SaveContext_Exit:
	rts                                                  ; Return from subroutine
; ============================================================================
; Function: Fpu_ExecuteHelperProtected
; Purpose : Executes an FPU instruction sequence with FPU model verification and Line-F safety checks.
; Inputs  : a0 = Pointer to FPU function to execute.
;           a2 = Pointer to FPU context buffer.
;           a6 = Monitor context base.
; Notes   : Avoids FPU crashes on machines without floating point units.
; ============================================================================
Fpu_ExecuteHelperProtected:
	tst.b    Var_FpuModel(a6)                      ; Check if Var_FpuModel is set / active
	beq.b    Fpu_ExecuteHelperProtected_Exit             ; Branch to Fpu_ExecuteHelperProtected_Exit if zero / equal
	cmpi.b   #$3,Var_FpuModel(a6)                        ; Compare detected FPU model against constant $3
	beq.b    Fpu_ExecuteHelperProtected_Exit             ; Branch to Fpu_ExecuteHelperProtected_Exit if zero / equal
	lea.l    $15f2(a6),a2                                ; Load address of $15f2(a6) into pointer a2
	dc.w     $F012,$4200                           ; fmove.l (a2),fp4 (using coprocessor ID 0)
	jsr      (a0)                                        ; Jump to subroutine via pointer (a0)
	dc.w     $F012,$4000                           ; fmove.l (a2),fp0 (using coprocessor ID 0)
Fpu_ExecuteHelperProtected_Exit:
	rts                                                  ; Return from subroutine
; ============================================================================
; Data Block: Fpu_Helper_ReadReg
; Purpose   : Fpu helper code block to read FPU status/control registers.
; ============================================================================
Fpu_Helper_ReadReg:
	move.l   (a2),d0                                     ; Move (a2) to register d0
; ============================================================================
; Data Block: Fpu_Helper_ClearBit
; Purpose   : Fpu helper code block to clear status register bits.
; ============================================================================
Fpu_Helper_ClearBit:
	bclr     #$7,(a2)                                    ; Clear bit #$7 of (a2)
	rts                                                  ; Return from subroutine
; ============================================================================
; Data Block: Fpu_Helper_WriteReg
; Purpose   : Fpu helper code block to write FPU status/control registers.
; ============================================================================
Fpu_Helper_WriteReg:
	move.l   d0,(a2)                                     ; Move register d0 to (a2)
	rts                                                  ; Return from subroutine
	bset     #$7,(a2)                                    ; Set bit #$7 of (a2)
	rts                                                  ; Return from subroutine
; ============================================================================
; Function: Breakpoints_SwapOpcodes
; Purpose : Swaps breakpoint instruction opcodes between the active user code and the monitor breakpoint table.
; Inputs  : a6 = Monitor context base.
; Notes   : Inserts or removes the trap opcodes in user memory to activate or deactivate breakpoints.
; ============================================================================
Breakpoints_SwapOpcodes:
	moveq    #$9,d0                                      ; Initialize register d0 to constant $9
	lea.l    Var_Breakpoints(a6),a0                      ; Load address of breakpoint table structure pointer into pointer a0
	lea.l    $1988(a6),a1                                ; Load address of $1988(a6) into pointer a1
Breakpoints_SwapOpcodes_Loop:
	movea.l  (a0)+,a2                                    ; Move (a0)+ to pointer a2
	move.l   a2,d1                                       ; Move pointer a2 to register d1
	beq.b    Breakpoints_SwapOpcodes_Next                ; Branch to Breakpoints_SwapOpcodes_Next if zero / equal
	move.w   (a2),-(a7)                                  ; Move (a2) to -(a7)
	move.w   (a1),(a2)                                   ; Move (a1) to (a2)
	move.w   (a7)+,(a1)+                                 ; Move (a7)+ to (a1)+
Breakpoints_SwapOpcodes_Next:
	dbra     d0,Breakpoints_SwapOpcodes_Loop             ; Decrement loop counter d0 and loop back to Breakpoints_SwapOpcodes_Loop if not exhausted
; ============================================================================
; Function: CacheFlush_040
; Purpose : Push and invalidate CPU caches on MC68040.
; ============================================================================
CacheFlush_040:
	cmpi.b   #$4,Var_CpuType(a6)                         ; Compare detected CPU type against constant $4
	bne.b    CacheFlush_040_Loc_45A0                     ; Branch to CacheFlush_040_Loc_45A0 if non-zero / not equal
	mc68040
	cpusha   bc                                    ; Execute cpusha instruction
	mc68030
CacheFlush_040_Loc_45A0:
	rts                                                  ; Return from subroutine
; ============================================================================
; Function: CacheFlush_020_030
; Purpose : Invalidate instruction/data caches on MC68020/68030.
; ============================================================================
CacheFlush_020_030:
	; On 68040 we use the dedicated cpusha (done in the 040-specific flush).
	; On 020/030 we must manually invalidate the caches before/after certain memory operations
	; (like the range copy and de-obfuscation below) so that the CPU sees the new data/code
	; that was written by the monitor or that will be executed after the obfuscated payload
	; is decrypted. This is critical for the "nasty" takeover and self-relocation to work
	; reliably on cached CPUs.
	cmpi.b   #$4,Var_CpuType(a6)                         ; Compare detected CPU type against constant $4
	bne.b    CacheFlush_020_030_DoFlush                  ; Branch to CacheFlush_020_030_DoFlush if non-zero / not equal
	rts                                                  ; Return from subroutine
CacheFlush_020_030_DoFlush:
	cmpi.b   #$2,Var_CpuType(a6)                         ; Compare detected CPU type against constant $2
	bcs.b    CacheFlush_020_030_Done                     ; Branch to CacheFlush_020_030_Done if carry set (less than)
	move.l   d0,-(a7)                                    ; Move register d0 to -(a7)
	movec    cacr,d0                                     ; Read control register CACR into register d0
	ori.w    #$808,d0                                    ; Logical OR register d0 with constant $808
	movec    d0,cacr                                     ; Write control register CACR from register d0
	move.l   (a7)+,d0                                    ; Move (a7)+ to register d0
CacheFlush_020_030_Done:
	rts                                                  ; Return from subroutine
; This following routine (no label in original - falls through or called after cache flush in the
; loader/install path) takes a source range (from Var_MemStart / d2 base, d4/d5/d6 related to source/target)
; and copies it to a target while avoiding custom chip space, then patches a standard Amiga HUNK_HEADER
; (from HunkHeader_MonitorExecutable) into the target to make it a valid loadable executable image, updates relocation/
; size fields in the hunk, prints the installed range for the user, refreshes the screen, and then
; falls into the de-obfuscation bootstrap that disables all DMA/INT and decrypts+executes the real
; monitor code from the obfuscated payload. This is the final stage of BeerMon's "nasty" loader that
; allows it to relocate itself, de-obfuscate its own code (anti-tamper), and take over $0 memory.
	movem.l  Var_MemStart(a6),d2/d4-d6                   ; Move multiple registers Var_MemStart(a6) to d2/d4-d6
	btst     #$0,d2                                      ; Test bit #$0 of register d2
	bne.b    CopyRange_OverlapsCustomChipOrDone          ; Branch to CopyRange_OverlapsCustomChipOrDone if non-zero / not equal
	subq.l   #$2,d3                                      ; Subtract constant $2 from register d3
	bmi.b    CopyRange_OverlapsCustomChipOrDone          ; Branch to CopyRange_OverlapsCustomChipOrDone if negative / minus
	bne.b    CopyRange_UseD2ForD5                        ; Branch to CopyRange_UseD2ForD5 if non-zero / not equal
	move.l   d2,d5                                       ; Move register d2 to register d5
CopyRange_UseD2ForD5:
	subq.l   #$2,d3                                      ; Subtract constant $2 from register d3
	bmi.b    CopyRange_SetD6FromD5                       ; Branch to CopyRange_SetD6FromD5 if negative / minus
	beq.b    CopyRange_DoTheCopy                         ; Branch to CopyRange_DoTheCopy if zero / equal
CopyRange_OverlapsCustomChipOrDone:
	rts                                                  ; Return from subroutine
CopyRange_SetD6FromD5:
	move.l   d5,d6                                       ; Move register d5 to register d6
CopyRange_DoTheCopy:
	lea.l    BPLCON0.w,a0                                ; Load address of BPLCON0 (bitplane control register 0) into pointer a0
	cmp.l    a0,d2                                       ; Compare register d2 against pointer a0
	bcs.b    CopyRange_OverlapsCustomChipOrDone    ; Source overlaps custom chips? Abort
	move.l   d4,d3                                       ; Move register d4 to register d3
	sub.l    d2,d3                                       ; Subtract register d2 from register d3
	bmi.b    CopyRange_OverlapsCustomChipOrDone          ; Branch to CopyRange_OverlapsCustomChipOrDone if negative / minus
	move.l   d3,d0                                       ; Move register d3 to register d0
	movea.l  d4,a0                                       ; Move register d4 to pointer a0
	movea.l  d2,a1                                       ; Move register d2 to pointer a1
CopyRange_ByteLoop:
	subq.l   #$1,d0                                      ; Subtract 1 from register d0
	bmi.b    CopyRange_PatchHunkHeader                   ; Branch to CopyRange_PatchHunkHeader if negative / minus
	move.b   -(a0),DENISEID(a0)                          ; Move -(a0) to DENISEID (Denise chip ID register)
	bra.b    CopyRange_ByteLoop                          ; Unconditional branch to CopyRange_ByteLoop
CopyRange_PatchHunkHeader:
	lea.l    HunkHeader_MonitorExecutable(pc),a0         ; Load address of HunkHeader_MonitorExecutable(pc) into pointer a0
	moveq    #$7b,d0                                     ; Initialize register d0 to constant $7b
CopyRange_CopyHunkHeaderLoop:
	move.b   (a0)+,(a1)+                                 ; Copy word/byte data from source pointer a0 to destination a1
	dbra     d0,CopyRange_CopyHunkHeaderLoop             ; Decrement loop counter d0 and loop back to CopyRange_CopyHunkHeaderLoop if not exhausted
	movea.l  d2,a0                                       ; Move register d2 to pointer a0
	move.l   d3,POTGPTR(a0)                              ; Move register d3 to POTGPTR (potentiometer port status register)
	move.l   d5,$3e(a0)                                  ; Move register d5 to $3e(a0)
	move.l   d6,$4a(a0)                                  ; Move register d6 to $4a(a0)
	addq.l   #$3,d3                                      ; Add constant $3 to register d3
	lsr.l    #$2,d3
	moveq    #$17,d0                                     ; Initialize register d0 to constant $17
	add.l    d0,d3                                       ; Add register d0 to register d3
	move.l   d3,$14(a0)                                  ; Move register d3 to $14(a0)
	move.l   d3,$1c(a0)                                  ; Move register d3 to $1c(a0)
	lsl.l    #$2,d3
	add.l    d2,d3                                       ; Add register d2 to register d3
	lea.l    $20.w,a3                                    ; Load address of $20.w into pointer a3
	adda.l   d3,a3                                       ; Add register d3 to pointer a3
	lea.l    $3f2.w,a0                                   ; Load address of $3f2.w into pointer a0
	move.l   a0,(a3)+                                    ; Move pointer a0 to (a3)+
	move.l   a0,(a3)+                                    ; Move pointer a0 to (a3)+
	lea.l    Var_DisasmBuffer+1(a6),a0                   ; Load address of disassembler output text buffer into pointer a0
	lea.l    Str_ObjectCreated(pc),a1                            ; Load address of Str_ObjectCreated(pc) into pointer a1
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	move.l   d2,d0                                       ; Move register d2 to register d0
	move.l   a3,d1                                       ; Move pointer a3 to register d1
	bsr.w    FormatAddressRange8                         ; Call subroutine to FormatAddressRange8
	bsr.w    RefreshAndDrawConsoleLine                   ; Call subroutine to RefreshAndDrawConsoleLine
	st.b     d7
	rts                                                  ; Return from subroutine
HunkHeader_MonitorExecutable:
	; This is the standard AmigaDOS hunk header that is patched into the target memory image.
	; It turns whatever was at the source range into a valid loadable executable (HUNK_HEADER + HUNK_CODE).
	; The real (obfuscated) monitor payload follows this header in the original file; the loader
	; copies the header + decrypts the payload on top of it so the final image at low memory is
	; a proper runnable Moni that the system (or the trampoline) can start.
	dc.b     $00,$00,$03,$F3,$00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00; HUNK_HEADER (magic, sizes, etc.)
	dc.b     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$E9,$00,$00,$00,$00; HUNK_CODE
	move.l   #$7fff7fff,$dff09a.l                        ; Move constant $7fff7fff to $dff09a.l
	move.w   #$0,$dff096.l                               ; Move 0 to $dff096.l
	move.l   #$0,d7                                      ; Move 0 to register d7
	lea.l    MonitorLoop_Entry(pc),a4                    ; Load address of MonitorLoop_Entry(pc) into pointer a4
	lea.l    $0.l,a5                                     ; Load address of $0.l into pointer a5
	lea.l    $80000.l,a7                                 ; Load address of $80000.l into stack pointer (a7)
	pea.l    $0.l                                  ; Push a dummy return address (the real code will never return)
	movem.w  ObfuscatedCopyLoop(pc),d0-d4                ; Move multiple registers ObfuscatedCopyLoop(pc) to d0-d4
	cmpa.l   a5,a4                                       ; Compare pointer a4 against pointer a5
	bhi.b    ObfuscatedCopyLoop_AdjustDelta
	eori.w   #$1f8,d2                              ; Apply part of the static de-obfuscation transform (the eori key is spread across the words)
	adda.l   d7,a4                                       ; Add register d7 to pointer a4
	adda.l   d7,a5                                       ; Add register d7 to pointer a5
ObfuscatedCopyLoop_AdjustDelta:
	; Write the (now partially decrypted) 5 words directly into BPLCON0. Because BPLCON0 is a custom-chip register it is both writable from the CPU *and* executable as code from the 68000's point of view when we jump to it.
	; This creates a tiny trampoline in a location that is guaranteed to be safe and visible even while the rest of the system is being taken over.
	lea.l    BPLCON0.w,a1                                ; Load address of BPLCON0 (bitplane control register 0) into pointer a1
	movem.w  d0-d4,(a1)                                  ; Move multiple registers d0-d4 to (a1)
	jmp      (a1)
	clr.w    d5                                          ; Clear / reset register d5
	dc.w     $4552
	dc.w     $3139
	dc.w     $3933
; ============================================================================
; Function: ObfuscatedCopyLoop
; Purpose : Decrypts/copies a block of monitor code/data from a4 to a5.
; ============================================================================
ObfuscatedCopyLoop:
	; This is the actual decryption loop (called after the initial setup above has prepared a4/a5/d7 and written the first chunk to the BPLCON0 trampoline).
	; It copies one byte at a time from the obfuscated image (a4) to the target low memory (a5), decrementing the remaining length in d7.
	; When d7 goes negative the copy is complete and we return (the jmp via the trampoline has already started the real code, or this finishes the payload).
	subq.l   #$1,d7                                      ; Subtract 1 from register d7
	bmi.b    ObfuscatedCopyLoop_Exit               ; Done (negative means we copied the exact amount)
	move.b   (a4)+,(a5)+                                 ; Move (a4)+ to (a5)+
	bra.b    ObfuscatedCopyLoop                          ; Unconditional branch to ObfuscatedCopyLoop
ObfuscatedCopyLoop_Exit:
	rts                                                  ; Return from subroutine
; ============================================================================
; Function: MonitorLoop_Entry
; Purpose : Entry point for the monitor command loop. Initializes console buffer and routes commands.
; ============================================================================
MonitorLoop_Entry:
	lea.l    Var_DisasmBuffer+1(a6),a0                   ; Load address of disassembler output text buffer into pointer a0
	lea.l    DMACONR(a5),a3                              ; Load address of DMACON (DMA control write register) into pointer a3
	bsr.b    ParseStringOperand                          ; Call subroutine to ParseStringOperand
	move.l   d0,d5                                       ; Move register d0 to register d5
MonitorLoop_Entry_Loc_46E2:
	bsr.b    SkipSpaces                                  ; Call subroutine to SkipSpaces
	beq.b    ParseImmediateOperand_Loc_474E              ; Branch to ParseImmediateOperand_Loc_474E if zero / equal
	move.b   (a3)+,d4                                    ; Move (a3)+ to register d4
	lea.l    Parser_OperatorChars(pc),a4                            ; Load address of Parser_OperatorChars(pc) into pointer a4
	lea.l    Parser_OperatorCallbacks(pc),a1                            ; Load address of Parser_OperatorCallbacks(pc) into pointer a1
MonitorLoop_Entry_Loc_46F0:
	move.b   (a4)+,d0                                    ; Move (a4)+ to register d0
	beq.w    ParseImmediateOperand_Loc_4796              ; Branch to ParseImmediateOperand_Loc_4796 if zero / equal
	addq.w   #$4,a1                                      ; Add constant $4 to pointer a1
	cmp.b    d4,d0                                       ; Compare register d0 against register d4
	bne.b    MonitorLoop_Entry_Loc_46F0                  ; Branch to MonitorLoop_Entry_Loc_46F0 if non-zero / not equal
	bsr.b    ParseStringOperand                          ; Call subroutine to ParseStringOperand
	move.l   d0,d6                                       ; Move register d0 to register d6
	jsr      (a1)                                        ; Jump to subroutine via pointer (a1)
	bra.b    MonitorLoop_Entry_Loc_46E2                  ; Unconditional branch to MonitorLoop_Entry_Loc_46E2
; ============================================================================
; Function: SkipSpaces
; Purpose : Skips space characters starting at (a3), advancing the pointer.
; ============================================================================
SkipSpaces:
	cmpi.b   #$20,(a3)                                   ; Compare (a3) against constant $20
	bne.b    SkipSpaces_Loc_4714                         ; Branch to SkipSpaces_Loc_4714 if non-zero / not equal
	addq.w   #$1,a3                                      ; Add 1 to pointer a3
	lea.l    BLTBPTH(a5),a1                              ; Load address of BLTBPTH(a5) into pointer a1
	cmpa.l   a1,a3                                       ; Compare pointer a3 against pointer a1
	bcs.b    SkipSpaces                                  ; Branch to SkipSpaces if carry set (less than)
SkipSpaces_Loc_4714:
	rts                                                  ; Return from subroutine
; ============================================================================
; Function: ParseStringOperand
; Purpose : Parses a quoted string operand from (a3) and packs up to 4 characters into d0.
; ============================================================================
ParseStringOperand:
	bsr.b    SkipSpaces                                  ; Call subroutine to SkipSpaces
	move.b   (a3),d1                                     ; Move (a3) to register d1
	cmpi.b   #$22,d1                                     ; Compare register d1 against constant $22
	beq.b    ParseStringOperand_Loc_4726                 ; Branch to ParseStringOperand_Loc_4726 if zero / equal
	cmpi.b   #$27,d1                                     ; Compare register d1 against constant $27
	bne.b    ParseImmediateOperand                       ; Branch to ParseImmediateOperand if non-zero / not equal
ParseStringOperand_Loc_4726:
	addq.w   #$1,a3                                      ; Add 1 to pointer a3
	moveq    #$0,d0                                      ; Initialize register d0 to 0
	moveq    #$4,d2                                      ; Initialize register d2 to constant $4
ParseStringOperand_Loc_472C:
	cmp.b    (a3)+,d1                                    ; Compare register d1 against (a3)+
	beq.b    ParseStringOperand_Loc_473C                 ; Branch to ParseStringOperand_Loc_473C if zero / equal
	lsl.l    #$8,d0
	move.b   -$1(a3),d0                                  ; Move -$1(a3) to register d0
	dbra     d2,ParseStringOperand_Loc_472C              ; Decrement loop counter d2 and loop back to ParseStringOperand_Loc_472C if not exhausted
	addq.w   #$4,a7                                      ; Add constant $4 to stack pointer (a7)
ParseStringOperand_Loc_473C:
	rts                                                  ; Return from subroutine
; ============================================================================
; Function: ParseImmediateOperand
; Purpose : Parses a number operand from (a3). Handles hex (default) or decimal (prefixed with #).
; ============================================================================
ParseImmediateOperand:
	cmpi.b   #$23,(a3)                                   ; Compare (a3) against constant $23
	bne.b    ParseImmediateOperand_Loc_474A              ; Branch to ParseImmediateOperand_Loc_474A if non-zero / not equal
	addq.w   #$1,a3                                      ; Add 1 to pointer a3
	bra.w    ParseDecimalNumber                          ; Unconditional branch to ParseDecimalNumber
ParseImmediateOperand_Loc_474A:
	bra.w    ParseHexNumber                              ; Unconditional branch to ParseHexNumber
ParseImmediateOperand_Loc_474E:
	move.l   d5,d0                                       ; Move register d5 to register d0
	bsr.w    PrintHex8                                   ; Call subroutine to PrintHex8
	bsr.w    CopyInlineString3Or4                        ; Call subroutine to CopyInlineString3Or4
	dc.w     $203D
	move.l   -(a3),d0                                    ; Move -(a3) to register d0
	move.l   d5,d0                                       ; Move register d5 to register d0
	bpl.b    ParseImmediateOperand_Loc_4766              ; Branch to ParseImmediateOperand_Loc_4766 if positive / plus
	move.b   #$2d,(a0)+                                  ; Move constant $2d to (a0)+
	neg.l    d0
ParseImmediateOperand_Loc_4766:
	bsr.w    FormatDecimal32Bit                          ; Call subroutine to FormatDecimal32Bit
	bsr.w    CopyInlineString3Or4                        ; Call subroutine to CopyInlineString3Or4
	dc.w     $203D
	move.l   -(a5),d0                                    ; Move -(a5) to register d0
	move.l   d5,d0                                       ; Move register d5 to register d0
	bsr.w    FormatDecimal                               ; Call subroutine to FormatDecimal
	bsr.w    CopyInlineString3Or4                        ; Call subroutine to CopyInlineString3Or4
	dc.w     $203D
	move.l   -(a2),d0                                    ; Move -(a2) to register d0
	move.l   d5,d0                                       ; Move register d5 to register d0
	moveq    #$3,d1                                      ; Initialize register d1 to constant $3
ParseImmediateOperand_Loc_4784:
	rol.l    #$8,d0
	move.b   d0,(a0)+                                    ; Move register d0 to (a0)+
	dbra     d1,ParseImmediateOperand_Loc_4784           ; Decrement loop counter d1 and loop back to ParseImmediateOperand_Loc_4784 if not exhausted
	move.b   #$22,(a0)+                                  ; Move constant $22 to (a0)+
ParseImmediateOperand_Loc_4790:
	bsr.w    RefreshAndDrawConsoleLine                   ; Call subroutine to RefreshAndDrawConsoleLine
	st.b     d7
ParseImmediateOperand_Loc_4796:
	rts                                                  ; Return from subroutine
; ============================================================================
; Data Block: Parser_OperatorChars
; Purpose   : Array of arithmetic operator characters for command line evaluator.
; ============================================================================
Parser_OperatorChars:
	move.l   $2a21(a5),-(a5)                             ; Move $2a21(a5) to -(a5)
	dc.w     $263D
; ============================================================================
; Data Block: Parser_OperatorCallbacks
; Purpose   : Jump table/routines for arithmetic expression operators.
; ============================================================================
Parser_OperatorCallbacks:
	dc.w     $3C3E
	move.l   d0,-(a7)                                    ; Move register d0 to -(a7)
	add.l    d6,d5                                       ; Add register d6 to register d5
	rts                                                  ; Return from subroutine
	sub.l    d6,d5                                       ; Subtract register d6 from register d5
	rts                                                  ; Return from subroutine
	muls.w   d6,d5
	rts                                                  ; Return from subroutine
	or.l     d6,d5                                       ; Logical OR register d5 with register d6
	rts                                                  ; Return from subroutine
	and.l    d6,d5                                       ; Logical AND register d5 with register d6
	rts                                                  ; Return from subroutine
	eor.l    d6,d5                                       ; Logical XOR register d5 with register d6
	rts                                                  ; Return from subroutine
	lsl.l    d6,d5
	rts                                                  ; Return from subroutine
	lsr.l    d6,d5
	rts                                                  ; Return from subroutine
	tst.w    d6                                          ; Test status of register d6 (for zero or negative)
	beq.b    ParseImmediateOperand_Loc_47CE              ; Branch to ParseImmediateOperand_Loc_47CE if zero / equal
	divs.w   d6,d5
	bvs.b    ParseImmediateOperand_Loc_47CE                              ; Execute bvs.b instruction
	ext.l    d5
	rts                                                  ; Return from subroutine
ParseImmediateOperand_Loc_47CE:
	addq.w   #$4,a7                                      ; Add constant $4 to stack pointer (a7)
	lea.l    Str_Overflow(pc),a1                            ; Load address of Str_Overflow(pc) into pointer a1
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	bra.b    ParseImmediateOperand_Loc_4790              ; Unconditional branch to ParseImmediateOperand_Loc_4790
Command_ModifyRegister:
	lea.l    Var_RegsSaved(a6),a2                        ; Load address of saved user registers area into pointer a2
	cmpi.b   #$2,d3                                      ; Compare register d3 against constant $2
	bhi.w    ModifyRegister_Exit_Loc_4AFE                              ; Branch to ModifyRegister_Exit_Loc_4AFE if higher.
	tst.b    d3                                          ; Test status of register d3 (for zero or negative)
	beq.w    ModifyRegister_Exit                         ; Branch to ModifyRegister_Exit if zero / equal
	cmpi.b   #$1,d3                                      ; Compare register d3 against 1
	bne.w    ModifyRegister_CheckGpr_Index               ; Branch to ModifyRegister_CheckGpr_Index if non-zero / not equal
	moveq    #$0,d2                                      ; Initialize register d2 to 0
	moveq    #$3,d0                                      ; Initialize register d0 to constant $3
	bclr     #$5,(a0)                                    ; Clear bit #$5 of (a0)
	cmpi.b   #$52,(a0)                                   ; Compare (a0) against constant $52
	bne.b    ModifyRegister_ParseNameLoop                ; Branch to ModifyRegister_ParseNameLoop if non-zero / not equal
	subq.w   #$3,a0                                      ; Subtract constant $3 from pointer a0
ModifyRegister_ParseNameLoop:
	move.b   (a0)+,d1                                    ; Move (a0)+ to register d1
	cmpi.b   #$20,d1                                     ; Compare register d1 against constant $20
	beq.b    ModifyRegister_MatchName                    ; Branch to ModifyRegister_MatchName if zero / equal
	bclr     #$5,d1                                      ; Clear bit #$5 of register d1
	lsl.l    #$8,d2
	or.b     d1,d2                                       ; Logical OR register d2 with register d1
	dbra     d0,ModifyRegister_ParseNameLoop             ; Decrement loop counter d0 and loop back to ModifyRegister_ParseNameLoop if not exhausted
ModifyRegister_MatchName:
	lea.l    BLTCON0(a2),a1                              ; Load address of BLTCON0(a2) into pointer a1
	move.l   Var_MemStart(a6),d0                         ; Load monitored memory start offset into register d0
	cmpi.l   #$555350,d2                                 ; Compare register d2 against constant $555350
	beq.b    ModifyRegister_ForceEvenAddress             ; Branch to ModifyRegister_ForceEvenAddress if zero / equal
	addq.w   #$4,a1                                      ; Add constant $4 to pointer a1
	cmpi.l   #$495350,d2                                 ; Compare register d2 against constant $495350
	beq.b    ModifyRegister_ForceEvenAddress             ; Branch to ModifyRegister_ForceEvenAddress if zero / equal
	addq.w   #$4,a1                                      ; Add constant $4 to pointer a1
	cmpi.l   #$4d5350,d2                                 ; Compare register d2 against constant $4d5350
	beq.b    ModifyRegister_ForceEvenAddress             ; Branch to ModifyRegister_ForceEvenAddress if zero / equal
	addq.w   #$4,a1                                      ; Add constant $4 to pointer a1
	cmpi.l   #$564252,d2                                 ; Compare register d2 against constant $564252
	beq.b    ModifyRegister_ForceEvenAddress             ; Branch to ModifyRegister_ForceEvenAddress if zero / equal
	addq.w   #$4,a1                                      ; Add constant $4 to pointer a1
	cmpi.l   #$43414352,d2                               ; Compare register d2 against constant $43414352
	beq.b    ModifyRegister_StoreValue                   ; Branch to ModifyRegister_StoreValue if zero / equal
	addq.w   #$4,a1                                      ; Add constant $4 to pointer a1
	cmpi.l   #$43414152,d2                               ; Compare register d2 against constant $43414152
	beq.b    ModifyRegister_StoreValue                   ; Branch to ModifyRegister_StoreValue if zero / equal
	addq.w   #$4,a1                                      ; Add constant $4 to pointer a1
	cmpi.l   #$5043,d2                                   ; Compare register d2 against constant $5043
	bne.b    ModifyRegister_CheckGpr                     ; Branch to ModifyRegister_CheckGpr if non-zero / not equal
ModifyRegister_ForceEvenAddress:
	bclr     #$0,d0                                      ; Clear bit #$0 of register d0
ModifyRegister_StoreValue:
	move.l   d0,(a1)                                     ; Move register d0 to (a1)
ModifyRegister_CheckGpr:
	moveq    #$7,d1                                      ; Initialize register d1 to constant $7
	cmpi.l   #$534643,d2                                 ; Compare register d2 against constant $534643
	bne.b    ModifyRegister_CheckSR                      ; Branch to ModifyRegister_CheckSR if non-zero / not equal
	cmp.l    d1,d0                                       ; Compare register d0 against register d1
	bhi.w    ModifyRegister_Exit_Loc_4AFE                              ; Branch to ModifyRegister_Exit_Loc_4AFE if higher.
	move.b   d0,Var_SfcSaved(a6)                         ; Store register d0 into saved Source Function Code (SFC) state
ModifyRegister_CheckSR:
	cmpi.l   #$5352,d2                                   ; Compare register d2 against constant $5352
	bne.b    ModifyRegister_Exit                         ; Branch to ModifyRegister_Exit if non-zero / not equal
	move.w   d0,$5c(a2)                                  ; Move register d0 to $5c(a2)
	bra.b    ModifyRegister_Exit                         ; Unconditional branch to ModifyRegister_Exit
ModifyRegister_CheckGpr_Index:
	move.w   Var_MemEnd+2(a6),d1                         ; Load monitored memory end offset into register d1
	cmpi.w   #$dfc,d1                                    ; Compare register d1 against constant $dfc
	bne.b    ModifyRegister_CheckGpr_Index_Body          ; Branch to ModifyRegister_CheckGpr_Index_Body if non-zero / not equal
	move.l   Var_MemStart(a6),d0                         ; Load monitored memory start offset into register d0
	moveq    #$7,d2                                      ; Initialize register d2 to constant $7
	cmp.l    d2,d0                                       ; Compare register d0 against register d2
	bhi.w    ModifyRegister_Exit_Loc_4AFE                              ; Branch to ModifyRegister_Exit_Loc_4AFE if higher.
	move.b   d0,Var_DfcSaved(a6)                         ; Store register d0 into saved Destination Function Code (DFC) state
	bra.b    ModifyRegister_Exit                         ; Unconditional branch to ModifyRegister_Exit
ModifyRegister_CheckGpr_Index_Body:
	andi.w   #$fff8,d1                                   ; Logical AND register d1 with constant $fff8
	cmpi.w   #$a0,d1                                     ; Compare register d1 against constant $a0
	beq.b    ModifyRegister_CalculateGprOffset           ; Branch to ModifyRegister_CalculateGprOffset if zero / equal
	cmpi.w   #$d0,d1                                     ; Compare register d1 against constant $d0
	bne.w    ModifyRegister_Exit_Loc_4AFE                ; Branch to ModifyRegister_Exit_Loc_4AFE if non-zero / not equal
ModifyRegister_CalculateGprOffset:
	move.w   Var_MemEnd+2(a6),d1                         ; Load monitored memory end offset into register d1
	subi.w   #$d0,d1                                     ; Subtract constant $d0 from register d1
	bcc.b    ModifyRegister_StoreGpr                     ; Branch to ModifyRegister_StoreGpr if carry clear (greater or equal)
	addi.w   #$38,d1                                     ; Add constant $38 to register d1
ModifyRegister_StoreGpr:
	add.w    d1,d1                                       ; Add register d1 to register d1
	add.w    d1,d1                                       ; Add register d1 to register d1
	move.l   Var_MemStart(a6),(a2,d1.w)                  ; Load monitored memory start offset into (a2,d1.w)
	cmpi.w   #$3c,d1                                     ; Compare register d1 against constant $3c
	bne.b    ModifyRegister_Exit                         ; Branch to ModifyRegister_Exit if non-zero / not equal
	lea.l    BLTCON0(a2),a1                              ; Load address of BLTCON0(a2) into pointer a1
	btst     #$d,$5c(a2)                                 ; Test bit #$d of $5c(a2)
	beq.b    ModifyRegister_StoreSPShadow                ; Branch to ModifyRegister_StoreSPShadow if zero / equal
	addq.w   #$4,a1                                      ; Add constant $4 to pointer a1
	btst     #$c,$5c(a2)                                 ; Test bit #$c of $5c(a2)
	beq.b    ModifyRegister_StoreSPShadow                ; Branch to ModifyRegister_StoreSPShadow if zero / equal
	addq.w   #$4,a1                                      ; Add constant $4 to pointer a1
ModifyRegister_StoreSPShadow:
	move.l   Var_MemStart(a6),(a1)                       ; Load monitored memory start offset into (a1)
ModifyRegister_Exit:
	tst.b    Var_ExceptionType(a6)                 ; Check if Var_ExceptionType is set / active
	beq.b    ModifyRegister_Exit_Loc_490C                ; Branch to ModifyRegister_Exit_Loc_490C if zero / equal
	move.w   Var_ExceptionSR(a6),$5c(a2)                 ; Load Var_ExceptionSR(a6) into $5c(a2)
	move.l   Var_ExceptionPC(a6),BLTSIZE(a2)             ; Load Var_ExceptionPC(a6) into BLTSIZE(a2)
	move.l   Var_ExceptionPC(a6),Var_MemStart(a6)        ; Store Var_ExceptionPC(a6) into monitored memory start offset
ModifyRegister_Exit_Loc_490C:
	move.l   BLTCON0(a2),d0                              ; Move BLTCON0(a2) to register d0
	btst     #$d,$5c(a2)                                 ; Test bit #$d of $5c(a2)
	beq.b    ModifyRegister_Exit_Loc_4928                ; Branch to ModifyRegister_Exit_Loc_4928 if zero / equal
	move.l   BLTAFWM(a2),d0                              ; Move BLTAFWM(a2) to register d0
	btst     #$c,$5c(a2)                                 ; Test bit #$c of $5c(a2)
	beq.b    ModifyRegister_Exit_Loc_4928                ; Branch to ModifyRegister_Exit_Loc_4928 if zero / equal
	move.l   $48(a2),d0                                  ; Move $48(a2) to register d0
ModifyRegister_Exit_Loc_4928:
	move.l   d0,$3c(a2)                                  ; Move register d0 to $3c(a2)
	lea.l    Var_DisasmBuffer(a6),a0                     ; Load address of disassembler output text buffer into pointer a0
	move.l   #$2044303a,d4                               ; Move constant $2044303a to register d4
	moveq    #$f,d6                                      ; Initialize register d6 to constant $f
ModifyRegister_Exit_Loc_4938:
	move.l   d4,(a0)+                                    ; Move register d4 to (a0)+
ModifyRegister_Exit_Loc_493A:
	move.l   (a2)+,d0                                    ; Move (a2)+ to register d0
	bsr.w    FormatHex8                                  ; Call subroutine to FormatHex8
	addq.w   #$1,a0                                      ; Add 1 to pointer a0
	moveq    #$7,d0                                      ; Initialize register d0 to constant $7
	and.b    d6,d0                                       ; Logical AND register d0 with register d6
	dbeq     d6,ModifyRegister_Exit_Loc_493A                           ; Execute dbeq instruction
	bsr.w    RefreshAndDrawConsoleLine                   ; Call subroutine to RefreshAndDrawConsoleLine
	move.l   #$2041303a,d4                               ; Move constant $2041303a to register d4
	dbra     d6,ModifyRegister_Exit_Loc_4938             ; Decrement loop counter d6 and loop back to ModifyRegister_Exit_Loc_4938 if not exhausted
	cmpi.b   #$1,Var_CpuType(a6)                         ; Compare detected CPU type against 1
	beq.b    ModifyRegister_Exit_Loc_498E                ; Branch to ModifyRegister_Exit_Loc_498E if zero / equal
	bcs.w    ModifyRegister_Exit_Loc_49EC                ; Branch to ModifyRegister_Exit_Loc_49EC if carry set (less than)
	cmpi.b   #$4,Var_CpuType(a6)                         ; Compare detected CPU type against constant $4
	beq.b    ModifyRegister_Exit_Loc_497E                ; Branch to ModifyRegister_Exit_Loc_497E if zero / equal
	move.w   #$2043,(a0)+                                ; Move constant $2043 to (a0)+
	move.l   #$4141523a,(a0)+                            ; Move constant $4141523a to (a0)+
	move.l   Var_CaarSaved(a6),d0                        ; Load saved Cache Address Register (CAAR) state into register d0
	bsr.w    FormatHex8                                  ; Call subroutine to FormatHex8
ModifyRegister_Exit_Loc_497E:
	addq.w   #$2,a0                                      ; Add constant $2 to pointer a0
	move.l   #$4d53503a,(a0)+                            ; Move constant $4d53503a to (a0)+
	move.l   Var_MspSaved(a6),d0                         ; Load saved Master Stack Pointer (MSP) state into register d0
	bsr.w    FormatHex8                                  ; Call subroutine to FormatHex8
ModifyRegister_Exit_Loc_498E:
	addq.w   #$2,a0                                      ; Add constant $2 to pointer a0
	move.l   #$5642523a,(a0)+                            ; Move constant $5642523a to (a0)+
	move.l   Var_VbrPointer(a6),d0                       ; Load active Vector Base Register (VBR) pointer into register d0
	bsr.w    FormatHex8                                  ; Call subroutine to FormatHex8
	addq.w   #$3,a0                                      ; Add constant $3 to pointer a0
	bsr.w    CopyInlineString3Or4                        ; Call subroutine to CopyInlineString3Or4
	subq.w   #$1,d6                                      ; Subtract 1 from register d6
	chk.l    Str_RegisterSFC(pc),d1                      ; Execute chk.l instruction
	add.b    Var_SfcSaved(a6),d0                         ; Add saved Source Function Code (SFC) state to register d0
	move.b   d0,(a0)+                                    ; Move register d0 to (a0)+
	addq.w   #$1,a0                                      ; Add 1 to pointer a0
	bsr.w    CopyInlineString3Or4                        ; Call subroutine to CopyInlineString3Or4
	neg.w    d6
	chk.l    Str_RegisterDFC(pc),d1                      ; Execute chk.l instruction
	add.b    Var_DfcSaved(a6),d0                         ; Add saved Destination Function Code (DFC) state to register d0
	move.b   d0,(a0)+                                    ; Move register d0 to (a0)+
	bsr.w    RefreshAndDrawConsoleLine                   ; Call subroutine to RefreshAndDrawConsoleLine
	cmpi.b   #$1,Var_CpuType(a6)                         ; Compare detected CPU type against 1
	bls.b    ModifyRegister_Exit_Loc_49EC                              ; Branch to ModifyRegister_Exit_Loc_49EC if lower or same.
	move.w   #$2043,(a0)+                                ; Move constant $2043 to (a0)+
	move.l   #$4143523a,(a0)+                            ; Move constant $4143523a to (a0)+
	move.l   Var_CacrSaved(a6),d0                        ; Load saved Cache Control Register (CACR) state into register d0
	move.l   d0,d2                                       ; Move register d0 to register d2
	bsr.w    FormatHex8                                  ; Call subroutine to FormatHex8
	addq.w   #$2,a0                                      ; Add constant $2 to pointer a0
	bsr.w    Console_FormatCpuInfo                       ; Call subroutine to Console_FormatCpuInfo
	bsr.w    RefreshAndDrawConsoleLine                   ; Call subroutine to RefreshAndDrawConsoleLine
ModifyRegister_Exit_Loc_49EC:
	addq.w   #$2,a0                                      ; Add constant $2 to pointer a0
	move.l   #$5553503a,(a0)+                            ; Move constant $5553503a to (a0)+
	move.l   Var_SavedUSP(a6),d0                         ; Load saved user stack pointer into register d0
	bsr.w    FormatHex8                                  ; Call subroutine to FormatHex8
	addq.w   #$2,a0                                      ; Add constant $2 to pointer a0
	move.l   #$4953503a,(a0)+                            ; Move constant $4953503a to (a0)+
	move.l   Var_SavedSSP(a6),d0                         ; Load saved supervisor stack pointer into register d0
	bsr.w    FormatHex8                                  ; Call subroutine to FormatHex8
	addq.w   #$2,a0                                      ; Add constant $2 to pointer a0
	move.l   #$2053523a,(a0)+                            ; Move constant $2053523a to (a0)+
	move.w   Var_CpuStatus(a6),d0                        ; Load Var_CpuStatus(a6) into register d0
	move.w   d0,d2                                       ; Move register d0 to register d2
	bsr.w    FormatHex4                                  ; Call subroutine to FormatHex4
	addq.w   #$2,a0                                      ; Add constant $2 to pointer a0
	move.b   #BLTDPTH,(a0)+                              ; Move constant BLTDPTH to (a0)+
	moveq    #$31,d0                                     ; Initialize register d0 to constant $31
	moveq    #$f,d3                                      ; Initialize register d3 to constant $f
	bsr.w    FormatRegisterBitToChar                     ; Call subroutine to FormatRegisterBitToChar
	cmpi.b   #$1,Var_CpuType(a6)                         ; Compare detected CPU type against 1
	bls.b    ModifyRegister_Exit_Loc_4A3E                              ; Branch to ModifyRegister_Exit_Loc_4A3E if lower or same.
	move.b   #BLTDPTH,(a0)+                              ; Move constant BLTDPTH to (a0)+
	moveq    #$30,d0                                     ; Initialize register d0 to constant $30
	bsr.w    FormatRegisterBitToChar                     ; Call subroutine to FormatRegisterBitToChar
ModifyRegister_Exit_Loc_4A3E:
	moveq    #$d,d3                                      ; Initialize register d3 to constant $d
	moveq    #$53,d0                                     ; Initialize register d0 to constant $53
	bsr.w    FormatRegisterBitToChar                     ; Call subroutine to FormatRegisterBitToChar
	cmpi.b   #$1,Var_CpuType(a6)                         ; Compare detected CPU type against 1
	bls.b    ModifyRegister_Exit_Loc_4A54                              ; Branch to ModifyRegister_Exit_Loc_4A54 if lower or same.
	moveq    #$4d,d0                                     ; Initialize register d0 to constant $4d
	bsr.w    FormatRegisterBitToChar                     ; Call subroutine to FormatRegisterBitToChar
ModifyRegister_Exit_Loc_4A54:
	moveq    #$4,d3                                      ; Initialize register d3 to constant $4
	moveq    #BLTSIZE,d0                                 ; Initialize register d0 to constant BLTSIZE
	bsr.w    FormatRegisterBitToChar                     ; Call subroutine to FormatRegisterBitToChar
	moveq    #$4e,d0                                     ; Initialize register d0 to constant $4e
	bsr.w    FormatRegisterBitToChar                     ; Call subroutine to FormatRegisterBitToChar
	moveq    #$5a,d0                                     ; Initialize register d0 to constant $5a
	bsr.w    FormatRegisterBitToChar                     ; Call subroutine to FormatRegisterBitToChar
	moveq    #$56,d0                                     ; Initialize register d0 to constant $56
	bsr.w    FormatRegisterBitToChar                     ; Call subroutine to FormatRegisterBitToChar
	moveq    #$43,d0                                     ; Initialize register d0 to constant $43
	bsr.w    FormatRegisterBitToChar                     ; Call subroutine to FormatRegisterBitToChar
	bsr.w    RefreshAndDrawConsoleLine                   ; Call subroutine to RefreshAndDrawConsoleLine
	cmpi.b   #$3,Var_ExceptionType(a6)                   ; Compare Var_ExceptionType(a6) against constant $3
	bne.b    ModifyRegister_Exit_Loc_4AA0                ; Branch to ModifyRegister_Exit_Loc_4AA0 if non-zero / not equal
	lea.l    Var_Breakpoints(a6),a0                      ; Load address of breakpoint table structure pointer into pointer a0
	move.l   Var_ExceptionPC(a6),d1                      ; Load Var_ExceptionPC(a6) into register d1
	moveq    #$9,d0                                      ; Initialize register d0 to constant $9
ModifyRegister_Exit_Loc_4A8A:
	cmp.l    (a0)+,d1                                    ; Compare register d1 against (a0)+
	bne.b    ModifyRegister_Exit_Loc_4A9C                ; Branch to ModifyRegister_Exit_Loc_4A9C if non-zero / not equal
	lea.l    Str_Breakpoint(pc),a1                            ; Load address of Str_Breakpoint(pc) into pointer a1
	lea.l    Var_DisasmBuffer+1(a6),a0                   ; Load address of disassembler output text buffer into pointer a0
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	bra.b    ModifyRegister_Exit_Loc_4AC8                ; Unconditional branch to ModifyRegister_Exit_Loc_4AC8
ModifyRegister_Exit_Loc_4A9C:
	dbra     d0,ModifyRegister_Exit_Loc_4A8A             ; Decrement loop counter d0 and loop back to ModifyRegister_Exit_Loc_4A8A if not exhausted
ModifyRegister_Exit_Loc_4AA0:
	move.b   Var_ExceptionType(a6),d0                    ; Load Var_ExceptionType(a6) into register d0
	beq.b    ModifyRegister_Exit_Loc_4AF0                ; Branch to ModifyRegister_Exit_Loc_4AF0 if zero / equal
	lea.l    Var_DisasmBuffer+1(a6),a0                   ; Load address of disassembler output text buffer into pointer a0
	lea.l    Str_ExceptionBusError(pc),a1                            ; Load address of Str_ExceptionBusError(pc) into pointer a1
	cmp.b    (a1)+,d0                                    ; Compare register d0 against (a1)+
	bsr.w    StringTable_Lookup                          ; Call subroutine to StringTable_Lookup
	lea.l    Str_ExceptionInstruction(pc),a1                            ; Load address of Str_ExceptionInstruction(pc) into pointer a1
	move.b   -(a0),d0                                    ; Move -(a0) to register d0
	cmp.b    (a1),d0                                     ; Compare register d0 against (a1)
	bhi.b    ModifyRegister_Exit_Loc_4AC8                              ; Branch to ModifyRegister_Exit_Loc_4AC8 if higher.
	move.b   #$20,(a0)                                   ; Move constant $20 to (a0)
	cmp.b    (a1)+,d0                                    ; Compare register d0 against (a1)+
	bsr.w    StringTable_Lookup                          ; Call subroutine to StringTable_Lookup
ModifyRegister_Exit_Loc_4AC8:
	cmpi.b   #$2,Var_ExceptionType(a6)                   ; Compare Var_ExceptionType(a6) against constant $2
	bne.b    ModifyRegister_Exit_Loc_4AE8                ; Branch to ModifyRegister_Exit_Loc_4AE8 if non-zero / not equal
	lea.l    Var_DisasmBuffer+29(a6),a0                  ; Load address of disassembler output text buffer into pointer a0
	move.w   Var_ExceptionAddr(a6),d0                    ; Load Var_ExceptionAddr(a6) into register d0
	bsr.w    FormatHex4                                  ; Call subroutine to FormatHex4
	lea.l    Var_DisasmBuffer+43(a6),a0                  ; Load address of disassembler output text buffer into pointer a0
	move.l   Var_ExceptionVO(a6),d0                      ; Load Var_ExceptionVO(a6) into register d0
	bsr.w    PrintHex8                                   ; Call subroutine to PrintHex8
ModifyRegister_Exit_Loc_4AE8:
	bsr.w    RefreshAndDrawConsoleLine                   ; Call subroutine to RefreshAndDrawConsoleLine
	sf.b     Var_ExceptionType(a6)                 ; Clear exception type code flag (false).
ModifyRegister_Exit_Loc_4AF0:
	movea.l  Var_SrpSaved(a6),a5                         ; Load saved exception instruction PC (SRP) into pointer a5
	bsr.w    Disasm_DisassembleInstruction               ; Call subroutine to Disasm_DisassembleInstruction
	bsr.w    RefreshAndDrawConsoleLine                   ; Call subroutine to RefreshAndDrawConsoleLine
	st.b     d7
ModifyRegister_Exit_Loc_4AFE:
	rts                                                  ; Return from subroutine
FormatRegisterBitToChar:
	move.b   d0,(a0)+                                    ; Move register d0 to (a0)+
FormatRegisterBitToChar_NoName:
	move.b   #$3d,(a0)+                                  ; Move constant $3d to (a0)+
	btst     d3,d2                                       ; Test bit d3 of register d2
	seq.b    (a0)
	addi.b   #$31,(a0)                                   ; Add constant $31 to (a0)
	addq.w   #$2,a0                                      ; Add constant $2 to pointer a0
	subq.b   #$1,d3                                      ; Subtract 1 from register d3
	rts                                                  ; Return from subroutine
Console_FormatCpuInfo:
	cmpi.b   #$4,Var_CpuType(a6)                         ; Compare detected CPU type against constant $4
	beq.b    FormatRegisterBitString_AltEntry            ; Branch to FormatRegisterBitString_AltEntry if zero / equal
	moveq    #$3,d3                                      ; Initialize register d3 to constant $3
	lea.l    Str_CpuStatusBits_68020(pc),a1                            ; Load address of Str_CpuStatusBits_68020(pc) into pointer a1
	cmpi.b   #$2,Var_CpuType(a6)                         ; Compare detected CPU type against constant $2
	beq.b    FormatRegisterBitString_Loop                ; Branch to FormatRegisterBitString_Loop if zero / equal
	lea.l    Str_CpuStatusBits_68000(pc),a1                            ; Load address of Str_CpuStatusBits_68000(pc) into pointer a1
	moveq    #$d,d3                                      ; Initialize register d3 to constant $d
FormatRegisterBitString_Loop:
	bsr.b    FormatRegisterBitString                     ; Call subroutine to FormatRegisterBitString
	bmi.b    FormatRegisterBitString_LoopExit            ; Branch to FormatRegisterBitString_LoopExit if negative / minus
	cmpi.b   #$7,d3                                      ; Compare register d3 against constant $7
	bne.b    FormatRegisterBitString_Loop                ; Branch to FormatRegisterBitString_Loop if non-zero / not equal
	subq.b   #$3,d3                                      ; Subtract constant $3 from register d3
	bra.b    FormatRegisterBitString_Loop                ; Unconditional branch to FormatRegisterBitString_Loop
FormatRegisterBitString_LoopExit:
	rts                                                  ; Return from subroutine
FormatRegisterBitString_AltEntry:
	moveq    #$1f,d3                                     ; Initialize register d3 to constant $1f
	lea.l    Str_CpuStatusBits_68040(pc),a1                            ; Load address of Str_CpuStatusBits_68040(pc) into pointer a1
	bsr.b    FormatRegisterBitString                     ; Call subroutine to FormatRegisterBitString
	moveq    #$f,d3                                      ; Initialize register d3 to constant $f
FormatRegisterBitString:
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	bra.b    FormatRegisterBitToChar_NoName              ; Unconditional branch to FormatRegisterBitToChar_NoName
	dc.b     $43,$FA,$01,$1C,$76,$0F,$61,$F2,$0C,$03,$00,$07,$66,$F8,$4E,$75; Table data bytes
	dc.b     $43,$FA,$01,$2D,$76,$1B,$61,$E2,$0C,$03,$00,$02,$67,$20,$0C,$03; Table data bytes
	dc.b     $00,$16,$66,$F2,$61,$00,$3B,$EA,$51,$3D,$20,$02,$48,$40,$72,$7F; Table data bytes
	dc.b     $C0,$81,$61,$00,$2A,$32,$52,$48,$04,$03,$00,$0F,$60,$D8,$4E,$75; Table data bytes
	dc.b     $43,$FA,$01,$15,$61,$00,$3B,$C0,$20,$02,$E1,$98,$61,$00,$2A,$18; Table data bytes
	dc.b     $61,$00,$3B,$B4,$E1,$98,$61,$00,$2A,$0E,$52,$48,$76,$0F,$70,$45; Table data bytes
	dc.b     $61,$00,$FF,$4E,$76,$0A,$61,$00,$3B,$9E,$61,$00,$FF,$46,$0C,$03; Table data bytes
	dc.b     $00,$07,$66,$F2,$61,$00,$3B,$90,$70,$70,$C0,$82,$E8,$08,$61,$00; Table data bytes
	dc.b     $29,$D8,$61,$00,$3B,$82,$70,$07,$C0,$82,$60,$00,$29,$CC,$43,$FA; Table data bytes
	dc.b     $00,$E0,$76,$1F,$70,$45,$61,$00,$FF,$18,$76,$19,$61,$00,$3B,$68; Table data bytes
	dc.b     $61,$00,$FF,$10,$61,$00,$3B,$60,$61,$00,$FF,$08,$61,$00,$3B,$58; Table data bytes
	dc.b     $20,$02,$48,$40,$02,$40,$00,$70,$E4,$48,$10,$FB,$00,$24,$10,$FB; Table data bytes
	dc.b     $00,$21,$10,$FB,$00,$1E,$10,$FB,$00,$1B,$76,$04,$20,$02,$48,$40; Table data bytes
	dc.b     $61,$00,$3B,$34,$61,$00,$2A,$4A,$E9,$98,$51,$CB,$FF,$F4,$4E,$75; Table data bytes
	dc.b     "256B512B1 KB2 KB4 KB8 KB16KB32KB"    ; String literal data
; ============================================================================
; Data Block: Str_CpuStatusBits_68000
; Purpose   : String representation characters for 68000/68010 status register bits.
; ============================================================================
Str_CpuStatusBits_68000:
	dc.b     $57,$C1,$44,$42,$C5,$43,$C4,$43,$45,$C4,$46,$C4,$45,$C4,$49,$42; Table data bytes
	dc.b     $C5                                   ; Table data bytes
; ============================================================================
; Data Block: Str_CpuStatusBits_68020
; Purpose   : String representation characters for 68020/68030 status register bits.
; ============================================================================
Str_CpuStatusBits_68020:
	dc.b     $43,$C9,$43,$45,$C9,$46,$C9,$45,$C9   ; Table data bytes
; ============================================================================
; Data Block: Str_CpuStatusBits_68040
; Purpose   : String representation characters for 68040 status register bits.
; ============================================================================
Str_CpuStatusBits_68040:
	dc.b     $44,$C5,$49,$C5,$42,$53,$55,$CE,$53,$4E,$41,$CE,$4F,$50,$45,$52; Table data bytes
	dc.b     $D2,$4F,$56,$46,$CC,$55,$4E,$46,$CC,$44,$DA,$49,$4E,$45,$58,$B1; Table data bytes
	dc.b     "INEX",$B2                            ; String literal data
	dc.b     $CE,$DA,$C9,$4E,$41,$CE,$D3,$49,$4F,$D0,$4F,$56,$46,$CC,$55,$4E; Table data bytes
	dc.b     $46,$CC,$44,$DA,$49,$4E,$45,$D8,$4C,$41,$42,$BD,$20,$4C,$41,$4D; Table data bytes
	dc.b     $BD,$43,$C9,$52,$2F,$D7,$52,$57,$CD,$46,$43,$BD,$20,$46,$43,$4D; Table data bytes
	dc.b     $BD,$53,$52,$C5,$46,$43,$CC,$50,$53,$BD,$20,$49,$53,$BD,$20,$54; Table data bytes
	dc.b     $49,$41,$BD,$20,$54,$49,$42,$BD,$20,$54,$49,$43,$BD,$20,$54,$49; Table data bytes
	dc.b     $44,$BD,$00,$45,$EE,$14,$3C,$4A,$03,$66,$00,$00,$B8,$28,$3C,$46; Table data bytes
	dc.b     "P0:t"                                ; String literal data
	dc.b     $07,$72,$05,$41,$EE,$19,$9E,$20,$C4,$26,$4A,$30,$1A,$61,$00,$28; Table data bytes
	dc.b     $C2,$51,$C9,$FF,$F8,$54,$48,$61,$00,$00,$A0,$61,$00,$C7,$BC,$06; Table data bytes
	dc.b     $44,$01,$00,$51,$CA,$FF,$DC,$30,$FC,$20,$46,$20,$FC,$50,$43,$52; Table data bytes
	dc.b     $3A,$24,$2E,$15,$BC,$20,$02,$61,$00,$28,$98,$52,$48,$10,$FC,$00; Table data bytes
	dc.b     $50,$20,$FC,$52,$45,$43,$3D,$70,$00,$10,$02,$EC,$48,$10,$FB,$00; Table data bytes
	dc.b     "bRH ",$FC                            ; String literal data
	dc.b     "RND=p0",$C0                          ; String literal data
	dc.b     $42,$E8,$48,$10,$FB,$00,$54,$52,$48,$61,$00,$FD,$F6,$61,$00,$C7; Table data bytes
	dc.b     $6E,$30,$FC,$20,$46,$20,$FC,$50,$53,$52,$3A,$24,$2E,$15,$C0,$20; Table data bytes
	dc.b     $02,$61,$00,$28,$6E,$41,$EE,$19,$B4,$61,$00,$FD,$D6,$61,$00,$C7; Table data bytes
	dc.b     $4E,$30,$FC,$46,$50,$20,$FC,$49,$41,$52,$3A,$20,$2E,$15,$C4,$61; Table data bytes
	dc.b     $00,$28,$50,$50,$48,$24,$2E,$15,$C0,$61,$00,$FD,$C6,$61,$00,$C7; Table data bytes
	dc.b     $2E,$50,$C7,$4E,$75,$58,$53,$44,$3F,$4E,$5A,$4D,$50,$4A,$2E,$16; Table data bytes
	dc.b     $58,$43,$FA,$00,$AE,$67,$44,$0C,$2E,$00,$03,$16,$58,$67,$00,$00; Table data bytes
	dc.b     $A0,$F2,$13,$48,$00,$47,$EE,$16,$3E,$F2,$13,$6C,$11,$70,$20,$4A; Table data bytes
	dc.b     $13,$6A,$02,$70,$2D,$10,$C0,$30,$1B,$00,$40,$80,$00,$52,$40,$66; Table data bytes
	dc.b     " TKC",$FA                            ; String literal data
	dc.b     $00,$84,$08,$13,$00,$06,$66,$0E,$22,$1B,$43,$FA,$00,$7B,$82,$93; Table data bytes
	dc.b     $67,$04,$43,$FA,$00,$6F,$61,$00,$39,$5A,$60,$5E,$52,$4B,$10,$1B; Table data bytes
	dc.b     $61,$00,$27,$A2,$10,$FC,$00,$2E,$72,$07,$10,$13,$E8,$08,$61,$00; Table data bytes
	dc.b     $27,$94,$10,$1B,$61,$00,$27,$8E,$51,$C9,$FF,$F0,$10,$FC,$00,$45; Table data bytes
	dc.b     $47,$EE,$16,$3E,$70,$2B,$08,$13,$00,$06,$67,$02,$70,$2D,$10,$C0; Table data bytes
	dc.b     $F2,$01,$A8,$00,$70,$00,$08,$01,$00,$0D,$67,$06,$10,$2B,$00,$02; Table data bytes
	dc.b     $E8,$08,$61,$00,$27,$60,$10,$1B,$61,$00,$27,$5A,$10,$13,$E8,$08; Table data bytes
	dc.b     $61,$00,$27,$52,$10,$13,$61,$00,$27,$4C,$4E,$75,$4E,$6F,$20,$46; Table data bytes
	dc.b     $50,$55,$A1,$53,$4E,$41,$CE,$49,$4E,$46,$49,$4E,$49,$54,$D9,$00; Table data bytes
	dc.b     $70,$00,$60,$28,$70,$04,$60,$24,$70,$08,$60,$20,$70,$1C,$72,$FF; Table data bytes
	dc.b     $60,$1C,$70,$0C,$60,$12,$70,$14,$60,$0E,$0C,$2E,$00,$01,$16,$59; Table data bytes
	dc.b     $43,$FA,$52,$59,$66,$52,$70,$1E,$72,$02,$60,$02,$72,$01,$43,$FA; Table data bytes
	dc.b     "R6J."                                ; String literal data
	dc.b     $16,$59,$67,$40,$43,$FA,$52,$5C,$0C,$2E,$00,$03,$16,$59,$67,$34; Table data bytes
	dc.b     $4C,$EE,$00,$30,$18,$20,$41,$EE,$15,$C8,$D1,$C0,$20,$03,$53,$80; Table data bytes
	dc.b     $66,$10,$B6,$81,$66,$04,$20,$84,$60,$14,$52,$81,$66,$1C,$30,$84; Table data bytes
	dc.b     $60,$0C,$53,$80,$66,$14,$B6,$81,$66,$10,$48,$D0,$00,$30,$61,$00; Table data bytes
	dc.b     $BA,$52,$60,$0C,$61,$00,$D4,$D0,$50,$C7,$4E,$75,$4A,$03,$66,$FA; Table data bytes
	dc.b     $61,$00,$B9,$F6,$50,$C7,$4A,$2E,$16,$59,$43,$FA,$51,$D6,$67,$00; Table data bytes
	dc.b     $D4,$B6,$0C,$2E,$00,$03,$16,$59,$43,$FA,$51,$F8,$67,$00,$D4,$A8; Table data bytes
	dc.b     $45,$EE,$15,$C8,$28,$3C,$54,$54,$30,$3A,$7A,$01,$41,$EE,$19,$9E; Table data bytes
	dc.b     $20,$C4,$20,$12,$61,$00,$26,$B2,$54,$48,$24,$1A,$61,$00,$FC,$5A; Table data bytes
	dc.b     $61,$00,$C5,$92,$06,$44,$01,$00,$51,$CD,$FF,$E2,$54,$48,$20,$FC; Table data bytes
	dc.b     " TC: "                               ; String literal data
	dc.b     $12,$61,$00,$26,$90,$54,$48,$24,$1A,$61,$00,$FC,$86,$61,$00,$C5; Table data bytes
	dc.b     $70,$0C,$2E,$00,$01,$16,$59,$66,$10,$2F,$0A,$45,$EE,$15,$E6,$20; Table data bytes
	dc.b     "<DRP:aj$_ <SRP:a` <CRP:aX0",$FC      ; String literal data
	dc.b     "MM ",$FC                             ; String literal data
	dc.b     "USR:4"                               ; String literal data
	dc.b     $12,$30,$02,$61,$00,$26,$2E,$5C,$48,$76,$0F,$70,$42,$61,$00,$FB; Table data bytes
	dc.b     "`pLa"                                ; String literal data
	dc.b     $00,$FB,$5A,$70,$53,$61,$00,$FB,$54,$53,$43,$70,$57,$61,$00,$FB; Table data bytes
	dc.b     "LpIa"                                ; String literal data
	dc.b     $00,$FB,$46,$70,$4D,$61,$00,$FB,$40,$55,$43,$70,$54,$61,$00,$FB; Table data bytes
	dc.b     $38,$61,$00,$37,$94,$4E,$3D,$70,$07,$C0,$42,$61,$00,$25,$D2,$61; Table data bytes
	dc.b     $00,$C4,$F2,$4E,$75,$54,$48,$20,$C0,$20,$12,$61,$00,$25,$FA,$52; Table data bytes
	dc.b     $48,$20,$2A,$00,$04,$61,$00,$25,$F0,$52,$48,$30,$FC,$4C,$2F,$70; Table data bytes
	dc.b     $55,$76,$0F,$34,$1A,$61,$00,$FB,$00,$61,$00,$37,$6C,$4C,$4D,$54; Table data bytes
	dc.b     $3D,$30,$3C,$7F,$FF,$C0,$42,$61,$00,$25,$B2,$61,$00,$37,$5A,$20; Table data bytes
	dc.b     "DT=p"                                ; String literal data
	dc.b     $03,$C0,$5A,$61,$00,$25,$86,$61,$00,$37,$4A,$20,$54,$41,$3D,$70; Table data bytes
	dc.b     $FC,$C0,$9A,$61,$00,$25,$AE,$60,$00,$C4,$96,$41,$FA,$F5,$3C,$60; Table data bytes
	dc.b     $04,$41,$FA,$F5,$2C,$50,$C7,$4A,$2E,$16,$59,$43,$FA,$50,$90,$67; Table data bytes
	dc.b     $00,$D3,$70,$0C,$2E,$00,$03,$16,$59,$43,$FA,$50,$B2,$67,$00,$D3; Table data bytes
	dc.b     $62,$60,$00,$F4,$EC,$6F,$6E,$A0,$6F,$66,$E6,$31,$4D,$42,$69,$74; Table data bytes
	dc.b     $2A,$B1,$00,$34,$4D,$42,$69,$74,$2A,$B4,$00,$32,$35,$36,$20,$4B; Table data bytes
	dc.b     $2A,$B4,$00,$31,$4D,$42,$69,$74,$2A,$B4,$00,$31,$32,$33,$6F,$35; Table data bytes
	dc.b     "38f480fA",$EE                        ; String literal data
	dc.b     $19,$9D,$43,$FA,$55,$CB,$61,$54,$10,$39,$00,$DE,$00,$43,$61,$00; Table data bytes
	dc.b     $25,$0C,$10,$39,$00,$DE,$00,$03,$72,$00,$41,$EE,$19,$A9,$61,$30; Table data bytes
	dc.b     "^Ha,\Ha(r"                           ; String literal data
	dc.b     $18,$C2,$40,$5E,$48,$43,$FB,$10,$A2,$61,$28,$72,$60,$C2,$40,$E7; Table data bytes
	dc.b     $19,$41,$E8,$00,$0E,$10,$FB,$10,$B2,$10,$FB,$10,$B2,$10,$FB,$10; Table data bytes
	dc.b     $B2,$50,$C7,$60,$00,$C3,$E8,$03,$00,$43,$FA,$FF,$78,$66,$02,$56; Table data bytes
	dc.b     $49,$52,$01,$60,$00,$36,$62,$49,$F9,$00,$DE,$00,$00,$41,$EE,$19; Table data bytes
	dc.b     $9D,$43,$FA,$55,$AD,$61,$EC,$4A,$2C,$00,$01,$6B,$08,$50,$49,$4A; Table data bytes
	dc.b     $14,$6A,$02,$5A,$49,$61,$DC,$43,$FA,$55,$B0,$61,$D6,$70,$6E,$4A; Table data bytes
	dc.b     $2C,$10,$01,$6A,$04,$70,$66,$10,$C0,$10,$C0,$61,$C6,$47,$EC,$10; Table data bytes
	dc.b     $02,$51,$D3,$72,$07,$4A,$13,$6A,$02,$52,$00,$D0,$00,$51,$C9,$FF; Table data bytes
	dc.b     $F6,$61,$00,$24,$70,$60,$00,$FF,$9A,$0C,$03,$00,$01,$62,$00,$00; Table data bytes
	dc.b     $9C,$4A,$03,$67,$5A,$20,$2E,$18,$20,$41,$F8,$00,$F1,$90,$88,$6B; Table data bytes
	dc.b     $00,$00,$8A,$41,$F8,$0E,$1F,$B0,$88,$66,$02,$70,$09,$72,$09,$B0; Table data bytes
	dc.b     $81,$62,$00,$00,$78,$45,$ED,$00,$02,$72,$4D,$0C,$12,$00,$22,$67; Table data bytes
	dc.b     $0E,$0C,$12,$00,$27,$67,$08,$52,$4A,$51,$C9,$FF,$F0,$60,$5C,$18; Table data bytes
	dc.b     $1A,$41,$EE,$16,$D2,$C0,$FC,$00,$14,$41,$F0,$00,$00,$72,$13,$B8; Table data bytes
	dc.b     $12,$67,$06,$10,$DA,$51,$C9,$FF,$F8,$4A,$41,$6B,$02,$51,$D0,$45; Table data bytes
	dc.b     $EE,$16,$D2,$74,$09,$22,$4A,$41,$EE,$19,$9D,$10,$FC,$00,$46,$70; Table data bytes
	dc.b     $0A,$90,$02,$61,$00,$24,$AC,$41,$EE,$19,$A1,$70,$27,$10,$C0,$76; Table data bytes
	dc.b     $13,$10,$D9,$57,$CB,$FF,$FC,$66,$02,$53,$48,$10,$80,$45,$EA,$00; Table data bytes
	dc.b     $14,$61,$00,$C2,$EA,$51,$CA,$FF,$CE,$50,$C7,$4E,$75,$55,$03,$66; Table data bytes
	dc.b     $22,$4C,$EE,$00,$03,$18,$20,$48,$AE,$00,$03,$16,$CE,$3D,$40,$13; Table data bytes
	dc.b     $B4,$3D,$41,$13,$B8,$20,$6E,$13,$D6,$31,$40,$00,$2A,$31,$41,$00; Table data bytes
	dc.b     $2E,$50,$C7,$4E,$75,$41,$EE,$19,$9D,$43,$FA,$52,$19,$61,$00,$35; Table data bytes
	dc.b     $38,$46,$2E,$16,$8B,$60,$12,$41,$EE,$19,$9D,$43,$FA,$52,$0F,$61; Table data bytes
	dc.b     $00,$35,$26,$08,$6E,$00,$04,$16,$CC,$61,$00,$FE,$AE,$61,$00,$C2; Table data bytes
	dc.b     $8E,$50,$C7,$4E,$75,$61,$20,$41,$EE,$19,$9D,$43,$FA,$51,$C7,$61; Table data bytes
	dc.b     $00,$35,$06,$4A,$2E,$13,$0E,$67,$06,$57,$48,$61,$00,$34,$FA,$61; Table data bytes
	dc.b     $00,$C2,$6C,$50,$C7,$4E,$75           ; Table data bytes
; ============================================================================
; Function: Monitor_DecryptCode
; Purpose : Toggles 15 specific bytes in the keymap table at $1288(a6) via XOR.
;           Since XOR is self-inverse, calling this routine twice restores the
;           original state. The keymap lies just outside the self-checksum range
;           ($0000-$D278), so these flips do not affect integrity verification.
;           The two conditional calls during init (lines 7705-7711) form a
;           toggle that depends on Var_NoSelfModifyFlag and bit 0 of $16cc(a6).
;           The exact purpose of this toggle is uncertain.
; ============================================================================
Monitor_DecryptCode:
	lea.l    $1288(a6),a0                                ; a0 -> keymap table (144 bytes, outside checksum range)
	eori.l   #$f21a00,(a0)                               ; Toggle offset $00: '\0 4 5 6' <-> '\0 . / 6'
	eori.w   #$3,$a(a0)                                  ; Toggle offset $0A: 'nm' <-> 'nn'
	eori.w   #$a776,$10(a0)                              ; Toggle offset $10: '.7' <-> '..'
Monitor_DecryptCode_Continue:
	eori.l   #$cdc323,$1e(a0)                            ; Toggle offset $1E: '-\0..'->'-..' (cursor/special keys)
	eori.w   #$3c03,$22(a0)                              ; Toggle offset $22: '..' <-> '/.' (non-printable keycodes)
	eori.w   #$200,$30(a0)                               ; Toggle offset $30: '/*' <-> '-*'
	eori.w   #$6284,$58(a0)                              ; Toggle offset $58: 'GH' <-> '%.'
	eori.l   #$78090201,$5c(a0)                          ; Toggle offset $5C: 'L..^' <-> '4.._'
	eori.l   #$14604b00,$60(a0)                          ; Toggle offset $60: '\0\0\0\0' <-> '.`K\0'
	eori.w   #$3,$6a(a0)                                 ; Toggle offset $6A: 'NM' <-> 'NN'
	eori.w   #$a757,$74(a0)                              ; Toggle offset $74: ' .' <-> '.P'
	eori.l   #$ece65e,$7e(a0)                            ; Toggle offset $7E: '-...' <-> '-..\\'
	eori.w   #$3e03,$80(a0)                              ; Toggle offset $80: '..' <-> '?.'
	eori.l   #$7046000,$8e(a0)                           ; Toggle offset $8E: '{}/*' <-> '|yO*'
	rts                                                  ; Return from subroutine
	dc.b     $50,$C7,$60,$00,$BE,$B8,$45,$EE,$19,$60,$74,$09,$20,$1A,$67,$0A; Table data bytes
	dc.b     $2A,$40,$61,$00,$28,$06,$61,$00,$C1,$EA,$51,$CA,$FF,$F0,$50,$C7; Table data bytes
	dc.b     $4E,$75,$74,$00,$53,$03,$66,$00,$00,$80,$26,$2E,$18,$20,$67,$00; Table data bytes
	dc.b     $00,$78,$05,$03,$66,$72,$45,$EE,$19,$60,$72,$09,$4A,$92,$66,$02; Table data bytes
	dc.b     $24,$0A,$B6,$9A,$57,$C9,$FF,$F6,$47,$FA,$4E,$2B,$67,$42,$47,$FA; Table data bytes
	dc.b     $4E,$3E,$4A,$82,$67,$3A,$41,$FA,$F2,$48,$61,$00,$F2,$26,$2F,$00; Table data bytes
	dc.b     $20,$43,$22,$10,$20,$BC,$42,$65,$45,$72,$61,$00,$F2,$60,$22,$50; Table data bytes
	dc.b     $20,$81,$47,$FA,$4D,$F6,$B3,$FC,$42,$65,$45,$72,$66,$08,$24,$42; Table data bytes
	dc.b     $24,$83,$47,$FA,$4E,$00,$20,$1F,$41,$FA,$F2,$1E,$61,$00,$F1,$F4; Table data bytes
	dc.b     $41,$EE,$19,$9D,$43,$FA,$4D,$C9,$61,$00,$33,$F2,$22,$4B,$61,$00; Table data bytes
	dc.b     $33,$EC,$61,$00,$C1,$5E,$50,$C7,$4E,$75,$74,$00,$53,$03,$66,$F8; Table data bytes
	dc.b     $45,$EE,$19,$60,$72,$09,$20,$2E,$18,$20,$67,$18,$05,$00,$66,$E8; Table data bytes
	dc.b     $B0,$9A,$57,$C9,$FF,$FC,$47,$FA,$4D,$B3,$66,$C4,$42,$A2,$47,$FA; Table data bytes
	dc.b     $4D,$B7,$60,$BC,$42,$9A,$51,$C9,$FF,$FC,$47,$FA,$4D,$BD,$60,$B0; Table data bytes
	dc.b     $76,$00,$61,$00,$BB,$DE,$10,$2E,$16,$2E,$0C,$00,$00,$61,$67,$00; Table data bytes
	dc.b     $02,$36,$0C,$00,$00,$6D,$67,$00,$01,$5A,$0C,$00,$00,$64,$67,$00; Table data bytes
	dc.b     $06,$8C,$0C,$00,$00,$75,$67,$00,$09,$96,$0C,$00,$00,$56,$67,$00; Table data bytes
	dc.b     $14,$68,$0C,$6E,$62,$69,$16,$2E,$66,$24,$30,$2E,$16,$30,$0C,$40; Table data bytes
	dc.b     "nwg."                                ; String literal data
	dc.b     $0C,$40,$6E,$6C,$67,$24,$0C,$40,$6E,$74,$67,$1A,$0C,$40,$6E,$71; Table data bytes
	dc.b     $67,$10,$51,$C0,$0C,$40,$6E,$00,$67,$18,$61,$00,$BB,$32,$50,$C7; Table data bytes
	dc.b     $4E,$75                               ; Table data bytes
; ============================================================================
; Data Block: Console_Draw_MenuOption8
; Purpose   : Display callback routine pushed to stack for menu option 8.
; ============================================================================
Console_Draw_MenuOption8:
	moveq    #$7b,d2
	dc.w     $600E ; bra.b $12 (external)
; ============================================================================
; Data Block: Console_Draw_MenuOption6
; Purpose   : Display callback routine pushed to stack for menu option 6.
; ============================================================================
Console_Draw_MenuOption6:
	moveq    #$7d,d2
	dc.w     $600A ; bra.b $e (external)
; ============================================================================
; Data Block: Console_Draw_MenuOption4
; Purpose   : Display callback routine pushed to stack for menu option 4.
; ============================================================================
Console_Draw_MenuOption4:
	moveq    #$5b,d2
	dc.w     $6006 ; bra.b $a (external)
; ============================================================================
; Data Block: Console_Draw_MenuOption2
; Purpose   : Display callback routine pushed to stack for menu option 2.
; ============================================================================
Console_Draw_MenuOption2:
	moveq    #$5d,d2
	dc.w     $6002 ; bra.b $6 (external)
; ============================================================================
; Data Block: Console_Draw_MenuOption1
; Purpose   : Display callback routine pushed to stack for menu option 1.
; ============================================================================
Console_Draw_MenuOption1:
	moveq    #$7c,d2
	cmpi.b   #$2,d3
	bgt.w    .L_Console_Draw_MenuOption1_0030
	dc.w     $6126 ; bsr.b $32 (external)
	moveq    #$f,d5
.L_Console_Draw_MenuOption1_000e:
	dc.w     $6150 ; bsr.b $60 (external)
	dc.w     $6100,$211A ; bsr.w $212c (external)
	beq.b    .L_Console_Draw_MenuOption1_002e
	cmpi.b   #$2,d3
	bne.b    .L_Console_Draw_MenuOption1_002a
	movea.l  $1820(a6),a0
	cmpa.l   $1824(a6),a0
	bcs.w    .L_Console_Draw_MenuOption1_000e
	bra.b    .L_Console_Draw_MenuOption1_002e
.L_Console_Draw_MenuOption1_002a:
	dbra     d5,.L_Console_Draw_MenuOption1_000e
.L_Console_Draw_MenuOption1_002e:
	st.b     d7
.L_Console_Draw_MenuOption1_0030:
	rts      
; ============ MatchSpecialDisplayItemType
; Purpose: Checks if the byte in d2 matches one of the special "item type" markers used by the monitor's
;   memory view / disasm formatter to pretty-print certain structures (blitter coordinates, Denise ID,
;   etc.) instead of raw disassembly. Returns a bit mask in d1 (or 0) that selects which special
;   renderer in the Data_ tables below to use. This allows the 'd' command and menu previews to show
;   human-friendly "x:123 y:456" or "bltmod" style annotations for BeerMon's own internal data or
;   cracking-related memory.
; Inputs: d2.b = marker byte from memory item (e.g. '{', '}', '[', ']', or Denise ID value).
; Outputs: d1.l = bitmask (8/6/4/2/1 or 0) indicating the special display type; Z flag set if no match.
; Notes: Called from the generic item display loop when the first byte of an item matches the "special"
;   prefix patterns (like $3e7b etc. seen in console buffer). The masks correspond to different
;   formatting routines in the following Data_ blocks.
MatchSpecialDisplayItemType:
	moveq    #$8,d1                                      ; Initialize register d1 to constant $8
	cmpi.b   #$7b,d2                                     ; Compare register d2 against constant $7b
	beq.b    SpecialItemTypeFound                        ; Branch to SpecialItemTypeFound if zero / equal
	moveq    #$6,d1                                      ; Initialize register d1 to constant $6
	cmpi.b   #$7d,d2                                     ; Compare register d2 against constant $7d
	beq.b    SpecialItemTypeFound                        ; Branch to SpecialItemTypeFound if zero / equal
	moveq    #$4,d1                                      ; Initialize register d1 to constant $4
	cmpi.b   #$5b,d2                                     ; Compare register d2 against constant $5b
	beq.b    SpecialItemTypeFound                        ; Branch to SpecialItemTypeFound if zero / equal
	moveq    #$2,d1                                      ; Initialize register d1 to constant $2
	cmpi.b   #$5d,d2                                     ; Compare register d2 against constant $5d
	beq.b    SpecialItemTypeFound                        ; Branch to SpecialItemTypeFound if zero / equal
	moveq    #$1,d1                                      ; Initialize register d1 to 1
	cmpi.b   #DENISEID,d2                                ; Compare register d2 against DENISEID (Denise chip ID register)
	beq.b    SpecialItemTypeFound                        ; Branch to SpecialItemTypeFound if zero / equal
	moveq    #$0,d1                                      ; Initialize register d1 to 0
SpecialItemTypeFound:
	tst.l    d1                                          ; Test status of register d1 (for zero or negative)
	rts                                                  ; Return from subroutine
; Console_Callback_SpecialItem (and following similar Data_ blocks) contain the actual machine code for the special
; item renderers selected by MatchSpecialDisplayItemType above. These routines are copied/executed
; in the context of the disasm buffer to emit pretty strings like "3e{" "3e}" "3e[" etc. for
; coordinate or blitter state display. They are stored as dc.b so the exact bytes (including any
; self-mod or position-dependent code) are preserved for the reconstruction. Each block implements
; one of the display variants for the monitor's enhanced memory view.
; ============================================================================
; Data Block: Console_Callback_SpecialItem
; Purpose   : Parser callback routine for console display special item modifications.
; ============================================================================
Console_Callback_SpecialItem:
.L_Console_Callback_SpecialItem_0000:
	movem.l  d1-d4,-(a7)
	lea.l    $199c(a6),a0
	move.b   #$3e,(a0)+
	move.b   d2,(a0)+
	move.l   $1820(a6),d0
	dc.w     $6100,$214C ; bsr.w $2160 (external)
	addq.w   #$1,a0
	movea.l  $1820(a6),a1
	move.w   d1,d4
	subq.w   #$1,d4
.L_Console_Callback_SpecialItem_0020:
	move.b   (a1)+,d3
	dc.w     $6100,$2264 ; bsr.w $2288 (external)
	subq.w   #$1,a0
	dbra     d4,.L_Console_Callback_SpecialItem_0020
	move.l   a1,$1820(a6)
	dc.w     $6100,$C01A ; bsr.w $ffffc04c (external)
	movem.l  (a7)+,d1-d4
	rts      
	moveq    #$9,d6
	bra.b    .L_Console_Callback_SpecialItem_004c
	moveq    #$7,d6
	bra.b    .L_Console_Callback_SpecialItem_004c
	moveq    #$5,d6
	bra.b    .L_Console_Callback_SpecialItem_004c
	moveq    #$3,d6
	bra.b    .L_Console_Callback_SpecialItem_004c
	moveq    #$2,d6
.L_Console_Callback_SpecialItem_004c:
	cmp.l    d3,d6
	bne.b    .L_Console_Callback_SpecialItem_009a
	move.b   $1(a5),d2
	subq.w   #$2,d6
	move.w   d6,d0
	lea.l    $1824(a6),a0
.L_Console_Callback_SpecialItem_005c:
	move.l   (a0)+,d1
	andi.l   #$eeeeeeee,d1
	bne.b    .L_Console_Callback_SpecialItem_009a
	dbra     d0,.L_Console_Callback_SpecialItem_005c
	move.w   d6,d0
	lea.l    $1820(a6),a0
	movea.l  (a0)+,a1
.L_Console_Callback_SpecialItem_0072:
	move.l   (a0)+,d3
	moveq    #$7,d5
.L_Console_Callback_SpecialItem_0076:
	add.b    d1,d1
	rol.l    #$4,d3
	btst     #$0,d3
	beq.b    .L_Console_Callback_SpecialItem_0082
	addq.b   #$1,d1
.L_Console_Callback_SpecialItem_0082:
	dbra     d5,.L_Console_Callback_SpecialItem_0076
	move.b   d1,(a1)+
	dbra     d0,.L_Console_Callback_SpecialItem_0072
	dc.w     $6100,$BA7E ; bsr.w $ffffbb0c (external)
	move.w   d6,d1
	addq.w   #$1,d1
	bsr.w    .L_Console_Callback_SpecialItem_0000
	st.b     d7
.L_Console_Callback_SpecialItem_009a:
	rts      
; ============================================================================
; Data Block: Console_Draw_Memory
; Purpose   : Display callback routine pushed to stack for memory view rendering.
; ============================================================================
Console_Draw_Memory:
	cmpi.b   #$2,d3
	bgt.w    .L_Console_Draw_Memory_002c
	moveq    #$f,d5
.L_Console_Draw_Memory_000a:
	dc.w     $6122 ; bsr.b $2e (external)
	dc.w     $6100,$2022 ; bsr.w $2030 (external)
	beq.b    .L_Console_Draw_Memory_002a
	cmpi.b   #$2,d3
	bne.b    .L_Console_Draw_Memory_0026
	movea.l  $1820(a6),a0
	cmpa.l   $1824(a6),a0
	bcs.w    .L_Console_Draw_Memory_000a
	bra.b    .L_Console_Draw_Memory_002a
.L_Console_Draw_Memory_0026:
	dbra     d5,.L_Console_Draw_Memory_000a
.L_Console_Draw_Memory_002a:
	st.b     d7
.L_Console_Draw_Memory_002c:
	rts      
; ============================================================================
; Data Block: Console_Callback_ModifyMemory
; Purpose   : Parser callback routine for console memory modifications.
; ============================================================================
Console_Callback_ModifyMemory:
	dc.b     $41,$EE,$19,$9C,$30,$FC,$3E,$3A,$20,$2E,$18,$20,$61,$00,$20,$88; Table data bytes
	dc.b     $52,$48,$74,$07,$22,$6E,$18,$20,$10,$FC,$00,$20,$10,$19,$E1,$48; Table data bytes
	dc.b     $10,$19,$61,$00,$20,$56,$51,$CA,$FF,$F0,$54,$48,$10,$FC,$00,$27; Table data bytes
	dc.b     $22,$6E,$18,$20,$74,$2E,$72,$0F,$10,$19,$6B,$0E,$0C,$00,$00,$20; Table data bytes
	dc.b     $6D,$08,$10,$C0,$51,$C9,$FF,$F2,$60,$06,$10,$C2,$51,$C9,$FF,$EA; Table data bytes
	dc.b     $10,$FC,$00,$27,$70,$10,$D1,$AE,$18,$20,$60,$00,$BF,$26,$0C,$03; Table data bytes
	dc.b     $00,$09,$66,$00,$00,$1C,$41,$EE,$18,$20,$22,$50,$0C,$06,$00,$36; Table data bytes
	dc.b     $6C,$1A,$5C,$48,$70,$07,$12,$D8,$12,$D8,$54,$48,$51,$C8,$FF,$F8; Table data bytes
	dc.b     $42,$45,$42,$03,$61,$00,$B9,$BC,$60,$00,$FF,$52,$70,$0F,$7C,$36; Table data bytes
	dc.b     $12,$35,$60,$00,$0C,$01,$00,$2E,$67,$02,$12,$81,$52,$46,$52,$49; Table data bytes
	dc.b     $51,$C8,$FF,$EE,$60,$DA               ; Table data bytes
; ============================================================================
; Data Block: Console_Draw_Registers
; Purpose   : Display callback routine pushed to stack for CPU register view rendering.
; ============================================================================
Console_Draw_Registers:
	cmpi.b   #$2,d3
	bgt.w    .L_Console_Draw_Registers_002c
	moveq    #$f,d5
.L_Console_Draw_Registers_000a:
	dc.w     $6122 ; bsr.b $2e (external)
	dc.w     $6100,$1F4E ; bsr.w $1f5c (external)
	beq.b    .L_Console_Draw_Registers_002a
	cmpi.b   #$2,d3
	bne.b    .L_Console_Draw_Registers_0026
	movea.l  $1820(a6),a0
	cmpa.l   $1824(a6),a0
	bcs.w    .L_Console_Draw_Registers_000a
	bra.b    .L_Console_Draw_Registers_002a
.L_Console_Draw_Registers_0026:
	dbra     d5,.L_Console_Draw_Registers_000a
.L_Console_Draw_Registers_002a:
	st.b     d7
.L_Console_Draw_Registers_002c:
	rts      
; ============================================================================
; Data Block: Console_Callback_ModifyRegs
; Purpose   : Parser callback routine for CPU register modifications.
; ============================================================================
Console_Callback_ModifyRegs:
	lea.l    $199c(a6),a0
	move.w   #$3e3b,(a0)+
	move.l   $1820(a6),d0
	dc.w     $6100,$1FB4 ; bsr.w $1fc2 (external)
	addq.w   #$2,a0
	move.b   #$27,(a0)+
	movea.l  $1820(a6),a1
	moveq    #$2e,d2
	moveq    #$3f,d1
.L_Console_Callback_ModifyRegs_001e:
	move.b   (a1)+,d0
	bmi.b    .L_Console_Callback_ModifyRegs_0030
	cmpi.b   #$20,d0
	blt.b    .L_Console_Callback_ModifyRegs_0030
	move.b   d0,(a0)+
	dbra     d1,.L_Console_Callback_ModifyRegs_001e
	bra.b    .L_Console_Callback_ModifyRegs_0036
.L_Console_Callback_ModifyRegs_0030:
	move.b   d2,(a0)+
	dbra     d1,.L_Console_Callback_ModifyRegs_001e
.L_Console_Callback_ModifyRegs_0036:
	move.b   #$27,(a0)+
	moveq    #$40,d0
	add.l    d0,$1820(a6)
	dc.w     $6000,$BE6C ; bra.w $ffffbeae (external)
	cmpi.b   #$1,d3
	dc.w     $6626 ; bne.b $70 (external)
	cmpi.b   #$27,$c(a5)
	dc.w     $661E ; bne.b $70 (external)
	movea.l  $1820(a6),a1
	moveq    #$3f,d0
	moveq    #$d,d6
.L_Console_Callback_ModifyRegs_005a:
	move.b   (a5,d6.w),d1
	cmpi.b   #$2e,d1
	beq.b    .L_Console_Callback_ModifyRegs_0066
	move.b   d1,(a1)
.L_Console_Callback_ModifyRegs_0066:
	addq.w   #$1,d6
	addq.w   #$1,a1
	dbra     d0,.L_Console_Callback_ModifyRegs_005a
	st.b     d7
	dc.b     "Nu3",$FC                             ; String literal data
	dc.b     $7F,$FF,$00,$DF,$F0,$96,$46,$FC,$27,$00,$70,$FF,$99,$CC,$20,$6E; Table data bytes
	dc.b     $18,$04,$43,$EE,$96,$90,$B3,$C8,$62,$0C,$47,$FA,$00,$5A,$26,$C0; Table data bytes
	dc.b     $B1,$CB,$62,$FA,$20,$49,$28,$C0,$B1,$CC,$62,$FA,$4E,$71,$4F,$F9; Table data bytes
	dc.b     $00,$04,$00,$00,$49,$F9,$00,$FC,$00,$FE,$0C,$B9,$00,$08,$00,$00; Table data bytes
	dc.b     $00,$FF,$FF,$EC,$66,$2C,$4F,$F8,$04,$00,$41,$F9,$00,$F8,$00,$00; Table data bytes
	dc.b     $28,$48,$72,$FF,$74,$01,$7A,$00,$DA,$98,$64,$02,$52,$85,$51,$C9; Table data bytes
	dc.b     $FF,$F8,$51,$CA,$FF,$F4,$0C,$9C,$4E,$E9,$00,$02,$67,$04,$55,$4C; Table data bytes
	dc.b     $60,$F4,$4E,$70,$4E,$D4,$70,$00,$0C,$03,$00,$01,$62,$00,$01,$44; Table data bytes
	dc.b     $66,$04,$20,$2E,$18,$20,$2D,$40,$16,$24,$33,$FC,$00,$20,$00,$DF; Table data bytes
	dc.b     $F0,$96,$70,$00,$23,$C0,$00,$DF,$F1,$44,$51,$EE,$16,$6A,$60,$10; Table data bytes
	dc.b     $70,$0A,$41,$F9,$00,$DF,$F0,$16,$01,$10,$66,$1C,$01,$10,$67,$FC; Table data bytes
	dc.b     $20,$6E,$13,$D6,$70,$02,$01,$68,$00,$13,$01,$68,$00,$17,$08,$68; Table data bytes
	dc.b     $00,$07,$00,$1A,$46,$2E,$16,$6A,$41,$EE,$19,$9D,$43,$FA,$48,$AC; Table data bytes
	dc.b     $61,$00,$2F,$F2,$20,$2E,$16,$24,$08,$80,$00,$00,$28,$40,$22,$3C; Table data bytes
	dc.b     $00,$00,$28,$00,$4A,$2E,$16,$5A,$66,$06,$22,$3C,$00,$00,$1F,$40; Table data bytes
	dc.b     $4A,$2E,$16,$6A,$66,$02,$D2,$81,$43,$F9,$00,$C8,$00,$00,$93,$C1; Table data bytes
	dc.b     $B0,$89,$63,$1C,$4B,$F9,$00,$F0,$00,$00,$B0,$8D,$64,$12,$24,$09; Table data bytes
	dc.b     $D4,$8D,$E2,$8A,$B0,$82,$63,$02,$22,$4D,$2D,$49,$16,$24,$60,$B4; Table data bytes
	dc.b     $D2,$80,$61,$00,$1D,$DA,$2A,$6E,$13,$CA,$43,$EE,$0B,$7A,$74,$07; Table data bytes
	dc.b     $72,$18,$41,$EE,$19,$9C,$4B,$ED,$00,$0F,$4A,$2E,$16,$6A,$66,$04; Table data bytes
	dc.b     $4B,$ED,$00,$28,$70,$00,$10,$18,$E7,$48,$1A,$F1,$00,$00,$51,$C9; Table data bytes
	dc.b     $FF,$F4,$52,$49,$51,$CA,$FF,$DA,$2A,$6E,$13,$CA,$74,$07,$72,$36; Table data bytes
	dc.b     $20,$3C,$00,$00,$01,$EF,$4A,$2E,$16,$5A,$66,$06,$20,$3C,$00,$00; Table data bytes
	dc.b     $01,$7F,$4A,$2E,$16,$6A,$67,$04,$72,$0E,$E2,$48,$1A,$DC,$51,$C9; Table data bytes
	dc.b     $FF,$FC,$49,$EC,$00,$19,$4B,$ED,$00,$19,$51,$CA,$FF,$D2,$4C,$DC; Table data bytes
	dc.b     $07,$FE,$48,$D5,$07,$FE,$4B,$ED,$00,$28,$51,$C8,$FF,$F2,$0C,$2E; Table data bytes
	dc.b     $00,$1B,$16,$88,$66,$00,$FE,$FA,$20,$6E,$13,$D6,$70,$02,$01,$E8; Table data bytes
	dc.b     $00,$13,$01,$E8,$00,$17,$08,$E8,$00,$07,$00,$1A,$61,$00,$B9,$36; Table data bytes
	dc.b     $50,$C7,$4E,$75,$0C,$03,$00,$01,$62,$00,$01,$F8,$4A,$03,$67,$00; Table data bytes
	dc.b     $01,$70,$20,$2E,$18,$20,$41,$F8,$01,$00,$B0,$88,$65,$00,$01,$E4; Table data bytes
	dc.b     $22,$2E,$18,$04,$04,$81,$00,$00,$B4,$0C,$B0,$81,$62,$00,$01,$D4; Table data bytes
	dc.b     $08,$00,$00,$00,$66,$00,$01,$CC,$33,$FC,$01,$80,$00,$DF,$F0,$96; Table data bytes
	dc.b     $33,$FC,$40,$00,$00,$DF,$F0,$9A,$4A,$AE,$18,$00,$67,$40,$22,$6E; Table data bytes
	dc.b     $13,$CA,$24,$40,$26,$6E,$18,$00,$49,$F9,$00,$DF,$F0,$06,$4B,$EC; Table data bytes
	dc.b     $01,$7A,$24,$3C,$00,$00,$B4,$0C,$B5,$C9,$67,$22,$62,$0E,$12,$1A; Table data bytes
	dc.b     $12,$D3,$16,$C1,$1A,$94,$53,$82,$66,$F4,$60,$12,$D3,$C2,$D5,$C2; Table data bytes
	dc.b     $D7,$C2,$12,$22,$13,$23,$16,$81,$1A,$94,$53,$82,$66,$F4; Table data bytes
; ============ SetupScreenResources
; Purpose: After memory sizing in entry, this allocates and initializes the monitor's direct-access
;   screen resources: two bitplanes (for 4-color text), a copper list for the display, and a screen
;   buffer. It wires the pointers into the a6 context (Var_Bitplane1/2, Var_CopperList, Var_ScreenBuf)
;   so that the font-to-bitplanes renderer (RenderConsoleTextLineToBitplanes) and refresh logic can
;   write the full-screen editor UI without any OS graphics.library. Also copies the font into the
;   bitplanes for the initial display and locks the monitor.
; Inputs: d0 = base address of the memory block allocated for screen (from earlier probe).
; Outputs: Var_* screen pointers filled; bitplanes cleared/copied with font; copper list set up;
;   screen refresh flag cleared; UI ready for MainMonitorInputLoop.
; Notes: This is the "nasty" takeover of the display hardware. The layout (bitplane at +$5000, copper
;   at +$6380, etc.) is fixed for the 320x? text mode used by BeerMon. Called from the end of the
;   entry path (after Monitor_WarmStart or similar) and after certain re-entries.
SetupScreenResources:
	movea.l  d0,a0                                       ; Move register d0 to pointer a0
	move.l   a0,Var_Bitplane1(a6)                        ; Store pointer a0 into first bitplane memory pointer
	lea.l    $5000(a0),a0                                ; Load address of $5000(a0) into pointer a0
	move.l   a0,Var_Bitplane2(a6)                        ; Store pointer a0 into second bitplane memory pointer
	lea.l    $6380(a0),a0                                ; Load address of $6380(a0) into pointer a0
	move.l   a0,Var_CopperList(a6)                       ; Store pointer a0 into Var_CopperList(a6)
	lea.l    BLTAPTH(a0),a0                              ; Load address of BLTAPTH(a0) into pointer a0
	move.l   a0,Var_ScreenBuf(a6)                        ; Store pointer a0 into screen character buffer pointer
	sf.b     Var_ScreenRefreshFlag(a6)             ; Clear flag so next refresh knows to do full or incremental
	bsr.w    RefreshAndDrawConsoleLine                   ; Call subroutine to RefreshAndDrawConsoleLine
	bsr.w    LockMonitor                                 ; Call subroutine to LockMonitor
	bsr.w    Console_ClearScreen_Body                    ; Call subroutine to Console_ClearScreen_Body
	sf.b     Var_CursorX(a6)                       ; Reset cursor to left edge for welcome message or initial view
	tst.b    Var_MonitorFlag_1679(a6)              ; Check if Var_MonitorFlag_1679 is set / active
	beq.b    AfterFontCopyToBitplanes_Loc_5956           ; Branch to AfterFontCopyToBitplanes_Loc_5956 if zero / equal
	sf.b     Var_MonitorFlag_1679(a6)
	lea.l    Var_FontData(a6),a1                         ; Load address of font glyph data pointer into pointer a1
	movea.l  Var_Bitplane1(a6),a2                        ; Load first bitplane memory pointer into pointer a2
	lea.l    $14(a2),a2                                  ; Load address of $14(a2) into pointer a2
	moveq    #$3f,d0                                     ; Initialize register d0 to constant $3f
CopyFontToBitplanes:
	moveq    #$27,d1                                     ; Initialize register d1 to constant $27
CopyFontRow:
	move.b   (a1)+,(a2)+                                 ; Move (a1)+ to (a2)+
	dbra     d1,CopyFontRow                              ; Decrement loop counter d1 and loop back to CopyFontRow if not exhausted
	lea.l    $28(a2),a2                                  ; Load address of $28(a2) into pointer a2
	dbra     d0,CopyFontToBitplanes                      ; Decrement loop counter d0 and loop back to CopyFontToBitplanes if not exhausted
AfterFontCopyToBitplanes:
	; ... (more of the init continues below with cursor setup, self-test etc.)
	move.b   #$9,Var_CursorY(a6)                         ; Store constant $9 into cursor vertical row coordinate
	tst.b    Var_NoSelfModifyFlag(a6)              ; Is self-modification disabled?
	bne.b    AfterFontCopyToBitplanes_Loc_594A           ; Yes -> skip first XOR pass
	bsr.w    Monitor_DecryptCode                         ; No -> toggle keymap bytes (1st pass)
AfterFontCopyToBitplanes_Loc_594A:
	btst     #$0,$16cc(a6)                               ; Test secondary condition flag bit 0
	beq.b    AfterFontCopyToBitplanes_Loc_5956           ; Clear -> skip second XOR pass
	bsr.w    Monitor_DecryptCode                         ; Set -> toggle keymap bytes again (2nd pass, undoes 1st)
AfterFontCopyToBitplanes_Loc_5956:
	lea.l    Var_DisasmBuffer+1(a6),a0                   ; Load address of disassembler output text buffer into pointer a0
	lea.l    Str_VersionGreeting(pc),a1                            ; Load address of Str_VersionGreeting(pc) into pointer a1
	lea.l    CopyHighBitTerminatedString(pc),a3          ; Load address of CopyHighBitTerminatedString(pc) into pointer a3
	jsr      (a3)                                        ; Jump to subroutine via pointer (a3)
	moveq    #$30,d0                                     ; Initialize register d0 to constant $30
	add.b    Var_CpuType(a6),d0                          ; Add detected CPU type to register d0
	move.b   d0,(a0)+                                    ; Move register d0 to (a0)+
	jsr      (a3)                                        ; Jump to subroutine via pointer (a3)
	move.l   a1,-(a7)                                    ; Move pointer a1 to -(a7)
	lea.l    Str_NoMmu(pc),a1                            ; Load address of Str_NoMmu(pc) into pointer a1
	move.b   Var_FpuModel(a6),d0                         ; Load detected FPU model into register d0
	bsr.w    StringTable_Lookup_SkipLoop                 ; Call subroutine to StringTable_Lookup_SkipLoop
	move.b   #$2c,(a0)+                                  ; Move constant $2c to (a0)+
	lea.l    Str_NoFpu(pc),a1                            ; Load address of Str_NoFpu(pc) into pointer a1
	move.b   Var_FpuType(a6),d0                          ; Load detected FPU type into register d0
	bsr.w    StringTable_Lookup_SkipLoop                 ; Call subroutine to StringTable_Lookup_SkipLoop
	move.b   #$2c,(a0)+                                  ; Move constant $2c to (a0)+
	lea.l    Str_Fpu(pc),a1                            ; Load address of Str_Fpu(pc) into pointer a1
	move.w   Var_MemoryLimit(a6),d0                      ; Load upper bound of monitored memory into register d0
	lsr.w    #$1,d0
	adda.w   d0,a1                                       ; Add register d0 to pointer a1
	jsr      (a3)                                        ; Jump to subroutine via pointer (a3)
	movea.l  (a7)+,a1                                    ; Move (a7)+ to pointer a1
	jsr      (a3)                                        ; Jump to subroutine via pointer (a3)
	move.l   a1,-(a7)                                    ; Move pointer a1 to -(a7)
	lea.l    Str_Mutilating(pc),a1                            ; Load address of Str_Mutilating(pc) into pointer a1
	tst.b    Var_EntryFlag(a6)                     ; Check if entering via cold start or warm start/re-entry
	beq.b    AfterFontCopyToBitplanes_Loc_59B2           ; Branch to AfterFontCopyToBitplanes_Loc_59B2 if zero / equal
	lea.l    Str_DeepFrost(pc),a1                            ; Load address of Str_DeepFrost(pc) into pointer a1
AfterFontCopyToBitplanes_Loc_59B2:
	jsr      (a3)                                        ; Jump to subroutine via pointer (a3)
	movea.l  (a7)+,a1                                    ; Move (a7)+ to pointer a1
	jsr      (a3)                                        ; Jump to subroutine via pointer (a3)
	bsr.w    RefreshAndDrawConsoleLine                   ; Call subroutine to RefreshAndDrawConsoleLine
	bsr.w    AfterFontCopyToBitplanes_Loc_59D2           ; Call subroutine to AfterFontCopyToBitplanes_Loc_59D2
	move.b   #$3,Var_MonitorFlag_166c(a6)                ; Store constant $3 into Var_MonitorFlag_166c(a6)
	bsr.w    Disk_CheckAndMount                          ; Call subroutine to Disk_CheckAndMount
	bsr.w    Console_CursorNextLine                      ; Call subroutine to Console_CursorNextLine
	bra.w    Monitor_WarmStart                           ; Unconditional branch to Monitor_WarmStart
AfterFontCopyToBitplanes_Loc_59D2:
	lea.l    Var_DisasmBuffer+1(a6),a0                   ; Load address of disassembler output text buffer into pointer a0
	lea.l    Table_Scr(pc),a1                            ; Load address of Table_Scr(pc) into pointer a1
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	lea.l    Str_Abs(pc),a1                            ; Load address of Str_Abs(pc) into pointer a1
	tst.b    Var_MemoryLayout(a6)                  ; Check if Var_MemoryLayout is set / active
	bne.b    AfterFontCopyToBitplanes_Loc_59EA           ; Branch to AfterFontCopyToBitplanes_Loc_59EA if non-zero / not equal
	addq.w   #$6,a1                                      ; Add constant $6 to pointer a1
AfterFontCopyToBitplanes_Loc_59EA:
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	move.l   Var_Bitplane1(a6),d0                        ; Load first bitplane memory pointer into register d0
	move.l   d0,d1                                       ; Move register d0 to register d1
	addi.l   #$b40c,d1                                   ; Add constant $b40c to register d1
	bsr.w    FormatAddressRange6                         ; Call subroutine to FormatAddressRange6
	lea.l    Str_Code(pc),a1                            ; Load address of Str_Code(pc) into pointer a1
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	lea.l    Start(pc),a1                                ; Load address of Start(pc) into pointer a1
	move.l   a1,d0                                       ; Move pointer a1 to register d0
	lea.l    Var_MonitorBufferOffset(a6),a1              ; Load address of Var_MonitorBufferOffset(a6) into pointer a1
	lea.l    $4000(a1),a1                                ; Load address of $4000(a1) into pointer a1
	move.l   a1,d1                                       ; Move pointer a1 to register d1
	bsr.w    FormatAddressRange8                         ; Call subroutine to FormatAddressRange8
	lea.l    Str_Ex(pc),a1                            ; Load address of Str_Ex(pc) into pointer a1
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	lea.l    Str_NotAvailable(pc),a1                            ; Load address of Str_NotAvailable(pc) into pointer a1
	move.l   Var_MemoryAddr(a6),d0                       ; Load active memory view pointer into register d0
	beq.b    AfterFontCopyToBitplanes_Loc_5A38           ; Branch to AfterFontCopyToBitplanes_Loc_5A38 if zero / equal
	lea.l    Str_Abs(pc),a1                            ; Load address of Str_Abs(pc) into pointer a1
	tst.b    Var_MonitorActive(a6)                 ; Check if Var_MonitorActive is set / active
	bne.b    AfterFontCopyToBitplanes_Loc_5A38           ; Branch to AfterFontCopyToBitplanes_Loc_5A38 if non-zero / not equal
	addq.w   #$6,a1                                      ; Add constant $6 to pointer a1
AfterFontCopyToBitplanes_Loc_5A38:
	bsr.w    CopyHighBitTerminatedString                 ; Call subroutine to CopyHighBitTerminatedString
	move.l   d0,d1                                       ; Move register d0 to register d1
	beq.b    AfterFontCopyToBitplanes_Loc_5A4A           ; Branch to AfterFontCopyToBitplanes_Loc_5A4A if zero / equal
	addi.l   #$b40c,d1                                   ; Add constant $b40c to register d1
	bsr.w    FormatAddressRange8                         ; Call subroutine to FormatAddressRange8
AfterFontCopyToBitplanes_Loc_5A4A:
	sf.b     Var_CursorX(a6)                       ; Clear cursor X coordinate flag (false).
	bsr.w    RefreshAndDrawConsoleLine                   ; Call subroutine to RefreshAndDrawConsoleLine
	st.b     d7
	rts                                                  ; Return from subroutine
	dc.b     $0C,$03,$00,$02,$62,$40,$7A,$0F,$20,$2E,$18,$20,$08,$00,$00,$00; Table data bytes
	dc.b     "f4*@a"                               ; String literal data
	dc.b     $00,$20,$78,$61,$00,$1F,$CC,$61,$00,$BA,$58,$61,$58,$2D,$4D,$18; Table data bytes
	dc.b     $20,$61,$00,$1A,$CE,$67,$18,$0C,$03,$00,$02,$66,$0E,$20,$6E,$18; Table data bytes
	dc.b     $20,$B1,$EE,$18,$24,$65,$00,$FF,$CC,$60,$04,$51,$CD,$FF,$C6,$50; Table data bytes
	dc.b     $C7,$4E,$75                           ; Table data bytes
; ============ IsSpecialVectorOrJump
; Purpose: Quick test used by the special item display logic to decide if the memory at MemStart
;   looks like a vector table entry, RTE, JMP, or blitter-related. If yes, the monitor can show a
;   nicer "3e," or arrow style annotation instead of plain disasm. Part of the enhanced 'd' view
;   for low-level structures (vectors, jump tables, copper lists etc.).
IsSpecialVectorOrJump:
	movea.l  Var_MemStart(a6),a0                         ; Load monitored memory start offset into pointer a0
	move.w   (a0),d0                                     ; Move (a0) to register d0
	subi.w   #$4e73,d0                                   ; Subtract constant $4e73 from register d0
	beq.b    SpecialVectorMatch                          ; Branch to SpecialVectorMatch if zero / equal
	subq.w   #$1,d0                                      ; Subtract 1 from register d0
	beq.b    SpecialVectorMatch                          ; Branch to SpecialVectorMatch if zero / equal
	subq.w   #$1,d0                                      ; Subtract 1 from register d0
	beq.b    SpecialVectorMatch                          ; Branch to SpecialVectorMatch if zero / equal
	subq.w   #$2,d0                                      ; Subtract constant $2 from register d0
	beq.b    SpecialVectorMatch                          ; Branch to SpecialVectorMatch if zero / equal
	moveq    #-16,d0                                     ; Initialize register d0 to constant -16
	and.w    (a0),d0                                     ; Logical AND register d0 with (a0)
	cmpi.w   #$6c0,d0                                    ; Compare register d0 against constant $6c0
	beq.b    SpecialVectorMatch                          ; Branch to SpecialVectorMatch if zero / equal
	moveq    #-64,d0                                     ; Initialize register d0 to constant -64
	and.w    (a0),d0                                     ; Logical AND register d0 with (a0)
	cmpi.w   #$4ec0,d0                                   ; Compare register d0 against constant $4ec0
	beq.b    SpecialVectorMatch                          ; Branch to SpecialVectorMatch if zero / equal
	cmpi.b   #BLTCMOD,(a0)                               ; Compare (a0) against constant BLTCMOD
SpecialVectorMatch:
	rts                                                  ; Return from subroutine
; ============ ShowSpecialVectorPlaceholder
; Purpose: When the item at MemStart is recognized as a special vector/jump, this emits a placeholder
;   line in the disasm buffer (lots of "----" or similar) so the pretty view can be shown instead of
;   the raw instruction. Then refreshes the screen.
ShowSpecialVectorPlaceholder:
	bsr.b    IsSpecialVectorOrJump                       ; Call subroutine to IsSpecialVectorOrJump
	bne.b    NotSpecialVector                            ; Branch to NotSpecialVector if non-zero / not equal
	move.l   a0,d0                                       ; Move pointer a0 to register d0
	lea.l    Var_DisasmBuffer(a6),a0                     ; Load address of disassembler output text buffer into pointer a0
	move.w   #$3e2c,(a0)+                                ; Move constant $3e2c to (a0)+
	bsr.w    FormatHex8                                  ; Call subroutine to FormatHex8
	addq.w   #$1,a0                                      ; Add 1 to pointer a0
	moveq    #$30,d0                                     ; Initialize register d0 to constant $30
EmitPlaceholderDashes:
	move.b   #$2d,(a0)+                                  ; Move constant $2d to (a0)+
	dbra     d0,EmitPlaceholderDashes                    ; Decrement loop counter d0 and loop back to EmitPlaceholderDashes if not exhausted
	bsr.w    RefreshAndDrawConsoleLine                   ; Call subroutine to RefreshAndDrawConsoleLine
NotSpecialVector:
	rts                                                  ; Return from subroutine
	dc.b     $70,$00,$60,$06,$70,$01,$60,$02,$70,$02,$01,$6E,$16,$67,$50,$C7; Table data bytes
	dc.b     $4E,$75,$4A,$03,$67,$1A,$20,$2E,$18,$20,$08,$00,$00,$00,$66,$10; Table data bytes
	dc.b     $41,$EE,$19,$9C,$30,$FC,$3E,$2C,$61,$00,$1A,$C2,$60,$00,$01,$FC; Table data bytes
	dc.b     $4E,$75,$4A,$03,$67,$FA,$20,$4D,$54,$48,$61,$00,$C6,$22,$B1,$EE; Table data bytes
	dc.b     $18,$0C,$62,$EC,$0C,$18,$00,$20,$66,$F4,$B1,$EE,$18,$0C,$62,$00; Table data bytes
	dc.b     $01,$E8,$0C,$10,$00,$20,$66,$04,$52,$48,$60,$EE,$2A,$48,$B1,$EE; Table data bytes
	dc.b     $18,$0C,$62,$18,$10,$18,$0C,$00,$00,$5A,$62,$F2,$0C,$00,$00,$41; Table data bytes
	dc.b     $65,$EC,$08,$C0,$00,$05,$11,$40,$FF,$FF,$60,$E2,$49,$FA,$5F,$D0; Table data bytes
	dc.b     $08,$2E,$00,$00,$18,$23,$66,$A8,$0C,$15,$00,$2D,$67,$00,$01,$A4; Table data bytes
	dc.b     " MC",$EC                             ; String literal data
	dc.b     $00,$06,$10,$11,$08,$80,$00,$07,$B0,$18,$66,$00,$01,$4A,$08,$19; Table data bytes
	dc.b     $00,$07,$67,$EE,$43,$EE,$17,$9E,$42,$AE,$17,$9A,$42,$59,$42,$51; Table data bytes
	dc.b     $30,$2C,$00,$04,$02,$40,$07,$00,$0C,$40,$04,$00,$67,$00,$01,$08; Table data bytes
	dc.b     $0C,$40,$03,$00,$67,$00,$00,$EC,$0C,$18,$00,$2E,$66,$00,$01,$18; Table data bytes
	dc.b     $0C,$40,$00,$00,$66,$30,$51,$EE,$16,$66,$0C,$18,$00,$62,$67,$00; Table data bytes
	dc.b     $00,$D2,$52,$2E,$16,$66,$32,$BC,$00,$40,$0C,$28,$00,$77,$FF,$FF; Table data bytes
	dc.b     $67,$00,$00,$C0,$52,$2E,$16,$66,$32,$BC,$00,$80,$0C,$28,$00,$6C; Table data bytes
	dc.b     $FF,$FF,$67,$00,$00,$AE,$0C,$40,$05,$00,$66,$32,$51,$EE,$16,$66; Table data bytes
	dc.b     $32,$BC,$02,$00,$0C,$18,$00,$62,$67,$00,$00,$98,$52,$2E,$16,$66; Table data bytes
	dc.b     $32,$BC,$04,$00,$0C,$28,$00,$77,$FF,$FF,$67,$00,$00,$86,$52,$2E; Table data bytes
	dc.b     $16,$66,$32,$BC,$06,$00,$0C,$28,$00,$6C,$FF,$FF,$67,$74,$0C,$40; Table data bytes
	dc.b     $06,$00,$66,$2A,$51,$EE,$16,$66,$0C,$18,$00,$62,$67,$64,$52,$2E; Table data bytes
	dc.b     $16,$66,$32,$BC,$02,$00,$0C,$28,$00,$77,$FF,$FF,$67,$54,$52,$2E; Table data bytes
	dc.b     $16,$66,$32,$BC,$04,$00,$0C,$28,$00,$6C,$FF,$FF,$67,$44,$0C,$40; Table data bytes
	dc.b     $01,$00,$66,$1C,$1D,$7C,$00,$01,$16,$66,$0C,$18,$00,$77,$67,$32; Table data bytes
	dc.b     $52,$2E,$16,$66,$32,$BC,$00,$40,$0C,$28,$00,$6C,$FF,$FF,$67,$22; Table data bytes
	dc.b     $0C,$40,$02,$00,$66,$50,$1D,$7C,$00,$01,$16,$66,$0C,$18,$00,$77; Table data bytes
	dc.b     $67,$10,$52,$2E,$16,$66,$32,$BC,$01,$00,$0C,$28,$00,$6C,$FF,$FF; Table data bytes
	dc.b     $66,$34,$0C,$10,$00,$20,$66,$2E,$52,$48,$B1,$EE,$18,$0C,$62,$26; Table data bytes
	dc.b     $0C,$10,$00,$20,$67,$F2,$50,$C7,$26,$48,$30,$2C,$00,$04,$48,$80; Table data bytes
	dc.b     $D0,$40,$41,$FA,$5C,$42,$30,$30,$00,$00,$41,$FA,$31,$5E,$4E,$B0; Table data bytes
	dc.b     $00,$00,$4A,$07,$66,$0E,$51,$C7,$4A,$94,$67,$3E,$49,$EC,$00,$0E; Table data bytes
	dc.b     $60,$00,$FE,$8A,$41,$EE,$17,$9E,$30,$18,$22,$6E,$18,$20,$2A,$49; Table data bytes
	dc.b     $32,$10,$82,$6C,$00,$02,$30,$81,$32,$D8,$51,$C8,$FF,$FC,$61,$00; Table data bytes
	dc.b     $B2,$84,$61,$00,$1D,$D8,$61,$00,$B7,$BC,$61,$00,$FD,$BC,$2D,$4D; Table data bytes
	dc.b     $18,$20,$61,$00,$1D,$C8,$61,$00,$B7,$AC,$61,$00,$B2,$68,$1D,$7C; Table data bytes
	dc.b     $00,$0B,$16,$5D,$50,$C7,$4E,$75,$45,$EE,$16,$7F,$60,$04,$45,$EE; Table data bytes
	dc.b     $16,$80,$53,$83,$66,$18,$70,$16,$90,$AE,$18,$20,$67,$08,$0C,$00; Table data bytes
	dc.b     $00,$0E,$66,$0A,$50,$C0,$14,$80,$51,$EE,$16,$81,$50,$C7,$4E,$75; Table data bytes
	dc.b     $50,$EE,$16,$81,$51,$EE,$16,$7F,$51,$EE,$16,$80,$50,$C7,$4E,$75; Table data bytes
	dc.b     $0C,$03,$00,$02,$62,$34,$7A,$0F,$20,$2E,$18,$20,$2A,$40,$61,$00; Table data bytes
	dc.b     $1A,$4A,$2D,$4D,$18,$20,$61,$00,$B7,$4C,$61,$00,$17,$C8,$67,$18; Table data bytes
	dc.b     $0C,$03,$00,$02,$66,$0E,$20,$6E,$18,$20,$B1,$EE,$18,$24,$65,$00; Table data bytes
	dc.b     $FF,$D8,$60,$04,$51,$CD,$FF,$D2,$50,$C7,$4E,$75,$53,$83,$66,$14; Table data bytes
	dc.b     $20,$2E,$18,$20,$41,$EE,$19,$9C,$30,$FC,$3E,$5F,$61,$00,$18,$2A; Table data bytes
	dc.b     $60,$00,$00,$CC,$4E,$75,$4A,$03,$67,$00,$00,$D4,$20,$4D,$72,$4F; Table data bytes
	dc.b     $10,$18,$0C,$00,$00,$5A,$62,$0E,$0C,$00,$00,$41,$65,$08,$08,$C0; Table data bytes
	dc.b     $00,$05,$11,$40,$FF,$FF,$51,$C9,$FF,$E8,$43,$FA,$69,$C3,$41,$ED; Table data bytes
	dc.b     $00,$19,$7A,$00,$70,$02,$12,$30,$00,$00,$08,$C1,$00,$05,$B2,$31; Table data bytes
	dc.b     $00,$00,$56,$C8,$FF,$F2,$67,$0C,$56,$49,$4A,$11,$6B,$00,$00,$84; Table data bytes
	dc.b     "RE`",$E0                             ; String literal data
	dc.b     $43,$FA,$67,$98,$76,$FF,$52,$83,$BA,$19,$67,$0A,$52,$49,$4A,$11; Table data bytes
	dc.b     $6B,$00,$00,$6C,$60,$F0,$47,$E8,$00,$03,$B7,$EE,$18,$0C,$62,$00; Table data bytes
	dc.b     $00,$0C,$0C,$13,$00,$20,$66,$04,$52,$4B,$60,$EE,$70,$00,$10,$19; Table data bytes
	dc.b     $D0,$40,$30,$3B,$00,$58,$50,$C7,$78,$01,$2F,$0B,$4E,$BB,$00,$4E; Table data bytes
	dc.b     $B7,$DF,$67,$C2,$4A,$07,$67,$BE,$2A,$6E,$18,$20,$1A,$83,$53,$04; Table data bytes
	dc.b     $67,$14,$1B,$40,$00,$01,$53,$04,$67,$0C,$1B,$41,$00,$02,$53,$04; Table data bytes
	dc.b     $67,$04,$1B,$42,$00,$03,$61,$00,$B1,$18,$61,$00,$19,$4A,$2D,$4D; Table data bytes
	dc.b     $18,$20,$61,$00,$B6,$4C,$61,$00,$19,$3E,$61,$00,$B6,$44,$61,$00; Table data bytes
	dc.b     $B1,$00,$1D,$7C,$00,$19,$16,$5D,$50,$C7,$4E,$75,$00,$72,$00,$3E; Table data bytes
	dc.b     $00,$4E,$00,$52,$00,$6A,$00,$76,$00,$96,$00,$A6,$00,$C2,$00,$D2; Table data bytes
	dc.b     $00,$D6,$00,$E6,$01,$16,$00,$5A,$01,$30,$01,$46,$00,$88,$01,$4C; Table data bytes
	dc.b     $01,$62,$01,$72,$01,$98,$00,$F0,$00,$DA,$00,$38,$00,$32,$4A,$2E; Table data bytes
	dc.b     $16,$80,$60,$04,$4A,$2E,$16,$7F,$67,$08,$0C,$1B,$00,$23,$66,$2C; Table data bytes
	dc.b     $60,$0C,$0C,$1B,$00,$23,$66,$00,$3C,$6A,$61,$5A,$60,$02,$61,$08; Table data bytes
	dc.b     $0C,$1B,$00,$20,$66,$16,$4E,$75,$78,$02,$0C,$13,$00,$24,$67,$00; Table data bytes
	dc.b     $18,$3A,$60,$00,$18,$6E,$0C,$1B,$00,$61,$67,$02,$51,$C7,$52,$4B; Table data bytes
	dc.b     $4E,$75,$0C,$1B,$00,$28,$66,$F4,$61,$DE,$61,$44,$0C,$1B,$00,$29; Table data bytes
	dc.b     $66,$EA,$4E,$75,$48,$7A,$FF,$CA,$0C,$1B,$00,$28,$66,$DE,$61,$C8; Table data bytes
	dc.b     $60,$EA,$61,$F4,$0C,$1B,$00,$2C,$66,$D2,$0C,$1B,$00,$79,$66,$CC; Table data bytes
	dc.b     "Nua",$B4                             ; String literal data
	dc.b     $60,$1A,$0C,$13,$00,$24,$67,$06,$61,$00,$18,$24,$60,$04,$61,$00; Table data bytes
	dc.b     $17,$DA,$78,$03,$32,$00,$E0,$49,$4E,$75,$61,$E6,$0C,$1B,$00,$2C; Table data bytes
	dc.b     $66,$A6,$0C,$1B,$00,$78,$66,$A0,$4E,$75,$61,$D6,$60,$C2,$61,$84; Table data bytes
	dc.b     $60,$BE,$0C,$1B,$00,$28,$66,$90,$61,$C8,$61,$E0,$60,$9A,$0C,$1B; Table data bytes
	dc.b     $00,$28,$66,$84,$61,$BC,$60,$90,$61,$18,$90,$AE,$18,$20,$57,$80; Table data bytes
	dc.b     $22,$3C,$00,$00,$7F,$FF,$B0,$81,$63,$B8,$46,$81,$B2,$80,$63,$B2; Table data bytes
	dc.b     $60,$22,$0C,$13,$00,$24,$67,$00,$17,$76,$60,$00,$17,$C2,$78,$02; Table data bytes
	dc.b     $61,$F0,$90,$AE,$18,$20,$55,$80,$72,$7F,$B0,$81,$63,$08,$72,$80; Table data bytes
	dc.b     $B2,$80,$63,$02,$51,$C7,$4E,$75,$48,$7A,$FF,$22,$0C,$1B,$00,$5B; Table data bytes
	dc.b     $66,$F2,$61,$00,$FF,$20,$0C,$1B,$00,$5D,$66,$E8,$4E,$75,$61,$EC; Table data bytes
	dc.b     $60,$00,$FF,$4E,$48,$7A,$FF,$06,$61,$00,$FF,$0A,$0C,$1B,$00,$2C; Table data bytes
	dc.b     $66,$D2,$0C,$1B,$00,$73,$66,$CC,$4E,$75,$0C,$1B,$00,$28,$66,$C4; Table data bytes
	dc.b     $61,$E6,$61,$00,$FF,$14,$60,$00,$FF,$28,$48,$7A,$FE,$E0,$0C,$13; Table data bytes
	dc.b     $00,$24,$67,$06,$61,$00,$17,$58,$60,$04,$61,$00,$17,$02,$78,$04; Table data bytes
	dc.b     $22,$00,$E0,$89,$24,$00,$48,$42,$0C,$42,$00,$FF,$62,$96,$4E,$75; Table data bytes
	dc.b     $61,$DC,$60,$00,$FF,$28,$0C,$03,$00,$03,$66,$6E,$22,$6E,$18,$20; Table data bytes
	dc.b     $24,$6E,$18,$24,$26,$6E,$18,$28,$41,$EE,$19,$9D,$49,$EE,$19,$E6; Table data bytes
	dc.b     $10,$19,$B0,$1B,$67,$3C,$2D,$49,$18,$20,$2C,$09,$61,$00,$1A,$1A; Table data bytes
	dc.b     $10,$2E,$16,$65,$67,$18,$48,$E7,$00,$E0,$48,$7A,$00,$0C,$53,$00; Table data bytes
	dc.b     $67,$00,$F4,$D8,$60,$00,$F5,$A8,$4C,$DF,$07,$00,$60,$14,$20,$09; Table data bytes
	dc.b     $53,$80,$61,$00,$15,$58,$54,$48,$B1,$CC,$65,$06,$61,$00,$B4,$3E; Table data bytes
	dc.b     $52,$48,$61,$00,$14,$B8,$67,$04,$B3,$CA,$65,$B4,$43,$EE,$19,$9D; Table data bytes
	dc.b     $B1,$C9,$67,$04,$61,$00,$B4,$26,$50,$C7,$4E,$75,$0C,$03,$00,$02; Table data bytes
	dc.b     $66,$76,$20,$0A,$67,$72,$43,$EE,$48,$94,$20,$49,$10,$1A,$0C,$00; Table data bytes
	dc.b     $00,$22,$67,$0E,$08,$C0,$00,$05,$10,$C0,$B5,$EE,$18,$0C,$62,$58; Table data bytes
	dc.b     $60,$EA,$10,$FC,$00,$2A,$51,$D0,$24,$49,$20,$2E,$18,$20,$08,$00; Table data bytes
	dc.b     $00,$00,$66,$44,$2C,$00,$2A,$40,$61,$00,$19,$FA,$2D,$4D,$18,$20; Table data bytes
	dc.b     $47,$EE,$19,$EC,$70,$44,$72,$20,$B2,$23,$56,$C8,$FF,$FC,$51,$EB; Table data bytes
	dc.b     $00,$01,$47,$EE,$19,$A7,$61,$3A,$66,$08,$61,$00,$19,$6C,$61,$00; Table data bytes
	dc.b     $B3,$BC,$61,$00,$14,$38,$67,$12,$20,$6E,$18,$20,$B1,$EE,$18,$24; Table data bytes
	dc.b     $65,$B8,$61,$00,$C4,$94,$50,$C7,$4E,$75,$61,$F6,$20,$0D,$41,$EE; Table data bytes
	dc.b     $19,$9D,$43,$FA,$3F,$1E,$61,$00,$26,$1E,$61,$00,$14,$A0,$60,$00; Table data bytes
	dc.b     $B3,$8C,$48,$E7,$00,$38,$49,$EE,$36,$94,$74,$00,$70,$00,$12,$12; Table data bytes
	dc.b     $66,$04,$4A,$13,$67,$7A,$0C,$01,$00,$2A,$66,$46,$0C,$42,$00,$08; Table data bytes
	dc.b     $66,$04,$70,$FF,$60,$6A,$30,$02,$E7,$48,$29,$8A,$00,$00,$52,$4A; Table data bytes
	dc.b     $29,$8B,$00,$04,$52,$42,$60,$D4,$53,$42,$6B,$0C,$30,$02,$E7,$48; Table data bytes
	dc.b     $20,$74,$00,$04,$4A,$10,$67,$F0,$4A,$42,$6B,$42,$30,$02,$E7,$48; Table data bytes
	dc.b     $24,$74,$00,$00,$52,$4A,$52,$B4,$00,$04,$52,$42,$26,$74,$00,$04; Table data bytes
	dc.b     $60,$AA,$0C,$01,$00,$3F,$66,$0A,$4A,$13,$66,$12,$4A,$42,$66,$C8; Table data bytes
	dc.b     $60,$1C,$10,$13,$B0,$12,$67,$06,$4A,$42,$66,$BC,$60,$10,$4A,$1A; Table data bytes
	dc.b     $66,$02,$53,$4A,$4A,$1B,$66,$84,$53,$4B,$60,$00,$FF,$80,$70,$01; Table data bytes
	dc.b     $4C,$DF,$1C,$00,$4A,$40,$4E,$75,$53,$83,$66,$10,$72,$02,$20,$2E; Table data bytes
	dc.b     $18,$20,$B0,$81,$62,$06,$1D,$40,$16,$65,$50,$C7,$4E,$75,$20,$0A; Table data bytes
	dc.b     $67,$22,$0C,$03,$00,$02,$66,$00,$00,$DA,$43,$EE,$18,$28,$70,$00; Table data bytes
	dc.b     $76,$02,$10,$1A,$0C,$00,$00,$22,$67,$0A,$22,$C0,$52,$43,$0C,$03; Table data bytes
	dc.b     $00,$10,$66,$EE,$0C,$03,$00,$03,$6D,$00,$00,$B8,$43,$EE,$18,$28; Table data bytes
	dc.b     $41,$EE,$19,$9C,$20,$FC,$20,$73,$65,$61,$20,$FC,$72,$63,$68,$69; Table data bytes
	dc.b     $20,$FC,$6E,$67,$20,$66,$20,$FC,$6F,$72,$3A,$20,$34,$03,$57,$42; Table data bytes
	dc.b     $20,$19,$61,$00,$13,$6E,$10,$FC,$00,$20,$51,$CA,$FF,$F4,$61,$00; Table data bytes
	dc.b     $B2,$7C,$52,$48,$22,$6E,$18,$20,$24,$6E,$18,$24,$18,$2E,$18,$2B; Table data bytes
	dc.b     $B8,$11,$66,$5A,$28,$49,$47,$EE,$18,$2B,$34,$03,$57,$42,$10,$1C; Table data bytes
	dc.b     $B0,$13,$66,$44,$58,$4B,$51,$CA,$FF,$F6,$2D,$49,$18,$20,$2C,$09; Table data bytes
	dc.b     $61,$00,$17,$F6,$10,$2E,$16,$65,$67,$18,$48,$E7,$00,$E0,$48,$7A; Table data bytes
	dc.b     $00,$0C,$53,$00,$67,$00,$F2,$B4,$60,$00,$F3,$84,$4C,$DF,$07,$00; Table data bytes
	dc.b     $60,$16,$20,$09,$61,$00,$13,$36,$54,$48,$49,$EE,$19,$E6,$B1,$CC; Table data bytes
	dc.b     $65,$06,$61,$00,$B2,$18,$52,$48,$61,$00,$12,$92,$67,$06,$52,$49; Table data bytes
	dc.b     $B3,$CA,$65,$9C,$43,$EE,$19,$9D,$B1,$C9,$67,$04,$61,$00,$B1,$FE; Table data bytes
	dc.b     $50,$C7,$4E,$75,$0C,$03,$00,$01,$66,$00,$00,$88,$10,$18,$E1,$48; Table data bytes
	dc.b     $10,$10,$00,$40,$20,$20,$0C,$40,$70,$63,$57,$C4,$70,$FE,$C0,$AE; Table data bytes
	dc.b     $18,$20,$22,$40,$95,$CA,$0C,$80,$00,$00,$80,$00,$63,$04,$45,$E9; Table data bytes
	dc.b     $80,$00,$49,$E9,$7F,$FE,$4A,$04,$66,$22,$32,$12,$02,$41,$F0,$F8; Table data bytes
	dc.b     $0C,$41,$50,$C8,$67,$20,$12,$12,$02,$41,$00,$F0,$0C,$41,$00,$60; Table data bytes
	dc.b     $66,$32,$12,$2A,$00,$01,$48,$81,$67,$0C,$60,$0E,$72,$3F,$C2,$52; Table data bytes
	dc.b     $0C,$41,$00,$3A,$66,$1E,$32,$2A,$00,$02,$47,$F2,$10,$02,$B7,$EE; Table data bytes
	dc.b     $18,$20,$66,$10,$2C,$0A,$61,$00,$17,$30,$2A,$4A,$61,$00,$17,$96; Table data bytes
	dc.b     $61,$00,$B1,$7A,$61,$00,$11,$F6,$67,$06,$54,$4A,$B9,$CA,$64,$A6; Table data bytes
	dc.b     $50,$C7,$4E,$75,$61,$00,$D3,$74,$41,$EE,$19,$9D,$20,$2E,$18,$14; Table data bytes
	dc.b     $61,$00,$D4,$B2,$41,$EE,$19,$B5,$20,$2E,$18,$18,$80,$FC,$00,$3C; Table data bytes
	dc.b     $61,$00,$12,$DA,$10,$FC,$00,$3A,$48,$40,$61,$00,$12,$D0,$10,$FC; Table data bytes
	dc.b     $00,$3A,$20,$2E,$18,$1C,$80,$FC,$00,$32,$61,$00,$12,$C0,$41,$EE; Table data bytes
	dc.b     $19,$9D,$61,$00,$B1,$28,$50,$C7,$4E,$75; Table data bytes
Memory_MoveOverlapSafe:
	cmpi.b   #$3,d3                                      ; Compare register d3 against constant $3
	bne.b    Memory_MoveOverlapSafe_Loc_63D8             ; Branch to Memory_MoveOverlapSafe_Loc_63D8 if non-zero / not equal
	movea.l  Var_MemStart(a6),a0                         ; Load monitored memory start offset into pointer a0
	movea.l  Var_MemEnd(a6),a1                           ; Load monitored memory end offset into pointer a1
	cmpa.l   a1,a0                                       ; Compare pointer a0 against pointer a1
	bcc.b    Memory_MoveOverlapSafe_Loc_63D8             ; Branch to Memory_MoveOverlapSafe_Loc_63D8 if carry clear (greater or equal)
	movea.l  Var_TempMemPtr(a6),a2                       ; Load temporary memory workspace pointer into pointer a2
	cmpa.l   a0,a2                                       ; Compare pointer a2 against pointer a0
	bcc.b    Memory_MoveOverlapSafe_Loc_63CC             ; Branch to Memory_MoveOverlapSafe_Loc_63CC if carry clear (greater or equal)
Memory_MoveOverlapSafe_Loc_63C4:
	move.b   (a0)+,(a2)+                                 ; Move (a0)+ to (a2)+
	cmpa.l   a1,a0                                       ; Compare pointer a0 against pointer a1
	bcs.b    Memory_MoveOverlapSafe_Loc_63C4             ; Branch to Memory_MoveOverlapSafe_Loc_63C4 if carry set (less than)
	bra.b    Memory_MoveOverlapSafe_Loc_63D6             ; Unconditional branch to Memory_MoveOverlapSafe_Loc_63D6
Memory_MoveOverlapSafe_Loc_63CC:
	adda.l   a1,a2                                       ; Add pointer a1 to pointer a2
	suba.l   a0,a2                                       ; Subtract pointer a0 from pointer a2
Memory_MoveOverlapSafe_Loc_63D0:
	move.b   -(a1),-(a2)                                 ; Move -(a1) to -(a2)
	cmpa.l   a0,a1                                       ; Compare pointer a1 against pointer a0
	bne.b    Memory_MoveOverlapSafe_Loc_63D0             ; Branch to Memory_MoveOverlapSafe_Loc_63D0 if non-zero / not equal
Memory_MoveOverlapSafe_Loc_63D6:
	st.b     d7
Memory_MoveOverlapSafe_Loc_63D8:
	rts                                                  ; Return from subroutine
	dc.b     $0C,$03,$00,$01,$62,$00,$02,$6E,$08,$38,$00,$00,$00,$07,$66,$00; Table data bytes
	dc.b     $02,$66,$4A,$B8,$00,$04,$67,$00,$02,$5E,$28,$78,$00,$04,$43,$FA; Table data bytes
	dc.b     "@UG",$EC                             ; String literal data
	dc.b     $01,$42,$20,$2E,$18,$20,$67,$72,$43,$FA,$40,$80,$47,$EC,$01,$50; Table data bytes
	dc.b     $53,$80,$67,$66,$43,$FA,$40,$E6,$47,$EC,$01,$5E,$53,$80,$67,$5A; Table data bytes
	dc.b     $43,$FA,$40,$A1,$47,$EC,$01,$6C,$53,$80,$67,$4E,$43,$FA,$40,$CE; Table data bytes
	dc.b     $47,$EC,$01,$7A,$53,$80,$67,$42,$43,$FA,$40,$FB,$47,$EC,$01,$88; Table data bytes
	dc.b     $53,$80,$67,$36,$43,$FA,$41,$28,$47,$EC,$01,$96,$53,$80,$67,$2A; Table data bytes
	dc.b     $43,$FA,$41,$1C,$47,$EC,$01,$A4,$53,$80,$67,$1E,$43,$FA,$41,$10; Table data bytes
	dc.b     $47,$EC,$01,$14,$53,$80,$67,$12,$43,$FA,$41,$3D,$47,$EC,$01,$2C; Table data bytes
	dc.b     $53,$80,$67,$00,$02,$14,$60,$00,$01,$D8,$61,$00,$BF,$44,$24,$5B; Table data bytes
	dc.b     $52,$48,$B5,$CB,$67,$00,$01,$C8,$20,$0A,$67,$00,$01,$C6,$08,$00; Table data bytes
	dc.b     $00,$00,$66,$00,$01,$BE,$61,$00,$11,$46,$20,$2E,$18,$20,$66,$00; Table data bytes
	dc.b     $00,$42,$41,$EE,$19,$9D,$20,$2A,$00,$14,$61,$00,$11,$32,$52,$48; Table data bytes
	dc.b     $20,$2A,$00,$10,$61,$00,$11,$28,$52,$48,$20,$2A,$00,$18,$61,$00; Table data bytes
	dc.b     $11,$1E,$52,$48,$20,$2A,$00,$1C,$61,$00,$11,$06,$52,$48,$30,$2A; Table data bytes
	dc.b     $00,$0E,$61,$00,$10,$EE,$10,$2A,$00,$09,$61,$00,$01,$98,$60,$00; Table data bytes
	dc.b     $01,$36,$55,$80,$67,$04,$55,$80,$66,$4C,$52,$48,$70,$00,$30,$2A; Table data bytes
	dc.b     $00,$20,$61,$00,$11,$9C,$41,$EE,$19,$AD,$30,$2A,$00,$14,$61,$00; Table data bytes
	dc.b     $11,$90,$41,$EE,$19,$B3,$30,$2A,$00,$16,$61,$00,$11,$84,$41,$EE; Table data bytes
	dc.b     $19,$B9,$30,$2A,$00,$10,$61,$00,$11,$78,$41,$EE,$19,$BF,$30,$2A; Table data bytes
	dc.b     $00,$12,$61,$00,$11,$6C,$41,$EE,$19,$C5,$30,$2A,$00,$1C,$61,$00; Table data bytes
	dc.b     $10,$92,$60,$00,$00,$E2,$53,$80,$66,$70,$22,$3C,$20,$53,$69,$67; Table data bytes
	dc.b     "$<nal "                              ; String literal data
	dc.b     $10,$2A,$00,$0E,$67,$1C,$22,$3C,$20,$53,$6F,$66,$24,$3C,$74,$69; Table data bytes
	dc.b     $6E,$74,$53,$00,$67,$0C,$22,$3C,$20,$49,$67,$6E,$24,$3C,$6F,$72; Table data bytes
	dc.b     "e  ",$C1                             ; String literal data
	dc.b     $20,$C2,$54,$48,$70,$00,$10,$2A,$00,$0F,$61,$00,$11,$1A,$41,$EE; Table data bytes
	dc.b     $19,$B4,$22,$6A,$00,$10,$20,$09,$67,$1A,$08,$00,$00,$00,$66,$00; Table data bytes
	dc.b     $00,$C8,$22,$69,$00,$0A,$20,$09,$67,$0A,$70,$15,$10,$D9,$57,$C8; Table data bytes
	dc.b     $FF,$FC,$60,$08,$20,$BC,$2D,$2D,$2D,$2D,$20,$98,$60,$00,$00,$6E; Table data bytes
	dc.b     $53,$80,$67,$0A,$53,$80,$67,$06,$53,$80,$66,$00,$00,$60,$52,$48; Table data bytes
	dc.b     $43,$FA,$45,$74,$10,$2A,$00,$08,$0C,$00,$00,$0E,$61,$00,$00,$98; Table data bytes
	dc.b     $41,$EE,$19,$AF,$10,$2A,$00,$09,$61,$00,$00,$A0,$41,$EE,$19,$B4; Table data bytes
	dc.b     $43,$FA,$45,$B9,$10,$2A,$00,$0F,$0C,$00,$00,$06,$61,$00,$00,$78; Table data bytes
	dc.b     $41,$EE,$19,$BC,$20,$2A,$00,$3A,$61,$00,$0F,$EA,$52,$48,$20,$2A; Table data bytes
	dc.b     $00,$3E,$90,$AA,$00,$3A,$61,$00,$10,$8E,$41,$EE,$19,$CC,$20,$2A; Table data bytes
	dc.b     $00,$3E,$90,$AA,$00,$36,$61,$00,$10,$7E,$4E,$71,$41,$EE,$19,$D2; Table data bytes
	dc.b     $22,$6A,$00,$0A,$20,$09,$67,$0A,$70,$19,$10,$D9,$57,$C8,$FF,$FC; Table data bytes
	dc.b     $60,$08,$20,$BC,$2D,$2D,$2D,$2D,$20,$98,$61,$00,$AE,$98,$24,$52; Table data bytes
	dc.b     $20,$0A,$67,$10,$08,$00,$00,$00,$66,$0E,$43,$EC,$01,$18,$B3,$CB; Table data bytes
	dc.b     $66,$00,$FE,$34,$50,$C7,$4E,$75,$61,$00,$BF,$66,$50,$C7,$43,$FA; Table data bytes
	dc.b     $3F,$78,$60,$00,$BD,$62               ; Table data bytes
StringTable_Lookup:
	bls.b    StringTable_Lookup_SkipLoop                              ; Branch to StringTable_Lookup_SkipLoop if lower or same.
	moveq    #$0,d0                                      ; Initialize register d0 to 0
StringTable_Lookup_SkipLoop:
	subq.b   #$1,d0                                      ; Subtract 1 from register d0
	bmi.b    StringTable_Lookup_Found                    ; Branch to StringTable_Lookup_Found if negative / minus
StringTable_Lookup_CharLoop:
	btst     #$7,(a1)+                                   ; Test bit #$7 of (a1)+
	beq.b    StringTable_Lookup_CharLoop                 ; Branch to StringTable_Lookup_CharLoop if zero / equal
	bra.b    StringTable_Lookup_SkipLoop                 ; Unconditional branch to StringTable_Lookup_SkipLoop
StringTable_Lookup_Found:
	bra.w    CopyHighBitTerminatedString                 ; Unconditional branch to CopyHighBitTerminatedString
	dc.b     $54,$48,$48,$80,$48,$C0,$6A,$08,$11,$7C,$00,$2D,$FF,$FF,$44,$80; Table data bytes
	dc.b     $60,$00,$10,$0A,$61,$00,$BD,$36,$26,$53,$52,$48,$20,$1B,$67,$50; Table data bytes
	dc.b     $08,$80,$00,$1F,$67,$04,$26,$40,$60,$F2,$24,$40,$61,$00,$0F,$3C; Table data bytes
	dc.b     "RHC",$FA                             ; String literal data
	dc.b     $44,$88,$70,$00,$10,$2A,$00,$0C,$0C,$00,$00,$0E,$61,$AA,$41,$EE; Table data bytes
	dc.b     $19,$AF,$10,$2A,$00,$0D,$61,$B4,$41,$EE,$19,$C4,$22,$6A,$00,$12; Table data bytes
	dc.b     $20,$09,$67,$0A,$70,$27,$10,$D9,$57,$C8,$FF,$FC,$60,$08,$20,$BC; Table data bytes
	dc.b     "---- "                               ; String literal data
	dc.b     $98,$61,$00,$AD,$EE,$60,$AA,$50,$C7,$4E,$75,$4A,$83,$66,$00,$00; Table data bytes
	dc.b     $B2,$61,$00,$AA,$9C,$49,$EE,$19,$9C,$45,$FA,$4D,$B6,$47,$FA,$50; Table data bytes
	dc.b     $5E,$7C,$00,$20,$4C,$20,$3C,$00,$DF,$F0,$00,$D0,$46,$D0,$46,$61; Table data bytes
	dc.b     $00,$0E,$C2,$52,$48,$BC,$12,$66,$0C,$43,$EA,$00,$01,$61,$00,$20; Table data bytes
	dc.b     "<$I`J"                               ; String literal data
	dc.b     $22,$4B,$BC,$29,$00,$01,$62,$32,$74,$00,$14,$06,$94,$11,$65,$2A; Table data bytes
	dc.b     $72,$00,$12,$29,$00,$02,$84,$C1,$48,$42,$4A,$42,$66,$1C,$56,$49; Table data bytes
	dc.b     $10,$D9,$0C,$11,$00,$20,$62,$F8,$48,$42,$D4,$19,$70,$00,$10,$02; Table data bytes
	dc.b     $61,$00,$0F,$3C,$61,$00,$20,$00,$60,$10,$56,$49,$08,$19,$00,$07; Table data bytes
	dc.b     $67,$FA,$0C,$11,$00,$FF,$66,$BA,$60,$12,$49,$EC,$00,$14,$41,$EE; Table data bytes
	dc.b     $19,$D8,$B9,$C8,$63,$06,$61,$00,$AD,$54,$28,$48,$10,$2E,$16,$5C; Table data bytes
	dc.b     $B0,$2E,$16,$61,$66,$0A,$61,$00,$0D,$DE,$67,$0E,$61,$00,$A9,$FC; Table data bytes
	dc.b     $52,$46,$0C,$46,$01,$00,$66,$00,$FF,$66,$50,$C7,$4E,$75,$99,$CC; Table data bytes
	dc.b     $2A,$6E,$18,$04,$4A,$83,$67,$20,$55,$83,$66,$00,$00,$94,$4C,$EE; Table data bytes
	dc.b     $30,$00,$18,$20,$BB,$CC,$63,$00,$00,$88,$20,$0C,$07,$00,$66,$00; Table data bytes
	dc.b     $00,$80,$20,$0D,$07,$00,$66,$78,$24,$3C,$00,$88,$00,$8A,$BB,$CC; Table data bytes
	dc.b     $67,$6C,$30,$1C,$B4,$40,$67,$10,$48,$42,$B4,$40,$67,$0A,$52,$40; Table data bytes
	dc.b     $66,$EC,$0C,$54,$FF,$FE,$66,$E6,$54,$4C,$47,$EC,$FF,$FC,$76,$FB; Table data bytes
	dc.b     $72,$F5,$53,$01,$67,$2C,$70,$02,$D0,$A3,$67,$26,$55,$80,$48,$40; Table data bytes
	dc.b     $08,$00,$00,$00,$66,$EC,$B0,$42,$67,$18,$48,$42,$B0,$42,$67,$12; Table data bytes
	dc.b     $0C,$40,$00,$20,$65,$0C,$0C,$40,$01,$FE,$62,$06,$52,$83,$28,$0B; Table data bytes
	dc.b     $60,$CE,$4A,$83,$6B,$16,$41,$EE,$19,$9D,$20,$04,$22,$0C,$61,$00; Table data bytes
	dc.b     $0D,$60,$61,$00,$AC,$98,$61,$00,$0D,$14,$67,$02,$60,$90,$50,$C7; Table data bytes
	dc.b     $4E,$75                               ; Table data bytes
; ============================================================================
; Data Block: Console_Draw_SingleStep
; Purpose   : Display callback routine pushed to stack for single step rendering.
; ============================================================================
Console_Draw_SingleStep:
	cmpi.b   #$2,d3
	bgt.b    .L_Console_Draw_SingleStep_0028
	moveq    #$f,d5
.L_Console_Draw_SingleStep_0008:
	dc.w     $6120 ; bsr.b $2a (external)
	dc.w     $6100,$0CFE ; bsr.w $d0a (external)
	beq.b    .L_Console_Draw_SingleStep_0026
	cmpi.b   #$2,d3
	bne.b    .L_Console_Draw_SingleStep_0022
	movea.l  $1820(a6),a0
	cmpa.l   $1824(a6),a0
	bcs.b    .L_Console_Draw_SingleStep_0008
	bra.b    .L_Console_Draw_SingleStep_0026
.L_Console_Draw_SingleStep_0022:
	dbra     d5,.L_Console_Draw_SingleStep_0008
.L_Console_Draw_SingleStep_0026:
	st.b     d7
.L_Console_Draw_SingleStep_0028:
	rts      
; ============================================================================
; Data Block: Console_Callback_SingleStep
; Purpose   : Parser callback routine for single step modifications.
; ============================================================================
Console_Callback_SingleStep:
	lea.l    $199c(a6),a0
	move.w   #$3e2e,(a0)+
	move.l   $1820(a6),d0
	movea.l  d0,a2
	btst     #$0,d0
	dc.w     $6600,$FFEA ; bne.w $fffffffe (external)
	dc.w     $6100,$0D5C ; bsr.w $d74 (external)
	adda.w   #$1,a0
	move.l   (a2),d1
	moveq    #$fe,d0
	cmp.l    d0,d1
	bne.b    .L_Console_Callback_SingleStep_0032
	dc.w     $43FA,$40B0 ; lea.l $40d8(pc),a1 (external)
	dc.w     $6100,$1EBE ; bsr.w $1eea (external)
	bra.w    .L_Console_Callback_SingleStep_0146
.L_Console_Callback_SingleStep_0032:
	move.l   d1,d0
	andi.l   #$10001,d0
	cmpi.l   #$10000,d0
	bne.b    .L_Console_Callback_SingleStep_0048
	dc.w     $43FA,$4090 ; lea.l $40d4(pc),a1 (external)
	bra.b    .L_Console_Callback_SingleStep_0054
.L_Console_Callback_SingleStep_0048:
	cmpi.l   #$10001,d0
	bne.b    .L_Console_Callback_SingleStep_00a0
	dc.w     $43FA,$407E ; lea.l $40d0(pc),a1 (external)
.L_Console_Callback_SingleStep_0054:
	dc.w     $6100,$1E94 ; bsr.w $1eea (external)
	addq.w   #$4,a0
	moveq    #$8,d2
	rol.l    d2,d1
	move.b   d1,d0
	dc.w     $6100,$0CE4 ; bsr.w $d46 (external)
	move.b   #$2c,(a0)+
	rol.l    d2,d1
	move.b   d1,d0
	lsr.b    #$1,d0
	dc.w     $6100,$0CD6 ; bsr.w $d46 (external)
	move.b   #$2c,(a0)+
	rol.l    d2,d1
	moveq    #$30,d0
	bclr     #$7,d1
	beq.b    .L_Console_Callback_SingleStep_0082
	moveq    #$31,d0
.L_Console_Callback_SingleStep_0082:
	move.b   d0,(a0)+
	move.b   #$2c,(a0)+
	move.b   d1,d0
	dc.w     $6100,$0CBA ; bsr.w $d46 (external)
	move.b   #$2c,(a0)+
	rol.l    d2,d1
	move.b   d1,d0
	lsr.b    #$1,d0
	dc.w     $6100,$0CAC ; bsr.w $d46 (external)
	bra.w    .L_Console_Callback_SingleStep_0146
.L_Console_Callback_SingleStep_00a0:
	dc.w     $43FA,$402A ; lea.l $40cc(pc),a1 (external)
	dc.w     $6100,$1E44 ; bsr.w $1eea (external)
	addq.w   #$4,a0
	move.b   #$23,(a0)+
	move.w   d1,d0
	dc.w     $6100,$0CA2 ; bsr.w $d54 (external)
	move.b   #$2c,(a0)+
	moveq    #$0,d0
	move.w   (a2),d1
	cmpi.w   #$3e,d1
	bls.w    .L_Console_Callback_SingleStep_0140
	cmpi.w   #$1fe,d1
	bhi.b    .L_Console_Callback_SingleStep_0140
	move.w   d1,d0
	lsr.w    #$1,d0
	dc.w     $43FA,$4C3B ; lea.l $4d0b(pc),a1 (external)
.L_Console_Callback_SingleStep_00d2:
	cmp.b    (a1),d0
	bne.b    .L_Console_Callback_SingleStep_00e2
	addq.w   #$1,a1
.L_Console_Callback_SingleStep_00d8:
	move.b   (a1)+,(a0)
	bclr     #$7,(a0)+
	beq.b    .L_Console_Callback_SingleStep_00d8
	bra.b    .L_Console_Callback_SingleStep_0146
.L_Console_Callback_SingleStep_00e2:
	cmpi.b   #$ff,(a1)+
	beq.b    .L_Console_Callback_SingleStep_00f0
.L_Console_Callback_SingleStep_00e8:
	btst     #$7,(a1)+
	beq.b    .L_Console_Callback_SingleStep_00e8
	bra.b    .L_Console_Callback_SingleStep_00d2
.L_Console_Callback_SingleStep_00f0:
	dc.w     $43FA,$4E0E ; lea.l $4f00(pc),a1 (external)
.L_Console_Callback_SingleStep_00f4:
	cmp.b    (a1),d0
	bcs.b    .L_Console_Callback_SingleStep_0130
	cmp.b    $1(a1),d0
	bhi.b    .L_Console_Callback_SingleStep_0130
	moveq    #$0,d2
	move.b   d0,d4
.L_Console_Callback_SingleStep_0102:
	cmp.b    (a1),d4
	beq.b    .L_Console_Callback_SingleStep_0112
	addq.b   #$1,d2
	sub.b    $2(a1),d4
	cmp.b    (a1),d4
	bcc.b    .L_Console_Callback_SingleStep_0102
	bra.b    .L_Console_Callback_SingleStep_0130
.L_Console_Callback_SingleStep_0112:
	addq.w   #$3,a1
.L_Console_Callback_SingleStep_0114:
	move.b   (a1)+,d0
	cmpi.b   #$1,d0
	bhi.b    .L_Console_Callback_SingleStep_0126
	add.b    d0,d2
	move.l   d2,d0
	dc.w     $6100,$0D00 ; bsr.w $e22 (external)
	bra.b    .L_Console_Callback_SingleStep_0114
.L_Console_Callback_SingleStep_0126:
	move.b   d0,(a0)
	bclr     #$7,(a0)+
	beq.b    .L_Console_Callback_SingleStep_0114
	bra.b    .L_Console_Callback_SingleStep_0146
.L_Console_Callback_SingleStep_0130:
	cmpi.b   #$ff,(a1)
	beq.b    .L_Console_Callback_SingleStep_0140
	addq.w   #$3,a1
.L_Console_Callback_SingleStep_0138:
	btst     #$7,(a1)+
	beq.b    .L_Console_Callback_SingleStep_0138
	bra.b    .L_Console_Callback_SingleStep_00f4
.L_Console_Callback_SingleStep_0140:
	move.w   d1,d0
	dc.w     $6100,$0C10 ; bsr.w $d54 (external)
.L_Console_Callback_SingleStep_0146:
	addq.l   #$4,$1820(a6)
	dc.w     $6000,$AB14 ; bra.w $ffffac60 (external)
.L_Console_Callback_SingleStep_014e:
	tst.b    d3
	beq.w    .L_Console_Callback_SingleStep_014e
	btst     #$0,$1823(a6)
	bne.b    .L_Console_Callback_SingleStep_014e
	movea.l  a5,a0
	addq.w   #$2,a0
	dc.w     $6100,$B784 ; bsr.w $ffffb8e6 (external)
.L_Console_Callback_SingleStep_0164:
	cmpa.l   $180c(a6),a0
	dc.w     $6200,$FE94 ; bhi.w $fffffffe (external)
	cmpi.b   #$20,(a0)+
	bne.b    .L_Console_Callback_SingleStep_0164
.L_Console_Callback_SingleStep_0172:
	cmpa.l   $180c(a6),a0                                ; Check if we reached the end of the line buffer
	dc.w     $6200,$0206                                 ; bhi.w $37e (external) - If beyond buffer, exit loop
	cmpi.b   #$20,(a0)                                   ; Check if character is a space ($20)
	bne.b    .L_Console_Callback_SingleStep_Skip_Addq    ; If not a space, skip adding 1 to the pointer
	addq.w   #$1,a0                                      ; Advance pointer by 1 byte (skip the space)
	bra.b    .L_Console_Callback_SingleStep_0172         ; Loop back to process the next character
.L_Console_Callback_SingleStep_Skip_Addq:
	dc.b     $24,$48,$B1,$EE,$18,$0C,$62,$18,$10,$18,$0C,$00,$00,$5A,$62,$F2; Table data bytes
	dc.b     $0C,$00,$00,$41,$65,$EC,$08,$C0,$00,$05,$11,$40,$FF,$FF,$60,$E2; Table data bytes
	dc.b     $43,$FA,$3F,$26,$61,$00,$01,$D8,$66,$00,$00,$FA,$0C,$1B,$00,$23; Table data bytes
	dc.b     $66,$00,$01,$BE,$50,$C7,$61,$00,$0D,$02,$4A,$07,$67,$00,$01,$B2; Table data bytes
	dc.b     $3C,$00,$0C,$1B,$00,$2C,$66,$00,$01,$A8,$0C,$13,$00,$24,$66,$1C; Table data bytes
	dc.b     $61,$00,$0C,$E8,$4A,$07,$67,$00,$01,$98,$08,$00,$00,$00,$66,$00; Table data bytes
	dc.b     $01,$90,$48,$40,$30,$06,$2C,$00,$60,$00,$01,$74,$43,$FA,$4B,$19; Table data bytes
	dc.b     $20,$4B,$70,$00,$10,$19,$12,$11,$08,$C1,$00,$05,$08,$81,$00,$07; Table data bytes
	dc.b     $B2,$18,$66,$0A,$08,$19,$00,$07,$67,$EC,$D0,$40,$60,$D4,$0C,$00; Table data bytes
	dc.b     $00,$FF,$67,$08,$08,$19,$00,$07,$67,$FA,$60,$D4,$43,$FA,$4C,$DE; Table data bytes
	dc.b     $20,$4B,$70,$00,$10,$19,$74,$00,$14,$19,$76,$00,$16,$19,$12,$11; Table data bytes
	dc.b     $0C,$01,$00,$01,$62,$44,$78,$00,$18,$10,$04,$04,$00,$30,$65,$00; Table data bytes
	dc.b     $00,$3A,$0C,$04,$00,$09,$62,$00,$00,$32,$52,$48,$1A,$10,$04,$05; Table data bytes
	dc.b     $00,$30,$65,$0E,$0C,$05,$00,$09,$62,$08,$52,$48,$C8,$FC,$00,$0A; Table data bytes
	dc.b     $D8,$05,$98,$01,$6B,$00,$01,$0A,$D6,$43,$C8,$C3,$D0,$40,$D8,$40; Table data bytes
	dc.b     $D4,$42,$B8,$42,$62,$00,$00,$FA,$60,$0C,$08,$C1,$00,$05,$08,$81; Table data bytes
	dc.b     $00,$07,$B2,$18,$66,$0C,$08,$19,$00,$07,$67,$A2,$30,$04,$60,$00; Table data bytes
	dc.b     $FF,$52,$0C,$00,$00,$FF,$67,$00,$00,$D8,$08,$19,$00,$07,$67,$FA; Table data bytes
	dc.b     $60,$00,$FF,$7E,$43,$FA,$3E,$2A,$61,$00,$00,$D4,$66,$08,$2C,$3C; Table data bytes
	dc.b     $00,$01,$00,$00,$60,$10,$43,$FA,$3E,$14,$61,$00,$00,$C2,$66,$7A; Table data bytes
	dc.b     $2C,$3C,$00,$01,$00,$01,$50,$C7,$61,$00,$0B,$FC,$4A,$07,$67,$00; Table data bytes
	dc.b     $00,$A0,$18,$00,$E1,$8C,$0C,$1B,$00,$2C,$66,$00,$00,$94,$61,$00; Table data bytes
	dc.b     $0B,$E6,$4A,$07,$67,$00,$00,$8A,$D0,$00,$65,$00,$00,$84,$18,$00; Table data bytes
	dc.b     $E1,$8C,$0C,$1B,$00,$2C,$66,$78,$10,$1B,$72,$30,$B2,$00,$67,$0A; Table data bytes
	dc.b     $72,$31,$B2,$00,$66,$6A,$08,$C4,$00,$07,$0C,$1B,$00,$2C,$66,$60; Table data bytes
	dc.b     $61,$00,$0B,$B4,$4A,$07,$67,$58,$0C,$00,$00,$7F,$62,$52,$88,$00; Table data bytes
	dc.b     $E1,$8C,$0C,$1B,$00,$2C,$66,$48,$61,$00,$0B,$9C,$4A,$07,$67,$40; Table data bytes
	dc.b     $D0,$00,$65,$3C,$18,$00,$8C,$84,$60,$24,$43,$FA,$3D,$98,$61,$3E; Table data bytes
	dc.b     $66,$04,$7C,$FE,$60,$18,$43,$FA,$3D,$93,$61,$32,$66,$0E,$50,$C7; Table data bytes
	dc.b     $61,$00,$0B,$5C,$4A,$07,$67,$18,$2C,$00,$60,$02,$60,$12,$20,$6E; Table data bytes
	dc.b     $18,$20,$20,$86,$61,$00,$A3,$B6,$76,$01,$7A,$01,$61,$00,$FC,$6C; Table data bytes
	dc.b     $61,$00,$A3,$AA,$1D,$7C,$00,$0B,$16,$5D,$50,$C7,$4E,$75,$2F,$0A; Table data bytes
	dc.b     $10,$11,$08,$C0,$00,$05,$08,$80,$00,$07,$B0,$1A,$66,$10,$08,$19; Table data bytes
	dc.b     $00,$07,$67,$EC,$20,$4A,$61,$00,$B5,$4A,$26,$48,$70,$00,$24,$5F; Table data bytes
	dc.b     $4E,$75,$78,$00,$60,$18,$78,$01,$60,$14,$78,$02,$60,$10,$78,$03; Table data bytes
	dc.b     $60,$06,$78,$04,$60,$02,$78,$05,$45,$FA,$34,$1B,$60,$04,$45,$FA; Table data bytes
	dc.b     $34,$08,$1A,$3B,$40,$66,$0C,$05,$00,$08,$67,$10,$0C,$2E,$00,$02; Table data bytes
	dc.b     $16,$57,$64,$08,$08,$2E,$00,$00,$18,$23,$66,$40,$57,$83,$66,$3C; Table data bytes
	dc.b     $0B,$C3,$4C,$EE,$00,$07,$18,$20,$4A,$05,$67,$04,$B4,$83,$64,$2C; Table data bytes
	dc.b     $20,$40,$D8,$44,$49,$FA,$00,$28,$D8,$FB,$40,$24,$E5,$4C,$4E,$BB; Table data bytes
	dc.b     $40,$30,$22,$08,$41,$EE,$19,$9D,$61,$00,$09,$16,$22,$4A,$61,$00; Table data bytes
	dc.b     $1A,$D6,$20,$02,$4E,$94,$61,$00,$A8,$44,$50,$C7,$4E,$75,$09,$24; Table data bytes
	dc.b     $09,$32,$09,$4E,$09,$24,$09,$32,$09,$4E,$08,$10,$00,$08,$10,$00; Table data bytes
	dc.b     $10,$C2,$B1,$C1,$65,$FA,$4E,$75,$30,$C2,$B1,$C1,$65,$FA,$4E,$75; Table data bytes
	dc.b     $20,$C2,$B1,$C1,$65,$FA,$4E,$75,$B5,$18,$B1,$C1,$65,$FA,$4E,$75; Table data bytes
	dc.b     $B5,$58,$B1,$C1,$65,$FA,$4E,$75,$B5,$98,$B1,$C1,$65,$FA,$4E,$75; Table data bytes
	dc.b     $55,$83,$66,$18,$4C,$EE,$00,$03,$18,$20,$07,$00,$66,$0E,$20,$40; Table data bytes
	dc.b     $53,$81,$6B,$06,$30,$FC,$4E,$71,$60,$F6,$50,$C7,$4E,$75,$55,$83; Table data bytes
	dc.b     "kjL",$EE                             ; String literal data
	dc.b     $00,$07,$18,$20,$53,$83,$67,$02,$74,$00,$76,$0B,$B4,$83,$62,$58; Table data bytes
	dc.b     $48,$42,$08,$00,$00,$00,$66,$50,$20,$40,$92,$80,$63,$4A,$20,$01; Table data bytes
	dc.b     $26,$00,$93,$C9,$22,$02,$61,$42,$41,$EE,$19,$9D,$43,$FA,$33,$79; Table data bytes
	dc.b     $22,$00,$67,$2A,$43,$FA,$33,$83,$6B,$24,$43,$FA,$33,$A3,$61,$00; Table data bytes
	dc.b     $1A,$22,$96,$81,$20,$03,$61,$00,$08,$CE,$43,$FA,$33,$7B,$61,$00; Table data bytes
	dc.b     $1A,$12,$20,$2E,$18,$20,$D2,$80,$61,$00,$08,$42,$60,$04,$61,$00; Table data bytes
	dc.b     $1A,$02,$61,$00,$A7,$74,$50,$C7,$4E,$75,$48,$E7,$3F,$3E,$74,$57; Table data bytes
	dc.b     "BgQ",$CA                             ; String literal data
	dc.b     $FF,$FC,$2C,$4F,$0C,$80,$00,$00,$00,$40,$65,$00,$02,$3C,$E0,$89; Table data bytes
	dc.b     $55,$D6,$E0,$89,$0C,$01,$00,$0C,$65,$02,$72,$00,$2D,$48,$00,$0A; Table data bytes
	dc.b     $2D,$48,$00,$22,$2D,$48,$00,$26,$2D,$40,$00,$12,$D1,$C0,$2D,$48; Table data bytes
	dc.b     $00,$0E,$41,$FA,$02,$28,$E5,$49,$22,$30,$10,$00,$52,$81,$B2,$80; Table data bytes
	dc.b     $63,$04,$22,$00,$53,$81,$2D,$41,$00,$1A,$53,$81,$70,$00,$B2,$98; Table data bytes
	dc.b     $63,$04,$52,$00,$60,$F8,$1D,$40,$00,$01,$43,$EE,$00,$A4,$72,$0C; Table data bytes
	dc.b     $C0,$C1,$41,$FA,$02,$28,$D1,$C0,$53,$41,$12,$D8,$51,$C9,$FF,$FC; Table data bytes
	dc.b     $43,$EE,$00,$74,$41,$EE,$00,$A4,$72,$0B,$10,$18,$74,$00,$01,$C2; Table data bytes
	dc.b     $22,$C2,$51,$C9,$FF,$F6,$41,$EE,$00,$74,$43,$EE,$00,$84,$72,$07; Table data bytes
	dc.b     $20,$18,$D1,$99,$51,$C9,$FF,$FA,$4A,$16,$67,$1A,$43,$EE,$00,$74; Table data bytes
	dc.b     $70,$07,$22,$19,$34,$C1,$51,$C8,$FF,$FA,$43,$EE,$00,$A4,$70,$0B; Table data bytes
	dc.b     $14,$D9,$51,$C8,$FF,$FC,$1D,$7C,$00,$07,$00,$2D,$61,$00,$02,$8A; Table data bytes
	dc.b     $67,$00,$01,$82,$61,$00,$02,$DA,$67,$70,$61,$00,$05,$0A,$66,$20; Table data bytes
	dc.b     $4B,$EE,$00,$1E,$52,$9D,$20,$55,$52,$9D,$22,$55,$12,$90,$52,$95; Table data bytes
	dc.b     $52,$AE,$00,$30,$0C,$AE,$00,$00,$40,$12,$00,$30,$65,$CE,$60,$4A; Table data bytes
	dc.b     $10,$2E,$00,$5C,$22,$2E,$00,$60,$61,$00,$03,$8E,$10,$2E,$00,$5E; Table data bytes
	dc.b     $32,$2E,$00,$66,$61,$00,$03,$82,$10,$2E,$00,$5D,$32,$2E,$00,$64; Table data bytes
	dc.b     $0C,$00,$00,$0D,$66,$0E,$20,$6E,$00,$26,$10,$C1,$2D,$48,$00,$26; Table data bytes
	dc.b     $70,$05,$72,$1F,$61,$00,$03,$62,$70,$00,$2D,$40,$00,$30,$10,$2E; Table data bytes
	dc.b     $00,$2E,$D1,$AE,$00,$22,$60,$00,$FF,$84,$61,$00,$02,$0C,$67,$00; Table data bytes
	dc.b     $01,$04,$4B,$EE,$00,$1E,$52,$9D,$20,$55,$52,$95,$20,$1D,$22,$55; Table data bytes
	dc.b     $12,$90,$52,$95,$52,$AE,$00,$30,$B0,$AE,$00,$0E,$66,$DC,$61,$00; Table data bytes
	dc.b     $01,$E8,$67,$00,$00,$E0,$4A,$16,$66,$00,$00,$98,$20,$2E,$00,$26; Table data bytes
	dc.b     $90,$AE,$00,$0A,$72,$0C,$B0,$81,$65,$00,$00,$CE,$22,$2E,$00,$12; Table data bytes
	dc.b     $92,$80,$7E,$36,$B2,$87,$63,$00,$00,$C0,$22,$6E,$00,$0A,$20,$6E; Table data bytes
	dc.b     $00,$26,$3E,$3C,$FF,$00,$08,$00,$00,$00,$67,$06,$7E,$00,$52,$80; Table data bytes
	dc.b     $42,$18,$21,$51,$00,$08,$22,$BC,$49,$4D,$50,$21,$21,$69,$00,$04; Table data bytes
	dc.b     $00,$04,$23,$6E,$00,$12,$00,$04,$20,$A9,$00,$08,$23,$40,$00,$08; Table data bytes
	dc.b     $72,$2E,$D0,$81,$2D,$40,$00,$16,$21,$6E,$00,$30,$00,$0C,$12,$2E; Table data bytes
	dc.b     $00,$2C,$02,$41,$00,$FE,$10,$2E,$00,$2D,$01,$C1,$82,$47,$31,$41; Table data bytes
	dc.b     $00,$10,$43,$EE,$00,$74,$D0,$FC,$00,$12,$70,$07,$22,$19,$30,$C1; Table data bytes
	dc.b     $51,$C8,$FF,$FA,$43,$EE,$00,$A4,$70,$0B,$10,$D9,$51,$C8,$FF,$FC; Table data bytes
	dc.b     "`F ."                                ; String literal data
	dc.b     $00,$26,$90,$AE,$00,$0A,$22,$2E,$00,$12,$92,$80,$74,$06,$B2,$82; Table data bytes
	dc.b     $63,$32,$12,$2E,$00,$2C,$02,$01,$00,$FE,$14,$2E,$00,$2D,$05,$C1; Table data bytes
	dc.b     $20,$6E,$00,$26,$08,$00,$00,$00,$67,$08,$10,$C1,$20,$AE,$00,$30; Table data bytes
	dc.b     $60,$06,$20,$EE,$00,$30,$10,$81,$5A,$80,$2D,$40,$00,$16,$60,$04; Table data bytes
	dc.b     $70,$FF,$60,$04,$20,$2E,$00,$16,$74,$57,$42,$5F,$51,$CA,$FF,$FC; Table data bytes
	dc.b     $4C,$DF,$7C,$FC,$4A,$80,$4E,$75,$00,$00,$00,$80,$00,$00,$01,$00; Table data bytes
	dc.b     $00,$00,$02,$00,$00,$00,$04,$00,$00,$00,$07,$00,$00,$00,$0D,$00; Table data bytes
	dc.b     $00,$00,$15,$00,$00,$00,$25,$00,$00,$00,$51,$00,$00,$00,$92,$00; Table data bytes
	dc.b     $00,$01,$09,$00,$00,$01,$09,$00,$05,$05,$05,$05,$05,$05,$05,$05; Table data bytes
	dc.b     $06,$06,$06,$06,$05,$06,$07,$07,$06,$06,$06,$06,$07,$07,$06,$06; Table data bytes
	dc.b     $05,$06,$07,$07,$07,$07,$07,$07,$08,$08,$08,$08,$05,$06,$07,$08; Table data bytes
	dc.b     $07,$07,$08,$08,$08,$08,$09,$09,$06,$07,$07,$08,$07,$08,$09,$09; Table data bytes
	dc.b     $08,$09,$0A,$0A,$06,$07,$07,$08,$07,$09,$09,$0A,$08,$0A,$0B,$0B; Table data bytes
	dc.b     $06,$07,$08,$08,$07,$09,$09,$0A,$08,$0A,$0B,$0C,$06,$07,$08,$08; Table data bytes
	dc.b     $07,$09,$09,$0A,$09,$0A,$0C,$0D,$06,$07,$07,$08,$07,$09,$09,$0C; Table data bytes
	dc.b     $09,$0A,$0C,$0E,$06,$07,$08,$09,$07,$09,$0A,$0C,$09,$0B,$0D,$0F; Table data bytes
	dc.b     $06,$07,$08,$08,$07,$0A,$0B,$0B,$09,$0C,$0D,$10,$06,$08,$08,$09; Table data bytes
	dc.b     $07,$0B,$0C,$0C,$09,$0D,$0E,$11,$00,$02,$06,$0E,$01,$02,$03,$04; Table data bytes
	dc.b     $01,$01,$01,$01,$02,$03,$03,$04,$04,$05,$07,$0E,$00,$02,$00,$02; Table data bytes
	dc.b     $00,$02,$00,$02,$00,$06,$00,$0A,$00,$0A,$00,$12,$00,$16,$00,$2A; Table data bytes
	dc.b     $00,$8A,$40,$12,$4B,$FA,$4F,$4E,$4A,$6D,$16,$28,$66,$08,$3B,$7C; Table data bytes
	dc.b     $00,$0A,$16,$28,$60,$02,$4E,$75,$48,$E7,$C0,$C2,$20,$2E,$00,$0E; Table data bytes
	dc.b     $90,$AE,$00,$22,$22,$2E,$00,$22,$92,$AE,$00,$26,$4D,$FA,$4F,$26; Table data bytes
	dc.b     $41,$EE,$19,$9D,$43,$FA,$2F,$EA,$61,$00,$16,$70,$61,$00,$05,$20; Table data bytes
	dc.b     $61,$00,$16,$68,$20,$01,$61,$00,$05,$16,$61,$00,$A3,$D4,$61,$00; Table data bytes
	dc.b     $9E,$90,$61,$00,$04,$4C,$4C,$DF,$43,$03,$4E,$75,$2A,$6E,$00,$22; Table data bytes
	dc.b     $28,$2E,$00,$0E,$20,$0D,$52,$80,$D0,$AE,$00,$1A,$B0,$84,$63,$12; Table data bytes
	dc.b     $20,$04,$22,$00,$92,$8D,$0C,$81,$00,$00,$00,$03,$64,$04,$70,$00; Table data bytes
	dc.b     $4E,$75,$2A,$00,$24,$4D,$52,$8A,$28,$4A,$7E,$01,$16,$15,$47,$EE; Table data bytes
	dc.b     $00,$34,$B6,$1A,$67,$44,$B6,$1A,$67,$40,$B6,$1A,$67,$3C,$B6,$1A; Table data bytes
	dc.b     $67,$38,$B6,$1A,$67,$34,$B6,$1A,$67,$30,$B6,$1A,$67,$2C,$B6,$1A; Table data bytes
	dc.b     $67,$28,$B6,$1A,$67,$24,$B6,$1A,$67,$20,$B6,$1A,$67,$1C,$B6,$1A; Table data bytes
	dc.b     $67,$18,$B6,$1A,$67,$14,$B6,$1A,$67,$10,$B6,$1A,$67,$0C,$B6,$1A; Table data bytes
	dc.b     $67,$08,$BA,$8A,$62,$BC,$70,$FF,$4E,$75,$BA,$8A,$63,$F8,$20,$4C; Table data bytes
	dc.b     $22,$4A,$B3,$08,$66,$AC,$B3,$08,$66,$14,$B3,$08,$66,$0A,$30,$3C; Table data bytes
	dc.b     $00,$FB,$B3,$08,$56,$C8,$FF,$FC,$B3,$C4,$63,$02,$22,$44,$2C,$09; Table data bytes
	dc.b     $9C,$8A,$BE,$46,$64,$8C,$3E,$06,$0C,$46,$00,$08,$62,$1E,$4A,$33; Table data bytes
	dc.b     $60,$FE,$66,$00,$FF,$7E,$17,$86,$60,$FE,$20,$0A,$90,$8D,$55,$80; Table data bytes
	dc.b     $32,$06,$E5,$49,$27,$80,$10,$00,$60,$00,$FF,$68,$17,$46,$00,$07; Table data bytes
	dc.b     $20,$0A,$90,$8D,$55,$80,$27,$40,$00,$24,$0C,$06,$00,$FF,$66,$00; Table data bytes
	dc.b     $FF,$52,$60,$92,$14,$2E,$00,$2C,$16,$2E,$00,$2D,$20,$6E,$00,$26; Table data bytes
	dc.b     $E2,$89,$E2,$12,$53,$03,$6A,$06,$76,$07,$10,$C2,$74,$00,$53,$00; Table data bytes
	dc.b     $66,$EE,$2D,$48,$00,$26,$1D,$43,$00,$2D,$1D,$42,$00,$2C,$4E,$75; Table data bytes
	dc.b     $02,$80,$00,$00,$00,$FF,$0C,$00,$00,$0D,$62,$2A,$0C,$00,$00,$05; Table data bytes
	dc.b     $62,$12,$41,$FA,$FE,$54,$1D,$70,$00,$FE,$00,$71,$1D,$70,$00,$02; Table data bytes
	dc.b     $00,$69,$60,$24,$5D,$00,$00,$00,$00,$F0,$1D,$40,$00,$71,$1D,$7C; Table data bytes
	dc.b     $00,$08,$00,$69,$60,$10,$1D,$7C,$00,$1F,$00,$70,$1D,$40,$00,$71; Table data bytes
	dc.b     $1D,$7C,$00,$0D,$00,$69,$70,$05,$55,$00,$24,$2E,$00,$30,$43,$FA; Table data bytes
	dc.b     $FE,$20,$41,$FA,$FE,$28,$D1,$C0,$D1,$C0,$B4,$50,$64,$10,$1C,$31; Table data bytes
	dc.b     $00,$00,$16,$06,$52,$03,$51,$EE,$00,$73,$78,$00,$60,$34,$B4,$68; Table data bytes
	dc.b     $00,$08,$64,$12,$1C,$31,$00,$04,$16,$06,$54,$03,$1D,$7C,$00,$02; Table data bytes
	dc.b     $00,$73,$38,$10,$60,$1C,$B4,$68,$00,$10,$65,$04,$70,$00,$4E,$75; Table data bytes
	dc.b     $1C,$31,$00,$08,$16,$06,$54,$03,$1D,$7C,$00,$03,$00,$73,$38,$28; Table data bytes
	dc.b     $00,$08,$1D,$43,$00,$6A,$94,$44,$7A,$10,$9A,$06,$EB,$6A,$D4,$42; Table data bytes
	dc.b     $E5,$EE,$00,$72,$53,$06,$66,$F6,$43,$EE,$00,$A4,$41,$EE,$00,$74; Table data bytes
	dc.b     $D0,$C0,$D0,$C0,$D0,$C0,$D0,$C0,$B2,$90,$64,$0E,$1C,$31,$00,$00; Table data bytes
	dc.b     $16,$06,$52,$03,$7E,$00,$78,$00,$60,$2C,$B2,$A8,$00,$10,$64,$0E; Table data bytes
	dc.b     $1C,$31,$00,$04,$16,$06,$54,$03,$7E,$02,$28,$10,$60,$18,$B2,$A8; Table data bytes
	dc.b     $00,$20,$65,$04,$70,$00,$4E,$75,$1C,$31,$00,$08,$16,$06,$54,$03; Table data bytes
	dc.b     $7E,$03,$28,$28,$00,$10,$1D,$43,$00,$68,$92,$84,$7A,$20,$9A,$06; Table data bytes
	dc.b     $EB,$A9,$D2,$81,$DF,$87,$53,$06,$66,$F8,$2D,$47,$00,$6C,$70,$FF; Table data bytes
	dc.b     "NuBn"                                ; String literal data
	dc.b     $00,$2A,$42,$2E,$00,$2E,$49,$EE,$00,$34,$4B,$EE,$00,$3C,$22,$1D; Table data bytes
	dc.b     $10,$1C,$67,$40,$61,$00,$FE,$C6,$67,$3A,$70,$00,$72,$00,$10,$2C; Table data bytes
	dc.b     $FF,$FF,$E7,$48,$D2,$2E,$00,$69,$D2,$2E,$00,$68,$D2,$2E,$00,$6A; Table data bytes
	dc.b     $90,$41,$6B,$20,$B0,$6E,$00,$2A,$65,$1A,$3D,$40,$00,$2A,$1D,$6C; Table data bytes
	dc.b     $FF,$FF,$00,$2E,$41,$EE,$00,$5C,$43,$EE,$00,$68,$72,$0C,$10,$D9; Table data bytes
	dc.b     $51,$C9,$FF,$FC,$20,$0C,$90,$8E,$0C,$40,$00,$3C,$66,$B0,$42,$A4; Table data bytes
	dc.b     $42,$A4,$4A,$6E,$00,$2E,$4E,$75,$53,$83,$66,$40,$20,$2E,$18,$20; Table data bytes
	dc.b     $08,$00,$00,$00,$66,$36,$20,$40,$24,$08,$26,$28,$00,$04,$61,$00; Table data bytes
	dc.b     $00,$2E,$4A,$80,$41,$EE,$19,$9D,$43,$FA,$2C,$AC,$67,$14,$43,$FA; Table data bytes
	dc.b     $2C,$BA,$61,$00,$13,$82,$20,$02,$22,$02,$D2,$83,$61,$00,$01,$B2; Table data bytes
	dc.b     $60,$04,$61,$00,$13,$72,$61,$00,$A0,$E4,$50,$C7,$4E,$75,$48,$E7; Table data bytes
	dc.b     "<8&H(H"                              ; String literal data
	dc.b     $0C,$98,$49,$4D,$50,$21,$66,$3E,$D9,$D8,$D7,$D8,$24,$4B,$21,$1A; Table data bytes
	dc.b     $21,$1A,$21,$1A,$24,$1A,$36,$1A,$6B,$02,$53,$8B,$4F,$EF,$FF,$E4; Table data bytes
	dc.b     $22,$4F,$70,$06,$22,$DA,$51,$C8,$FF,$FC,$22,$4F,$78,$00,$4A,$82; Table data bytes
	dc.b     $67,$06,$19,$23,$53,$82,$66,$FA,$B1,$CC,$65,$14,$4F,$EF,$00,$1C; Table data bytes
	dc.b     $70,$FF,$B1,$CB,$67,$02,$70,$00,$4C,$DF,$1C,$3C,$4A,$80,$4E,$75; Table data bytes
	dc.b     $D6,$03,$66,$04,$16,$23,$D7,$03,$64,$64,$D6,$03,$66,$04,$16,$23; Table data bytes
	dc.b     $D7,$03,$64,$54,$D6,$03,$66,$04,$16,$23,$D7,$03,$64,$44,$D6,$03; Table data bytes
	dc.b     $66,$04,$16,$23,$D7,$03,$64,$34,$D6,$03,$66,$04,$16,$23,$D7,$03; Table data bytes
	dc.b     $64,$06,$18,$23,$70,$03,$60,$3A,$D6,$03,$66,$04,$16,$23,$D7,$03; Table data bytes
	dc.b     $D9,$04,$D6,$03,$66,$04,$16,$23,$D7,$03,$D9,$04,$D6,$03,$66,$04; Table data bytes
	dc.b     $16,$23,$D7,$03,$D9,$04,$5C,$04,$70,$03,$60,$16,$78,$05,$70,$03; Table data bytes
	dc.b     $60,$10,$78,$04,$70,$02,$60,$0A,$78,$03,$70,$01,$60,$04,$78,$02; Table data bytes
	dc.b     $70,$00,$7A,$00,$32,$00,$D6,$03,$66,$04,$16,$23,$D7,$03,$64,$16; Table data bytes
	dc.b     $D6,$03,$66,$04,$16,$23,$D7,$03,$64,$08,$1A,$3B,$00,$6A,$50,$00; Table data bytes
	dc.b     $60,$04,$7A,$02,$58,$00,$10,$3B,$00,$62,$D6,$03,$66,$04,$16,$23; Table data bytes
	dc.b     $D7,$03,$D5,$42,$53,$00,$66,$F2,$D4,$45,$7A,$00,$24,$45,$30,$01; Table data bytes
	dc.b     $D6,$03,$66,$04,$16,$23,$D7,$03,$64,$1A,$D2,$41,$D6,$03,$66,$04; Table data bytes
	dc.b     $16,$23,$D7,$03,$64,$08,$34,$71,$10,$08,$50,$00,$60,$06,$34,$71; Table data bytes
	dc.b     $10,$00,$58,$00,$10,$31,$00,$10,$D6,$03,$66,$04,$16,$23,$D7,$03; Table data bytes
	dc.b     $DB,$85,$53,$00,$66,$F2,$52,$4A,$D5,$C5,$D5,$CC,$19,$22,$53,$04; Table data bytes
	dc.b     $66,$FA,$60,$00,$FE,$EA,$06,$0A,$0A,$12,$01,$01,$01,$01,$02,$03; Table data bytes
	dc.b     $03,$04,$04,$05,$07,$0E               ; Table data bytes
; ============================================================================
; Function: WaitInputOrButton
; Purpose : Waits for user input or POTGOR joystick/mouse button press.
; ============================================================================
WaitInputOrButton:
	cmpi.b   #$1b,Var_LockFlag(a6)                       ; Compare monitor lock status against constant $1b
	beq.b    WaitInputOrButton_Loc_7560                  ; Branch to WaitInputOrButton_Loc_7560 if zero / equal
	btst     #$a,$dff016.l                               ; Test bit #$a of $dff016.l
	beq.b    WaitInputOrButton                           ; Branch to WaitInputOrButton if zero / equal
	rts                                                  ; Return from subroutine
WaitInputOrButton_Loc_7560:
	clr.w    Var_BufferLength(a6)                        ; Clear / reset keyboard input buffer character count
	rts                                                  ; Return from subroutine
WaitInputOrButton_Loc_7566:
	cmpi.b   #$1b,Var_LockFlag(a6)                       ; Compare monitor lock status against constant $1b
	beq.b    WaitInputOrButton_Loc_7560                  ; Branch to WaitInputOrButton_Loc_7560 if zero / equal
	btst     #$a,$dff016.l                               ; Test bit #$a of $dff016.l
	bne.b    WaitInputOrButton_Loc_7566                  ; Branch to WaitInputOrButton_Loc_7566 if non-zero / not equal
	move.w   #$5,$1628(a6)                               ; Move constant $5 to $1628(a6)
WaitInputOrButton_Loc_757E:
	tst.w    $1628(a6)                             ; Check if $1628 is set / active
	bne.b    WaitInputOrButton_Loc_757E                  ; Branch to WaitInputOrButton_Loc_757E if non-zero / not equal
WaitInputOrButton_Loc_7584:
	btst     #$a,$dff016.l                               ; Test bit #$a of $dff016.l
	beq.b    WaitInputOrButton_Loc_7584                  ; Branch to WaitInputOrButton_Loc_7584 if zero / equal
	rts                                                  ; Return from subroutine
; ============================================================================
; Function: FormatAddressRange8
; Purpose : Formats an address range as two 8-digit hex values separated by a dash.
; ============================================================================
FormatAddressRange8:
	bsr.b    PrintHex8                                   ; Call subroutine to PrintHex8
	move.b   #$2d,(a0)+                                  ; Move constant $2d to (a0)+
	move.l   d1,d0                                       ; Move register d1 to register d0
	bra.b    PrintHex8                                   ; Unconditional branch to PrintHex8
; ============================================================================
; Function: FormatAddressRange6
; Purpose : Formats an address range as two 6-digit hex values separated by a dash.
; ============================================================================
FormatAddressRange6:
	bsr.b    PrintHex6                                   ; Call subroutine to PrintHex6
	move.b   #$2d,(a0)+                                  ; Move constant $2d to (a0)+
	move.l   d1,d0                                       ; Move register d1 to register d0
	bra.b    PrintHex6                                   ; Unconditional branch to PrintHex6
	move.b   #$24,(a0)+                                  ; Move constant $24 to (a0)+
	movem.l  d0-d2,-(a7)                                 ; Move multiple registers d0-d2 to -(a7)
	moveq    #$0,d2                                      ; Initialize register d2 to 0
	ror.l    #$4,d0
	bra.b    FormatHexLoop                               ; Unconditional branch to FormatHexLoop
PrintHex2_Entry:
	move.b   #$24,(a0)+                                  ; Move constant $24 to (a0)+
; ============================================================================
; Function: FormatHex2
; Purpose : Formats a byte as a 2-digit hex string into (a0)+.
; ============================================================================
FormatHex2:
	movem.l  d0-d2,-(a7)                                 ; Move multiple registers d0-d2 to -(a7)
	moveq    #$1,d2                                      ; Initialize register d2 to 1
	ror.l    #$8,d0
	bra.b    FormatHexLoop                               ; Unconditional branch to FormatHexLoop
PrintHex4_Entry:
	move.b   #$24,(a0)+                                  ; Move constant $24 to (a0)+
; ============================================================================
; Function: FormatHex4
; Purpose : Formats a word as a 4-digit hex string into (a0)+.
; ============================================================================
FormatHex4:
	movem.l  d0-d2,-(a7)                                 ; Move multiple registers d0-d2 to -(a7)
	moveq    #$3,d2                                      ; Initialize register d2 to constant $3
	swap     d0
	bra.b    FormatHexLoop                               ; Unconditional branch to FormatHexLoop
; ============================================================================
; Function: PrintHex6
; Purpose : Formats a 3-byte value as a 6-digit hex string with a dollar sign prefix into (a0)+.
; ============================================================================
PrintHex6:
	move.b   #$24,(a0)+                                  ; Move constant $24 to (a0)+
	movem.l  d0-d2,-(a7)                                 ; Move multiple registers d0-d2 to -(a7)
	moveq    #$5,d2                                      ; Initialize register d2 to constant $5
	lsl.l    #$8,d0
	bra.b    FormatHexLoop                               ; Unconditional branch to FormatHexLoop
; ============================================================================
; Function: PrintHex8
; Purpose : Formats a longword as a 8-digit hex string with a dollar sign prefix into (a0)+.
; ============================================================================
PrintHex8:
	move.b   #$24,(a0)+                                  ; Move constant $24 to (a0)+
; ============================================================================
; Function: FormatHex8
; Purpose : Formats a longword as a 8-digit hex string into (a0)+.
; ============================================================================
FormatHex8:
	movem.l  d0-d2,-(a7)                                 ; Move multiple registers d0-d2 to -(a7)
	moveq    #$7,d2                                      ; Initialize register d2 to constant $7
; ============================================================================
; Function: FormatHexLoop
; Purpose : Core loop to translate a numeric value into hex ASCII representation.
; ============================================================================
FormatHexLoop:
	rol.l    #$4,d0
	moveq    #$f,d1                                      ; Initialize register d1 to constant $f
	and.w    d0,d1                                       ; Logical AND register d1 with register d0
	move.b   HexCharTable(pc,d1.w),(a0)+                 ; Move HexCharTable(pc,d1.w) to (a0)+
	dbra     d2,FormatHexLoop                            ; Decrement loop counter d2 and loop back to FormatHexLoop if not exhausted
	movem.l  (a7)+,d0-d2                                 ; Move multiple registers (a7)+ to d0-d2
	rts                                                  ; Return from subroutine
HexCharTable:
	dc.b     "0123456789abcdef"                    ; String literal data
; ============================================================================
; ============ FormatHexCompact
; Purpose: Formats a 32-bit value (in d0) as a compact hexadecimal string into the buffer at (a0)+.
;          Leading zeros are omitted (the value 0 prints as a single "0"), and a '$' prefix is added
;          for any value greater than 9. This keeps disasm lines, register views, immediate operands,
;          and memory dumps short and readable. It is the "variable width" companion to the fixed-width
;          FormatHex8 / FormatHex4 routines and is heavily used by the table-driven 68k/65C816
;          disassembler (Disasm_FormatOneLine and its formatter subs) as well as command output helpers.
; Inputs:  d0.l = value to print; a0 = current write pointer in output buffer (usually inside
;          Var_DisasmBuffer or a console line in Var_ConsoleBuffer); a6 = monitor context (used
;          only for pc-relative access to the shared HexCharTable).
; Outputs: ASCII hex digits (and optional '$') written at successive (a0)+ positions; a0 advanced
;          past the last emitted character; no leading zeros ever appear.
; Notes:   d3 is used as a "have we started emitting digits" flag. The initial cmp against #9 decides
;          whether the $ prefix is needed. The loop always walks all 8 nibbles (d2=7..0) but the zero-
;          suppression logic (tst.b d3 + the d2==0 special case) skips until the first non-zero nibble.
;          Shares the 16-byte HexCharTable with all other hex formatters in the monitor.
;          Called from many places inside Data_DisasmFormatterSubs for immediates, displacements,
;          addresses, etc.
; ============================================================================
FormatHexCompact:
	movem.l  d0-d3,-(a7)                                 ; Move multiple registers d0-d3 to -(a7)
	moveq    #$9,d2                                      ; Initialize register d2 to constant $9
	cmp.l    d2,d0                                       ; Compare register d0 against register d2
	bls.b    FormatHexCompact_EmitDollar           ; No $ prefix needed for 0..9 (they look the same in hex or decimal in this context)
	move.b   #$24,(a0)+                                  ; Move constant $24 to (a0)+
FormatHexCompact_EmitDollar:
	sf.b     d3
	moveq    #$7,d2                                      ; Initialize register d2 to constant $7
FormatHexCompact_Loop:
	rol.l    #$4,d0
	moveq    #$f,d1                                      ; Initialize register d1 to constant $f
	and.w    d0,d1                                       ; Logical AND register d1 with register d0
	bne.b    FormatHexCompact_Write                      ; Branch to FormatHexCompact_Write if non-zero / not equal
	tst.w    d2                                          ; Test status of register d2 (for zero or negative)
	beq.b    FormatHexCompact_Write                      ; Branch to FormatHexCompact_Write if zero / equal
	tst.b    d3                                          ; Test status of register d3 (for zero or negative)
	beq.b    FormatHexCompact_SkipZero                   ; Branch to FormatHexCompact_SkipZero if zero / equal
FormatHexCompact_Write:
	st.b     d3
	move.b   HexCharTable(pc,d1.w),(a0)+           ; Look up '0'-'9' or 'a'-'f' in the shared table and append the character to the output line
FormatHexCompact_SkipZero:
	dbra     d2,FormatHexCompact_Loop                    ; Decrement loop counter d2 and loop back to FormatHexCompact_Loop if not exhausted
	movem.l  (a7)+,d0-d3                                 ; Move multiple registers (a7)+ to d0-d3
FormatHexCompact_Exit:
	rts                                                  ; Return from subroutine
; ============ FormatDecimal3Digit
; Purpose: Formats a small positive value (0-999) as a fixed 3-digit decimal ASCII string into (a0)+.
;          Always emits exactly three digits (with leading zeros if necessary). Used for track numbers,
;          sector counts, menu indices, small counters etc. in disk tools, disassembly output and UI.
;          Shares the tens+units code with FormatDecimal2Digit for code size.
; Inputs:  d0.w = value (0..999); a0 = write pointer in output buffer (Var_DisasmBuffer or console line).
; Outputs: Three ASCII digits '0'-'9' written at (a0)+ ; a0 advanced by 3; d0 preserved on stack.
; Notes:   Re-uses the hardware constant BLTAMOD ($064 = 100 decimal) as the divisor for the tens place.
;          The final swap + bra hands the remainder (tens+units) to the common body in the 2-digit formatter.
;          Part of the small family of decimal printers called from the 68k disasm formatter and disk MFM tools.
; ============================================================================
FormatDecimal3Digit:
	move.l   d0,-(a7)                                    ; Move register d0 to -(a7)
	ext.l    d0
	divu.w   #$3e8,d0                              ; Divide by 1000 → quotient in low word of d0 is the hundreds digit (0-9)
	addi.b   #$30,d0                                     ; Add constant $30 to register d0
	move.b   d0,(a0)+                                    ; Move register d0 to (a0)+
	clr.w    d0                                          ; Clear / reset register d0
	swap     d0
	divu.w   #BLTAMOD,d0                           ; Divide remainder by 100 (BLTAMOD = $064) → quotient = tens digit (0-9)
	addi.b   #$30,d0                                     ; Add constant $30 to register d0
	move.b   d0,(a0)+                                    ; Move register d0 to (a0)+
	swap     d0
	bra.b    FormatDecimal_EmitTensAndUnits              ; Unconditional branch to FormatDecimal_EmitTensAndUnits
; ============================================================================
; Function: FormatDecimal2Digit
; Purpose : Formats a value as a 2-digit decimal string into (a0)+.
; ============================================================================
FormatDecimal2Digit:
	move.l   d0,-(a7)                                    ; Move register d0 to -(a7)
FormatDecimal_EmitTensAndUnits:
	cmpi.b   #$63,d0                                     ; Compare register d0 against constant $63
	bls.b    FormatDecimal_EmitTensAndUnits_Loc_7666                              ; Branch to FormatDecimal_EmitTensAndUnits_Loc_7666 if lower or same.
	moveq    #$63,d0                                     ; Initialize register d0 to constant $63
FormatDecimal_EmitTensAndUnits_Loc_7666:
	ext.w    d0
	ext.l    d0
	divu.w   #$a,d0
	bra.b    FormatDecimal1Digit_Write                   ; Unconditional branch to FormatDecimal1Digit_Write
; ============================================================================
; Function: FormatDecimal1Digit
; Purpose : Formats a value as a 1-digit decimal string into (a0)+.
; ============================================================================
FormatDecimal1Digit:
	move.l   d0,-(a7)                                    ; Move register d0 to -(a7)
	moveq    #$f,d0                                      ; Initialize register d0 to constant $f
	and.l    (a7),d0                                     ; Logical AND register d0 with (a7)
	divu.w   #$a,d0
	beq.b    FormatDecimal1Digit_Write_Loc_7682          ; Branch to FormatDecimal1Digit_Write_Loc_7682 if zero / equal
FormatDecimal1Digit_Write:
	addi.b   #$30,d0                                     ; Add constant $30 to register d0
	move.b   d0,(a0)+                                    ; Move register d0 to (a0)+
FormatDecimal1Digit_Write_Loc_7682:
	swap     d0
	addi.b   #$30,d0                                     ; Add constant $30 to register d0
	move.b   d0,(a0)+                                    ; Move register d0 to (a0)+
	move.l   (a7)+,d0                                    ; Move (a7)+ to register d0
FormatDecimal1Digit_Exit:
	rts                                                  ; Return from subroutine
; ============================================================================
; Function: FormatDecimal32Bit
; Purpose : Formats a 32-bit longword as a decimal string into (a0)+ using a division table.
; ============================================================================
FormatDecimal32Bit:
	movem.l  d0-d4/a1,-(a7)                              ; Move multiple registers d0-d4/a1 to -(a7)
	lea.l    Table_PowersOf10(pc),a1                     ; Load address of Table_PowersOf10(pc) into pointer a1
	moveq    #$9,d1                                      ; Initialize register d1 to constant $9
	sf.b     d4
FormatDecimal32Bit_Loop:
	moveq    #$30,d2                                     ; Initialize register d2 to constant $30
	move.l   (a1)+,d3                                    ; Move (a1)+ to register d3
FormatDecimal32Bit_SubLoop:
	cmp.l    d3,d0                                       ; Compare register d0 against register d3
	bcs.b    FormatDecimal32Bit_SubLoop_Loc_76AA         ; Branch to FormatDecimal32Bit_SubLoop_Loc_76AA if carry set (less than)
	st.b     d4
	sub.l    d3,d0                                       ; Subtract register d3 from register d0
	addq.b   #$1,d2                                      ; Add 1 to register d2
	bra.b    FormatDecimal32Bit_SubLoop                  ; Unconditional branch to FormatDecimal32Bit_SubLoop
FormatDecimal32Bit_SubLoop_Loc_76AA:
	tst.w    d1                                          ; Test status of register d1 (for zero or negative)
	beq.b    FormatDecimal32Bit_SubLoop_Loc_76B2         ; Branch to FormatDecimal32Bit_SubLoop_Loc_76B2 if zero / equal
	tst.b    d4                                          ; Test status of register d4 (for zero or negative)
	beq.b    FormatDecimal32Bit_SubLoop_Loc_76B4         ; Branch to FormatDecimal32Bit_SubLoop_Loc_76B4 if zero / equal
FormatDecimal32Bit_SubLoop_Loc_76B2:
	move.b   d2,(a0)+                                    ; Move register d2 to (a0)+
FormatDecimal32Bit_SubLoop_Loc_76B4:
	dbra     d1,FormatDecimal32Bit_Loop                  ; Decrement loop counter d1 and loop back to FormatDecimal32Bit_Loop if not exhausted
	movem.l  (a7)+,d0-d4/a1                              ; Move multiple registers (a7)+ to d0-d4/a1
FormatDecimal32Bit_Exit:
	rts                                                  ; Return from subroutine
Table_PowersOf10:
	dc.l     1000000000     ; 1,000,000,000
	dc.l     100000000      ; 100,000,000
	dc.l     10000000       ; 10,000,000
	dc.l     1000000        ; 1,000,000
	dc.l     100000         ; 100,000
	dc.l     10000          ; 10,000
	dc.l     1000           ; 1,000
	dc.l     100            ; 100
	dc.l     10             ; 10
	dc.l     1              ; 1
; ============================================================================
; Function: FormatDecimal
; Purpose : Formats a 16-bit word value as a decimal string and writes it to (a0)+.
; ============================================================================
FormatDecimal:
	movem.l  d0-d4,-(a7)                                 ; Move multiple registers d0-d4 to -(a7)
	sf.b     d4
	bsr.b    FormatDecimal_Body                          ; Call subroutine to FormatDecimal_Body
	bsr.b    FormatDecimal_Body                          ; Call subroutine to FormatDecimal_Body
	bsr.b    FormatDecimal_Body                          ; Call subroutine to FormatDecimal_Body
	st.b     d4
	bsr.b    FormatDecimal_Body                          ; Call subroutine to FormatDecimal_Body
	movem.l  (a7)+,d0-d4                                 ; Move multiple registers (a7)+ to d0-d4
	rts                                                  ; Return from subroutine
FormatDecimal_Body:
	rol.l    #$8,d0
	move.b   d0,d3                                       ; Move register d0 to register d3
	bne.b    FormatDecimal_Body_Loc_7706                 ; Branch to FormatDecimal_Body_Loc_7706 if non-zero / not equal
	tst.b    d4                                          ; Test status of register d4 (for zero or negative)
	beq.b    FormatDecimal_Exit                          ; Branch to FormatDecimal_Exit if zero / equal
FormatDecimal_Body_Loc_7706:
	st.b     d4
	moveq    #$7,d2                                      ; Initialize register d2 to constant $7
FormatDecimal_Loop:
	moveq    #$30,d1                                     ; Initialize register d1 to constant $30
	add.b    d3,d3                                       ; Add register d3 to register d3
	bcc.b    FormatDecimal_Loop_Loc_7712                 ; Branch to FormatDecimal_Loop_Loc_7712 if carry clear (greater or equal)
	moveq    #$31,d1                                     ; Initialize register d1 to constant $31
FormatDecimal_Loop_Loc_7712:
	move.b   d1,(a0)+                                    ; Move register d1 to (a0)+
	dbra     d2,FormatDecimal_Loop                       ; Decrement loop counter d2 and loop back to FormatDecimal_Loop if not exhausted
	move.b   #$20,(a0)+                                  ; Move constant $20 to (a0)+
FormatDecimal_Exit:
	rts                                                  ; Return from subroutine
	cmpi.b   #$24,(a3)                                   ; Compare (a3) against constant $24
	bne.b    ParseHexNumber                              ; Branch to ParseHexNumber if non-zero / not equal
	addq.w   #$1,a3                                      ; Add 1 to pointer a3
; ============================================================================
; Function: ParseHexNumber
; Purpose : Parses a hexadecimal number from the string at (a3) into d0.
; ============================================================================
ParseHexNumber:
	moveq    #$7,d2                                      ; Initialize register d2 to constant $7
	bra.b    ParseHexNumber_Start                        ; Unconditional branch to ParseHexNumber_Start
	cmpi.b   #$24,(a3)                                   ; Compare (a3) against constant $24
	bne.b    ParseHexNumber_Loc_7732                     ; Branch to ParseHexNumber_Loc_7732 if non-zero / not equal
	addq.w   #$1,a3                                      ; Add 1 to pointer a3
ParseHexNumber_Loc_7732:
	moveq    #$3,d2                                      ; Initialize register d2 to constant $3
	bra.b    ParseHexNumber_Start                        ; Unconditional branch to ParseHexNumber_Start
	cmpi.b   #$24,(a3)                                   ; Compare (a3) against constant $24
	bne.b    ParseHexNumber_Loc_773E                     ; Branch to ParseHexNumber_Loc_773E if non-zero / not equal
	addq.w   #$1,a3                                      ; Add 1 to pointer a3
ParseHexNumber_Loc_773E:
	moveq    #$1,d2                                      ; Initialize register d2 to 1
ParseHexNumber_Start:
	moveq    #$0,d0                                      ; Initialize register d0 to 0
ParseHexNumber_Loop:
	move.b   (a3),d1                                     ; Move (a3) to register d1
	cmpi.b   #BLTDMOD,d1                                 ; Compare register d1 against constant BLTDMOD
	bhi.b    ParseHexNumber_Exit                   ; Branch to ParseHexNumber_Exit if higher.
	subi.b   #$30,d1                                     ; Subtract constant $30 from register d1
	bcs.b    ParseHexNumber_Exit                         ; Branch to ParseHexNumber_Exit if carry set (less than)
	cmpi.b   #$9,d1                                      ; Compare register d1 against constant $9
	bls.b    ParseHexNumber_Loop_Loc_7760                              ; Branch to ParseHexNumber_Loop_Loc_7760 if lower or same.
	cmpi.b   #$31,d1                                     ; Compare register d1 against constant $31
	bcs.b    ParseHexNumber_Exit                         ; Branch to ParseHexNumber_Exit if carry set (less than)
	subi.b   #$27,d1                                     ; Subtract constant $27 from register d1
ParseHexNumber_Loop_Loc_7760:
	lsl.l    #$4,d0
	or.b     d1,d0                                       ; Logical OR register d0 with register d1
	addq.w   #$1,a3                                      ; Add 1 to pointer a3
	dbra     d2,ParseHexNumber_Loop                      ; Decrement loop counter d2 and loop back to ParseHexNumber_Loop if not exhausted
ParseHexNumber_Exit:
	tst.l    d0                                          ; Test status of register d0 (for zero or negative)
	rts                                                  ; Return from subroutine
; ============================================================================
; Function: ParseDecimal2Digit
; Purpose : Parses a 2-digit decimal number from the string at (a3) into d0.
; ============================================================================
ParseDecimal2Digit:
	moveq    #$0,d0                                      ; Initialize register d0 to 0
	move.b   (a3),d1                                     ; Move (a3) to register d1
	subi.b   #$30,d1                                     ; Subtract constant $30 from register d1
	bcs.b    ParseDecimal2Digit_Loop_Loc_7798            ; Branch to ParseDecimal2Digit_Loop_Loc_7798 if carry set (less than)
	cmpi.b   #$9,d1                                      ; Compare register d1 against constant $9
	bhi.b    ParseDecimal2Digit_Loop_Loc_7798                              ; Branch to ParseDecimal2Digit_Loop_Loc_7798 if higher.
ParseDecimal2Digit_Loop:
	addq.w   #$1,a3                                      ; Add 1 to pointer a3
	move.b   d1,d0                                       ; Move register d1 to register d0
	move.b   (a3),d1                                     ; Move (a3) to register d1
	subi.b   #$30,d1                                     ; Subtract constant $30 from register d1
	bcs.b    ParseDecimal2Digit_Loop_Loc_7798            ; Branch to ParseDecimal2Digit_Loop_Loc_7798 if carry set (less than)
	cmpi.b   #$9,d1                                      ; Compare register d1 against constant $9
	bhi.b    ParseDecimal2Digit_Loop_Loc_7798                              ; Branch to ParseDecimal2Digit_Loop_Loc_7798 if higher.
	addq.w   #$1,a3                                      ; Add 1 to pointer a3
	mulu.w   #$a,d0
	add.b    d1,d0                                       ; Add register d1 to register d0
ParseDecimal2Digit_Loop_Loc_7798:
	tst.b    d0                                          ; Test status of register d0 (for zero or negative)
ParseDecimal2Digit_Exit:
	rts                                                  ; Return from subroutine
; ============================================================================
; Function: ParseDecimalNumber
; Purpose : Parses a decimal number from the string at (a3) into d0.
; ============================================================================
ParseDecimalNumber:
	moveq    #$0,d0                                      ; Initialize register d0 to 0
	moveq    #$0,d1                                      ; Initialize register d1 to 0
	moveq    #$9,d2                                      ; Initialize register d2 to constant $9
ParseDecimalNumber_Loop:
	move.b   (a3),d1                                     ; Move (a3) to register d1
	subi.b   #$30,d1                                     ; Subtract constant $30 from register d1
	bcs.b    ParseDecimalNumber_Exit                     ; Branch to ParseDecimalNumber_Exit if carry set (less than)
	cmpi.b   #$9,d1                                      ; Compare register d1 against constant $9
	bhi.b    ParseDecimalNumber_Exit               ; Branch to ParseDecimalNumber_Exit if higher.
	addq.w   #$1,a3                                      ; Add 1 to pointer a3
	add.l    d0,d0                                       ; Add register d0 to register d0
	move.l   d0,-(a7)                                    ; Move register d0 to -(a7)
	lsl.l    #$2,d0
	add.l    (a7)+,d0                                    ; Add (a7)+ to register d0
	add.l    d1,d0                                       ; Add register d1 to register d0
	dbra     d2,ParseDecimalNumber_Loop                  ; Decrement loop counter d2 and loop back to ParseDecimalNumber_Loop if not exhausted
ParseDecimalNumber_Exit:
	rts                                                  ; Return from subroutine
Disasm_FormatOneLine:
	movem.l  d0-d2/a0-a1/a4,-(a7)                        ; Move multiple registers d0-d2/a0-a1/a4 to -(a7)
	move.l   a5,d2                                       ; Move pointer a5 to register d2
	bsr.w    ClearDisasmBuffer                           ; Call subroutine to ClearDisasmBuffer
	lea.l    Var_DisasmBuffer(a6),a0                     ; Load address of disassembler output text buffer into pointer a0
	move.w   #$3e5f,(a0)+                                ; Move constant $3e5f to (a0)+
	move.l   a5,d0                                       ; Move pointer a5 to register d0
	bsr.w    FormatHex8                                  ; Call subroutine to FormatHex8
	moveq    #-33,d0                                     ; Initialize register d0 to constant -33
	and.b    (a5),d0                                     ; Logical AND register d0 with (a5)
	cmpi.b   #$c2,d0                                     ; Compare register d0 against constant $c2
	bne.b    Disasm_LookupMnemonicAndDispatch            ; Branch to Disasm_LookupMnemonicAndDispatch if non-zero / not equal
	btst     #$5,(a5)                                    ; Test bit #$5 of (a5)
	sne.b    d1
	moveq    #$30,d0                                     ; Initialize register d0 to constant $30
	and.b    $1(a5),d0                             ; Check next byte of the special item
	beq.b    Disasm_LookupMnemonicAndDispatch            ; Branch to Disasm_LookupMnemonicAndDispatch if zero / equal
	move.b   $1(a5),d0                                   ; Move $1(a5) to register d0
	lea.l    Var_DisasmBuffer+40(a6),a0                  ; Load address of disassembler output text buffer into pointer a0
	move.b   #$3b,(a0)+                                  ; Move constant $3b to (a0)+
	btst     #$5,d0                                      ; Test bit #$5 of register d0
	beq.b    Disasm_FormatSpecial_YCoord                 ; Branch to Disasm_FormatSpecial_YCoord if zero / equal
	move.b   #$61,(a0)+                                  ; Move constant $61 to (a0)+
	move.b   #$3a,(a0)+                                  ; Move constant $3a to (a0)+
	tst.b    Var_HexFormatFlag(a6)                 ; Check if Var_HexFormatFlag is set / active
	beq.b    Disasm_FormatSpecial_YCoord                 ; Branch to Disasm_FormatSpecial_YCoord if zero / equal
	move.b   d1,Var_HexChar_Y(a6)                        ; Store register d1 into hex layout row position
Disasm_FormatSpecial_YCoord:
	btst     #$4,d0                                      ; Test bit #$4 of register d0
	beq.b    Disasm_FormatSpecialCoords_Done             ; Branch to Disasm_FormatSpecialCoords_Done if zero / equal
	btst     #$5,d0                                      ; Test bit #$5 of register d0
	beq.b    Disasm_FormatSpecial_XCoord                 ; Branch to Disasm_FormatSpecial_XCoord if zero / equal
	move.b   #$2c,-$1(a0)                                ; Move constant $2c to -$1(a0)
Disasm_FormatSpecial_XCoord:
	move.b   #$78,(a0)+                                  ; Move constant $78 to (a0)+
	move.b   #$2c,(a0)+                                  ; Move constant $2c to (a0)+
	move.b   #$79,(a0)+                                  ; Move constant $79 to (a0)+
	move.b   #$3a,(a0)+                                  ; Move constant $3a to (a0)+
	tst.b    Var_HexFormatFlag(a6)                       ; Test status of hexadecimal display format flag (for zero or negative)
	beq.b    Disasm_FormatSpecialCoords_Done             ; Branch to Disasm_FormatSpecialCoords_Done if zero / equal
	move.b   d1,Var_HexChar_X(a6)                        ; Store register d1 into hex layout column position
Disasm_FormatSpecialCoords_Done:
	lsl.b    #$3,d1
	moveq    #$10,d0                                     ; Initialize register d0 to constant $10
	add.b    d1,d0                                       ; Add register d1 to register d0
	bsr.w    FormatDecimal32Bit                          ; Call subroutine to FormatDecimal32Bit
	move.b   #BLTBMOD,(a0)+                              ; Move constant BLTBMOD to (a0)+
	move.b   #$69,(a0)+                                  ; Move constant $69 to (a0)+
	move.b   #BLTADAT,(a0)                               ; Move constant BLTADAT to (a0)
Disasm_LookupMnemonicAndDispatch:
	lea.l    Var_DisasmBuffer+25(a6),a0                  ; Load address of disassembler output text buffer into pointer a0
	moveq    #$0,d0                                      ; Initialize register d0 to 0
	move.b   (a5)+,d0                                    ; Move (a5)+ to register d0
	add.w    d0,d0                                 ; *2 for word lookup
	lea.l    Disasm_OpcodeTypeTable(pc),a4                            ; Load address of Disasm_OpcodeTypeTable(pc) into pointer a4
	adda.w   d0,a4                                       ; Add register d0 to pointer a4
	moveq    #$0,d1                                      ; Initialize register d1 to 0
	move.b   (a4)+,d1                                    ; Move (a4)+ to register d1
	mulu.w   #$3,d1                                ; *3 because the string pool stores 3-char entries
	moveq    #$0,d0                                      ; Initialize register d0 to 0
	move.b   (a4)+,d0                                    ; Move (a4)+ to register d0
	lea.l    Disasm_MnemonicPool(pc),a4                            ; Load address of Disasm_MnemonicPool(pc) into pointer a4
	adda.w   d1,a4                                       ; Add register d1 to pointer a4
	move.b   (a4)+,(a0)+                                 ; Move (a4)+ to (a0)+
	move.b   (a4)+,(a0)+                                 ; Move (a4)+ to (a0)+
	move.b   (a4)+,(a0)                                  ; Move (a4)+ to (a0)
	addq.w   #$2,a0                                      ; Add constant $2 to pointer a0
	add.w    d0,d0                                       ; Add register d0 to register d0
	move.w   Data_DisasmFormatterOffsets(pc,d0.w),d0  ; Get byte offset from base to the chosen operand formatter sub
	jsr      Data_DisasmFormatterSubs(pc,d0.w)           ; Call subroutine Data_DisasmFormatterSubs(pc,d0.w)
	; Now append the raw bytes of the item after a "; " separator so the user sees the exact memory contents
	lea.l    Var_DisasmBuffer+12(a6),a0                  ; Load address of disassembler output text buffer into pointer a0
	lea.l    Var_DisasmBuffer+70(a6),a1                  ; Load address of disassembler output text buffer into pointer a1
	move.b   #$3b,(a1)+                                  ; Move constant $3b to (a1)+
	movea.l  d2,a4                                       ; Move register d2 to pointer a4
	sub.l    a5,d2                                       ; Subtract pointer a5 from register d2
Disasm_RawBytesDumpLoop:
	move.b   (a4)+,d0                                    ; Move (a4)+ to register d0
	bsr.w    FormatHex2                                  ; Call subroutine to FormatHex2
	moveq    #BLTCMOD,d1                                 ; Initialize register d1 to constant BLTCMOD
	and.b    d0,d1                                       ; Logical AND register d1 with register d0
	bne.b    Disasm_RawBytesDump_UseDot                  ; Branch to Disasm_RawBytesDump_UseDot if non-zero / not equal
	moveq    #$2e,d0                                     ; Initialize register d0 to constant $2e
Disasm_RawBytesDump_UseDot:
	move.b   d0,(a1)+                                    ; Move register d0 to (a1)+
	addq.w   #$1,a0                                      ; Add 1 to pointer a0
	addq.b   #$1,d2                                      ; Add 1 to register d2
	bne.b    Disasm_RawBytesDumpLoop                     ; Branch to Disasm_RawBytesDumpLoop if non-zero / not equal
	movem.l  (a7)+,d0-d2/a0-a1/a4                        ; Move multiple registers (a7)+ to d0-d2/a0-a1/a4
	rts                                                  ; Return from subroutine

; Offsets (in bytes) from Data_DisasmFormatterSubs to the start of the formatter sub for each type byte.
; Indexed by (type*2). The subs themselves live in the following block (kept as dc.b for exact binary match).
Data_DisasmFormatterOffsets:
	dc.b     $00,$5C,$00,$24,$00,$2E,$00,$50,$00,$58,$00,$5E,$00,$74,$00,$80; Table data bytes
	dc.b     $00,$84,$00,$90,$00,$94,$00,$A2,$00,$AA,$00,$D4,$00,$C8,$00,$C4; Table data bytes
	dc.b     $00,$6C,$00,$D6,$00,$E4,$00,$04,$00,$00,$00,$B4,$00,$98,$00,$1E; Table data bytes
	dc.b     $00,$18                               ; Table data bytes

; ============ 68000 Disassembler Core (inside Data_DisasmFormatterSubs)
; The 68000-specific part of BeerMon's disassembler is entirely table-driven and lives in the
; Data_DisasmFormatterSubs block (plus the two lookup tables Disasm_OpcodeTypeTable and Disasm_MnemonicPool).
;
; How the 68000 path works (in context of the monitor):
; 1. Disasm_FormatOneLine (already documented) has already printed the address and decided this is
;    not a special "coord/blit" item.
; 2. It takes the first byte of the memory item as "type" (for real 68k instructions this is usually
;    the high byte of the opcode).
; 3. Uses Disasm_OpcodeTypeTable[type] to get char-count + index into the 3-char mnemonic pool (Disasm_MnemonicPool).
;    This gives the base mnemonic ("move", "add", "bcc", "dc." etc.).
; 4. Uses Data_DisasmFormatterOffsets[type] to get a byte offset into this subs block.
; 5. Jumps to the selected small formatter sub. For standard 68000 instructions the sub does:
;    - Extract size field (usually bits 6-7 of opcode).
;    - Decode effective address: mode (bits 3-5) and register (bits 0-2) of source and/or dest.
;    - For each EA, call a common EA decoder (there are several small routines in the block for
;      the 12 addressing modes of the 68000: Dn, An, (An), (An)+, -(An), d16(An), d8(An,Xi),
;      xxx.W, xxx.L, d16(PC), d8(PC,Xi), #imm).
;    - Append the operands using FormatHex*/FormatDecimal helpers (e.g. "$1234", "(a0)", "#$2a",
;      "label(pc)", "d0-d3/a0-a2").
;    - For branches/displacements compute target and may look up symbols (though BeerMon mostly
;      just prints hex).
; 6. After the sub returns, the main routine always appends "; " + the raw bytes.
;
Data_DisasmFormatterSubs:
; --- 68000 Default Instruction Formatter (first sub, offset $0000 in this block) ---
; This is the entry point used by many standard 68000 opcodes (type 0 in the table).
; It decodes the full instruction word, determines size, source/dest EA, calls the common
; 68000 EA mode handlers (the routines that follow in the block), and emits the operands.
	dc.b     $48,$7A,$00,$84,$70,$00,$10,$2D,$00,$02,$E1,$48,$10,$2D,$00,$01; Table data bytes  ; start of 68000 default formatter (movem + setup for EA decode)
; The bytes immediately following contain the common 68000 Effective Address decoder used by
; almost all 68000 instruction formatters. It takes the mode/reg fields from the instruction
; word (in registers after the setup above) and dispatches to 12 small handlers for the
; classic 68000 addressing modes. Each handler appends the textual representation using the
; FormatHex* helpers and advances the output pointer in the disasm buffer. This is the heart
; of why 'd' on a 68000 program produces readable output like "move.l (a0)+,d0" or "adda.w $1234(a6),a1".
	dc.b     $E1,$88,$10,$15,$56,$4D,$60,$3C,$4A,$2E,$16,$80,$60,$04,$4A,$2E; Table data bytes
	dc.b     $16,$7F,$67,$06,$10,$FC,$00,$23,$60,$26,$10,$FC,$00,$23,$0C,$2D; Table data bytes
	dc.b     $00,$20,$FF,$FF,$67,$0C,$0C,$2D,$00,$4C,$FF,$FF,$67,$04,$48,$7A; Table data bytes
	dc.b     $00,$B2,$70,$00,$10,$2D,$00,$01,$E1,$88,$10,$15,$54,$4D,$60,$04; Table data bytes
	dc.b     $70,$00,$10,$1D,$60,$00,$FC,$CA,$10,$FC,$00,$61,$4E,$75,$10,$FC; Table data bytes
	dc.b     $00,$28,$61,$EC,$61,$20,$10,$FC,$00,$29,$4E,$75,$10,$FC,$00,$28; Table data bytes
	dc.b     $61,$DE,$60,$F2,$61,$F6,$10,$FC,$00,$2C,$10,$FC,$00,$79,$4E,$75; Table data bytes
	dc.b     $61,$CE,$60,$02,$61,$A8,$10,$FC,$00,$2C,$10,$FC,$00,$78,$4E,$75; Table data bytes
	dc.b     $61,$9C,$60,$E2,$61,$BA,$60,$DE,$10,$FC,$00,$28,$61,$A4,$61,$E6; Table data bytes
	dc.b     $60,$C4,$10,$FC,$00,$28,$61,$9A,$60,$BC,$10,$1D,$48,$80,$48,$C0; Table data bytes
	dc.b     $D0,$8D,$60,$A0,$10,$2D,$00,$01,$E1,$48,$10,$15,$54,$4D,$48,$C0; Table data bytes
	dc.b     $D0,$8D,$60,$90,$48,$7A,$FF,$B0,$10,$FC,$00,$5B,$61,$00,$FF,$82; Table data bytes
	dc.b     $10,$FC,$00,$5D,$4E,$75,$61,$00,$FF,$78,$10,$FC,$00,$2C,$10,$FC; Table data bytes
	dc.b     $00,$73,$4E,$75,$10,$FC,$00,$28,$61,$EC,$10,$FC,$00,$29,$60,$00; Table data bytes
	dc.b     $FF,$86,$48,$E7,$E0,$C0,$32,$00,$51,$C1,$0C,$41,$43,$00,$66,$0C; Table data bytes
	dc.b     $12,$00,$E8,$09,$06,$01,$00,$30,$02,$40,$FF,$8F,$43,$FA,$4E,$C4; Table data bytes
	dc.b     $41,$FA,$4E,$D6,$4A,$51,$6B,$34,$B0,$59,$65,$30,$B0,$51,$63,$0E; Table data bytes
	dc.b     $34,$11,$94,$61,$52,$42,$58,$49,$E7,$4A,$D0,$C2,$60,$E6,$90,$61; Table data bytes
	dc.b     $E7,$48,$43,$F0,$00,$00,$41,$EE,$19,$C4,$10,$FC,$00,$3B,$74,$07; Table data bytes
	dc.b     $10,$D9,$66,$04,$11,$41,$FF,$FF,$51,$CA,$FF,$F6,$4C,$DF,$03,$07; Table data bytes
	dc.b     $4E,$75                               ; Table data bytes
Disasm_CheckBreakpoint:
	movem.l  d0-d1/a0,-(a7)                              ; Move multiple registers d0-d1/a0 to -(a7)
	lea.l    Var_Breakpoints(a6),a0                      ; Load address of breakpoint table structure pointer into pointer a0
	moveq    #$9,d0                                      ; Initialize register d0 to constant $9
	bsr.b    Disasm_CheckAddressInRange                  ; Call subroutine to Disasm_CheckAddressInRange
	bpl.b    Disasm_CheckBreakpoint_Done                 ; Branch to Disasm_CheckBreakpoint_Done if positive / plus
	lea.l    Var_CommandLine(a6),a0                      ; Load address of console command line input buffer into pointer a0
	move.w   #$63,d0                                     ; Move constant $63 to register d0
	bsr.b    Disasm_CheckAddressInRange                  ; Call subroutine to Disasm_CheckAddressInRange
Disasm_CheckBreakpoint_Done:
	movem.l  (a7)+,d0-d1/a0                              ; Move multiple registers (a7)+ to d0-d1/a0
	rts                                                  ; Return from subroutine
Disasm_CheckAddressInRange:
	move.l   (a0)+,d1                                    ; Move (a0)+ to register d1
	beq.b    Disasm_CheckAddressInRange_Loop             ; Branch to Disasm_CheckAddressInRange_Loop if zero / equal
	cmp.l    $1632(a6),d1                                ; Compare register d1 against $1632(a6)
	bcs.b    Disasm_CheckAddressInRange_Loop             ; Branch to Disasm_CheckAddressInRange_Loop if carry set (less than)
	cmp.l    $1636(a6),d1                                ; Compare register d1 against $1636(a6)
	bcc.b    Disasm_CheckAddressInRange_Loop             ; Branch to Disasm_CheckAddressInRange_Loop if carry clear (greater or equal)
	st.b     Var_ScreenFlags(a6)                   ; Set screen display mode flags flag (true).
	bra.b    Disasm_CheckAddressInRange_Exit             ; Unconditional branch to Disasm_CheckAddressInRange_Exit
Disasm_CheckAddressInRange_Loop:
	dbra     d0,Disasm_CheckAddressInRange               ; Decrement loop counter d0 and loop back to Disasm_CheckAddressInRange if not exhausted
Disasm_CheckAddressInRange_Exit:
	tst.w    d0                                          ; Test status of register d0 (for zero or negative)
	rts                                                  ; Return from subroutine
	dc.b     $48,$E7,$C0,$80,$41,$EE,$1D,$04,$30,$3C,$00,$63,$22,$18,$66,$04; Table data bytes
	dc.b     $21,$06,$60,$06,$B2,$86,$57,$C8,$FF,$F4,$4C,$DF,$01,$03,$4E,$75; Table data bytes
	dc.b     $49,$EE,$19,$9C,$43,$EE,$1D,$04,$53,$83,$6B,$14,$66,$3C,$4A,$AE; Table data bytes
	dc.b     $18,$20,$66,$36,$20,$49,$30,$3C,$00,$63,$42,$98,$51,$C8,$FF,$FC; Table data bytes
	dc.b     " LE",$E8                             ; String literal data
	dc.b     $00,$46,$34,$3C,$00,$63,$20,$19,$67,$0E,$52,$48,$61,$00,$FB,$12; Table data bytes
	dc.b     $B1,$CA,$63,$04,$61,$00,$99,$FA,$51,$CA,$FF,$EC,$B9,$C8,$67,$04; Table data bytes
	dc.b     $61,$00,$99,$EE,$50,$C7,$4E,$75       ; Table data bytes
; ============================================================================
; Function: Disasm_DisassembleInstruction
; Purpose : Disassembles a single Motorola 68000 instruction from the address in a5.
; Inputs  : a5 = Pointer to instruction opcode word in memory.
;           a6 = Pointer to the monitor base context.
; Outputs : a5 = Pointer advanced past the disassembled instruction.
;           Var_DisasmBuffer = Formatted instruction ASCII string.
; Clobbers: d0-d7, a0-a4.
; Notes   : Decodes size suffixes, registers, immediate operands, and dispatches
;           via the jump table to format helper routines.
; ============================================================================
Disasm_DisassembleInstruction:
	movem.l  d0-d7/a0-a4/a6,-(a7)                        ; Move multiple registers d0-d7/a0-a4/a6 to -(a7)
	lea.l    Disasm_InstructionOpcodeMap(pc),a4                            ; Load address of Disasm_InstructionOpcodeMap(pc) into pointer a4
	move.l   a5,d6                                       ; Move pointer a5 to register d6
	move.l   a5,$1632(a6)                                ; Move pointer a5 to $1632(a6)
Disasm_DisassembleInstruction_Loc_7AF2:
	moveq    #$13,d0                                     ; Initialize register d0 to constant $13
	lea.l    Var_DisasmBuffer(a6),a0                     ; Load address of disassembler output text buffer into pointer a0
	move.l   #$20202020,d1                               ; Move constant $20202020 to register d1
Disasm_DisassembleInstruction_Loc_7AFE:
	move.l   d1,(a0)+                                    ; Move register d1 to (a0)+
	dbra     d0,Disasm_DisassembleInstruction_Loc_7AFE   ; Decrement loop counter d0 and loop back to Disasm_DisassembleInstruction_Loc_7AFE if not exhausted
	sf.b     Var_DisasmFlag(a6)                    ; Clear disassembler mode flag flag (false).
	movea.l  d6,a5                                       ; Move register d6 to pointer a5
	move.w   (a5)+,d1                                    ; Move (a5)+ to register d1
Disasm_DisassembleInstruction_Loc_7B0C:
	move.w   d1,d0                                       ; Move register d1 to register d0
	and.w    (a4)+,d0                                    ; Logical AND register d0 with (a4)+
	cmp.w    (a4),d0                                     ; Compare register d0 against (a4)
	lea.l    $c(a4),a4                                   ; Load address of $c(a4) into pointer a4
	bne.b    Disasm_DisassembleInstruction_Loc_7B0C      ; Branch to Disasm_DisassembleInstruction_Loc_7B0C if non-zero / not equal
	move.w   -$a(a4),d2                                  ; Move -$a(a4) to register d2
	move.l   d6,d0                                       ; Move register d6 to register d0
	lea.l    Var_DisasmBuffer(a6),a0                     ; Load address of disassembler output text buffer into pointer a0
	move.w   #$3e2c,(a0)+                                ; Move constant $3e2c to (a0)+
	bsr.w    FormatHex8                                  ; Call subroutine to FormatHex8
	addq.w   #$1,a0                                      ; Add 1 to pointer a0
	lea.l    -$8(a4),a1                                  ; Load address of -$8(a4) into pointer a1
Disasm_DisassembleInstruction_Loc_7B30:
	move.b   (a1)+,(a0)+                                 ; Copy word/byte data from source pointer a1 to destination a0
	bpl.b    Disasm_DisassembleInstruction_Loc_7B30      ; Branch to Disasm_DisassembleInstruction_Loc_7B30 if positive / plus
	bclr     #$7,-$1(a0)                                 ; Clear bit #$7 of -$1(a0)
	st.b     d7
	move.w   d2,d4                                       ; Move register d2 to register d4
	andi.w   #$ff00,d4                                   ; Logical AND register d4 with constant $ff00
	cmpi.w   #$0,d4                                      ; Compare register d4 against 0
	bne.b    Disasm_DisassembleInstruction_Loc_7B4C      ; Branch to Disasm_DisassembleInstruction_Loc_7B4C if non-zero / not equal
	bsr.w    Disasm_FormatSize_Normal                    ; Call subroutine to Disasm_FormatSize_Normal
Disasm_DisassembleInstruction_Loc_7B4C:
	cmpi.w   #$500,d4                                    ; Compare register d4 against constant $500
	bne.b    Disasm_DisassembleInstruction_Loc_7B56      ; Branch to Disasm_DisassembleInstruction_Loc_7B56 if non-zero / not equal
	bsr.w    Disasm_FormatSize_Shift3_Minus40            ; Call subroutine to Disasm_FormatSize_Shift3_Minus40
Disasm_DisassembleInstruction_Loc_7B56:
	cmpi.w   #$600,d4                                    ; Compare register d4 against constant $600
	bne.b    Disasm_DisassembleInstruction_Loc_7B60      ; Branch to Disasm_DisassembleInstruction_Loc_7B60 if non-zero / not equal
	bsr.w    Disasm_FormatSize_Shift3                    ; Call subroutine to Disasm_FormatSize_Shift3
Disasm_DisassembleInstruction_Loc_7B60:
	cmpi.w   #BPLCON0,d4                                 ; Compare register d4 against BPLCON0 (bitplane control register 0)
	bne.b    Disasm_DisassembleInstruction_Loc_7B6A      ; Branch to Disasm_DisassembleInstruction_Loc_7B6A if non-zero / not equal
	bsr.w    Disasm_FormatSizeWordOrLong_Bit6            ; Call subroutine to Disasm_FormatSizeWordOrLong_Bit6
Disasm_DisassembleInstruction_Loc_7B6A:
	cmpi.w   #$200,d4                                    ; Compare register d4 against constant $200
	bne.b    Disasm_DisassembleInstruction_Loc_7B74      ; Branch to Disasm_DisassembleInstruction_Loc_7B74 if non-zero / not equal
	bsr.w    Disasm_FormatSizeWordOrLong_Bit8            ; Call subroutine to Disasm_FormatSizeWordOrLong_Bit8
Disasm_DisassembleInstruction_Loc_7B74:
	cmpi.w   #$300,d4                                    ; Compare register d4 against constant $300
	bne.b    Disasm_DisassembleInstruction_Loc_7B7E      ; Branch to Disasm_DisassembleInstruction_Loc_7B7E if non-zero / not equal
	bsr.w    Disasm_PositionOperandColumn                ; Call subroutine to Disasm_PositionOperandColumn
Disasm_DisassembleInstruction_Loc_7B7E:
	lea.l    Disasm_HandlerOffsetTable(pc),a1                            ; Load address of Disasm_HandlerOffsetTable(pc) into pointer a1
	ext.w    d2
	add.w    d2,d2                                       ; Add register d2 to register d2
	move.w   (a1,d2.w),d2                                ; Move (a1,d2.w) to register d2
	move.l   d6,-(a7)                                    ; Move register d6 to -(a7)
	jsr      Disasm_HandlerCodeBlock(pc,d2.w)                          ; Call subroutine Disasm_HandlerCodeBlock(pc,d2.w)
	move.l   (a7)+,d6                                    ; Move (a7)+ to register d6
	tst.b    d7                                          ; Test status of register d7 (for zero or negative)
	beq.w    Disasm_DisassembleInstruction_Loc_7AF2      ; Branch to Disasm_DisassembleInstruction_Loc_7AF2 if zero / equal
	move.l   a5,$1636(a6)                                ; Move pointer a5 to $1636(a6)
	movem.l  (a7)+,d0-d7/a0-a4/a6                        ; Move multiple registers (a7)+ to d0-d7/a0-a4/a6
	rts                                                  ; Return from subroutine
; ============================================================================
; Data Block: Disasm_HandlerCodeBlock
; Purpose   : Target code block for disassembler formatting routines.
; ============================================================================
Disasm_HandlerCodeBlock:
	dc.b     $70,$FF,$33,$C0,$00,$DF,$F1,$80,$51,$C8,$FF,$F8,$4E,$75,$30,$01; Table data bytes
	dc.b     $60,$00,$FA,$0C,$51,$EE,$16,$66,$61,$00,$0D,$68,$60,$00,$0B,$84; Table data bytes
	dc.b     $1D,$7C,$00,$01,$16,$66,$61,$00,$0D,$5A,$60,$00,$0B,$80,$61,$00; Table data bytes
	dc.b     $0B,$76,$60,$04,$61,$00,$0B,$7A,$60,$00,$0D,$34,$6C,$73,$78,$70; Table data bytes
	dc.b     "wdbpC",$FA                           ; String literal data
	dc.b     $3E,$A4,$61,$00,$0B,$6A,$10,$FC,$00,$2E,$30,$06,$ED,$58,$02,$40; Table data bytes
	dc.b     $00,$07,$10,$FB,$00,$E2,$61,$00,$0A,$CE,$74,$38,$C4,$41,$66,$10; Table data bytes
	dc.b     $4A,$00,$67,$0C,$53,$00,$67,$08,$57,$00,$67,$04,$55,$00,$66,$66; Table data bytes
	dc.b     $0C,$02,$00,$08,$67,$60,$7A,$7F,$CA,$46,$76,$01,$57,$00,$67,$0C; Table data bytes
	dc.b     $76,$02,$59,$00,$67,$06,$4A,$05,$66,$4C,$76,$00,$30,$06,$EE,$48; Table data bytes
	dc.b     $02,$40,$00,$07,$61,$00,$01,$3C,$61,$00,$0C,$CE,$53,$03,$6B,$34; Table data bytes
	dc.b     $10,$FC,$00,$7B,$4A,$03,$67,$0E,$70,$0F,$C0,$05,$66,$28,$10,$FC; Table data bytes
	dc.b     $00,$64,$E8,$0D,$60,$14,$10,$FC,$00,$23,$08,$05,$00,$06,$67,$0A; Table data bytes
	dc.b     $08,$C5,$00,$07,$44,$05,$10,$FC,$00,$2D,$20,$05,$61,$00,$FA,$18; Table data bytes
	dc.b     $10,$FC,$00,$7D,$4E,$75,$60,$00,$1E,$CE,$3C,$1D,$30,$3C,$E0,$00; Table data bytes
	dc.b     $C0,$46,$0C,$40,$60,$00,$67,$00,$FF,$56,$30,$3C,$A0,$00,$C0,$46; Table data bytes
	dc.b     $66,$30,$08,$06,$00,$0E,$66,$04,$4A,$01,$66,$26,$43,$FA,$3D,$28; Table data bytes
	dc.b     $70,$7F,$C0,$46,$14,$19,$08,$82,$00,$07,$56,$C3,$78,$78,$C8,$06; Table data bytes
	dc.b     $0C,$04,$00,$30,$57,$C4,$67,$1E,$B0,$02,$67,$1A,$5C,$49,$4A,$11; Table data bytes
	dc.b     $66,$E2,$51,$C7,$4E,$75,$6C,$73,$78,$70,$77,$64,$62,$2A,$02,$02; Table data bytes
	dc.b     $06,$06,$01,$04,$00,$FF,$61,$00,$0A,$76,$10,$FC,$00,$2E,$30,$06; Table data bytes
	dc.b     $ED,$58,$02,$40,$00,$07,$08,$06,$00,$0E,$67,$3A,$0C,$40,$00,$07; Table data bytes
	dc.b     $67,$D0,$10,$FB,$00,$D2,$1D,$7B,$00,$D6,$16,$66,$61,$00,$09,$C8; Table data bytes
	dc.b     $74,$38,$C4,$41,$66,$10,$4A,$00,$67,$0C,$53,$00,$67,$08,$57,$00; Table data bytes
	dc.b     $67,$04,$55,$00,$66,$AC,$0C,$02,$00,$08,$67,$A6,$61,$00,$0B,$FE; Table data bytes
	dc.b     $50,$C0,$51,$C3,$60,$0A,$10,$FC,$00,$78,$61,$00,$09,$9A,$61,$42; Table data bytes
	dc.b     $74,$7F,$C4,$46,$0C,$02,$00,$3A,$66,$0A,$02,$46,$03,$80,$66,$00; Table data bytes
	dc.b     $1E,$06,$4E,$75,$4A,$04,$67,$14,$74,$07,$C4,$46,$61,$1E,$10,$FC; Table data bytes
	dc.b     $00,$3A,$30,$06,$EE,$48,$02,$40,$00,$07,$60,$16,$34,$06,$EE,$4A; Table data bytes
	dc.b     $02,$42,$00,$07,$4A,$03,$66,$04,$B4,$00,$67,$14,$30,$02,$10,$FC; Table data bytes
	dc.b     $00,$2C,$10,$FC,$00,$66,$10,$FC,$00,$70,$74,$30,$D4,$00,$10,$C2; Table data bytes
	dc.b     "Nu0<",$C7                            ; String literal data
	dc.b     $00,$C0,$55,$0C,$40,$C0,$00,$66,$00,$1D,$B8,$36,$1D,$08,$03,$00; Table data bytes
	dc.b     $0D,$66,$0C,$61,$00,$0B,$82,$10,$FC,$00,$2C,$60,$00,$0A,$60,$61; Table data bytes
	dc.b     $00,$0A,$5C,$60,$00,$0B,$5E,$50,$C5,$60,$02,$51,$C5,$30,$3C,$C3; Table data bytes
	dc.b     $FF,$C0,$55,$0C,$40,$80,$00,$66,$00,$1D,$88,$1D,$7C,$00,$02,$16; Table data bytes
	dc.b     $66,$3C,$1D,$B1,$46,$08,$06,$00,$0A,$56,$C4,$08,$06,$00,$0B,$56; Table data bytes
	dc.b     $C0,$D8,$00,$08,$06,$00,$0C,$56,$C0,$D8,$00,$67,$00,$1D,$64,$70; Table data bytes
	dc.b     $38,$C0,$41,$66,$08,$0C,$04,$00,$FF,$66,$00,$1D,$56,$51,$40,$66; Table data bytes
	dc.b     $10,$0C,$04,$00,$FF,$66,$00,$1D,$4A,$08,$06,$00,$0A,$67,$00,$1D; Table data bytes
	dc.b     $42,$08,$86,$00,$0D,$67,$06,$61,$0C,$60,$00,$0A,$F8,$61,$00,$0B; Table data bytes
	dc.b     $08,$10,$FC,$00,$2C,$10,$FC,$00,$66,$10,$FC,$00,$70,$70,$63,$08; Table data bytes
	dc.b     $86,$00,$0C,$66,$16,$70,$73,$08,$86,$00,$0B,$66,$0E,$10,$FC,$00; Table data bytes
	dc.b     $69,$70,$61,$08,$86,$00,$0A,$67,$00,$1D,$08,$10,$C0,$10,$FC,$00; Table data bytes
	dc.b     "rJFg"                                ; String literal data
	dc.b     $0C,$4A,$05,$67,$00,$1C,$F8,$10,$FC,$00,$2F,$60,$C4,$4E,$75,$30; Table data bytes
	dc.b     $15,$02,$40,$FC,$40,$0C,$40,$5C,$00,$66,$00,$1C,$E2,$70,$3F,$C0; Table data bytes
	dc.b     $55,$32,$00,$67,$22,$0C,$00,$00,$30,$64,$00,$00,$18,$0C,$00,$00; Table data bytes
	dc.b     $0F,$62,$00,$1C,$CA,$0C,$00,$00,$0B,$65,$00,$1C,$C2,$04,$01,$00; Table data bytes
	dc.b     $0A,$60,$04,$04,$01,$00,$2A,$10,$FC,$00,$23,$61,$00,$F7,$6C,$30; Table data bytes
	dc.b     $1D,$61,$00,$08,$8A,$41,$EE,$19,$C4,$10,$FC,$00,$3B,$43,$FA,$2B; Table data bytes
	dc.b     $60,$0C,$01,$00,$0A,$63,$0E,$61,$14,$70,$00,$04,$01,$00,$09,$03; Table data bytes
	dc.b     $C0,$60,$00,$F7,$CA,$4A,$19,$6A,$FC,$51,$C9,$FF,$FA,$60,$00,$08; Table data bytes
	dc.b     $86,$70,$F0,$C0,$55,$66,$00,$1C,$76,$30,$1D,$61,$00,$09,$F8,$60; Table data bytes
	dc.b     $0E,$70,$E0,$C0,$55,$66,$00,$1C,$66,$30,$1D,$61,$00,$09,$FC,$61; Table data bytes
	dc.b     $00,$07,$DC,$61,$00,$08,$26,$10,$FC,$00,$2C,$30,$1D,$43,$F5,$00; Table data bytes
	dc.b     $FE,$60,$2A,$30,$01,$61,$00,$09,$B6,$61,$00,$07,$C2,$61,$00,$08; Table data bytes
	dc.b     $0C,$10,$FC,$00,$2C,$60,$10,$30,$01,$61,$00,$09,$A2,$61,$00,$08; Table data bytes
	dc.b     "@.wa"                                ; String literal data
	dc.b     $00,$07,$A8,$30,$1D,$43,$F5,$00,$FE,$20,$09,$60,$00,$F6,$D8,$30; Table data bytes
	dc.b     $01,$61,$00,$09,$86,$61,$00,$08,$24,$2E,$6C,$61,$00,$07,$8C,$20; Table data bytes
	dc.b     $1D,$43,$F5,$08,$FC,$60,$E2,$30,$01,$61,$00,$09,$6E,$61,$00,$08; Table data bytes
	dc.b     $0C,$2E,$62,$61,$00,$07,$74,$10,$01,$48,$80,$43,$F5,$00,$00,$60; Table data bytes
	dc.b     $C8,$30,$01,$61,$00,$09,$6C,$60,$06,$30,$01,$61,$00,$09,$78,$08; Table data bytes
	dc.b     $01,$00,$06,$67,$A4,$60,$BE,$61,$00,$09,$A6,$60,$00,$07,$6A,$1D; Table data bytes
	dc.b     $7C,$00,$02,$16,$66,$60,$06,$1D,$7C,$00,$01,$16,$66,$61,$00,$09; Table data bytes
	dc.b     $90,$60,$00,$07,$5E,$61,$00,$07,$5E,$30,$3C,$F1,$C0,$C0,$41,$0C; Table data bytes
	dc.b     $40,$01,$00,$67,$04,$60,$00,$09,$64,$10,$FC,$00,$2C,$60,$00,$09; Table data bytes
	dc.b     $70,$10,$FC,$00,$23,$70,$00,$10,$1D,$66,$00,$1B,$8E,$10,$1D,$61; Table data bytes
	dc.b     $00,$F6,$44,$60,$00,$07,$7A,$61,$08,$60,$00,$07,$7E,$10,$FC,$00; Table data bytes
	dc.b     $2C,$10,$FC,$00,$23,$70,$00,$30,$1D,$60,$00,$F6,$2A,$0C,$5D,$01; Table data bytes
	dc.b     $C0,$67,$EE,$60,$00,$1B,$64,$30,$15,$02,$40,$82,$38,$66,$00,$1B; Table data bytes
	dc.b     $5A,$30,$15,$76,$73,$08,$00,$00,$0B,$66,$02,$76,$75,$10,$C3,$08; Table data bytes
	dc.b     $00,$00,$0A,$67,$04,$10,$FC,$00,$6E,$61,$00,$06,$A4,$36,$1D,$08; Table data bytes
	dc.b     $03,$00,$08,$67,$0E,$70,$3F,$C0,$43,$66,$00,$1B,$2E,$61,$00,$09; Table data bytes
	dc.b     $00,$60,$12,$61,$00,$06,$F2,$10,$FC,$00,$3A,$10,$FC,$00,$64,$30; Table data bytes
	dc.b     $03,$61,$00,$06,$EA,$30,$03,$E9,$58,$10,$FC,$00,$2C,$10,$FC,$00; Table data bytes
	dc.b     $64,$60,$00,$06,$DA,$10,$FC,$00,$23,$30,$1D,$02,$80,$00,$00,$00; Table data bytes
	dc.b     $1F,$61,$00,$F6,$36,$30,$3C,$FF,$C0,$C0,$41,$0C,$40,$08,$00,$67; Table data bytes
	dc.b     $04,$60,$00,$08,$A8,$10,$FC,$00,$2C,$60,$00,$08,$B4,$70,$F0,$C0; Table data bytes
	dc.b     $55,$66,$00,$1A,$D6,$30,$1D,$61,$00,$08,$58,$60,$16,$70,$E0,$C0; Table data bytes
	dc.b     $55,$66,$00,$1A,$C6,$30,$1D,$61,$00,$08,$5C,$60,$06,$30,$01,$61; Table data bytes
	dc.b     $00,$08,$28,$61,$00,$06,$34,$60,$00,$08,$86,$36,$1D,$30,$3C,$07; Table data bytes
	dc.b     $FF,$C0,$43,$66,$00,$1A,$A4,$08,$83,$00,$0B,$66,$0C,$61,$00,$08; Table data bytes
	dc.b     $70,$10,$FC,$00,$2C,$60,$00,$01,$10,$61,$00,$01,$0C,$60,$00,$08; Table data bytes
	dc.b     $4C,$61,$00,$0C,$5E,$60,$00,$08,$44,$61,$00,$06,$08,$60,$00,$08; Table data bytes
	dc.b     $3C,$08,$01,$00,$05,$67,$06,$61,$00,$06,$1C,$60,$04,$61,$00,$05; Table data bytes
	dc.b     $F4,$60,$00,$06,$30,$10,$FC,$00,$23,$30,$01,$60,$00,$F5,$7E,$60; Table data bytes
	dc.b     $00,$06,$26,$08,$01,$00,$03,$67,$08,$61,$00,$06,$3E,$60,$00,$06; Table data bytes
	dc.b     $0A,$61,$00,$06,$0A,$60,$00,$06,$2E,$30,$15,$0C,$40,$41,$00,$67; Table data bytes
	dc.b     $00,$00,$1A,$0A,$40,$09,$00,$02,$40,$BB,$FF,$66,$00,$1A,$2C,$60; Table data bytes
	dc.b     $0A,$30,$3C,$01,$FF,$C0,$55,$66,$00,$1A,$20,$36,$1D,$08,$83,$00; Table data bytes
	dc.b     $08,$08,$83,$00,$09,$66,$0A,$61,$00,$07,$E6,$10,$FC,$00,$2C,$60; Table data bytes
	dc.b     $06,$61,$04,$60,$00,$07,$C6,$43,$FA,$29,$65,$E0,$4B,$10,$19,$67; Table data bytes
	dc.b     $00,$19,$F8,$B0,$03,$67,$08,$08,$19,$00,$07,$67,$FA,$60,$EE,$60; Table data bytes
	dc.b     $00,$05,$F0,$EC,$49,$70,$03,$C0,$41,$10,$FB,$00,$08,$10,$FC,$00; Table data bytes
	dc.b     "cNundib?"                            ; String literal data
	dc.b     $01,$61,$E8,$32,$1F,$60,$00,$07,$E2,$60,$00,$07,$E2,$36,$1D,$08; Table data bytes
	dc.b     $01,$00,$00,$66,$08,$61,$0C,$10,$FC,$00,$2C,$60,$32,$61,$30,$10; Table data bytes
	dc.b     $FC,$00,$2C,$43,$FA,$28,$B0,$32,$03,$02,$41,$0F,$FF,$B2,$51,$67; Table data bytes
	dc.b     $0A,$4A,$51,$5C,$49,$66,$F6,$60,$00,$19,$98,$54,$49,$10,$D9,$10; Table data bytes
	dc.b     $D9,$4A,$11,$67,$08,$10,$D9,$4A,$11,$67,$02,$10,$D1,$4E,$75,$30; Table data bytes
	dc.b     $03,$02,$40,$F0,$00,$E9,$58,$06,$00,$00,$30,$10,$FC,$00,$61,$08; Table data bytes
	dc.b     $80,$00,$03,$66,$04,$56,$28,$FF,$FF,$10,$C0,$4E,$75,$34,$1D,$08; Table data bytes
	dc.b     $02,$00,$0F,$66,$00,$19,$5C,$61,$28,$10,$FC,$00,$2C,$30,$02,$60; Table data bytes
	dc.b     $D0,$30,$15,$08,$00,$00,$0F,$66,$00,$19,$48,$61,$C4,$10,$FC,$00; Table data bytes
	dc.b     $2C,$34,$1D,$60,$0C,$34,$1D,$30,$02,$02,$40,$F0,$00,$66,$00,$19; Table data bytes
	dc.b     $32,$61,$00,$07,$04,$10,$FC,$00,$7B,$30,$02,$EC,$48,$61,$0E,$10; Table data bytes
	dc.b     $FC,$00,$3A,$30,$02,$61,$06,$10,$FC,$00,$7D,$4E,$75,$08,$00,$00; Table data bytes
	dc.b     $05,$66,$0C,$02,$00,$00,$1F,$66,$02,$70,$20,$60,$00,$F4,$12,$08; Table data bytes
	dc.b     $00,$00,$04,$66,$00,$18,$FC,$08,$00,$00,$03,$66,$00,$18,$F4,$10; Table data bytes
	dc.b     $FC,$00,$64,$02,$00,$00,$07,$06,$00,$00,$30,$10,$C0,$4E,$75,$10; Table data bytes
	dc.b     $FC,$00,$23,$60,$00,$04,$AE,$08,$01,$00,$03,$67,$1C,$61,$00,$04; Table data bytes
	dc.b     $E4,$2D,$28,$61,$00,$04,$90,$61,$00,$04,$EA,$29,$2C,$2D,$28,$61; Table data bytes
	dc.b     $00,$04,$62,$10,$FC,$00,$29,$60,$08,$61,$00,$04,$84,$61,$00,$04; Table data bytes
	dc.b     $5A,$60,$00,$FD,$32,$34,$15,$02,$42,$8F,$FF,$0C,$42,$80,$00,$66; Table data bytes
	dc.b     $00,$18,$A0,$61,$00,$06,$DA,$32,$1D,$E9,$59,$60,$00,$06,$CE,$74; Table data bytes
	dc.b     $10,$08,$81,$00,$04,$66,$02,$74,$18,$08,$81,$00,$03,$67,$08,$61; Table data bytes
	dc.b     $10,$82,$42,$60,$00,$06,$3E,$82,$42,$61,$00,$06,$4C,$10,$FC,$00; Table data bytes
	dc.b     $2C,$60,$00,$09,$82,$30,$01,$02,$40,$30,$00,$E9,$58,$66,$04,$51; Table data bytes
	dc.b     $C7,$4E,$75,$43,$FA,$27,$F7,$10,$F1,$00,$00,$1D,$71,$00,$04,$16; Table data bytes
	dc.b     $66,$61,$00,$03,$CE,$61,$00,$06,$20,$30,$01,$EF,$58,$02,$40,$00; Table data bytes
	dc.b     $07,$36,$01,$E6,$4B,$02,$43,$00,$38,$80,$43,$32,$00,$60,$00,$05; Table data bytes
	dc.b     $F4,$10,$FC,$00,$23,$70,$00,$10,$01,$61,$00,$F2,$E2,$60,$00,$03; Table data bytes
	dc.b     $CA,$4A,$15,$66,$00,$18,$1C,$3F,$01,$10,$FC,$00,$23,$70,$00,$10; Table data bytes
	dc.b     $1D,$66,$00,$18,$0E,$10,$1D,$61,$00,$F2,$C4,$32,$1F,$60,$00,$05; Table data bytes
	dc.b     $C4,$61,$00,$03,$7E,$30,$15,$02,$40,$0E,$38,$66,$00,$17,$F4,$30; Table data bytes
	dc.b     $15,$10,$FC,$00,$64,$61,$00,$03,$BE,$10,$FC,$00,$2C,$30,$1D,$EC; Table data bytes
	dc.b     $48,$10,$FC,$00,$64,$61,$00,$03,$AE,$60,$00,$05,$98,$74,$77,$08; Table data bytes
	dc.b     $01,$00,$09,$67,$02,$74,$6C,$10,$C2,$61,$00,$03,$46,$24,$15,$02; Table data bytes
	dc.b     $82,$0E,$38,$0E,$38,$66,$00,$17,$BA,$24,$15,$61,$28,$10,$FC,$00; Table data bytes
	dc.b     $2C,$EC,$8A,$61,$20,$61,$00,$03,$BC,$2C,$28,$30,$1D,$61,$00,$FE; Table data bytes
	dc.b     $22,$61,$00,$03,$C0,$29,$3A,$28,$00,$30,$1D,$61,$00,$FE,$14,$10; Table data bytes
	dc.b     $FC,$00,$29,$4E,$75,$20,$02,$48,$40,$10,$FC,$00,$64,$61,$00,$03; Table data bytes
	dc.b     $56,$30,$02,$61,$00,$03,$8E,$3A,$64,$60,$00,$03,$4A,$34,$1D,$08; Table data bytes
	dc.b     $02,$00,$0B,$67,$00,$17,$6C,$60,$0A,$34,$1D,$08,$02,$00,$0B,$66; Table data bytes
	dc.b     $00,$17,$60,$61,$00,$05,$32,$10,$FC,$00,$2C,$30,$02,$60,$00,$FD; Table data bytes
	dc.b     $D2,$70,$0F,$C0,$41,$60,$00,$FD,$D0,$30,$01,$61,$00,$04,$B4,$10; Table data bytes
	dc.b     $FC,$00,$2E,$70,$77,$08,$01,$00,$00,$67,$02,$70,$6C,$10,$C0,$61; Table data bytes
	dc.b     $00,$02,$B0,$10,$FC,$00,$23,$70,$00,$01,$01,$66,$06,$30,$1D,$60; Table data bytes
	dc.b     $00,$F1,$DC,$20,$1D,$60,$00,$F1,$D6,$30,$01,$60,$00,$04,$84,$61; Table data bytes
	dc.b     $02,$60,$CC,$70,$E0,$C0,$55,$66,$00,$17,$08,$30,$1D,$60,$00,$04; Table data bytes
	dc.b     $9E,$61,$02,$60,$BA,$70,$F0,$C0,$55,$66,$00,$16,$F6,$30,$1D,$60; Table data bytes
	dc.b     $00,$04,$78,$4A,$5D,$57,$C7,$4E,$75,$70,$F8,$C0,$55,$0C,$40,$2C; Table data bytes
	dc.b     $00,$66,$00,$16,$DE,$30,$1D,$10,$FC,$00,$61,$61,$00,$02,$A8,$60; Table data bytes
	dc.b     $00,$04,$92,$0C,$5D,$24,$00,$57,$C7,$4E,$75,$0C,$5D,$A0,$00,$66; Table data bytes
	dc.b     $00,$16,$C0,$60,$00,$04,$92,$0C,$15,$00,$34,$67,$0A,$60,$00,$16; Table data bytes
	dc.b     $B2,$0C,$15,$00,$30,$66,$F6,$30,$1D,$72,$18,$C2,$40,$66,$1A,$72; Table data bytes
	dc.b     $07,$74,$73,$C2,$40,$67,$08,$74,$64,$53,$01,$66,$00,$16,$94,$10; Table data bytes
	dc.b     $C2,$61,$00,$02,$A0,$66,$63,$60,$18,$0C,$41,$00,$18,$67,$00,$16; Table data bytes
	dc.b     $82,$72,$23,$08,$80,$00,$03,$67,$02,$72,$64,$10,$C1,$61,$00,$F0; Table data bytes
	dc.b     $CC,$61,$00,$02,$80,$2C,$23,$EA,$48,$60,$00,$02,$3A,$30,$15,$02; Table data bytes
	dc.b     $40,$FD,$F8,$0C,$40,$20,$10,$66,$00,$16,$58,$30,$1D,$10,$BC,$00; Table data bytes
	dc.b     $72,$08,$00,$00,$09,$66,$02,$5A,$10,$61,$00,$01,$C6,$10,$FC,$00; Table data bytes
	dc.b     $23,$61,$00,$F0,$98,$60,$00,$03,$FC,$30,$15,$02,$40,$E1,$18,$0C; Table data bytes
	dc.b     $40,$81,$10,$66,$00,$16,$2C,$34,$15,$61,$D0,$61,$00,$02,$36,$2C; Table data bytes
	dc.b     $23,$30,$02,$ED,$58,$74,$07,$C4,$00,$67,$00,$16,$16,$61,$00,$F0; Table data bytes
	dc.b     $6C,$61,$00,$02,$20,$2C,$61,$EB,$58,$08,$80,$00,$03,$60,$00,$F0; Table data bytes
	dc.b     $5C,$34,$1D,$08,$42,$00,$0A,$66,$00,$15,$F8,$61,$1C,$60,$0C,$34; Table data bytes
	dc.b     $1D,$08,$42,$00,$0A,$66,$00,$15,$EA,$61,$1A,$92,$02,$02,$01,$00; Table data bytes
	dc.b     $07,$67,$00,$15,$DE,$4E,$75,$34,$1D,$08,$02,$00,$0B,$67,$00,$15; Table data bytes
	dc.b     $D2,$60,$0A,$34,$1D,$08,$02,$00,$0B,$66,$00,$15,$C6,$30,$3C,$83; Table data bytes
	dc.b     $F8,$C0,$42,$66,$00,$15,$BC,$1D,$7C,$00,$02,$16,$66,$61,$00,$03; Table data bytes
	dc.b     $88,$10,$FC,$00,$2C,$32,$02,$08,$02,$00,$0A,$67,$0E,$61,$00,$01; Table data bytes
	dc.b     $70,$10,$FC,$00,$3A,$E9,$59,$60,$00,$01,$66,$E9,$59,$61,$00,$01; Table data bytes
	dc.b     $60,$92,$02,$02,$01,$00,$07,$66,$00,$15,$88,$4E,$75,$61,$00,$03; Table data bytes
	dc.b     $C0,$EF,$59,$60,$00,$03,$B6,$08,$81,$00,$0E,$08,$81,$00,$03,$67; Table data bytes
	dc.b     $08,$08,$C1,$00,$05,$08,$C1,$00,$0E,$61,$00,$03,$3C,$EF,$59,$60; Table data bytes
	dc.b     $00,$03,$22,$08,$81,$00,$0E,$08,$81,$00,$0C,$08,$81,$00,$03,$67; Table data bytes
	dc.b     $08,$08,$C1,$00,$0E,$08,$C1,$00,$05,$61,$00,$03,$1C,$EF,$59,$60; Table data bytes
	dc.b     $00,$03,$02,$08,$C1,$00,$05,$08,$01,$00,$07,$67,$08,$61,$00,$00; Table data bytes
	dc.b     $DE,$60,$00,$02,$F0,$61,$00,$03,$00,$60,$00,$00,$CE,$36,$1D,$08; Table data bytes
	dc.b     $01,$00,$0A,$66,$08,$61,$00,$01,$60,$60,$00,$02,$D8,$61,$00,$02; Table data bytes
	dc.b     $E8,$10,$FC,$00,$2C,$60,$00,$01,$50,$61,$00,$00,$B2,$60,$00,$00; Table data bytes
	dc.b     $CC,$61,$00,$00,$A0,$60,$00,$00,$BA,$61,$00,$00,$A2,$60,$00,$00; Table data bytes
	dc.b     $B2,$61,$10,$61,$00,$00,$FE,$2C,$23,$60,$00,$FD,$C8,$61,$04,$60; Table data bytes
	dc.b     $00,$F9,$64,$60,$00,$00,$A0,$61,$00,$02,$AE,$60,$72; Table data bytes
; ============================================================================
; Function: Disasm_FormatSizeWordOrLong_Bit8
; Purpose : Decides whether to append a word (.w) or long (.l) size suffix based on bit 8 of the opcode.
; Inputs  : d1 = Opcode word.
;           a0 = Destination pointer in the disassembly buffer.
;           a6 = Pointer to the monitor base context.
; Outputs : a0 = Pointer positioned at the operand column (offset 23).
; ============================================================================
Disasm_FormatSizeWordOrLong_Bit8:
	btst     #$8,d1                                      ; Test bit #$8 of register d1
	beq.b    Disasm_SetSizeWord                          ; Branch to Disasm_SetSizeWord if zero / equal
	bra.b    Disasm_SetSizeLong                          ; Unconditional branch to Disasm_SetSizeLong
Disasm_FormatSizeWordOrLong_Bit6:
	btst     #$6,d1                                      ; Test bit #$6 of register d1
	bne.b    Disasm_SetSizeLong                          ; Branch to Disasm_SetSizeLong if non-zero / not equal
Disasm_SetSizeWord:
	moveq    #$77,d0                                     ; Initialize register d0 to constant $77
	move.b   #$1,Var_DisasmSize(a6)                      ; Store 1 into Var_DisasmSize(a6)
	bra.b    Disasm_WriteSuffixDot                       ; Unconditional branch to Disasm_WriteSuffixDot
Disasm_SetSizeLong:
	moveq    #$6c,d0                                     ; Initialize register d0 to constant $6c
	move.b   #$2,Var_DisasmSize(a6)                      ; Store constant $2 into Var_DisasmSize(a6)
Disasm_WriteSuffixDot:
	move.b   #$2e,(a0)+                                  ; Move constant $2e to (a0)+
	move.b   d0,(a0)                                     ; Move register d0 to (a0)
	bra.b    Disasm_PositionOperandColumn                ; Unconditional branch to Disasm_PositionOperandColumn
Disasm_FormatSize_Shift3_Minus40:
	move.w   d1,d0                                       ; Move register d1 to register d0
	lsr.w    #$3,d0
	subi.w   #BLTCON0,d0                                 ; Subtract constant BLTCON0 from register d0
	bra.b    Disasm_FormatSize_Common                    ; Unconditional branch to Disasm_FormatSize_Common
Disasm_FormatSize_Shift3:
	move.w   d1,d0                                       ; Move register d1 to register d0
	lsr.w    #$3,d0
	bra.b    Disasm_FormatSize_Common                    ; Unconditional branch to Disasm_FormatSize_Common
Disasm_FormatSize_Normal:
	move.w   d1,d0                                       ; Move register d1 to register d0
Disasm_FormatSize_Common:
	andi.w   #$c0,d0                                     ; Logical AND register d0 with constant $c0
	cmpi.w   #$c0,d0                                     ; Compare register d0 against constant $c0
	beq.w    Disasm_ClearExitFlag                        ; Branch to Disasm_ClearExitFlag if zero / equal
	lsr.w    #$6,d0
	move.b   d0,Var_DisasmSize(a6)                       ; Store register d0 into Var_DisasmSize(a6)
	move.b   #$2e,(a0)+                                  ; Move constant $2e to (a0)+
	move.b   Str_FormatSuffixes(pc,d0.w),(a0)                     ; Move Str_FormatSuffixes(pc,d0.w) to (a0)
Disasm_PositionOperandColumn:
	lea.l    Var_DisasmBuffer+23(a6),a0                  ; Load address of disassembler output text buffer into pointer a0
	rts                                                  ; Return from subroutine
; ============================================================================
; Data Block: Str_FormatSuffixes
; Purpose   : String literal suffix list "bwl*".
; ============================================================================
Str_FormatSuffixes:
	dc.b     "bwl*"                                ; String literal data
	dc.b     $10,$FC,$00,$23,$30,$01,$02,$40,$0E,$00,$EF,$58,$66,$02,$70,$08; Table data bytes
	dc.b     $60,$00,$EF,$86,$10,$FC,$00,$2C,$10,$FC,$00,$61,$60,$08,$10,$FC; Table data bytes
	dc.b     $00,$2C,$10,$FC,$00,$64,$30,$01,$02,$40,$0E,$00,$EF,$58,$06,$00; Table data bytes
	dc.b     $00,$30,$10,$C0,$4E,$75,$10,$FC,$00,$2C,$10,$FC,$00,$61,$60,$08; Table data bytes
	dc.b     $10,$FC,$00,$2C,$10,$FC,$00,$64,$30,$01,$02,$40,$00,$07,$06,$00; Table data bytes
	dc.b     $00,$30,$10,$C0,$4E,$75,$10,$FC,$00,$2C,$61,$2C,$66,$70,$EE,$48; Table data bytes
	dc.b     $60,$E8,$10,$FC,$00,$2C,$43,$FA,$23,$00,$60,$12,$10,$FC,$00,$2C; Table data bytes
	dc.b     $43,$FA,$22,$FA,$60,$08,$10,$FC,$00,$2C,$43,$FA,$22,$F4; Table data bytes
CopyHighBitTerminatedString:
	move.b   (a1)+,(a0)                                  ; Move (a1)+ to (a0)
	bclr     #$7,(a0)+                                   ; Clear bit #$7 of (a0)+
	beq.b    CopyHighBitTerminatedString                 ; Branch to CopyHighBitTerminatedString if zero / equal
	rts                                                  ; Return from subroutine
	dc.b     $2F,$09,$22,$6F,$00,$04,$10,$D9,$10,$D9,$22,$5F,$54,$97,$4E,$75; Table data bytes
CopyInlineString3Or4:
	move.l   a1,-(a7)                                    ; Move pointer a1 to -(a7)
	movea.l  $4(a7),a1                                   ; Move $4(a7) to pointer a1
	move.b   (a1)+,(a0)+                                 ; Copy word/byte data from source pointer a1 to destination a0
	move.b   (a1)+,(a0)+                                 ; Copy word/byte data from source pointer a1 to destination a0
	move.b   (a1)+,(a0)+                                 ; Copy word/byte data from source pointer a1 to destination a0
	tst.b    (a1)                                        ; Test status of (a1) (for zero or negative)
	beq.b    CopyInlineString3Or4_Exit                   ; Branch to CopyInlineString3Or4_Exit if zero / equal
	move.b   (a1)+,(a0)+                                 ; Copy word/byte data from source pointer a1 to destination a0
CopyInlineString3Or4_Exit:
	movea.l  (a7)+,a1                                    ; Move (a7)+ to pointer a1
	addq.l   #$4,(a7)                                    ; Add constant $4 to (a7)
	rts                                                  ; Return from subroutine
CopyBoundedString:
	dc.b     $10,$19,$53,$00,$6B,$04,$10,$D9,$60,$F8,$4E,$75,$30,$01,$02,$40; Table data bytes
	dc.b     $00,$38,$0C,$40,$00,$20,$66,$0C,$74,$0F,$E2,$4B,$E3,$50,$51,$CA; Table data bytes
	dc.b     $FF,$FA,$36,$00,$51,$C5,$42,$42,$70,$64,$61,$02,$70,$61,$78,$08; Table data bytes
	dc.b     "JDgL"                                ; String literal data
	dc.b     $05,$03,$66,$06,$52,$42,$53,$44,$60,$F2,$4A,$C5,$67,$04,$10,$FC; Table data bytes
	dc.b     $00,$2F,$10,$C0,$10,$82,$06,$10,$00,$30,$08,$98,$00,$03,$51,$C6; Table data bytes
	dc.b     "RBSDg"                               ; String literal data
	dc.b     $08,$05,$03,$67,$04,$50,$C6,$60,$F2,$4A,$06,$67,$10,$10,$FC,$00; Table data bytes
	dc.b     $2D,$10,$C0,$10,$82,$06,$10,$00,$2F,$08,$98,$00,$03,$4A,$44,$67; Table data bytes
	dc.b     $06,$53,$44,$52,$42,$60,$B0,$4E,$75,$30,$01,$02,$40,$00,$38,$67; Table data bytes
	dc.b     $00,$13,$3C,$0C,$40,$00,$08,$67,$00,$13,$34,$7C,$70,$CC,$83,$BC; Table data bytes
	dc.b     $03,$67,$02,$7C,$FF,$E8,$0E,$06,$06,$00,$30,$0C,$40,$00,$20,$66; Table data bytes
	dc.b     $1E,$08,$03,$00,$0D,$67,$00,$13,$16,$08,$03,$00,$0C,$66,$00,$13; Table data bytes
	dc.b     $0E,$74,$07,$E2,$0B,$E3,$10,$51,$CA,$FF,$FA,$16,$00,$60,$08,$08; Table data bytes
	dc.b     $03,$00,$0C,$67,$00,$12,$F8,$08,$03,$00,$0B,$67,$0E,$4A,$86,$6B; Table data bytes
	dc.b     $00,$12,$EC,$10,$FC,$00,$64,$10,$C6,$4E,$75,$51,$C0,$74,$07,$4A; Table data bytes
	dc.b     $42,$6B,$F6,$05,$03,$66,$04,$53,$42,$60,$F4,$4A,$C0,$67,$04,$10; Table data bytes
	dc.b     $FC,$00,$2F,$10,$FC,$00,$66,$10,$FC,$00,$70,$10,$BC,$00,$37,$95; Table data bytes
	dc.b     $18,$51,$C6,$53,$42,$6B,$08,$05,$03,$67,$04,$50,$C6,$60,$F4,$4A; Table data bytes
	dc.b     $06,$67,$12,$10,$FC,$00,$2D,$10,$FC,$00,$66,$10,$FC,$00,$70,$10; Table data bytes
	dc.b     $BC,$00,$36,$95,$18,$4A,$42,$6B,$B0,$53,$42,$60,$B2,$43,$FA,$20; Table data bytes
	dc.b     $90,$02,$40,$0F,$00,$EE,$48,$43,$F1,$00,$00,$10,$D9,$4A,$11,$67; Table data bytes
	dc.b     $02,$10,$D9,$4E,$75,$43,$FA,$20,$98,$02,$40,$00,$0F,$D0,$40,$43; Table data bytes
	dc.b     $F1,$00,$00,$10,$D9,$10,$D9,$4E,$75,$43,$FA,$20,$A4,$02,$40,$00; Table data bytes
	dc.b     $1F,$D0,$40,$D0,$40,$43,$F1,$00,$00,$10,$D9,$4A,$11,$67,$0E,$10; Table data bytes
	dc.b     $D9,$4A,$11,$67,$08,$10,$D9,$4A,$11,$67,$02,$10,$D9,$4E,$75,$30; Table data bytes
	dc.b     $01,$02,$40,$00,$3F,$0C,$40,$00,$39,$63,$04,$51,$C7,$4E,$75,$10; Table data bytes
	dc.b     $FC,$00,$2C,$70,$38,$C0,$41,$E4,$48,$48,$7A,$00,$0A,$30,$3B,$00; Table data bytes
	dc.b     $06,$D1,$97,$4E,$75,$00,$10,$00,$20,$00,$34,$00,$56,$00,$78,$00; Table data bytes
	dc.b     $9A,$00,$CA,$02,$F0,$10,$FC,$00,$64,$70,$07,$C0,$41,$06,$00,$00; Table data bytes
	dc.b     $30,$10,$C0,$4E,$75,$10,$FC,$00,$61,$70,$07,$C0,$41,$06,$00,$00; Table data bytes
	dc.b     $30,$10,$C0,$4E,$75,$10,$FC,$00,$2C,$10,$FC,$00,$28,$10,$FC,$00; Table data bytes
	dc.b     $61,$70,$07,$C0,$41,$06,$00,$00,$30,$10,$C0,$10,$FC,$00,$29,$61; Table data bytes
	dc.b     $00,$04,$0E,$60,$00,$04,$20,$10,$FC,$00,$2C,$10,$FC,$00,$28,$10; Table data bytes
	dc.b     $FC,$00,$61,$70,$07,$C0,$41,$06,$00,$00,$30,$10,$C0,$10,$FC,$00; Table data bytes
	dc.b     $29,$10,$FC,$00,$2B,$61,$00,$03,$E8,$60,$00,$03,$FA,$10,$FC,$00; Table data bytes
	dc.b     $2D,$10,$FC,$00,$28,$70,$07,$C0,$41,$06,$00,$00,$30,$10,$FC,$00; Table data bytes
	dc.b     $61,$10,$C0,$10,$FC,$00,$29,$61,$00,$03,$C6,$60,$00,$03,$D8,$10; Table data bytes
	dc.b     $FC,$00,$28,$30,$15,$61,$00,$04,$2A,$10,$FC,$00,$2C,$10,$FC,$00; Table data bytes
	dc.b     $61,$70,$07,$C0,$41,$06,$00,$00,$30,$10,$C0,$10,$FC,$00,$29,$61; Table data bytes
	dc.b     $00,$03,$9E,$30,$1D,$48,$C0,$D1,$AE,$18,$10,$60,$00,$03,$A8,$08; Table data bytes
	dc.b     $15,$00,$00,$66,$00,$00,$94,$61,$00,$03,$86,$10,$FC,$00,$28,$30; Table data bytes
	dc.b     $15,$61,$00,$03,$BE,$48,$80,$48,$C0,$D1,$AE,$18,$10,$10,$FC,$00; Table data bytes
	dc.b     $2C,$10,$FC,$00,$61,$70,$07,$C0,$41,$06,$00,$00,$30,$10,$C0,$10; Table data bytes
	dc.b     $FC,$00,$2C,$70,$64,$08,$15,$00,$07,$67,$02,$70,$61,$10,$C0,$70; Table data bytes
	dc.b     $70,$C0,$15,$E8,$08,$06,$00,$00,$30,$10,$C0,$48,$E7,$40,$40,$30; Table data bytes
	dc.b     $3C,$00,$F0,$C0,$15,$E4,$08,$43,$EE,$13,$DA,$22,$31,$00,$00,$10; Table data bytes
	dc.b     $FC,$00,$2E,$70,$6C,$08,$15,$00,$03,$66,$04,$70,$77,$48,$C1,$10; Table data bytes
	dc.b     $C0,$70,$06,$C0,$15,$67,$0A,$E2,$08,$10,$FC,$00,$2A,$10,$FB,$00; Table data bytes
	dc.b     $16,$E1,$A9,$D3,$AE,$18,$10,$10,$FC,$00,$29,$4C,$DF,$02,$02,$54; Table data bytes
	dc.b     $4D,$60,$00,$03,$12,$31,$32,$34,$38,$70,$08,$C0,$55,$66,$00,$02; Table data bytes
	dc.b     $EC,$70,$47,$C0,$55,$0C,$00,$00,$44,$64,$00,$02,$E0,$0C,$00,$00; Table data bytes
	dc.b     $04,$67,$00,$02,$D8,$70,$30,$C0,$55,$67,$00,$02,$D0,$3F,$02,$34; Table data bytes
	dc.b     $1D,$10,$FC,$00,$28,$70,$07,$C0,$42,$67,$04,$10,$FC,$00,$5B,$70; Table data bytes
	dc.b     $3F,$C0,$41,$0C,$40,$00,$3B,$66,$58,$70,$30,$C0,$42,$E8,$48,$08; Table data bytes
	dc.b     $02,$00,$07,$67,$16,$61,$00,$01,$1E,$0C,$28,$00,$5B,$FF,$FF,$67; Table data bytes
	dc.b     $04,$10,$FC,$00,$2C,$10,$FC,$00,$7A,$60,$2C,$53,$00,$67,$28,$53; Table data bytes
	dc.b     $00,$67,$0C,$20,$0D,$D0,$9D,$55,$80,$61,$00,$EA,$FE,$60,$14,$30; Table data bytes
	dc.b     $1D,$48,$C0,$D0,$8D,$59,$80,$61,$00,$EA,$F0,$10,$FC,$00,$2E,$10; Table data bytes
	dc.b     $FC,$00,$77,$10,$FC,$00,$2C,$10,$FC,$00,$70,$10,$FC,$00,$63,$60; Table data bytes
	dc.b     ":p0",$C0                             ; String literal data
	dc.b     $42,$E8,$48,$61,$00,$00,$CC,$70,$07,$C0,$41,$08,$02,$00,$07,$66; Table data bytes
	dc.b     $20,$0C,$28,$00,$5B,$FF,$FF,$67,$0C,$0C,$28,$00,$28,$FF,$FF,$67; Table data bytes
	dc.b     $04,$10,$FC,$00,$2C,$10,$FC,$00,$61,$06,$00,$00,$30,$10,$C0,$60; Table data bytes
	dc.b     $06,$4A,$00,$66,$00,$00,$98,$08,$02,$00,$02,$67,$04,$10,$FC,$00; Table data bytes
	dc.b     $5D,$08,$02,$00,$06,$66,$54,$0C,$28,$00,$5B,$FF,$FF,$67,$0C,$0C; Table data bytes
	dc.b     $28,$00,$28,$FF,$FF,$67,$04,$10,$FC,$00,$2C,$70,$64,$4A,$42,$6A; Table data bytes
	dc.b     $02,$70,$61,$10,$C0,$30,$3C,$70,$00,$C0,$42,$E9,$58,$06,$00,$00; Table data bytes
	dc.b     $30,$10,$C0,$10,$FC,$00,$2E,$70,$6C,$08,$02,$00,$0B,$66,$02,$70; Table data bytes
	dc.b     $77,$10,$C0,$30,$3C,$06,$00,$C0,$42,$67,$0A,$EF,$58,$10,$FC,$00; Table data bytes
	dc.b     $2A,$10,$FB,$00,$04,$60,$0C,$31,$32,$34,$38,$30,$3C,$FE,$00,$C0; Table data bytes
	dc.b     "Bf*p"                                ; String literal data
	dc.b     $07,$C0,$42,$67,$0A,$08,$02,$00,$02,$66,$04,$10,$FC,$00,$5D,$70; Table data bytes
	dc.b     $03,$C0,$42,$67,$0C,$0C,$00,$00,$01,$67,$04,$10,$FC,$00,$2C,$61; Table data bytes
	dc.b     $0C,$10,$FC,$00,$29,$34,$1F,$4E,$75,$51,$C7,$60,$F8,$53,$00,$67; Table data bytes
	dc.b     $1A,$53,$00,$67,$08,$20,$1D,$61,$00,$E9,$F8,$4E,$75,$30,$1D,$61; Table data bytes
	dc.b     $00,$E9,$F0,$10,$FC,$00,$2E,$10,$FC,$00,$77,$4E,$75,$70,$07,$C0; Table data bytes
	dc.b     $41,$D0,$40,$48,$7A,$00,$0A,$30,$3B,$00,$06,$D1,$97,$4E,$75,$00; Table data bytes
	dc.b     $10,$00,$2A,$00,$3A,$00,$5C,$00,$EE,$01,$54,$01,$54,$01,$54,$10; Table data bytes
	dc.b     $FC,$00,$28,$70,$00,$30,$1D,$61,$00,$E9,$B8,$10,$FC,$00,$29,$10; Table data bytes
	dc.b     $FC,$00,$2E,$10,$FC,$00,$77,$4E,$75,$10,$FC,$00,$28,$20,$1D,$61; Table data bytes
	dc.b     $00,$E9,$A0,$10,$FC,$00,$29,$4E,$75,$10,$FC,$00,$28,$70,$FE,$D0; Table data bytes
	dc.b     $5D,$48,$C0,$D0,$8D,$61,$00,$E9,$8A,$10,$FC,$00,$2C,$10,$FC,$00; Table data bytes
	dc.b     $70,$10,$FC,$00,$63,$10,$FC,$00,$29,$4E,$75,$08,$15,$00,$00,$66; Table data bytes
	dc.b     $00,$FE,$00,$10,$FC,$00,$28,$30,$15,$48,$80,$48,$C0,$D0,$8D,$2D; Table data bytes
	dc.b     $40,$18,$10,$61,$00,$E9,$5C,$10,$FC,$00,$2C,$10,$FC,$00,$70,$10; Table data bytes
	dc.b     $FC,$00,$63,$10,$FC,$00,$2C,$70,$64,$08,$15,$00,$07,$67,$02,$70; Table data bytes
	dc.b     $61,$10,$C0,$70,$70,$C0,$15,$E8,$08,$06,$00,$00,$30,$10,$C0,$48; Table data bytes
	dc.b     $E7,$40,$40,$30,$3C,$00,$F0,$C0,$15,$E4,$08,$43,$EE,$13,$DA,$22; Table data bytes
	dc.b     $31,$00,$00,$10,$FC,$00,$2E,$70,$6C,$08,$15,$00,$03,$66,$04,$70; Table data bytes
	dc.b     $77,$48,$C1,$10,$C0,$70,$06,$C0,$15,$67,$0A,$E2,$08,$10,$FC,$00; Table data bytes
	dc.b     $2A,$10,$FB,$00,$16,$E1,$A9,$D3,$AE,$18,$10,$10,$FC,$00,$29,$4C; Table data bytes
	dc.b     $DF,$02,$02,$54,$4D,$60,$00,$00,$86,$31,$32,$34,$38,$10,$FC,$00; Table data bytes
	dc.b     $23,$70,$00,$30,$1D,$4A,$2E,$16,$66,$66,$0A,$0C,$40,$00,$FF,$62; Table data bytes
	dc.b     $52,$60,$00,$E8,$CE,$0C,$2E,$00,$01,$16,$66,$66,$04,$60,$00,$E8; Table data bytes
	dc.b     $C2,$0C,$2E,$00,$02,$16,$66,$66,$10,$48,$40,$30,$1D,$60,$00,$E8; Table data bytes
	dc.b     $B2,$0C,$2E,$00,$03,$16,$66,$67,$2A,$0C,$2E,$00,$04,$16,$66,$66; Table data bytes
	dc.b     $0E,$48,$40,$30,$1D,$61,$00,$E8,$6C,$20,$1D,$60,$00,$E8,$6A,$0C; Table data bytes
	dc.b     $2E,$00,$05,$16,$66,$67,$0C,$0C,$2E,$00,$06,$16,$66,$66,$04,$61; Table data bytes
	dc.b     $E0,$60,$E6,$51,$C7,$4E,$75,$2F,$09,$43,$EE,$13,$DA,$70,$07,$C0; Table data bytes
	dc.b     $41,$E5,$48,$2D,$71,$00,$20,$18,$10,$22,$5F,$4E,$75,$08,$2E,$00; Table data bytes
	dc.b     $02,$16,$67,$67,$22,$2F,$08,$20,$2E,$18,$10,$41,$EE,$19,$D8,$10; Table data bytes
	dc.b     $FC,$00,$3B,$4A,$2E,$16,$68,$67,$04,$41,$E8,$00,$0A,$61,$00,$E8; Table data bytes
	dc.b     $14,$50,$EE,$16,$68,$20,$5F,$4E,$75,$2F,$00,$08,$2E,$00,$00,$16; Table data bytes
	dc.b     $67,$67,$0A,$4A,$00,$6A,$06,$44,$00,$10,$FC,$00,$2D,$02,$80,$00; Table data bytes
	dc.b     $00,$00,$FF,$08,$2E,$00,$01,$16,$67,$67,$06,$61,$00,$E8,$98,$60; Table data bytes
	dc.b     $04,$61,$00,$E8,$0E,$20,$1F,$4E,$75,$2F,$00,$08,$2E,$00,$00,$16; Table data bytes
	dc.b     $67,$67,$0A,$4A,$40,$6A,$06,$44,$40,$10,$FC,$00,$2D,$02,$80,$00; Table data bytes
	dc.b     $00,$FF,$FF,$08,$2E,$00,$01,$16,$67,$67,$06,$61,$00,$E8,$68,$60; Table data bytes
	dc.b     $04,$61,$00,$E7,$DE,$20,$1F,$4E,$75,$4E,$75,$61,$00,$E8,$F4,$3D; Table data bytes
	dc.b     $40,$17,$A0,$4E,$75,$51,$EE,$16,$66,$61,$00,$0E,$0C,$41,$FA,$1B; Table data bytes
	dc.b     $FB,$60,$00,$0D,$B6,$1D,$7C,$00,$01,$16,$66,$61,$00,$0D,$FA,$41; Table data bytes
	dc.b     $FA,$1B,$ED,$60,$00,$0D,$A4,$41,$FA,$1B,$E2,$60,$04,$41,$FA,$1B; Table data bytes
	dc.b     $E0,$61,$00,$0D,$96,$60,$00,$0D,$D8,$61,$00,$0D,$6A,$60,$04,$61; Table data bytes
	dc.b     $00,$0D,$36,$81,$6E,$17,$A0,$0C,$1B,$00,$2E,$66,$00,$0C,$C8,$0C; Table data bytes
	dc.b     $1B,$00,$77,$67,$20,$08,$EE,$00,$06,$17,$A1,$0C,$2B,$00,$6C,$FF; Table data bytes
	dc.b     $FF,$67,$4A,$60,$34,$61,$00,$0C,$DC,$0C,$1B,$00,$2E,$66,$2A,$0C; Table data bytes
	dc.b     $1B,$00,$77,$66,$24,$61,$00,$0D,$86,$61,$00,$E8,$6A,$55,$80,$90; Table data bytes
	dc.b     $AE,$17,$9A,$90,$AE,$18,$20,$22,$00,$6A,$02,$46,$81,$0C,$81,$00; Table data bytes
	dc.b     $00,$7F,$FF,$62,$04,$60,$00,$0D,$46,$51,$C7,$4E,$75,$61,$00,$0C; Table data bytes
	dc.b     $A4,$0C,$1B,$00,$2E,$66,$F2,$0C,$1B,$00,$6C,$66,$EC,$61,$00,$0D; Table data bytes
	dc.b     $4E,$61,$00,$E8,$32,$55,$80,$90,$AE,$18,$20,$60,$00,$0D,$30,$61; Table data bytes
	dc.b     $00,$0C,$82,$0C,$1B,$00,$2E,$66,$2A,$70,$62,$90,$1B,$67,$06,$0C; Table data bytes
	dc.b     $00,$00,$EF,$66,$1E,$61,$00,$0D,$26,$61,$00,$E8,$0A,$55,$80,$90; Table data bytes
	dc.b     $AE,$18,$20,$81,$2E,$17,$A1,$67,$0A,$6A,$02,$46,$80,$72,$7F,$B0; Table data bytes
	dc.b     $81,$63,$02,$51,$C7,$4E,$75,$61,$00,$0D,$1E,$60,$00,$0B,$B8,$1D; Table data bytes
	dc.b     $7C,$00,$02,$16,$66,$60,$06,$1D,$7C,$00,$01,$16,$66,$61,$00,$0D; Table data bytes
	dc.b     $08,$60,$00,$0B,$B0,$61,$00,$0B,$B2,$60,$00,$0C,$F4,$0C,$1B,$00; Table data bytes
	dc.b     $23,$66,$00,$0B,$F2,$61,$00,$E7,$D6,$61,$00,$0C,$B2,$41,$FA,$1A; Table data bytes
	dc.b     $DB,$60,$00,$0C,$96,$61,$08,$41,$FA,$1A,$D5,$60,$00,$0C,$8C,$0C; Table data bytes
	dc.b     $1B,$00,$23,$66,$00,$0B,$D0,$61,$00,$E7,$A8,$60,$00,$0C,$90,$30; Table data bytes
	dc.b     $3C,$01,$C0,$61,$00,$0C,$84,$60,$E6,$70,$00,$72,$75,$92,$1B,$67; Table data bytes
	dc.b     $0C,$06,$01,$00,$FE,$66,$00,$0B,$AE,$08,$C0,$00,$0B,$0C,$13,$00; Table data bytes
	dc.b     $6E,$66,$06,$08,$C0,$00,$0A,$52,$4B,$0C,$1B,$00,$2E,$66,$00,$0B; Table data bytes
	dc.b     $96,$72,$62,$92,$1B,$67,$16,$08,$C0,$00,$06,$0C,$01,$00,$EB,$67; Table data bytes
	dc.b     $0C,$0C,$01,$00,$F6,$66,$00,$0B,$7E,$0A,$00,$00,$C0,$61,$00,$0C; Table data bytes
	dc.b     $3A,$61,$00,$0C,$5A,$0C,$1B,$00,$64,$66,$16,$61,$00,$0B,$54,$0C; Table data bytes
	dc.b     $1B,$00,$3A,$66,$00,$0B,$60,$61,$00,$06,$CA,$81,$2E,$17,$A3,$60; Table data bytes
	dc.b     $0C,$53,$4B,$61,$00,$0C,$52,$08,$EE,$00,$00,$17,$A2,$0C,$1B,$00; Table data bytes
	dc.b     $2C,$66,$00,$0B,$42,$61,$00,$06,$AC,$E9,$58,$81,$2E,$17,$A2,$4E; Table data bytes
	dc.b     $75,$51,$C7,$4E,$75,$70,$00,$61,$00,$0B,$F0,$0C,$13,$00,$64,$67; Table data bytes
	dc.b     $16,$0C,$13,$00,$66,$67,$10,$61,$00,$0C,$1E,$0C,$1B,$00,$2C,$66; Table data bytes
	dc.b     $00,$0B,$14,$60,$00,$01,$24,$08,$EE,$00,$0D,$17,$A2,$61,$00,$01; Table data bytes
	dc.b     $1A,$61,$00,$0B,$FC,$70,$38,$C0,$6E,$17,$A0,$67,$00,$0A,$F8,$0C; Table data bytes
	dc.b     $00,$00,$08,$67,$00,$0A,$F0,$0C,$00,$00,$3C,$67,$00,$0A,$E8,$0C; Table data bytes
	dc.b     $00,$00,$20,$66,$18,$12,$2E,$17,$A3,$70,$07,$E2,$09,$E3,$12,$51; Table data bytes
	dc.b     $C8,$FF,$FA,$1D,$42,$17,$A3,$08,$AE,$00,$0C,$17,$A2,$4E,$75,$50; Table data bytes
	dc.b     $C5,$60,$02,$51,$C5,$78,$00,$30,$3C,$80,$00,$61,$00,$0B,$7C,$1D; Table data bytes
	dc.b     $7C,$00,$02,$16,$66,$48,$7A,$00,$66,$0C,$13,$00,$66,$66,$0C,$08; Table data bytes
	dc.b     $EE,$00,$0D,$17,$A2,$61,$0E,$60,$00,$0B,$96,$61,$00,$0B,$9A,$0C; Table data bytes
	dc.b     $1B,$00,$2C,$66,$68,$0C,$1B,$00,$66,$66,$62,$0C,$1B,$00,$70,$66; Table data bytes
	dc.b     $5C,$74,$0C,$0C,$13,$00,$63,$67,$16,$74,$0B,$0C,$13,$00,$73,$67; Table data bytes
	dc.b     $0E,$74,$0A,$0C,$1B,$00,$69,$66,$44,$0C,$13,$00,$61,$66,$3E,$52; Table data bytes
	dc.b     $4B,$0C,$1B,$00,$72,$66,$36,$05,$EE,$17,$A2,$52,$04,$0C,$13,$00; Table data bytes
	dc.b     $2F,$66,$08,$4A,$05,$67,$26,$52,$4B,$60,$BA,$4E,$75,$70,$38,$C0; Table data bytes
	dc.b     $2E,$17,$A1,$66,$06,$0C,$04,$00,$01,$66,$12,$51,$00,$66,$10,$0C; Table data bytes
	dc.b     $04,$00,$01,$66,$08,$08,$2E,$00,$0A,$17,$A2,$66,$02,$51,$C7,$4E; Table data bytes
	dc.b     $75,$0C,$1B,$00,$23,$66,$00,$0A,$1E,$61,$00,$E6,$02,$67,$1E,$0C; Table data bytes
	dc.b     $00,$00,$3F,$62,$00,$0A,$10,$0C,$00,$00,$0B,$65,$00,$0A,$08,$0C; Table data bytes
	dc.b     $00,$00,$0F,$63,$08,$0C,$00,$00,$30,$65,$00,$09,$FA,$00,$40,$5C; Table data bytes
	dc.b     $00,$61,$00,$0A,$BA,$60,$00,$09,$F2,$30,$3C,$D0,$00,$0C,$13,$00; Table data bytes
	dc.b     $64,$66,$18,$52,$4B,$10,$1B,$04,$00,$00,$30,$65,$74,$0C,$00,$00; Table data bytes
	dc.b     $07,$62,$6E,$E9,$08,$08,$C0,$00,$0B,$60,$60,$0C,$1B,$00,$66,$66; Table data bytes
	dc.b     $60,$0C,$1B,$00,$70,$66,$5A,$12,$1B,$04,$01,$00,$30,$65,$52,$0C; Table data bytes
	dc.b     $01,$00,$07,$62,$4C,$76,$07,$96,$01,$07,$C0,$0C,$13,$00,$2C,$67; Table data bytes
	dc.b     $3A,$0C,$1B,$00,$2F,$67,$D4,$0C,$2B,$00,$2D,$FF,$FF,$66,$2C,$0C; Table data bytes
	dc.b     $1B,$00,$66,$66,$2C,$0C,$1B,$00,$70,$66,$26,$14,$1B,$04,$02,$00; Table data bytes
	dc.b     $30,$65,$1E,$0C,$02,$00,$07,$62,$18,$B4,$01,$63,$14,$52,$01,$76; Table data bytes
	dc.b     $07,$96,$01,$07,$C0,$B4,$01,$66,$F4,$60,$C0,$81,$6E,$17,$A2,$4E; Table data bytes
	dc.b     $75,$60,$00,$09,$62,$61,$00,$09,$EE,$60,$04,$61,$00,$09,$BA,$61; Table data bytes
	dc.b     $00,$0A,$18,$60,$04,$61,$00,$09,$7C,$61,$00,$0A,$32,$61,$00,$09; Table data bytes
	dc.b     $2C,$0C,$1B,$00,$2C,$67,$00,$FC,$A2,$51,$C7,$4E,$75,$0C,$1B,$00; Table data bytes
	dc.b     $23,$66,$00,$09,$32,$61,$00,$E5,$4E,$0C,$00,$00,$1F,$62,$00,$09; Table data bytes
	dc.b     $26,$61,$00,$09,$E6,$60,$00,$0A,$18,$61,$00,$09,$AA,$60,$04,$61; Table data bytes
	dc.b     $00,$09,$76,$61,$00,$09,$D4,$60,$04,$61,$00,$09,$38,$61,$00,$09; Table data bytes
	dc.b     $EE,$60,$00,$0A,$04,$61,$00,$09,$C2,$76,$00,$0C,$2B,$00,$2C,$00; Table data bytes
	dc.b     $02,$66,$10,$08,$C3,$00,$0B,$61,$00,$01,$EA,$52,$4B,$61,$00,$09; Table data bytes
	dc.b     $E8,$60,$10,$61,$00,$09,$E2,$0C,$1B,$00,$2C,$66,$00,$08,$D8,$61; Table data bytes
	dc.b     $00,$01,$D2,$3D,$43,$17,$A2,$4E,$75,$61,$00,$09,$CC,$60,$00,$08; Table data bytes
	dc.b     $66,$0C,$13,$00,$23,$66,$00,$08,$BE,$61,$00,$09,$BC,$60,$00,$09; Table data bytes
	dc.b     $B0,$0C,$1B,$00,$23,$66,$00,$08,$AE,$61,$00,$E4,$9A,$67,$00,$08; Table data bytes
	dc.b     $A6,$0C,$00,$00,$08,$62,$00,$08,$9E,$66,$02,$51,$C0,$D0,$00,$81; Table data bytes
	dc.b     $2E,$17,$A0,$60,$00,$09,$8A,$0C,$1B,$00,$23,$66,$1E,$61,$00,$E4; Table data bytes
	dc.b     $76,$67,$00,$08,$82,$0C,$00,$00,$08,$62,$00,$08,$7A,$66,$02,$51; Table data bytes
	dc.b     $C0,$D0,$00,$81,$2E,$17,$A0,$60,$00,$08,$4C,$08,$EE,$00,$05,$17; Table data bytes
	dc.b     $A1,$53,$4B,$61,$00,$08,$14,$60,$00,$08,$3C,$0C,$1B,$00,$23,$66; Table data bytes
	dc.b     $00,$08,$54,$61,$00,$E4,$70,$0C,$00,$00,$0F,$62,$00,$08,$48,$81; Table data bytes
	dc.b     $2E,$17,$A1,$4E,$75,$60,$00,$08,$24,$41,$FA,$17,$2C,$0C,$13,$00; Table data bytes
	dc.b     $61,$67,$10,$08,$EE,$00,$03,$17,$A1,$61,$14,$0C,$1B,$00,$2C,$60; Table data bytes
	dc.b     $00,$07,$FC,$61,$00,$07,$F8,$0C,$1B,$00,$2C,$66,$00,$08,$18,$60; Table data bytes
	dc.b     $00,$08,$C8,$30,$3C,$01,$00,$61,$32,$30,$2E,$17,$A2,$0C,$40,$41; Table data bytes
	dc.b     $00,$67,$00,$00,$0E,$0A,$40,$09,$00,$02,$40,$BB,$FF,$66,$00,$07; Table data bytes
	dc.b     $F6,$4E,$75,$61,$26,$26,$49,$4A,$C7,$67,$0E,$30,$3C,$02,$00,$61; Table data bytes
	dc.b     $00,$08,$A8,$61,$16,$60,$00,$08,$D8,$70,$00,$61,$00,$08,$9C,$61; Table data bytes
	dc.b     $00,$08,$D6,$0C,$1B,$00,$2C,$66,$00,$07,$CC,$41,$FA,$17,$2D,$22; Table data bytes
	dc.b     $4B,$12,$18,$67,$00,$07,$C0,$70,$7F,$C0,$10,$B0,$1B,$66,$06,$4A; Table data bytes
	dc.b     $18,$6A,$F4,$60,$08,$4A,$18,$6A,$FC,$26,$49,$60,$E4,$83,$2E,$17; Table data bytes
	dc.b     $A2,$4E,$75,$12,$1B,$0C,$1B,$00,$63,$66,$10,$70,$03,$41,$FA,$ED; Table data bytes
	dc.b     $C0,$B2,$30,$00,$00,$67,$08,$51,$C8,$FF,$F8,$60,$00,$07,$88,$ED; Table data bytes
	dc.b     $48,$81,$6E,$17,$A0,$4E,$75,$61,$DA,$0C,$1B,$00,$2C,$66,$00,$07; Table data bytes
	dc.b     $76,$0C,$1B,$00,$28,$66,$00,$07,$6E,$61,$00,$07,$42,$0C,$1B,$00; Table data bytes
	dc.b     $29,$66,$00,$07,$62,$4E,$75,$76,$00,$0C,$13,$00,$74,$67,$16,$0C; Table data bytes
	dc.b     $2B,$00,$2C,$00,$02,$66,$0E,$08,$EE,$00,$00,$17,$A1,$61,$44,$52; Table data bytes
	dc.b     $4B,$61,$14,$60,$0C,$61,$10,$0C,$1B,$00,$2C,$66,$00,$07,$38,$61; Table data bytes
	dc.b     $32,$30,$03,$60,$00,$07,$F8,$45,$FA,$16,$2A,$5C,$4A,$4A,$12,$6B; Table data bytes
	dc.b     $00,$00,$1E,$72,$00,$10,$32,$10,$02,$67,$0E,$B0,$33,$10,$00,$66; Table data bytes
	dc.b     $EA,$52,$01,$0C,$01,$00,$04,$66,$EC,$86,$52,$D6,$C1,$4E,$75,$51; Table data bytes
	dc.b     $C7,$4E,$75,$10,$1B,$0C,$00,$00,$64,$67,$0C,$08,$C3,$00,$0F,$0C; Table data bytes
	dc.b     $00,$00,$61,$66,$00,$FF,$EA,$61,$00,$02,$62,$E8,$58,$86,$40,$4E; Table data bytes
	dc.b     $75,$61,$36,$0C,$1B,$00,$2C,$66,$00,$06,$DC,$0C,$1B,$00,$64,$66; Table data bytes
	dc.b     $00,$06,$D4,$76,$00,$61,$E0,$87,$6E,$17,$A2,$4E,$75,$0C,$1B,$00; Table data bytes
	dc.b     $64,$66,$00,$06,$C2,$76,$00,$61,$CE,$0C,$1B,$00,$2C,$66,$00,$06; Table data bytes
	dc.b     $B6,$61,$06,$87,$6E,$17,$A2,$4E,$75,$61,$00,$07,$6E,$61,$00,$07; Table data bytes
	dc.b     $A8,$0C,$1B,$00,$7B,$66,$00,$06,$9E,$61,$26,$02,$40,$00,$3F,$ED; Table data bytes
	dc.b     $48,$34,$00,$0C,$1B,$00,$3A,$66,$00,$06,$8C,$61,$14,$02,$40,$00; Table data bytes
	dc.b     $3F,$80,$42,$0C,$1B,$00,$7D,$66,$00,$06,$7C,$3D,$40,$17,$A2,$4E; Table data bytes
	dc.b     $75,$0C,$13,$00,$64,$67,$16,$61,$00,$E2,$8C,$67,$00,$06,$68,$0C; Table data bytes
	dc.b     $00,$00,$20,$62,$00,$06,$60,$08,$80,$00,$05,$4E,$75,$52,$4B,$10; Table data bytes
	dc.b     $1B,$04,$00,$00,$30,$65,$00,$06,$4E,$0C,$00,$00,$07,$62,$00,$06; Table data bytes
	dc.b     $46,$08,$C0,$00,$05,$4E,$75,$0C,$1B,$00,$23,$66,$00,$06,$38,$60; Table data bytes
	dc.b     $00,$06,$20,$0C,$13,$00,$2D,$66,$2A,$52,$4B,$0C,$1B,$00,$28,$66; Table data bytes
	dc.b     $00,$06,$24,$61,$00,$05,$F8,$41,$FA,$15,$18,$61,$00,$06,$CC,$61; Table data bytes
	dc.b     $00,$05,$BA,$0C,$1B,$00,$29,$66,$00,$06,$0C,$08,$EE,$00,$03,$17; Table data bytes
	dc.b     $A1,$60,$08,$61,$00,$05,$E6,$61,$00,$05,$AA,$0C,$1B,$00,$2C,$66; Table data bytes
	dc.b     $00,$05,$F4,$60,$00,$FA,$1A,$0C,$1B,$00,$28,$66,$00,$05,$E8,$61; Table data bytes
	dc.b     $00,$05,$BC,$41,$FA,$14,$E0,$61,$00,$06,$90,$61,$00,$01,$3C,$E8; Table data bytes
	dc.b     $58,$00,$40,$80,$00,$60,$00,$06,$92,$0C,$2B,$00,$61,$00,$01,$66; Table data bytes
	dc.b     $48,$0C,$1B,$00,$28,$66,$00,$05,$BE,$61,$00,$05,$92,$0C,$1B,$00; Table data bytes
	dc.b     $29,$66,$00,$05,$B2,$72,$00,$0C,$1B,$00,$2B,$67,$04,$53,$4B,$72; Table data bytes
	dc.b     $10,$0C,$1B,$00,$2C,$66,$00,$05,$9E,$83,$2E,$17,$A1,$3F,$2E,$17; Table data bytes
	dc.b     $A0,$61,$00,$06,$94,$70,$3F,$C0,$6E,$17,$A0,$3D,$5F,$17,$A0,$0C; Table data bytes
	dc.b     $40,$00,$39,$66,$00,$05,$80,$4E,$75,$61,$E2,$0C,$1B,$00,$2C,$66; Table data bytes
	dc.b     $00,$05,$74,$0C,$1B,$00,$28,$66,$00,$05,$6C,$61,$00,$05,$40,$0C; Table data bytes
	dc.b     $1B,$00,$29,$66,$00,$05,$60,$72,$08,$0C,$1B,$00,$2B,$67,$02,$72; Table data bytes
	dc.b     $18,$83,$2E,$17,$A1,$4E,$75,$70,$01,$51,$EE,$16,$66,$0C,$13,$00; Table data bytes
	dc.b     $62,$67,$1A,$70,$03,$52,$2E,$16,$66,$0C,$13,$00,$77,$67,$0E,$70; Table data bytes
	dc.b     $02,$52,$2E,$16,$66,$0C,$13,$00,$6C,$66,$00,$05,$2A,$E9,$08,$81; Table data bytes
	dc.b     $2E,$17,$A0,$52,$4B,$61,$00,$06,$06,$61,$00,$06,$1C,$3F,$2E,$17; Table data bytes
	dc.b     $A0,$61,$00,$06,$0C,$32,$2E,$17,$A0,$3D,$5F,$17,$A0,$30,$01,$02; Table data bytes
	dc.b     $40,$00,$07,$EE,$58,$81,$6E,$17,$A0,$02,$41,$00,$38,$E7,$49,$83; Table data bytes
	dc.b     $6E,$17,$A0,$4E,$75,$51,$EE,$16,$66,$61,$00,$05,$EC,$30,$2E,$17; Table data bytes
	dc.b     $A0,$42,$AE,$17,$9E,$02,$40,$00,$3F,$0C,$40,$00,$3C,$66,$00,$04; Table data bytes
	dc.b     $D6,$1D,$6E,$17,$A3,$17,$A1,$60,$00,$04,$7A,$0C,$1B,$00,$23,$66; Table data bytes
	dc.b     $00,$04,$C4,$61,$00,$E0,$A8,$61,$00,$05,$80,$60,$00,$05,$B2,$61; Table data bytes
	dc.b     $22,$34,$00,$0C,$1B,$00,$2C,$66,$00,$04,$AC,$61,$16,$ED,$48,$80; Table data bytes
	dc.b     $42,$61,$00,$05,$66,$60,$00,$05,$98,$0C,$1B,$00,$61,$66,$00,$04; Table data bytes
	dc.b     $96,$60,$08,$0C,$1B,$00,$64,$66,$00,$04,$8C,$10,$1B,$04,$00,$00; Table data bytes
	dc.b     $30,$65,$00,$04,$82,$0C,$00,$00,$07,$62,$00,$04,$7A,$48,$80,$4E; Table data bytes
	dc.b     $75,$0C,$13,$00,$77,$67,$0E,$0C,$13,$00,$6C,$66,$00,$04,$68,$08; Table data bytes
	dc.b     $EE,$00,$09,$17,$A0,$52,$4B,$61,$00,$05,$44,$61,$C6,$48,$40,$0C; Table data bytes
	dc.b     $1B,$00,$3A,$66,$52,$61,$BC,$22,$00,$0C,$1B,$00,$2C,$66,$48,$61; Table data bytes
	dc.b     $B2,$48,$40,$0C,$1B,$00,$3A,$66,$3E,$61,$A8,$ED,$88,$82,$80,$0C; Table data bytes
	dc.b     $1B,$00,$2C,$66,$32,$0C,$1B,$00,$28,$66,$2C,$76,$00,$61,$00,$FD; Table data bytes
	dc.b     $24,$0C,$1B,$00,$29,$66,$20,$0C,$1B,$00,$3A,$66,$1A,$0C,$1B,$00; Table data bytes
	dc.b     $28,$66,$14,$48,$43,$61,$00,$FD,$0C,$0C,$1B,$00,$29,$66,$08,$86; Table data bytes
	dc.b     $81,$20,$03,$60,$00,$04,$D8,$51,$C7,$4E,$75,$36,$3C,$08,$00,$60; Table data bytes
	dc.b     $02,$76,$00,$61,$00,$04,$B4,$61,$00,$04,$EE,$0C,$1B,$00,$2C,$66; Table data bytes
	dc.b     $E6,$61,$00,$FC,$E0,$3D,$43,$17,$A2,$4E,$75,$76,$00,$61,$00,$FC; Table data bytes
	dc.b     $D4,$E9,$5B,$87,$6E,$17,$A0,$4E,$75,$61,$00,$04,$5A,$60,$04,$61; Table data bytes
	dc.b     $00,$04,$26,$61,$00,$04,$84,$60,$04,$61,$00,$03,$E8,$0C,$1B,$00; Table data bytes
	dc.b     $2E,$66,$00,$03,$B2,$10,$1B,$61,$00,$04,$94,$0C,$00,$00,$77,$67; Table data bytes
	dc.b     $00,$F7,$CE,$0C,$00,$00,$6C,$66,$00,$03,$9C,$08,$EE,$00,$00,$17; Table data bytes
	dc.b     $A1,$0C,$1B,$00,$23,$66,$00,$03,$8E,$61,$00,$DF,$5A,$60,$00,$04; Table data bytes
	dc.b     $5E,$61,$00,$03,$B0,$0C,$1B,$00,$20,$66,$00,$03,$7A,$4E,$75,$61; Table data bytes
	dc.b     $00,$FE,$D8,$00,$40,$2C,$00,$61,$16,$60,$00,$04,$64,$61,$00,$03; Table data bytes
	dc.b     $F6,$60,$04,$61,$00,$03,$C2,$0C,$1B,$00,$20,$66,$00,$03,$58,$60; Table data bytes
	dc.b     $00,$04,$18,$70,$00,$60,$F8,$30,$3C,$24,$00,$60,$F2,$30,$3C,$A0; Table data bytes
	dc.b     $00,$61,$EC,$60,$00,$04,$42,$36,$3C,$34,$00,$60,$04,$36,$3C,$30; Table data bytes
	dc.b     $00,$14,$1B,$0C,$13,$00,$66,$66,$1E,$52,$4B,$0C,$1B,$00,$63,$66; Table data bytes
	dc.b     $00,$03,$24,$72,$00,$0C,$02,$00,$73,$67,$24,$72,$01,$0C,$02,$00; Table data bytes
	dc.b     $64,$67,$1C,$60,$00,$03,$10,$72,$10,$70,$23,$90,$02,$67,$0A,$0C; Table data bytes
	dc.b     $00,$00,$BF,$66,$00,$03,$00,$72,$08,$61,$00,$FE,$70,$82,$40,$0C; Table data bytes
	dc.b     $1B,$00,$2C,$66,$00,$02,$F0,$0C,$1B,$00,$23,$66,$00,$02,$E8,$61; Table data bytes
	dc.b     $00,$FE,$5A,$EB,$48,$80,$41,$80,$43,$60,$84,$32,$3C,$20,$10,$70; Table data bytes
	dc.b     $77,$90,$1B,$67,$0A,$08,$C1,$00,$09,$5B,$00,$66,$00,$02,$C8,$61; Table data bytes
	dc.b     $00,$03,$AC,$0C,$1B,$00,$23,$66,$00,$02,$BC,$61,$00,$FE,$2E,$80; Table data bytes
	dc.b     $41,$61,$00,$FF,$5C,$60,$00,$03,$A8,$32,$3C,$81,$10,$61,$D0,$0C; Table data bytes
	dc.b     $1B,$00,$2C,$66,$00,$02,$A0,$0C,$1B,$00,$23,$66,$00,$02,$98,$61; Table data bytes
	dc.b     $00,$FE,$0A,$EC,$58,$67,$00,$02,$8E,$32,$00,$0C,$1B,$00,$2C,$66; Table data bytes
	dc.b     $00,$02,$84,$0C,$1B,$00,$61,$66,$00,$02,$7C,$61,$00,$FD,$EE,$EB; Table data bytes
	dc.b     $58,$80,$41,$81,$6E,$17,$A2,$4E,$75,$30,$3C,$08,$00,$60,$02,$70; Table data bytes
	dc.b     $00,$61,$00,$03,$26,$1D,$7C,$00,$02,$16,$66,$61,$00,$03,$5A,$0C; Table data bytes
	dc.b     $1B,$00,$2C,$66,$00,$02,$50,$61,$00,$FD,$BA,$36,$00,$0C,$1B,$00; Table data bytes
	dc.b     $3A,$66,$00,$02,$42,$61,$00,$FD,$AC,$B6,$00,$67,$00,$02,$38,$60; Table data bytes
	dc.b     $32,$30,$3C,$08,$00,$60,$02,$70,$00,$61,$00,$02,$EE,$1D,$7C,$00; Table data bytes
	dc.b     $02,$16,$66,$61,$00,$03,$22,$0C,$1B,$00,$2C,$66,$00,$02,$18,$61; Table data bytes
	dc.b     $00,$FD,$82,$36,$00,$0C,$1B,$00,$3A,$66,$08,$08,$C3,$00,$0A,$61; Table data bytes
	dc.b     $00,$FD,$72,$E8,$58,$86,$40,$87,$6E,$17,$A2,$4E,$75,$0C,$1B,$00; Table data bytes
	dc.b     $28,$66,$00,$01,$F2,$61,$00,$01,$C6,$41,$FA,$10,$EA,$61,$00,$02; Table data bytes
	dc.b     $9A,$61,$00,$01,$88,$0C,$1B,$00,$29,$66,$00,$01,$DA,$0C,$1B,$00; Table data bytes
	dc.b     $2B,$66,$00,$01,$D2,$4E,$75,$0C,$1B,$00,$2D,$66,$26,$08,$EE,$00; Table data bytes
	dc.b     $03,$17,$A1,$0C,$1B,$00,$28,$66,$16,$61,$00,$01,$92,$41,$FA,$10; Table data bytes
	dc.b     $B2,$61,$00,$02,$66,$61,$00,$01,$54,$0C,$1B,$00,$29,$67,$02,$51; Table data bytes
	dc.b     $C7,$4E,$75,$53,$4B,$61,$00,$01,$84,$60,$00,$01,$48,$0C,$13,$00; Table data bytes
	dc.b     $64,$67,$1E,$61,$00,$02,$92,$30,$2E,$17,$A0,$08,$AE,$00,$05,$17; Table data bytes
	dc.b     $A1,$02,$40,$00,$38,$0C,$40,$00,$28,$66,$00,$01,$7A,$60,$00,$01; Table data bytes
	dc.b     $24,$08,$EE,$00,$07,$17,$A1,$61,$00,$01,$20,$61,$00,$02,$62,$30; Table data bytes
	dc.b     $2E,$17,$A0,$08,$AE,$00,$05,$17,$A1,$02,$40,$00,$38,$0C,$40,$00; Table data bytes
	dc.b     $28,$66,$00,$01,$52,$4E,$75,$70,$00,$61,$00,$02,$0E,$0C,$13,$00; Table data bytes
	dc.b     $64,$67,$1C,$0C,$13,$00,$61,$67,$16,$08,$EE,$00,$0A,$17,$A0,$61; Table data bytes
	dc.b     $00,$02,$36,$0C,$1B,$00,$2C,$66,$00,$01,$2C,$61,$28,$60,$06,$61; Table data bytes
	dc.b     $24,$61,$00,$02,$1C,$70,$38,$C0,$6E,$17,$A0,$0C,$40,$00,$20,$66; Table data bytes
	dc.b     $12,$32,$2E,$17,$A2,$70,$0F,$E2,$49,$E3,$52,$51,$C8,$FF,$FA,$3D; Table data bytes
	dc.b     $42,$17,$A2,$4E,$75,$42,$40,$12,$2B,$00,$01,$04,$01,$00,$30,$65; Table data bytes
	dc.b     $00,$00,$F4,$0C,$01,$00,$07,$62,$00,$00,$EC,$0C,$13,$00,$64,$67; Table data bytes
	dc.b     $0A,$0C,$13,$00,$61,$66,$00,$00,$DE,$50,$01,$54,$4B,$03,$C0,$0C; Table data bytes
	dc.b     $13,$00,$2C,$67,$44,$0C,$1B,$00,$2F,$67,$CC,$0C,$2B,$00,$2D,$FF; Table data bytes
	dc.b     $FF,$66,$36,$14,$2B,$00,$01,$04,$02,$00,$30,$65,$00,$00,$B8,$0C; Table data bytes
	dc.b     $02,$00,$07,$62,$00,$00,$B0,$0C,$13,$00,$64,$67,$0A,$0C,$13,$00; Table data bytes
	dc.b     $61,$66,$00,$00,$A2,$50,$02,$54,$4B,$B4,$01,$63,$00,$00,$98,$52; Table data bytes
	dc.b     $01,$03,$C0,$B4,$01,$66,$F8,$60,$B6,$3D,$40,$17,$A2,$4E,$75,$61; Table data bytes
	dc.b     "8`ba&`Pa0`L`PaN"                     ; String literal data
	dc.b     $0C,$1B,$00,$2C,$66,$70,$60,$00,$FC,$DA,$61,$42,$0C,$1B,$00,$2C; Table data bytes
	dc.b     $66,$64,$60,$00,$F4,$8C,$0C,$1B,$00,$2C,$66,$5A,$0C,$1B,$00,$61; Table data bytes
	dc.b     $67,$0E,$60,$52,$0C,$1B,$00,$2C,$66,$4C,$0C,$1B,$00,$64,$66,$46; Table data bytes
	dc.b     $10,$1B,$04,$00,$00,$30,$65,$3E,$0C,$00,$00,$07,$62,$38,$E1,$48; Table data bytes
	dc.b     $D0,$40,$81,$6E,$17,$A0,$4E,$75,$0C,$1B,$00,$2C,$66,$28,$0C,$1B; Table data bytes
	dc.b     $00,$61,$66,$22,$60,$0C,$0C,$1B,$00,$2C,$66,$1A,$0C,$1B,$00,$64; Table data bytes
	dc.b     $66,$14,$10,$1B,$04,$00,$00,$30,$65,$0C,$0C,$00,$00,$07,$62,$06; Table data bytes
	dc.b     $81,$2E,$17,$A1,$4E,$75               ; Table data bytes
Disasm_ClearExitFlag:
	sf.b     d7
	rts                                                  ; Return from subroutine
	dc.b     $0C,$1B,$00,$2C,$66,$F6,$0C,$1B,$00,$66,$66,$F0,$0C,$1B,$00,$70; Table data bytes
	dc.b     $66,$EA,$10,$1B,$04,$00,$00,$30,$65,$E2,$0C,$00,$00,$07,$62,$DC; Table data bytes
	dc.b     $48,$80,$EF,$48,$81,$6E,$17,$A2,$4E,$75,$42,$40,$41,$FA,$0D,$D0; Table data bytes
	dc.b     $12,$13,$E1,$49,$12,$2B,$00,$01,$4A,$28,$00,$01,$66,$02,$51,$C1; Table data bytes
	dc.b     $B2,$58,$67,$0C,$06,$40,$01,$00,$0C,$40,$10,$00,$66,$E2,$60,$AC; Table data bytes
	dc.b     $52,$4B,$4A,$01,$67,$02,$52,$4B,$81,$6E,$17,$A0,$4E,$75,$70,$7C; Table data bytes
	dc.b     $41,$FA,$0D,$DC,$41,$F0,$00,$00,$2F,$0B,$72,$03,$B1,$0B,$66,$12; Table data bytes
	dc.b     $4A,$10,$57,$C9,$FF,$F8,$0C,$13,$00,$65,$67,$06,$58,$4F,$E4,$48; Table data bytes
	dc.b     "Nu&_Y@j",$D8                         ; String literal data
	dc.b     $60,$00,$FF,$72,$12,$1B,$E1,$49,$12,$1B,$41,$FA,$0D,$8A,$70,$1E; Table data bytes
	dc.b     $B2,$70,$00,$00,$67,$08,$55,$40,$6A,$F6,$60,$00,$FF,$58,$E2,$48; Table data bytes
	dc.b     $4E,$75,$B0,$1B,$66,$00,$FF,$4E,$10,$18,$08,$80,$00,$07,$67,$F2; Table data bytes
	dc.b     $B0,$1B,$66,$00,$FF,$40,$4E,$75,$54,$AE,$17,$9A,$41,$EE,$17,$9E; Table data bytes
	dc.b     $32,$10,$52,$58,$D2,$41,$31,$80,$10,$02,$4E,$75,$41,$EE,$17,$9E; Table data bytes
	dc.b     $32,$10,$54,$58,$D2,$41,$21,$80,$10,$02,$4E,$75,$B7,$EE,$18,$0C; Table data bytes
	dc.b     $62,$00,$FF,$12,$0C,$1B,$00,$20,$67,$F2,$53,$4B,$4E,$75,$0C,$1B; Table data bytes
	dc.b     $00,$2C,$66,$00,$FF,$00,$02,$6E,$FF,$C0,$17,$A0,$0C,$13,$00,$64; Table data bytes
	dc.b     $67,$00,$FE,$D8,$00,$6E,$00,$08,$17,$A0,$0C,$13,$00,$61,$67,$00; Table data bytes
	dc.b     $FE,$BC,$02,$6E,$FF,$C0,$17,$A0,$0C,$13,$00,$28,$66,$2C,$0C,$2B; Table data bytes
	dc.b     $00,$61,$00,$01,$66,$24,$52,$4B,$00,$6E,$00,$10,$17,$A0,$61,$00; Table data bytes
	dc.b     $FE,$9C,$0C,$1B,$00,$29,$66,$00,$FE,$BC,$0C,$13,$00,$2B,$66,$08; Table data bytes
	dc.b     $52,$4B,$00,$6E,$00,$18,$17,$A0,$4E,$75,$0C,$13,$00,$2D,$66,$20; Table data bytes
	dc.b     $0C,$2B,$00,$28,$00,$01,$66,$00,$FE,$9C,$54,$4B,$00,$6E,$00,$20; Table data bytes
	dc.b     $17,$A0,$61,$00,$FE,$68,$0C,$1B,$00,$29,$66,$00,$FE,$88,$4E,$75; Table data bytes
	dc.b     $0C,$13,$00,$23,$66,$6C,$52,$4B,$00,$6E,$00,$3C,$17,$A0,$0C,$13; Table data bytes
	dc.b     $00,$22,$66,$1A,$52,$4B,$70,$00,$72,$04,$0C,$1B,$00,$22,$67,$1E; Table data bytes
	dc.b     $E1,$88,$10,$2B,$FF,$FF,$51,$C9,$FF,$F2,$60,$00,$FE,$58,$0C,$13; Table data bytes
	dc.b     $00,$24,$67,$06,$61,$00,$DA,$9C,$60,$04,$61,$00,$DA,$18,$12,$2E; Table data bytes
	dc.b     $16,$66,$67,$16,$0C,$01,$00,$01,$67,$1A,$0C,$01,$00,$02,$66,$00; Table data bytes
	dc.b     $FE,$34,$48,$40,$61,$18,$48,$40,$60,$14,$0C,$80,$00,$00,$00,$FF; Table data bytes
	dc.b     $62,$00,$FE,$22,$0C,$80,$00,$00,$FF,$FF,$62,$00,$FE,$18,$60,$00; Table data bytes
	dc.b     $FE,$DC,$0C,$1B,$00,$28,$66,$00,$FE,$0C,$51,$C2,$0C,$13,$00,$2D; Table data bytes
	dc.b     $66,$04,$52,$4B,$50,$C2,$3F,$02,$0C,$13,$00,$24,$67,$06,$61,$00; Table data bytes
	dc.b     $DA,$42,$60,$04,$61,$00,$D9,$BE,$34,$1F,$0C,$13,$00,$2C,$66,$00; Table data bytes
	dc.b     $01,$32,$4A,$02,$67,$02,$44,$80,$52,$4B,$0C,$13,$00,$61,$66,$00; Table data bytes
	dc.b     $00,$C4,$2F,$00,$61,$00,$FD,$A6,$20,$1F,$22,$00,$6A,$02,$44,$81; Table data bytes
	dc.b     $0C,$1B,$00,$29,$66,$14,$00,$6E,$00,$28,$17,$A0,$0C,$81,$00,$00; Table data bytes
	dc.b     $FF,$FF,$62,$00,$FD,$B0,$60,$00,$FE,$74,$0C,$2B,$00,$2C,$FF,$FF; Table data bytes
	dc.b     $66,$00,$FD,$A2,$00,$6E,$00,$30,$17,$A0,$0C,$81,$00,$00,$00,$FF; Table data bytes
	dc.b     $62,$00,$FD,$92,$02,$40,$00,$FF,$0C,$1B,$00,$64,$67,$0E,$0C,$2B; Table data bytes
	dc.b     $00,$61,$FF,$FF,$66,$00,$FD,$7E,$08,$C0,$00,$0F,$12,$1B,$04,$01; Table data bytes
	dc.b     $00,$30,$65,$00,$FD,$70,$0C,$01,$00,$07,$62,$00,$FD,$68,$48,$81; Table data bytes
	dc.b     $E8,$59,$80,$41,$0C,$1B,$00,$2E,$66,$00,$FD,$5A,$0C,$1B,$00,$77; Table data bytes
	dc.b     $67,$0E,$0C,$2B,$00,$6C,$FF,$FF,$66,$00,$FD,$4A,$08,$C0,$00,$0B; Table data bytes
	dc.b     $0C,$13,$00,$2A,$66,$22,$52,$4B,$72,$CF,$D2,$1B,$67,$1A,$00,$40; Table data bytes
	dc.b     $02,$00,$53,$01,$67,$12,$0A,$40,$06,$00,$55,$01,$67,$0A,$0A,$40; Table data bytes
	dc.b     $02,$00,$59,$01,$66,$00,$FD,$1E,$0C,$1B,$00,$29,$66,$00,$FD,$16; Table data bytes
	dc.b     $60,$00,$FD,$DA,$0C,$1B,$00,$70,$66,$00,$FD,$0A,$0C,$1B,$00,$63; Table data bytes
	dc.b     $66,$00,$FD,$02,$0C,$1B,$00,$29,$66,$20,$00,$6E,$00,$3A,$17,$A0; Table data bytes
	dc.b     $55,$80,$90,$AE,$17,$9A,$90,$AE,$18,$20,$61,$00,$FD,$B0,$22,$00; Table data bytes
	dc.b     $48,$C1,$B2,$80,$66,$00,$FC,$DE,$4E,$75,$00,$6E,$00,$3B,$17,$A0; Table data bytes
	dc.b     $55,$80,$90,$AE,$17,$9A,$90,$AE,$18,$20,$12,$00,$48,$81,$48,$C1; Table data bytes
	dc.b     $B0,$81,$66,$0A,$0C,$2B,$00,$2C,$FF,$FF,$67,$00,$FF,$28,$51,$C7; Table data bytes
	dc.b     $4E,$75,$0C,$1B,$00,$29,$66,$00,$FC,$AC,$0C,$13,$00,$2E,$67,$12; Table data bytes
	dc.b     $00,$6E,$00,$39,$17,$A0,$48,$40,$61,$00,$FD,$62,$48,$40,$60,$00; Table data bytes
	dc.b     $FD,$5C,$52,$4B,$0C,$1B,$00,$77,$66,$00,$FC,$8A,$00,$6E,$00,$38; Table data bytes
	dc.b     $17,$A0,$0C,$80,$00,$00,$FF,$FF,$62,$00,$FC,$7A,$60,$00,$FD,$3E; Table data bytes
	dc.b     $2D                                   ; Table data bytes
; ============================================================================
; Data Block: Str_VersionGreeting
; Purpose   : Greeting banner string containing "BeerMon V0.45".
; ============================================================================
Str_VersionGreeting:
	dc.b     "BeerMon V0.45  68",$B0               ; String literal data
	dc.b     $30,$AC,$20,$47,$66,$78,$4D,$65,$6D,$AC,$20,$6D,$6F,$64,$65,$2C; Table data bytes
	dc.b     " morbid versio",$EE                  ; String literal data
; ============================================================================
; Data Block: Str_NoMmu
; Purpose   : String literal "NoMMU" used for CPU features display.
; ============================================================================
Str_NoMmu:
	dc.b     "NoMM",$D5                            ; String literal data
	dc.b     "6885",$B1                            ; String literal data
	dc.b     "(MMU",$A9                            ; String literal data
	dc.b     "(MMU",$A9                            ; String literal data
; ============================================================================
; Data Block: Str_NoFpu
; Purpose   : String literal "NoFPU" used for FPU status display.
; ============================================================================
Str_NoFpu:
	dc.b     "NoFP",$D5                            ; String literal data
	dc.b     "6888",$B1                            ; String literal data
	dc.b     "6888",$B2                            ; String literal data
	dc.b     $28                                   ; Table data bytes
; ============================================================================
; Data Block: Str_Fpu
; Purpose   : String literal "FPU" used for FPU status display.
; ============================================================================
Str_Fpu:
	dc.b     "FPU",$A9                             ; String literal data
	dc.b     "512",$CB                             ; String literal data
	dc.b     "1 M",$C2                             ; String literal data
	dc.b     "1.5",$CD                             ; String literal data
	dc.b     "2 M",$C2                             ; String literal data
; ============================================================================
; Data Block: Str_Mutilating
; Purpose   : String literal "mutilating" used for disk display.
; ============================================================================
Str_Mutilating:
	dc.b     "mutilatin",$E7                       ; String literal data
; ============================================================================
; Data Block: Str_DeepFrost
; Purpose   : String literal "deep frost" used for disk display.
; ============================================================================
Str_DeepFrost:
	dc.b     "deep fros",$F4                       ; String literal data
; ============================================================================
; Data Block: Str_Track
; Purpose   : String literal ": track" used for disk status display.
; ============================================================================
Str_Track:
	dc.b     ": track",$A0                         ; String literal data
	dc.b     " head",$A0                           ; String literal data
; ============================================================================
; Data Block: Str_Sector
; Purpose   : String literal " sector" used for disk status display.
; ============================================================================
Str_Sector:
	dc.b     " sector",$A0                         ; String literal data
; ============================================================================
; Data Block: Str_Block
; Purpose   : String literal " block" used for disk status display.
; ============================================================================
Str_Block:
	dc.b     " block",$A0                          ; String literal data
; ============================================================================
; Data Block: Str_DiskInDrive
; Purpose   : String literal " Disk in drive DFn: is" used for disk status.
; ============================================================================
Str_DiskInDrive:
	dc.b     " Disk in drive DFn: is",$A0          ; String literal data
; ============================================================================
; Data Block: Str_NotPresent
; Purpose   : String literal "not present" used for disk status.
; ============================================================================
Str_NotPresent:
	dc.b     "not presen",$F4                      ; String literal data
; ============================================================================
; Data Block: Str_NotDosDisk
; Purpose   : String literal "not a dos disk" used for disk status.
; ============================================================================
Str_NotDosDisk:
	dc.b     "not a dos dis",$EB                   ; String literal data
; ============================================================================
; Data Block: Str_NotValidated
; Purpose   : String literal "not validated" used for disk status.
; ============================================================================
Str_NotValidated:
	dc.b     "not validate",$E4                    ; String literal data
; ============================================================================
; Data Block: Str_Filesystem
; Purpose   : String literal "Filesystem:" used for disk status.
; ============================================================================
Str_Filesystem:
	dc.b     "Filesystem:",$A0                     ; String literal data
	dc.b     "not international nFS,",$A0          ; String literal data
; ============================================================================
; Data Block: Str_BadChecksum
; Purpose   : String literal "without correct checksum" used for disk status.
; ============================================================================
Str_BadChecksum:
	dc.b     "without correct checksu",$ED         ; String literal data
; ============================================================================
; Data Block: Str_WriteProtected
; Purpose   : String literal "writeprotected" used for disk status.
; ============================================================================
Str_WriteProtected:
	dc.b     "writeprotecte",$E4                   ; String literal data
; ============================================================================
; Data Block: Str_Logged
; Purpose   : String literal "logged" used for disk status.
; ============================================================================
Str_Logged:
	dc.b     "logge",$E4                           ; String literal data
; ============================================================================
; Data Block: Str_NotMounted
; Purpose   : String literal "not mounted" used for disk status.
; ============================================================================
Str_NotMounted:
	dc.b     "not mounte",$E4                      ; String literal data
	dc.b     "Mem:",$A0                            ; String literal data
; ============================================================================
; Data Block: Table_Scr
; Purpose   : Bytes "Sc\xf2" used for screen/disk labels.
; ============================================================================
Table_Scr:
	dc.b     $53,$63,$F2                           ; Table data bytes
; ============================================================================
; Data Block: Str_Abs
; Purpose   : String literal "(ABS)" used for address space display.
; ============================================================================
Str_Abs:
	dc.b     "(ABS)",$A0                           ; String literal data
	dc.b     "(SYS)",$A0                           ; String literal data
; ============================================================================
; Data Block: Str_Code
; Purpose   : String literal " Code" used for disassembly display.
; ============================================================================
Str_Code:
	dc.b     " Code",$A0                           ; String literal data
; ============================================================================
; Data Block: Str_Ex
; Purpose   : String literal " Ex" used for exceptions.
; ============================================================================
Str_Ex:
	dc.b     " Ex",$E7                             ; String literal data
; ============================================================================
; Data Block: Str_NotAvailable
; Purpose   : String literal " not available" used for status display.
; ============================================================================
Str_NotAvailable:
	dc.b     " not availabl",$E5                   ; String literal data
	dc.b     " filled with",$A0                    ; String literal data
	dc.b     " exored with",$A0                    ; String literal data
	dc.b     "function aborted at",$A0             ; String literal data
; ============================================================================
; Data Block: Str_ObjectCreated
; Purpose   : String literal "object created:" used for console command feedback.
; ============================================================================
Str_ObjectCreated:
	dc.b     "object created:",$A0                 ; String literal data
	dc.b     "cannot decrunch dat",$E1             ; String literal data
	dc.b     "decrunched data:",$A0                ; String literal data
	dc.b     "cannot crunch dat",$E1               ; String literal data
	dc.b     "crunch aborte",$E4                   ; String literal data
	dc.b     ", crunched data:",$A0                ; String literal data
	dc.b     "to go",$BA                           ; String literal data
	dc.b     " gained",$BA                         ; String literal data
	dc.b     "You don"                             ; String literal data
	dc.b     $27,$74,$20,$68,$61,$76,$65,$20,$61,$20,$4D,$4D,$55,$A1,$59,$6F; Table data bytes
	dc.b     "u don"                               ; String literal data
	dc.b     $27,$74,$20,$68,$61,$76,$65,$20,$61,$20,$36,$38,$38,$35,$31,$20; Table data bytes
	dc.b     "MMU",$A1                             ; String literal data
	dc.b     "68040 MMU is not supported yet",$A1  ; String literal data
; ============================================================================
; Data Block: Str_Breakpoint
; Purpose   : String literal "Breakpoint" used for breakpoint status messages.
; ============================================================================
Str_Breakpoint:
	dc.b     "Breakpoint",$A0                      ; String literal data
	dc.b     "not in RAM",$A1                      ; String literal data
	dc.b     "exist",$F3                           ; String literal data
	dc.b     "not foun",$E4                        ; String literal data
	dc.b     $73,$65,$F4,$72,$65,$6D,$6F,$76,$65,$E4,$62,$75,$66,$66,$65,$72; Table data bytes
	dc.b     " ful",$EC                            ; String literal data
	dc.b     "buffer cleare",$E4                   ; String literal data
; ============================================================================
; Data Block: Str_OldChksum
; Purpose   : String literal "old chksum:" used for checksum verification.
; ============================================================================
Str_OldChksum:
	dc.b     "old chksum:",$A0                     ; String literal data
; ============================================================================
; Data Block: Str_NewChksum
; Purpose   : String literal " new chksum:" used for checksum verification.
; ============================================================================
Str_NewChksum:
	dc.b     " new chksum:",$A0                    ; String literal data
; ============================================================================
; Data Block: Str_NoKickstart
; Purpose   : String literal "No Kickstart" warning string.
; ============================================================================
Str_NoKickstart:
	dc.b     "No Kickstart",$A1                    ; String literal data
; ============================================================================
; Data Block: Str_NoMegadriveRom
; Purpose   : String literal "No Megadrive ROM" warning string.
; ============================================================================
Str_NoMegadriveRom:
	dc.b     "No Megadrive ROM",$A1                ; String literal data
; ============================================================================
; Data Block: Str_InvalidHeader
; Purpose   : String literal "Invalid header" warning string.
; ============================================================================
Str_InvalidHeader:
	dc.b     "Invalid heade",$F2                   ; String literal data
; ============================================================================
; Data Block: Str_CurrentAddress
; Purpose   : String literal "Current address" used for console displays.
; ============================================================================
Str_CurrentAddress:
	dc.b     "Current address",$A0                 ; String literal data
; ============================================================================
; Data Block: Str_BlocksToGo
; Purpose   : String literal ", blocks to go" used for copy/disk progress.
; ============================================================================
Str_BlocksToGo:
	dc.b     ", blocks to go",$A0                  ; String literal data
; ============================================================================
; Data Block: Str_ConversionComplete
; Purpose   : String literal "Conversion complete" progress message.
; ============================================================================
Str_ConversionComplete:
	dc.b     "Conversion complete",$E4             ; String literal data
; ============================================================================
; Data Block: Str_TransferAborted
; Purpose   : String literal "Transfer aborted" progress message.
; ============================================================================
Str_TransferAborted:
	dc.b     "Transfer aborte",$E4                 ; String literal data
; ============================================================================
; Data Block: Str_TransferComplete
; Purpose   : String literal "Transfer complete" progress message.
; ============================================================================
Str_TransferComplete:
	dc.b     "Transfer complete",$E4               ; String literal data
; ============================================================================
; Data Block: Str_TransferTimeout
; Purpose   : String literal "Transfer timeout" progress message.
; ============================================================================
Str_TransferTimeout:
	dc.b     "Transfer timeou",$F4                 ; String literal data
; ============================================================================
; Data Block: Str_Name
; Purpose   : String literal "Name" header string.
; ============================================================================
Str_Name:
	dc.b     "Name",$BA                            ; String literal data
; ============================================================================
; Data Block: Str_KbRom
; Purpose   : String literal "KB ROM," details string.
; ============================================================================
Str_KbRom:
	dc.b     "KB ROM,",$A0                         ; String literal data
; ============================================================================
; Data Block: Str_BackedUp
; Purpose   : String literal " backed up" details string.
; ============================================================================
Str_BackedUp:
	dc.b     " backed up"                          ; String literal data
; ============================================================================
; Data Block: Str_Ram
; Purpose   : String literal " RAM," details string.
; ============================================================================
Str_Ram:
	dc.b     " RAM,",$A0                           ; String literal data
; ============================================================================
; Data Block: Str_Manufacturer
; Purpose   : String literal "manu" details string.
; ============================================================================
Str_Manufacturer:
	dc.b     "manu",$BA                            ; String literal data
	dc.b     ", v",$BA                             ; String literal data
; ============================================================================
; Data Block: Str_ModeBitmapIs
; Purpose   : String literal "Mode:nD, Bitmap is" disk view string.
; ============================================================================
Str_ModeBitmapIs:
	dc.b     "Mode:nD, Bitmap is",$A0              ; String literal data
	dc.b     "invalid ",$A8                        ; String literal data
; ============================================================================
; Data Block: Str_Sync
; Purpose   : String literal "Sync:" details string.
; ============================================================================
Str_Sync:
	dc.b     "Sync:",$A0                           ; String literal data
; ============================================================================
; Data Block: Str_Invalid
; Purpose   : String literal " (invalid" details string.
; ============================================================================
Str_Invalid:
	dc.b     " (invalid",$A9                       ; String literal data
; ============================================================================
; Data Block: Str_Volume
; Purpose   : String literal "Volume: " disk view string.
; ============================================================================
Str_Volume:
	dc.b     "Volume: ",$A2                        ; String literal data
; ============================================================================
; Data Block: Str_Dir
; Purpose   : String literal "(Dir" details string.
; ============================================================================
Str_Dir:
	dc.b     "(Dir",$A9                            ; String literal data
; ============================================================================
; Data Block: Str_Dirlink
; Purpose   : String literal "dirlink:  " details string.
; ============================================================================
Str_Dirlink:
	dc.b     "dirlink:  ",$A2                      ; String literal data
; ============================================================================
; Data Block: Str_Hardlink
; Purpose   : String literal "hardlink: " details string.
; ============================================================================
Str_Hardlink:
	dc.b     "hardlink: ",$A2                      ; String literal data
; ============================================================================
; Data Block: Str_UsedBlocks
; Purpose   : String literal " used blocks," details string.
; ============================================================================
Str_UsedBlocks:
	dc.b     " used blocks,",$A0                   ; String literal data
; ============================================================================
; Data Block: Str_FreeBlocks
; Purpose   : String literal " free block" details string.
; ============================================================================
Str_FreeBlocks:
	dc.b     " free block",$F3                     ; String literal data
; ============================================================================
; Data Block: Str_FreeBytes
; Purpose   : String literal " free byte" details string.
; ============================================================================
Str_FreeBytes:
	dc.b     " free byte",$F3                      ; String literal data
	dc.b     "saving: ",$A2                        ; String literal data
	dc.b     "loading: ",$A2                       ; String literal data
	dc.b     "typing: ",$A2                        ; String literal data
	dc.b     "read error ",$A8                     ; String literal data
	dc.b     "verify error ",$A8                   ; String literal data
; ============================================================================
; Data Block: Str_RetryIgnoreAbort
; Purpose   : String literal "(r)etry, (i)gnore, (a)bor" user prompt.
; ============================================================================
Str_RetryIgnoreAbort:
	dc.b     "(r)etry, (i)gnore, (a)bor",$F4       ; String literal data
; ============================================================================
; Data Block: Str_SeekError
; Purpose   : String literal "seek error (30), track 0 not foun" message.
; ============================================================================
Str_SeekError:
	dc.b     "seek error (30), track 0 not foun",$E4; String literal data
	dc.b     "bad bitma",$F0                       ; String literal data
; ============================================================================
; Data Block: Str_DiskFull
; Purpose   : String literal "disk full" error message.
; ============================================================================
Str_DiskFull:
	dc.b     "disk ful",$EC                        ; String literal data
	dc.b     "not enough free spac",$E5            ; String literal data
	dc.b     "directory not empt",$F9              ; String literal data
	dc.b     "directory exist",$F3                 ; String literal data
	dc.b     "directory is a fil",$E5              ; String literal data
	dc.b     "directory not foun",$E4              ; String literal data
	dc.b     "file exist",$F3                      ; String literal data
	dc.b     "file is a director",$F9              ; String literal data
	dc.b     "file not foun",$E4                   ; String literal data
; ============================================================================
; Data Block: Str_FormattingTrack
; Purpose   : String literal "Formatting track nn head " progress message.
; ============================================================================
Str_FormattingTrack:
	dc.b     "Formatting track nn head ",$B0       ; String literal data
; ============================================================================
; Data Block: Str_FormattingComplete
; Purpose   : String literal "Formatting complete" progress message.
; ============================================================================
Str_FormattingComplete:
	dc.b     "Formatting complete",$E4             ; String literal data
; ============================================================================
; Data Block: Str_FormattingAborted
; Purpose   : String literal "Formatting aborted" progress message.
; ============================================================================
Str_FormattingAborted:
	dc.b     "Formatting aborte",$E4               ; String literal data
; ============================================================================
; Data Block: Str_DiskInstalled
; Purpose   : String literal "disk installed" progress message.
; ============================================================================
Str_DiskInstalled:
	dc.b     "disk installe",$E4                   ; String literal data
	dc.b     "Active keymap: us",$E1               ; String literal data
	dc.b     "germa",$EE                           ; String literal data
; ============================================================================
; Data Block: Str_Overflow
; Purpose   : String literal "Overflow" error message.
; ============================================================================
Str_Overflow:
	dc.b     "Overflo",$F7                         ; String literal data
	dc.b     "Printer",$A0                         ; String literal data
	dc.b     "Verify",$A0                          ; String literal data
; ============================================================================
; Data Block: Str_SoundAddress
; Purpose   : String literal "Soundaddress" header string.
; ============================================================================
Str_SoundAddress:
	dc.b     "Soundaddress",$A0                    ; String literal data
	dc.b     " lower     first     upper     size    attr pri      nam",$E5; String literal data
	dc.b     "address                                              nam",$E5; String literal data
	dc.b     "address                                              nam",$E5; String literal data
	dc.b     "address   open  ver   rev   nsize psize chksum       nam",$E5; String literal data
	dc.b     "address   flag  sigbit sigtask                       nam",$E5; String literal data
	dc.b     "address   type     pri state   splower   size  used  nam",$E5; String literal data
	dc.b     "address   type      pri                nam",$E5; String literal data
	dc.b     "exec lists corrup",$F4               ; String literal data
; ============================================================================
; Data Block: Str_BoardHeader
; Purpose   : String literal "board    type address-range       size flags..." header.
; ============================================================================
Str_BoardHeader:
	dc.b     "board    type address-range       size flags product manu  serialnum romoffse",$F4; String literal data
; ============================================================================
; Data Block: Str_NoBoardsFound
; Purpose   : String literal "no unconfigured boards found" message.
; ============================================================================
Str_NoBoardsFound:
	dc.b     "no unconfigured boards found",$A1    ; String literal data
; ============================================================================
; Data Block: Str_Unknown
; Purpose   : String literal "unknown" details string.
; ============================================================================
Str_Unknown:
	dc.b     "unknow",$EE                          ; String literal data
; ============================================================================
; Data Block: Str_ZorroI
; Purpose   : String literal "zorro-I" details string.
; ============================================================================
Str_ZorroI:
	dc.b     "zorro-I",$C9                         ; String literal data
; ============================================================================
; Data Block: Str_ZorroII
; Purpose   : String literal "zorro-II" details string.
; ============================================================================
Str_ZorroII:
	dc.b     "zorro-II",$C9                        ; String literal data
	dc.b     "Page Detect:nnn Burst:nnn Wrap:nnn Chips:nnnnnnn Refresh Rate:nnn Version",$BA; String literal data
	dc.b     "Timeout",$BA                         ; String literal data
	dc.b     "disable",$E4                         ; String literal data
	dc.b     "DSAC",$CB                            ; String literal data
	dc.b     "BER",$D2                             ; String literal data
	dc.b     " Keyboard Reset:",$EF                ; String literal data
	dc.b     " ID",$BA                             ; String literal data
	dc.b     "reserve",$E4                         ; String literal data
; ============================================================================
; Data Block: Str_MonthsTable
; Purpose   : String literal lookup table of abbreviated months Jan-Dec.
; ============================================================================
Str_MonthsTable:
	dc.b     "JanFebMarAprMayJunJulAugSepOctNovDec"; String literal data
; ============================================================================
; Data Block: Str_ExceptionBusError
; Purpose   : Bus Error or Address Error exception details.
; ============================================================================
Str_ExceptionBusError:
	dc.b     $3E,$80,$42,$55,$53,$20,$45,$52,$52,$4F,$52,$87,$41,$44,$44,$52; Table data bytes
	dc.b     "ESS ERROR: INSTRUCTION $     ACCESSE",$C4; String literal data
	dc.b     "ILLEGAL"                             ; String literal data
	dc.b     $81,$44,$49,$56,$49,$53,$49,$4F,$4E,$20,$42,$59,$20,$5A,$45,$52; Table data bytes
	dc.b     $CF,$43,$48,$4B,$81,$54,$52,$41,$50,$56,$81,$50,$52,$49,$56,$49; Table data bytes
	dc.b     "LEGE"                                ; String literal data
	dc.b     $84,$54,$52,$41,$43,$45,$20,$4D,$4F,$44,$C5,$4C,$49,$4E,$45,$2D; Table data bytes
	dc.b     $41,$83,$4C,$49,$4E,$45,$2D,$46,$83,$28,$24,$33,$30,$29,$88,$50; Table data bytes
	dc.b     "ROTOCOLL"                            ; String literal data
	dc.b     $84,$46,$4F,$52,$4D,$41,$54,$20,$45,$52,$52,$4F,$52,$87,$55,$4E; Table data bytes
	dc.b     "INITIALISED"                         ; String literal data
	dc.b     $82,$28,$24,$34,$30,$29,$88,$28,$24,$34,$34,$29,$88,$28,$24,$34; Table data bytes
	dc.b     $38,$29,$88,$28,$24,$34,$43,$29,$88,$28,$24,$35,$30,$29,$88,$28; Table data bytes
	dc.b     "$54)"                                ; String literal data
	dc.b     $88,$28,$24,$35,$38,$29,$88,$28,$24,$35,$43,$29,$88,$53,$50,$55; Table data bytes
	dc.b     "RIOUS"                               ; String literal data
	dc.b     $82,$4C,$45,$56,$45,$4C,$20,$31,$82,$4C,$45,$56,$45,$4C,$20,$32; Table data bytes
	dc.b     $82,$4C,$45,$56,$45,$4C,$20,$33,$82,$4C,$45,$56,$45,$4C,$20,$34; Table data bytes
	dc.b     $82,$4C,$45,$56,$45,$4C,$20,$35,$82,$4C,$45,$56,$45,$4C,$20,$36; Table data bytes
	dc.b     $82,$4C,$45,$56,$45,$4C,$20,$37,$82,$85,$85,$85,$85,$85,$85,$85; Table data bytes
	dc.b     $85,$85,$85,$85,$85,$85,$85,$85,$85,$42,$52,$41,$4E,$43,$48,$2F; Table data bytes
	dc.b     "UNORDERED"                           ; String literal data
	dc.b     $86,$49,$4E,$45,$58,$41,$43,$54,$20,$52,$45,$53,$55,$4C,$54,$86; Table data bytes
	dc.b     "DIVISION BY ZERO"                    ; String literal data
	dc.b     $86,$55,$4E,$44,$45,$52,$46,$4C,$4F,$57,$86,$4F,$50,$45,$52,$41; Table data bytes
	dc.b     "ND ERROR"                            ; String literal data
	dc.b     $86,$4F,$56,$45,$52,$46,$4C,$4F,$57,$86,$53,$49,$47,$4E,$41,$4C; Table data bytes
	dc.b     " NAN"                                ; String literal data
	dc.b     $86,$55,$4E,$49,$4D,$50,$4C,$45,$4D,$45,$4E,$54,$45,$44,$20,$44; Table data bytes
	dc.b     "ATA TYPE"                            ; String literal data
	dc.b     $86,$4D,$4D,$55,$20,$53,$45,$54,$55,$50,$87,$36,$38,$38,$35,$31; Table data bytes
	dc.b     $5F,$31,$87,$36,$38,$38,$35,$31,$5F,$32,$87,$28,$24,$45,$43,$29; Table data bytes
	dc.b     $88,$28,$24,$46,$30,$29,$88,$28,$24,$46,$34,$29,$88,$28,$24,$46; Table data bytes
	dc.b     $38,$29,$88,$28,$24,$46,$43,$29,$88   ; Table data bytes
; ============================================================================
; Data Block: Str_ExceptionInstruction
; Purpose   : Instruction or Interrupt exception details.
; ============================================================================
Str_ExceptionInstruction:
	dc.b     $08,$80,$20,$49,$4E,$53,$54,$52,$55,$43,$54,$49,$4F,$CE,$20,$49; Table data bytes
	dc.b     "NTERRUP",$D4                         ; String literal data
	dc.b     " EMULATIO",$CE                       ; String literal data
	dc.b     " VIOLATIO",$CE                       ; String literal data
	dc.b     "TRAP INSTRUCTIO",$CE                 ; String literal data
	dc.b     " FPU EXCEPTIO",$CE                   ; String literal data
	dc.b     " EXCEPTIO",$CE                       ; String literal data
	dc.b     " RESERVE",$C4                        ; String literal data
	dc.b     "Mov",$E5                             ; String literal data
	dc.b     "Ski",$F0                             ; String literal data
	dc.b     "Wai",$F4                             ; String literal data
	dc.b     "EndLis",$F4                          ; String literal data
	dc.b     "dc.",$EC                             ; String literal data
	dc.b     $00,$74,$00,$66,$00,$68,$69,$6C,$73,$63,$63,$63,$73,$6E,$65,$65; Table data bytes
	dc.b     "qvcvsplmigeltgtlebsbclslcssscasacwswcisicgsgccsccf"; String literal data
	dc.b     $00,$00,$00,$65,$71,$00,$00,$6F,$67,$74,$00,$6F,$67,$65,$00,$6F; Table data bytes
	dc.b     $6C,$74,$00,$6F,$6C,$65,$00,$6F,$67,$6C,$00,$6F,$72,$00,$00,$75; Table data bytes
	dc.b     $6E,$00,$00,$75,$65,$71,$00,$75,$67,$74,$00,$75,$67,$65,$00,$75; Table data bytes
	dc.b     $6C,$74,$00,$75,$6C,$65,$00,$6E,$65,$00,$00,$74,$00,$00,$00,$73; Table data bytes
	dc.b     $66,$00,$00,$73,$65,$71,$00,$67,$74,$00,$00,$67,$65,$00,$00,$6C; Table data bytes
	dc.b     $74,$00,$00,$6C,$65,$00,$00,$67,$6C,$00,$00,$67,$6C,$65,$00,$6E; Table data bytes
	dc.b     "glengl"                              ; String literal data
	dc.b     $00,$6E,$6C,$65,$00,$6E,$6C,$74,$00,$6E,$67,$65,$00,$6E,$67,$74; Table data bytes
	dc.b     $00,$73,$6E,$65,$00,$73,$74,$00,$00,$31,$C5,$50,$E9,$4C,$6F,$67; Table data bytes
	dc.b     "10(2",$A9                            ; String literal data
	dc.b     $E5,$4C,$6F,$67,$32,$28,$65,$A9,$4C,$6F,$67,$31,$30,$28,$65,$A9; Table data bytes
	dc.b     $30,$2E,$B0,$6C,$6E,$28,$32,$A9,$6C,$6E,$28,$31,$30,$A9,$B1,$31; Table data bytes
	dc.b     $B0,$31,$30,$B0,$75,$73,$F0,$2C,$63,$63,$F2,$2C,$73,$F2,$29,$2C; Table data bytes
	dc.b     $2D,$A8,$29,$2B,$2C,$A8,$08,$07,$73,$72,$70,$00,$08,$06,$75,$72; Table data bytes
	dc.b     $70,$00,$08,$05,$6D,$6D,$75,$72,$08,$04,$69,$73,$70,$00,$08,$03; Table data bytes
	dc.b     $6D,$73,$70,$00,$08,$02,$63,$61,$61,$72,$08,$01,$76,$62,$72,$00; Table data bytes
	dc.b     $08,$00,$75,$73,$70,$00,$00,$07,$64,$74,$74,$31,$00,$06,$64,$74; Table data bytes
	dc.b     $74,$30,$00,$05,$69,$74,$74,$31,$00,$04,$69,$74,$74,$30,$00,$03; Table data bytes
	dc.b     $74,$63,$00,$00,$00,$02,$63,$61,$63,$72,$00,$01,$64,$66,$63,$00; Table data bytes
	dc.b     $00,$00,$73,$66,$63,$00,$80,$08,$74,$74,$B0,$0C,$74,$74,$B1,$40; Table data bytes
	dc.b     $74,$E3,$44,$64,$72,$F0,$48,$73,$72,$F0,$4C,$63,$72,$F0,$50,$63; Table data bytes
	dc.b     $61,$EC,$58,$73,$63,$E3,$5C,$61,$E3,$60,$6D,$6D,$75,$73,$F2,$60; Table data bytes
	dc.b     $70,$73,$F2,$64,$70,$63,$73,$F2,$AC,$76,$61,$EC,$00,$2A,$62,$6C; Table data bytes
	dc.b     $77,$03,$00,$02,$01,$64,$63,$2E,$62,$A0,$68,$6F,$6C,$79,$20,$68; Table data bytes
	dc.b     "ell,death to us,god is slaughtered,drink his bloodUnknow",$EE; String literal data
	dc.b     "Tas",$EB                             ; String literal data
	dc.b     "Interpt",$AE                         ; String literal data
	dc.b     "Devic",$E5                           ; String literal data
	dc.b     "MsgPor",$F4                          ; String literal data
	dc.b     "Messag",$E5                          ; String literal data
	dc.b     "FreeMs",$E7                          ; String literal data
	dc.b     "ReplyMs",$E7                         ; String literal data
	dc.b     "Resourc",$E5                         ; String literal data
	dc.b     "Librar",$F9                          ; String literal data
	dc.b     "Memor",$F9                           ; String literal data
	dc.b     "SoftIn",$F4                          ; String literal data
	dc.b     "Fon",$F4                             ; String literal data
	dc.b     "Proces",$F3                          ; String literal data
	dc.b     "Semapho",$F2                         ; String literal data
	dc.b     "Invali",$E4                          ; String literal data
	dc.b     "Adde",$E4                            ; String literal data
	dc.b     "Runnin",$E7                          ; String literal data
	dc.b     "Read",$F9                            ; String literal data
	dc.b     "Waitin",$E7                          ; String literal data
	dc.b     "Excep",$F4                           ; String literal data
	dc.b     "Remove",$E4                          ; String literal data
	dc.b     "m <s><e",$BE                         ; String literal data
	dc.b     "Memory Dum",$F0                      ; String literal data
	dc.b     "a <s><e",$BE                         ; String literal data
	dc.b     "ASCII Dum",$F0                       ; String literal data
	dc.b     "bin<wltq> <s><e",$BE                 ; String literal data
	dc.b     "Binary Dum",$F0                      ; String literal data
	dc.b     "t [s][e][target",$DD                 ; String literal data
	dc.b     "TransferMe",$ED                      ; String literal data
	dc.b     "c [s][e][target",$DD                 ; String literal data
	dc.b     "CompareMe",$ED                       ; String literal data
	dc.b     "o [s][e][byte",$DD                   ; String literal data
	dc.b     "Occupy Me",$ED                       ; String literal data
	dc.b     "ow [s][e][word",$DD                  ; String literal data
	dc.b     "Occupy Me",$ED                       ; String literal data
	dc.b     "ol [s][e][longword",$DD              ; String literal data
	dc.b     "Occupy Me",$ED                       ; String literal data
	dc.b     "e [s][e][byte",$DD                   ; String literal data
	dc.b     "EXOR Me",$ED                         ; String literal data
	dc.b     "ew [s][e][word",$DD                  ; String literal data
	dc.b     "EXOR Me",$ED                         ; String literal data
	dc.b     "el [s][e][longword",$DD              ; String literal data
	dc.b     "EXOR Me",$ED                         ; String literal data
	dc.b     "nop [adr][num",$DD                   ; String literal data
	dc.b     "Fill With NO",$D0                    ; String literal data
	dc.b     "imp [s][e]<mode",$BE                 ; String literal data
	dc.b     "Implode Memor",$F9                   ; String literal data
	dc.b     "exp [addr",$DD                       ; String literal data
	dc.b     "Explode Memor",$F9                   ; String literal data
	dc.b     "f [s][e][b]<..",$BE                  ; String literal data
	dc.b     "Find Byte",$F3                       ; String literal data
	dc.b     "f [s][e]["                           ; String literal data
	dc.b     $22,$74,$65,$78,$74,$22,$DD,$46,$69,$6E,$64,$20,$54,$65,$78,$F4; Table data bytes
	dc.b     "fmode [0|1|2",$DD                    ; String literal data
	dc.b     "Show Tab|Hex|Tex",$F4                ; String literal data
	dc.b     "fi [s][e]["                          ; String literal data
	dc.b     $22,$3F,$2A,$74,$65,$78,$74,$22,$DD,$46,$69,$6E,$64,$20,$49,$6E; Table data bytes
	dc.b     "str",$AE                             ; String literal data
	dc.b     "F [addr",$DD                         ; String literal data
	dc.b     "Find Branc",$E8                      ; String literal data
	dc.b     "F [addr] p",$E3                      ; String literal data
	dc.b     "Find PC-rel",$AE                     ; String literal data
	dc.b     "match [0",$DD                        ; String literal data
	dc.b     "Show/Clr MatchBu",$E6                ; String literal data
	dc.b     "p [s][e]<period",$BE                 ; String literal data
	dc.b     "Play Sampl",$E5                      ; String literal data
	dc.b     "b <addr",$BE                         ; String literal data
	dc.b     "View Bitplan",$E5                    ; String literal data
	dc.b     $63,$6C,$F3,$43,$6C,$65,$61,$72,$20,$53,$63,$72,$65,$65,$EE,$42; Table data bytes
	dc.b     " [rgb1] [rgb2",$DD                   ; String literal data
	dc.b     "Set Color",$F3                       ; String literal data
	dc.b     "W <addr",$BE                         ; String literal data
	dc.b     "Move Workspac",$E5                   ; String literal data
	dc.b     "r <value register",$BE               ; String literal data
	dc.b     "Load CP",$D5                         ; String literal data
	dc.b     $D2,$53,$68,$6F,$77,$20,$46,$50,$D5,$6D,$6D,$F5,$53,$68,$6F,$77; Table data bytes
	dc.b     " MM",$D5                             ; String literal data
	dc.b     "mmuo",$EE                            ; String literal data
	dc.b     "Enable MM",$D5                       ; String literal data
	dc.b     "mmuof",$E6                           ; String literal data
	dc.b     "Disable MM",$D5                      ; String literal data
	dc.b     "settt0 [x",$DD                       ; String literal data
	dc.b     "modify TT0 (MMU",$A9                 ; String literal data
	dc.b     "settt1 [x",$DD                       ; String literal data
	dc.b     "modify TT1 (MMU",$A9                 ; String literal data
	dc.b     "settc [x",$DD                        ; String literal data
	dc.b     "modify TC (MMU",$A9                  ; String literal data
	dc.b     "setsrp [x y",$DD                     ; String literal data
	dc.b     "modify SRP (MMU",$A9                 ; String literal data
	dc.b     "setcrp [x y",$DD                     ; String literal data
	dc.b     "modify CRP (MMU",$A9                 ; String literal data
	dc.b     "setdrp [x y",$DD                     ; String literal data
	dc.b     "modify DRP (MMU",$A9                 ; String literal data
	dc.b     "setmmusr [x",$DD                     ; String literal data
	dc.b     "modify SR (MMU",$A9                  ; String literal data
	dc.b     $62,$EC,$4C,$69,$73,$74,$20,$42,$72,$65,$61,$6B,$70,$6F,$69,$6E; Table data bytes
	dc.b     $74,$F3,$62,$73,$20,$5B,$61,$64,$64,$72,$DD,$53,$65,$74,$20,$42; Table data bytes
	dc.b     "reakpoin",$F4                        ; String literal data
	dc.b     "bc [0|addr",$DD                      ; String literal data
	dc.b     "Clr Breakpoin",$F4                   ; String literal data
	dc.b     "g [addr",$DD                         ; String literal data
	dc.b     "Start Progra",$ED                    ; String literal data
	dc.b     $E9,$44,$69,$73,$70,$6C,$61,$79,$20,$56,$65,$63,$74,$6F,$72,$F3; Table data bytes
	dc.b     "d <s><e",$BE                         ; String literal data
	dc.b     "Disassemble 680x",$B0                ; String literal data
	dc.b     $64,$ED,$54,$6F,$67,$67,$6C,$65,$20,$44,$65,$63,$2F,$48,$65,$F8; Table data bytes
	dc.b     $64,$F3,$54,$6F,$67,$67,$6C,$65,$20,$53,$69,$67,$6E,$65,$E4,$64; Table data bytes
	dc.b     $F6,$54,$6F,$67,$67,$6C,$65,$20,$45,$66,$66,$2E,$41,$64,$64,$F2; Table data bytes
	dc.b     "n [addr",$DD                         ; String literal data
	dc.b     "Assemble 680x",$B0                   ; String literal data
	dc.b     "u <s><e",$BE                         ; String literal data
	dc.b     "Disassemble 6581",$B6                ; String literal data
	dc.b     "N [addr",$DD                         ; String literal data
	dc.b     "Assemble 6581",$B6                   ; String literal data
	dc.b     "accu [8|16",$DD                      ; String literal data
	dc.b     "65816 Accu Siz",$E5                  ; String literal data
	dc.b     "index [8|16",$DD                     ; String literal data
	dc.b     "65816 Index Siz",$E5                 ; String literal data
	dc.b     "aut",$EF                             ; String literal data
	dc.b     "65816 Auto Siz",$E5                  ; String literal data
	dc.b     "K <Fn "                              ; String literal data
	dc.b     $27,$74,$65,$78,$74,$31,$7C,$74,$65,$78,$74,$32,$2E,$2E,$27,$BE; Table data bytes
	dc.b     "Set FKe",$F9                         ; String literal data
	dc.b     "D <n",$BE                            ; String literal data
	dc.b     "Select Driv",$E5                     ; String literal data
	dc.b     "dir <f",$BE                          ; String literal data
	dc.b     "Show Director",$F9                   ; String literal data
	dc.b     "bootsum [addr",$DD                   ; String literal data
	dc.b     "Bootblk Checksu",$ED                 ; String literal data
	dc.b     "datasum [addr",$DD                   ; String literal data
	dc.b     "Datablk Checksu",$ED                 ; String literal data
	dc.b     "bitsum [addr",$DD                    ; String literal data
	dc.b     "Bitmap Checksu",$ED                  ; String literal data
	dc.b     "kicksum [addr",$DD                   ; String literal data
	dc.b     "Kickstart Ch",$EB                    ; String literal data
	dc.b     "megasum [addr",$DD                   ; String literal data
	dc.b     "Sega MD Checksu",$ED                 ; String literal data
	dc.b     "famisum [addr",$DD                   ; String literal data
	dc.b     "Famicon Checksu",$ED                 ; String literal data
	dc.b     "rawplay [addr",$DD                   ; String literal data
	dc.b     "Transfer Ra",$F7                     ; String literal data
	dc.b     "smdplay [addr",$DD                   ; String literal data
	dc.b     "Transfer SM",$C4                     ; String literal data
	dc.b     "famiplay [addr",$DD                  ; String literal data
	dc.b     "Transfer SM",$C3                     ; String literal data
	dc.b     "smd2raw [addr",$DD                   ; String literal data
	dc.b     "Convert To Ra",$F7                   ; String literal data
	dc.b     "v <sync",$BE                         ; String literal data
	dc.b     "Set Sync Wor",$E4                    ; String literal data
	dc.b     "vc <track",$BE                       ; String literal data
	dc.b     "Search Sync Wor",$E4                 ; String literal data
	dc.b     "format [name]<q><0..3",$BE           ; String literal data
	dc.b     "Format Dis",$EB                      ; String literal data
	dc.b     "install <0..3|4",$BE                 ; String literal data
	dc.b     "Install DOS\n|1.",$B3                ; String literal data
	dc.b     "verif",$F9                           ; String literal data
	dc.b     "Toggle Verif",$F9                    ; String literal data
	dc.b     "inf",$EF                             ; String literal data
	dc.b     "Report Diskinf",$EF                  ; String literal data
	dc.b     $CD,$53,$68,$6F,$77,$20,$42,$6C,$6F,$63,$6B,$20,$4D,$61,$F0,$6C; Table data bytes
	dc.b     " [addr][cyl]<num",$BE                ; String literal data
	dc.b     "Read Cylinde",$F2                    ; String literal data
	dc.b     "s [addr][cyl]<num",$BE               ; String literal data
	dc.b     "Write Cylinde",$F2                   ; String literal data
	dc.b     "l [addr][sec]<num> ",$F3             ; String literal data
	dc.b     "Read Secto",$F2                      ; String literal data
	dc.b     "s [addr][sec]<num> ",$F3             ; String literal data
	dc.b     "Write Secto",$F2                     ; String literal data
	dc.b     "type "                               ; String literal data
	dc.b     $22,$66,$69,$6C,$65,$A2,$54,$79,$70,$65,$20,$46,$69,$6C,$E5,$4C; Table data bytes
	dc.b     $20,$22,$66,$69,$6C,$65,$22,$20,$5B,$61,$64,$64,$72,$DD,$4C,$6F; Table data bytes
	dc.b     "ad Fil",$E5                          ; String literal data
	dc.b     $53,$20,$22,$66,$69,$6C,$65,$22,$20,$5B,$73,$5D,$5B,$65,$DD,$53; Table data bytes
	dc.b     "ave Fil",$E5                         ; String literal data
	dc.b     "cd ",$BA                             ; String literal data
	dc.b     "Go To Rootdi",$F2                    ; String literal data
	dc.b     "cd [subdir",$DD                      ; String literal data
	dc.b     "Change Di",$F2                       ; String literal data
	dc.b     "mk [subdir",$DD                      ; String literal data
	dc.b     "Make Director",$F9                   ; String literal data
	dc.b     "del "                                ; String literal data
	dc.b     $22,$66,$69,$6C,$65,$2F,$64,$69,$72,$A2,$44,$65,$6C,$65,$74,$65; Table data bytes
	dc.b     " File/Di",$F2                        ; String literal data
	dc.b     $EB,$54,$6F,$67,$67,$6C,$65,$20,$4B,$65,$79,$6D,$61,$F0,$63,$6F; Table data bytes
	dc.b     "nfi",$E7                             ; String literal data
	dc.b     "Config Board",$F3                    ; String literal data
	dc.b     "gar",$F9                             ; String literal data
	dc.b     "A3000/A4000 Inf",$EF                 ; String literal data
	dc.b     "ramse",$F9                           ; String literal data
	dc.b     "A3000/A4000 Inf",$EF                 ; String literal data
	dc.b     $D0,$54,$6F,$67,$67,$6C,$65,$20,$50,$72,$69,$6E,$74,$65,$F2,$68; Table data bytes
	dc.b     " [beg][end]<dst><jmp",$BE            ; String literal data
	dc.b     "Create Hun",$EB                      ; String literal data
	dc.b     "tim",$E5                             ; String literal data
	dc.b     "Show Date/Tim",$E5                   ; String literal data
	dc.b     "/ [n",$DD                            ; String literal data
	dc.b     "Show Systeminf",$EF                  ; String literal data
	dc.b     "V <s><e",$BE                         ; String literal data
	dc.b     "Disasm Coppe",$F2                    ; String literal data
	dc.b     "cop <s e",$BE                        ; String literal data
	dc.b     "Find Copperlist",$F3                 ; String literal data
	dc.b     "custo",$ED                           ; String literal data
	dc.b     "Customreg Hel",$F0                   ; String literal data
	dc.b     "? [value] <exp value",$BE            ; String literal data
	dc.b     "Calculato",$F2                       ; String literal data
	dc.b     $F8,$71,$75,$69,$F4,$00,$00,$42,$6C,$74,$44,$44,$61,$F4,$01,$44; Table data bytes
	dc.b     "MACon",$D2                           ; String literal data
	dc.b     $02,$56,$50,$6F,$73,$D2,$03,$56,$48,$50,$6F,$73,$D2,$04,$44,$73; Table data bytes
	dc.b     "kDat",$D2                            ; String literal data
	dc.b     $07,$43,$6C,$78,$44,$61,$F4,$08,$41,$44,$4B,$43,$6F,$6E,$D2,$0B; Table data bytes
	dc.b     "PotGo",$D2                           ; String literal data
	dc.b     $0C,$53,$65,$72,$44,$61,$74,$D2,$0D,$44,$73,$6B,$42,$79,$74,$D2; Table data bytes
	dc.b     $0E,$49,$6E,$74,$45,$6E,$61,$D2,$0F,$49,$6E,$74,$52,$65,$71,$D2; Table data bytes
	dc.b     $10,$44,$73,$6B,$50,$74,$E8,$11,$44,$73,$6B,$50,$74,$EC,$12,$44; Table data bytes
	dc.b     "skLe",$EE                            ; String literal data
	dc.b     $13,$44,$73,$6B,$44,$61,$F4,$14,$52,$65,$66,$50,$74,$F2,$15,$56; Table data bytes
	dc.b     "Pos",$D7                             ; String literal data
	dc.b     $16,$56,$48,$50,$6F,$73,$D7,$17,$43,$6F,$70,$43,$6F,$EE,$18,$53; Table data bytes
	dc.b     "erDa",$F4                            ; String literal data
	dc.b     $19,$53,$65,$72,$50,$65,$F2,$1A,$50,$6F,$74,$47,$EF,$1B,$4A,$6F; Table data bytes
	dc.b     "yTes",$F4                            ; String literal data
	dc.b     $1C,$53,$74,$72,$45,$71,$F5,$1D,$53,$74,$72,$56,$62,$EC,$1E,$53; Table data bytes
	dc.b     "trHo",$F2                            ; String literal data
	dc.b     $1F,$53,$74,$72,$4C,$6F,$6E,$E7,$22,$42,$6C,$74,$41,$46,$57,$CD; Table data bytes
	dc.b     "#BltALW",$CD                         ; String literal data
	dc.b     "$BltCPt",$E8                         ; String literal data
	dc.b     "%BltCPt",$EC                         ; String literal data
	dc.b     "&BltBPt",$E8                         ; String literal data
	dc.b     $27,$42,$6C,$74,$42,$50,$74,$EC,$28,$42,$6C,$74,$41,$50,$74,$E8; Table data bytes
	dc.b     ")BltAPt",$EC                         ; String literal data
	dc.b     "*BltDPt",$E8                         ; String literal data
	dc.b     "+BltDPt",$EC                         ; String literal data
	dc.b     ",BltSiz",$E5                         ; String literal data
	dc.b     "-BltCon",$B2                         ; String literal data
	dc.b     ".BltSiz",$D6                         ; String literal data
	dc.b     "/BltSiz",$C8                         ; String literal data
	dc.b     "0BltCMo",$E4                         ; String literal data
	dc.b     "1BltBMo",$E4                         ; String literal data
	dc.b     "2BltAMo",$E4                         ; String literal data
	dc.b     "3BltDMo",$E4                         ; String literal data
	dc.b     "8BltCDa",$F4                         ; String literal data
	dc.b     "9BltBDa",$F4                         ; String literal data
	dc.b     ":BltADa",$F4                         ; String literal data
	dc.b     "<SprHDa",$F4                         ; String literal data
	dc.b     ">DeniseI",$C4                        ; String literal data
	dc.b     "?DskSyn",$E3                         ; String literal data
	dc.b     "FCopIn",$F3                          ; String literal data
	dc.b     "GDiwStr",$F4                         ; String literal data
	dc.b     "HDiwSto",$F0                         ; String literal data
	dc.b     "IDDFStr",$F4                         ; String literal data
	dc.b     "JDDFSto",$F0                         ; String literal data
	dc.b     "KDMACo",$EE                          ; String literal data
	dc.b     "LClxCo",$EE                          ; String literal data
	dc.b     "MIntEn",$E1                          ; String literal data
	dc.b     "NIntRe",$F1                          ; String literal data
	dc.b     "OAdkCo",$EE                          ; String literal data
	dc.b     $86,$42,$70,$6C,$43,$6F,$6E,$B4,$87,$43,$6C,$78,$43,$6F,$6E,$B2; Table data bytes
	dc.b     $E0,$48,$54,$6F,$74,$61,$EC,$E1,$48,$53,$53,$74,$6F,$F0,$E2,$48; Table data bytes
	dc.b     "BStr",$F4                            ; String literal data
	dc.b     $E3,$48,$42,$53,$74,$6F,$F0,$E4,$56,$54,$6F,$74,$61,$EC,$E5,$56; Table data bytes
	dc.b     "SSto",$F0                            ; String literal data
	dc.b     $E6,$56,$42,$53,$74,$72,$F4,$E7,$56,$42,$53,$74,$6F,$F0,$E8,$53; Table data bytes
	dc.b     "prHStr",$F4                          ; String literal data
	dc.b     $E9,$53,$70,$72,$48,$53,$74,$6F,$F0,$EA,$42,$70,$6C,$48,$53,$74; Table data bytes
	dc.b     $72,$F4,$EB,$42,$70,$6C,$48,$53,$74,$6F,$F0,$EC,$48,$48,$50,$6F; Table data bytes
	dc.b     $73,$D7,$ED,$48,$48,$50,$6F,$73,$D2,$EE,$42,$65,$61,$6D,$43,$6F; Table data bytes
	dc.b     $6E,$B0,$EF,$48,$53,$53,$74,$72,$F4,$F0,$56,$53,$53,$74,$72,$F4; Table data bytes
	dc.b     $F1,$48,$43,$65,$6E,$74,$65,$F2,$F2,$44,$69,$77,$48,$69,$67,$E8; Table data bytes
	dc.b     $F3,$42,$70,$6C,$48,$4D,$6F,$E4,$F4,$53,$70,$72,$48,$50,$74,$E8; Table data bytes
	dc.b     $F5,$53,$70,$72,$48,$50,$74,$EC,$F6,$42,$70,$6C,$48,$50,$74,$E8; Table data bytes
	dc.b     $F7,$42,$70,$6C,$48,$50,$74,$EC,$FE,$46,$4D,$6F,$64,$E5,$FF,$43; Table data bytes
	dc.b     "opNO",$D0                            ; String literal data
	dc.b     $05,$06,$01,$4A,$6F,$79,$00,$44,$61,$F4,$09,$0A,$01,$50,$6F,$74; Table data bytes
	dc.b     $00,$44,$61,$F4,$20,$21,$01,$42,$6C,$74,$43,$6F,$6E,$00,$A0,$40; Table data bytes
	dc.b     $42,$02,$43,$6F,$70,$01,$4C,$63,$E8,$41,$43,$02,$43,$6F,$70,$01; Table data bytes
	dc.b     $4C,$63,$EC,$44,$45,$01,$43,$6F,$70,$4A,$6D,$70,$01,$A0,$50,$68; Table data bytes
	dc.b     $08,$41,$75,$64,$00,$4C,$63,$E8,$51,$69,$08,$41,$75,$64,$00,$4C; Table data bytes
	dc.b     $63,$EC,$52,$6A,$08,$41,$75,$64,$00,$4C,$65,$EE,$53,$6B,$08,$41; Table data bytes
	dc.b     $75,$64,$00,$50,$65,$F2,$54,$6C,$08,$41,$75,$64,$00,$56,$6F,$EC; Table data bytes
	dc.b     $55,$6D,$08,$41,$75,$64,$00,$44,$61,$F4,$70,$7E,$02,$42,$70,$6C; Table data bytes
	dc.b     $01,$50,$74,$E8,$71,$7F,$02,$42,$70,$6C,$01,$50,$74,$EC,$80,$83; Table data bytes
	dc.b     $01,$42,$70,$6C,$43,$6F,$6E,$00,$A0,$84,$85,$01,$42,$70,$6C,$01; Table data bytes
	dc.b     $4D,$6F,$E4,$88,$8F,$01,$42,$70,$6C,$01,$44,$61,$F4,$90,$9E,$02; Table data bytes
	dc.b     $53,$70,$72,$00,$50,$74,$E8,$91,$9F,$02,$53,$70,$72,$00,$50,$74; Table data bytes
	dc.b     $EC,$A0,$BC,$04,$53,$70,$72,$00,$50,$6F,$F3,$A1,$BD,$04,$53,$70; Table data bytes
	dc.b     $72,$00,$43,$74,$EC,$A2,$BE,$04,$53,$70,$72,$00,$44,$61,$74,$C1; Table data bytes
	dc.b     $A3,$BF,$04,$53,$70,$72,$00,$44,$61,$74,$C2,$C0,$DF,$01,$43,$6F; Table data bytes
	dc.b     $6C,$6F,$72,$00,$A0,$FF               ; Table data bytes
; ============================================================================
; Data Block: Disasm_HandlerOffsetTable
; Purpose   : Disassembler formatting handlers word offset table.
; ============================================================================
Disasm_HandlerOffsetTable:
	dc.b     $00,$00,$00,$0C,$00,$0E,$00,$14,$00,$20,$00,$34,$03,$86,$03,$76; Table data bytes
	dc.b     $03,$BA,$03,$AA,$03,$DA,$03,$EA,$03,$F8,$04,$14,$04,$2A,$04,$34; Table data bytes
	dc.b     $03,$62,$04,$A8,$04,$F0,$04,$FA,$03,$F0,$0A,$D2,$0A,$4E,$05,$24; Table data bytes
	dc.b     $05,$2C,$05,$34,$05,$48,$05,$52,$05,$56,$07,$40,$07,$7C,$0A,$28; Table data bytes
	dc.b     $0A,$32,$0A,$6E,$0A,$88,$0A,$A4,$0A,$AC,$0A,$B4,$0A,$CE,$0A,$C8; Table data bytes
	dc.b     $05,$E8,$00,$2E,$04,$FE,$06,$70,$06,$48,$06,$5C,$06,$CA,$03,$A2; Table data bytes
	dc.b     $03,$92,$07,$8C,$07,$AC,$07,$D8,$08,$38,$08,$44,$08,$5C,$08,$94; Table data bytes
	dc.b     $08,$64,$0A,$BC,$09,$DE,$09,$D2,$09,$BA,$09,$AC,$06,$D2,$03,$E2; Table data bytes
	dc.b     $08,$9E,$08,$9A,$03,$40,$04,$E0,$08,$BE,$02,$BE,$05,$84,$05,$6C; Table data bytes
	dc.b     $08,$DE,$08,$FC,$09,$48,$09,$74,$05,$C6,$05,$DA,$07,$00,$04,$D0; Table data bytes
	dc.b     $03,$30,$08,$B0,$08,$AC,$03,$C4,$03,$CC,$08,$F2,$08,$E6,$08,$C4; Table data bytes
	dc.b     $05,$E4,$07,$1A,$04,$40,$04,$4A,$00,$E0,$02,$16,$02,$12,$01,$E8; Table data bytes
	dc.b     $00,$00,$00,$00,$00,$02,$00,$0C,$00,$1C,$00,$34,$00,$80,$00,$6C; Table data bytes
	dc.b     $00,$E0,$00,$C6,$00,$FE,$01,$0E,$01,$1C,$01,$24,$01,$3C,$01,$46; Table data bytes
	dc.b     $03,$CC,$03,$E4,$04,$10,$04,$18,$01,$14,$04,$50,$0B,$4E,$04,$58; Table data bytes
	dc.b     $04,$68,$04,$8E,$04,$C2,$04,$DC,$04,$E0,$07,$CE,$08,$2C,$0B,$24; Table data bytes
	dc.b     $0B,$4E,$0B,$84,$0B,$CE,$0C,$96,$0C,$9A,$0C,$9E,$0C,$A2,$0C,$B0; Table data bytes
	dc.b     $05,$BE,$00,$2E,$04,$1C,$06,$70,$06,$38,$06,$54,$06,$DE,$00,$B8; Table data bytes
	dc.b     $00,$A4,$08,$52,$08,$66,$08,$A8,$09,$22,$09,$28,$09,$42,$09,$98; Table data bytes
	dc.b     $09,$60,$0C,$A4,$0A,$EE,$0A,$E8,$0A,$B6,$0A,$B0,$06,$EA,$01,$06; Table data bytes
	dc.b     $09,$BA,$09,$56,$03,$C2,$04,$06,$09,$CA,$02,$F8,$05,$2A,$05,$0A; Table data bytes
	dc.b     $09,$CE,$09,$E4,$0A,$42,$0A,$70,$05,$7A,$05,$9E,$07,$2E,$04,$00; Table data bytes
	dc.b     $03,$BC,$09,$B4,$09,$50,$00,$40,$00,$46,$09,$DE,$09,$D4,$09,$A6; Table data bytes
	dc.b     $05,$A8,$07,$50,$01,$56,$01,$60,$01,$E8,$02,$5A,$02,$56,$01,$EC; Table data bytes
	dc.b     $B0,$73,$69,$6E,$63,$6F,$F3,$18,$61,$62; Table data bytes
; ============================================================================
; Data Block: Str_RegisterSFC
; Purpose   : Register view SFC field descriptor string.
; ============================================================================
Str_RegisterSFC:
	dc.b     $F3,$00,$00,$00,$58,$73,$61,$62,$F3,$00,$00,$5C,$64,$61,$62,$F3; Table data bytes
	dc.b     $00,$00                               ; Table data bytes
; ============================================================================
; Data Block: Str_RegisterDFC
; Purpose   : Register view DFC field descriptor string.
; ============================================================================
Str_RegisterDFC:
	dc.b     $1C,$61,$63,$6F,$F3,$00,$00,$A2,$61,$64,$E4,$00,$00,$00,$E2,$73; Table data bytes
	dc.b     $61,$64,$E4,$00,$00,$E6,$64,$61,$64,$E4,$00,$00,$0C,$61,$73,$69; Table data bytes
	dc.b     $EE,$00,$00,$0A,$61,$74,$61,$EE,$00,$00,$0D,$61,$74,$61,$6E,$E8; Table data bytes
	dc.b     $00,$B8,$63,$6D,$F0,$00,$00,$00,$1D,$63,$6F,$F3,$00,$00,$00,$19; Table data bytes
	dc.b     "cos",$E8                             ; String literal data
	dc.b     $00,$00,$A0,$64,$69,$F6,$00,$00,$00,$E0,$73,$64,$69,$F6,$00,$00; Table data bytes
	dc.b     $E4,$64,$64,$69,$F6,$00,$00,$10,$65,$74,$6F,$F8,$00,$00,$1E,$67; Table data bytes
	dc.b     "etex",$F0                            ; String literal data
	dc.b     $1F,$67,$65,$74,$6D,$61,$EE,$01,$69,$6E,$F4,$00,$00,$00,$03,$69; Table data bytes
	dc.b     "ntr",$FA                             ; String literal data
	dc.b     $00,$15,$6C,$6F,$67,$31,$B0,$00,$16,$6C,$6F,$67,$B2,$00,$00,$14; Table data bytes
	dc.b     "log",$EE                             ; String literal data
	dc.b     $00,$00,$06,$6C,$6F,$67,$6E,$70,$B1,$A1,$6D,$6F,$E4,$00,$00,$00; Table data bytes
	dc.b     $80,$6D,$6F,$76,$E5,$00,$00,$C0,$73,$6D,$6F,$76,$E5,$00,$C4,$64; Table data bytes
	dc.b     "mov",$E5                             ; String literal data
	dc.b     $00,$A3,$6D,$75,$EC,$00,$00,$00,$E3,$73,$6D,$75,$EC,$00,$00,$E7; Table data bytes
	dc.b     "dmu",$EC                             ; String literal data
	dc.b     $00,$00,$1A,$6E,$65,$E7,$00,$00,$00,$5A,$73,$6E,$65,$E7,$00,$00; Table data bytes
	dc.b     "^dne",$E7                            ; String literal data
	dc.b     $00,$00,$A5,$72,$65,$ED,$00,$00,$00,$A6,$73,$63,$61,$6C,$E5,$00; Table data bytes
	dc.b     $A4,$73,$67,$6C,$64,$69,$F6,$A7,$73,$67,$6C,$6D,$75,$EC,$0E,$73; Table data bytes
	dc.b     $69,$EE,$00,$00,$00,$02,$73,$69,$6E,$E8,$00,$00,$04,$73,$71,$72; Table data bytes
	dc.b     $F4,$00,$00,$41,$73,$73,$71,$72,$F4,$00,$45,$64,$73,$71,$72,$F4; Table data bytes
	dc.b     $00,$A8,$73,$75,$E2,$00,$00,$00,$E8,$73,$73,$75,$E2,$00,$00,$EC; Table data bytes
	dc.b     "dsu",$E2                             ; String literal data
	dc.b     $00,$00,$0F,$74,$61,$EE,$00,$00,$00,$09,$74,$61,$6E,$E8,$00,$00; Table data bytes
	dc.b     $12,$74,$65,$6E,$74,$6F,$F8,$3A,$74,$73,$F4,$00,$00,$00,$11,$74; Table data bytes
	dc.b     "woto",$F8                            ; String literal data
	dc.b     $00                                   ; Table data bytes
; ============================================================================
; Data Block: Disasm_InstructionOpcodeMap
; Purpose   : Opcode map table used by disassembler.
; ============================================================================
Disasm_InstructionOpcodeMap:
	dc.b     $FF,$FF,$4A,$FC,$04,$01,$69,$6C,$6C,$65,$67,$61,$EC,$00,$FF,$FF; Table data bytes
	dc.b     $4E,$70,$04,$01,$72,$65,$73,$65,$F4,$00,$00,$00,$FF,$FF,$4E,$71; Table data bytes
	dc.b     $04,$01,$6E,$6F,$F0,$00,$00,$00,$00,$00,$FF,$FF,$4E,$73,$04,$01; Table data bytes
	dc.b     $72,$74,$E5,$00,$00,$00,$00,$00,$FF,$FF,$4E,$75,$04,$01,$72,$74; Table data bytes
	dc.b     $F3,$00,$00,$00,$00,$00,$FF,$FF,$4E,$77,$04,$01,$72,$74,$F2,$00; Table data bytes
	dc.b     $00,$00,$00,$00,$FF,$FF,$4A,$FA,$04,$01,$62,$67,$6E,$E4,$00,$00; Table data bytes
	dc.b     $00,$00,$FF,$C0,$F2,$00,$04,$5C,$E6,$00,$00,$00,$00,$00,$00,$00; Table data bytes
	dc.b     $FF,$C0,$F2,$00,$03,$5D,$66,$6D,$6F,$76,$65,$2E,$EC,$00,$FF,$C0; Table data bytes
	dc.b     $F2,$00,$03,$5E,$66,$6D,$6F,$76,$65,$6D,$2E,$EC,$FF,$C0,$F2,$00; Table data bytes
	dc.b     $03,$5F,$66,$6D,$6F,$76,$65,$6D,$2E,$F8,$FF,$FF,$F2,$00,$03,$45; Table data bytes
	dc.b     "fmovec",$F2                          ; String literal data
	dc.b     $00,$FF,$FF,$F2,$80,$04,$44,$66,$6E,$6F,$F0,$00,$00,$00,$00,$FF; Table data bytes
	dc.b     $FF,$F5,$10,$04,$01,$70,$66,$6C,$75,$73,$68,$61,$EE,$FF,$FF,$F5; Table data bytes
	dc.b     $18,$04,$01,$70,$66,$6C,$75,$73,$68,$61,$A1,$FF,$FF,$F0,$00,$04; Table data bytes
	dc.b     "Hpflush",$E1                         ; String literal data
	dc.b     $00,$FF,$FF,$F0,$00,$03,$55,$70,$66,$6C,$75,$73,$68,$F3,$00,$FF; Table data bytes
	dc.b     $C0,$F0,$00,$03,$56,$70,$66,$6C,$75,$73,$68,$F2,$00,$FF,$F8,$F5; Table data bytes
	dc.b     $00,$03,$58,$70,$66,$6C,$75,$73,$68,$EE,$00,$FF,$F8,$F5,$08,$03; Table data bytes
	dc.b     "Xpflus",$E8                          ; String literal data
	dc.b     $00,$00,$FF,$F8,$F5,$48,$03,$58,$70,$74,$65,$73,$74,$F7,$00,$00; Table data bytes
	dc.b     $FF,$F8,$F5,$68,$03,$58,$70,$74,$65,$73,$74,$F2,$00,$00,$FF,$FF; Table data bytes
	dc.b     $F0,$00,$03,$49,$70,$66,$6C,$75,$73,$E8,$00,$00,$FF,$C0,$F0,$00; Table data bytes
	dc.b     $03,$57,$70,$76,$61,$6C,$69,$E4,$00,$00,$FF,$FF,$00,$3C,$03,$0D; Table data bytes
	dc.b     $6F,$72,$E9,$00,$00,$00,$00,$00,$FF,$FF,$02,$3C,$03,$0D,$61,$6E; Table data bytes
	dc.b     $64,$E9,$00,$00,$00,$00,$FF,$FF,$0A,$3C,$03,$0D,$65,$6F,$72,$E9; Table data bytes
	dc.b     $00,$00,$00,$00,$FF,$FF,$00,$7C,$03,$0E,$6F,$72,$E9,$00,$00,$00; Table data bytes
	dc.b     $00,$00,$FF,$FF,$02,$7C,$03,$0E,$61,$6E,$64,$E9,$00,$00,$00,$00; Table data bytes
	dc.b     $FF,$FF,$0A,$7C,$03,$0E,$65,$6F,$72,$E9,$00,$00,$00,$00,$F1,$F8; Table data bytes
	dc.b     $C1,$40,$03,$23,$65,$78,$E7,$00,$00,$00,$00,$00,$F1,$F8,$C1,$48; Table data bytes
	dc.b     $03,$24,$65,$78,$E7,$00,$00,$00,$00,$00,$F1,$F8,$C1,$88,$03,$25; Table data bytes
	dc.b     $65,$78,$E7,$00,$00,$00,$00,$00,$FF,$F8,$4E,$58,$03,$26,$75,$6E; Table data bytes
	dc.b     $6C,$EB,$00,$00,$00,$00,$FF,$F8,$48,$08,$03,$39,$6C,$69,$6E,$6B; Table data bytes
	dc.b     $2E,$EC,$00,$00,$FF,$F8,$4E,$50,$03,$27,$6C,$69,$6E,$EB,$00,$00; Table data bytes
	dc.b     $00,$00,$FF,$F8,$48,$48,$03,$2E,$62,$6B,$70,$F4,$00,$00,$00,$00; Table data bytes
	dc.b     $F1,$F0,$81,$40,$03,$3E,$70,$61,$63,$EB,$00,$00,$00,$00,$F1,$F0; Table data bytes
	dc.b     $81,$80,$03,$3E,$75,$6E,$70,$EB,$00,$00,$00,$00,$FF,$F0,$4E,$40; Table data bytes
	dc.b     $03,$1A,$74,$72,$61,$F0,$00,$00,$00,$00,$F1,$00,$70,$00,$03,$1E; Table data bytes
	dc.b     "move",$F1                            ; String literal data
	dc.b     $00,$00,$00,$FF,$FF,$F8,$00,$03,$5A,$6C,$70,$73,$74,$6F,$F0,$00; Table data bytes
	dc.b     $00,$FF,$FF,$4E,$72,$03,$0F,$73,$74,$6F,$F0,$00,$00,$00,$00,$FF; Table data bytes
	dc.b     $FF,$4E,$74,$03,$0F,$72,$74,$E4,$00,$00,$00,$00,$00,$FD,$FF,$0C; Table data bytes
	dc.b     $FC,$04,$33,$63,$61,$73,$32,$AE,$00,$00,$00,$FF,$F8,$48,$40,$03; Table data bytes
	dc.b     $1B,$73,$77,$61,$F0,$00,$00,$00,$00,$FF,$F8,$49,$C0,$03,$1B,$65; Table data bytes
	dc.b     $78,$74,$E2,$00,$00,$00,$00,$FF,$B8,$48,$80,$01,$1B,$65,$78,$F4; Table data bytes
	dc.b     $00,$00,$00,$00,$00,$FF,$F0,$06,$C0,$03,$36,$72,$74,$ED,$00,$00; Table data bytes
	dc.b     $00,$00,$00,$FF,$FE,$F0,$7A,$04,$52,$70,$74,$72,$61,$F0,$00,$00; Table data bytes
	dc.b     $00,$FF,$FF,$F0,$7C,$04,$51,$70,$74,$72,$61,$F0,$00,$00,$00,$FF; Table data bytes
	dc.b     $FE,$F2,$7A,$04,$41,$66,$74,$72,$61,$F0,$00,$00,$00,$FF,$FF,$F2; Table data bytes
	dc.b     $7C,$04,$40,$66,$74,$72,$61,$F0,$00,$00,$00,$F0,$FE,$50,$FA,$04; Table data bytes
	dc.b     "8tra",$F0                            ; String literal data
	dc.b     $00,$00,$00,$00,$F0,$FF,$50,$FC,$04,$37,$74,$72,$61,$F0,$00,$00; Table data bytes
	dc.b     $00,$00,$FF,$FF,$4E,$76,$04,$01,$74,$72,$61,$70,$F6,$00,$00,$00; Table data bytes
	dc.b     $FF,$3F,$F4,$18,$03,$4C,$63,$69,$6E,$76,$E1,$00,$00,$00,$FF,$38; Table data bytes
	dc.b     $F4,$08,$03,$4D,$63,$69,$6E,$76,$EC,$00,$00,$00,$FF,$38,$F4,$10; Table data bytes
	dc.b     $03,$4D,$63,$69,$6E,$76,$F0,$00,$00,$00,$FF,$3F,$F4,$38,$03,$4C; Table data bytes
	dc.b     "cpush",$E1                           ; String literal data
	dc.b     $00,$00,$FF,$38,$F4,$28,$03,$4D,$63,$70,$75,$73,$68,$EC,$00,$00; Table data bytes
	dc.b     $FF,$38,$F4,$30,$03,$4D,$63,$70,$75,$73,$68,$F0,$00,$00,$FF,$F8; Table data bytes
	dc.b     $F6,$20,$03,$4E,$6D,$6F,$76,$65,$31,$B6,$00,$00,$FF,$E0,$F6,$00; Table data bytes
	dc.b     $03,$59,$6D,$6F,$76,$65,$31,$B6,$00,$00,$F1,$38,$B1,$08,$00,$1F; Table data bytes
	dc.b     "cmp",$ED                             ; String literal data
	dc.b     $00,$00,$00,$00,$F1,$F0,$C1,$00,$03,$20,$61,$62,$63,$E4,$00,$00; Table data bytes
	dc.b     $00,$00,$F1,$F0,$81,$00,$03,$20,$73,$62,$63,$E4,$00,$00,$00,$00; Table data bytes
	dc.b     $F1,$30,$D1,$00,$00,$16,$61,$64,$64,$F8,$00,$00,$00,$00,$F1,$30; Table data bytes
	dc.b     $91,$00,$00,$16,$73,$75,$62,$F8,$00,$00,$00,$00,$FF,$C0,$F0,$00; Table data bytes
	dc.b     $03,$47,$70,$6D,$6F,$76,$65,$66,$E4,$00,$FF,$C0,$F0,$00,$03,$46; Table data bytes
	dc.b     "pmov",$E5                            ; String literal data
	dc.b     $00,$00,$00,$FF,$C0,$F0,$00,$04,$4A,$70,$6C,$6F,$61,$E4,$00,$00; Table data bytes
	dc.b     $00,$FF,$C0,$F0,$00,$04,$4B,$70,$74,$65,$73,$F4,$00,$00,$00,$FF; Table data bytes
	dc.b     $C0,$E8,$C0,$03,$2B,$62,$66,$74,$73,$F4,$00,$00,$00,$FF,$C0,$EA; Table data bytes
	dc.b     $C0,$03,$2B,$62,$66,$63,$68,$E7,$00,$00,$00,$FF,$C0,$EC,$C0,$03; Table data bytes
	dc.b     "+bfcl",$F2                           ; String literal data
	dc.b     $00,$00,$00,$FF,$C0,$EE,$C0,$03,$2B,$62,$66,$73,$65,$F4,$00,$00; Table data bytes
	dc.b     $00,$FF,$C0,$E9,$C0,$03,$2C,$62,$66,$65,$78,$74,$F5,$00,$00,$FF; Table data bytes
	dc.b     $C0,$EB,$C0,$03,$2C,$62,$66,$65,$78,$74,$F3,$00,$00,$FF,$C0,$ED; Table data bytes
	dc.b     $C0,$03,$2C,$62,$66,$66,$66,$EF,$00,$00,$00,$FF,$C0,$EF,$C0,$03; Table data bytes
	dc.b     "-bfin",$F3                           ; String literal data
	dc.b     $00,$00,$00,$FF,$C0,$06,$C0,$03,$31,$63,$61,$6C,$6C,$ED,$00,$00; Table data bytes
	dc.b     $00,$FF,$C0,$40,$C0,$03,$05,$6D,$6F,$76,$E5,$00,$00,$00,$00,$FF; Table data bytes
	dc.b     $C0,$42,$C0,$03,$29,$6D,$6F,$76,$E5,$00,$00,$00,$00,$FF,$C0,$44; Table data bytes
	dc.b     $C0,$03,$03,$6D,$6F,$76,$E5,$00,$00,$00,$00,$FF,$C0,$46,$C0,$03; Table data bytes
	dc.b     $04,$6D,$6F,$76,$E5,$00,$00,$00,$00,$FF,$F0,$4E,$60,$03,$1C,$6D; Table data bytes
	dc.b     $6F,$76,$E5                           ; Table data bytes
; ============================================================================
; Data Block: Disasm_OpcodeMaskTable
; Purpose   : Instruction bitmask / opcode matching table.
; ============================================================================
Disasm_OpcodeMaskTable:
	dc.b     $00,$00,$00,$00,$FF,$FE,$4E,$7A,$03,$28,$6D,$6F,$76,$65,$E3,$00; Table data bytes
	dc.b     $00,$00,$FB,$80,$48,$80,$01,$22,$6D,$6F,$76,$65,$ED,$00,$00,$00; Table data bytes
	dc.b     $F1,$38,$01,$08,$01,$21,$6D,$6F,$76,$65,$F0,$00,$00,$00,$FF,$C0; Table data bytes
	dc.b     $F8,$00,$04,$5B,$74,$62,$EC,$00,$00,$00,$00,$00,$F1,$C0,$41,$C0; Table data bytes
	dc.b     $03,$0A,$6C,$65,$E1,$00,$00,$00,$00,$00,$FF,$FF,$60,$FF,$03,$2F; Table data bytes
	dc.b     "bra.",$EC                            ; String literal data
	dc.b     $00,$00,$00,$FF,$FF,$61,$FF,$03,$2F,$62,$73,$72,$2E,$EC,$00,$00; Table data bytes
	dc.b     $00,$FF,$FF,$60,$00,$03,$06,$62,$72,$61,$2E,$F7,$00,$00,$00,$FF; Table data bytes
	dc.b     $FF,$61,$00,$03,$06,$62,$73,$72,$2E,$F7,$00,$00,$00,$FF,$00,$60; Table data bytes
	dc.b     $00,$03,$08,$62,$72,$61,$2E,$E2,$00,$00,$00,$FF,$00,$60,$00,$03; Table data bytes
	dc.b     $08,$62,$72,$61,$2E,$F3,$00,$00,$00,$FF,$00,$61,$00,$03,$08,$62; Table data bytes
	dc.b     "sr.",$E2                             ; String literal data
	dc.b     $00,$00,$00,$FF,$00,$61,$00,$03,$08,$62,$73,$72,$2E,$F3,$00,$00; Table data bytes
	dc.b     $00,$FF,$B0,$F0,$80,$04,$53,$70,$E2,$00,$00,$00,$00,$00,$00,$FF; Table data bytes
	dc.b     $A0,$F2,$80,$04,$54,$66,$E2,$00,$00,$00,$00,$00,$00,$F0,$FF,$60; Table data bytes
	dc.b     $FF,$04,$30,$E2,$00,$00,$00,$00,$00,$00,$00,$F0,$FF,$60,$00,$04; Table data bytes
	dc.b     $07,$E2,$00,$00,$00,$00,$00,$00,$00,$F0,$00,$60,$00,$04,$09,$E2; Table data bytes
	dc.b     $00,$00,$00,$00,$00,$00,$00,$FF,$F8,$F0,$48,$04,$50,$70,$64,$E2; Table data bytes
	dc.b     $00,$00,$00,$00,$00,$FF,$C0,$F0,$40,$04,$4F,$70,$F3,$00,$00,$00; Table data bytes
	dc.b     $00,$00,$00,$FF,$F8,$F2,$48,$04,$42,$66,$64,$E2,$00,$00,$00,$00; Table data bytes
	dc.b     $00,$FF,$C0,$F2,$40,$04,$43,$66,$F3,$00,$00,$00,$00,$00,$00,$F0; Table data bytes
	dc.b     $F8,$50,$C8,$04,$10,$64,$E2,$00,$00,$00,$00,$00,$00,$F0,$C0,$50; Table data bytes
	dc.b     $C0,$04,$12,$F3,$00,$00,$00,$00,$00,$00,$00,$FF,$C0,$48,$00,$03; Table data bytes
	dc.b     $13,$6E,$62,$63,$E4,$00,$00,$00,$00,$FF,$C0,$48,$40,$03,$13,$70; Table data bytes
	dc.b     $65,$E1,$00,$00,$00,$00,$00,$FF,$C0,$4A,$C0,$03,$13,$74,$61,$F3; Table data bytes
	dc.b     $00,$00,$00,$00,$00,$FF,$C0,$4E,$80,$03,$13,$6A,$73,$F2,$00,$00; Table data bytes
	dc.b     $00,$00,$00,$FF,$C0,$4E,$C0,$03,$13,$6A,$6D,$F0,$00,$00,$00,$00; Table data bytes
	dc.b     $00,$FF,$C0,$E0,$C0,$03,$13,$61,$73,$F2,$00,$00,$00,$00,$00,$FF; Table data bytes
	dc.b     $C0,$E1,$C0,$03,$13,$61,$73,$EC,$00,$00,$00,$00,$00,$FF,$C0,$E2; Table data bytes
	dc.b     $C0,$03,$13,$6C,$73,$F2,$00,$00,$00,$00,$00,$FF,$C0,$E3,$C0,$03; Table data bytes
	dc.b     $13,$6C,$73,$EC,$00,$00,$00,$00,$00,$FF,$C0,$E4,$C0,$03,$13,$72; Table data bytes
	dc.b     $6F,$78,$F2,$00,$00,$00,$00,$FF,$C0,$E5,$C0,$03,$13,$72,$6F,$78; Table data bytes
	dc.b     $EC,$00,$00,$00,$00,$FF,$C0,$E6,$C0,$03,$13,$72,$6F,$F2,$00,$00; Table data bytes
	dc.b     $00,$00,$00,$FF,$C0,$E7,$C0,$03,$13,$72,$6F,$EC,$00,$00,$00,$00; Table data bytes
	dc.b     $00,$FF,$C0,$F1,$00,$03,$13,$70,$73,$61,$76,$E5,$00,$00,$00,$FF; Table data bytes
	dc.b     $C0,$F1,$40,$03,$13,$70,$72,$65,$73,$74,$6F,$72,$E5,$FF,$C0,$F3; Table data bytes
	dc.b     $00,$03,$13,$66,$73,$61,$76,$E5,$00,$00,$00,$FF,$C0,$F3,$40,$03; Table data bytes
	dc.b     $13,$66,$72,$65,$73,$74,$6F,$72,$E5,$FF,$C0,$4C,$40,$03,$3C,$64; Table data bytes
	dc.b     "ivul.",$EC                           ; String literal data
	dc.b     $00,$FF,$C0,$4C,$40,$03,$3D,$64,$69,$76,$73,$6C,$2E,$EC,$00,$FF; Table data bytes
	dc.b     $C0,$4C,$40,$03,$3A,$64,$69,$76,$75,$2E,$EC,$00,$00,$FF,$C0,$4C; Table data bytes
	dc.b     $40,$03,$3B,$64,$69,$76,$73,$2E,$EC,$00,$00,$FF,$C0,$4C,$00,$03; Table data bytes
	dc.b     ":mulu.",$EC                          ; String literal data
	dc.b     $00,$00,$FF,$C0,$4C,$00,$03,$3B,$6D,$75,$6C,$73,$2E,$EC,$00,$00; Table data bytes
	dc.b     $F1,$C0,$80,$C0,$03,$0B,$64,$69,$76,$F5,$00,$00,$00,$00,$F1,$C0; Table data bytes
	dc.b     $81,$C0,$03,$0B,$64,$69,$76,$F3,$00,$00,$00,$00,$F1,$C0,$C0,$C0; Table data bytes
	dc.b     $03,$0B,$6D,$75,$6C,$F5,$00,$00,$00,$00,$F1,$C0,$C1,$C0,$03,$0B; Table data bytes
	dc.b     "mul",$F3                             ; String literal data
	dc.b     $00,$00,$00,$00,$F1,$C0,$41,$80,$03,$0B,$63,$68,$6B,$2E,$F7,$00; Table data bytes
	dc.b     $00,$00,$F1,$C0,$41,$00,$03,$3F,$63,$68,$6B,$2E,$EC,$00,$00,$00; Table data bytes
	dc.b     $F0,$C0,$90,$C0,$02,$15,$73,$75,$62,$E1,$00,$00,$00,$00,$F0,$C0; Table data bytes
	dc.b     $B0,$C0,$02,$15,$63,$6D,$70,$E1,$00,$00,$00,$00,$F0,$C0,$D0,$C0; Table data bytes
	dc.b     $02,$15,$61,$64,$64,$E1,$00,$00,$00,$00,$F1,$00,$80,$00,$00,$14; Table data bytes
	dc.b     $6F,$F2,$00,$00,$00,$00,$00,$00,$F1,$00,$90,$00,$00,$14,$73,$75; Table data bytes
	dc.b     $E2,$00,$00,$00,$00,$00,$F1,$00,$B0,$00,$00,$14,$63,$6D,$F0,$00; Table data bytes
	dc.b     $00,$00,$00,$00,$F1,$00,$C0,$00,$00,$14,$61,$6E,$E4,$00,$00,$00; Table data bytes
	dc.b     $00,$00,$F1,$00,$D0,$00,$00,$14,$61,$64,$E4,$00,$00,$00,$00,$00; Table data bytes
	dc.b     $F1,$00,$81,$00,$00,$0C,$6F,$F2,$00,$00,$00,$00,$00,$00,$F1,$00; Table data bytes
	dc.b     $91,$00,$00,$0C,$73,$75,$E2,$00,$00,$00,$00,$00,$F1,$00,$B1,$00; Table data bytes
	dc.b     $00,$0C,$65,$6F,$F2,$00,$00,$00,$00,$00,$F1,$00,$C1,$00,$00,$0C; Table data bytes
	dc.b     $61,$6E,$E4,$00,$00,$00,$00,$00,$F1,$00,$D1,$00,$00,$0C,$61,$64; Table data bytes
	dc.b     $E4,$00,$00,$00,$00,$00,$FF,$C0,$08,$00,$03,$11,$62,$74,$73,$F4; Table data bytes
	dc.b     $00,$00,$00,$00,$FF,$C0,$08,$40,$03,$11,$62,$63,$68,$E7,$00,$00; Table data bytes
	dc.b     $00,$00,$FF,$C0,$08,$80,$03,$11,$62,$63,$6C,$F2,$00,$00,$00,$00; Table data bytes
	dc.b     $FF,$C0,$08,$C0,$03,$11,$62,$73,$65,$F4,$00,$00,$00,$00,$F9,$C0; Table data bytes
	dc.b     $08,$C0,$05,$32,$63,$61,$F3,$00,$00,$00,$00,$00,$F9,$C0,$00,$C0; Table data bytes
	dc.b     $06,$34,$63,$68,$6B,$B2,$00,$00,$00,$00,$F9,$C0,$00,$C0,$06,$35; Table data bytes
	dc.b     "cmp",$B2                             ; String literal data
	dc.b     $00,$00,$00,$00,$F1,$00,$50,$00,$00,$18,$61,$64,$64,$F1,$00,$00; Table data bytes
	dc.b     $00,$00,$F1,$00,$51,$00,$00,$18,$73,$75,$62,$F1,$00,$00,$00,$00; Table data bytes
	dc.b     $F1,$18,$E0,$00,$00,$19,$61,$73,$F2,$00,$00,$00,$00,$00,$F1,$18; Table data bytes
	dc.b     $E0,$08,$00,$19,$6C,$73,$F2,$00,$00,$00,$00,$00,$F1,$18,$E0,$10; Table data bytes
	dc.b     $00,$19,$72,$6F,$78,$F2,$00,$00,$00,$00,$F1,$18,$E0,$18,$00,$19; Table data bytes
	dc.b     $72,$6F,$F2,$00,$00,$00,$00,$00,$F1,$18,$E1,$00,$00,$19,$61,$73; Table data bytes
	dc.b     $EC,$00,$00,$00,$00,$00,$F1,$18,$E1,$08,$00,$19,$6C,$73,$EC,$00; Table data bytes
	dc.b     $00,$00,$00,$00,$F1,$18,$E1,$10,$00,$19,$72,$6F,$78,$EC,$00,$00; Table data bytes
	dc.b     $00,$00,$F1,$18,$E1,$18,$00,$19,$72,$6F,$EC,$00,$00,$00,$00,$00; Table data bytes
	dc.b     $FF,$00,$00,$00,$00,$17,$6F,$72,$E9,$00,$00,$00,$00,$00,$FF,$00; Table data bytes
	dc.b     $02,$00,$00,$17,$61,$6E,$64,$E9,$00,$00,$00,$00,$FF,$00,$04,$00; Table data bytes
	dc.b     $00,$17,$73,$75,$62,$E9,$00,$00,$00,$00,$FF,$00,$06,$00,$00,$17; Table data bytes
	dc.b     "add",$E9                             ; String literal data
	dc.b     $00,$00,$00,$00,$FF,$00,$0A,$00,$00,$17,$65,$6F,$72,$E9,$00,$00; Table data bytes
	dc.b     $00,$00,$FF,$00,$0C,$00,$00,$17,$63,$6D,$70,$E9,$00,$00,$00,$00; Table data bytes
	dc.b     $F1,$C0,$01,$00,$03,$0C,$62,$74,$73,$F4,$00,$00,$00,$00,$F1,$C0; Table data bytes
	dc.b     $01,$40,$03,$0C,$62,$63,$68,$E7,$00,$00,$00,$00,$F1,$C0,$01,$80; Table data bytes
	dc.b     $03,$0C,$62,$63,$6C,$F2,$00,$00,$00,$00,$F1,$C0,$01,$C0,$03,$0C; Table data bytes
	dc.b     "bse",$F4                             ; String literal data
	dc.b     $00,$00,$00,$00,$FF,$00,$0E,$00,$00,$2A,$6D,$6F,$76,$65,$F3,$00; Table data bytes
	dc.b     $00,$00,$FF,$00,$40,$00,$00,$13,$6E,$65,$67,$F8,$00,$00,$00,$00; Table data bytes
	dc.b     $FF,$00,$42,$00,$00,$13,$63,$6C,$F2,$00,$00,$00,$00,$00,$FF,$00; Table data bytes
	dc.b     $44,$00,$00,$13,$6E,$65,$E7,$00,$00,$00,$00,$00,$FF,$00,$46,$00; Table data bytes
	dc.b     $00,$13,$6E,$6F,$F4,$00,$00,$00,$00,$00,$FF,$00,$4A,$00,$00,$13; Table data bytes
	dc.b     $74,$73,$F4,$00,$00,$00,$00,$00,$C0,$00,$00,$00,$04,$1D,$6D,$6F; Table data bytes
	dc.b     $76,$65,$AE,$00,$00,$00,$F0,$00,$A0,$00,$03,$02,$6C,$69,$6E,$65; Table data bytes
	dc.b     $2D,$E1,$00,$00,$F0,$00,$F0,$00,$03,$02,$6C,$69,$6E,$65,$2D,$E6; Table data bytes
	dc.b     $00,$00,$00,$00,$00,$00,$03,$02,$64,$63,$2E,$F7,$00,$00,$00,$00; Table data bytes
; ============================================================================
; Data Block: Disasm_OpcodeTypeTable
; Purpose   : Disassembler opcode formatting type table.
; ============================================================================
Disasm_OpcodeTypeTable:
	dc.b     $0A,$01,$22,$05,$50,$01,$22,$11,$52,$03,$22,$03,$02,$03,$22,$0E; Table data bytes
	dc.b     $24,$00,$22,$17,$02,$04,$4B,$00,$52,$02,$22,$02,$02,$02,$22,$13; Table data bytes
	dc.b     $09,$0C,$22,$06,$22,$10,$22,$12,$53,$03,$22,$07,$02,$07,$22,$0F; Table data bytes
	dc.b     $0D,$00,$22,$09,$18,$04,$42,$00,$53,$02,$22,$08,$02,$08,$22,$14; Table data bytes
	dc.b     $1C,$02,$01,$05,$58,$13,$01,$11,$06,$03,$01,$03,$27,$03,$01,$0E; Table data bytes
	dc.b     $26,$00,$01,$17,$27,$04,$46,$00,$06,$02,$01,$02,$27,$02,$01,$13; Table data bytes
	dc.b     $07,$0C,$01,$06,$01,$10,$01,$12,$06,$07,$01,$07,$27,$07,$01,$0F; Table data bytes
	dc.b     $2C,$00,$01,$09,$14,$04,$40,$00,$06,$08,$01,$08,$27,$08,$01,$14; Table data bytes
	dc.b     $29,$00,$17,$05,$38,$01,$17,$11,$59,$02,$17,$03,$1D,$03,$17,$0E; Table data bytes
	dc.b     $23,$00,$17,$17,$1D,$04,$4A,$00,$1B,$02,$17,$02,$1D,$02,$17,$13; Table data bytes
	dc.b     $0B,$0C,$17,$06,$17,$10,$17,$12,$5A,$02,$17,$07,$1D,$07,$17,$0F; Table data bytes
	dc.b     $0E,$00,$17,$09,$48,$00,$43,$00,$1B,$13,$17,$08,$1D,$08,$17,$14; Table data bytes
	dc.b     $2A,$00,$00,$05,$56,$15,$00,$11,$5B,$03,$00,$03,$28,$03,$00,$0E; Table data bytes
	dc.b     $25,$00,$00,$17,$28,$04,$3C,$00,$1B,$0B,$00,$02,$28,$02,$00,$13; Table data bytes
	dc.b     $0C,$0C,$00,$06,$00,$10,$00,$12,$5B,$07,$00,$07,$28,$07,$00,$0F; Table data bytes
	dc.b     $2E,$00,$00,$09,$44,$00,$41,$00,$1B,$16,$00,$08,$28,$08,$00,$14; Table data bytes
	dc.b     $51,$0C,$2F,$05,$57,$15,$2F,$11,$31,$03,$2F,$03,$30,$03,$2F,$0E; Table data bytes
	dc.b     $16,$00,$06,$17,$35,$00,$4C,$00,$31,$02,$2F,$02,$30,$02,$2F,$13; Table data bytes
	dc.b     $03,$0C,$2F,$06,$2F,$10,$2F,$12,$31,$07,$2F,$07,$30,$0A,$2F,$0F; Table data bytes
	dc.b     $37,$00,$2F,$09,$36,$00,$3F,$00,$5B,$02,$2F,$08,$5B,$08,$2F,$14; Table data bytes
	dc.b     $20,$18,$1E,$05,$1F,$18,$1E,$11,$20,$03,$1E,$03,$1F,$03,$1E,$0E; Table data bytes
	dc.b     $33,$00,$1E,$17,$32,$00,$47,$00,$20,$02,$1E,$02,$1F,$02,$1E,$13; Table data bytes
	dc.b     $04,$0C,$1E,$06,$1E,$10,$1E,$12,$20,$07,$1E,$07,$1F,$0A,$1E,$0F; Table data bytes
	dc.b     $10,$00,$1E,$09,$34,$00,$3E,$00,$20,$08,$1E,$08,$1F,$09,$1E,$14; Table data bytes
	dc.b     $13,$18,$11,$05,$4E,$01,$11,$11,$13,$03,$11,$03,$14,$03,$11,$0E; Table data bytes
	dc.b     $1A,$00,$11,$17,$15,$00,$3A,$00,$13,$02,$11,$02,$14,$02,$11,$13; Table data bytes
	dc.b     $08,$0C,$11,$06,$11,$10,$11,$12,$55,$10,$11,$07,$14,$07,$11,$0F; Table data bytes
	dc.b     $0F,$00,$11,$09,$49,$00,$3B,$00,$4F,$0B,$11,$08,$14,$08,$11,$14; Table data bytes
	dc.b     $12,$18,$2B,$05,$4D,$01,$2B,$11,$12,$03,$2B,$03,$18,$03,$2B,$0E; Table data bytes
	dc.b     $19,$00,$2B,$17,$21,$00,$39,$00,$12,$02,$2B,$02,$18,$02,$2B,$13; Table data bytes
	dc.b     $05,$0C,$2B,$06,$2B,$10,$2B,$12,$54,$02,$2B,$07,$18,$07,$2B,$0F; Table data bytes
	dc.b     $2D,$00,$2B,$09,$45,$00,$3D,$00,$1C,$16,$2B,$08,$18,$08,$2B,$14; Table data bytes
	dc.b     $FF                                   ; Table data bytes
; ============================================================================
; Data Block: Disasm_MnemonicPool
; Purpose   : Disassembler mnemonic character pool.
; ============================================================================
Disasm_MnemonicPool:
	dc.b     "adcandaslbccbcsbeqbitbmibnebplbrkbvcbvsclcclicldclvcmpcpxcpydecdexdeyeorincinxinyjmpjsrlsrldaldxldynoporaphaphpplaplprolrorrtirtssbcsecsedseistastxstytaxtaytsxtxatxstyawdmxbawaistprtlxcetyxtxytsctdctcstcdplyplxpldplbphyphxphkphdphbseprepjmlcopbratsbtrbpeapeiperbrljslmvpmvnstz"; String literal data
	dc.b     $FF,$21,$00,$21,$43,$21,$80,$21,$83,$40,$16,$40,$17,$42,$00,$42; Table data bytes
	dc.b     $1F,$43,$00,$43,$0A,$FF,$FF,$73,$63,$72,$6E,$66,$61,$64,$65,$6F; Table data bytes
	dc.b     "am_sizeoam_addroam_adhioam_datavscrnmodmozaik  playf0_aplayf1_aplayf2_aplayf3_atile01_atile23_ascrollx0scrolly0scrollx1scrolly1scrollx2scrolly2scrollx3scrolly3vportconvportadrvportadhvportdatvportdhimod7initmod7regamod7regbmod7regcmod7regdmod7regxmod7regypaletpntpaletdatwi12maskwi34maskwind_objwind0poswind1poswind2poswind3poswind1logwind2logplayfflgsscrnflgwinmaskmwinmaskscolsinitcolstvalcolstdatilaceflgresult_lresult_mresult_hhv_latchoamrddatvrrddatlvrrddathpalrddatho_countve_countppusta77ppusta78audireg0audireg1audireg2audireg3wm_data wmaddrlowmaddrmewmdatahictr13datctr24datnmitmflgioprtoutmulticanmultiplrdividlowdivid_hidivisor hcountlohcounthivcountlovcounthidmaonflghdmaonflmemselecreservedreservednmivblflirg_flaghvjoy_onioprtinpdivquolodivquohimultprlomultprhipad_1_lopad_1_hipad_2_lopad_2_hipad_3_lopad_3_hipad_4_lopad_4_hidma"; String literal data
	dc.b     $00,$70,$61,$72,$6D,$64,$6D,$61,$00,$64,$65,$73,$74,$64,$6D,$61; Table data bytes
	dc.b     $00,$73,$72,$63,$6C,$64,$6D,$61,$00,$73,$72,$63,$6D,$64,$6D,$61; Table data bytes
	dc.b     $00,$73,$72,$63,$68,$64,$6D,$61,$00,$73,$69,$7A,$6C,$64,$6D,$61; Table data bytes
	dc.b     $00,$73,$69,$7A,$68,$64,$6D,$61,$00,$68,$6D,$6D,$6D,$64,$6D,$61; Table data bytes
	dc.b     $00,$74,$61,$62,$6C,$64,$6D,$61,$00,$74,$61,$62,$68,$68,$64,$6D; Table data bytes
	dc.b     $61,$00,$6C,$69,$6E,$00,$00,$00,$00,$00,$00,$00,$00,$18,$18,$18; Table data bytes
	dc.b     $18,$18,$00,$18,$00,$6C,$6C,$00,$00,$00,$00,$00,$00,$66,$66,$FF; Table data bytes
	dc.b     $66,$FF,$66,$66,$00,$18,$3E,$60,$3C,$06,$7C,$18,$00,$C3,$C6,$0C; Table data bytes
	dc.b     $18,$30,$63,$C3,$00,$38,$6C,$68,$76,$DC,$CC,$76,$00,$18,$18,$30; Table data bytes
	dc.b     $00,$00,$00,$00,$00,$0C,$18,$30,$30,$30,$18,$0C,$00,$30,$18,$0C; Table data bytes
	dc.b     $0C,$0C,$18,$30,$00,$00,$66,$3C,$FF,$3C,$66,$00,$00,$00,$18,$18; Table data bytes
	dc.b     $7E,$18,$18,$00,$00,$00,$00,$00,$00,$00,$18,$18,$30,$00,$00,$00; Table data bytes
	dc.b     $7E,$00,$00,$00,$00,$00,$00,$00,$00,$00,$18,$18,$00,$03,$06,$0C; Table data bytes
	dc.b     $18,$30,$60,$C0,$00,$3C,$66,$6E,$7E,$76,$66,$3C,$00,$18,$38,$18; Table data bytes
	dc.b     $18,$18,$18,$18,$00,$3C,$66,$06,$0C,$18,$30,$7E,$00,$7E,$06,$0C; Table data bytes
	dc.b     $1C,$06,$66,$3C,$00,$1C,$3C,$6C,$CC,$FE,$0C,$0C,$00,$7E,$60,$7C; Table data bytes
	dc.b     $06,$06,$66,$3C,$00,$0C,$18,$30,$7C,$66,$66,$3C,$00,$7E,$06,$06; Table data bytes
	dc.b     $0C,$18,$18,$18,$00,$3C,$66,$66,$3C,$66,$66,$3C,$00,$3C,$66,$66; Table data bytes
	dc.b     $3E,$0C,$18,$30,$00,$00,$18,$18,$00,$00,$18,$18,$00,$00,$00,$18; Table data bytes
	dc.b     $18,$00,$18,$18,$30,$0C,$18,$30,$60,$30,$18,$0C,$00,$00,$00,$7E; Table data bytes
	dc.b     $00,$00,$7E,$00,$00,$30,$18,$0C,$06,$0C,$18,$30,$00,$3C,$66,$06; Table data bytes
	dc.b     $0C,$18,$00,$18,$00,$3E,$63,$6F,$6F,$6F,$60,$3E,$00,$3C,$66,$66; Table data bytes
	dc.b     "~fff"                                ; String literal data
	dc.b     $00,$7C,$66,$66,$7C,$66,$66,$7C,$00,$3C,$66,$60,$60,$60,$66,$3C; Table data bytes
	dc.b     $00,$78,$6C,$66,$66,$66,$6C,$78,$00,$3E,$60,$60,$7C,$60,$60,$3E; Table data bytes
	dc.b     $00,$3E,$60,$60,$7C,$60,$60,$60,$00,$3C,$66,$60,$6E,$66,$66,$3E; Table data bytes
	dc.b     $00,$66,$66,$66,$7E,$66,$66,$66,$00,$18,$18,$18,$18,$18,$18,$18; Table data bytes
	dc.b     $00,$06,$06,$06,$06,$06,$66,$3C,$00,$66,$66,$6C,$78,$6C,$66,$66; Table data bytes
	dc.b     $00,$60,$60,$60,$60,$60,$60,$3E,$00,$63,$77,$7F,$6B,$63,$63,$63; Table data bytes
	dc.b     $00,$66,$76,$7E,$6E,$66,$66,$66,$00,$3C,$66,$66,$66,$66,$66,$3C; Table data bytes
	dc.b     $00,$7C,$66,$66,$7C,$60,$60,$60,$00,$3C,$66,$66,$66,$66,$6E,$3C; Table data bytes
	dc.b     $06,$7C,$66,$66,$7C,$78,$6C,$66,$00,$3C,$66,$60,$3C,$06,$66,$3C; Table data bytes
	dc.b     $00,$7E,$18,$18,$18,$18,$18,$18,$00,$66,$66,$66,$66,$66,$66,$3C; Table data bytes
	dc.b     $00,$66,$66,$66,$66,$6C,$78,$70,$00,$63,$63,$63,$6B,$7F,$77,$63; Table data bytes
	dc.b     $00,$63,$63,$36,$1C,$36,$63,$63,$00,$66,$66,$66,$3C,$18,$18,$18; Table data bytes
	dc.b     $00,$7E,$06,$0C,$18,$30,$60,$7E,$00,$3C,$30,$30,$30,$30,$30,$3C; Table data bytes
	dc.b     $00,$C0,$60,$30,$18,$0C,$06,$03,$00,$3C,$0C,$0C,$0C,$0C,$0C,$3C; Table data bytes
	dc.b     $00,$10,$38,$6C,$C6,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FE; Table data bytes
	dc.b     $00,$18,$18,$0C,$00,$00,$00,$00,$00,$00,$00,$3C,$66,$7E,$66,$66; Table data bytes
	dc.b     $00,$60,$60,$7C,$66,$66,$66,$7C,$00,$00,$00,$3C,$66,$60,$66,$3C; Table data bytes
	dc.b     $00,$06,$06,$3E,$66,$66,$66,$3E,$00,$00,$00,$3E,$60,$7E,$60,$3E; Table data bytes
	dc.b     $00,$1C,$30,$3C,$30,$30,$30,$30,$00,$00,$00,$3E,$66,$66,$3E,$06; Table data bytes
	dc.b     "<``ff~ff"                            ; String literal data
	dc.b     $00,$18,$00,$18,$18,$18,$18,$18,$00,$18,$00,$18,$18,$18,$18,$18; Table data bytes
	dc.b     "p``flxlf"                            ; String literal data
	dc.b     $00,$30,$30,$30,$30,$30,$30,$1C,$00,$00,$00,$63,$77,$7F,$6B,$63; Table data bytes
	dc.b     $00,$00,$00,$66,$76,$7E,$6E,$66,$00,$00,$00,$3C,$66,$66,$66,$3C; Table data bytes
	dc.b     $00,$00,$00,$7C,$66,$66,$7C,$60,$60,$00,$00,$3E,$66,$66,$3E,$06; Table data bytes
	dc.b     $06,$00,$00,$7C,$66,$7C,$6C,$66,$00,$00,$00,$3E,$60,$3C,$06,$7C; Table data bytes
	dc.b     $00,$00,$00,$7E,$18,$18,$18,$18,$00,$00,$00,$66,$66,$66,$66,$3C; Table data bytes
	dc.b     $00,$00,$00,$66,$66,$6C,$78,$70,$00,$00,$00,$63,$6B,$6B,$36,$36; Table data bytes
	dc.b     $00,$00,$00,$63,$36,$1C,$36,$63,$00,$00,$00,$66,$66,$66,$3E,$06; Table data bytes
	dc.b     $3C,$00,$00,$7E,$0C,$18,$30,$7E,$00,$0E,$18,$18,$70,$18,$18,$0E; Table data bytes
	dc.b     $00,$18,$18,$18,$08,$18,$18,$18,$00,$70,$18,$18,$0E,$18,$18,$70; Table data bytes
	dc.b     $00,$72,$9C,$00,$00,$00,$00,$00,$00,$CC,$33,$CC,$33,$CC,$33,$CC; Table data bytes
	dc.b     $33,$00,$00,$00,$00,$00,$00,$00,$00,$18,$00,$18,$18,$18,$18,$18; Table data bytes
	dc.b     $00,$0C,$3E,$6C,$6C,$3E,$0C,$00,$00,$1C,$36,$30,$78,$30,$30,$7E; Table data bytes
	dc.b     $00,$42,$3C,$66,$3C,$42,$00,$00,$00,$C3,$66,$3C,$18,$3C,$18,$3C; Table data bytes
	dc.b     $00,$18,$18,$18,$00,$18,$18,$18,$00,$3C,$40,$3C,$66,$3C,$02,$3C; Table data bytes
	dc.b     $00,$66,$00,$00,$00,$00,$00,$00,$00,$7E,$81,$BD,$B1,$BD,$81,$7E; Table data bytes
	dc.b     $00,$78,$D8,$D8,$7C,$00,$FC,$00,$00,$00,$33,$66,$CC,$66,$33,$00; Table data bytes
	dc.b     $00,$7E,$06,$00,$00,$00,$00,$00,$00,$00,$00,$7E,$7E,$00,$00,$00; Table data bytes
	dc.b     $00,$7E,$81,$BD,$A5,$B9,$AD,$81,$7E,$7E,$00,$00,$00,$00,$00,$00; Table data bytes
	dc.b     $00,$3C,$66,$3C,$00,$00,$00,$00,$00,$18,$18,$7E,$18,$18,$00,$7E; Table data bytes
	dc.b     $00,$F0,$18,$30,$60,$F8,$00,$00,$00,$F0,$18,$30,$18,$F0,$00,$00; Table data bytes
	dc.b     $00,$18,$30,$00,$00,$00,$00,$00,$00,$00,$00,$C6,$C6,$C6,$EE,$FA; Table data bytes
	dc.b     $C0,$7E,$F4,$F4,$74,$14,$14,$14,$00,$00,$00,$00,$18,$18,$00,$00; Table data bytes
	dc.b     $00,$00,$00,$00,$00,$00,$00,$18,$30,$30,$70,$30,$30,$30,$00,$00; Table data bytes
	dc.b     $00,$70,$88,$88,$70,$00,$F8,$00,$00,$00,$CC,$66,$33,$66,$CC,$00; Table data bytes
	dc.b     $00,$40,$C6,$4C,$58,$32,$66,$CF,$02,$60,$E6,$6C,$78,$3F,$6B,$C6; Table data bytes
	dc.b     $0F,$C0,$23,$66,$2C,$D9,$33,$67,$01,$18,$00,$18,$30,$60,$66,$3C; Table data bytes
	dc.b     $00,$30,$08,$3C,$66,$7E,$66,$66,$00,$0C,$10,$3C,$66,$7E,$66,$66; Table data bytes
	dc.b     $00,$18,$24,$3C,$66,$7E,$66,$66,$00,$32,$4C,$3C,$66,$7E,$66,$66; Table data bytes
	dc.b     $00,$66,$3C,$66,$66,$7E,$66,$66,$00,$3C,$66,$3C,$66,$7E,$66,$66; Table data bytes
	dc.b     $00,$7F,$CC,$CC,$FF,$CC,$CC,$CF,$00,$3C,$66,$60,$60,$66,$3C,$08; Table data bytes
	dc.b     $30,$30,$08,$3E,$60,$7C,$60,$3E,$00,$0C,$10,$3E,$60,$7C,$60,$3E; Table data bytes
	dc.b     $00,$18,$24,$3E,$60,$7C,$60,$3E,$00,$66,$00,$3E,$60,$7C,$60,$3E; Table data bytes
	dc.b     $00,$30,$08,$18,$18,$18,$18,$18,$00,$0C,$10,$18,$18,$18,$18,$18; Table data bytes
	dc.b     $00,$18,$24,$18,$18,$18,$18,$18,$00,$66,$00,$18,$18,$18,$18,$18; Table data bytes
	dc.b     $00,$78,$6C,$66,$F6,$66,$6C,$78,$00,$32,$4C,$76,$7E,$6E,$66,$66; Table data bytes
	dc.b     $00,$30,$08,$3C,$66,$66,$66,$3C,$00,$0C,$10,$3C,$66,$66,$66,$3C; Table data bytes
	dc.b     $00,$18,$24,$3C,$66,$66,$66,$3C,$00,$32,$4C,$3C,$66,$66,$66,$3C; Table data bytes
	dc.b     $00,$66,$3C,$66,$66,$66,$66,$3C,$00,$00,$00,$63,$36,$1C,$36,$63; Table data bytes
	dc.b     $00,$3D,$66,$6E,$7E,$76,$66,$BC,$00,$30,$08,$66,$66,$66,$66,$3C; Table data bytes
	dc.b     $00,$0C,$10,$66,$66,$66,$66,$3C,$00,$18,$24,$66,$66,$66,$66,$3C; Table data bytes
	dc.b     $00,$CC,$00,$CC,$CC,$CC,$CC,$78,$00,$06,$08,$66,$66,$3C,$18,$18; Table data bytes
	dc.b     $00,$60,$60,$7C,$66,$66,$7C,$60,$60,$7C,$66,$66,$6C,$66,$66,$6C; Table data bytes
	dc.b     $60,$30,$08,$00,$3C,$66,$7E,$66,$00,$0C,$10,$00,$3C,$66,$7E,$66; Table data bytes
	dc.b     $00,$18,$24,$00,$3C,$66,$7E,$66,$00,$32,$4C,$00,$3C,$66,$7E,$66; Table data bytes
	dc.b     $00,$66,$00,$3C,$66,$7E,$66,$66,$00,$3C,$66,$3C,$3C,$66,$7E,$66; Table data bytes
	dc.b     $00,$00,$00,$7F,$CC,$FF,$CC,$CF,$00,$00,$00,$3C,$66,$60,$66,$3C; Table data bytes
	dc.b     $10,$18,$04,$1E,$30,$3E,$30,$1E,$00,$0C,$10,$1E,$30,$3E,$30,$1E; Table data bytes
	dc.b     $00,$0C,$12,$1E,$30,$3E,$30,$1E,$00,$36,$00,$1E,$30,$3E,$30,$1E; Table data bytes
	dc.b     $00,$30,$08,$00,$18,$18,$18,$18,$00,$0C,$10,$00,$18,$18,$18,$18; Table data bytes
	dc.b     $00,$18,$24,$00,$18,$18,$18,$18,$00,$66,$00,$00,$18,$18,$18,$18; Table data bytes
	dc.b     $00,$30,$7C,$18,$3C,$66,$66,$3C,$00,$32,$4C,$00,$76,$7E,$6E,$66; Table data bytes
	dc.b     $00,$30,$08,$00,$3C,$66,$66,$3C,$00,$0C,$10,$00,$3C,$66,$66,$3C; Table data bytes
	dc.b     $00,$18,$24,$00,$3C,$66,$66,$3C,$00,$32,$4C,$00,$3C,$66,$66,$3C; Table data bytes
	dc.b     $00,$66,$00,$3C,$66,$66,$66,$3C,$00,$00,$18,$00,$7E,$00,$18,$00; Table data bytes
	dc.b     $00,$00,$01,$3E,$67,$6B,$73,$3E,$40,$30,$08,$00,$66,$66,$66,$3C; Table data bytes
	dc.b     $00,$0C,$10,$00,$66,$66,$66,$3C,$00,$18,$24,$00,$66,$66,$66,$3C; Table data bytes
	dc.b     $00,$00,$66,$00,$66,$66,$66,$3C,$00,$0C,$10,$00,$66,$66,$3E,$06; Table data bytes
	dc.b     "<00<66<00f"                          ; String literal data
	dc.b     $00,$66,$66,$66,$3E,$06,$3C,$BC,$CB,$3F,$52,$60,$31,$32,$33,$34; Table data bytes
	dc.b     "567890",$DF                          ; String literal data
	dc.b     $27,$5C,$00,$30,$71,$77,$65,$72,$74,$7A,$75,$69,$6F,$70,$FC,$2B; Table data bytes
	dc.b     $00,$31,$32,$33,$61,$73,$64,$66,$67,$68,$6A,$6B,$6C,$F6,$E4,$23; Table data bytes
	dc.b     $00,$34,$35,$36,$3C,$79,$78,$63,$76,$62,$6E,$6D,$2C,$2E,$2D,$00; Table data bytes
	dc.b     ".789 "                               ; String literal data
	dc.b     $08,$05,$0D,$0D,$1B,$09,$00,$00,$00,$2D,$00,$10,$11,$13,$12,$80; Table data bytes
	dc.b     $81,$82,$83,$84,$85,$86,$87,$88,$89,$5B,$5D,$2F,$2A,$2B,$06,$7E; Table data bytes
	dc.b     $21,$22,$A7,$24,$25,$26,$2F,$28,$29,$3D,$3F,$60,$7C,$00,$0C,$51; Table data bytes
	dc.b     "WERTZUIOP",$DC                       ; String literal data
	dc.b     $2A,$00,$1A,$16,$00,$41,$53,$44,$46,$47,$48,$4A,$4B,$4C,$D6,$C4; Table data bytes
	dc.b     $5E,$00,$00,$00,$00,$3E,$59,$58,$43,$56,$42,$4E,$4D,$3B,$3A,$5F; Table data bytes
	dc.b     $00,$00,$19,$15,$00,$20,$07,$14,$00,$0E,$00,$0A,$00,$00,$00,$2D; Table data bytes
	dc.b     $00,$01,$02,$04,$03,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$7B; Table data bytes
	dc.b     "}/*+"                                ; String literal data
	dc.b     $0B,$80,$80,$92,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00; Table data bytes
	dc.b     $00,$00,$00,$01,$C0,$00,$80,$01,$C0,$00,$80,$01,$40,$00,$80,$01; Table data bytes
	dc.b     $40,$00,$80,$01,$40,$00,$80,$01,$40,$00,$80,$01,$40,$00,$80,$01; Table data bytes
	dc.b     $40,$00,$80,$07,$70,$03,$E0,$04,$10,$00,$80,$07,$70,$00,$80,$01; Table data bytes
	dc.b     $40,$00,$00,$01,$C0,$00,$00,$00,$00,$00,$00,$00,$00,$00,$E0,$00; Table data bytes
	dc.b     $00,$00,$E2,$00,$00,$00,$8E,$2C,$81,$00,$90,$2C,$C1,$00,$92,$00; Table data bytes
	dc.b     $00,$00,$94,$00,$00,$01,$00,$92,$00,$01,$02,$00,$00,$01,$FC,$00; Table data bytes
	dc.b     $00,$01,$08,$00,$00,$01,$80,$00,$00,$01,$82,$00,$00,$01,$A2,$0F; Table data bytes
	dc.b     $00,$01,$A4,$00,$00,$01,$A6,$00,$F0,$FF,$FF,$FF,$FE; Table data bytes
	ds.b     661                                   ; Reserve zero-filled buffer data
	dc.b     $01,$00,$00,$00,$00,$00,$00,$00,$05   ; Table data bytes
	ds.b     17                                    ; Reserve zero-filled buffer data
	dc.b     $FF,$00,$00,$00,$00,$00,$00,$00,$FF,$00,$00,$01; Table data bytes
	ds.b     49                                    ; Reserve zero-filled buffer data
	dc.b     $1F,$1C,$1F,$1E,$1F,$1E,$1F,$1F,$1E,$1F,$1E,$1F,$50,$54,$43,$48; Table data bytes
	dc.b     $DE,$AD,$DE,$AD,$00,$00,$00,$00,$0B,$BB,$02,$22,$6C,$20,$34,$30; Table data bytes
	dc.b     "000 0 2 s|"                          ; String literal data
	dc.b     $00,$00,$00,$00,$00,$00,$61,$20,$34,$30,$30,$30,$30,$7C,$00,$00; Table data bytes
	dc.b     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$64,$20,$34,$30,$30,$30; Table data bytes
	dc.b     $30,$7C,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$4C,$20; Table data bytes
	dc.b     "oi 40000|"                           ; String literal data
	dc.b     $00,$00,$00,$00,$00,$00,$00,$00,$00,$63,$64,$3A,$7C,$64,$69,$72; Table data bytes
	dc.b     $7C                                   ; Table data bytes
	ds.b     128                                   ; Reserve zero-filled buffer data
	dc.b     "UUUU",$AA                            ; String literal data
	dc.b     $AA,$AA,$AA,$44,$89                   ; Table data bytes
	ds.b     54                                    ; Reserve zero-filled buffer data
	dc.b     $44,$4F,$53                           ; Table data bytes
	ds.b     411                                   ; Reserve zero-filled buffer data
	dc.b     $4A,$FC,$4A,$FC,$4A,$FC,$4A,$FC,$4A,$FC,$4A,$FC,$4A,$FC,$4A,$FC; Table data bytes
	dc.b     $4A,$FC,$4A,$FC                       ; Table data bytes
	ds.b     3832                                  ; Reserve zero-filled buffer data
	dc.b     ">                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               "; String literal data
	ds.b     5645                                  ; Reserve zero-filled buffer data
	dc.b     $08                                   ; Table data bytes
	ds.b     39                                    ; Reserve zero-filled buffer data
	dc.b     $29,$00,$00,$00,$00,$20               ; Table data bytes
	ds.b     34                                    ; Reserve zero-filled buffer data
	dc.b     $0C                                   ; Table data bytes
	ds.b     39                                    ; Reserve zero-filled buffer data
	dc.b     $0E,$80,$30,$60,$00,$28               ; Table data bytes
	ds.b     34                                    ; Reserve zero-filled buffer data
	dc.b     $1E,$50,$BF,$00,$00,$0A               ; Table data bytes
	ds.b     32                                    ; Reserve zero-filled buffer data
	dc.b     $02,$00,$9F,$41,$0B,$F2,$00,$20       ; Table data bytes
	ds.b     32                                    ; Reserve zero-filled buffer data
	dc.b     $40,$C4,$1F,$41,$C9,$FE,$00,$14       ; Table data bytes
	ds.b     32                                    ; Reserve zero-filled buffer data
	dc.b     $1F,$F2,$5B,$40,$E1,$54,$00,$1A       ; Table data bytes
	ds.b     24                                    ; Reserve zero-filled buffer data
	dc.b     $04,$00,$00,$00,$00,$00,$00,$01,$7F,$FD,$13,$80,$F4,$79,$80,$1A; Table data bytes
	ds.b     23                                    ; Reserve zero-filled buffer data
	dc.b     $03,$1F,$C0,$00,$00,$00,$00,$00,$00,$7F,$C6,$51,$A0,$E1,$F0,$00; Table data bytes
	dc.b     $3A                                   ; Table data bytes
	ds.b     16                                    ; Reserve zero-filled buffer data
	dc.b     $0F,$E3,$00,$00,$00,$00,$00,$0C,$3F,$E0,$00,$00,$00,$00,$00,$00; Table data bytes
	dc.b     $7C,$00,$1A,$CF,$F3,$A0,$80,$28,$80,$00,$00,$00,$00,$00,$00,$00; Table data bytes
	dc.b     $00,$00,$00,$00,$00,$00,$00,$00,$1F,$F0,$80,$00,$00,$00,$00,$18; Table data bytes
	dc.b     $3F,$F0,$00,$00,$00,$00,$00,$00,$74,$08,$B3,$FF,$F7,$82,$E0,$18; Table data bytes
	ds.b     16                                    ; Reserve zero-filled buffer data
	dc.b     $7F,$E0,$C0,$00,$00,$00,$00,$1C,$1D,$F8,$14,$00,$00,$00,$00,$00; Table data bytes
	dc.b     $60,$01,$3F,$F0,$7F,$00,$74,$B8,$20,$00,$00,$00,$00,$00,$00,$00; Table data bytes
	dc.b     $00,$00,$00,$00,$00,$00,$00,$80,$7D,$E0,$C0,$00,$00,$00,$00,$1F; Table data bytes
	dc.b     $F8,$4C,$44,$00,$00,$00,$00,$00,$60,$09,$F8,$70,$5F,$80,$7C,$5C; Table data bytes
	dc.b     $58,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$90; Table data bytes
	dc.b     $98,$FD,$C0,$00,$00,$00,$00,$0F,$FC,$78,$7E,$00,$00,$00,$00,$01; Table data bytes
	dc.b     $70,$11,$02,$28,$B9,$E8,$7C,$1C,$A0,$00,$00,$00,$00,$00,$00,$00; Table data bytes
	dc.b     $00,$00,$00,$00,$00,$00,$01,$F0,$F1,$FF,$C0,$00,$00,$00,$00,$07; Table data bytes
	dc.b     $FE,$60,$3F,$00,$00,$00,$00,$00,$B8,$04,$B0,$34,$F4,$F1,$7E,$1A; Table data bytes
	dc.b     $F4,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07,$F0; Table data bytes
	dc.b     $1B,$FF,$00,$00,$00,$00,$00,$01,$FA,$00,$1F,$00,$00,$00,$00,$00; Table data bytes
	dc.b     $1D,$04,$30,$5C,$B8,$A8,$5E,$78,$F0,$00,$00,$00,$00,$00,$00,$00; Table data bytes
	dc.b     $00,$00,$00,$00,$00,$00,$07,$E0,$02,$FE,$00,$00,$00,$00,$00,$00; Table data bytes
	dc.b     $0D,$01,$1F,$80,$00,$00,$00,$00,$2F,$83,$30,$5C,$7E,$0E,$76,$90; Table data bytes
	dc.b     $F0,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0F,$C0; Table data bytes
	dc.b     $03,$C0,$00,$00,$00,$00,$00,$00,$03,$00,$5F,$C0,$00,$00,$00,$00; Table data bytes
	dc.b     $03,$FD,$A0,$17,$3C,$07,$77,$15,$FA,$00,$00,$08,$00,$00,$00,$00; Table data bytes
	dc.b     $00,$00,$00,$00,$00,$00,$0F,$E0,$02,$80,$00,$00,$00,$00,$00,$00; Table data bytes
	dc.b     $1D,$00,$2B,$C0,$00,$00,$00,$00,$00,$F0,$A4,$0E,$9E,$01,$F3,$5D; Table data bytes
	dc.b     $F5,$00,$00,$50,$00,$41,$01,$00,$00,$00,$00,$00,$00,$00,$1F,$20; Table data bytes
	dc.b     $03,$C0,$00,$00,$00,$00,$00,$00,$27,$F8,$05,$E0,$00,$00,$00,$00; Table data bytes
	dc.b     $00,$84,$58,$07,$06,$00,$71,$FC,$FC,$80,$00,$20,$02,$7F,$C0,$80; Table data bytes
	dc.b     $00,$00,$00,$00,$00,$00,$35,$00,$7F,$A0,$00,$00,$00,$00,$00,$00; Table data bytes
	dc.b     $7B,$BC,$03,$20,$00,$00,$00,$00,$00,$08,$50,$03,$13,$00,$B1,$D4; Table data bytes
	dc.b     $7D,$00,$02,$E0,$00,$AD,$3F,$A0,$00,$00,$00,$00,$00,$00,$27,$01; Table data bytes
	dc.b     $F7,$F8,$00,$00,$00,$00,$00,$00,$D3,$96,$07,$B0,$00,$00,$00,$00; Table data bytes
	dc.b     $00,$00,$00,$03,$C1,$00,$3D,$5D,$7D,$80,$09,$E0,$09,$F4,$03,$82; Table data bytes
	dc.b     $00,$00,$00,$00,$00,$00,$27,$81,$66,$5C,$00,$00,$00,$00,$00,$00; Table data bytes
	dc.b     $08,$C7,$07,$90,$00,$00,$00,$00,$00,$01,$40,$03,$05,$40,$20,$EE; Table data bytes
	dc.b     $78,$A0,$03,$80,$00,$FC,$17,$A6,$00,$00,$00,$00,$00,$00,$27,$83; Table data bytes
	dc.b     $08,$80,$00,$00,$00,$00,$00,$00,$3F,$3F,$83,$D0,$00,$00,$00,$00; Table data bytes
	dc.b     $00,$00,$00,$0B,$00,$80,$35,$5D,$79,$74,$0A,$D8,$0A,$BE,$1F,$A8; Table data bytes
	dc.b     $00,$00,$00,$00,$00,$00,$4F,$0F,$E7,$E0,$00,$00,$00,$00,$00,$00; Table data bytes
	dc.b     $F8,$07,$E3,$F8,$00,$00,$00,$00,$00,$00,$00,$19,$40,$40,$D0,$BD; Table data bytes
	dc.b     $78,$70,$17,$41,$F9,$5F,$7F,$40,$00,$42,$00,$00,$00,$00,$7F,$3F; Table data bytes
	dc.b     $80,$7C,$00,$00,$00,$00,$00,$00,$F0,$51,$17,$78,$00,$00,$00,$00; Table data bytes
	dc.b     $00,$00,$00,$02,$80,$00,$04,$19,$7A,$79,$0F,$0F,$FB,$8F,$FC,$A0; Table data bytes
	dc.b     $93,$F5,$B8,$00,$00,$00,$FF,$A6,$48,$38,$00,$00,$00,$00,$00,$03; Table data bytes
	dc.b     $43,$F2,$87,$BC,$00,$00,$00,$00,$00,$00,$00,$01,$80,$00,$20,$1C; Table data bytes
	dc.b     $3C,$BD,$1C,$3F,$F5,$7F,$AA,$7F,$FF,$FF,$E4,$00,$00,$00,$F7,$8B; Table data bytes
	dc.b     $7F,$1B,$00,$00,$00,$00,$00,$07,$18,$01,$E3,$FC,$00,$00,$00,$00; Table data bytes
	dc.b     $00,$00,$00,$00,$00,$00,$00,$2C,$14,$3E,$3D,$3E,$96,$9F,$FA,$7D; Table data bytes
	dc.b     $F8,$30,$40,$00,$00,$01,$FE,$3E,$00,$E7,$00,$00,$00,$00,$00,$04; Table data bytes
	dc.b     $63,$1B,$9F,$FC,$00,$00,$00,$00,$00,$00,$00,$00,$40,$00,$00,$2C; Table data bytes
	dc.b     $1C,$0F,$B5,$1D,$02,$9F,$FC,$7E,$84,$00,$00,$00,$00,$00,$FF,$EE; Table data bytes
	dc.b     $66,$32,$00,$00,$00,$00,$00,$01,$8F,$F7,$0F,$80,$00,$00,$00,$00; Table data bytes
	dc.b     $00,$00,$00,$00,$00,$00,$00,$04,$04,$0E,$F3,$70,$00,$6C,$1E,$5F; Table data bytes
	dc.b     $C4,$18,$00,$00,$00,$00,$0F,$C7,$FF,$CC,$00,$00,$00,$00,$00,$05; Table data bytes
	dc.b     $79,$9D,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03; Table data bytes
	dc.b     $19,$06,$E1,$74,$00,$E6,$1E,$8F,$CF,$FE,$00,$00,$00,$00,$00,$04; Table data bytes
	dc.b     $E4,$77,$00,$00,$00,$00,$00,$03,$FF,$BF,$00,$00,$00,$00,$00,$00; Table data bytes
	dc.b     $00,$00,$00,$00,$00,$00,$00,$04,$80,$07,$C0,$7C,$01,$C7,$5F,$AF; Table data bytes
	dc.b     $FF,$82,$00,$00,$00,$00,$00,$03,$EF,$FE,$00,$00,$00,$00,$00,$03; Table data bytes
	dc.b     $3F,$EA,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00; Table data bytes
	dc.b     $80,$07,$C0,$7E,$00,$D5,$13,$E7,$FC,$40,$00,$00,$00,$00,$00,$02; Table data bytes
	dc.b     $F7,$E7,$00,$00,$00,$00,$00,$00,$FF,$20,$00,$00,$00,$00,$00,$00; Table data bytes
	dc.b     $00,$00,$00,$00,$00,$00,$00,$00,$00,$0B,$80,$1F,$81,$43,$60,$9F; Table data bytes
	dc.b     $90,$00,$00,$00,$00,$00,$00,$01,$33,$FC,$00,$00,$00,$00,$00,$00; Table data bytes
	dc.b     $FC,$E0,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00; Table data bytes
	dc.b     $00,$22,$00,$4F,$FE,$83,$40,$3F,$40,$00,$00,$00,$00,$00,$00,$00; Table data bytes
	dc.b     $1C,$FC,$00,$00,$00,$00,$00,$00,$FC   ; Table data bytes
	ds.b     17                                    ; Reserve zero-filled buffer data
	dc.b     $40,$00,$FE,$08,$00,$97,$02,$00,$00,$00,$00,$00,$00,$00,$01,$FC; Table data bytes
	dc.b     $00,$00,$00,$00,$00,$01,$9E           ; Table data bytes
	ds.b     17                                    ; Reserve zero-filled buffer data
	dc.b     $C0,$00,$00,$06,$80,$03,$10,$02,$C0,$00,$00,$00,$00,$00,$03,$D6; Table data bytes
	dc.b     $00,$00,$00,$00,$00,$08,$0E           ; Table data bytes
	ds.b     22                                    ; Reserve zero-filled buffer data
	dc.b     $03,$FF,$D4,$20,$00,$00,$00,$00,$00,$01,$C0,$40,$00,$00,$00,$00; Table data bytes
	dc.b     $38,$07                               ; Table data bytes
	ds.b     22                                    ; Reserve zero-filled buffer data
	dc.b     $01,$7C,$03,$30,$00,$00,$00,$00,$00,$03,$00,$40,$00,$00,$00,$00; Table data bytes
	dc.b     $22,$17                               ; Table data bytes
	ds.b     22                                    ; Reserve zero-filled buffer data
	dc.b     $01,$80,$15,$E8,$00,$00,$00,$00,$00,$03,$A1,$00,$00,$00,$00,$00; Table data bytes
	dc.b     $0C,$0E                               ; Table data bytes
	ds.b     23                                    ; Reserve zero-filled buffer data
	dc.b     $40,$17,$C0,$00,$00,$00,$00,$00,$03,$81,$C0,$00,$00,$00,$00,$03; Table data bytes
	dc.b     $F8                                   ; Table data bytes
	ds.b     22                                    ; Reserve zero-filled buffer data
	dc.b     $04,$00,$10,$40,$00,$00,$00,$00,$00,$00,$7F,$00,$00,$00,$00,$00; Table data bytes
	dc.b     $0F,$F0                               ; Table data bytes
	ds.b     32                                    ; Reserve zero-filled buffer data
	dc.b     $3F,$C0,$00,$00,$00,$00,$39,$F0       ; Table data bytes
	ds.b     32                                    ; Reserve zero-filled buffer data
	dc.b     $3E,$F0,$00,$00,$00,$00,$0F,$F8       ; Table data bytes
	ds.b     32                                    ; Reserve zero-filled buffer data
	dc.b     $FF,$80,$00,$00,$00,$00,$00,$7E       ; Table data bytes
	ds.b     31                                    ; Reserve zero-filled buffer data
	dc.b     $03,$F0,$00,$00,$00,$00,$00,$00,$0B,$80; Table data bytes
	ds.b     30                                    ; Reserve zero-filled buffer data
	dc.b     $07,$40,$00,$00,$00,$00,$00,$00,$01,$40; Table data bytes
	ds.b     30                                    ; Reserve zero-filled buffer data
	dc.b     $15,$20,$00,$00,$00,$00,$00,$00,$01,$10; Table data bytes
	ds.b     30                                    ; Reserve zero-filled buffer data
	dc.b     $52,$00,$00,$00,$00,$00,$00,$00,$00,$84; Table data bytes
	ds.b     30                                    ; Reserve zero-filled buffer data
	dc.b     $A0,$00,$00,$00,$00,$00,$00,$00,$00,$22; Table data bytes
	ds.b     29                                    ; Reserve zero-filled buffer data
	dc.b     $02,$10,$00,$00,$00,$00,$00,$00,$00,$00,$15; Table data bytes
	ds.b     29                                    ; Reserve zero-filled buffer data
	dc.b     $04,$40,$00,$00,$00,$00,$00,$00,$00,$00,$0C,$C0; Table data bytes
	ds.b     28                                    ; Reserve zero-filled buffer data
	dc.b     $0A,$80,$00,$00,$00,$00,$00,$00,$00,$00,$02,$A0; Table data bytes
	ds.b     28                                    ; Reserve zero-filled buffer data
	dc.b     $15,$00,$00,$00,$00,$00,$00,$FE,$00,$00,$00,$50; Table data bytes
	ds.b     28                                    ; Reserve zero-filled buffer data
	dc.b     $2A,$00,$00,$01,$FC,$00,$00,$DF,$80,$00,$04,$FC; Table data bytes
	ds.b     28                                    ; Reserve zero-filled buffer data
	dc.b     $FC,$00,$00,$0F,$DC,$00,$01,$FF,$FF,$FF,$FE,$FC; Table data bytes
	ds.b     27                                    ; Reserve zero-filled buffer data
	dc.b     $01,$FB,$FF,$FF,$FF,$FE,$00,$07,$FF,$FF,$FF,$FE,$BF,$F8; Table data bytes
	ds.b     26                                    ; Reserve zero-filled buffer data
	dc.b     $7F,$FF,$FF,$FF,$FF,$FF,$00,$0F,$F8,$1F,$FF,$FF,$FF,$7F,$C0; Table data bytes
	ds.b     24                                    ; Reserve zero-filled buffer data
	dc.b     $1F,$FB,$FF,$EF,$FF,$E0,$FF,$80,$3F,$E3,$C0,$00,$3F,$80,$FF,$80; Table data bytes
	ds.b     24                                    ; Reserve zero-filled buffer data
	dc.b     $0F,$FC,$07,$E0,$00,$0F,$1F,$F0,$3F,$00,$FE,$FE,$77,$AF,$FF; Table data bytes
	ds.b     25                                    ; Reserve zero-filled buffer data
	dc.b     $07,$FF,$B7,$B1,$EF,$FC,$07,$F0,$7E,$07,$FF,$FF,$FF,$FD,$FC; Table data bytes
	ds.b     26                                    ; Reserve zero-filled buffer data
	dc.b     $FF,$FF,$FF,$FF,$FF,$81,$F8,$34,$00,$00,$1F,$0F; Table data bytes
	ds.b     29                                    ; Reserve zero-filled buffer data
	dc.b     $03,$C7,$E0,$00,$00,$B0               ; Table data bytes
	ds.b     8704                                  ; Reserve zero-filled buffer data (tuned for disk/MFM pass; keeps Hunk ~79000)
