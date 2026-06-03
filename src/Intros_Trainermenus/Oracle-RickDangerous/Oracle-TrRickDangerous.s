; ============================================================================
; Source  : Trainermenu for Rick Dangerous by Weetibix/Oracle
; Creator : Reconstructed by Volker Schwaberow <volker@schwaberow.de>
; ============================================================================
CUSTOM          EQU     $dff000         ; Base address of Custom Chip registers.
VHPOSR          EQU     $dff006         ; Read vertical and horizontal raster position.
DMACON          EQU     $dff096         ; DMA control register write offset.
INTENA          EQU     $dff09a         ; Interrupt enable register write offset.
INTREQR         EQU     $dff01e         ; Interrupt request register read offset.
COP1LCH         EQU     $dff084         ; Copper 1 pointer high register offset.
COPJMP1         EQU     $dff08a         ; Copper 1 trigger register offset.
CIAA_SDR        EQU     $bfec01         ; CIA-A Serial Data Register (keyboard input).
CIAA_CRA        EQU     $bfee01         ; CIA-A Control Register A (keyboard handshake).
ExecBase        EQU     $00000004       ; Pointer to Exec library base.
Forbid          EQU     -132            ; Exec Forbid vector offset.

; Kickstart ROM constants
KICKSTART_ROM   EQU     $fc5000         ; Base address of Kickstart ROM.
ROM_SIGNATURE   EQU     $186c6c         ; Kickstart ROM signature checked.

; Game memory layout and execution parameters
GAME_SRC        EQU     $25000          ; Location of raw game copy in RAM.
GAME_DST        EQU     $15000          ; Destination address to run the game from.
GAME_LIMIT      EQU     $70600          ; Upper boundary of copied game code.
GAME_STACK      EQU     $80000          ; Safe stack pointer for the game.
GAME_ENTRY      EQU     $152e0          ; Unpacked game entry point.

; Game patches
PATCH_LIVES     EQU     $55e3f          ; Address of Infinite Lives patch in game.
PATCH_AMMO      EQU     $55c6b          ; Address of Unlimited Ammo patch in game.
PATCH_BOMBS     EQU     $55b97          ; Address of Unlimited Bombs patch in game.
PATCH_LEVEL     EQU     $530f9          ; Address of Selected Starting Level in game.

; Exception vectors
PRIV_VIOL_VEC   EQU     $20             ; Privilege Violation Exception Vector address.

; Screen layout constants
SCREEN_OPTIONS_DEST EQU $708c8          ; Location in playfield buffer where YES/NO options are drawn.


        ORG     $70000                  ; Menu binary expects to run at absolute address $70000.

; ============================================================================
; Function: Start
; Purpose : Entry point of the trainer menu. Initializes graphics, interrupts,
;           and waits for user choice or timer expiry.
; ============================================================================
Start:
        movem.l d0-d7/a0-a6,-(a7)       ; Save all CPU registers before taking over hardware.
        movea.l ExecBase.l,a6           ; Point a6 to Exec base for library calls.
        jsr     Forbid(a6)              ; Disable multitasking to gain exclusive control.
        move.l  #$8000,d0               ; Loop counter for ROM scanning.
        lea.l   KICKSTART_ROM.l,a0      ; Scan range starting at Kickstart ROM base.
ScanLoop:
        cmpi.l  #ROM_SIGNATURE,(a0)+    ; Check if signature is found at current address.
        beq.s   ScanFound               ; Branch to initialize once signature is found.
        dbra    d0,ScanLoop             ; Otherwise continue scan until limit reached.
ScanFound:
        lea.l   -$e4(a0),a0             ; Compute adjusted ROM pointer from match address.
        move.l  a0,KickstartROM_Ptr.l   ; Store Kickstart ROM pointer in trainer state.
        move.w  #7,LivesCounter.l       ; Set default starting lives to 7.
        move.w  #$bf6,OptionsStatus.l   ; Set default trainer options status word.
        bsr.w   ClearBuffers            ; Clear screen and temporary state buffers.
        move.w  #$20,INTENA.l           ; Disable vertical blank interrupt.
        move.w  #$8380,DMACON.l         ; Enable Copper, Bitplane, and Master DMA.
        lea.l   CopperList(pc),a0       ; Point a0 to the menu's copper list.
        move.l  a0,COP1LCH.l            ; Write Copper list address to COP1LCH.
        tst.w   COPJMP1.l               ; Trigger Copper to start menu display.
        lea.l   ScrollerBuffer.l,a2     ; Point a2 to the scroller/info text.
        bsr.w   PrintText_Start+2       ; Draw the static instructions screen (overlap target).
