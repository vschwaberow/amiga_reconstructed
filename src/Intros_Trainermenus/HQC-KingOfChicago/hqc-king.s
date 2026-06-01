; ============================================================================
; Source  : hqc-king.s
; Purpose : Reconstructed Amiga Intro source for King of Chicago (HQC, 1988)
; Creator : Reconstructed by Volker Schwaberow <volker@schwaberow.de>
; ============================================================================

; --- Amiga Hardware Register offsets ---
CUSTOM          EQU     $dff000         ; Base address of the Amiga Custom Chip registers.
DMACON          EQU     $096            ; DMA control register write offset.
INTENA          EQU     $09a            ; Interrupt enable register write offset.
INTREQ          EQU     $09c            ; Interrupt request register write offset.
COLOR00         EQU     $180            ; Background color register offset.
ExecBase        EQU     $00000004       ; Exec library base pointer stored at address 4.

; --- Exec Library Vector offsets ---
Forbid          EQU     -132            ; Disable task switching.
Permit          EQU     -138            ; Enable task switching.
OpenLibrary     EQU     -408            ; Open library.
CloseLibrary    EQU     -414            ; Close library.

	ORG     $70002                  ; Segment base address in memory

; ============================================================================
; Data Block: Segment Leading Zero Padding (0x0000 - 0x002A)
; ============================================================================
	ds.b     16                            ; Zeros padding
	ds.b     16                            ; Zeros padding
	ds.b     6                             ; Zeros padding
Var_SavedExecVector:
	ds.b     4                             ; Zeros padding

; ============================================================================
; Function: Start
; Purpose : Main program initialization, takeover, VBlank setup, and event loop.
; ============================================================================
Start:
        movem.l  d0-d7/a0-a6,-(a7)                    ; Save all working registers on stack at intro startup (file offset: 0x002A)
        move.l   #$8100,$dff096.l                     ; Disable all OCS hardware DMA channels except copper (file offset: 0x002E)
        move.w   #$8100,$dff096.l                     ; Acknowledge and clear DMA controller status        (file offset: 0x0038)
        movea.l  ExecBase.l,a6                        ; Load ExecBase base pointer from absolute address $4 (file offset: 0x0040)
        lea      Var_0428(pc),a1                      ; Point to standard Amiga OS 'graphics.library' name string (file offset: 0x0046)
        jsr      -$198(a6)                            ; Call OpenLibrary to open graphics library          (file offset: 0x004A)
        move.l   d0,Var_GfxBase.l                     ; Store returned GfxBase pointer in graphics.library string slot (GfxBase trick!) (file offset: 0x004E)
        jsr      -$84(a6)                             ; Call Exec/Forbid to disable multitasking while in intro (file offset: 0x0054)
        movea.l  Var_GfxBase(pc),a6                   ; Load GfxBase base pointer for graphics library routines (file offset: 0x0058)
        lea      Var_SavedExecVector.l,a0             ; Point to variable where we will backup system vector (file offset: 0x005C)
        move.l   $32(a6),(a0)                         ; Backup the system vector at offset $32 from GfxBase (file offset: 0x0062)
        lea      Var_043A(pc),a0                      ; Point to our dynamically built copper list buffer  (file offset: 0x0066)
        move.w   #$1,d0                               ; Set screen display parameter 1                     (file offset: 0x006A)
        move.w   #$160,d1                             ; Set screen display width to 352 pixels             (file offset: 0x006E)
        move.w   #$c8,d2                              ; Set screen display height to 200 pixels            (file offset: 0x0072)
        jsr      -$186(a6)                            ; Call graphics library function to configure screen layout (file offset: 0x0076)
        move.l   #$50000,Var_0442.l                   ; Set playfield bitmap graphics load address buffer to $50000 (file offset: 0x007A)
        lea      Var_046A(pc),a1                      ; Point to background graphics structure logo header (file offset: 0x0084)
        jsr      -$c6(a6)                             ; Call graphics library structure initialization function (file offset: 0x0088)
        move.l   #Var_043A,Var_046E.l                 ; Initialize default viewport copper list pointer in playfield state (file offset: 0x008C)
        lea      Var_046A(pc),a1                      ; Point to background graphics structure logo header again (file offset: 0x0096)
        jsr      -$30(a6)                             ; Call graphics library routine to render the logo background (file offset: 0x009A)
        lea      Table_RectFillCoordinates(pc),a5                      ; Point to RectFill coordinate offsets table (file offset: 0x009E)
Loop_RectFillInterfaceElements:
        lea      Var_046A(pc),a1                      ; Point to background graphics logo header descriptor (file offset: 0x00A2)
        clr.l    d0                                   ; Clear registers d0-d3 for blitter function arguments (file offset: 0x00A6)
        clr.l    d1                                   ; Clear register d1                                  (file offset: 0x00A8)
        clr.l    d2                                   ; Clear register d2                                  (file offset: 0x00AA)
        clr.l    d3                                   ; Clear register d3                                  (file offset: 0x00AC)
        move.w   (a5)+,d0                             ; Read next character horizontal offset from scroll description (file offset: 0x00AE)
        move.w   (a5)+,d1                             ; Read next character width from scroll description  (file offset: 0x00B0)
        move.w   (a5)+,d2                             ; Read next character vertical offset from scroll description (file offset: 0x00B2)
        move.w   (a5)+,d3                             ; Read next character height from scroll description (file offset: 0x00B4)
        subi.w   #$11,d1                              ; Apply horizontal spacing bounce displacement offset (file offset: 0x00B6)
        subi.w   #$11,d3                              ; Apply vertical spacing bounce displacement offset  (file offset: 0x00BA)
        jsr      -$132(a6)                            ; Call graphics library RectFill routine to draw screen layout (file offset: 0x00BE)
        cmpa.l   #Table_RectFillCoordinates_Sentinel,a5              ; Compare RectFill coordinates pointer to end limit to check completion (file offset: 0x00C2)
        bne.b    Loop_RectFillInterfaceElements                               ; Loop back to draw remaining boxes of user interface layout (file offset: 0x00C8)
        move.l   #Sub_AnimateBounceLogo,$32(a6)       ; Set custom VBlank VBR handler vector hook to our bounce routine (file offset: 0x00CA)
        move.l   #Str_ScrollingText_Greetings,Var_ScrollText_CharPointer.l   ; Set starting scroll text greetings address pointer (file offset: 0x00D2)
        move.w   #$6000,d0                            ; Load busy wait iteration delay timer (24576 frames) (file offset: 0x00DC)
Loop_HardwareDelay:
        dbra     d0,Loop_HardwareDelay                            ; Stabilize system hardware in busy wait delay loop  (file offset: 0x00E0)
        bsr.w    InitMusic                               ; Call custom sound synthesizer synthesizer initializer (file offset: 0x00E4)
        move.w   #$4000,$dff09a.l                     ; Disable hardware sound audio interrupts in INTENA  (file offset: 0x00E8)
        move.l   $6c.l,Var_SavedVBlankVector.l        ; Backup the original system Level 3 VBlank interrupt vector (file offset: 0x00F0)
        move.l   #VBlankHandler,$6c.l                 ; Install our custom Level 3 VBlank interrupt handler (file offset: 0x00FA)
        move.w   #$c010,$dff09a.l                     ; Re-enable vertical blanking and master interrupts  (file offset: 0x0104)
        bra.w    ExitIntro                            ; Jump to the main idle looping block to let intro run (file offset: 0x010C)
VBlankHandler:
        movem.l  d0-d7/a0-a6,-(a7)                    ; Save all registers on stack at start of VBlank interrupt (file offset: 0x0110)
        move.l   #$12345678,$24.w                     ; Write debug marker value to stack frame location $24 (file offset: 0x0114)
        move.w   $dff01e.l,d0                         ; Read Amiga hardware interrupt request status (INTREQR) (file offset: 0x011C)
        move.w   d0,$dff09c.l                         ; Acknowledge and clear vertical blanking interrupt request (file offset: 0x0122)
        btst     #$4,d0                               ; Test whether the Level 3 VBlank interrupt flag is active (file offset: 0x0128)
        bne.b    VBlank_HandleActiveVBlank                               ; If set, continue executing VBlank interrupt frame code (file offset: 0x012C)
        bra.w    VBlank_ExitInterrupt                               ; Otherwise, exit Level 3 interrupt handler immediately (file offset: 0x012E)
VBlank_HandleActiveVBlank:
        move.l   #$8b,d7                              ; Load count of copper line instructions for palette writes (139 lines) (file offset: 0x0132)
        move.w   #$4a09,d3                            ; Set copper list palette register offset            (file offset: 0x0138)
        lea      Buffer_DynamicCopperColorCommands(pc),a0                        ; Point to copper list color register write commands (file offset: 0x013C)
        move.l   #$2c09fffe,(a0)+                     ; Assemble copper instruction wait command (VBlank sync) (file offset: 0x0140)
        move.l   #$1800aaf,(a0)+                      ; Assemble copper color palette instruction bytes    (file offset: 0x0146)
        move.l   #$2e09fffe,(a0)+                     ; Assemble copper instruction wait command (Raster line sync) (file offset: 0x014C)
        move.l   #$180086f,(a0)+                      ; Assemble copper color palette instruction bytes    (file offset: 0x0152)
        move.l   #$4809fffe,(a0)+                     ; Assemble copper instruction wait command (Raster line sync) (file offset: 0x0158)
        move.l   #$180042f,(a0)+                      ; Assemble copper color palette instruction bytes    (file offset: 0x015E)
        lea      $75078.l,a2                          ; Point to intermediate palette gradient colors      (file offset: 0x0164)
        move.w   #$4909,(a0)+                         ; Write copper end marker instruction byte           (file offset: 0x016A)
        move.w   #$fffe,(a0)+                         ; Write copper end marker instruction word           (file offset: 0x016E)
        move.w   #$e2,(a0)+                           ; Write copper register pointer setup instruction word (file offset: 0x0172)
        move.w   Var_VerticalScroll_AnimationTimer(pc),d0                        ; Read active copper scroll row animation counter index (file offset: 0x0176)
        mulu.w   #$2c,d0                              ; Multiply by vertical row offset spacing factor (44 bytes) (file offset: 0x017A)
        addi.w   #$528,d0                             ; Calculate target color gradient palette index      (file offset: 0x017E)
        move.w   d0,(a0)+                             ; Write dynamic color gradient palette offset to copper (file offset: 0x0182)
        lea      Var_VerticalScroll_DirectionFlag(pc),a5                        ; Point to screen vertical scroll direction indicator flag (file offset: 0x0184)
        lea      Var_VerticalScroll_AnimationTimer(pc),a4                        ; Point to screen vertical scroll animation timer counter (file offset: 0x0188)
        tst.w    (a5)                                 ; Check screen vertical scroll direction (up vs down) (file offset: 0x018C)
        beq.b    VBlank_ScrollUp                               ; If moving down, skip to decrement timer            (file offset: 0x018E)
        subi.w   #$1,(a4)                             ; Decrement scroll animation timer (direction down)  (file offset: 0x0190)
        cmpi.w   #$ffff,(a4)                          ; Check if scroll animation timer reached minimum ($ffff) (file offset: 0x0194)
        bne.b    VBlank_ScrollDone                               ; If not minimum, branch to continue compilation     (file offset: 0x0198)
        clr.w    (a5)                                 ; Change direction indicator to scroll upwards (0)   (file offset: 0x019A)
        bra.b    VBlank_ScrollDone                               ; Branch to continue copper list compilation         (file offset: 0x019C)
VBlank_ScrollUp:
        addi.w   #$1,(a4)                             ; Increment scroll animation timer (direction up)    (file offset: 0x019E)
        cmpi.w   #$9,(a4)                             ; Check if scroll animation timer reached maximum (9) (file offset: 0x01A2)
        bne.b    VBlank_ScrollDone                               ; If not maximum, branch to continue compilation     (file offset: 0x01A6)
        move.w   #$ffff,(a5)                          ; Change direction indicator to scroll downwards ($ffff) (file offset: 0x01A8)
VBlank_ScrollDone:
        move.w   #$182,(a0)+                          ; Write final palette horizontal position register setup (file offset: 0x01AC)
        move.w   Table_RectFillCoordinates_Sentinel(pc),(a0)+        ; Write next palette gradient color word             (file offset: 0x01B0)
Loop_BuildCopperRows:
        move.w   d3,(a0)+                             ; Write next intermediate color word                 (file offset: 0x01B4)
        move.w   #$fffe,(a0)+                         ; Write next vertical position copper instruction wait (file offset: 0x01B6)
        move.w   #$180,(a0)+                          ; Write next palette color register setup            (file offset: 0x01BA)
        move.w   (a2)+,(a0)+                          ; Write next copper gradient palette color           (file offset: 0x01BE)
        move.w   d3,d4                                ; Copy current color value                           (file offset: 0x01C0)
        addi.b   #$84,d4                              ; Add intermediate offset factor                     (file offset: 0x01C2)
        move.w   d4,(a0)+                             ; Write color offset value to copper list            (file offset: 0x01C6)
        move.w   #$fffe,(a0)+                         ; Write next vertical position copper instruction wait (file offset: 0x01C8)
        move.w   #$180,(a0)+                          ; Write next palette color register setup            (file offset: 0x01CC)
        move.w   (a2)+,(a0)+                          ; Write next copper gradient palette color           (file offset: 0x01D0)
        addi.w   #$100,d3                             ; Advance vertical offset pointer for next copper row (file offset: 0x01D2)
        dbra     d7,Loop_BuildCopperRows                            ; Repeat dynamic copper construction for remaining lines (file offset: 0x01D6)
        move.l   #$d609fffe,(a0)+                     ; Assemble final copper screen close register instruction (file offset: 0x01DA)
        move.l   #$e21d38,(a0)+                       ; Assemble final copper palette layout instructions  (file offset: 0x01E0)
        move.l   #$1820fff,(a0)+                      ; Assemble final copper color gradient baseline instructions (file offset: 0x01E6)
        move.l   #$1800aaf,(a0)+                      ; Assemble final copper background sync wait instruction (file offset: 0x01EC)
        move.l   #$d809fffe,(a0)+                     ; Assemble final copper viewport vertical sync wait  (file offset: 0x01F2)
        move.l   #$180086f,(a0)+                      ; Assemble final copper viewport vertical sync wait  (file offset: 0x01F8)
        move.l   #$f209fffe,(a0)+                     ; Assemble final copper screen boundary sync wait    (file offset: 0x01FE)
        move.l   #$180042f,(a0)+                      ; Assemble final copper screen boundary sync wait    (file offset: 0x0204)
        move.l   #$f409fffe,(a0)+                     ; Assemble final copper layout reset instructions    (file offset: 0x020A)
        move.l   #$1800000,(a0)+                      ; Assemble final copper base background palette clear (file offset: 0x0210)
        move.l   #$9c8010,(a0)+                       ; Acknowledge VBlank frame interrupt in copper       (file offset: 0x0216)
        move.l   #$fffffffe,(a0)                      ; Write double longword copper list end block sentinel ($fffffffe) (file offset: 0x021C)
        lea      Var_046A(pc),a1                      ; Point to background graphics structure logo header (file offset: 0x0222)
        clr.l    d1                                   ; Clear background display configuration mode (d1 = 0) (file offset: 0x0226)
        move.w   #$3,d0                               ; Set viewport height parameter (3)                  (file offset: 0x0228)
        clr.w    d2                                   ; Clear viewport scroll parameter (d2 = 0)           (file offset: 0x022C)
        move.w   #$a,d3                               ; Set screen scroll speed vertical delay factor (10) (file offset: 0x022E)
        move.w   #$150,d4                             ; Set screen scroll vertical height offset (336)     (file offset: 0x0232)
        move.w   #$14,d5                              ; Set screen scroll vertical boundary width limit (20) (file offset: 0x0236)
        movea.l  Var_GfxBase.l,a6                     ; Load GfxBase base library pointer for graphics routine call (file offset: 0x023A)
        jsr      -$18c(a6)                            ; Call graphics library viewport update display routine (file offset: 0x0240)
        lea      Var_046A(pc),a1                      ; Point to background graphics structure logo header again (file offset: 0x0244)
        clr.l    d1                                   ; Clear background display configuration mode (d1 = 0) (file offset: 0x0248)
        move.w   #$3,d0                               ; move.w instruction                                 (file offset: 0x024A)
        clr.w    d2                                   ; clr.w instruction                                  (file offset: 0x024E)
        move.w   #$a5,d3                              ; Clear viewport scroll parameter (d2 = 0)           (file offset: 0x0250)
        move.w   #$150,d4                             ; Set screen scroll vertical height offset (336)     (file offset: 0x0254)
        move.w   #$be,d5                              ; Set screen scroll vertical boundary width limit (190) (file offset: 0x0258)
        movea.l  Var_GfxBase(pc),a6                   ; Load GfxBase base library pointer for graphics routine call (file offset: 0x025C)
        jsr      -$18c(a6)                            ; Call graphics library viewport update display routine (file offset: 0x0260)
        subi.b   #$1,Var_ScrollText_CharDelayTimer.l          ; Decrement VBlank scroll delay speed counter        (file offset: 0x0264)
        bne.w    VBlank_SkipScrollText                               ; If delay has not expired, skip scroll text rendering (file offset: 0x026C)
        move.b   #$3,Var_ScrollText_CharDelayTimer.l          ; Reset scroll text character delay counter back to 3 (file offset: 0x0270)
        movea.l  Var_GfxBase(pc),a6                   ; Load GfxBase base library pointer for graphics routine call (file offset: 0x0278)
        lea      Var_046A(pc),a1                      ; Point to background graphics structure logo header (file offset: 0x027C)
        move.w   #$140,$24(a1)                        ; Set scroll text dynamic horizontal width offset (320 pixels) (file offset: 0x0280)
        move.w   #$11,$26(a1)                         ; Set scroll text dynamic vertical layout height offset (17 pixels) (file offset: 0x0286)
        movea.l  Var_ScrollText_CharPointer(pc),a0            ; Load active scroll text char pointer from font pointer variable (file offset: 0x028C)
        move.l   #$1,d0                               ; Set text character print limit parameter to 1      (file offset: 0x0290)
        jsr      -$3c(a6)                             ; Call graphics library character text rendering function (file offset: 0x0296)
        lea      Var_046A(pc),a1                      ; Point to background graphics structure logo header again (file offset: 0x029A)
        move.w   #$140,$24(a1)                        ; Set scroll text dynamic horizontal width offset (320 pixels) (file offset: 0x029E)
        move.w   #$bb,$26(a1)                         ; Set scroll text dynamic vertical layout height offset (187 pixels) (file offset: 0x02A4)
        movea.l  Var_ScrollText_CharPointer(pc),a0            ; Load active scroll text char pointer from font pointer variable (file offset: 0x02AA)
        move.l   #$1,d0                               ; Set text character print limit parameter to 1      (file offset: 0x02AE)
        jsr      -$3c(a6)                             ; Call graphics library character text rendering function (file offset: 0x02B4)
        addi.l   #$1,Var_ScrollText_CharPointer.l             ; Advance active scroll font character pointer by one byte (file offset: 0x02B8)
        cmpi.l   #Str_ScrollingText_Greetings_End,Var_ScrollText_CharPointer.l ; Check if we reached the end of the scroll text data limit (file offset: 0x02C2)
        bne.b    VBlank_SkipScrollText                               ; If not at limit, continue executing VBlank interrupt frame (file offset: 0x02CC)
        move.l   #Str_ScrollingText_Greetings,Var_ScrollText_CharPointer.l   ; Reset scroll text char pointer back to start of greetings (file offset: 0x02CE)