MainLoop:
        bsr.w   DrawOptions_AltTarget   ; Redraw current selection for YES/NO options.
        bsr.w   ReadKeyboard_Start+2    ; Check keyboard state synced with vertical blank (overlap target).
        cmpi.b  #$50,LastKeyCode.l      ; Was F1 key pressed?
        bne.s   NotF1                   ; Skip option 1 toggle if not pressed.
        eori.b  #1,LivesOptionState.l   ; Toggle Infinite Lives state.
NotF1:
        cmpi.b  #$51,LastKeyCode.l      ; Was F2 key pressed?
        bne.s   NotF2                   ; Skip option 2 toggle if not pressed.
        eori.b  #1,AmmoOptionState.l    ; Toggle Unlimited Explosives state.
NotF2:
        cmpi.b  #$52,LastKeyCode.l      ; Was F3 key pressed?
        bne.w   NotF3                   ; Skip option 3 toggle if not pressed (16-bit branch).
        eori.b  #1,BombsOptionState.l   ; Toggle Constant Ammo state.
NotF3:
        cmpi.b  #$53,LastKeyCode.l      ; Was F4 key pressed?
        bne.w   NotF4                   ; Skip starting level increment if not pressed (16-bit branch).
        cmpi.b  #4,SelectedStartingLevel.l ; Check if starting level has reached maximum (4).
        beq.w   NotF4                   ; Prevent starting level from exceeding 4 (16-bit branch).
        addq.b  #1,SelectedStartingLevel.l ; Increment selected starting level.
NotF4:
        cmpi.b  #$54,LastKeyCode.l      ; Was F5 key pressed?
        bne.w   NotF5                   ; Skip starting level decrement if not pressed (16-bit branch).
        tst.b   SelectedStartingLevel.l ; Check if starting level is at minimum (0).
        beq.w   NotF5                   ; Prevent starting level from going below 0 (16-bit branch).
        subq.b  #1,SelectedStartingLevel.l ; Decrement selected starting level.
NotF5:
        cmpi.b  #$44,LastKeyCode.l      ; Was RETURN key pressed to start the game?
        bne.w   MainLoop                ; Continue displaying menu if RETURN not pressed (16-bit branch).
        bsr.w   ExitSequence_Start+4    ; Prepare the game copy loop once key is pressed (overlap target).
        moveq   #0,d1                   ; Clear helper register for poking options.
        tst.b   LivesOptionState.l      ; Is Infinite Lives option enabled?
        beq.s   PokeAmmo                ; Skip poke if option is disabled.
        move.b  d1,PATCH_LIVES.l        ; Apply patch for infinite lives.
PokeAmmo:
        tst.b   AmmoOptionState.l       ; Is Unlimited Ammo option enabled?
        beq.s   PokeBombs               ; Skip poke if option is disabled.
        move.b  d1,PATCH_AMMO.l         ; Apply patch for unlimited ammo.
PokeBombs:
        tst.b   BombsOptionState.l      ; Is Unlimited Bombs option enabled?
        beq.s   PokeLevel               ; Skip poke if option is disabled.
        move.b  d1,PATCH_BOMBS.l        ; Apply patch for unlimited bombs.
PokeLevel:
        move.b  SelectedStartingLevel.l,PATCH_LEVEL.l ; Write selected starting level to game state.
        move.w  #$7fff,INTENA.l         ; Restore system interrupts state.
        move.w  #$7fff,DMACON.l         ; Restore original DMA registers.
        movem.l (a7)+,d0-d7/a0-a6       ; Restore saved registers before launching game.
        lea.l   SupervisorEntry(pc),a0  ; Load address of supervisor mode entry.
        move.l  a0,PRIV_VIOL_VEC.w      ; Set Privilege Violation exception vector to our handler.
SupervisorEntry:
        move.w  #$2700,sr               ; Execute in user mode to switch, then runs in supervisor.
        dc.w    $41f9                   ; Opcode of lea.l GAME_SRC.l, a0
CopyLoop:
        dc.w    GAME_SRC>>16
        dc.w    GAME_SRC&$ffff          ; Address of lea.l GAME_SRC.l, a0 ($25000)
        lea.l   GAME_DST.l,a1           ; Point a1 to destination memory address.