VBlank_SkipScrollText:
        lea      $75000.l,a0                          ; Point a0 to copper layout memory buffer address $75000 (file offset: 0x02D8)
        lea      Table_CopperPaletteGradients_Right(pc),a1 ; Point a1 to the right-cycling copper gradient/waveform table (file offset: 0x02DE)
        lea      Table_CopperPaletteGradients_Left(pc),a2 ; Point a2 to the left-cycling copper gradient table (file offset: 0x02E2)
        move.w   #$c7,d7                              ; Set loop counter to copy 200 copper line instructions (file offset: 0x02E6)
Loop_CopyCopperGradients:
        move.w   (a2)+,(a0)+                          ; Copy copper gradient color word to viewport memory (file offset: 0x02EA)
        move.w   (a1)+,(a0)+                          ; Copy copper bounce horizontal offset word to viewport memory (file offset: 0x02EC)
        cmpa.l   #Var_Music_SilentLoop,a1             ; Check if pointer reached the end of the cycled gradient table ($70604) (file offset: 0x02EE)
        blt.b    Loop_CopyCopperGradients_Next                               ; If within range, continue copying normal copper line (file offset: 0x02F4)
        lea      Table_CopperPaletteGradients_Right(pc),a1 ; Reset pointer to the start of the right-cycling table (file offset: 0x02F6)
        lea      Table_CopperPaletteGradients_Left(pc),a2 ; Reset pointer to the start of the left-cycling table (file offset: 0x02FA)
Loop_CopyCopperGradients_Next:
        dbra     d7,Loop_CopyCopperGradients                            ; Repeat loop for all 200 screen lines               (file offset: 0x02FE)
        clr.l    d5                                   ; Clear viewport scroll counter register d5          (file offset: 0x0302)
Loop_AnimateViewportRows:
        lea      Var_VerticalBounce_ScrollWaitTable(pc),a1                        ; Point a1 to intermediate bounce tables address     (file offset: 0x0304)
        move.w   #$6,d7                               ; Set copper bounce iteration loop counter to 6      (file offset: 0x0308)
        lea      Table_CopperBounce_Sine(pc),a2       ; Point a2 to 114-byte sine-based vertical displacement bounce table (file offset: 0x030C)
        clr.l    d0                                   ; Clear register d0                                  (file offset: 0x0310)
        lea      Var_VerticalBounce_ScrollIndexTable(pc),a3                        ; Point a3 to vertical bounce horizontal position register (file offset: 0x0312)
        move.b   (a3,d5.l),d0                         ; Read active vertical bounce displacement index     (file offset: 0x0316)
        move.b   (a2,d0.l),d0                         ; Read horizontal displacement bounce factor from offset table (file offset: 0x031A)
        move.l   d0,d1                                ; Copy horizontal displacement factor                (file offset: 0x031E)
        move.l   #$64,d2                              ; Set scroll limit horizontal constraint (100 pixels) (file offset: 0x0320)
        sub.l    d0,d2                                ; Calculate bounce screen scrolling offset           (file offset: 0x0326)
        exg.l    d0,d2                                ; Exchange register values for screen position calculation (file offset: 0x0328)
        addi.l   #$64,d0                              ; Add baseline horizontal offset (100 pixels)        (file offset: 0x032A)
        asl.l    #$2,d0                               ; Multiply vertical scroll factor by 4 for alignment (file offset: 0x0330)
        asl.l    #$2,d1                               ; Multiply horizontal scroll factor by 4 for alignment (file offset: 0x0332)
        lea      $75000.l,a0                          ; Point a0 to copper layout memory buffer address $75000 (file offset: 0x0334)
        lea      $75000.l,a5                          ; Point a5 to copper layout memory buffer address $75000 (file offset: 0x033A)
        adda.l   d1,a5                                ; Add calculated horizontal displacement factor offset (file offset: 0x0340)
        adda.l   d0,a0                                ; Add calculated vertical displacement factor offset (file offset: 0x0342)
Loop_WriteDynamicScrollWords:
        move.w   (a1),(a5)+                           ; Write updated scroll value to dynamic copper list  (file offset: 0x0344)
        move.w   (a1),(a5)+                           ; Write updated scroll value to dynamic copper list again (file offset: 0x0346)
        move.w   (a1),(a0)+                           ; Write intermediate color value to dynamic copper list (file offset: 0x0348)
        move.w   (a1)+,(a0)+                          ; Write intermediate color value to dynamic copper list again (file offset: 0x034A)
        dbra     d7,Loop_WriteDynamicScrollWords                            ; Repeat dynamic horizontal scroll assembly loop     (file offset: 0x034C)
        addq.l   #$1,d5                               ; Increment viewport scroll counter d5 by one        (file offset: 0x0350)
        cmpi.b   #$8,d5                               ; Compare viewport scroll counter to maximum (8)     (file offset: 0x0352)
        bne.b    Loop_AnimateViewportRows                               ; Loop back to render remaining dynamic viewport rows (file offset: 0x0356)
        move.w   #$7,d7                               ; Set loop counter to update 8 scrolling bounce variables (file offset: 0x0358)
        lea      Var_VerticalBounce_ScrollIndexTable(pc),a0                        ; Point a0 to vertical bounce horizontal position table start (file offset: 0x035C)
Loop_UpdateBounceTimers:
        addi.b   #$1,(a0)                             ; Increment scroll timer parameter inside dynamic table (file offset: 0x0360)
        cmpi.b   #$80,(a0)                            ; Check if scroll timer parameter reached maximum delay ($80) (file offset: 0x0364)
        bne.b    Loop_UpdateBounceTimers_Next                               ; If not maximum, continue scroll animation update   (file offset: 0x0368)
        clr.b    (a0)                                 ; Reset scroll timer parameter back to zero          (file offset: 0x036A)
Loop_UpdateBounceTimers_Next:
        addq.l   #$1,a0                               ; Advance to next scroll timer parameter address slot (file offset: 0x036C)
        dbra     d7,Loop_UpdateBounceTimers                            ; Repeat loop for remaining scroll timers            (file offset: 0x036E)
        lea      Table_CopperPaletteGradients_Left(pc),a0 ; Point a0 to left-cycling copper gradient table (file offset: 0x0372)
        move.w   #$27,d7                              ; Set loop counter to cycle 41 palette colors (40 iterations + 1) (file offset: 0x0376)
        move.w   (a0),d1                              ; Read first color value from gradient table (file offset: 0x037A)
Loop_CycleGradientLeft:
        move.w   $2(a0),(a0)+                         ; Shift next color gradient value into preceding slot (cycle left!) (file offset: 0x037C)
        dbra     d7,Loop_CycleGradientLeft                            ; Repeat cycle copy loop for remaining colors        (file offset: 0x0380)
        move.w   d1,(a0)                              ; Store original first color in the last slot (cycle wrap!) (file offset: 0x0384)
        lea      Var_Music_SilentLoop(pc),a0          ; Point a0 to the dynamic silent loop (end boundary of right gradient) (file offset: 0x0386)
        lea      Table_CopperPaletteGradients_Right_End(pc),a1 ; Point a1 to the end word of right-cycling table (file offset: 0x038A)
        move.l   #$28,d7                              ; Set loop counter to cycle 41 gradient values (40 iterations + 1) (file offset: 0x038E)
        move.w   (a1),d1                              ; Read last color value from right-cycling gradient table (file offset: 0x0394)
Loop_CycleGradientRight:
        move.w   -(a1),-(a0)                          ; Shift each color value right by one slot (cycle right!) (file offset: 0x0396)
        dbra     d7,Loop_CycleGradientRight                            ; Repeat shift loop for remaining colors            (file offset: 0x0398)
        move.w   d1,Table_CopperPaletteGradients_Right.l ; Store original last color in first slot (cycle wrap!) (file offset: 0x039C)
        bsr.w    Music_ParserTick                               ; Advance synthesizer music player parser by one tick! (file offset: 0x03A2)
        lea      Table_RectFillCoordinates_Sentinel(pc),a0           ; Point a0 to copper color bar cycle buffer start    (file offset: 0x03A6)
        lea      Table_CopperColorBar_CycleBuffer(pc),a1              ; Point a1 to copper color bar cycle buffer body     (file offset: 0x03AA)
        move.w   #$26,d0                              ; Set loop counter to cycle 40 waveform words (39 iterations + 1) (file offset: 0x03AE)
        move.w   (a0),d1                              ; Shift first color word into temp register d1       (file offset: 0x03B2)
Loop_ShiftScrollCoords:
        move.w   (a1)+,(a0)+                          ; Repeat shift loop to cycle color bar palette wave left (file offset: 0x03B4)
        dbra     d0,Loop_ShiftScrollCoords                            ; Repeat shift loop for all 40 color words           (file offset: 0x03B6)
        move.w   d1,-(a1)                             ; Wrap cycled first color to the end of buffer       (file offset: 0x03BA)
VBlank_ExitInterrupt:
        movem.l  (a7)+,d0-d7/a0-a6                    ; Return from Exception (Level 3 interrupt complete) (file offset: 0x03BC)
        rte                                           ; rte instruction                                    (file offset: 0x03C0)