CopyLoop_Body:
        move.l  (a0)+,(a1)+             ; Copy game binary data longword by longword.
        cmpa.l  #GAME_LIMIT,a0          ; Have we finished copying up to target boundary?
        bne.w   CopyLoop_Body           ; Loop until copy is completed (16-bit branch).
        lea.l   GAME_STACK.l,a7         ; Reset system stack pointer to a safe area.
        jmp     GAME_ENTRY.l            ; Jump to the unpacked game entry point.

; ============================================================================
; Function: ClearBuffers
; Purpose : Wipes the screen playfield and variables storage space to zero.
; ============================================================================
ClearBuffers:
        lea.l   ClearBuffers_Start(pc),a0 ; Start of playfield and BSS memory.
        move.l  #$7ef,d0                ; Set counter to clear 8128 bytes (2032 longwords).
ClearLoop:
        clr.l   (a0)+                   ; Zero four bytes of data.
        dbra    d0,ClearLoop            ; Loop until complete buffer is wiped.
        rts                             ; Return to caller.

; ============================================================================
; Data: CopperList
; Purpose : Configures Amiga display parameters, window size, and color palette.
; ============================================================================
CopperList:
        dc.w    $0180,$000f             ; Set background color register (COLOR00) to blue-black.
        dc.w    $0100,$0000             ; Disable playfield display initially.
        dc.w    $3701,$fffe             ; Wait for raster line 55.
        dc.w    $0102,$0000             ; Set horizontal scroll register (BPLCON1) to 0.
        dc.w    $0092,$0038             ; Set display data start (DDFSTRT) to $0038.
        dc.w    $0094,$00d0             ; Set display data stop (DDFSTOP) to $00d0.
        dc.w    $008e                   ; Set display window start (DIWSTRT) register.
PrintText_AltTarget:
        dc.w    $1c81                   ; Set display window start (DIWSTRT) to $1c81.
        dc.w    $0090,$f4c1             ; Set display window stop (DIWSTOP) to $f4c1.
        dc.w    $0108,$0000             ; Clear bitplane priority register (BPLCON2).
        dc.w    $0100,$1200             ; Configure BPLCON0 for 1 bitplane, color display enabled.
        dc.w    $00e0,$0000             ; Clear BPL1PTH.
        dc.w    $00e2,$0000             ; Clear BPL1PTL.
        dc.w    $0182,$0fff             ; Set text color register (COLOR01) to white.
        dc.w    $fffe                   ; Terminate the Copper List.

; ============================================================================
; Function: PrintText
; Purpose : Renders a null-terminated font character string to screen.
; ============================================================================
PrintText_Start:
        lea.l   Buffer_5F4(pc),a1       ; Load screen buffer address (Buffer_5F4 starts at $705f4).
PrintText:
        moveq   #$27,d1                 ; Print 40 characters per line (d1 count).
PrintText_Loop:
        movea.l FontGraphics_Ptr(pc),a0 ; Load base address of the font graphics.
        clr.l   d7                      ; Clear upper bytes of character offset.
        move.b  (a2)+,d7                ; Read next character index from string pointer.
        bne.s   DrawChar                ; Draw character if it is non-zero.
        rts                             ; Return once null-terminator is reached.
DrawChar:
        ; Notes: The font graphics sheet is stored in a planar layout with a stride of 192
        ;        bytes per character row. The screen buffer uses a stride of 40 bytes per line.
        adda.l  d7,a0                   ; Offset font pointer to selected character.
        move.b  $c0(a0),0.w(a1)         ; Copy font row 0 (y=0: offset 192) to screen row 0.
        move.b  $180(a0),$28.w(a1)      ; Copy font row 1 (y=1: offset 384) to screen row 1 (offset 40).
        move.b  $240(a0),$50.w(a1)      ; Copy font row 2 (y=2: offset 576) to screen row 2 (offset 80).
        move.b  $300(a0),$78.w(a1)      ; Copy font row 3 (y=3: offset 768) to screen row 3 (offset 120).
        move.b  $3c0(a0),$a0.w(a1)      ; Copy font row 4 (y=4: offset 960) to screen row 4 (offset 160).
        move.b  $480(a0),$c8.w(a1)      ; Copy font row 5 (y=5: offset 1152) to screen row 5 (offset 200).
        move.b  $540(a0),$f0.w(a1)      ; Copy font row 6 (y=6: offset 1344) to screen row 6 (offset 240).
        move.b  $600(a0),$118.w(a1)     ; Copy font row 7 (y=7: offset 1536) to screen row 7 (offset 280).
        addq.l  #1,a1                   ; Advance screen column pointer by 1 byte.
        dbra    d1,PrintText_Loop       ; Loop until 40 characters have been drawn.
        moveq   #$27,d1                 ; Reset characters count for next line.
        adda.l  #$140,a1                ; Stride screen pointer by 320 bytes (8 raster lines down).
        bra.s   PrintText_Loop          ; Continue printing next line.

; ============================================================================
; Data: InfoText
; Purpose : Trainer instructions and credits text (null-terminated).
; ============================================================================
InfoText:
        dc.b    " RICK DANGEROUS megatrainer (C)WEETIBIX "
        dc.b    "-------------------------------------- F"
        dc.b    "1   - Infinite lives,       = NO   F2   "
        dc.b    "- Unlimited explosives,   = NO   F3   - "
        dc.b    "Constant ammo,        = NO   F4/F5  - St"
        dc.b    "arting level,       = 00   RETURN - Begi"
        dc.b    "n game.                                 "
        dc.b    "                          During game, H"
        dc.b    "ELP key toggles enemy   collision ON/OFF"
        dc.b    ".Use this to escape pitsand holes.      "
        dc.b    "                                        "
        dc.b    "                       Cracked by WEETIB"
        dc.b    "IX on August 1st 1989   Original supplie"
        dc.b    "d by the Annihilator      and released t"
        dc.b    "hrough ORACLE.                          "
        dc.b    "                             ORACLE memb"
        dc.b    "ers are:                   -------------"
        dc.b    "----                  Rogue - Arcade mas"
        dc.b    "ter         The General - Vertigo - Anni"
        dc.b    "hilator   ",0,0

; ============================================================================
; Function: ReadKeyboard
; Purpose : Checks keyboard buffer synchronized with vertical blank interrupt.
; ============================================================================
ReadKeyboard:
        move.w  INTREQR.l,d1            ; Read INTREQR.
        btst    #5,d1                   ; Test if VERTB vertical blank bit is set.
        beq.s   ReadKeyboard_Exit       ; Exit immediately if no vertical blank occurred.
        move.b  CIAA_SDR.l,d0           ; Read raw key code from keyboard matrix register.
        not.b   d0                      ; Invert active-low raw key code bits.
        ror.b   #1,d0                   ; Normalize bits by rotating right.
        move.w  #$600,d7                ; Load delay loop counter.
ReadKeyboard_Delay:
        dbra    d7,ReadKeyboard_Delay   ; CPU delay loop.
ReadKeyboard_Start:
        andi.b  #$bf,CIAA_CRA.l         ; Handshake keyboard via CIAA PRB bit 6.
        cmp.b   LastKeyCode.l,d0        ; Compare key code with last stored key code.
        beq.s   ReadKeyboard            ; If unchanged, loop back to wait next frame.
        move.b  d0,LastKeyCode.l        ; Store new raw key code in menu state.
ReadKeyboard_Exit:
        rts                             ; Return to caller.

OptionsStateTable:
        dc.l    0                       ; Options state table (relocated to LivesOptionState at runtime).

; ============================================================================
; Function: ExitSequence
; Purpose : Handles screen sync, decrementing timer, and triggering launch.
; ============================================================================
ExitSequence:
        cmpi.b  #$ff,VHPOSR.l           ; Wait until raster beam is at line 255.
WaitBeam255:
        bne.s   ExitSequence            ; Stay in wait loop if not at line 255.
WaitBeam254:
        cmpi.b  #$fe,VHPOSR.l           ; Wait until raster beam is at line 254.
        bne.s   WaitBeam254             ; Loop until next frame starts.
        move.w  TrainerTimer.l,d0       ; Read active trainer timer value.
        subi.w  #$110,d0                ; Subtract frame step value from timer.
ExitSequence_Start:
        move.w  d0,TrainerTimer.l       ; Update active trainer timer value.
        bpl.s   ExitSequence            ; If timer hasn't expired, repeat wait loop.
        bsr.w   CopyLoop                ; Exit to game copying sequence.
        move.w  #$fff,TrainerTimer.l    ; (Dead code) Reset timer value.
        rts                             ; Return to caller.