Var_SavedVBlankVector:
        dc.w     $0000                            ; Part of split instruction (ori.b #$39, d0) (file offset: 0x03C2)
VBlank_RestoreVector_BtstOpcode:
        dc.w     $0839                            ; Part of split instruction (ori.b #$39, d0) (file offset: 0x03C4)
ExitIntro:
        ori.b    #$bf,d6                              ; Restore original Level 3 VBlank interrupt vector   (file offset: 0x03C6)
        asr.b    #$8,d1                               ; asr.b instruction                                  (file offset: 0x03CA)
        bne.b    VBlank_RestoreVector_BtstOpcode                               ; bne.b instruction                                  (file offset: 0x03CC)
        move.w   #$10f,$dff096.l                      ; Disable custom master interrupts in INTENA register (file offset: 0x03CE)
        move.w   #$4010,$dff09a.l                     ; move.w instruction                                 (file offset: 0x03D6)
        move.l   Var_SavedVBlankVector.l,$6c.l        ; move.l instruction                                 (file offset: 0x03DE)
        move.w   #$c000,$dff09a.l                     ; move.w instruction                                 (file offset: 0x03E8)
        movea.l  ExecBase.l,a6                        ; movea.l instruction                                (file offset: 0x03F0)
        movea.l  Str_GraphicsLib(pc),a1               ; Load GfxBase base library pointer for graphics routine call (file offset: 0x03F6)
        move.l   Var_SavedExecVector.l,$32(a1)        ; Restore Exec system stack vector state             (file offset: 0x03FA)
        move.w   #$83f0,$dff096.l                     ; move.w instruction                                 (file offset: 0x0402)
        jsr      -$19e(a6)                            ; Call graphics library display viewport restore routine (file offset: 0x040A)
        jsr      -$8a(a6)                             ; Call graphics library display viewport close routine (file offset: 0x040E)
        movem.l  (a7)+,d0-d7/a0-a6                    ; Restore all saved CPU registers from stack         (file offset: 0x0412)
        moveq    #$0,d0                               ; Set success return code (d0 = 0)                   (file offset: 0x0416)
        rts                                           ; Return from program entry point to AmigaOS CLI/Workbench (file offset: 0x0418)

; ============================================================================
; Data Block: Graphics Library String & Overlay Variables (0x041A - 0x043A)
; ============================================================================
	ds.b     8                             ; Zeros padding
Str_GraphicsLib:
	dc.b     $00,$00                       ; Data bytes
Var_GfxBase:
	dc.b     $67,$72,$61,$70               ; Data bytes
Var_0428:
	dc.b     $68,$69,$63,$73,$2E,$6C,$69,$62,$72,$61,$72,$79,$00,$00,$00,$00 ; Data bytes
	dc.b     $00,$00                       ; Data bytes

; ============================================================================
; Data Block: Zero Padding Workspace (0x043A - 0x04DE)
; ============================================================================
Var_043A:
	ds.b     8                             ; Zeros padding
Var_0442:
	ds.b     16                            ; Zeros padding
	ds.b     16                            ; Zeros padding
	ds.b     8                             ; Zeros padding
Var_046A:
	ds.b     4                             ; Zeros padding
Var_046E:
	ds.b     16                            ; Zeros padding
	ds.b     16                            ; Zeros padding
	ds.b     16                            ; Zeros padding
	ds.b     16                            ; Zeros padding
	ds.b     16                            ; Zeros padding
	ds.b     16                            ; Zeros padding
	dc.b     $00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$64,$63,$63,$63,$63,$62 ; Data bytes

; ============================================================================
; Data Block: Text Copper Bounce Tables (0x04DE - 0x0550)
; ============================================================================
; ============================================================================
; Data Block: Text Copper Bounce Tables (0x04DE - 0x0550)
; Purpose   : 114-byte sine-based vertical displacement bounce lookup table.
;             Used to animate the smooth sinusoidal vertical bouncing movement of the overlay.
; ============================================================================
Table_CopperBounce_Sine:
	dc.b     $62,$62,$61,$61,$60,$5F,$5F,$5E,$5D,$5C,$5C,$5B,$5A,$59,$58,$56 ; Symmetrical sine wave data (crest at $62)
	dc.b     $55,$54,$53,$52,$50,$4F,$4D,$4C,$4A,$49,$47,$45,$44,$42,$40,$3E ; 
	dc.b     $3C,$3A,$38,$36,$34,$32,$2F,$2D,$2B,$28,$26,$23,$21,$1E,$1C,$19 ; 
	dc.b     $16,$13,$11,$0E,$0B,$08,$05,$02,$00,$03,$06,$09,$0C,$0F,$11,$14 ; Sinusoidal descent to trough ($00)
	dc.b     $17,$1A,$1C,$1F,$22,$24,$27,$29,$2B,$2E,$30,$32,$34,$37,$39,$3B ; 
	dc.b     $3D,$3F,$40,$42,$44,$46,$48,$49,$4B,$4C,$4E,$4F,$51,$52,$53,$54 ; 
	dc.b     $56,$57,$58,$59,$5A,$5B,$5C,$5D,$5D,$5E,$5F,$60,$60,$61,$61,$62 ; Ascent back to crest
	dc.b     $62,$62                       ; End of 114-byte vertical sine table

; ============================================================================
; Data Block: Copper Palette Gradients & Overlapping Waveform (0x0550 - 0x060C)
; Purpose   : Background sky color gradients for the copper list, and a space-saving
;             hybrid data layout that overlaps the color table with the sound synthesizer wave!
; ============================================================================
	dc.w     $6363,$6363,$0222,$0333,$0444,$0555,$0666 ; Padding and initial gradient colors (uncycled)

; Left-Cycling Copper Palette Gradient (Table of 41 color words, cycled left in VBlank)
Table_CopperPaletteGradients_Left:
	dc.w     $0777,$0888,$0999,$0AAA,$0BBB,$0CCC,$0DDD,$0EEE ; Grey to white ramp
	dc.w     $0FFF,$0EEF,$0DDF,$0CCF,$0BBF,$0AAF,$099F,$088F ; Pure white to blue ramp
	dc.w     $077F,$066F,$055F,$044F,$033F,$022F,$011F,$000F ; Light blue to dark blue ramp
	dc.w     $000D,$000C,$000B,$000A,$0009,$0008,$0007,$0006 ; Deep blue to black ramp
	dc.w     $0005,$0004,$0003,$0002,$0222,$0333,$0444,$0555 ; Near black returning to grey
	dc.w     $0666                         ; Final color of the left-cycling table

; Right-Cycling Copper Palette Gradient & Overlapping Synthesizer Waveform (41 words)
; NOTE: The last 5 words of this table ($8088 - $C0C8) overlap EXACTLY with the first
; 10 bytes of the 32-byte signed linear Sawtooth Waveform used by the audio engine!
; On the Amiga OCS hardware, color registers are 12-bit ($0RGB). The hardware completely
; ignores the high bit of each nibble, translating $8088 to $0088, $9098 to $0098, etc.
; Thus, these words act perfectly as BOTH smooth dark blue background colors AND the start of the audio wave!
Table_CopperPaletteGradients_Right:
	dc.w     $0777,$0888,$0999,$0AAA,$0BBB,$0CCC,$0DDD,$0EEE ; Grey to white ramp
	dc.w     $0FFF,$0EEF,$0DDF,$0CCF,$0BBF,$0AAF,$099F,$088F ; Pure white to blue ramp
	dc.w     $077F,$066F,$055F,$044F,$033F,$022F,$011F,$000F ; Light blue to dark blue ramp
	dc.w     $000D,$000C,$000B,$000A,$0009,$0008,$0007,$0006 ; Deep blue to black ramp
	dc.w     $0005,$0004,$0003,$0002                         ; Near black colors
	; --- START OF THE OVERLAPPING SYNTHESIZER SAWTOOTH WAVEFORM (Bytes 0 to 9) ---
	dc.w     $8088                         ; Sawtooth bytes: $80, $88 (Color: dark blue $0088)
	dc.w     $9098                         ; Sawtooth bytes: $90, $98 (Color: dark blue $0098)
	dc.w     $A0A8                         ; Sawtooth bytes: $A0, $A8 (Color: dark blue $00A8)
	dc.w     $B0B8                         ; Sawtooth bytes: $B0, $B8 (Color: dark blue $00B8)
Table_CopperPaletteGradients_Right_End:
	dc.w     $C0C8                         ; Sawtooth bytes: $C0, $C8 (Color: dark blue $00C8)

; Middle part of the Synthesizer Sawtooth Waveform (Bytes 10 to 19).
; Also serves as the "Silent Loop" dummy buffer when audio channels are idle and muted (volume 0).
; Paula DMA channels are initialized to loop 16 words (32 bytes) starting at this label.
Var_Music_SilentLoop:
Track_Voice0_Notes:
	dc.w     $D0D8                         ; Sawtooth bytes: $D0, $D8 (Voice 0 notes start)
	dc.w     $E0E8                         ; Sawtooth bytes: $E0, $E8
	dc.w     $F0F8                         ; Sawtooth bytes: $F0, $F8
	dc.w     $0008                         ; Sawtooth bytes: $00, $08
	dc.w     $1018                         ; Sawtooth bytes: $10, $18

; ============================================================================
; Data Block: Spacing Offsets & Remainder of Synthesizer Sawtooth Waveform (0x060C - 0x063A)
; Purpose   : Layout coordinates, dynamic delay counters, and the tail bytes of the sawtooth wave!
; ============================================================================
	dc.b     $20,$28,$30,$38,$40,$48,$50,$58,$60,$68,$70,$78 ; Synthesizer Sawtooth wave (Bytes 20-31)
	dc.b     $FF,$FF,$0E,$00                                 ; Dynamic scroll delay / control markers
	dc.b     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,$02,$04,$06 ; Data bytes
	dc.b     $08,$06,$04,$02,$00,$FE,$FC,$FA,$F8,$FA,$FC,$FE,$00,$02 ; Data bytes

; ============================================================================
; Data Block: Music Loader Zeroes and Variables (0x063A - 0x098E)
; ============================================================================
	dc.b     $04,$06,$08,$06,$04,$02,$00,$FE,$FC,$FA,$F8,$FA,$FC,$FE,$00,$00 ; Data bytes
	dc.b     $01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$F0 ; Data bytes
	dc.b     $E0,$D0,$C0,$B0,$A0,$90,$80,$90,$A0,$B0,$C0,$D0
Track_Voice1_Notes:
	dc.b     $E0,$F0,$00,$10 ; Data bytes (Voice 1 notes start)
	dc.b     $20,$30,$40,$50,$60,$70,$7F,$70,$60,$50,$40,$30,$20,$10,$96,$96 ; Data bytes
	dc.b     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$02 ; Data bytes
	dc.b     $04,$06,$08,$06,$04,$02,$00,$FE,$FC,$FA,$F8,$FA,$FC,$FE,$00,$02 ; Data bytes
	dc.b     $04,$06,$08,$06,$04,$02,$00,$FE,$FC,$FA,$F8,$FA,$FC,$FE,$00,$00 ; Data bytes
	dc.b     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80,$80 ; Data bytes
	dc.b     $80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$7F,$7F,$7F,$7F ; Data bytes
Track_Voice2_Notes:
	dc.b     $7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$FF,$FF,$1E,$00,$00,$00 ; Data bytes (Voice 2 notes start)
	dc.b     $00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,$02,$04,$06,$08,$06 ; Data bytes
	dc.b     $04,$02,$00,$FE,$FC,$FA,$F8,$FA,$FC,$FE,$00,$02,$04,$06,$08,$06 ; Data bytes
	dc.b     $04,$02,$00,$FE,$FC,$FA,$F8,$FA,$FC,$FE,$00,$00,$00,$00,$00,$00 ; Data bytes
	dc.b     $00,$00,$00,$00,$00,$00,$FF,$E2,$00,$00,$80,$80,$80,$80,$80,$80 ; Data bytes
	dc.b     $80,$80,$80,$80,$80,$80,$80,$80,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F ; Data bytes
	dc.b     $7F,$7F,$7F,$7F
Track_Voice3_Notes:
	dc.b     $7F,$7F,$28,$AF,$0A,$64,$06,$00,$00,$00,$00,$00 ; Data bytes (Voice 3 notes start)
	ds.b     4                             ; Zeros padding
Var_Music_TickCounter:
	dc.b     $02,$03,$00,$02,$04,$06,$08,$06,$04,$02,$00,$FE,$FC,$FA ; Data bytes
Table_VibratoWaveform:
	dc.b     $F8,$FA,$FC,$FE,$00,$02,$04,$06,$08,$06,$04,$02,$00,$FE,$FC,$FA ; Data bytes
	dc.b     $F8,$FA,$FC,$FE,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; Data bytes
	dc.b     $00,$00,$00,$00,$1A,$C0,$19,$40,$17,$D0,$16,$80,$15,$30,$14,$00 ; Data bytes
	dc.b     $12,$E0,$11,$D0,$10,$D0,$0F,$E0,$0F,$00,$0E,$20,$0D,$60,$0C,$A0 ; Data bytes
	dc.b     $0B,$E8,$0B,$40,$0A,$98,$0A,$00,$09,$70,$08,$E8,$08,$68,$07,$F0 ; Data bytes
	dc.b     $07,$80,$07,$10,$06,$B0,$06,$50,$05,$F4,$05,$A0,$05,$4C,$05,$00 ; Data bytes
	dc.b     $04,$B8,$04,$74,$04,$34,$03,$F8,$03,$C0,$03,$88,$03,$58,$03,$28 ; Data bytes
	dc.b     $02,$FA,$02,$D0,$02,$A6,$02,$80,$02,$5C,$02,$3A,$02,$1A,$01,$FC ; Data bytes
	dc.b     $01,$E0,$01,$C4,$01,$AC,$01,$94,$01,$7D,$01,$68,$01,$53 ; Data bytes
Var_Music_Chan0_StateBlock:
	dc.b     $01,$40,$01,$2E,$01,$1D,$01,$0D,$00,$FE,$00,$F0,$00,$E2,$00,$D6 ; Data bytes
	dc.b     $00,$CA,$00,$BE,$00,$B4,$00,$AA,$00,$A0,$00,$97,$00,$8F,$00,$87 ; Data bytes
	dc.b     $00,$7F,$00,$07,$06,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; Data bytes
	ds.b     10                            ; Zeros padding
Var_Music_Chan1_StateBlock:
	dc.b     $00,$DF,$F0,$A0,$00,$00,$00,$00,$00,$00,$00,$07,$09,$08,$00,$00 ; Data bytes
	dc.b     $00,$00                       ; Data bytes
Var_Music_Chan0_State:
	ds.b     6                             ; Zeros padding
Var_Music_Chan0_Volume:
	dc.b     $00,$00                       ; Data bytes
Var_Music_Chan0_Period:
	dc.b     $00,$00,$00,$07,$06,$04,$00,$00,$00,$00,$00,$00,$00,$00 ; Data bytes
Var_Music_Chan0_DataPtr:
	ds.b     4                             ; Zeros padding
Var_Music_Chan0_CmdPtr:
	dc.b     $00,$00,$00,$00,$00,$00,$00,$00,$00,$DF,$F0,$B0 ; Data bytes
Var_Music_Chan0_LoopPtr:
	dc.b     $00,$00                       ; Data bytes
Var_084E:
	dc.b     $00,$00,$00,$00,$00,$07,$09,$30,$00,$00,$00,$00,$00,$00,$00,$00 ; Data bytes
	dc.b     $00,$00                       ; Data bytes
Var_Music_Chan1_State:
	dc.b     $00,$00,$00,$00,$00,$07       ; Data bytes
Var_Music_Chan1_Volume:
	dc.b     $06,$04                       ; Data bytes
Var_Music_Chan1_Period:
	ds.b     14                            ; Zeros padding
Var_Music_Chan1_DataPtr:
	ds.b     4                             ; Zeros padding
Var_Music_Chan1_CmdPtr:
	dc.b     $00,$00,$00,$DF,$F0,$C0,$00,$00,$00,$00,$00,$00 ; Data bytes
Var_Music_Chan1_LoopPtr:
	dc.b     $00,$07                       ; Data bytes
Var_0888:
	dc.b     $09,$40,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; Data bytes
	dc.b     $00,$07                       ; Data bytes
Var_Music_Chan2_State:
	dc.b     $06,$04,$00,$00,$00,$00       ; Data bytes
Var_Music_Chan2_Volume:
	dc.b     $00,$00                       ; Data bytes
Var_Music_Chan2_Period:
	ds.b     14                            ; Zeros padding
Var_Music_Chan2_DataPtr:
	dc.b     $00,$DF,$F0,$D0               ; Data bytes
Var_Music_Chan2_CmdPtr:
	dc.b     $00,$00,$00,$00,$00,$00,$00,$07,$09,$50,$00,$00 ; Data bytes
Var_Music_Chan2_LoopPtr:
	dc.b     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07,$0D,$86 ; Data bytes
	dc.b     $00,$00,$00,$01               ; Data bytes
Var_Music_Chan3_State:
	dc.b     $00,$07,$0D,$86,$FF,$FF       ; Data bytes
Var_Music_Chan3_Volume:
	dc.b     $FF,$FD                       ; Data bytes
Var_Music_Chan3_Period:
	dc.b     $00,$07,$0D,$86,$FF,$FF,$FF,$F8,$00,$07,$0D,$B2,$FF,$FF ; Data bytes
Var_Music_Chan3_DataPtr:
	dc.l     0                             ; Channel 3 notes track data start pointer
Var_Music_Chan3_CmdPtr:
	dc.b     $00,$00,$00,$07,$0D,$DE,$00,$00,$00,$01,$00,$00 ; Data bytes
Var_Music_Chan3_LoopPtr:
	dc.b     $00,$00,$00,$00,$00,$07,$0E,$20,$00,$00,$00,$00 ; Data bytes
Var_Music_NoteTable0:
	ds.b     4                             ; Zeros padding
Var_Music_NoteTable0_End:
	dc.b     $00,$00,$00,$07,$0F,$58,$00,$00,$00,$01,$00,$07,$0E,$64,$00,$00 ; Data bytes
	dc.b     $00,$01,$00,$07,$0E,$64,$00,$00,$00,$01,$00,$07,$0F,$10,$00,$00 ; Data bytes
	dc.b     $00,$01,$00,$07               ; Data bytes
Var_Music_NoteTable1:
	dc.b     $0F,$10,$00,$00               ; Data bytes
Var_Music_NoteTable1_End:
	dc.b     $00,$01,$00,$07,$0E,$C4,$00,$00,$00,$01,$00,$07 ; Data bytes
Var_Music_NoteTable2:
	dc.b     $0E,$C4,$00,$00               ; Data bytes
Var_Music_NoteTable2_End:
	dc.b     $00,$01,$00,$00,$00,$00,$00,$00,$61,$00,$00,$10 ; Data bytes
Var_Music_NoteTable3:
	dc.b     $61,$00,$00,$48               ; Data bytes
Var_Music_NoteTable3_End:
; ============================================================================
; Function: SilenceAudioChannels
; Purpose : Silences all four Paula hardware audio DMA channels.
; Notes   : This function utilizes an incredibly clever space-saving hack:
;           it calls a shared helper to clear pointers/lengths, and instead
;           of returning with its own 'rts', the helper falls directly through
;           into the following 'InitMusic' routine to reuse its 'rts' instruction,
;           saving exactly 2 bytes of RAM!
; ============================================================================
SilenceAudioChannels:
        move.w   #$800f,CUSTOM+DMACON.l               ; Enable master DMA, copper DMA, blitter DMA, sprite DMA
        rts                                           ; Return

SilenceAllChannels:
        lea      CUSTOM.l,a0                          ; Point a0 to Channel 0 base offset
        bsr.w    Helper_SilenceChannel                ; Silence Channel 0
        lea      CUSTOM+$10.l,a0                      ; Point a0 to Channel 1 base offset
        bsr.w    Helper_SilenceChannel                ; Silence Channel 1
        lea      CUSTOM+$20.l,a0                      ; Point a0 to Channel 2 base offset
        bsr.w    Helper_SilenceChannel                ; Silence Channel 2
        lea      CUSTOM+$30.l,a0                      ; Point a0 to Channel 3 base offset
        bsr.w    Helper_SilenceChannel                ; Silence Channel 3
        rts                                           ; Return from SilenceAllChannels

Helper_SilenceChannel:
        clr.l    $a0(a0)                              ; Clear channel audio DMA pointer (AUDxLCH/AUDxLCL)
        clr.w    $a4(a0)                              ; Clear channel audio DMA length (AUDxLEN)
        ; Space-saving fall-through into InitMusic to reuse its 'rts'!

; ============================================================================
; Function: InitMusic
; Purpose : Initialize sound player memory and voice vectors.
; ============================================================================
InitMusic:
        clr.w    $a6(a0)                              ; Clear first music state variable word inside structures (file offset: 0x098E)
        clr.w    $a8(a0)                              ; Clear second music state variable word inside structures (file offset: 0x0992)
        rts                                           ; Return from custom music initialization subroutine (file offset: 0x0996)
        move.l   #Var_Music_NoteTable0,Var_Music_Chan0_DataPtr.l ; Initialize Channel 0 notes track data start pointer (file offset: 0x0998)
        move.l   #Var_Music_NoteTable1,Var_Music_Chan1_DataPtr.l ; Initialize Channel 1 notes track data start pointer (file offset: 0x09A2)
        move.l   #Var_Music_NoteTable2,Var_Music_Chan2_DataPtr.l ; Initialize Channel 2 notes track data start pointer (file offset: 0x09AC)
        move.l   #Var_Music_NoteTable3,Var_Music_Chan3_DataPtr.l     ; Initialize Channel 3 notes track data start pointer (file offset: 0x09B6)
        clr.l    Var_Music_Chan0_State.l              ; Clear Channel 0 music play state control register  (file offset: 0x09C0)
        clr.l    Var_Music_Chan1_State.l              ; Clear Channel 1 music play state control register  (file offset: 0x09C6)
        clr.l    Var_Music_Chan2_State.l              ; Clear Channel 2 music play state control register  (file offset: 0x09CC)
        clr.l    Var_Music_Chan3_State.l              ; Clear Channel 3 music play state control register  (file offset: 0x09D2)
        clr.l    Var_Music_Chan0_Volume.l             ; Clear Channel 0 active music play volume register  (file offset: 0x09D8)
        clr.l    Var_Music_Chan1_Volume.l             ; Clear Channel 1 active music play volume register  (file offset: 0x09DE)
        clr.l    Var_Music_Chan2_Volume.l             ; Clear Channel 2 active music play volume register  (file offset: 0x09E4)
        clr.l    Var_Music_Chan3_Volume.l             ; Clear Channel 3 active music play volume register  (file offset: 0x09EA)
        move.l   Var_Music_NoteTable0.l,Var_Music_Chan0_CmdPtr.l ; Set Channel 0 command notes reader pointer         (file offset: 0x09F0)
        move.l   Var_Music_NoteTable1.l,Var_Music_Chan1_CmdPtr.l ; Set Channel 1 command notes reader pointer         (file offset: 0x09FA)
        move.l   Var_Music_NoteTable2.l,Var_Music_Chan2_CmdPtr.l ; Set Channel 2 command notes reader pointer         (file offset: 0x0A04)
        move.l   Var_Music_NoteTable3.l,Var_Music_Chan3_CmdPtr.l ; Set Channel 3 command notes reader pointer         (file offset: 0x0A0E)
        move.l   Var_Music_NoteTable0_End.l,Var_Music_Chan0_LoopPtr.l ; Set Channel 0 notes play buffer loop loopback pointer (file offset: 0x0A18)
        move.l   Var_Music_NoteTable1_End.l,Var_Music_Chan1_LoopPtr.l ; Set Channel 1 notes play buffer loop loopback pointer (file offset: 0x0A22)
        move.l   Var_Music_NoteTable2_End.l,Var_Music_Chan2_LoopPtr.l ; Set Channel 2 notes play buffer loop loopback pointer (file offset: 0x0A2C)
        move.l   Var_Music_NoteTable3_End.l,Var_Music_Chan3_LoopPtr.l ; Set Channel 3 notes play buffer loop loopback pointer (file offset: 0x0A36)
        clr.l    Var_Music_Chan0_Period.l             ; Clear Channel 0 current play notes pitch period offset (file offset: 0x0A40)
        clr.l    Var_Music_Chan1_Period.l             ; Clear Channel 1 current play notes pitch period offset (file offset: 0x0A46)
        clr.l    Var_Music_Chan2_Period.l             ; Clear Channel 2 current play notes pitch period offset (file offset: 0x0A4C)
        clr.l    Var_Music_Chan3_Period.l             ; Clear Channel 3 current play notes pitch period offset (file offset: 0x0A52)
        move.l   #Var_Music_SilentLoop,$dff0a0.l      ; Point Paula Audio Channel 0 DMA pointer to dynamic silent loop (file offset: 0x0A58)
        move.l   #Var_Music_SilentLoop,$dff0b0.l      ; Point Paula Audio Channel 1 DMA pointer to dynamic silent loop (file offset: 0x0A62)
        move.l   #Var_Music_SilentLoop,$dff0c0.l      ; Point Paula Audio Channel 2 DMA pointer to dynamic silent loop (file offset: 0x0A6C)
        move.l   #Var_Music_SilentLoop,$dff0d0.l      ; Point Paula Audio Channel 3 DMA pointer to dynamic silent loop (file offset: 0x0A76)
        move.w   #$10,$dff0a4.l                       ; Set Paula Audio Channel 0 DMA buffer length to 16 words (32 bytes) (file offset: 0x0A80)
        move.w   #$10,$dff0b4.l                       ; Set Paula Audio Channel 1 DMA buffer length to 16 words (32 bytes) (file offset: 0x0A88)
        move.w   #$10,$dff0c4.l                       ; Set Paula Audio Channel 2 DMA buffer length to 16 words (32 bytes) (file offset: 0x0A90)
        move.w   #$10,$dff0d4.l                       ; Set Paula Audio Channel 3 DMA buffer length to 16 words (32 bytes) (file offset: 0x0A98)
        rts                                           ; Return from InitMusicChannels subroutine           (file offset: 0x0AA0)
        eori.b   #$ff,Var_Music_TickCounter.l         ; Invert music update frequency tick timing flag byte (file offset: 0x0AA2)
        lea      Var_Music_Chan0_StateBlock(pc),a0                      ; Point a0 to state structure address of Audio Channel 0 (file offset: 0x0AAA)
        bsr.w    Music_UpdateTimer                               ; Call Music_UpdateTimer subroutine for Channel 0    (file offset: 0x0AAE)
        lea      Var_Music_Chan1_StateBlock(pc),a0                      ; Point a0 to state structure address of Audio Channel 1 (file offset: 0x0AB2)
        bsr.w    Music_UpdateTimer                               ; Call Music_UpdateTimer subroutine for Channel 1    (file offset: 0x0AB6)
        lea      Var_084E(pc),a0                      ; Point a0 to state structure address of Audio Channel 2 (file offset: 0x0ABA)
        bsr.w    Music_UpdateTimer                               ; Call Music_UpdateTimer subroutine for Channel 2    (file offset: 0x0ABE)
        lea      Var_0888(pc),a0                      ; Point a0 to state structure address of Audio Channel 3 (file offset: 0x0AC2)
        bsr.w    Music_UpdateTimer                               ; Call Music_UpdateTimer subroutine for Channel 3    (file offset: 0x0AC6)
        rts                                           ; Return from VBlank music advancement tick handler  (file offset: 0x0ACA)

; ============================================================================
; Function: Music_UpdateTimer
; Purpose : Decrement tick counters for all active synthesizer channels.
; ============================================================================
Music_UpdateTimer:
        subq.w   #$1,$e(a0)                           ; Decrement active note duration timer for current audio channel (file offset: 0x0ACC)
        bpl.w    Music_Overlap_MoveaA2                               ; If note duration has not expired, branch to exit channel update (file offset: 0x0AD0)
        clr.w    $34(a0)                              ; Reset channel active pitch slide slide factor to zero (file offset: 0x0AD4)
        dc.w     $4268                            ; Part of split instruction (clr.w $36(a0)) (file offset: 0x0AD8)
Music_Overlap_Clr36:
        dc.w     $0036                            ; Part of split instruction (clr.w $36(a0)) (file offset: 0x0ADA)
Music_LoadTrackPointer:
        movea.l  $22(a0),a1                           ; Load active sound synthesizer track read address pointer (file offset: 0x0ADC)
        move.l   $2e(a0),d3                           ; Load current track end address pointer limit       (file offset: 0x0AE0)
        clr.l    d4                                   ; Clear register d4                                  (file offset: 0x0AE4)

; ============================================================================
; Function: Music_ParserTick
; Purpose : Main chip music command parser and channel output compiler.
; ============================================================================
Music_ParserTick:
        move.w   (a1),d4                              ; Read next music synthesizer word command from notes stream (file offset: 0x0AE6)
        cmpi.w   #$80,d4                              ; Check if command is instrument volume slide code ($80) (file offset: 0x0AE8)
        bne.b    Music_CheckEnvelopeCommand                               ; If not volume slide code, branch to check next command type (file offset: 0x0AEC)
        clr.l    $8(a0)                               ; Clear active note timer counter for current audio channel (file offset: 0x0AEE)
        move.l   $2(a1),$0(a0)                        ; Set new play note command read track pointer offset (file offset: 0x0AF2)
        addi.l   #$6,$22(a0)                          ; Advance track note reader pointer by 6 bytes       (file offset: 0x0AF8)
        move.l   $2(a1),d5                            ; Copy note command read track pointer offset        (file offset: 0x0B00)
        movea.l  $1a(a0),a3                           ; Load notes command playback buffer destination vector (file offset: 0x0B04)
        move.l   d5,(a3)                              ; Update play note track loop loopback destination vector (file offset: 0x0B08)
        bra.b    Music_LoadTrackPointer                               ; Exit parser loop and proceed to channel updates    (file offset: 0x0B0A)
Music_CheckEnvelopeCommand:
        cmpi.w   #$81,d4                              ; Check if command is voice envelope update code ($81) (file offset: 0x0B0C)
        bne.b    Music_CheckPitchBendCommand                               ; If not envelope update code, branch to check next command type (file offset: 0x0B10)
        movea.l  $0(a0),a3                            ; Load notes play status channel structure base register (file offset: 0x0B12)
        move.l   $2(a1),$56(a3)                       ; Update envelope attack stage parameters inside structure (file offset: 0x0B16)
        move.l   $6(a1),$5a(a3)                       ; Update envelope decay stage parameters inside structure (file offset: 0x0B1C)
        addi.l   #$a,$22(a0)                          ; Advance track note reader pointer by 10 bytes      (file offset: 0x0B22)
        bra.b    Music_LoadTrackPointer                               ; Exit parser loop and proceed to channel updates    (file offset: 0x0B2A)
Music_CheckPitchBendCommand:
        cmpi.w   #$82,d4                              ; Check if command is pitch bend update code ($82)   (file offset: 0x0B2C)
        bne.b    Music_PlayNormalNote                               ; If not pitch bend update code, branch to check next command type (file offset: 0x0B30)
        move.w   #$1,$36(a0)                          ; Set dynamic pitch bend mode active indicator flag word (file offset: 0x0B32)
        bra.b    Music_Overlap_Tst36                               ; Branch to configure next note playback parameters  (file offset: 0x0B38)
Music_PlayNormalNote:
        add.w    d4,d3                                ; Add command pitch value to active pitch offset register d3 (file offset: 0x0B3A)
        cmpi.l   #$6630,d4                            ; Check if command pitch value matches silence command ($6630) (file offset: 0x0B3C)
        addi.l   #$8,$1e(a0)                          ; Advance voice sound instruments tracker database pointer (file offset: 0x0B42)
        movea.l  $1e(a0),a2                           ; Point to voice sound instruments tracker database entry (file offset: 0x0B4A)
        move.l   $4(a2),$2e(a0)                       ; Load instruments tracker database block end parameter (file offset: 0x0B4E)
        move.l   (a2),$22(a0)                         ; Load instruments tracker database block start parameter (file offset: 0x0B54)
        bne.b    Music_Overlap_Clr36                               ; If not at database block end, branch to check timer (file offset: 0x0B58)
        move.l   $26(a0),$1e(a0)                      ; Reset database block reader pointer to baseline address (file offset: 0x0B5A)
        movea.l  $1e(a0),a2                           ; Point to voice sound instruments tracker database entry (file offset: 0x0B60)
        move.l   $4(a2),$2e(a0)                       ; Load instruments tracker database block end parameter (file offset: 0x0B64)
        move.l   (a2),$22(a0)                         ; Load instruments tracker database block start parameter (file offset: 0x0B6A)
        bra.w    Music_Overlap_Clr36                               ; Branch to exit channel update and configure voice play (file offset: 0x0B6E)
        dc.w     $4A68                            ; Part of split instruction (tst.w $36(a0)) (file offset: 0x0B72)
Music_Overlap_Tst36:
        dc.w     $0036                            ; Part of split instruction (tst.w $36(a0)) (file offset: 0x0B74)
        bne.b    Music_SkipEnvelopeReset                               ; If active, skip channel envelope reset routines    (file offset: 0x0B76)
        clr.l    $4(a0)                               ; Clear voice active envelope decay speed parameters (file offset: 0x0B78)
        clr.w    $38(a0)                              ; Clear voice active envelope current decay volume step (file offset: 0x0B7C)
        move.w   d3,$32(a0)                           ; Set channel base playback pitch period directly from note (file offset: 0x0B80)
Music_SkipEnvelopeReset:
        move.w   $2(a1),$e(a0)                        ; Read note duration timer parameter from notes stream (file offset: 0x0B84)
        subq.w   #$1,$e(a0)                           ; Adjust note duration loop limit iteration factor (-1) (file offset: 0x0B8A)
        adda.l   #$4,a1                               ; Advance track note reader pointer by 4 bytes       (file offset: 0x0B8E)
        move.l   a1,$22(a0)                           ; Save advanced track note reader pointer inside structure (file offset: 0x0B94)
        dc.w     $2468                            ; Part of split instruction (movea.l $1a(a0), a2) (file offset: 0x0B98)
Music_Overlap_MoveaA2:
        dc.w     $001A                            ; Part of split instruction (movea.l $1a(a0), a2) (file offset: 0x0B9A)
        movea.l  $0(a0),a3                            ; Load voice notes play status channel structure base register (file offset: 0x0B9C)
        move.w   $18(a0),d0                           ; Load active note pitch offset register index       (file offset: 0x0BA0)
        subq.w   #$1,d0                               ; Adjust index offset iteration factor (-1)          (file offset: 0x0BA4)
        mulu.w   #$2,d0                               ; Multiply index by 2 for word offset alignment      (file offset: 0x0BA6)
        lea      Table_VibratoWaveform(pc),a4                      ; Point a4 to standard sound hardware pitch tuning table (file offset: 0x0BAA)
        move.w   (a4,d0.w),d1                         ; Read base tuning pitch period word from table      (file offset: 0x0BAE)
        move.w   $5e(a3),d0                           ; Read channel active pitch slide slide factor from structure (file offset: 0x0BB2)
        beq.b    Music_ApplyVibratoOnly                               ; If slide factor is zero, skip pitch slide calculations (file offset: 0x0BB6)
        cmp.w    $2a(a0),d1                           ; Compare active pitch slide to target base tuning period (file offset: 0x0BB8)
        bcs.b    Music_SlideDown                               ; If slide has exceeded target tuning, branch to limit pitch (file offset: 0x0BBC)
        add.w    d0,$2a(a0)                           ; Apply slide factor to current playing pitch period (file offset: 0x0BBE)
        cmp.w    $2a(a0),d1                           ; Compare updated playing pitch to target tuning period (file offset: 0x0BC2)
        bhi.b    Music_SlideUp_Done                               ; If updated pitch is above target, continue play configure (file offset: 0x0BC6)
        move.w   d1,$2a(a0)                           ; Cap playing pitch period exactly at target base tuning (file offset: 0x0BC8)
Music_SlideUp_Done:
        bra.b    Music_PitchModulation_Done                               ; Branch to configure channel sound hardware registers (file offset: 0x0BCC)
Music_SlideDown:
        sub.w    d0,$2a(a0)                           ; Apply slide factor to current playing pitch period (negative direction) (file offset: 0x0BCE)
        cmp.w    $2a(a0),d1                           ; Compare updated playing pitch to target tuning period (file offset: 0x0BD2)
        bcs.b    Music_SlideDown_Done                               ; If updated pitch is below target, continue play configure (file offset: 0x0BD6)
        move.w   d1,$2a(a0)                           ; Cap playing pitch period exactly at target base tuning (file offset: 0x0BD8)
Music_SlideDown_Done:
        bra.b    Music_PitchModulation_Done                               ; Branch to configure channel sound hardware registers (file offset: 0x0BDC)
Music_ApplyVibratoOnly:
        add.w    $34(a0),d1                           ; Add vibrato frequency modulation swing directly to base pitch (file offset: 0x0BDE)
        move.w   d1,$2a(a0)                           ; Update channel current playing pitch period        (file offset: 0x0BE2)
Music_PitchModulation_Done:
        movea.l  $0(a0),a3                            ; Load voice notes play status channel structure base register (file offset: 0x0BE6)
        adda.l   #$56,a3                              ; Point to active channel voice envelope parameters offset (file offset: 0x0BEA)
        move.l   $12(a0),d1                           ; Load current voice envelope tick position index    (file offset: 0x0BF0)
        clr.l    d2                                   ; Clear register d2                                  (file offset: 0x0BF4)
        move.b   (a3,d1.l),d2                         ; Read active volume level from envelope parameter stream (file offset: 0x0BF6)
        bpl.b    Music_Envelope_FadeIn                               ; Check if envelope volume level value is negative   (file offset: 0x0BFA)
        neg.b    d2                                   ; Negate volume value if negative (absolute value)   (file offset: 0x0BFC)
        clr.l    d3                                   ; Clear register d3                                  (file offset: 0x0BFE)
        move.w   $32(a0),d3                           ; Load channel baseline play note volume             (file offset: 0x0C00)
        sub.w    d2,d3                                ; Subtract active volume offset step (fade out!)     (file offset: 0x0C04)
        move.w   d3,d2                                ; Copy updated note volume value                     (file offset: 0x0C06)
        bra.b    Music_Envelope_UpdateVolume                               ; Branch to configure channel volume hardware register (file offset: 0x0C08)
Music_Envelope_FadeIn:
        add.w    $32(a0),d2                           ; Add active volume offset step (fade in!)           (file offset: 0x0C0A)
Music_Envelope_UpdateVolume:
        move.w   d2,$18(a0)                           ; Update active channel volume register variable     (file offset: 0x0C0E)
        addq.l   #$1,$12(a0)                          ; Advance voice envelope tick position index by one step (file offset: 0x0C12)
        cmpi.l   #$8,$12(a0)                          ; Check if envelope position reached envelope length limit (8) (file offset: 0x0C16)
        bne.b    Music_Envelope_IndexDone                               ; If not at limit, continue envelope update execution (file offset: 0x0C1E)
        clr.l    $12(a0)                              ; Reset voice envelope tick position index back to zero (file offset: 0x0C20)
Music_Envelope_IndexDone:
        movea.l  $0(a0),a3                            ; Load voice notes play status channel structure base register (file offset: 0x0C24)
        tst.w    $c(a0)                               ; Test channel active vibrato slide slide factor word (file offset: 0x0C28)
        beq.b    Music_Vibrato_Subtract                               ; If vibrato factor is zero, skip vibrato updates    (file offset: 0x0C2C)
        clr.w    $c(a0)                               ; Clear vibrato status flag word inside structure    (file offset: 0x0C2E)
        clr.l    d2                                   ; Clear register d2                                  (file offset: 0x0C32)
        move.b   $55(a3),d2                           ; Read vibrato swing amplitude factor from structure (file offset: 0x0C34)
        move.w   $2a(a0),d1                           ; Load current playing pitch period                  (file offset: 0x0C38)
        add.w    d2,d1                                ; Add vibrato swing displacement to pitch period     (file offset: 0x0C3C)
        move.w   d1,$2a(a0)                           ; Update channel current playing pitch period        (file offset: 0x0C3E)
        bra.b    Music_Vibrato_Done                               ; Branch to configure channel play speed parameters  (file offset: 0x0C42)
Music_Vibrato_Subtract:
        move.w   #$ffff,$c(a0)                        ; Set vibrato direction status flag word ($ffff)     (file offset: 0x0C44)
        clr.l    d2                                   ; Clear register d2                                  (file offset: 0x0C4A)
        move.b   $55(a3),d2                           ; Read vibrato swing amplitude factor from structure (file offset: 0x0C4C)
        move.w   $2a(a0),d1                           ; Load current playing pitch period                  (file offset: 0x0C50)
        sub.w    d2,d1                                ; Subtract vibrato swing displacement from pitch period (file offset: 0x0C54)
        move.w   d1,$2a(a0)                           ; Update channel current playing pitch period        (file offset: 0x0C56)
Music_Vibrato_Done:
        clr.l    d2                                   ; Clear register d2                                  (file offset: 0x0C5A)
        move.w   $60(a3),d2                           ; Read channel active pitch slide slide factor from structure (file offset: 0x0C5C)
        sub.w    d2,$34(a0)                           ; Subtract pitch slide factor from current playing pitch (file offset: 0x0C60)
        clr.l    d0                                   ; Clear register d0                                  (file offset: 0x0C64)
        move.w   $2a(a0),d0                           ; Load current playing pitch period                  (file offset: 0x0C66)
        move.w   $62(a3),d1                           ; Read instrument active frequency modulation depth  (file offset: 0x0C6A)
        beq.b    Music_Modulate_Done                               ; If modulation depth is zero, skip vibrato modulation (file offset: 0x0C6E)
        bmi.b    Music_Modulate_Add                               ; If modulation direction is negative, branch to subtract (file offset: 0x0C70)
        sub.w    $38(a0),d0                           ; Subtract modulation swing from current playing pitch (file offset: 0x0C72)
        bra.b    Music_Modulate_Done                               ; Branch to compile voice configuration parameter values (file offset: 0x0C76)
Music_Modulate_Add:
        add.w    $38(a0),d0                           ; Add modulation swing to current playing pitch      (file offset: 0x0C78)
Music_Modulate_Done:
        move.l   $8(a0),d1                            ; Load voice active envelope decay speed parameters  (file offset: 0x0C7C)
        subq.b   #$1,$10(a0)                          ; Decrement voice envelope current decay volume step (file offset: 0x0C80)
        bpl.b    Music_CycleWave_Done                               ; If volume step remains active, continue playback configure (file offset: 0x0C84)
        addq.l   #$1,d1                               ; Advance active instrument wave cycle pointer by one longword (file offset: 0x0C86)
        cmpi.l   #$20,d1                              ; Check if wave cycle pointer reached end of wave database (32) (file offset: 0x0C88)
        bne.w    Music_CycleWave_Save                               ; If not at database end, continue wave cycling execution (file offset: 0x0C8E)
        clr.l    d1                                   ; Reset instrument wave cycle pointer back to database start (file offset: 0x0C92)
Music_CycleWave_Save:
        move.l   d1,$8(a0)                            ; Save advanced instrument wave cycle pointer inside structure (file offset: 0x0C94)
        move.b   $52(a3),$10(a0)                      ; Reset voice envelope current decay volume step counter (file offset: 0x0C98)
Music_CycleWave_Done:
        lea      $32(a3),a4                           ; Point to active instrument wave description entries start (file offset: 0x0C9E)
        clr.l    d2                                   ; Clear register d2                                  (file offset: 0x0CA2)
        move.b   (a4,d1.l),d2                         ; Read active wave cycle data byte offset from descriptor (file offset: 0x0CA4)
        ext.w    d2                                   ; Sign-extend wave data byte offset to word size     (file offset: 0x0CA8)
        tst.b    $54(a3)                              ; Test active instrument wave cycle timing flag byte (file offset: 0x0CAA)
        beq.w    Music_SkipWavePitchOffset                               ; If flag is zero, skip manual wave cycle pitch offsets (file offset: 0x0CAE)
        add.w    d2,d0                                ; Add manual wave cycle pitch offset to current playing pitch (file offset: 0x0CB2)
Music_SkipWavePitchOffset:
        move.w   d0,$6(a2)                            ; Write final compiled pitch period to Paula voice hardware (file offset: 0x0CB4)
        clr.l    d2                                   ; Clear register d2                                  (file offset: 0x0CB8)
        movea.l  $0(a0),a2                            ; Load voice notes play status channel structure base register (file offset: 0x0CBA)
        clr.l    d0                                   ; Clear register d0                                  (file offset: 0x0CBE)
        clr.l    d1                                   ; Clear register d1                                  (file offset: 0x0CC0)
        move.b   $30(a2),d0                           ; Read active play voice volume limit parameter      (file offset: 0x0CC2)
        move.b   $31(a2),d1                           ; Read active play voice volume current level        (file offset: 0x0CC6)
        cmp.l    $4(a0),d1                            ; Compare current volume level to volume limit parameter (file offset: 0x0CCA)
        beq.b    Music_Volume_WriteHardware                               ; If volume is exactly at limit, branch to write hardware (file offset: 0x0CCE)
        cmpi.l   #$670e,d0                            ; Set volume slide transition parameters             (file offset: 0x0CD0)
        cmp.l    $4(a0),d0                            ; Compare current volume level to volume limit parameter (file offset: 0x0CD6)
        bne.b    Music_Volume_DoSlide                               ; If volume has not reached limit, branch to slide volume (file offset: 0x0CDA)
        cmpi.w   #$0,$36(a0)                          ; Check if current voice envelope has completed play lifecycle (file offset: 0x0CDC)
        beq.b    Music_Volume_SetSilence                               ; If envelope has finished, branch to set silent volume (file offset: 0x0CE2)
Music_Volume_DoSlide:
        move.l   $4(a0),d2                            ; Load current volume level from register structure  (file offset: 0x0CE4)
        mulu.w   #$2,d2                               ; Multiply volume level by 2 for word offset alignment (file offset: 0x0CE8)
        lea      $20(a2),a3                           ; Point a3 to active channel voice volume scaling tables (file offset: 0x0CEC)
        clr.l    d3                                   ; Clear register d3                                  (file offset: 0x0CF0)
        clr.l    d4                                   ; Clear register d4                                  (file offset: 0x0CF2)
        move.b   (a3,d2.w),d3                         ; Read active channel voice volume scale step increment (file offset: 0x0CF4)
        move.b   $1(a3,d2.w),d4                       ; Read active channel voice volume scale step decrement (file offset: 0x0CF8)
        cmp.w    $38(a0),d4                           ; Compare volume limit to current voice envelope level (file offset: 0x0CFC)
        bhi.b    Music_Volume_SlideUp                               ; If envelope is above limit, branch to decrement volume (file offset: 0x0D00)
        sub.w    d3,$38(a0)                           ; Subtract volume increment step from current envelope level (file offset: 0x0D02)
        cmp.w    $38(a0),d4                           ; Compare updated envelope level to volume limit     (file offset: 0x0D06)
        ble.b    Music_Volume_SlideDown_Done                               ; If updated level is below limit, branch to save volume (file offset: 0x0D0A)
        move.w   d4,$38(a0)                           ; Cap playing note volume exactly at target volume limit (file offset: 0x0D0C)
        addq.l   #$1,$4(a0)                           ; Increment voice volume change delay frame counter  (file offset: 0x0D10)
Music_Volume_SlideDown_Done:
        bra.b    Music_Volume_SetSilence                               ; Branch to write volume to Paula voice hardware registers (file offset: 0x0D14)
Music_Volume_SlideUp:
        add.w    d3,$38(a0)                           ; Add volume decrement step to current envelope level (file offset: 0x0D16)
        cmp.w    $38(a0),d4                           ; Compare updated envelope level to volume limit     (file offset: 0x0D1A)
        bhi.b    Music_Volume_SetSilence                               ; If updated level is above limit, branch to save volume (file offset: 0x0D1E)
        move.w   d4,$38(a0)                           ; Cap playing note volume exactly at target volume limit (file offset: 0x0D20)
        addq.l   #$1,$4(a0)                           ; Increment voice volume change delay frame counter  (file offset: 0x0D24)
Music_Volume_SetSilence:
        clr.l    d1                                   ; Clear register d1 (set voice volume to absolute silence) (file offset: 0x0D28)
Music_Volume_WriteHardware:
        move.w   $38(a0),d1                           ; Load voice active envelope decay volume step       (file offset: 0x0D2A)
        divu.w   #$4,d1                               ; Divide volume level by 4 for hardware register scale (0-64) (file offset: 0x0D2E)
        movea.l  $1a(a0),a1                           ; Load Paula hardware audio interface target registers (file offset: 0x0D32)
        move.w   d1,$8(a1)                            ; Write final scaled voice volume value to Paula hardware register (file offset: 0x0D36)
        rts                                           ; Return from sound player parser ticks handler subroutine (file offset: 0x0D3A)

; ============================================================================
; Data Block: Sound Synthesizer Commands and Pattern Data (0x0D3C - 0x0FD2)
; Notes   : The music player uses an array of 10-byte step descriptors for each voice
;           to play these patterns. Many patterns are reused and overlapped.
; ============================================================================
Pattern_Voice0_Start:
	dc.w     $0080,$0007,Track_Voice0_Notes&$ffff,$0081,$0000,$0000,$0000,$0019 ; Data words (file offset: 0x0D3C)
	dc.w     $000C,$0019,$0018,$0019,$0006,$0025,$0006,$0019 ; Data words (file offset: 0x0D4C)
	dc.w     $000C,$0019,$0024,$0000,$0080,$0007,Track_Voice0_Notes&$ffff,$0081 ; Data words (file offset: 0x0D5C)
	dc.w     $0000,$0000,$0000,$0019,$000C,$0019,$0018,$0019 ; Data words (file offset: 0x0D6C)
	dc.w     $0006,$0017,$0006,$0019                       ; Data words (file offset: 0x0D7C)
Pattern_Voice2_Start:
	dc.w     $000C                                         ; Data words (file offset: 0x0D84)
Pattern_Voice2_Alt:
	dc.w     $0019,$0024,$0000,$0080,$0007,Track_Voice1_Notes&$ffff,$0081 ; Data words (file offset: 0x0D86)
	dc.w     $0003,$0700,$0003,$0700,$003D,$0060,$0081,$0003 ; Data words (file offset: 0x0D94)
	dc.w     $0800,$0003,$0800,$003D,$0060,$0081,$FE03,$07FE ; Data words (file offset: 0x0DA4)
	dc.w     $FE03,$07FE,$003D,$0060                       ; Data words (file offset: 0x0DB4)
Pattern_Voice2_Notes:
	dc.w     $0081,$FE02,$05FE,$FE02,$05FE,$003D,$0060,$0000 ; Data words (file offset: 0x0DBC)
	dc.w     $0080,$0007,Track_Voice2_Notes&$ffff,$0081,$0000,$0000,$0000,$0082 ; Data words (file offset: 0x0DCC)
Pattern_Voice3_Start:
Pattern_Voice3_Alt:
	dc.w     $0018,$002D,$000C,$0082,$0024,$002D,$000C,$002D ; Data words (file offset: 0x0DDC)
	dc.w     $0006,$002D,$0006,$0082,$0018,$002D,$000C,$0082 ; Data words (file offset: 0x0DEC)
	dc.w     $0024,$002D,$0008,$002C,$0008,$002B,$0008,$0000 ; Data words (file offset: 0x0DFC)
	dc.w     $0080,$0007,Track_Voice3_Notes&$ffff,$0081,$0000,$0000,$0000,$0031 ; Data words (file offset: 0x0E0C)
Pattern_Voice3_Part2:
	dc.w     $0030,$0034,$000C,$0033,$000C,$0031,$000C,$002F ; Data words (file offset: 0x0E1E)
	dc.w     $000C,$002D,$0030,$0034,$000C,$0033,$000C,$0031 ; Data words (file offset: 0x0E2E)
	dc.w     $000C,$002F,$000C,$0034,$0030,$0034,$000C,$0033 ; Data words (file offset: 0x0E3E)
	dc.w     $000C,$0031,$000C,$002F,$000C,$0036,$0018,$0033 ; Data words (file offset: 0x0E4E)
	dc.w     $0018,$0031,$0018                             ; Data words (file offset: 0x0E5E)
Pattern_Voice3_Part3:
	dc.w     $002F,$0018,$0000,$0080,$0007,Track_Voice3_Notes&$ffff,$0081,$0000 ; Data words (file offset: 0x0E62)
	dc.w     $0000,$0000,$0031,$0030,$0038,$000C,$0038,$000C ; Data words (file offset: 0x0E72)
	dc.w     $0038,$000C,$0036,$0018,$0038,$006C,$0034,$000C ; Data words (file offset: 0x0E82)
	dc.w     $0034,$0018,$0034,$0018,$0034,$000C,$0036,$0018 ; Data words (file offset: 0x0E92)
	dc.w     $0033,$0018,$0031,$0018,$002F,$0018,$0000,$0080 ; Data words (file offset: 0x0EA2)
	dc.w     $0007,Track_Voice3_Notes&$ffff,$0081,$0000,$0000,$0000,$0031,$0048 ; Data words (file offset: 0x0EB2)
	dc.w     $0038                                         ; Data words (file offset: 0x0EC0)
Pattern_Voice2_Step2:
	dc.w     $0018,$0036,$000C,$0034,$000C,$0031,$0060,$0034 ; Data words (file offset: 0x0EC2)
	dc.w     $000C,$0034,$0018,$0034,$0018,$0034,$000C,$0036 ; Data words (file offset: 0x0ED2)
	dc.w     $0018,$0033,$0018,$0031,$0018,$002F,$0018,$0000 ; Data words (file offset: 0x0EE2)
	dc.w     $0082,$0180,$0000,$0100,$0000,$0032,$0050,$0046 ; Data words (file offset: 0x0EF2)
	dc.w     $00A0,$0028,$006E,$0032                       ; Data words (file offset: 0x0F02)
Pattern_Voice1_Step3:
	dc.w     $00A0,$005A,$0050,$006E,$00A0,$0046,$006E,$005A ; Data words (file offset: 0x0F0E)
	dc.w     $0082,$0078,$0050,$008C,$00A0,$00A0,$0050,$00B4 ; Data words (file offset: 0x0F1E)
	dc.w     $00A0,$0078,$0050,$00B4,$0064,$0078,$008C,$00A0 ; Data words (file offset: 0x0F2E)
	dc.w     $00A0,$0096,$006E,$00A0,$00A0,$00B4,$006E,$00BE ; Data words (file offset: 0x0F3E)
	dc.w     $00A0,$00C8,$0050,$00DC,$00A0                 ; Data words (file offset: 0x0F4E)
Pattern_Voice0_Step2:
	dc.w     $00C8,$0050,$010E,$0064                       ; Data words (file offset: 0x0F56)
Var_ScrollText_CharDelayTimer:
	dc.w     $00C8                         ; Data words
Var_ScrollText_CharPointer:
	dc.w     $008C,$010E                   ; Data words
Table_RectFillCoordinates:
	dc.w     $00A0,$00DC,$006E,$00E6,$00A0,$00FA,$0064,$010E ; RectFill coordinate data words (file offset: 0x0F64)
	dc.w     $006E,$00FA,$0082,$010E,$008C,$0005,$0006,$0007 ; RectFill coordinate data words
	dc.w     $0008,$0009,$000A,$000B,$000C,$000D,$000E,$000F ; RectFill coordinate data words
	dc.w     $050F,$060F,$070F,$080F,$090F,$0A0F,$0B0F,$0C0F ; RectFill coordinate data words
	dc.w     $0D0F,$0E0F,$0F0F,$0E0F,$0D0F,$0C0F,$0B0F,$0A0F ; RectFill coordinate data words
	dc.w     $090F,$080F,$070F,$060F,$050F,$000F,$000E,$000D ; RectFill coordinate data words
	dc.w     $000C,$000B,$000A,$0009,$0008,$0007,$0006 ; RectFill coordinate data words

; ============================================================================
; Data Block: Intro Scrolltext String (0x0FD2 - 0x1038)
; Notes   : The first 18 bytes of this string ("HQC inc. and Hotli") are also read
;           by the Start loop as the final coordinate words of the RectFill table
;           (Table_RectFillCoordinates).
; ============================================================================
Str_ScrollText_IntroPrefix:
        dc.b     "HQC inc. and Hot"            ; Scrolltext string prefix / RectFill coords (file offset: 0x0FD2)
        dc.b     "li"                          ; Continuation of scrolltext prefix / RectFill coords (file offset: 0x0FE2)
Table_RectFillCoordinates_Sentinel:
        dc.b     "ne"                          ; Sentinel for RectFill coordinates / ColorBar Cycle start (file offset: 0x0FE4)
Table_CopperColorBar_CycleBuffer:
        dc.b     " proudly present -- King of Chicago --  Thanx to Hotline and also to Dave for the "
                                               ; Cycled copper color bar palette wave buffer (file offset: 0x0FE6)

; ============================================================================
; Data Block: Scrolltext Greeting Body (0x1038 - 0x13CB)
; Notes   : The vertical blank routine prints these characters one-by-one
;           using the default graphics.library topaz font in the RastPort.
; ============================================================================
Str_ScrollingText_Greetings:
        dc.b     "original !!! Cracked by HQC inc. on 11.01.1988 !!! (Hi Ben, "
        dc.b     "good protection!?). Smashing Greetings to our Mega-Contacts "
        dc.b     "The Champs , Bitstoppers, The Cure , Bamiga Sector One, Wizards, "
        dc.b     "OGM-Crew, The Visitors, Skyline, Irata/Red Sector, ACF, Explorer, "
        dc.b     "S.S.I., S.C.A., Movers,  Powerslaves, Prophets AG, I.C.I.,Axxess "
        dc.b     ",Tristar,CRM-Crew, The 3rd Wave, Vision, New Edition, Def Jam, "
        dc.b     "R.B.B, Megaforce, M.C.P (Thanxx for the Mega Graphixx), Jaggerboy, "
        dc.b     "Spreadpoint, Yeti-Factories, Blizzard, 1001 and the cracking "
        dc.b     "Crew, Executer, Powerstation, USR, Atom-Soft, The New Age, HQC "
        dc.b     "II!, Star Frontiers, Unit A, The Australian Jungle Cracking "
        dc.b     "Crew, FY , The Light Circle, The African Jumping Kangaroos!, "
        dc.b     "Bitkillersoft, Pah! , and outstanding Greetings to the Beastie "
        dc.b     "Boys for always the latest 64 Stuff and Hotline for the new "
        dc.b     "originals . Contact us for the latest Stuff, Write to: HQC, "
        dc.b     "Postlagernd, 8 Muenchen 71. Bye .....    "

; ============================================================================
; Data Block: ViewPort & Display Setup Structure Parameters (0x13CB - 0x1400)
; Purpose   : System viewport configuration registers, horizontal boundaries, 
;             and vertical bouncy displacement tables parsed by graphics.library
; Notes     : These bytes are printed by the scrolltext loop before looping back!
; ============================================================================
Table_Graphics_ViewportSetup:
        dc.b     $00,$00,$04,$08,$0C,$10,$14,$18,$1C,$20,$28,$30,$00 ; Vertical displacement step sizes (13 bytes) (file offset: 0x13CB)
Table_Graphics_DIW_Regs:
        dc.b     $00,$00,$02,$94,$04,$B6,$06,$D8,$08,$FA,$06,$D8,$04,$B6,$02,$94 ; Bouncy copper wait positions (16 bytes) (file offset: 0x13D8)
Table_Viewport_InitRegs:
        dc.w     $0000                                           ; Table boundary / padding word (file offset: 0x13E8)
        dc.w     $008E,$2C81                                     ; DIWSTRT = $2C81 (Display Window Start) (file offset: 0x13EA)
        dc.w     $0090,$F4C1                                     ; DIWSTOP = $F4C1 (Display Window Stop) (file offset: 0x13EE)
        dc.w     $0092,$0038                                     ; DDFSTRT = $0038 (Data Fetch Start) (file offset: 0x13F2)
        dc.w     $0094,$00D0                                     ; DDFSTOP = $00D0 (Display Data Fetch Stop) (file offset: 0x13F6)
        dc.w     $0102,$0000                                     ; BPLCON1 = $0000 (Bitplane horizontal scroll) (file offset: 0x13FA)
        dc.w     $0104                                           ; BPLCON2 register offset (value $003F is dual-purpose overlapped at 0x1400) (file offset: 0x13FE)

; ============================================================================
; Data Block: Static Copper List (0x1400 - 0x1428)
; ============================================================================
        dc.w     $003F                         ; Padding / alignment word (file offset: 0x1400)
        dc.w     $0108,$0004                   ; BPL1MOD  = $0004 (Bitplane modulo for odd planes) (file offset: 0x1402)
Loop_BuildCopperWaitInstructions:
        dc.w     $010A,$0004                   ; BPLCON3  = $0004 (Bitplane control register 3) (file offset: 0x1406)
        dc.w     $0180,$0000                   ; COLOR00  = $0000 (Set background color to black) (file offset: 0x140A)
        dc.w     $0182,$0FFF                   ; COLOR01  = $0FFF (Set color 1 to white) (file offset: 0x140E)
        dc.w     $0100,$1200                   ; BPLCON0  = $1200 (1 Bitplane, color enabled) (file offset: 0x1412)
        dc.w     $00E0,$0005                   ; BPL1PTH  = $0005 (Bitplane 1 pointer high word) (file offset: 0x1416)
        dc.w     $00E2,$0000                   ; BPL1PTL  = $0000 (Bitplane 1 pointer low word) (file offset: 0x141A)
        dc.w     $009C,$8010                   ; INTREQ   = $8010 (Request copper interrupt) (file offset: 0x141E)
        dc.w     $FFFF,$FFFE                   ; COPPER WAIT (Wait for end of frame sentinel) (file offset: 0x1422)
        dc.w     $0008                         ; Padding / end marker (file offset: 0x1426)

; ============================================================================
; Function: Sub_GenerateCopperList
; Purpose : Compile VBlank copper wait lists dynamically on the fly.
; ============================================================================
Sub_GenerateCopperList:
        clr.l    $e(a0)                               ; Clear Paula Audio DMA state parameters inside register (file offset: 0x1428)
        move.w   #$96,$6(a1)                          ; Write Paula vertical scroll delay speed config     (file offset: 0x142C)
        move.w   d2,$96(a6)                           ; Update vertical scroll height scale inside structure (file offset: 0x1432)
        dc.w     $216C                            ; Part of split instruction (move.l -$7b3c(a4), $4(a0)) (file offset: 0x1436)
        dc.w     $84C4                            ; Part of split instruction (move.l -$7b3c(a4), $4(a0)) (file offset: 0x1438)
Var_VerticalBounce_ScrollIndexTable:
        dc.w     $0004                            ; Part of split instruction (move.l -$7b3c(a4), $4(a0)) (file offset: 0x143A)
        clr.l    (a0)                                 ; Clear register values for next loop sync initialization (file offset: 0x143C)
        moveq    #$0,d4                               ; Clear copper write command state register d4       (file offset: 0x143E)
        bset     d1,d4                                ; Set copper wait target line sync bit inside register d4 (file offset: 0x1440)
        move.w   d4,$9c(a6)                           ; Write copper VBlank sync wait instruction to viewport list (file offset: 0x1442)
Var_VerticalScroll_DirectionFlag:
        addq.w   #$1,d1                               ; Advance active copper row horizontal scan limit (+1) (file offset: 0x1446)
Var_VerticalScroll_AnimationTimer:
        lsl.w    #$1,d2                               ; Shift scan limit left for copper instruction offset alignment (file offset: 0x1448)
Var_VerticalBounce_ScrollWaitTable:
        adda.w   #$1e,a0                              ; Advance copper wait list layout destination address pointer (file offset: 0x144A)
        adda.w   #$10,a1                              ; Advance copper bounce offset source address pointer (file offset: 0x144E)
        dbra     d3,Loop_BuildCopperWaitInstructions                            ; Repeat copper sync instruction compilation loop    (file offset: 0x1452)
        movem.l  (a7)+,d0-d4/a0-a1/a4/a6              ; Restore saved registers from stack at subroutine exit (file offset: 0x1456)
Sub_AnimateBounceLogo:
        rte                                           ; Return from Exception (Level 3 interrupt complete) (file offset: 0x145A)

; ============================================================================
; Function: Sub_AnimateBounceLogo
; Purpose : Calculate bouncy color gradient spacing and screen scrolls.
; ============================================================================
        movem.l  d2/a0-a1/a4,-(a7)                    ; Save registers d2/a0-a1/a4 on stack at bounce entry (file offset: 0x145C)
        movea.l  a0,a6                                ; Point a6 to graphics base viewport state structure (file offset: 0x1460)
        movea.l  a1,a4                                ; Point a4 to logo vertical bounce animation variables (file offset: 0x1462)
        addq.l   #$1,-$7b3c(a4)                       ; Increment logo bounce animation frame counter      (file offset: 0x1464)
        lea      -$7bb8(a4),a0                        ; Point a0 to intermediate vertical bounce offset table 1 (file offset: 0x1468)
        lea      $a0(a6),a1                           ; Point a1 to copper list dynamic screen wait instructions (file offset: 0x146C)
        move.w   #$1,d1                               ; Set baseline screen vertical scroll index parameter (file offset: 0x1470)
        move.w   #$3,d2                               ; Set bounce viewport rows update loop counter to 4  (file offset: 0x1474)
        move.w   $1c(a6),d0                           ; Read current vertical scan timing parameters from register (file offset: 0x1478)
        and.w    #$780,d0                             ; Mask timing parameters to isolate scroll boundary  (file offset: 0x147C)
        move.w   d0,-$7b36(a4)                        ; Save scroll boundary scan position inside structure (file offset: 0x1480)
        move.w   #$780,$9a(a6)                        ; Disable Level 3 hardware vertical blanking interrupts (file offset: 0x1484)
        dc.w     $397C                            ; Part of split instruction (move.w #$8000, -$7b38(a4)) (file offset: 0x148A)
        dc.w     $8000                            ; Part of split instruction (move.w #$8000, -$7b38(a4)) (file offset: 0x148C)
Buffer_DynamicCopperColorCommands:
        dc.w     $84C8                            ; Part of split instruction (move.w #$8000, -$7b38(a4)) (file offset: 0x148E)
        tst.w    $8(a0)                               ; Test active bounce animation timer inside structure entry (file offset: 0x1490)
        beq.b    Bounce_SkipVScroll                               ; If timer is zero, skip vertical bounce calculations (file offset: 0x1494)
        move.l   -$7b3c(a4),d0                        ; Load logo bounce animation frame counter           (file offset: 0x1496)
        sub.l    $4(a0),d0                            ; Subtract logo bounce animation start timer offset  (file offset: 0x149A)
        cmp.l    #$2,d0                               ; Compare frame difference to bounce timing limit (2) (file offset: 0x149E)
        blt.b    Bounce_SkipVScroll                               ; If within timing limit, skip vertical scroll updates (file offset: 0x14A4)
        move.l   (a0),(a1)                            ; Copy advanced bounce parameter to dynamic copper list (file offset: 0x14A6)
        move.w   $a(a0),$4(a1)                        ; Write next bounce displacement word to copper wait instruction (file offset: 0x14A8)
        move.w   $c(a0),$6(a1)                        ; Write next bounce displacement word to copper wait instruction (file offset: 0x14AE)
        move.w   $e(a0),$8(a1)                        ; Write next bounce displacement word to copper wait instruction (file offset: 0x14B4)
        move.w   $12(a0),$14(a0)                      ; Write next bounce displacement word to copper wait instruction (file offset: 0x14BA)
        or.w     d1,-$7b38(a4)                        ; Set sound master register volume scale offset factor (file offset: 0x14C0)
        clr.w    $8(a0)                               ; Clear active bounce animation timer inside structure entry (file offset: 0x14C4)
Bounce_SkipVScroll:
        tst.w    $16(a0)                              ; Test active vertical scan timing parameters limit  (file offset: 0x14C8)
        blt.b    Bounce_NextRow                               ; If vertical scan timing has exceeded limit, branch to wrap (file offset: 0x14CC)
        move.l   $e(a0),d0                            ; move.l instruction                                 (file offset: 0x14CE)
        cmp.l    $16(a0),d0                           ; cmp.l instruction                                  (file offset: 0x14D2)
        beq.b    Bounce_ResetScanTiming                               ; beq.b instruction                                  (file offset: 0x14D6)
        blt.b    Bounce_IncrementScan                               ; If scan timing is below target, branch to increment (file offset: 0x14D8)
        sub.l    $1a(a0),d0                           ; Subtract active vertical scroll step factor        (file offset: 0x14DA)
        cmp.l    $16(a0),d0                           ; Compare updated scan timing to boundary limit      (file offset: 0x14DE)
        ble.b    Bounce_ResetScanTiming                               ; If updated timing is below boundary, branch to save (file offset: 0x14E2)
        bra.b    Bounce_UpdateScanTiming                               ; Branch to continue scroll animation compilation    (file offset: 0x14E4)
Bounce_IncrementScan:
        add.l    $1a(a0),d0                           ; Add active vertical scroll step factor             (file offset: 0x14E6)
        cmp.l    $16(a0),d0                           ; Compare updated scan timing to boundary limit      (file offset: 0x14EA)
        bge.b    Bounce_ResetScanTiming                               ; If updated timing is above boundary, branch to save (file offset: 0x14EE)
Bounce_UpdateScanTiming:
        move.l   d0,$e(a0)                            ; Update current logo vertical scan timing variable  (file offset: 0x14F0)
        swap     d0                                   ; Exchange upper and lower words of register for writing (file offset: 0x14F4)
        move.w   d0,$8(a1)                            ; Write updated logo vertical scan timing to copper list (file offset: 0x14F6)
        bra.b    Bounce_NextRow                               ; Branch to exit channel scroll animation subroutine (file offset: 0x14FA)
Bounce_ResetScanTiming:
        move.l   $16(a0),d0                           ; Load maximum logo vertical scan timing boundary value (file offset: 0x14FC)
        move.l   #$ffff0016,$60e6(a0)                 ; Reset current logo vertical scan timing variables  (file offset: 0x1500)
        lsl.w    #$1,d1                               ; Shift baseline screen vertical scroll index parameter left (file offset: 0x1508)
Bounce_NextRow:
        adda.w   #$1e,a0                              ; Advance vertical bounce offset source address pointer (+30) (file offset: 0x150A)
        adda.w   #$10,a1                              ; Advance copper wait list layout destination address pointer (+16) (file offset: 0x150E)
        dbra     d2,Buffer_DynamicCopperColorCommands                            ; Repeat vertical bounce animation update loop for rows (file offset: 0x1512)
        move.w   -$7b36(a4),d0                        ; Load saved scroll boundary scan position from structure (file offset: 0x1516)
        beq.b    Bounce_CheckVolume                               ; If position is zero, skip vertical blank re-enabling (file offset: 0x151A)
        or.w     #$8000,d0                            ; Set vertical blank re-enabling control flag bit ($8000) (file offset: 0x151C)
        move.w   d0,$9a(a6)                           ; Enable Level 3 hardware vertical blanking interrupts (file offset: 0x1520)
Bounce_CheckVolume:
        tst.b    -$7b37(a4)                           ; Test sound master register volume scale offset factor (file offset: 0x1524)
        beq.b    Bounce_Done                               ; If sound master factor is zero, skip Paula updates (file offset: 0x1528)
        move.w   -$7b38(a4),$96(a6)                   ; Write compiled volume scaling directly to Paula hardware (file offset: 0x152A)
Bounce_Done:
        movem.l  (a7)+,d2/a0-a1/a4                    ; Restore saved registers d2/a0-a1/a4 from stack     (file offset: 0x1530)
        moveq    #$0,d0                               ; Set success return code (d0 = 0)                   (file offset: 0x1534)
        rts                                           ; Return from Sub_AnimateBounceLogo subroutine       (file offset: 0x1536)

; ============================================================================
; Data Block: Background Graphics Header & 1-Bitplane Logo Data (4.3KB) (0x1538 - 0x2700)
; ============================================================================
	dc.b     $4E,$55,$00,$00,$4A,$6C,$84,$CC,$66,$3C,$29,$4C,$9E,$B8,$42,$6C ; Data bytes
	dc.b     $87,$34,$42,$AC,$87,$36,$19,$7C,$00,$02,$9E,$C4,$19,$7C,$00,$20 ; Data bytes
	dc.b     $9E,$C5,$41,$FA,$00,$38,$29,$48,$9E,$C6,$29,$6C,$9E,$B8,$9E,$CA ; Data bytes
	dc.b     $41,$FA,$02,$96,$29,$48,$9E,$CE,$48,$6C,$9E,$BC,$48,$78,$00,$05 ; Data bytes
	dc.b     $4E,$BA,$4E,$CC,$50,$4F,$39,$7C,$00,$01,$84,$CC,$42,$A7,$3F,$3C ; Data bytes
	dc.b     $00,$10,$4E,$BA,$00,$00,$00,$08,$00,$00,$03,$89,$00,$00,$01,$A2 ; Data bytes
	dc.b     $00,$00,$01,$E8,$00,$00,$00,$0C,$BF,$3D,$21,$D2,$44,$50,$50,$56 ; Data bytes
	dc.b     $00,$00,$00,$68,$00,$00,$00,$00,$00,$00,$01,$68,$00,$00,$01,$40 ; Data bytes
	dc.b     $00,$C8,$00,$02,$00,$5A,$00,$02,$00,$00,$00,$02,$00,$00,$00,$02 ; Data bytes
	ds.b     16                            ; Zeros padding
	ds.b     16                            ; Zeros padding
	dc.b     $00,$00,$00,$00,$00,$01,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00 ; Data bytes
	dc.b     $00,$00,$00,$01,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; Data bytes
	dc.b     $00,$01,$00,$02,$43,$52,$4E,$47,$00,$00,$00,$08,$00,$00,$00,$01 ; Data bytes
	dc.b     $14,$1F,$43,$52,$4E,$47,$00,$00,$00,$08,$22,$00,$0D,$00,$00,$01 ; Data bytes
	dc.b     $0B,$0F,$43,$52,$4E,$47,$00,$00,$00,$08,$38,$00,$0A,$00,$00,$01 ; Data bytes
	dc.b     $00,$00,$43,$52,$4E,$47,$00,$00,$00,$08,$0C,$00,$0A,$00,$00,$01 ; Data bytes
	dc.b     $00,$00,$42,$4F,$44,$59,$00,$00,$69,$55,$27,$FF,$AB,$FF,$AB,$FF ; Data bytes
	dc.b     $AB,$FF,$AB,$FF,$D5,$FB,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF ; Data bytes
	dc.b     $93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF ; Data bytes
	dc.b     $05,$40,$05,$27,$FF,$EF,$FF,$EF,$FF,$EF,$FF,$EF,$FF,$F7,$FC,$28 ; Data bytes
	dc.b     $00,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$28 ; Data bytes
	dc.b     $00,$28,$00,$28,$00,$28,$00,$28,$00,$FB,$BF,$FB,$0A,$FF,$EF,$FF ; Data bytes
	dc.b     $EF,$FF,$EF,$FF,$EF,$FF,$F7,$F8,$E7,$00,$02,$7F,$FF,$FF,$0A,$00 ; Data bytes
	dc.b     $10,$00,$10,$00,$10,$00,$0F,$FF,$F7,$FB,$E7,$FF,$02,$7F,$FF,$FF ; Data bytes
	dc.b     $FA,$00,$02,$10,$00,$08,$E3,$00,$27,$FF,$AB,$FF,$AB,$FF,$AB,$FF ; Data bytes
	dc.b     $AB,$FF,$D5,$FB,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF ; Data bytes
	dc.b     $93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$05,$40 ; Data bytes
	dc.b     $05,$27,$FF,$EF,$FF,$EF,$FF,$EF,$FF,$EF,$FF,$F7,$FC,$28,$00,$28 ; Data bytes
	dc.b     $00,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$28 ; Data bytes
	dc.b     $00,$28,$00,$28,$00,$28,$00,$FB,$BF,$FB,$0A,$FF,$EF,$FF,$EF,$FF ; Data bytes
	dc.b     $EF,$FF,$EF,$FF,$F7,$F8,$E7,$00,$02,$7F,$FF,$FF,$0A,$00,$10,$00 ; Data bytes
	dc.b     $10,$00,$10,$00,$0F,$FF,$F7,$FB,$E7,$FF,$02,$7F,$FF,$FF,$FA,$00 ; Data bytes
	dc.b     $02,$10,$00,$08,$E3,$00,$27,$FF,$AB,$FF,$AB,$FF,$AB,$FF,$AB,$FF ; Data bytes
	dc.b     $D5,$FB,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF ; Data bytes
	dc.b     $93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$05,$40,$05,$27 ; Data bytes
	dc.b     $FF,$EF,$FF,$EF,$FF,$EF,$FF,$EF,$FF,$F7,$00,$00,$00,$08,$00,$00 ; Data bytes
	dc.b     $03,$89,$00,$00,$01,$A3,$00,$00,$01,$E8,$00,$00,$00,$0D,$26,$FD ; Data bytes
	dc.b     $D9,$2B,$FC,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$28 ; Data bytes
	dc.b     $00,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$FB,$BF,$FB ; Data bytes
	dc.b     $0A,$FF,$EF,$FF,$EF,$FF,$EF,$FF,$EF,$FF,$F7,$F8,$E7,$00,$02,$7F ; Data bytes
	dc.b     $FF,$FF,$0A,$00,$10,$00,$10,$00,$10,$00,$0F,$FF,$F7,$FB,$E7,$FF ; Data bytes
	dc.b     $02,$7F,$FF,$FF,$FA,$00,$02,$10,$00,$08,$E3,$00,$00,$FF,$FA,$00 ; Data bytes
	dc.b     $1F,$03,$D5,$FB,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF ; Data bytes
	dc.b     $93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$05,$40 ; Data bytes
	dc.b     $05,$00,$FF,$FA,$00,$1F,$03,$F7,$FC,$28,$00,$28,$00,$28,$00,$28 ; Data bytes
	dc.b     $00,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$28 ; Data bytes
	dc.b     $00,$28,$00,$FB,$BF,$FB,$F8,$FF,$01,$F7,$F8,$E7,$00,$02,$7F,$FF ; Data bytes
	dc.b     $FF,$00,$00,$F9,$FF,$01,$F7,$FB,$E7,$FF,$02,$7F,$FF,$FF,$F8,$00 ; Data bytes
	dc.b     $00,$08,$E3,$00,$01,$FF,$7F,$FB,$FF,$1F,$FB,$D5,$FB,$93,$FF,$93 ; Data bytes
	dc.b     $FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93 ; Data bytes
	dc.b     $FF,$93,$FF,$93,$FF,$93,$FF,$05,$40,$05,$01,$FF,$7F,$FB,$FF,$1F ; Data bytes
	dc.b     $FB,$F7,$FC,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$28 ; Data bytes
	dc.b     $00,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$FB,$BF,$FB ; Data bytes
	dc.b     $F8,$FF,$01,$F7,$F8,$E7,$00,$02,$7F,$FF,$FF,$01,$00,$80,$FB,$00 ; Data bytes
	dc.b     $02,$07,$F7,$FB,$E7,$FF,$02,$7F,$FF,$FF,$F8,$00,$00,$08,$E3,$00 ; Data bytes
	dc.b     $01,$F8,$40,$FB,$00,$1F,$0B,$D5,$FB,$93,$FF,$93,$FF,$93,$FF,$93 ; Data bytes
	dc.b     $FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93 ; Data bytes
	dc.b     $FF,$93,$FF,$05,$40,$05,$01,$FF,$40,$FB,$00,$1F,$0B,$F7,$FC,$28 ; Data bytes
	dc.b     $00,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$28 ; Data bytes
	dc.b     $00,$28,$00,$28,$00,$28,$00,$28,$00,$FB,$BF,$FB,$F8,$FF,$01,$F7 ; Data bytes
	dc.b     $F8,$E7,$00,$02,$7F,$FF,$FF,$01,$07,$80,$FB,$00,$02,$07,$F7,$FB ; Data bytes
	dc.b     $E7,$FF,$02,$7F,$FF,$FF,$F8,$00,$00,$08,$E3,$00,$01,$F8,$40,$FB ; Data bytes
	dc.b     $00,$1F,$0B,$D5,$FB,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93 ; Data bytes
	dc.b     $FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$84,$19,$FF,$93,$FF,$04 ; Data bytes
	dc.b     $00,$00,$01,$FF,$40,$FB,$00,$1F,$0B,$F7,$FC,$28,$00,$28,$00,$28 ; Data bytes
	dc.b     $00,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$28 ; Data bytes
	dc.b     $0F,$F8,$00,$28,$00,$F8,$00,$00,$F8,$FF,$01,$F7,$F8,$EC,$00,$01 ; Data bytes
	dc.b     $0F,$F8,$FE,$00,$02,$7F,$FF,$FF,$01,$07,$00,$00,$00,$08,$00,$00 ; Data bytes
	dc.b     $03,$89,$00,$00,$01,$A4,$00,$00,$01,$E8,$00,$00,$00,$0E,$63,$82 ; Data bytes
	dc.b     $D3,$87,$80,$FB,$00,$02,$07,$F7,$FB,$EC,$FF,$00,$F7,$FD,$FF,$02 ; Data bytes
	dc.b     $7F,$FF,$FF,$F8,$00,$00,$08,$E3,$00,$01,$F8,$4F,$FB,$FF,$1F,$8B ; Data bytes
	dc.b     $D5,$FB,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF ; Data bytes
	dc.b     $93,$FF,$93,$FF,$93,$FF,$92,$00,$03,$7F,$93,$FF,$05,$FF,$FF,$01 ; Data bytes
	dc.b     $FF,$4F,$FB,$FF,$1F,$8B,$F7,$FC,$28,$00,$28,$00,$28,$00,$28,$00 ; Data bytes
	dc.b     $28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$28,$7F,$FF,$00 ; Data bytes
	dc.b     $28,$00,$F9,$FF,$FF,$01,$FF,$F0,$FB,$00,$02,$7F,$F7,$F8,$EC,$00 ; Data bytes
	dc.b     $01,$7F,$FF,$FE,$00,$02,$7F,$FF,$FF,$01,$07,$80,$FB,$00,$02,$07 ; Data bytes
	dc.b     $F7,$FB,$EC,$FF,$00,$BF,$FD,$FF,$02,$7F,$FF,$FF,$F8,$00,$00,$08 ; Data bytes
	dc.b     $E3,$00,$01,$F8,$4C,$FB,$00,$1F,$8B,$D5,$FB,$93,$FF,$93,$FF,$93 ; Data bytes
	dc.b     $FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$90 ; Data bytes
	dc.b     $88,$08,$5F,$93,$FF,$05,$00,$00,$01,$FF,$4C,$FB,$00,$1F,$8B,$F7 ; Data bytes
	dc.b     $FC,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$28 ; Data bytes
	dc.b     $00,$28,$00,$28,$00,$29,$F8,$0F,$C0,$28,$00,$F9,$00,$00,$01,$FF ; Data bytes
	dc.b     $F7,$FB,$FF,$02,$7F,$F7,$F8,$ED,$00,$08,$01,$F8,$0F,$C0,$00,$00 ; Data bytes
	dc.b     $7F,$FF,$FF,$01,$07,$83,$FB,$FF,$02,$07,$F7,$FB,$ED,$FF,$02,$FE ; Data bytes
	dc.b     $F8,$0F,$FE,$FF,$02,$7F,$00,$00,$F8,$00,$00,$08,$EB,$00,$01,$07 ; Data bytes
	dc.b     $F0,$FB,$00,$01,$F8,$4D,$FC,$FF,$20,$FE,$8B,$D5,$FB,$93,$FF,$93 ; Data bytes
	dc.b     $FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93 ; Data bytes
	dc.b     $FF,$92,$40,$01,$2F,$93,$FF,$05,$00,$00,$01,$FF,$4D,$FC,$FF,$20 ; Data bytes
	dc.b     $FE,$8B,$F7,$FC,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00 ; Data bytes
	dc.b     $28,$00,$28,$00,$28,$00,$28,$00,$23,$C0,$01,$E0,$28,$00,$F9,$00 ; Data bytes
	dc.b     $00,$01,$FF,$F6,$FC,$00,$03,$01,$7F,$F7,$F8,$ED,$00,$08,$03,$C0 ; Data bytes
	dc.b     $01,$E0,$00,$00,$7F,$FF,$FF,$01,$07,$82,$FC,$00,$03,$01,$07,$F7 ; Data bytes
	dc.b     $FB,$EC,$FF,$01,$CF,$F9,$FE,$FF,$02,$7F,$00,$00,$F8,$00,$00,$08 ; Data bytes
	dc.b     $EB,$00,$01,$30,$06,$FB,$00,$01,$F8,$4D,$FC,$FF,$20,$FE,$8B,$D5 ; Data bytes
	dc.b     $FB,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93 ; Data bytes
	dc.b     $FF,$93,$FF,$93,$FF,$84,$00,$00,$17,$93,$FF,$05,$1F,$FF,$01,$FF ; Data bytes
	dc.b     $4D,$FC,$FF,$20,$FE,$8B,$F7,$FC,$28,$00,$28,$00,$28,$00,$28,$00 ; Data bytes
	dc.b     $28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$27,$07,$F0,$70 ; Data bytes
	dc.b     $28,$00,$F9,$1F,$FF,$01,$FF,$F7,$FB,$FF,$00,$00,$00,$08,$00,$00 ; Data bytes
	dc.b     $03,$89,$00,$00,$01,$A5,$00,$00,$01,$E8,$00,$00,$00,$0F,$D4,$69 ; Data bytes
	dc.b     $EC,$93,$02,$7F,$F7,$F8,$ED,$00,$FF,$07,$06,$F0,$70,$00,$00,$7F ; Data bytes
	dc.b     $FF,$FF,$01,$07,$82,$FC,$00,$03,$01,$07,$F7,$FB,$EC,$FF,$07,$38 ; Data bytes
	dc.b     $0F,$7F,$FF,$FF,$7F,$1F,$FF,$F8,$00,$00,$08,$EB,$00,$02,$C0,$00 ; Data bytes
	dc.b     $80,$FC,$00,$01,$F8,$4D,$FC,$FF,$20,$FC,$8B,$D5,$FB,$93,$FF,$93 ; Data bytes
	dc.b     $FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93 ; Data bytes
	dc.b     $FF,$88,$07,$F0,$0B,$93,$FF,$05,$10,$00,$01,$FF,$4C,$FB,$00,$1F ; Data bytes
	dc.b     $8B,$F7,$FC,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$28 ; Data bytes
	dc.b     $00,$28,$00,$28,$00,$28,$00,$0E,$33,$66,$38,$28,$00,$F9,$10,$00 ; Data bytes
	dc.b     $01,$FF,$F6,$FC,$00,$03,$01,$7F,$F7,$F8,$ED,$00,$08,$0E,$30,$06 ; Data bytes
	dc.b     $38,$00,$00,$7F,$FF,$FF,$01,$07,$83,$FB,$FF,$02,$07,$F7,$FB,$ED ; Data bytes
	dc.b     $FF,$08,$FE,$CF,$79,$BF,$FF,$FF,$7F,$1F,$FF,$F8,$00,$00,$08,$EC ; Data bytes
	dc.b     $00,$03,$01,$00,$00,$40,$FC,$00,$01,$F8,$4C,$FB,$00,$1F,$8B,$D5 ; Data bytes
	dc.b     $FB,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93 ; Data bytes
	dc.b     $FF,$93,$FF,$93,$FF,$90,$1D,$18,$05,$93,$FF,$05,$17,$FF,$01,$FF ; Data bytes
	dc.b     $4C,$FB,$00,$1F,$8B,$F7,$FC,$28,$00,$28,$00,$28,$00,$28,$00,$28 ; Data bytes
	dc.b     $00,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$1C,$5D,$1F,$1C,$28 ; Data bytes
	dc.b     $00,$F9,$17,$FF,$01,$FF,$F6,$FC,$00,$03,$01,$7F,$F7,$F8,$ED,$00 ; Data bytes
	dc.b     $08,$1C,$40,$03,$1C,$00,$00,$7F,$F8,$00,$01,$07,$83,$FB,$FF,$02 ; Data bytes
	dc.b     $07,$F7,$FB,$ED,$FF,$08,$FD,$BD,$1C,$DF,$FF,$FF,$7F,$18,$00,$F8 ; Data bytes
	dc.b     $00,$00,$08,$EC,$00,$FF,$02,$01,$E0,$20,$FC,$00,$01,$F8,$4C,$FB ; Data bytes
	dc.b     $00,$1F,$8B,$D5,$FB,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93 ; Data bytes
	dc.b     $FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$00,$3D,$BE,$03,$93,$FF,$05 ; Data bytes
	dc.b     $10,$00,$01,$FF,$4D,$FC,$FF,$20,$FE,$8B,$F7,$FC,$28,$00,$28,$00 ; Data bytes
	dc.b     $28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00 ; Data bytes
	dc.b     $38,$FD,$BF,$8E,$28,$00,$F9,$17,$FF,$01,$FF,$F7,$FB,$FF,$02,$7F ; Data bytes
	dc.b     $F7,$F8,$ED,$00,$08,$38,$80,$00,$8E,$00,$00,$7F,$FF,$FF,$01,$07 ; Data bytes
	dc.b     $82,$FC,$00,$03,$01,$07,$F7,$FB,$ED,$FF,$08,$DB,$7D,$FF,$6F,$FF ; Data bytes
	dc.b     $FF,$7F,$1F,$FF,$F8,$00,$00,$08,$EC,$00,$03,$04,$02,$00,$10,$FC ; Data bytes
	dc.b     $00,$01,$F8,$4C,$FB,$00,$1F,$8B,$D5,$FB,$93,$FF,$93,$FF,$93,$FF ; Data bytes
	dc.b     $93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$00,$7D ; Data bytes
	dc.b     $1F,$00,$93,$FF,$05,$17,$FF,$01,$FF,$4C,$00,$00,$00,$08,$00,$00 ; Data bytes
	dc.b     $03,$89,$00,$00,$01,$A6,$00,$00,$01,$E8,$00,$00,$00,$10,$DC,$81 ; Data bytes
	dc.b     $19,$12,$FB,$00,$1F,$8B,$F7,$FC,$28,$00,$28,$00,$28,$00,$28,$00 ; Data bytes
	dc.b     $28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$31,$FD,$1F,$C6 ; Data bytes
	dc.b     $28,$00,$F9,$17,$FF,$01,$FF,$F6,$FC,$00,$03,$01,$7F,$F7,$F8,$ED ; Data bytes
	dc.b     $00,$08,$31,$00,$00,$46,$00,$00,$7F,$FF,$FF,$01,$07,$82,$FC,$00 ; Data bytes
	dc.b     $03,$01,$07,$F7,$FB,$ED,$FF,$08,$F6,$FD,$1F,$B7,$FF,$FF,$7F,$18 ; Data bytes
	dc.b     $00,$01,$00,$01,$FC,$FF,$02,$FE,$00,$08,$EC,$00,$03,$08,$02,$E0 ; Data bytes
	dc.b     $08,$FC,$00,$01,$F8,$4C,$FB,$00,$1F,$8B,$D5,$FB,$93,$FF,$93,$FF ; Data bytes
	dc.b     $93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FE ; Data bytes
	dc.b     $50,$FF,$FF,$81,$93,$FF,$05,$17,$FF,$01,$FF,$4C,$FB,$00,$1F,$8B ; Data bytes
	dc.b     $F7,$FC,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00 ; Data bytes
	dc.b     $28,$00,$28,$00,$28,$00,$73,$FF,$FF,$E7,$28,$00,$F9,$17,$FF,$01 ; Data bytes
	dc.b     $FF,$F6,$FC,$00,$03,$01,$7F,$F7,$F8,$ED,$00,$08,$72,$00,$00,$27 ; Data bytes
	dc.b     $00,$00,$7F,$FF,$FF,$01,$07,$82,$FC,$00,$03,$01,$07,$F7,$FB,$ED ; Data bytes
	dc.b     $FF,$08,$F5,$FF,$FF,$D7,$FF,$FF,$7F,$1F,$FF,$01,$00,$01,$FC,$FF ; Data bytes
	dc.b     $02,$FE,$00,$08,$EC,$00,$03,$08,$00,$00,$08,$FC,$00,$01,$F8,$4C ; Data bytes
	dc.b     $FB,$00,$1F,$8B,$D5,$FB,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF ; Data bytes
	dc.b     $93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FE,$01,$FF,$7F,$C1,$13,$FF ; Data bytes
	dc.b     $05,$17,$FF,$01,$FF,$4C,$FB,$00,$1F,$8B,$F7,$FC,$28,$00,$28,$00 ; Data bytes
	dc.b     $28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00 ; Data bytes
	dc.b     $67,$FF,$7F,$F3,$28,$00,$F9,$17,$FF,$01,$FF,$F6,$FC,$00,$03,$01 ; Data bytes
	dc.b     $7F,$F7,$F8,$ED,$00,$08,$66,$00,$00,$33,$00,$00,$7F,$FF,$FF,$01 ; Data bytes
	dc.b     $07,$82,$FC,$00,$03,$01,$07,$F7,$FB,$ED,$FF,$08,$E9,$FF,$FF,$CB ; Data bytes
	dc.b     $FF,$FF,$7F,$1F,$FF,$01,$00,$01,$FC,$FF,$02,$FE,$00,$08,$EC,$00 ; Data bytes
	dc.b     $03,$10,$00,$00,$04,$FC,$00,$01,$F8,$4C,$FB,$00,$1F,$8B,$D5,$FB ; Data bytes
	dc.b     $93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF ; Data bytes
	dc.b     $93,$FF,$93,$FC,$A3,$FE,$3F,$E0,$13,$FF,$05,$10,$00,$01,$FF,$4C ; Data bytes
	dc.b     $FB,$00,$1F,$8B,$F7,$FC,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00 ; Data bytes
	dc.b     $28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$C5,$FE,$3F,$D3,$A8,$00 ; Data bytes
	dc.b     $F9,$10,$00,$01,$FF,$F6,$FC,$00,$03,$01,$7F,$F7,$F8,$ED,$00,$08 ; Data bytes
	dc.b     $E4,$00,$00,$13,$80,$00,$7F,$F8,$00,$01,$07,$82,$FC,$00,$03,$01 ; Data bytes
	dc.b     $07,$F7,$FB,$ED,$FF,$08,$EB,$FF,$7F,$EB,$00,$00,$00,$08,$00,$00 ; Data bytes
	dc.b     $03,$89,$00,$00,$01,$A7,$00,$00,$01,$E8,$00,$00,$00,$11,$6A,$AF ; Data bytes
	dc.b     $98,$94,$7F,$FF,$7F,$18,$00,$01,$00,$01,$FC,$FF,$02,$FE,$00,$08 ; Data bytes
	dc.b     $EC,$00,$03,$10,$00,$80,$04,$FE,$00,$01,$07,$FF,$01,$F8,$4C,$FB ; Data bytes
	dc.b     $00,$1F,$8B,$D5,$FB,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93 ; Data bytes
	dc.b     $FF,$93,$FF,$93,$FF,$93,$FF,$93,$FC,$A3,$FE,$3F,$E0,$93,$FF,$05 ; Data bytes
	dc.b     $10,$00,$01,$FF,$4C,$FB,$00,$1F,$8B,$F7,$FC,$28,$00,$28,$00,$28 ; Data bytes
	dc.b     $00,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$E3 ; Data bytes
	dc.b     $FE,$BF,$F3,$A8,$00,$F9,$10,$00,$01,$FF,$F6,$FC,$00,$03,$01,$7F ; Data bytes
	dc.b     $F7,$F8,$ED,$00,$08,$E0,$00,$80,$13,$80,$00,$7F,$F8,$00,$01,$07 ; Data bytes
	dc.b     $82,$FC,$00,$03,$01,$07,$F7,$FB,$EC,$FF,$07,$FE,$BF,$EF,$FF,$FF ; Data bytes
	dc.b     $7F,$18,$00,$01,$00,$01,$FC,$FF,$02,$FE,$00,$08,$EB,$00,$01,$01 ; Data bytes
	dc.b     $40,$FD,$00,$01,$07,$FF,$01,$F8,$4C,$FB,$00,$1F,$8B,$D5,$FB,$93 ; Data bytes
	dc.b     $FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93 ; Data bytes
	dc.b     $FF,$93,$F8,$A3,$FE,$3F,$E2,$93,$FF,$05,$10,$00,$01,$FF,$4C,$FB ; Data bytes
	dc.b     $00,$1F,$8B,$F7,$FC,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$28 ; Data bytes
	dc.b     $00,$28,$00,$28,$00,$28,$00,$28,$01,$63,$FE,$BF,$E3,$A8,$00,$F9 ; Data bytes
	dc.b     $10,$00,$01,$FF,$F6,$FC,$00,$03,$01,$7F,$F7,$F8,$EE,$00,$09,$01 ; Data bytes
	dc.b     $E0,$00,$80,$03,$80,$00,$7F,$F8,$00,$01,$07,$82,$FC,$00,$03,$01 ; Data bytes
	dc.b     $07,$F7,$FB,$EE,$FF,$09,$FE,$F7,$FE,$BF,$F7,$FF,$FF,$7F,$18,$00 ; Data bytes
	dc.b     $01,$00,$01,$FC,$FF,$02,$FE,$00,$08,$EC,$00,$03,$08,$01,$40,$08 ; Data bytes
	dc.b     $FE,$00,$01,$07,$FF,$01,$F8,$4C,$FB,$00,$1F,$8B,$D5,$FB,$93,$FF ; Data bytes
	dc.b     $93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF ; Data bytes
	dc.b     $93,$F8,$03,$FE,$3F,$E0,$13,$FF,$05,$10,$00,$01,$FF,$4C,$FB,$00 ; Data bytes
	dc.b     $1F,$8B,$F7,$FC,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00 ; Data bytes
	dc.b     $28,$00,$28,$00,$28,$00,$28,$01,$C7,$FE,$BF,$F1,$A8,$00,$F9,$10 ; Data bytes
	dc.b     $00,$01,$FF,$F6,$FC,$00,$03,$01,$7F,$F7,$F8,$EE,$00,$09,$01,$C0 ; Data bytes
	dc.b     $00,$80,$01,$80,$00,$7F,$F8,$00,$01,$07,$82,$FC,$00,$03,$01,$07 ; Data bytes
	dc.b     $F7,$FB,$EE,$FF,$09,$FE,$D7,$FE,$BF,$F5,$FF,$FF,$7F,$18,$00,$01 ; Data bytes
	dc.b     $00,$01,$FC,$FF,$02,$FE,$00,$08,$EC,$00,$03,$28,$01,$40,$0A,$FE ; Data bytes
	dc.b     $00,$01,$07,$FF,$01,$F8,$4C,$FB,$00,$1F,$8B,$D5,$FB,$93,$FF,$93 ; Data bytes
	dc.b     $FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93 ; Data bytes
	dc.b     $F8,$0C,$7E,$3F,$18,$13,$FF,$05,$10,$00,$00,$08,$00,$00,$03,$89 ; Data bytes
	dc.b     $00,$00,$01,$A8,$00,$00,$01,$E8,$00,$00,$00,$12,$1C,$80,$C1,$4A ; Data bytes
	dc.b     $01,$FF,$4C,$FB,$00,$1F,$8B,$F7,$FC,$28,$00,$28,$00,$28,$00,$28 ; Data bytes
	dc.b     $00,$28,$00,$28,$00,$28,$00,$28,$00,$28,$00,$28,$01,$CC,$7E,$BF ; Data bytes
	dc.b     $99,$A8,$00,$F9,$10,$00,$01,$FF,$F6,$FC,$00,$03,$01,$7F,$F7,$F8 ; Data bytes
	dc.b     $EE,$00,$09,$01,$C8,$00,$80,$09,$80,$00,$7F,$F8,$00,$01,$07,$82 ; Data bytes
	dc.b     $FC,$00,$03,$01,$07,$F7,$FB,$EE,$FF,$09,$FE,$DC,$7E,$BF,$9D,$FF ; Data bytes
	dc.b     $FF,$7F,$18,$00,$01,$00,$01,$FC,$FF,$02,$FE,$00,$08,$EC,$00,$03 ; Data bytes
	dc.b     $23,$81,$40,$62,$FE,$00,$01,$07,$FF,$01,$F8,$4C,$FB,$00,$0B,$8B ; Data bytes
	dc.b     $D5,$FB,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FA,$FF,$0C,$D3,$FF ; Data bytes
	dc.b     $93,$F8,$0D,$7E,$3E,$98,$13,$FF,$05,$10,$00,$01,$FF,$4C,$FB,$00 ; Data bytes
	dc.b     $0B,$8B,$F7,$FC,$28,$00,$28,$00,$28,$00,$28,$00,$28,$FA,$FF,$0C ; Data bytes
	dc.b     $E8,$00,$28,$01,$CC,$7E,$BE,$99,$A8,$00,$F9,$10,$00,$01,$FF,$F6 ; Data bytes
	dc.b     $FC,$00,$03,$01,$7F,$F7,$F8,$EE,$00,$09,$01,$C8,$06,$BE,$09,$80 ; Data bytes
	dc.b     $00,$7F,$F8,$00,$01,$07,$82,$FC,$00,$03,$01,$07,$F7,$FB,$F8,$FF ; Data bytes
	dc.b     $FA,$00,$0C,$3F,$FF,$FF,$FE,$DC,$7E,$BE,$DD,$FF,$FF,$7F,$18,$00 ; Data bytes
	dc.b     $01,$00,$01,$FC,$FF,$02,$FE,$00,$08,$EC,$00,$03,$22,$81,$41,$22 ; Data bytes
	dc.b     $FE,$00,$01,$07,$FF,$01,$F8,$4C,$FB,$00,$0B,$8B,$D5,$FB,$93,$FF ; Data bytes
	dc.b     $93,$FF,$93,$FF,$93,$FF,$93,$FA,$FF,$0C,$D3,$FF,$93,$F8,$0C,$7F ; Data bytes
	dc.b     $FF,$D8,$13,$FF,$05,$10,$00,$01,$FF,$4C,$FB,$00,$0B,$8B,$F7,$FC ; Data bytes
	dc.b     $28,$00,$28,$00,$28,$00,$28,$00,$28,$FA,$FF,$0C,$E8,$00,$28,$01 ; Data bytes
	dc.b     $CC,$7F,$FF,$D9,$A8,$00,$F9,$10,$00,$01,$FF,$F6,$FC,$00,$03,$01 ; Data bytes
	dc.b     $7F,$F7,$F8,$F8,$00,$00,$3F,$FC,$FF,$00,$FE,$FE,$00,$09,$01,$C8 ; Data bytes
	dc.b     $01,$C0,$09,$80,$00,$7F,$F8,$00,$01,$07,$82,$FC,$00,$03,$01,$07 ; Data bytes
	dc.b     $F7,$FB,$F8,$FF,$FA,$00,$0C,$3F,$FF,$FF,$FE,$DC,$7F,$FF,$DD,$FF ; Data bytes
	dc.b     $FF,$7F,$18,$00,$01,$00,$01,$FC,$FF,$02,$FE,$00,$08,$EC,$00,$03 ; Data bytes
	dc.b     $23,$80,$00,$22,$FE,$00,$01,$07,$FF,$01,$F8,$4C,$FB,$00,$0B,$8B ; Data bytes
	dc.b     $D5,$FB,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$FA,$FF,$0C,$D3,$FF ; Data bytes
	dc.b     $93,$F8,$A7,$7F,$FF,$10,$93,$FF,$05,$17,$FF,$01,$FF,$4C,$FB,$00 ; Data bytes
	dc.b     $0B,$8B,$F7,$FC,$28,$00,$28,$00,$28,$00,$28,$00,$28,$FA,$FF,$0C ; Data bytes
	dc.b     $E8,$00,$28,$01,$E7,$7E,$BF,$91,$A8,$00,$F9,$17,$FF,$01,$FF,$F6 ; Data bytes
	dc.b     $FC,$00,$03,$01,$7F,$F7,$F8,$EE,$00,$09,$01,$E0,$00,$80,$01,$80 ; Data bytes
	dc.b     $00,$7F,$FF,$FF,$01,$07,$82,$FC,$00,$00,$00,$08,$00,$00,$03,$89 ; Data bytes
	dc.b     $00,$00,$01,$A9,$00,$00,$01,$E8,$00,$00,$00,$13,$A1,$33,$5B,$CA ; Data bytes
	dc.b     $00,$03,$01,$07,$F7,$FB,$F8,$FF,$FA,$00,$0C,$3F,$FF,$FF,$FE,$F7 ; Data bytes
	dc.b     $7F,$FF,$95,$FF,$FF,$7F,$18,$00,$01,$00,$01,$FC,$FF,$02,$FE,$00 ; Data bytes
	dc.b     $08,$EC,$00,$03,$08,$80,$00,$6A,$FC,$00,$01,$F8,$4C,$FB,$00,$0C ; Data bytes
	dc.b     $8B,$D5,$FB,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$E0,$FC,$00,$0D ; Data bytes
	dc.b     $01,$D3,$FF,$93,$F8,$AF,$FF,$FF,$F2,$93,$FF,$05,$17,$FF,$01,$FF ; Data bytes
	dc.b     $4C,$FB,$00,$0C,$8B,$F7,$FC,$28,$00,$28,$00,$28,$00,$28,$00,$28 ; Data bytes
	dc.b     $E0,$FC,$00,$0D,$01,$E8,$00,$28,$01,$EB,$FF,$FF,$E3,$A8,$00,$F9 ; Data bytes
	dc.b     $17,$FF,$01,$FF,$F6,$FC,$00,$03,$01,$7F,$F7,$F8,$EE,$00,$09,$01 ; Data bytes
	dc.b     $E8,$00,$00,$03,$80,$00,$7F,$FF,$FF,$01,$07,$82,$FC,$00,$03,$01 ; Data bytes
	dc.b     $07,$F7,$FB,$F8,$FF,$FA,$00,$03,$3F,$FF,$FF,$FE,$FE,$FF,$05,$F7 ; Data bytes
	dc.b     $FF,$FF,$7F,$1F,$FF,$01,$00,$01,$FC,$FF,$02,$FE,$00,$08,$F7,$00 ; Data bytes
	dc.b     $00,$1F,$FC,$FF,$00,$FE,$FA,$00,$00,$08,$FC,$00,$01,$F8,$4C,$FB ; Data bytes
	dc.b     $00,$0C,$8B,$D5,$FB,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$E0,$FC ; Data bytes
	dc.b     $00,$0D,$01,$D3,$FF,$93,$F8,$07,$FF,$FF,$F0,$13,$FF,$05,$10,$00 ; Data bytes
	dc.b     $01,$FF,$4C,$FB,$00,$0C,$8B,$F7,$FC,$28,$00,$28,$00,$28,$00,$28 ; Data bytes
	dc.b     $00,$28,$E0,$FC,$00,$0D,$01,$E8,$00,$28,$01,$63,$FF,$FF,$EB,$28 ; Data bytes
	dc.b     $00,$F9,$17,$FF,$01,$FF,$F6,$FC,$00,$03,$01,$7F,$F7,$F8,$EE,$00 ; Data bytes
	dc.b     $09,$01,$60,$00,$00,$0B,$00,$00,$7F,$FF,$FF,$01,$07,$82,$FC,$00 ; Data bytes
	dc.b     $03,$01,$07,$F7,$FB,$F8,$FF,$FA,$00,$0C,$3F,$FF,$FF,$FE,$7F,$FF ; Data bytes
	dc.b     $FF,$F7,$7F,$FF,$7F,$1F,$FF,$01,$00,$01,$FC,$FF,$02,$FE,$00,$08 ; Data bytes
	dc.b     $F7,$00,$00,$1F,$FC,$FF,$00,$FE,$FD,$00,$00,$80,$FE,$00,$00,$80 ; Data bytes
	dc.b     $FD,$00,$01,$F8,$4C,$FB,$00,$0C,$8B,$D5,$FB,$93,$FF,$93,$FF,$93 ; Data bytes
	dc.b     $FF,$93,$FF,$93,$E0,$FC,$00,$0D,$01,$D3,$FF,$93,$F8,$03,$FF,$FF ; Data bytes
	dc.b     $E0,$13,$FF,$05,$10,$00,$01,$FF,$4C,$FB,$00,$0C,$8B,$F7,$FC,$28 ; Data bytes
	dc.b     $00,$28,$00,$28,$00,$28,$00,$28,$E0,$FC,$00,$0D,$01,$E8,$00,$28 ; Data bytes
	dc.b     $01,$E5,$FF,$FF,$F3,$28,$00,$F9,$14,$00,$01,$FF,$F6,$FC,$00,$03 ; Data bytes
	dc.b     $01,$7F,$F7,$F8,$EE,$00,$09,$01,$E4,$00,$00,$13,$00,$00,$7F,$FB ; Data bytes
	dc.b     $FF,$01,$07,$82,$FC,$00,$03,$01,$07,$F7,$FB,$F8,$FF,$FA,$00,$0C ; Data bytes
	dc.b     $3F,$FF,$FF,$FE,$6B,$FF,$FF,$EB,$FF,$FF,$7F,$18,$00,$01,$00,$01 ; Data bytes
	dc.b     $FC,$FF,$02,$FE,$00,$08,$F7,$00,$00,$1F,$FC,$FF,$00,$FE,$FD,$00 ; Data bytes
	dc.b     $03,$10,$00,$00,$04,$FE,$00,$01,$00,$00,$00,$08,$00,$00,$03,$89 ; Data bytes
	dc.b     $00,$00,$01,$AA,$00,$00,$01,$E8,$00,$00,$00,$14,$D1,$43,$FC,$68 ; Data bytes
	dc.b     $03,$FF,$01,$F8,$4C,$FB,$00,$0C,$8B,$D5,$FB,$93,$FF,$93,$FF,$93 ; Data bytes
	dc.b     $FF,$93,$FF,$93,$E1,$FC,$FF,$0D,$E1,$D3,$FF,$93,$FC,$03,$FF,$FF ; Data bytes
	dc.b     $E1,$13,$FF,$05,$10,$00,$01,$FF,$4C,$FB,$00,$0C,$8B,$F7,$FC,$28 ; Data bytes
	dc.b     $00,$28,$00,$28,$00,$28,$00,$28,$E0,$FC,$00,$0D,$01,$E8,$00,$28 ; Data bytes
	dc.b     $00,$E5,$FF,$FF,$D3,$28,$00,$F9,$14,$00,$01,$FF,$F6,$FC,$00,$03 ; Data bytes
	dc.b     $01,$7F,$F7,$F8,$ED,$00,$08,$E4,$00,$00,$13,$00,$00,$7F,$FB,$FF ; Data bytes
	dc.b     $01,$07,$82,$FC,$00,$03,$01,$07,$F7,$FB,$F8,$FF,$00,$01,$FC,$FF ; Data bytes
	dc.b     $01,$E0,$3F,$FE,$FF,$08,$6B,$FF,$FF,$EB,$FF,$FF,$7F,$18,$00,$01 ; Data bytes
	dc.b     $00,$01,$FC,$FF,$02,$FE,$00,$08,$F7,$00,$00,$1E,$FC,$00,$00,$1E ; Data bytes
	dc.b     $FD,$00,$03,$10,$00,$00,$04,$FC,$00,$01,$F8,$4C,$FB,$00,$0C,$8B ; Data bytes
	dc.b     $D5,$FB,$93,$FF,$93,$FF,$93,$FF,$93,$FF,$93,$E1,$FC,$FF,$0D,$E1 ; Data bytes
	dc.b     $D3,$FF,$93,$FC,$00,$FF,$7F,$80,$93,$FF,$05,$10,$00,$01,$FF,$4C ; Data bytes
	dc.b     $FB,$00,$0C,$8B,$F7,$FC,$28,$00,$28,$00,$28,$00,$28,$00,$28,$E0 ; Data bytes
	dc.b     $FC,$00,$0D,$01,$E8,$00,$28,$00,$F3,$FF,$7F,$E6,$28,$00,$F9,$17 ; Data bytes
	dc.b     $FF,$01,$FF,$F6,$FC,$00,$03,$01,$7F,$F7,$F8,$ED,$00,$08,$F2,$00 ; Data bytes
	dc.b     $00,$26,$00,$00,$7F,$F8,$00,$01,$07,$82,$FC,$00,$03,$01,$07,$F7 ; Data bytes
	dc.b     $FB,$F8,$FF,$00,$01,$FC,$FF,$01,$E0,$3F,$FE,$FF,$08,$35,$FF,$7F ; Data bytes
	dc.b     $D7,$FF,$FF,$7F,$18,$00,$01,$00,$01,$FC,$FF,$02,$FE,$00,$08,$F7 ; Data bytes
	dc.b     $00,$00,$1E,$FC,$00,$00,$1E,$FD,$00,$03,$08,$00,$80,$08,$FC,$00 ; Data bytes
	dc.b     $01,$F8,$4C,$FB,$00,$03,$8B,$D5,$FB,$93,$FB,$00,$15,$3F,$93,$E1 ; Data bytes
	dc.b     $C4,$44,$63,$F1,$FC,$61,$D3,$FF,$93,$FE,$00,$7E,$7F,$02,$93,$FF ; Data bytes
	dc.b     $05,$10,$00,$01,$FF,$4C,$FB,$00,$03,$8B,$F7,$FC,$28,$FA,$00,$14 ; Data bytes
	dc.b     $28,$E0,$00,$00,$1C,$A0,$88,$01 ; Data bytes

; ============================================================================
; Data Block: Segment Trailing Zero Padding (0x2700 - 0x2800)
; ============================================================================
	dc.b     $E8,$00,$28,$00,$71,$FE,$7F,$C6,$28,$00,$F9,$14,$00,$01,$FF,$F6 ; Data bytes
	dc.b     $FC,$00,$04,$01,$7F,$F7,$F8,$00,$FB,$FF,$00,$C0,$FD,$00,$02,$1C ; Data bytes
	dc.b     $A0,$88,$FC,$00,$08,$71,$00,$00,$46,$00,$00,$7F,$FB,$FF,$01,$07 ; Data bytes
	dc.b     $82,$FC,$00,$04,$01,$07,$F7,$FB,$FF,$FB,$00,$09,$3F,$FF,$01,$C4 ; Data bytes
	dc.b     $44,$63,$D1,$FC,$60,$3F,$FE,$FF,$08,$B6,$FF,$7F,$B7,$FF,$FF,$7F ; Data bytes
	dc.b     $18,$00,$01,$00,$01,$FC,$FF,$02,$FE,$00,$08,$F7,$00,$06,$1E,$3B ; Data bytes
	dc.b     $BB,$80,$0E,$03,$9E,$FD,$00,$03,$08,$00,$80,$08,$FE,$00,$01,$03 ; Data bytes
	dc.b     $FF,$01,$F8,$4C,$FB,$00,$04,$8B,$D5,$FB,$93,$7F,$FC,$FF,$15,$BF ; Data bytes
	ds.b     16                            ; Zeros padding
	ds.b     16                            ; Zeros padding
	ds.b     16                            ; Zeros padding
	ds.b     16                            ; Zeros padding
	ds.b     16                            ; Zeros padding
	ds.b     16                            ; Zeros padding
	ds.b     16                            ; Zeros padding
	ds.b     16                            ; Zeros padding

; ============================================================================
; Equates for un-emitted internal addresses
; ============================================================================
Str_ScrollingText_Greetings_End EQU     $7143B         ; End boundary of scrolltext greetings parser (past copper list into Sub_GenerateCopperList)