; ============================================================================
; Function: DrawOptions
; Purpose : Formats and prints option state strings (YES/NO) and start level.
; ============================================================================
DrawOptions:
        lea.l   SCREEN_OPTIONS_DEST(pc),a1 ; Point a1 to screen destination for option strings.
        lea.l   OptionsStateTable(pc),a3 ; Load options state table base pointer.
        moveq   #2,d6                   ; Print 3 trainer options.
DrawOptions_Loop:
        clr.l   d0                      ; Clear d0.
        move.b  (a3)+,d0                ; Get option status value (0 = NO, 1 = YES).
        mulu.w  #4,d0                   ; Multiply index by 4 (length of status string + null).
        lea.l   YES_NO_StringsBlock.l,a2 ; Point to strings block.
        adda.l  d0,a2                   ; Adjust pointer to target string (NO or YES).
        bsr.w   PrintText_AltTarget     ; Draw the option text on screen.
        dc.w    $d3fc,$0000             ; Opcode/prefix of adda.l #$165, a1
DrawOptions_AltTarget:
        dc.w    $0165                   ; Displacement of adda.l #$165, a1
        dbra    d6,DrawOptions_Loop     ; Loop for next option string.
        move.b  SelectedStartingLevel.l,d0 ; Get selected starting level number.
        addi.b  #$31,d0                 ; Convert level number to ASCII digit.
        move.b  d0,LevelASCIIBuffer.l   ; Store ASCII digit in starting level string buffer.
        lea.l   LevelString.l,a2        ; Point a2 to level string.
        bsr.w   PrintText_AltTarget     ; Draw starting level digit.
        rts                             ; Return to caller.

; ============================================================================
; Data: YES_NO_Strings
; Purpose : Option status strings (NO / YES) and level digits.
; ============================================================================
YES_NO_Strings:
        dc.b    "NO ",0                 ; Option state strings
        dc.b    "YES",0
        dc.b    "01",0,0
        dc.w    0
        dc.w    $40ff

; ============================================================================
; Variables & BSS Buffers (located in the file padding)
; ============================================================================
        ds.b    $705f0-*                ; Zero-fill padding to FontGraphics_Ptr
FontGraphics_Ptr:
        ds.l    1                       ; Variable: base address of font graphics
Buffer_5F4:
        ds.w    1                       ; Variable: unused buffer
ClearBuffers_Start:
        ds.w    0                       ; Target starting address for ClearBuffers loop

        ds.b    $707ae-*                ; Zero-fill padding to LivesCounter
LivesCounter:
        ds.w    1                       ; Variable: lives count (default=7)
        ds.w    1                       ; Unused padding word at $707b0
OptionsStatus:
        ds.w    1                       ; Variable: option selection status (default=$bf6)
        ds.w    1                       ; Unused padding word at $707b4
TrainerTimer:
        ds.w    1                       ; Variable: menu countdown timer (default=$fff)

        ds.b    $70810-*                ; Zero-fill padding to ScrollerBuffer
ScrollerBuffer:
        ds.b    $70b68-*                ; Buffer for scroller / dynamic text

LastKeyCode:
        ds.b    1                       ; Variable: last keyboard scan code
        ds.b    1                       ; Zero padding
LivesOptionState:
        ds.b    1                       ; Variable: Infinite Lives option state (0=NO, 1=YES)
AmmoOptionState:
        ds.b    1                       ; Variable: Unlimited Ammo option state (0=NO, 1=YES)
BombsOptionState:
        ds.b    1                       ; Variable: Unlimited Bombs option state (0=NO, 1=YES)

        ds.b    $70be6-*                ; Zero-fill padding to YES_NO_StringsBlock
YES_NO_StringsBlock:
        ds.b    8                       ; Pointer block or dynamic target string memory (relocated strings at runtime)
LevelString:
        ds.b    1                       ; String buffer
LevelASCIIBuffer:
        ds.b    1                       ; Dynamic ASCII digit buffer
        ds.b    1                       ; Zero padding
SelectedStartingLevel:
        ds.b    1                       ; Variable: starting level (0 to 4)
KickstartROM_Ptr:
        ds.l    1                       ; Variable: scanned Kickstart ROM signature pointer

        ds.b    $72000-*                ; Pad binary to exactly 8192 bytes
