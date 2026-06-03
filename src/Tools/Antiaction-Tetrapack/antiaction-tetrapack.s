; ============================================================================
; Source  : antiaction-tetrapack.s
; Purpose : Reconstructed Amiga source for AntiAction Tetrapack v2.2 (1988)
; Creator : Reconstructed by Volker Schwaberow <volker@schwaberow.de>
; ============================================================================

ExecBase        EQU     $00000004       ; Exec library base pointer stored at address 4.
CUSTOM          EQU     $dff000         ; Base address of the Amiga Custom Chip registers.
CIAA            EQU     $bfe001         ; Base address of the first CIA chip (CIAA).

; --- Exec library vector offsets ---
Forbid          EQU     -132            ; Disable task switching.
Permit          EQU     -138            ; Enable task switching.
OpenLibrary     EQU     -408            ; Open an Amiga library.
CloseLibrary    EQU     -414            ; Close an opened library.
AllocMem        EQU     -198            ; Allocate a memory block.
FreeMem         EQU     -210            ; Free allocated memory.

; --- DOS library vector offsets ---
Open            EQU     -30             ; Open a file.
Close           EQU     -36             ; Close an open file.
Read            EQU     -42             ; Read bytes from a file.
Write           EQU     -48             ; Write bytes to a file.
Input           EQU     -60             ; Get standard input handle.
Output          EQU     -54             ; Get standard output handle.


; ========================================
	SECTION Hunk_0_Code, CODE
	bsr.b    InitDOSLibrary                ; Initialize the DOS library and IO handles
	bsr.w    ShowMainMenu                  ; Display main menu banner and parse user configurations
	bsr.w    PerformPreCompressionRLE      ; Perform RLE pre-compression over source data
	bsr.w    PerformLZ77CompressionAndSave ; Perform secondary LZ77 compression and save output
	bsr.w    FreeWorkspaceBuffers          ; Free allocated workspace memory buffer
	rts                                    ; Return from subroutine

; ============================================================================
; Function: InitDOSLibrary
; Purpose : Load ExecBase, open "dos.library", and set up StdinHandle.
; Notes   : This is the essential system bootstrap before console interaction.
; ============================================================================
InitDOSLibrary:
	moveq    #$0,d0                        ; Set DOS library version to 0 (any version)
	lea      Str_DosLibrary(pc),a1         ; Load address of "dos.library" string
	movea.l  $4.w,a6                       ; Load Exec library base pointer (ExecBase) from address 4
	jsr      -$228(a6)                     ; Call Exec/DOS vector -$228(a6)
	move.l   d0,Var_DOSBase.l              ; Store DOS library base pointer globally
	movea.l  d0,a6                         ; Load DOS library base for DOS calls
	jsr      -$3c(a6)                      ; Call Exec/DOS vector -$3c(a6)
	move.l   d0,Var_StdinHandle.l          ; Store standard input handle globally
	rts                                    ; Return from subroutine

; ============================================================================
; Function: FreeWorkspaceBuffers
; Purpose : Free allocated workspace memory block from Exec memory pool.
; Notes   : Standard cleanup function, prevents memory leaks.
; ============================================================================
FreeWorkspaceBuffers:
	move.l   Var_WorkspaceSize(pc),d0      ; Load allocated workspace size
	movea.l  Var_WorkspaceBuffer(pc),a1    ; Load allocated workspace buffer pointer
	cmpa.l   #$c00000,a1                   ; Check if the buffer is external FastMem dummy
	beq.b    FreeWorkspaceBuffers_Exit     ; Skip freeing if dummy FastMem buffer is active
	move.l   a6,-(a7)                      ; Preserve DOSBase register a6
	movea.l  $4.w,a6                       ; Load Exec library base pointer (ExecBase) from address 4
	jsr      -$d2(a6)                      ; Call Exec/DOS vector -$d2(a6)
	movea.l  (a7)+,a6                      ; Restore DOSBase register a6
FreeWorkspaceBuffers_Exit:
	rts                                    ; Return from subroutine

; ============================================================================
; Function: PrintString
; Purpose : Print a null-terminated string to standard output.
; Inputs  : a5 = Address of null-terminated ASCII string.
; Notes   : Automatically calculates string length and performs DOS Write().
; ============================================================================
PrintString:
	movem.l  d0-d7/a0-a6,-(a7)             ; Preserve all working registers
	move.l   a5,d2                         ; Load string buffer pointer as DOS write argument
	movea.l  d2,a1                         ; Copy pointer into a1 for scanning
	moveq    #$0,d3                        ; Initialize string length counter to 0
PrintString_CharLoop:
	tst.b    (a1)+                         ; Test current string character and advance pointer
	beq.b    PrintString_Execute           ; Break scanning loop if null-terminator is reached
	addq.l   #$1,d3                        ; Increment string character length counter
	bra.b    PrintString_CharLoop          ; Loop back to scan the next character
PrintString_Execute:
	movea.l  Var_DOSBase(pc),a6            ; Load DOS library base pointer
	move.l   Var_StdinHandle(pc),d1        ; Load output handle (should be stdout)
	jsr      -$30(a6)                      ; Call Exec/DOS vector -$30(a6)
	movem.l  (a7)+,d0-d7/a0-a6             ; Restore all working registers
	rts                                    ; Return from subroutine

; ============================================================================
; Function: ReadKeyboardInput
; Purpose : Reads up to 8 hexadecimal digits from standard input.
; Outputs : d4 = Evaluated 32-bit hexadecimal value.
; Notes   : Used to parse memory address inputs from user.
; ============================================================================
ReadKeyboardInput:
	move.l   Var_StdinHandle(pc),d1        ; Load output handle (should be stdout)
	move.l   #$200,d2                      ; Set buffer offset $200 to receive keyboard input
	moveq    #$7f,d3                       ; Quick load constant value #$7f into register d3
	movea.l  Var_DOSBase(pc),a6            ; Load DOS library base pointer
	jsr      -$2a(a6)                      ; Call Exec/DOS vector -$2a(a6)
	subq.l   #$1,d0                        ; Exclude trailing newline character from read count
	cmpi.l   #$8,d0                        ; Check if address exceeds 8 hex characters (32-bit)
	bgt.b    ReadKeyboardInput_Exit        ; Branch to ReadKeyboardInput_Exit if greater than condition is met
	lea      $200.w,a5                     ; Point a5 at input buffer location $200
	subq.l   #$1,d0                        ; Exclude trailing newline character from read count
	moveq    #$0,d4                        ; Clear / initialize register d4 to 0
ReadKeyboardInput_HexLoop:
	move.b   (a5)+,d1                      ; Fetch next ASCII character from input buffer
	lea      Var_HexTable(pc),a4           ; Load address of hexadecimal digits ASCII table
	moveq    #$1f,d6                       ; Quick load constant value #$1f into register d6
ReadKeyboardInput_FindChar:
	cmp.b    (a4)+,d1                      ; Compare character with table digit and advance
	dbeq     d6,ReadKeyboardInput_FindChar ; Search until character matches table or table ends
	not.w    d6                            ; Invert loop index to get digit index value
	beq.b    ReadKeyboardInput_Exit        ; Branch to ReadKeyboardInput_Exit if equal / zero condition is met
	andi.w   #$f,d6                        ; Mask index to retrieve 4-bit nibble value
	lsl.l    #$4,d4                        ; Shift 32-bit accumulator left by one hex digit (4 bits)
	or.w     d6,d4                         ; Merge nibble value into 32-bit accumulator register
	dbra     d0,ReadKeyboardInput_HexLoop  ; Decrement counter and loop to d0,ReadKeyboardInput_HexLoop until finished
	move.l   d4,d0                         ; Return parsed 32-bit hex address in d0
	rts                                    ; Return from subroutine
ReadKeyboardInput_Exit:
	moveq    #$0,d0                        ; Set DOS library version to 0 (any version)
	rts                                    ; Return from subroutine

; ============================================================================
; Function: ReadChar
; Purpose : Wait and read a single character from console standard input.
; Outputs : d1 = Read ASCII character, d0 = Status code.
; Notes   : Checks for special CLI escape '*' command.
; ============================================================================
ReadChar:
	move.l   #$100,d2                      ; Set buffer offset $100 to receive character
	move.l   Var_StdinHandle(pc),d1        ; Load output handle (should be stdout)
	moveq    #$30,d3                       ; Quick load constant value #$30 into register d3
	movea.l  Var_DOSBase(pc),a6            ; Load DOS library base pointer
	jsr      -$2a(a6)                      ; Call Exec/DOS vector -$2a(a6)
	move.b   $100.w,d1                     ; Read inputted character byte from buffer
	cmpi.b   #$a,d1                        ; Check if character is newline (ASCII newline)
	beq.b    ReadChar_Empty                ; Branch to ReadChar_Empty if equal / zero condition is met
	subq.l   #$1,d0                        ; Calculate actual length excluding newline
	movea.l  d0,a0                         ; Copy length into index pointer register a0
	clr.b    $100(a0)                      ; Null-terminate input buffer
	move.b   d1,d0                         ; Copy character to return status d0
	cmpi.b   #$2a,d0                       ; Check if character is CLI escape "*" command
	bne.b    ReadChar_Done                 ; Branch to ReadChar_Done if not equal / non-zero condition is met
	move.l   #$101,d1                      ; Load buffer pointer offset $101
	moveq    #$0,d2                        ; Clear / initialize register d2 to 0
	moveq    #$0,d3                        ; Initialize string length counter to 0
	move.l   a6,-(a7)                      ; Preserve DOSBase register a6
	movea.l  Var_DOSBase(pc),a6            ; Load DOS library base pointer
	jsr      -$de(a6)                      ; Call Exec/DOS vector -$de(a6)
	movea.l  (a7)+,a6                      ; Restore DOSBase register a6
	moveq    #$ff,d0                       ; Initialize register d0 with error code -1 ($ff)
ReadChar_Done:
	tst.b    d0                            ; Test input status code
	rts                                    ; Return from subroutine
ReadChar_Empty:
	moveq    #$0,d2                        ; Clear / initialize register d2 to 0
	rts                                    ; Return to caller

; ============================================================================
; Function: PrintHexWordOrByte
; Purpose : Alternate hex formatting entry point. (dead code fragment)
; Notes   : Sets loop limit to print 2 characters (1 byte).
; ============================================================================
PrintHexWordOrByte:
	movem.l  d0-d7/a0-a6,-(a7)             ; Preserve all registers on the stack
	moveq    #$1,d4                        ; Set loop limit to print 2 characters (1 byte)
	bra.s    PrintHexLong_Start            ; Branch into hex formatting routine

; ============================================================================
; Function: PrintHexLong
; Purpose : Convert a 32-bit value in d0 into hex ASCII and print it.
; Inputs  : d0 = 32-bit value to print.
; Notes   : Sets loop limit to print 8 hex characters.
; ============================================================================
PrintHexLong:
	movem.l  d0-d7/a0-a6,-(a7)             ; Preserve all working registers on the stack
	moveq    #$7,d4                        ; Set character count limit to 8 digits
PrintHexLong_Start:
	moveq    #$c,d7                        ; Set shift limit to 12 bits (first digit)
	lea      Str_AllocBufferHex(pc),a5     ; Load pointer to temporary hex output buffer
	bsr.w    PrintString                   ; Print hex buffer to console
	move.l   d0,d6                         ; Copy 32-bit value to d6 for digit extraction
PrintHexLong_CharLoop:
	move.l   d6,d5                         ; Copy working long to d5 for current nibble
	swap     d5                            ; Swap words to shift upper word to low word
	lsr.w    d7,d5                         ; Shift right by shift limit to isolate nibble
	andi.w   #$f,d5                        ; Mask out all bits except lower 4 bits (nibble)
	lsl.l    #$4,d6                        ; Shift accumulator long left by 4 bits for next digit
	bsr.b    PrintHexDigit                 ; Print single hexadecimal digit
	dbra     d4,PrintHexLong_CharLoop      ; Decrement counter and loop to d4,PrintHexLong_CharLoop until finished
	movem.l  (a7)+,d0-d7/a0-a6             ; Restore all working registers
	rts                                    ; Return from subroutine
PrintHexDigit:
	movem.l  d0-d3/a0-a1/a6,-(a7)          ; Preserve working registers on stack
	lea      Var_HexTable(pc),a0           ; Load address of base-16 digit conversion table
	lea      Var_HexCharBuffer(pc),a1      ; Load address of temporary hex output character
	move.b   (a0,d5.w),(a1)                ; Get hex digit ASCII character from table
	movea.l  Var_DOSBase(pc),a6            ; Load DOS library base pointer
	move.l   Var_StdinHandle(pc),d1        ; Load output handle (should be stdout)
	moveq    #$1,d3                        ; Set write length to 1 byte
	move.l   a1,d2                         ; Load pointer to the temporary hex character
	jsr      -$30(a6)                      ; Call Exec/DOS vector -$30(a6)
	movem.l  (a7)+,d0-d3/a0-a1/a6          ; Restore working registers from stack
	rts                                    ; Return from subroutine

; ============================================================================
; Function: ShowMainMenu
; Purpose : Interactive shell banner, memory configuration, and parameter prompts.
; Notes   : Drives CLI options, memory expansion checks, trackdisk, etc.
; ============================================================================
ShowMainMenu:
	lea      Str_Header_Tetrapack(pc),a5   ; Load main screen welcome banner string
	bsr.w    PrintString                   ; Display the welcome banner to the screen
	bsr.w    ReadChar                      ; Wait and read user confirmation key
	cmpi.b   #$59,$100.w                   ; Check if user pressed "Y" (ASCII $59)
	beq.b    MainMenu_CheckFastMem         ; Branch to MainMenu_CheckFastMem if equal / zero condition is met
	cmpi.b   #$79,$100.w                   ; Check if user pressed "y" (ASCII $79)
MainMenu_CheckFastMem:
	seq.b    Var_MegacrunchFlag.l          ; Set Megacrunch flag if user pressed Y/y
	bne.w    MainMenu_GetAddressRange      ; Jump to FastMem evaluation if Megacrunch is enabled
	move.b   $c00000.l,d0                  ; Test expansion memory / pseudo-FastMem byte
	not.b    d0                            ; Invert byte to test read/write status
	move.b   d0,$c00000.l                  ; Write inverted test byte to expansion memory
	cmp.b    $c00000.l,d0                  ; Verify if expansion memory is writeable
	beq.b    MainMenu_CheckChipMem         ; Branch to MainMenu_CheckChipMem if equal / zero condition is met
	lea      Str_NoMegacrunch_1MB(pc),a5   ; Load pointer to 1MB RAM prompt string
	bsr.w    PrintString                   ; Display the welcome banner to the screen
	moveq    #$1,d0                        ; Quick load constant value #$1 into register d0
	bra.b    MainMenu_CheckFastMem         ; Unconditional branch to MainMenu_CheckFastMem
MainMenu_CheckChipMem:
	not.b    $c00000.l                     ; Restore original memory value
	move.l   $4.w,d0                       ; Read ExecBase pointer from memory address 4
	cmpi.l   #$80000,d0                    ; Verify if total memory is at least 512KB
	blt.w    MainMenu_GetAddressRange      ; Skip Megacrunch checks if memory is below 512KB
	lea      Str_TurnFastmemOff(pc),a5     ; Load pointer to warning about turning FastMem off
	bsr.w    PrintString                   ; Display the welcome banner to the screen
	bsr.w    ReadChar                      ; Wait and read user confirmation key
	cmpi.b   #$59,$100.w                   ; Check if user pressed "Y" (ASCII $59)
	beq.b    MainMenu_PromptDisableFastMem ; Branch to MainMenu_PromptDisableFastMem if equal / zero condition is met
	cmpi.b   #$79,$100.w                   ; Check if user pressed "y" (ASCII $79)
MainMenu_PromptDisableFastMem:
	bne.w    MainMenu_SmallCrunchWarning   ; Jump to FastMem evaluation if Megacrunch is enabled
	movea.l  $4.w,a6                       ; Load Exec library base pointer (ExecBase) from address 4
	bsr.w    RebootAmigaHardware           ; Call local subroutine RebootAmigaHardware
	movea.l  $4.w,a0                       ; Load Exec library base pointer (ExecBase) from address 4
	lea      $fc0100.l,a5                  ; Point a5 at start of Kickstart 1.x ROM area ($fc0100)
MainMenu_SearchRebootAddress:
	move.w   #$41f8,d0                     ; Load ROM search signature code (lea check)
MainMenu_RebootLoop:
	cmp.w    (a5)+,d0                      ; Scan ROM memory for signature match and advance
	bne.b    MainMenu_RebootLoop           ; Branch to MainMenu_RebootLoop if not equal / non-zero condition is met
	move.w   (a5),d0                       ; Check if next word matches ROM reboot instruction code
	bne.b    MainMenu_SearchRebootAddress  ; Branch to MainMenu_SearchRebootAddress if not equal / non-zero condition is met
	lea      $400.w,a6                     ; Set a6 to base memory offset $400
	adda.w   $10(a0),a6                    ; Add offset from ExecBase structure
	lea      RebootSupervisorHandler(pc),a0 ; Load address of supervisor mode reboot handler
	move.l   a0,$80.w                      ; Register handler address at Trap 0 vector ($80)
	trap     #$0                           ; Call Trap 0 to enter Supervisor Mode
RebootSupervisorHandler:
	lea      $40000.l,a7                   ; Set initial Supervisor stack pointer to $40000
	lea      $c00000.l,a0                  ; Point a0 at base of expansion memory buffer ($c00000)
	lea      $dc0000.l,a1                  ; Point a1 at end of expansion memory range ($dc0000)
	suba.l   a2,a2                         ; Clear register a2 to clear chip memory
	suba.l   a3,a3                         ; Clear register a3 to clear chip memory
	moveq    #$ff,d6                       ; Initialize register d6 with error code -1 ($ff)
	moveq    #$0,d7                        ; Clear / initialize register d7 to 0
	jmp      -$2(a5)                       ; Hard jump to ROM reset/reboot vector entry point

; ============================================================================
; Function: RebootAmigaHardware
; Purpose : Completely take over OCS custom chips, disable interrupts, and hard-reset.
; Notes   : Hard hardware reset used to flush system memory for megacrunches.
; ============================================================================
RebootAmigaHardware:
	move.b   #$3,$bfe201.l                 ; Configure CIA-A Port A direction (power LED/drive)
	move.b   #$2,$bfe001.l                 ; Set CIA-A Port A data (dim power LED)
	lea      $dff000.l,a4                  ; Load Custom Chip register base address ($dff000)
	move.w   #$7fff,d0                     ; Prepare hardware mask to disable all DMA/interrupts
	move.w   d0,$9a(a4)                    ; Disable all interrupts (INTENA)
	move.w   d0,$9c(a4)                    ; Clear all interrupt requests (INTREQ)
	move.w   d0,$96(a4)                    ; Disable all DMA channels (DMACON)
	move.w   #$200,$100(a4)                ; Configure base playfield control (BPLCON0)
	move.w   #$0,$110(a4)                  ; Disable custom sprites and modulos (BPLCON1)
	move.w   #$444,$180(a4)                ; Set screen color register 0 to gray (COLOR00)
	suba.l   a4,a4                         ; Clear register a4
	rts                                    ; Return from subroutine
MainMenu_SmallCrunchWarning:
	lea      Str_FastmemActiveWarning(pc),a5 ; Load warning string for active FastMem
	bsr.w    PrintString                   ; Display the welcome banner to the screen
	moveq    #$1,d0                        ; Quick load constant value #$1 into register d0
	bra.w    MainMenu_CheckFastMem         ; Unconditional branch to MainMenu_CheckFastMem
MainMenu_GetAddressRange:
	lea      Str_StartAddr(pc),a5          ; Load pointer to start address prompt string
	bsr.w    PrintString                   ; Display the welcome banner to the screen
	bsr.w    ReadKeyboardInput             ; Read hexadecimal address input from keyboard
	beq.w    ShowMainMenu                  ; Branch to ShowMainMenu if equal / zero condition is met
	move.l   d0,Var_SourceStartAddr.l      ; Store parsed start address globally
	move.l   d0,Var_SourceBuffer_Minus80.l ; Store adjusted payload start pointer globally
	lea      Str_EndAddr(pc),a5            ; Load pointer to end address prompt string
	bsr.w    PrintString                   ; Display the welcome banner to the screen
	bsr.w    ReadKeyboardInput             ; Read hexadecimal address input from keyboard
	beq.w    ShowMainMenu                  ; Branch to ShowMainMenu if equal / zero condition is met
	move.l   d0,Var_SourceEndAddr.l        ; Store parsed end address globally
	addi.l   #$108,d0                      ; Add workspace overhead to source end address
	sub.l    Var_SourceStartAddr(pc),d0    ; Subtract start address to compute payload size
	tst.b    Var_MegacrunchFlag.l          ; Test if Megacrunch mode is active
	beq.b    MainMenu_AllocWorkspace       ; Branch to MainMenu_AllocWorkspace if equal / zero condition is met
	lea      Str_AllocBuffer(pc),a5        ; Load pointer to buffer allocation prompt
	bsr.w    PrintString                   ; Display the welcome banner to the screen
	move.l   #$c00000,d0                   ; Use default expansion memory base address ($c00000)
	bra.b    MainMenu_CheckAlloc           ; Unconditional branch to MainMenu_CheckAlloc
MainMenu_AllocWorkspace:
	move.l   #$10000,d1                    ; Configure memory allocation attributes (MEMF_CHIP)
	move.l   a6,-(a7)                      ; Preserve DOSBase register a6
	movea.l  $4.w,a6                       ; Load Exec library base pointer (ExecBase) from address 4
	move.l   d0,Var_WorkspaceSize.l        ; Store calculated workspace size globally
	jsr      -$c6(a6)                      ; Call Exec/DOS vector -$c6(a6)
	movea.l  (a7)+,a6                      ; Restore DOSBase register a6
MainMenu_CheckAlloc:
	tst.l    d0                            ; Check if memory allocation was successful
	bne.b    MainMenu_DisplayAddresses     ; Branch to MainMenu_DisplayAddresses if not equal / non-zero condition is met
	lea      Str_MemAllocError(pc),a5      ; Load pointer to memory allocation error message
	bsr.w    PrintString                   ; Display the welcome banner to the screen
	moveq    #$1,d0                        ; Quick load constant value #$1 into register d0
	bra.w    MainMenu_CheckFastMem         ; Unconditional branch to MainMenu_CheckFastMem
MainMenu_DisplayAddresses:
	move.l   d0,Var_WorkspaceBuffer.l      ; Store allocated workspace buffer address globally
	move.l   d0,d7                         ; Copy workspace address to d7
	lea      Str_FastMemAllocPrompt(pc),a5 ; Load pointer to FastMem allocation address prompt
	bsr.w    PrintString                   ; Display the welcome banner to the screen
	move.l   d7,d0                         ; Copy address to d0 for printing
	bsr.w    PrintHexLong                  ; Print 32-bit value in d0 as hexadecimal text
	lea      Str_ChipMemAllocPrompt(pc),a5 ; Load pointer to ChipMem allocation address prompt
	bsr.w    PrintString                   ; Display the welcome banner to the screen
	move.l   Var_SourceEndAddr(pc),d0      ; Load payload end address
	sub.l    Var_SourceStartAddr(pc),d0    ; Subtract start address to compute payload size
	add.l    Var_WorkspaceBuffer(pc),d0    ; Add workspace buffer base to compute end pointer
	addi.l   #$100,d0                      ; Add standard decrunch safety padding offset
	bsr.w    PrintHexLong                  ; Print 32-bit value in d0 as hexadecimal text
	lea      Str_DecrunchError(pc),a5      ; Load pointer to decompressor error message string
	bsr.w    PrintString                   ; Display the welcome banner to the screen
	lea      Str_AddressTable(pc),a5       ; Load pointer to address layout table header
	bsr.w    PrintString                   ; Display the welcome banner to the screen
	movea.l  Var_SourceStartAddr(pc),a0    ; Load payload start address
	suba.l   Var_SourceStartAddr(pc),a0    ; Subtract to zero index offset
	adda.l   Var_WorkspaceBuffer(pc),a0    ; Calculate actual start pointer in workspace
	movea.l  Var_SourceEndAddr(pc),a1      ; Load payload end address
	suba.l   Var_SourceStartAddr(pc),a1    ; Subtract start to calculate length offset
	adda.l   Var_WorkspaceBuffer(pc),a1    ; Calculate actual end pointer in workspace
	adda.l   #$100,a1                      ; Add standard decrunch safety padding limit
MainMenu_ClearWorkspaceLoop:
	clr.b    (a0)+                         ; Zero-out current workspace byte and advance
	cmpa.l   a1,a0                         ; Check if clearing pointer reached buffer limit
	blt.b    MainMenu_ClearWorkspaceLoop   ; Skip compressing run if length is under 4 bytes
MainMenu_GetFileLength:
	lea      Str_SuccessLen(pc),a5         ; Load pointer to file size prompt string
	bsr.w    PrintString                   ; Display the welcome banner to the screen
	bsr.w    ReadKeyboardInput             ; Read hexadecimal address input from keyboard
	move.l   d0,Var_FileLength.l           ; Store keyboard parsed file length globally
	beq.b    MainMenu_GetFileLength        ; Branch to MainMenu_GetFileLength if equal / zero condition is met
	cmpi.l   #$10,d0                       ; Check if file size is at least 16 bytes
	blt.b    MainMenu_GetFileLength        ; Skip compressing run if length is under 4 bytes
	cmpi.l   #$8000,d0                     ; Check if file size exceeds maximum load limit ($8000)
	bgt.b    MainMenu_GetFileLength        ; Branch to MainMenu_GetFileLength if greater than condition is met
	bsr.w    CalculateDecompressionShift   ; Call local subroutine CalculateDecompressionShift
	lea      Str_Description(pc),a5        ; Load pointer to file description header
	bsr.w    PrintString                   ; Display the welcome banner to the screen
MainMenu_PromptFlashRegister:
	lea      Str_DescriptionTable(pc),a5   ; Load pointer to compression type selection table string
	bsr.w    PrintString                   ; Display the welcome banner to the screen
	bsr.w    ReadChar                      ; Wait and read user confirmation key
	beq.w    MainMenu_AbortExit            ; Branch to MainMenu_AbortExit if equal / zero condition is met
	bmi.b    MainMenu_PromptFlashRegister  ; Branch to MainMenu_PromptFlashRegister if negative sign bit is set
	move.b   $100.l,d0                     ; Read console keyboard character code byte
	cmpi.b   #$72,d0                       ; Check if user selected "r" (RLE compression only)
	seq.b    Var_IsEncrypted.l             ; Set RLE-only compression flag if selected
	cmpi.b   #$74,d0                       ; Check if user selected "t" (Pro-Decruncher mode)
	seq.b    Var_ProDecruncherFlag.l       ; Set Pro-Decruncher mode flag if selected
MainMenu_CheckFlashRegisterInput:
	tst.w    Var_ProDecruncherFlag.l       ; Test if Pro-Decruncher flag is active
	bne.b    MainMenu_PromptStackAddress   ; Branch to MainMenu_PromptStackAddress if not equal / non-zero condition is met
	lea      Str_PromptFlashRegister(pc),a5 ; Load pointer to custom flash register prompt
	bsr.w    PrintString                   ; Display the welcome banner to the screen
	bsr.w    ReadChar                      ; Wait and read user confirmation key
	beq.w    MainMenu_PromptFlashRegister  ; Branch to MainMenu_PromptFlashRegister if equal / zero condition is met
	bmi.b    MainMenu_CheckFlashRegisterInput ; Branch to MainMenu_CheckFlashRegisterInput if negative sign bit is set
	move.l   #$100,d1                      ; Configure memory block allocation flags (MEMF_CHIP)
	move.l   #$3ed,d2                      ; Set maximum hunk size / type parameters
	jsr      -$1e(a6)                      ; Call Exec/DOS vector -$1e(a6)
	tst.l    d0                            ; Check if memory allocation was successful
	beq.b    MainMenu_PromptFlashRegister  ; Branch to MainMenu_PromptFlashRegister if equal / zero condition is met
	move.l   d0,Var_FileHandle.l           ; Store opened file handle globally
MainMenu_PromptStackAddress:
	lea      Str_DescriptionTable_Hex(pc),a5 ; Load pointer to hexadecimal compression options string
	bsr.w    PrintString                   ; Display the welcome banner to the screen
	bsr.w    ReadKeyboardInput             ; Read hexadecimal address input from keyboard
	beq.b    MainMenu_PromptFlashRegister  ; Branch to MainMenu_PromptFlashRegister if equal / zero condition is met
	cmp.l    Var_SourceStartAddr(pc),d0    ; Check if stack address is below source start address
	blt.b    MainMenu_InvalidStackError    ; Skip compressing run if length is under 4 bytes
	cmp.l    Var_SourceEndAddr(pc),d0      ; Verify if payload fits within source memory limits
	blt.b    MainMenu_CalculateOffsets     ; Skip compressing run if length is under 4 bytes
MainMenu_InvalidStackError:
	lea      Str_StackError(pc),a5         ; Load pointer to stack boundary warning error string
	bsr.w    PrintString                   ; Display the welcome banner to the screen
	bra.b    MainMenu_PromptStackAddress   ; Unconditional branch to MainMenu_PromptStackAddress
MainMenu_CalculateOffsets:
	sub.l    Var_SourceStartAddr(pc),d0    ; Subtract start address to compute payload size
	add.l    Var_WorkspaceBuffer(pc),d0    ; Add workspace buffer base to compute end pointer
	addi.l   #$100,d0                      ; Add standard decrunch safety padding offset
	move.l   d0,Var_FilePayloadBuffer.l    ; Store payload buffer address globally
	tst.w    Var_ProDecruncherFlag.l       ; Test if Pro-Decruncher flag is active
	bne.w    MainMenu_PromptTrackdisk      ; Jump to FastMem evaluation if Megacrunch is enabled
	move.l   d0,d2                         ; Copy payload buffer address to d2 for DOS Read()
	move.l   Var_FileHandle(pc),d1         ; Load open input file handle
	movea.l  Var_DOSBase(pc),a6            ; Load DOS library base pointer
	move.l   Var_SourceEndAddr(pc),d3      ; Load source payload end address
	sub.l    Var_SourceStartAddr(pc),d3    ; Calculate net size of source payload
	add.l    Var_WorkspaceBuffer(pc),d3    ; Add workspace base to get workspace end pointer
	addi.l   #$101,d3                      ; Add standard safety padding buffer headroom
	sub.l    d2,d3                         ; Subtract start to calculate net payload size
	tst.b    Var_IsEncrypted.l             ; Check if RLE-only compression is selected
	beq.b    MainMenu_ReadBuffer           ; Branch to MainMenu_ReadBuffer if equal / zero condition is met
	bsr.w    ParseExecutableHunks                 ; Call local subroutine ParseExecutableHunks
	cmpi.l   #$ffffffff,d0                 ; Check if file read returned error code -1
	seq.b    Var_EncryptionKey.l           ; Set encryption / compression state key flag
	clr.b    Var_IsEncrypted.l             ; Clear temporary RLE encryption flag
	bra.b    MainMenu_DecompressCheck      ; Unconditional branch to MainMenu_DecompressCheck
MainMenu_ReadBuffer:
	jsr      -$2a(a6)                      ; Call Exec/DOS vector -$2a(a6)
MainMenu_DecompressCheck:
	add.l    Var_FilePayloadBuffer(pc),d0  ; Add payload base address to compute payload end
	sub.l    Var_WorkspaceBuffer(pc),d0    ; Subtract workspace buffer base to find offset
	add.l    Var_SourceStartAddr(pc),d0    ; Add source base to reconstruct absolute address
	subi.l   #$100,d0                      ; Subtract safety padding offset
	move.l   d0,Var_FilePayloadEnd.l       ; Store calculated payload end pointer globally
	move.l   Var_FileHandle(pc),d1         ; Load open input file handle
	jsr      -$24(a6)                      ; Call Exec/DOS vector -$24(a6)
	tst.b    Var_EncryptionKey.l           ; Test if payload decryption key is valid
	beq.b    MainMenu_CheckFileLength      ; Branch to MainMenu_CheckFileLength if equal / zero condition is met
	lea      Str_DecompressError(pc),a5    ; Load pointer to decompression read error
	bsr.w    PrintString                   ; Display the welcome banner to the screen
	bra.w    MainMenu_PromptFlashRegister  ; Unconditional branch to MainMenu_PromptFlashRegister
MainMenu_CheckFileLength:
	move.l   Var_FilePayloadEnd(pc),d0     ; Load payload end address
	cmp.l    Var_SourceEndAddr(pc),d0      ; Verify if payload fits within source memory limits
	ble.b    MainMenu_SuccessExit          ; Keep current run length if it is within limits
	lea      Str_Success(pc),a5            ; Load pointer to successful compression status banner
	bsr.w    PrintString                   ; Display the welcome banner to the screen
MainMenu_SuccessExit:
	lea      Str_SuccessAddress(pc),a5     ; Load pointer to compression summary address header
	bsr.w    PrintString                   ; Display the welcome banner to the screen
	move.l   Var_FilePayloadEnd(pc),d0     ; Load payload end address
	bsr.w    PrintHexLong                  ; Print 32-bit value in d0 as hexadecimal text
	bra.w    MainMenu_PromptFlashRegister  ; Unconditional branch to MainMenu_PromptFlashRegister
MainMenu_AbortExit:
	rts                                    ; Return from subroutine

; ============================================================================
; Function: CalculateDecompressionShift
; Purpose : Calculate bitplane decompression shifts and set decruncher variables.
; ============================================================================
CalculateDecompressionShift:
	subq.w   #$1,d0                        ; Adjust loop index for shift table
	moveq    #$11,d1                       ; Quick load constant value #$11 into register d1
CalculateDecompressionShift_Loop:
	subq.l   #$1,d1                        ; Adjust bit shift count limit
	asl.w    #$1,d0                        ; Multiply shift index by 2
	bcc.b    CalculateDecompressionShift_Loop ; Branch to CalculateDecompressionShift_Loop if carry clear (greater or equal)
	move.w   d1,Table_LZ77_PrefixCodesClass3.l ; Write shift count prefix for class 3
	move.b   d1,Var_Decruncher_Adkcon.l    ; Patch standard decruncher ADKCON shift
	move.b   d1,Var_RLE_EscapeChar_End.l   ; Patch RLE escape end indicator
	cmpi.w   #$a,d1                        ; Compare shift limit with class 2 maximum
	bge.b    DecompressionShift_Less10     ; Branch to DecompressionShift_Less10 if greater than or equal condition is met
	move.w   d1,Table_LZ77_PrefixCodesClass0_2.l ; Write prefix shift count for class 0-2
DecompressionShift_Less10:
	cmpi.w   #$9,d1                        ; Compare shift limit with class 2 lower bounds
	bgt.b    DecompressionShift_Less9      ; Branch to DecompressionShift_Less9 if greater than condition is met
	move.w   d1,Table_LZ77_BitLengthsClass3.l ; Write bit lengths class 3 parameter
	move.b   d1,Var_Decruncher_Intena.l    ; Patch standard decruncher INTENA shift
	move.b   d1,Var_RLE_Histogram_End.l    ; Patch RLE histogram search limits
	move.w   Table_LZ77_PrefixCodesClass0_2.l,d7 ; Load class 0-2 shift count
	sub.w    d1,d7                         ; Calculate relative shift difference
	bne.b    DecompressionShift_Less9      ; Branch to DecompressionShift_Less9 if not equal / non-zero condition is met
	move.w   #$4e71,Var_Decruncher_IntenaNop.l ; Patch INTENA NOP code ($4e71)
	move.w   #$4e71,Var_RLE_EscapeChar.l   ; Patch RLE escape NOP code ($4e71)
DecompressionShift_Less9:
	cmpi.w   #$8,d1                        ; Compare shift count with class 0 limit
	bge.b    DecompressionShift_Exit       ; Branch to DecompressionShift_Exit if greater than or equal condition is met
	move.w   d1,Table_LZ77_BitLengthsClass0_2.l ; Write bit lengths class 0-2 parameter
	move.b   d1,Var_Decruncher_Dmacon.l    ; Patch standard decruncher DMACON shift
	move.b   d1,Var_RLE_Histogram.l        ; Patch RLE histogram start offset
DecompressionShift_Exit:
	rts                                    ; Return from subroutine
MainMenu_PromptTrackdisk:
	move.l   #$200,d0                      ; Configure standard sector size (512 bytes)
	moveq    #$2,d1                        ; Quick load constant value #$2 into register d1
	movea.l  $4.w,a6                       ; Load Exec library base pointer (ExecBase) from address 4
	jsr      -$c6(a6)                      ; Call Exec/DOS vector -$c6(a6)
	move.l   d0,Var_IOBuffer.l             ; Store sector buffer pointer globally
	lea      Str_DecompressSuccess(pc),a5  ; Load pointer to decompression success string
	bsr.w    PrintString                   ; Display the welcome banner to the screen
	bsr.w    ReadKeyboardInput             ; Read hexadecimal address input from keyboard
	move.l   d0,Var_TrackdiskCmd.l         ; Store sector read command globally
	lea      Str_OriginalLength(pc),a5     ; Load pointer to original file length string
	bsr.w    PrintString                   ; Display the welcome banner to the screen
	bsr.w    ReadKeyboardInput             ; Read hexadecimal address input from keyboard
	move.l   d0,Var_TrackdiskTrack.l       ; Store track number globally
	bsr.w    MainMenu_ReadTrackdisk        ; Call local subroutine MainMenu_ReadTrackdisk
	move.l   #$200,d0                      ; Configure standard sector size (512 bytes)
	movea.l  Var_IOBuffer(pc),a1           ; Load sector IO buffer address pointer
	movea.l  $4.w,a6                       ; Load Exec library base pointer (ExecBase) from address 4
	jsr      -$d2(a6)                      ; Call Exec/DOS vector -$d2(a6)
	bra.w    MainMenu_PromptFlashRegister  ; Unconditional branch to MainMenu_PromptFlashRegister
MainMenu_ReadTrackdisk:
	movea.l  $4.l,a6                       ; Load ExecBase library pointer
	moveq    #$ff,d0                       ; Initialize register d0 with error code -1 ($ff)
	jsr      -$14a(a6)                     ; Call Exec/DOS vector -$14a(a6)
	tst.b    d0                            ; Check if device status returned error flag
	bmi.w    MainMenu_Trackdisk_Error                  ; Branch to MainMenu_Trackdisk_Error if negative sign bit is set
	move.b   d0,Var_TrackdiskError.l       ; Store trackdisk error status globally
	suba.l   a1,a1                         ; Clear address register a1
	jsr      -$126(a6)                     ; Call Exec/DOS vector -$126(a6)
	lea      Var_TrackdiskMsg(pc),a1       ; Load address of message port structure
	move.l   d0,$10(a1)                    ; Configure sector number in IORequest structure
	move.l   #Var_TrackdiskIO,$a(a1)       ; Write trackdisk device signature to IORequest
	clr.b    $9(a1)                        ; Clear flag byte in IORequest
	move.b   #$4,$8(a1)                    ; Set IO command to CMD_CLEAR
	move.b   #$0,$e(a1)                    ; Set command priority to zero
	move.b   Var_TrackdiskError(pc),$f(a1) ; Write trackdisk error byte to structure
	jsr      -$162(a6)                     ; Call Exec/DOS vector -$162(a6)
	lea      Var_TrackdiskIORequest(pc),a1 ; Load pointer to trackdisk IORequest block
	move.b   #$5,$8(a1)                    ; Set IO command to CMD_UPDATE
	move.l   #$38,$12(a1)                  ; Configure drive type identifier
	move.l   #Var_TrackdiskMsg,$e(a1)      ; Set message port address in IORequest
	movea.l  $4.l,a6                       ; Load ExecBase library pointer
	lea      Var_TrackdiskPort(pc),a0      ; Load trackdisk message port address
	lea      Var_TrackdiskIORequest(pc),a1 ; Load pointer to trackdisk IORequest block
	moveq    #$0,d0                        ; Set DOS library version to 0 (any version)
	clr.l    d1                            ; Clear register d1
	jsr      -$1bc(a6)                     ; Call Exec/DOS vector -$1bc(a6)
	tst.l    d0                            ; Check if memory allocation was successful
	bne.w    MainMenu_Trackdisk_Error                  ; Jump to FastMem evaluation if Megacrunch is enabled
	moveq    #$5,d2                        ; Quick load constant value #$5 into register d2
	bsr.w    DoDeviceIO                    ; Perform direct trackdisk device I/O operation
	movea.l  Var_FilePayloadBuffer(pc),a5  ; Load payload buffer pointer
	move.l   Var_TrackdiskCmd(pc),d6       ; Load sectors count
	move.l   Var_TrackdiskTrack(pc),d7     ; Load target track offset
MainMenu_ReadTrackdisk_SectorLoop:
	move.l   d6,d0                         ; Copy sector number to d0
	move.l   #$200,d1                      ; Configure standard sector size (512 bytes)
	moveq    #$2,d2                        ; Quick load constant value #$2 into register d2
	move.l   Var_IOBuffer(pc),d3           ; Load temporary sector buffer pointer
	bsr.w    DoDeviceIO                    ; Perform direct trackdisk device I/O operation
	bne.b    MainMenu_Trackdisk_Error                  ; Branch to MainMenu_Trackdisk_Error if not equal / non-zero condition is met
	moveq    #$7f,d0                       ; Quick load constant value #$7f into register d0
	movea.l  Var_IOBuffer(pc),a0           ; Load source sector buffer pointer
MainMenu_TrackdiskCopyLoop:
	move.l   (a0)+,(a5)+                   ; Copy sector longword to payload buffer and advance
	dbra     d0,MainMenu_TrackdiskCopyLoop ; Decrement counter and loop to d0,MainMenu_TrackdiskCopyLoop until finished
	addi.l   #$200,d6                      ; Advance track address offset by 512 bytes
	subi.l   #$200,d7                      ; Decrement remaining bytes count by 512
	bpl.b    MainMenu_ReadTrackdisk_SectorLoop                  ; Branch to MainMenu_ReadTrackdisk_SectorLoop if positive sign bit is clear
	move.w   #$4,d2                        ; Configure trackdisk command (CMD_CLEAR)
	bsr.w    DoDeviceIO                    ; Perform direct trackdisk device I/O operation
	bsr.w    DoDeviceIO_Cmd9                  ; Call local subroutine DoDeviceIO_Cmd9
	lea      Var_TrackdiskIORequest(pc),a1 ; Load pointer to trackdisk IORequest block
	jsr      -$1c2(a6)                     ; Call Exec/DOS vector -$1c2(a6)
	movea.l  $4.l,a6                       ; Load ExecBase library pointer
	lea      Var_TrackdiskMsg(pc),a1       ; Load address of message port structure
	jsr      -$168(a6)                     ; Call Exec/DOS vector -$168(a6)
	clr.l    d0                            ; Clear register d0
	move.b   Var_TrackdiskError(pc),d1     ; Load final device error byte code
	jsr      -$150(a6)                     ; Call Exec/DOS vector -$150(a6)
	rts                                    ; Return from subroutine
MainMenu_Trackdisk_Error:
	moveq    #$ff,d0                       ; Initialize register d0 with error code -1 ($ff)
	rts                                    ; Return from subroutine
DoDeviceIO_Cmd9:
	clr.l    d1                            ; Clear register d1
	move.w   #$9,d2                        ; Configure trackdisk command (CMD_MOTOR off)

; ============================================================================
; Function: DoDeviceIO
; Purpose : Perform direct trackdisk device I/O operation via Exec.
; Inputs  : a1 = IORequest block pointer.
; ============================================================================
DoDeviceIO:
	lea      Var_TrackdiskIORequest(pc),a1 ; Load pointer to trackdisk IOStdReq structure
	move.l   d0,$2c(a1)                    ; Set standard IO_OFFSET (byte offset on track/disk)
	move.l   d1,$24(a1)                    ; Set standard IO_LENGTH (number of bytes to read)
	move.w   d2,$1c(a1)                    ; Set standard IO_COMMAND (read/write/update command)
	move.l   d3,$28(a1)                    ; Set standard IO_DATA (destination buffer address)
	movea.l  $4.l,a6                       ; Load ExecBase library pointer from location 4
	jsr      -$1c8(a6)                     ; Call Exec DoIO() to execute trackdisk command synchronously
	lea      Var_TrackdiskIORequest(pc),a1 ; Reload pointer to trackdisk IOStdReq structure
	move.b   $1f(a1),d0                    ; Retrieve standard IO_ERROR returned by the device
	rts                                    ; Return to caller

; ============================================================================
; Function: ClearBssBuffer
; Purpose : Fills memory workspace buffer with zeros.
; ============================================================================
ClearBssBuffer:
	movea.l  Var_SourceStartAddr(pc),a5    ; Load source payload start pointer
	suba.l   Var_SourceStartAddr(pc),a5    ; Subtract to index from zero base
	adda.l   Var_WorkspaceBuffer(pc),a5    ; Point a5 at actual payload start in workspace
	adda.l   #$100,a5                      ; Add decrunch safety padding buffer offset
	movea.l  Var_SourceEndAddr(pc),a4      ; Load source payload end pointer
	suba.l   Var_SourceStartAddr(pc),a4    ; Subtract start address to calculate size offset
	adda.l   Var_WorkspaceBuffer(pc),a4    ; Point a4 at actual payload end in workspace
	adda.l   #$100,a4                      ; Add decrunch safety padding buffer limit
	moveq    #$0,d7                        ; Clear / initialize register d7 to 0
	moveq    #$0,d6                        ; Clear / initialize register d6 to 0
	lea      $100.w,a0                     ; Point a0 at base of local frequency table at $100
	movea.l  a0,a1                         ; Copy table base pointer to clear register a1
	moveq    #$7f,d0                       ; Quick load constant value #$7f into register d0
ClearBssBuffer_Loop:
	clr.l    (a1)+                         ; Clear table frequency entry longword and advance
	dbra     d0,ClearBssBuffer_Loop        ; Decrement counter and loop to d0,ClearBssBuffer_Loop until finished
ClearBssBuffer_HistogramScanLoop:
	moveq    #$0,d0                        ; Set DOS library version to 0 (any version)
	move.b   (a5)+,d0                      ; Fetch next byte character from source payload
	asl.w    #$1,d0                        ; Shift byte value left by 1 (convert byte value to word index)
	addq.w   #$1,(a0,d0.w)                 ; Increment occurrences count for this byte value
	bne.b    ClearBssBuffer_HistogramScanNext                  ; Branch to ClearBssBuffer_HistogramScanNext if not equal / non-zero condition is met
	subq.w   #$1,(a0,d0.w)                 ; Clamp frequency count at maximum value limit $ffff
ClearBssBuffer_HistogramScanNext:
	cmpa.l   a4,a5                         ; Check if entire source payload was scanned
	blt.b    ClearBssBuffer_HistogramScanLoop                  ; Skip compressing run if length is under 4 bytes
	moveq    #$0,d0                        ; Set DOS library version to 0 (any version)
	move.w   #$ffff,d1                     ; Set initial minimum frequency limit to $ffff
	moveq    #$0,d3                        ; Initialize string length counter to 0
ClearBssBuffer_FindMinFreqLoop:
	move.w   d0,d2                         ; Copy byte value to d2
	asl.w    #$1,d2                        ; Convert byte value to word offset
	moveq    #$0,d5                        ; Clear / initialize register d5 to 0
	move.w   (a0,d2.w),d5                  ; Retrieve occurrence frequency count of this character
	cmp.l    d5,d1                         ; Compare current character occurrences with current minimum
	ble.b    ClearBssBuffer_FindMinFreqNext                  ; Keep current run length if it is within limits
	move.l   d0,d3                         ; Update best RLE marker candidate character value
	move.w   d5,d1                         ; Update minimal frequency count limit
ClearBssBuffer_FindMinFreqNext:
	addq.b   #$1,d0                        ; Step index to next byte character value (0-255)
	bne.b    ClearBssBuffer_FindMinFreqLoop                  ; Branch to ClearBssBuffer_FindMinFreqLoop if not equal / non-zero condition is met
	move.b   d3,Var_RleMarkerByte.l        ; Store calculated optimal RLE marker byte globally
	move.w   d1,Var_SourceSize.l           ; Store total unique RLE characters globally
	rts                                    ; Return from subroutine

; ============================================================================
; Function: PerformPreCompressionRLE
; Purpose : Runs a fast run-length encoding (RLE) pre-pass over input file payload.
; Notes   : Optimizes uniform runs of identical bytes before LZ77 compression.
; ============================================================================
PerformPreCompressionRLE:
	lea      Str_RleHeader(pc),a5          ; Load pointer to RLE compression start message string
	bsr.w    PrintString                   ; Display the welcome banner to the screen
	bsr.w    ClearBssBuffer                ; Clear BSS workspace buffer with zero bytes
	bsr.w    PerformRLE_Body               ; Call local subroutine PerformRLE_Body
	bsr.w    CompressLZ77                  ; Call local subroutine CompressLZ77
	move.l   a2,Var_SourceBufferEnd.l      ; Store payload end pointer globally
	rts                                    ; Return from subroutine
PerformRLE_Body:
	movea.l  Var_SourceStartAddr(pc),a0    ; Load payload start address
	suba.l   Var_SourceStartAddr(pc),a0    ; Subtract to index from zero base
	adda.l   Var_WorkspaceBuffer(pc),a0    ; Point a0 at actual payload start in workspace buffer
	movea.l  a0,a1                         ; Point a1 at start of destination RLE output workspace buffer
	adda.l   #$100,a0                      ; Add standard safety decompress buffer padding offset
	adda.l   #$80,a1                       ; Advance workspace target RLE buffer pointer by $80
	movea.l  Var_SourceEndAddr(pc),a2      ; Load source end address pointer
	suba.l   Var_SourceStartAddr(pc),a2    ; Subtract start address to calculate offset
	adda.l   Var_WorkspaceBuffer(pc),a2    ; Point a2 at actual payload end in workspace buffer
	adda.l   #$100,a2                      ; Add standard decompress buffer padding limit
	move.b   -$1(a2),(a2)                  ; Copy last RLE compressed payload byte
	addq.b   #$1,(a2)                      ; Increment ending payload marker value
	moveq    #$0,d7                        ; Clear / initialize register d7 to 0
	move.b   Var_RleMarkerByte(pc),d7      ; Load optimal RLE escape marker character byte
	moveq    #$0,d0                        ; Set DOS library version to 0 (any version)
	moveq    #$0,d1                        ; Clear / initialize register d1 to 0
PerformRLE_ByteLoop:
	move.b   (a0)+,d0                      ; Read next byte of source data
	bsr.w    CountRleRepeatBytes           ; Scan ahead to count consecutive identical bytes
	cmpi.l   #$4,d1                        ; Check if run contains at least 4 identical bytes
	blt.b    PerformRLE_CheckMarker        ; Skip compressing run if length is under 4 bytes
	cmpi.l   #$102,d1                      ; Check if run exceeds maximum length limit of 258
	ble.b    PerformRLE_WriteLiteral       ; Keep current run length if it is within limits
	move.l   #$102,d1                      ; Cap run length at maximum limit of 258 bytes
PerformRLE_WriteLiteral:
	subq.w   #$3,d1                        ; Encode run length offset (-3 offset for RLE encoding)
	move.b   d7,(a1)+                      ; Write RLE escape marker character to buffer
	move.b   d1,(a1)+                      ; Write encoded run length to RLE buffer
	move.b   d0,(a1)+                      ; Write identical run character to RLE buffer
	addq.l   #$2,a0                        ; Advance source pointer beyond RLE marker and count
	adda.l   d1,a0                         ; Advance source pointer by remaining encoded run length
	bra.b    PerformRLE_CheckEnd           ; Unconditional branch to PerformRLE_CheckEnd
PerformRLE_CheckMarker:
	cmp.b    d7,d0                         ; Check if literal byte character matches RLE escape marker
	bne.b    PerformRLE_WriteLiteralSingle ; Branch to PerformRLE_WriteLiteralSingle if not equal / non-zero condition is met
	move.b   d7,(a1)+                      ; Write RLE escape marker character to buffer
	clr.b    (a1)+                         ; Write zero byte run length (escape marker indicator)
	bra.b    PerformRLE_CheckEnd           ; Unconditional branch to PerformRLE_CheckEnd
PerformRLE_WriteLiteralSingle:
	move.b   d0,(a1)+                      ; Write identical run character to RLE buffer
PerformRLE_CheckEnd:
	cmpa.l   a2,a0                         ; Check if entire source payload buffer was compressed
	blt.b    PerformRLE_ByteLoop           ; Skip compressing run if length is under 4 bytes
	move.l   a1,Var_RlePayloadEnd.l        ; Store RLE pre-compressed payload end pointer globally
	move.l   Var_SourceStartAddr(pc),Var_Decruncher_StartAddr.l ; Store source payload start address in standard decompressor stub
	move.l   Var_SourceEndAddr(pc),Var_Decruncher_EndAddr.l ; Store source payload end address in standard decompressor stub
	move.l   Var_SourceStartAddr(pc),Var_DecruncherPro_StartAddr.l ; Store source payload start address in Pro-decompressor stub
	move.l   Var_SourceEndAddr(pc),Var_DecruncherPro_EndAddr.l ; Store source payload end address in Pro-decompressor stub
	move.b   Var_RleMarkerByte(pc),Var_Decruncher_RleMarker.l ; Store RLE marker byte in standard decompressor stub
	move.b   Var_RleMarkerByte(pc),Var_DecruncherPro_RleMarker.l ; Store RLE marker byte in Pro-decompressor stub
	subi.l   #$80,Var_SourceBuffer_Minus80.l ; Adjust start pointer to account for safety headroom
	rts                                    ; Return from subroutine
CountRleRepeatBytes:
	movea.l  a0,a3                         ; Copy start pointer to a3 for scanning
	move.w   #$102,d5                      ; Set scan limits count to 258 bytes
CountRleRepeatBytes_Loop:
	cmp.b    (a3)+,d0                      ; Compare next byte character to run value and advance
	bne.b    CountRleRepeatBytes_Exit                  ; Branch to CountRleRepeatBytes_Exit if not equal / non-zero condition is met
	dbra     d5,CountRleRepeatBytes_Loop   ; Decrement counter and loop to d5,CountRleRepeatBytes_Loop until finished
CountRleRepeatBytes_Exit:
	suba.l   a0,a3                         ; Calculate number of identical characters found
	move.l   a3,d1                         ; Return consecutive run length in d1
	rts                                    ; Return from subroutine

; ============================================================================
; Function: PerformLZ77CompressionAndSave
; Purpose : Drives the secondary LZ77 compression and saves final executable.
; ============================================================================
PerformLZ77CompressionAndSave:
	bsr.w    AskStackAddress               ; Prompt user for custom stack (A7) address layout
Save_PromptFilename:
	lea      Str_SaveHeader(pc),a5         ; Load pointer to save file status header string
	bsr.w    PrintString                   ; Display the welcome banner to the screen
	bsr.w    ReadKeyboardInput             ; Read hexadecimal address input from keyboard
	beq.b    Save_PromptFilename           ; Branch to Save_PromptFilename if equal / zero condition is met
	move.l   d0,Str_AskFilename.l          ; Patch standard decruncher filename pointer
	move.l   d0,Str_AskFilenamePro.l       ; Patch Pro-decompresser filename pointer
	lea      Str_FlashRegisterPrompt(pc),a5 ; Load pointer to flash register prompt string
	bsr.w    PrintString                   ; Display the welcome banner to the screen
	bsr.w    ReadKeyboardInput             ; Read hexadecimal address input from keyboard
	cmpi.w   #$1f,d0                       ; Check if user choice index is within custom chip registers bounds
	bgt.b    Save_PromptFilename           ; Branch to Save_PromptFilename if greater than condition is met
	asl.w    #$1,d0                        ; Multiply shift index by 2
	add.b    d0,Var_Decruncher_FlashReg.l  ; Patch standard decruncher flash register target
	add.b    d0,Var_DecruncherPro_FlashReg.l ; Patch Pro-decompresser flash register target
	tst.b    Var_MegacrunchFlag.l          ; Test if Megacrunch mode is active
	bne.b    Save_AskProDecruncher         ; Branch to Save_AskProDecruncher if not equal / non-zero condition is met
	lea      Str_ProDecruncherPrompt(pc),a5 ; Load pointer to Pro-Decruncher prompt string
	bsr.w    PrintString                   ; Display the welcome banner to the screen
	bsr.w    ReadChar                      ; Wait and read user confirmation key
	cmpi.b   #$79,$100.w                   ; Check if user pressed "y" (ASCII $79)
	beq.b    Save_AskProDecruncher         ; Branch to Save_AskProDecruncher if equal / zero condition is met
	cmpi.b   #$59,$100.w                   ; Check if user pressed "Y" (ASCII $59)
	bne.w    Save_PrepareDecompressorStub  ; Jump to FastMem evaluation if Megacrunch is enabled
Save_AskProDecruncher:
	st.b     Var_MegacrunchFlag.l          ; Enable Megacrunch expansion memory bypass flag globally
	lea      Str_Dmacon(pc),a5             ; Load pointer to DMACON register name string
	bsr.w    PrintString                   ; Display the welcome banner to the screen
	bsr.w    ReadKeyboardInput             ; Read hexadecimal address input from keyboard
	move.w   d0,Var_DecruncherPro_Adkcon.l ; Patch Pro-decompresser DMACON register target
	lea      Str_Intena(pc),a5             ; Load pointer to INTENA register name string
	bsr.w    PrintString                   ; Display the welcome banner to the screen
	bsr.w    ReadKeyboardInput             ; Read hexadecimal address input from keyboard
	move.w   d0,Var_DecruncherPro_AdkconNop.l ; Patch Pro-decompresser INTENA register target
	lea      Str_Adkcon(pc),a5             ; Load pointer to ADKCON register name string
	bsr.w    PrintString                   ; Display the welcome banner to the screen
	bsr.w    ReadKeyboardInput             ; Read hexadecimal address input from keyboard
	move.w   d0,Var_DecruncherPro_IntenaNop.l ; Patch Pro-decompresser ADKCON register target
	lea      Str_LocateStack(pc),a5        ; Load pointer to stack relocation prompt string
	bsr.w    PrintString                   ; Display the welcome banner to the screen
	bsr.w    ReadKeyboardInput             ; Read hexadecimal address input from keyboard
	move.w   d0,Str_WriteSuccessPro.l      ; Patch Pro-decompresser output success string
	lea      Str_StackA7(pc),a5            ; Load pointer to custom stack configuration prompt
	bsr.w    PrintString                   ; Display the welcome banner to the screen
	bsr.w    ReadKeyboardInput             ; Read hexadecimal address input from keyboard
	beq.w    Save_PromptFilename           ; Branch to Save_PromptFilename if equal / zero condition is met
	move.l   d0,Var_DecruncherPro_JmpAddr.l ; Patch Pro-decompresser execution jump vector
	lea      Str_StackAlloc(pc),a5         ; Load pointer to stack memory allocation prompt
	bsr.w    PrintString                   ; Display the welcome banner to the screen
	bsr.w    ReadKeyboardInput             ; Read hexadecimal address input from keyboard
	move.l   d0,Var_DecruncherPro_StackA7.l ; Patch Pro-decompresser custom stack pointer
Save_PrepareDecompressorStub:
	move.l   Var_SourceBufferEnd(pc),d3    ; Load source payload end address pointer
	move.l   Var_SourceBuffer_Minus80(pc),d2 ; Load adjusted payload start address pointer
	addi.l   #$100,d2                      ; Add safety buffer headroom limit
	move.l   Var_RlePayloadEnd(pc),d5      ; Load RLE payload end pointer
	sub.l    d2,d5                         ; Subtract to calculate payload memory layout size
	addi.l   #$80,d5                       ; Add safety buffer overhead
	move.l   Var_SourceEndAddr(pc),d6      ; Load source payload end address
	sub.l    d5,d6                         ; Subtract lookahead size to determine absolute stack layout pointer
	move.l   d6,Var_Decruncher_StackA7.l   ; Patch standard decruncher custom stack pointer
	move.l   d6,Var_DecruncherPro_Intena.l ; Patch Pro-decompresser INTENA target
	subi.l   #$100,d2                      ; Re-adjust workspace base pointer
	sub.l    d2,d3                         ; Subtract start to calculate net payload size
	move.l   d3,Var_Decruncher_JmpAddr.l   ; Patch standard decruncher execution jump vector
	move.l   d3,Var_DecruncherPro_Dmacon.l ; Patch Pro-decompresser DMACON target
	asr.l    #$2,d3                        ; Convert size bytes count to longword count
	tst.b    Var_MegacrunchFlag.l          ; Test if Megacrunch mode is active
	beq.b    Save_SmallCrunchStub          ; Branch to Save_SmallCrunchStub if equal / zero condition is met
	addi.l   #$59,d3                       ; Add standard decruncher header overhead shift
	bra.b    Save_InitLZ77                 ; Unconditional branch to Save_InitLZ77
Save_SmallCrunchStub:
	addi.l   #$40,d3                       ; Add standard decruncher safety code shift
Save_InitLZ77:
	move.l   d3,Var_Decruncher_PayloadLen.l ; Patch standard decruncher payload length field
	move.l   d3,Var_Decruncher_OrigLen.l   ; Patch standard decruncher original length field
	move.l   d3,Var_DecruncherPro_PayloadLen.l ; Patch Pro-decompresser payload length field
	move.l   d3,Var_DecruncherPro_OrigLen.l ; Patch Pro-decompresser original length field
	lea      Str_SaveHeaderAgain(pc),a5    ; Load pointer to "Save again" prompt header string
	bsr.w    PrintString                   ; Display the welcome banner to the screen
	bsr.w    ReadChar                      ; Wait and read user confirmation key
	beq.w    Save_PromptSaveAgain          ; Branch to Save_PromptSaveAgain if equal / zero condition is met
	bmi.w    Save_PrepareDecompressorStub  ; Branch to Save_PrepareDecompressorStub if negative sign bit is set
	move.l   #$100,d1                      ; Configure memory block allocation flags (MEMF_CHIP)
	move.l   #$3ee,d2                      ; Set hunk relocation type parameter ($3ee)
	movea.l  Var_DOSBase(pc),a6            ; Load DOS library base pointer
	jsr      -$1e(a6)                      ; Call Exec/DOS vector -$1e(a6)
	move.l   d0,Var_FilePayloadSize.l      ; Store final file payload size globally
	beq.w    Save_PromptFilename           ; Branch to Save_PromptFilename if equal / zero condition is met
	move.l   d0,d1                         ; Copy size count to d1 for DOS Write()
	tst.b    Var_MegacrunchFlag.l          ; Test if Megacrunch mode is active
	beq.b    Save_StandardHeaderMessage    ; Branch to Save_StandardHeaderMessage if equal / zero condition is met
	move.l   #Str_AskSaveAgain,d2          ; Load save again prompt string pointer
	move.l   #$184,d3                      ; Set write length to 388 bytes
	jsr      -$30(a6)                      ; Call Exec/DOS vector -$30(a6)
	bra.b    Save_WritePayload             ; Unconditional branch to Save_WritePayload
Save_StandardHeaderMessage:
	move.l   #Template_Decruncher_Header,d2 ; Load standard decruncher template header pointer
	move.l   #$120,d3                      ; Set standard decruncher header length to 288 bytes
	jsr      -$30(a6)                      ; Call Exec/DOS vector -$30(a6)
Save_WritePayload:
	move.l   Var_FilePayloadSize(pc),d1    ; Load final compressed payload size in bytes
	move.l   Var_SourceBufferEnd(pc),d3    ; Load source payload end address pointer
	move.l   Var_SourceBuffer_Minus80(pc),d2 ; Load adjusted payload start address pointer
	sub.l    d2,d3                         ; Subtract start to calculate net payload size
	jsr      -$30(a6)                      ; Call Exec/DOS vector -$30(a6)
	move.l   Var_FilePayloadSize(pc),d1    ; Load final compressed payload size in bytes
	move.l   #Str_WriteSuccess,d2          ; Load success message string pointer
	moveq    #$4,d3                        ; Quick load constant value #$4 into register d3
	jsr      -$30(a6)                      ; Call Exec/DOS vector -$30(a6)
	move.l   Var_FilePayloadSize(pc),d1    ; Load final compressed payload size in bytes
	jsr      -$24(a6)                      ; Call Exec/DOS vector -$24(a6)
Save_PromptSaveAgain:
	lea      Str_SaveAgain(pc),a5          ; Load pointer to "Save again? (y/n)" prompt
	bsr.w    PrintString                   ; Display the welcome banner to the screen
	bsr.w    ReadChar                      ; Wait and read user confirmation key
	move.b   $100.l,d0                     ; Read console keyboard character code byte
	cmpi.b   #$79,d0                       ; Check if keyboard input choice is "y"
Save_AskSaveAgain_CheckY:
	beq.w    Save_PromptFilename           ; Branch to Save_PromptFilename if equal / zero condition is met
	cmpi.b   #$59,d0                       ; Check if keyboard input choice is "Y"
	beq.b    Save_AskSaveAgain_CheckY                  ; Branch to Save_AskSaveAgain_CheckY if equal / zero condition is met
	lea      Str_DecompressPrompt(pc),a5   ; Load pointer to "Run test? (y/n)" prompt
	bsr.w    PrintString                   ; Display the welcome banner to the screen
	bsr.w    ReadChar                      ; Wait and read user confirmation key
	move.b   $100.l,d0                     ; Read console keyboard character code byte
	cmpi.b   #$79,d0                       ; Check if keyboard input choice is "y"
	beq.b    Save_DecompressTest_Start                  ; Branch to Save_DecompressTest_Start if equal / zero condition is met
	cmpi.b   #$59,d0                       ; Check if keyboard input choice is "Y"
	bne.b    Save_DecompressTest_Exit                  ; Branch to Save_DecompressTest_Exit if not equal / non-zero condition is met
Save_DecompressTest_Start:
	move.l   #$80000,d0                    ; Configure delay loop count to 524,288 iterations
Save_DecompressTest_DelayLoop:
	subq.l   #$1,d0                        ; Decrement delay loop counter
	bne.b    Save_DecompressTest_DelayLoop                  ; Branch to Save_DecompressTest_DelayLoop if not equal / non-zero condition is met
	tst.b    Var_MegacrunchFlag.l          ; Test if Megacrunch mode is active
	beq.b    Save_DecompressTest_StandardStub                  ; Branch to Save_DecompressTest_StandardStub if equal / zero condition is met
	move.l   #$164,d6                      ; Set Pro-Decruncher template stub size (356 bytes)
	lea      Template_DecruncherPro_Start(pc),a2 ; Load address of Pro-Decruncher template start
	bra.b    Save_DecompressTest_Setup                  ; Unconditional branch to Save_DecompressTest_Setup
Save_DecompressTest_StandardStub:
	move.l   #$100,d6                      ; Set standard decruncher template stub size (256 bytes)
	lea      Template_Decruncher_Start(pc),a2 ; Load address of standard decruncher template start
Save_DecompressTest_Setup:
	movea.l  Var_WorkspaceBuffer(pc),a0    ; Load Var_WorkspaceBuffer memory buffer pointer
	movea.l  a0,a1                         ; Point a1 at workspace buffer start to build stub
	movea.l  a0,a4                         ; Copy workspace base pointer to a4 for jump target
	adda.l   Var_WorkspaceSize(pc),a1      ; Point a1 at end of allocated workspace buffer
	movea.l  a1,a3                         ; Copy workspace end pointer to a3
	suba.l   d6,a3                         ; Subtract stub size to find shift boundary
Save_DecompressTest_ShiftPayloadLoop:
	move.b   -(a3),-(a1)                   ; Shift crunched payload byte upwards to make room for stub
	cmpa.l   a0,a3                         ; Check if entire payload data has been shifted
	bgt.b    Save_DecompressTest_ShiftPayloadLoop                  ; Branch to Save_DecompressTest_ShiftPayloadLoop if greater than condition is met
	subq.w   #$1,d6                        ; Adjust stub copy loop counter for dbra (count - 1)
Save_DecompressTest_CopyStubLoop:
	move.b   (a2)+,(a0)+                   ; Copy decruncher stub template byte to workspace start
	dbra     d6,Save_DecompressTest_CopyStubLoop               ; Decrement counter and loop to d6,Save_DecompressTest_CopyStubLoop until finished
	jmp      (a4)                          ; Jump to workspace buffer to run in-memory decrunch test
Save_DecompressTest_Exit:
	rts                                    ; Return from subroutine

; ============================================================================
; Function: AskStackAddress
; Purpose : Prompt user for custom stack (A7) address layout.
; ============================================================================
AskStackAddress:
	lea      Str_PromptStackAddress(pc),a5 ; Load pointer to stack configuration prompt string
	bsr.w    PrintString                   ; Display the welcome banner to the screen
	move.l   Var_SourceBufferEnd(pc),d0    ; Load crunched payload end address pointer
	sub.l    Var_SourceBuffer_Minus80(pc),d0 ; Subtract start to calculate buffer size
	bsr.w    PrintHexLong                  ; Print 32-bit value in d0 as hexadecimal text
	move.l   Var_SourceBuffer_Minus80(pc),d0 ; Load adjusted payload start address
	sub.l    Var_WorkspaceBuffer(pc),d0    ; Subtract workspace buffer base to find offset
	add.l    Var_SourceStartAddr(pc),d0    ; Add source base to reconstruct absolute address
	bsr.w    PrintHexLong                  ; Print 32-bit value in d0 as hexadecimal text
	move.l   Var_SourceBufferEnd(pc),d0    ; Load crunched payload end address pointer
	sub.l    Var_WorkspaceBuffer(pc),d0    ; Subtract workspace buffer base to find offset
	add.l    Var_SourceStartAddr(pc),d0    ; Add source base to reconstruct absolute address
	bsr.w    PrintHexLong                  ; Print 32-bit value in d0 as hexadecimal text
	lea      Str_StackAddressInvalid(pc),a5 ; Load pointer to invalid stack layout error message
	bsr.w    PrintString                   ; Display the welcome banner to the screen
	move.l   Var_SourceEndAddr(pc),d0      ; Load source payload end address
	sub.l    Var_SourceStartAddr(pc),d0    ; Subtract start address to compute payload size
	bsr.w    PrintHexLong                  ; Print 32-bit value in d0 as hexadecimal text
	move.l   Var_SourceStartAddr(pc),d0    ; Load source start address
	bsr.w    PrintHexLong                  ; Print 32-bit value in d0 as hexadecimal text
	move.l   Var_SourceEndAddr(pc),d0      ; Load source payload end address
	bsr.w    PrintHexLong                  ; Print 32-bit value in d0 as hexadecimal text
	lea      Str_AllocatingStack(pc),a5    ; Load pointer to stack auto-allocation message
	bsr.w    PrintString                   ; Display the welcome banner to the screen
	move.l   Var_SourceBufferEnd(pc),d0    ; Load crunched payload end address pointer
	sub.l    Var_SourceBuffer_Minus80(pc),d0 ; Subtract start to calculate buffer size
	move.l   Var_SourceEndAddr(pc),d1      ; Load source payload end address pointer
	sub.l    Var_SourceStartAddr(pc),d1    ; Subtract start pointer to calculate size
	exg.l    d0,d1                         ; Exchange size registers to swap values
	sub.l    d1,d0                         ; Calculate safety stack offset boundaries
	bsr.w    PrintHexLong                  ; Print 32-bit value in d0 as hexadecimal text
	lea      Str_StackAllocSuccess(pc),a5  ; Load pointer to stack allocation success message
	bsr.w    PrintString                   ; Display the welcome banner to the screen
	bsr.w    ReadChar                      ; Wait and read user confirmation key
	rts                                    ; Return from subroutine

; ============================================================================
; Function: CompressLZ77
; Purpose : Compresses the RLE-encoded payload using Red Sector-compatible LZ77.
; ============================================================================
CompressLZ77:
	move.w   #$28,$dff09a.l                ; Disable custom chip interrupt controller
	move.w   #$180,$dff096.l               ; Configure Custom Chip playfield DMA control
	movea.l  Var_SourceStartAddr(pc),a0    ; Load payload start address pointer
	suba.l   Var_SourceStartAddr(pc),a0    ; Subtract start pointer to calculate base
	adda.l   Var_WorkspaceBuffer(pc),a0    ; Point a0 at actual payload start in workspace
	movea.l  a0,a2                         ; Copy payload base address to a2
	adda.l   #$80,a0                       ; Advance payload read pointer by $80
	movea.l  Var_RlePayloadEnd(pc),a1      ; Load RLE pre-compressed payload end pointer
	move.l   a2,Var_SourceBuffer_Minus80.l ; Store adjusted buffer pointer globally
	moveq    #$1,d2                        ; Quick load constant value #$1 into register d2
	clr.w    d1                            ; Initialize literal run count to zero
LZ77_CompressLoop:
	bsr.w    LZ77_FindMatchAtA0                  ; Call local subroutine LZ77_FindMatchAtA0
	tst.b    d0                            ; Check if match search was successful
	beq.b    LZ77_CompressLoop_Next                  ; Branch to LZ77_CompressLoop_Next if equal / zero condition is met
	addq.w   #$1,d1                        ; Increment literal characters run count
	cmpi.w   #$88,d1                       ; Check if literal run length reaches 136 bytes maximum limit
	bne.b    LZ77_CompressLoop_Next                  ; Branch to LZ77_CompressLoop_Next if not equal / non-zero condition is met
	bsr.w    LZ77_FlushLiterals                  ; Call local subroutine LZ77_FlushLiterals
LZ77_CompressLoop_Next:
	cmpa.l   a0,a1                         ; Check if entire payload data has been crunched
	bgt.b    LZ77_CompressLoop                  ; Branch to LZ77_CompressLoop if greater than condition is met
	bsr.w    LZ77_FlushLiterals                  ; Call local subroutine LZ77_FlushLiterals
	bsr.w    LZ77_FlushBitBuffer                  ; Call local subroutine LZ77_FlushBitBuffer
	movea.l  Var_SourceBuffer_Minus80(pc),a0 ; Load payload base pointer
	movea.l  Var_RlePayloadEnd(pc),a1      ; Load RLE pre-compressed payload end pointer
	move.l   a1,d2                         ; Load pointer to the temporary hex character
	sub.l    a0,d2                         ; Subtract base pointer to calculate payload size
	subi.l   #$80,d2                       ; Subtract padding offset
	move.l   d2,(a2)+                      ; Write compressed payload size to file header
	move.w   #$8180,$dff096.l              ; Restore custom chip DMA controllers
	move.w   #$8028,$dff09a.l              ; Restore custom chip interrupt vectors
	rts                                    ; Return from subroutine
LZ77_FindMatchAtA0:
	movea.l  a0,a3                         ; Point a3 at lookahead buffer range start
	adda.l   Var_FileLength(pc),a3         ; Advance by lookahead limit (max match length)
	cmpa.l   a1,a3                         ; Check if lookahead exceeds payload end pointer
	ble.b    LZ77_FindMatch_Start                  ; Keep current run length if it is within limits
	movea.l  a1,a3                         ; Clamp lookahead at payload end boundary
LZ77_FindMatch_Start:
	moveq    #$1,d5                        ; Quick load constant value #$1 into register d5
	movea.l  a0,a5                         ; Initialize sliding window search pointer at a0
	addq.w   #$1,a5                        ; Step sliding window search pointer by 1 byte
LZ77_FindMatch_NextChar:
	move.b   (a0),d3                       ; Load first lookahead byte character to d3
	move.b   $1(a0),d4                     ; Load second lookahead byte character to d4
LZ77_FindMatch_ScanLoop:
	cmp.b    (a5)+,d3                      ; Scan sliding window for first character match and advance
	bne.b    LZ77_FindMatch_CheckEnd                  ; Branch to LZ77_FindMatch_CheckEnd if not equal / non-zero condition is met
	cmp.b    (a5),d4                       ; Check if second character matches lookahead byte
	beq.b    LZ77_FindMatch_LengthLoop                  ; Branch to LZ77_FindMatch_LengthLoop if equal / zero condition is met
LZ77_FindMatch_CheckEnd:
	cmpa.l   a5,a3                         ; Check if sliding window search pointer reached lookahead limit
	bgt.b    LZ77_FindMatch_ScanLoop                  ; Branch to LZ77_FindMatch_ScanLoop if greater than condition is met
	bra.b    LZ77_FindMatch_Done                  ; Unconditional branch to LZ77_FindMatch_Done
LZ77_FindMatch_LengthLoop:
	subq.w   #$1,a5                        ; Realign search pointer after scan
	movea.l  a0,a4                         ; Initialize lookahead pointer in a4
	move.l   a6,-(a7)                      ; Preserve DOSBase register a6
	movea.l  a5,a6                         ; Copy search pointer to a6
	adda.l   #$107,a6                      ; Advance search pointer to maximum match limit (263 bytes)
	cmpa.l   a1,a6                         ; Check if search pointer exceeds payload end
	blt.b    LZ77_FindMatch_CompareLoop                  ; Skip compressing run if length is under 4 bytes
	movea.l  a1,a6                         ; Clamp search limit at payload end boundary
LZ77_FindMatch_CompareLoop:
	move.b   (a4)+,d3                      ; Fetch next lookahead byte character
	cmp.b    (a5)+,d3                      ; Scan sliding window for first character match and advance
	bne.b    LZ77_FindMatch_CompareDone                  ; Branch to LZ77_FindMatch_CompareDone if not equal / non-zero condition is met
	cmpa.l   a5,a6                         ; Check if maximum search limits are reached
	bgt.b    LZ77_FindMatch_CompareLoop                  ; Branch to LZ77_FindMatch_CompareLoop if greater than condition is met
LZ77_FindMatch_CompareDone:
	movea.l  (a7)+,a6                      ; Restore DOSBase register a6
	move.l   a4,d3                         ; Copy lookahead pointer to d3
	sub.l    a0,d3                         ; Calculate actual matched run length
	subq.l   #$1,d3                        ; Adjust match count offset
	cmp.l    d3,d5                         ; Compare matched run length with current best
	bge.w    LZ77_FindMatch_ScanNext                  ; Branch to LZ77_FindMatch_ScanNext if greater than or equal condition is met
	move.l   a5,d4                         ; Copy search pointer to d4
	sub.l    a0,d4                         ; Calculate match offset
	sub.l    d3,d4                         ; Calculate backward distance index
	subq.w   #$1,d4                        ; Adjust backward distance offset by 1
	cmpi.l   #$4,d3                        ; Check if matched run is at least 4 bytes
	ble.b    LZ77_FindMatch_ShortOffset                  ; Keep current run length if it is within limits
	moveq    #$6,d6                        ; Quick load constant value #$6 into register d6
	cmpi.l   #$105,d3                      ; Check if match size is maximum lookahead limit
	blt.b    LZ77_FindMatch_OffsetLimitD3                  ; Skip compressing run if length is under 4 bytes
	move.w   #$104,d3                      ; Clamp match size at 260 bytes
LZ77_FindMatch_OffsetLimitD3:
	bra.b    LZ77_FindMatch_CheckLimits                  ; Unconditional branch to LZ77_FindMatch_CheckLimits
LZ77_FindMatch_ShortOffset:
	move.w   d3,d6                         ; Copy matched length to d6
	subq.w   #$2,d6                        ; Subtract base offset
	lsl.w    #$1,d6                        ; Multiply class index by 2
LZ77_FindMatch_CheckLimits:
	lea      Table_LZ77_OffsetLimits(pc),a6 ; Load pointer to offset limits class table
	cmp.w    (a6,d6.w),d4                  ; Compare backward distance with class limit
	bge.b    LZ77_FindMatch_ScanNext                  ; Branch to LZ77_FindMatch_ScanNext if greater than or equal condition is met
	move.l   d3,d5                         ; Update best match length to d5
	move.l   d4,Var_LZ77_BestMatchOffset.l ; Update best match backward distance globally
	move.b   d6,Var_LZ77_BestMatchClass.l  ; Update best match class index globally
	cmpi.w   #$104,d3                      ; Check if best match reached absolute maximum
	bge.b    LZ77_FindMatch_Done                  ; Branch to LZ77_FindMatch_Done if greater than or equal condition is met
LZ77_FindMatch_ScanNext:
	cmpa.l   a5,a3                         ; Check if sliding window search pointer reached lookahead limit
	bgt.w    LZ77_FindMatch_NextChar                  ; Branch to LZ77_FindMatch_NextChar if greater than condition is met
LZ77_FindMatch_Done:
	cmpi.l   #$1,d5                        ; Check if any valid match was found (length > 1)
	beq.b    LZ77_WriteLiteralByte                  ; Branch to LZ77_WriteLiteralByte if equal / zero condition is met
	bsr.b    LZ77_FlushLiterals                  ; Call local subroutine LZ77_FlushLiterals
	move.b   Var_LZ77_BestMatchClass(pc),d6 ; Load best match class index value
	move.l   Var_LZ77_BestMatchOffset(pc),d3 ; Load best match backward distance offset
	move.w   $8(a6,d6.w),d0                ; Load prefix bit count for this match class
	bsr.w    LZ77_WriteBits                  ; Call local subroutine LZ77_WriteBits
	move.w   $10(a6,d6.w),d0               ; Load offset bit count for this match class
	beq.b    LZ77_FindMatch_EncodeDone                  ; Branch to LZ77_FindMatch_EncodeDone if equal / zero condition is met
	move.l   d5,d3                         ; Copy match length to d3
	subq.w   #$5,d3                        ; Subtract base offset index
	bsr.w    LZ77_WriteBits                  ; Call local subroutine LZ77_WriteBits
LZ77_FindMatch_EncodeDone:
	move.w   $18(a6,d6.w),d0               ; Load prefix bits value for this match class
	move.w   $20(a6,d6.w),d3               ; Load prefix bits count
	bsr.w    LZ77_WriteBits                  ; Call local subroutine LZ77_WriteBits
	move.w   d2,$dff180.l                  ; Acknowledge frame raster status (debug flash)
	adda.l   d5,a0                         ; Advance payload read pointer past matched run
	clr.b    d0                            ; Return status 0 to signal match was encoded
	rts                                    ; Return from subroutine
LZ77_WriteLiteralByte:
	move.b   (a0)+,d3                      ; Fetch literal character byte from lookahead
	moveq    #$8,d0                        ; Quick load constant value #$8 into register d0
	bsr.w    LZ77_WriteBits                  ; Call local subroutine LZ77_WriteBits
	moveq    #$1,d0                        ; Quick load constant value #$1 into register d0
	rts                                    ; Return from subroutine
Var_LZ77_BestMatchOffset:
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
Var_LZ77_BestMatchClass:
	dc.b $00
	dc.b $00
Table_LZ77_OffsetLimits:
	dc.b $01
	dc.b $00
	dc.b $02
	dc.b $00
	dc.b $04
	dc.b $00
	dc.b $10
	dc.b $00
Table_LZ77_BitLengthsClass0_2:
	dc.b $00
	dc.b $08
Table_LZ77_BitLengthsClass3:
	dc.b $00
	dc.b $09
Table_LZ77_PrefixCodesClass0_2:
	dc.b $00
	dc.b $0A
Table_LZ77_PrefixCodesClass3:
	dc.b $00
	dc.b $0C
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $08
	dc.b $00
	dc.b $02
	dc.b $00
	dc.b $03
	dc.b $00
	dc.b $03
	dc.b $00
	dc.b $03
	dc.b $00
	dc.b $01
	dc.b $00
	dc.b $04
	dc.b $00
	dc.b $05
	dc.b $00
	dc.b $06
LZ77_FlushLiterals:
	tst.w    d1                            ; Check if any literal bytes are currently buffered
	beq.b    LZ77_FlushLiterals_Exit                  ; Branch to LZ77_FlushLiterals_Exit if equal / zero condition is met
	move.w   d1,d3                         ; Copy literal run count to d3
	clr.w    d1                            ; Initialize literal run count to zero
	cmpi.w   #$9,d3                        ; Check if literal run exceeds 8 bytes
	bge.b    LZ77_FlushLiterals_Large                  ; Branch to LZ77_FlushLiterals_Large if greater than or equal condition is met
	subq.w   #$1,d3                        ; Subtract base literal run offset
	moveq    #$5,d0                        ; Quick load constant value #$5 into register d0
	bra.b    LZ77_WriteBits                  ; Unconditional branch to LZ77_WriteBits
LZ77_FlushLiterals_Exit:
	rts                                    ; Return from subroutine
LZ77_FlushLiterals_Large:
	subi.w   #$9,d3                        ; Subtract base offset for large run
	ori.w    #$380,d3                      ; Merge prefix header signature
	moveq    #$a,d0                        ; Quick load constant value #$a into register d0
LZ77_WriteBits:
	subq.w   #$1,d0                        ; Adjust bit loop counter (bits - 1)
LZ77_WriteBits_Loop:
	lsr.l    #$1,d3                        ; Shift current value bit right into carry flag
	roxl.l   #$1,d2                        ; Rotate carry flag bit into output longword buffer
	bcs.b    LZ77_WriteBits_BufferFull                  ; Branch to LZ77_WriteBits_BufferFull if carry set (less than / lower)
	dbra     d0,LZ77_WriteBits_Loop               ; Decrement counter and loop to d0,LZ77_WriteBits_Loop until finished
	rts                                    ; Return from subroutine
LZ77_FlushBitBuffer:
	clr.w    d0                            ; Clear bits register d0
LZ77_WriteBits_BufferFull:
	move.l   d2,(a2)+                      ; Write compressed payload size to file header
	moveq    #$1,d2                        ; Quick load constant value #$1 into register d2
	dbra     d0,LZ77_WriteBits_Loop               ; Decrement counter and loop to d0,LZ77_WriteBits_Loop until finished
	rts                                    ; Return from subroutine
ParseExecutableHunks:
	move.l   a7,Var_SavedSP.l              ; Preserve stack pointer globally in case of fatal error
	move.l   d1,Var_ReadFileHandle.l       ; Store file handle globally
	move.l   d2,Var_AllocFlags.l           ; Store memory allocation attributes globally
	move.l   a6,Var_SavedRegister.l        ; Preserve current DOSBase register globally
	clr.l    Var_HunkLoadStatus.l          ; Clear hunk loading status globally
	lea      Str_LoadingMessage(pc),a5     ; Load pointer to hunk loading welcome string
	bsr.w    PrintString                   ; Display the welcome banner to the screen
	bsr.w    ReadLongFromFile                  ; Call local subroutine ReadLongFromFile
	cmpi.l   #$3f3,d0                      ; Check if file header matches executable hunk format ($3f3)
	bne.w    ParseExecutableHunks_Reloc32Loop ; Jump to FastMem evaluation if Megacrunch is enabled
ParseExecutableHunks_HeaderLoop:
	bsr.w    ReadLongFromFile                  ; Call local subroutine ReadLongFromFile
	bne.b    ParseExecutableHunks_HeaderLoop                  ; Branch to ParseExecutableHunks_HeaderLoop if not equal / non-zero condition is met
	bsr.w    ReadLongFromFile                  ; Call local subroutine ReadLongFromFile
	move.l   d0,Var_TotalHunkCount.l       ; Store total hunks count globally
	asl.l    #$2,d0                        ; Multiply size by 4 to compute total offset table bytes
	move.l   d0,Var_TotalHunkSize.l        ; Store hunk index offset table size globally
	bsr.w    AllocateHunkMemory                  ; Call local subroutine AllocateHunkMemory
	move.l   d0,Var_AllocatedHunkList.l    ; Store allocated hunk list pointer globally
	beq.w    ParseExecutableHunks_Reloc32Loop ; Branch to ParseExecutableHunks_Reloc32Loop if equal / zero condition is met
	move.l   Var_TotalHunkSize(pc),d0      ; Load total segment hunks table size
	bsr.w    AllocateHunkMemory                  ; Call local subroutine AllocateHunkMemory
	move.l   d0,Var_CurrentHunkIdx.l       ; Store target hunk index globally
	beq.w    ParseExecutableHunks_Reloc32Loop ; Branch to ParseExecutableHunks_Reloc32Loop if equal / zero condition is met
	bsr.w    ReadLongFromFile                  ; Call local subroutine ReadLongFromFile
	move.l   d0,Var_TempHunkSize.l         ; Store current hunk size globally
	bsr.w    ReadLongFromFile                  ; Call local subroutine ReadLongFromFile
	move.l   d0,Var_TempHunkType.l         ; Store current hunk type globally
	sub.l    Var_TempHunkSize(pc),d0       ; Subtract temp hunk size to check limits
	move.l   d0,Var_HunkLoadCount.l        ; Store resolved hunks target count globally
	movea.l  Var_AllocFlags(pc),a4         ; Load global segment allocation flags
	move.l   d0,d7                         ; Copy hunk remaining count to d7
	movea.l  Var_CurrentHunkIdx(pc),a5     ; Load current hunk pointer
	movea.l  Var_AllocatedHunkList(pc),a3  ; Load allocated segment hunks table pointer
ParseExecutableHunks_LoadHunks:
	bsr.w    ReadLongFromFile                  ; Call local subroutine ReadLongFromFile
	move.l   d0,(a5)+                      ; Write hunk start address into index list and step
	move.l   a4,(a3)+                      ; Write segment memory pointer into allocated table and step
	asl.l    #$2,d0                        ; Multiply size by 4 to compute total offset table bytes
	adda.l   d0,a4                         ; Advance segment memory pointer by hunk bytes
	dbra     d7,ParseExecutableHunks_LoadHunks               ; Decrement counter and loop to d7,ParseExecutableHunks_LoadHunks until finished
	move.l   a4,Var_OpenLibraryVector.l    ; Store open library vector pointer globally
ParseExecutableHunks_HunkCode:
	bsr.w    ReadLongFromFile                  ; Call local subroutine ReadLongFromFile
	subi.l   #$3e7,d0                      ; Subtract base header index to find offset
	asl.l    #$2,d0                        ; Multiply size by 4 to compute total offset table bytes
	lea      ParseExecutableHunks_HunkData(pc),a0 ; Load address of hunk segment type jump table
	move.l   (a0,d0.w),d1                  ; Fetch target hunk type handler from jump table
	beq.w    ParseExecutableHunks_Reloc32Loop ; Branch to ParseExecutableHunks_Reloc32Loop if equal / zero condition is met
	movea.l  d1,a1                         ; Copy hunk base pointer to a1
	jsr      (a1)                          ; Call Exec/DOS vector (a1)
	lea      Str_DecrunchError(pc),a5      ; Load pointer to decompressor error message string
	bsr.w    PrintString                   ; Display the welcome banner to the screen
	bra.b    ParseExecutableHunks_HunkCode                  ; Unconditional branch to ParseExecutableHunks_HunkCode
; ============================================================================
; Data: ParseExecutableHunks_HunkData
; Purpose : Jump table containing handler addresses for each Amiga hunk type.
; Offsets correspond to (HunkType - 999) * 4.
; ============================================================================
ParseExecutableHunks_HunkData:
	dc.l     0                             ; Entry 0: HUNK_UNIT (no handler)
	dc.l     AllocateHunkMemory_FastMem    ; Entry 1: HUNK_NAME (Hunk name loader)
	dc.l     ParseExecutableHunks_CleanupAndError ; Entry 2: HUNK_CODE (Hunk code loader)
	dc.l     AllocateHunkMemory_Exit       ; Entry 3: HUNK_DATA (Hunk data loader)
	dc.l     AllocateHunkMemory_Error      ; Entry 4: HUNK_BSS (Hunk BSS initializer)
	dc.l     AllocateHunkMemory_Success    ; Entry 5: HUNK_RELOC32 (Hunk reloc32 parser)
	dc.l     0                             ; Entry 6: HUNK_RELOC16 (no handler)
	dc.l     0                             ; Entry 7: HUNK_RELOC8 (no handler)
	dc.l     0                             ; Entry 8: HUNK_EXT (no handler)
	dc.l     AllocateHunkMemory_ChipMem    ; Entry 9: HUNK_SYMBOL (Hunk symbol handler)
	dc.l     AllocateHunkMemory_Check      ; Entry 10: HUNK_DEBUG (Hunk debug handler)
	dc.l     ParseExecutableHunks_Reloc32_Loop ; Entry 11: HUNK_END (Hunk end marker)
ParseExecutableHunks_HunkBss:
	move.l   Var_OpenLibraryVector(pc),d0  ; Load current end pointer of loaded hunk memory
	sub.l    Var_AllocFlags(pc),d0         ; Subtract start pointer to compute total loaded bytes
ParseExecutableHunks_HunkBss_SaveResult:
	move.l   d0,-(a7)                      ; Preserve current status register d0 on stack
	tst.l    Var_CurrentHunkIdx.l          ; Test if current hunk segment is loaded
	beq.b    ParseExecutableHunks_Reloc32  ; Branch to ParseExecutableHunks_Reloc32 if equal / zero condition is met
	tst.l    Var_AllocatedHunkList.l       ; Test if allocated segment list exists
	beq.b    ParseExecutableHunks_NextHunk                  ; Branch to ParseExecutableHunks_NextHunk if equal / zero condition is met
	movea.l  $4.w,a6                       ; Load Exec library base pointer (ExecBase) from address 4
	movea.l  Var_AllocatedHunkList(pc),a1  ; Load allocated hunks list pointer
	move.l   Var_TotalHunkSize(pc),d0      ; Load total segment hunks table size
	jsr      -$d2(a6)                      ; Call Exec/DOS vector -$d2(a6)
ParseExecutableHunks_NextHunk:
	movea.l  Var_CurrentHunkIdx(pc),a1     ; Load current hunk pointer
	move.l   Var_TotalHunkSize(pc),d0      ; Load total segment hunks table size
	jsr      -$d2(a6)                      ; Call Exec/DOS vector -$d2(a6)
ParseExecutableHunks_Reloc32:
	lea      Str_DecrunchError(pc),a5      ; Load pointer to decompressor error message string
	bsr.w    PrintString                   ; Display the welcome banner to the screen
	move.l   (a7)+,d0                      ; Restore status register d0 from stack
	movea.l  Var_SavedRegister(pc),a6      ; Restore saved DOSBase register globally
	movea.l  Var_SavedSP(pc),a7            ; Restore saved stack pointer (SP) globally
	rts                                    ; Return from subroutine
ParseExecutableHunks_Reloc32Loop:
	moveq    #$ff,d0                       ; Initialize register d0 with error code -1 ($ff)
	bra.b    ParseExecutableHunks_HunkBss_SaveResult       ; Unconditional branch to save error status on stack
ParseExecutableHunks_Reloc32_Loop:
	lea      Str_HunkType_End(pc),a5       ; Load pointer to "Hunk_End" segment name string (original quirk!)
	bsr.w    PrintString                   ; Print segment type status message
	addq.l   #$1,Var_TempHunkSize.l        ; Increment relocated hunk index / size counter
	move.l   Var_TempHunkSize(pc),d0       ; Load current relocated hunk index
	cmp.l    Var_TempHunkType(pc),d0       ; Check if all relocated hunks are processed
	bgt.w    ParseExecutableHunks_HunkBss  ; Exit relocation parsing once all segments are completed
	addq.l   #$4,Var_HunkLoadStatus.l      ; Advance relocation offset pointer by 4 bytes (1 longword)
	rts                                    ; Return to caller
AllocateHunkMemory:
	moveq    #$0,d1                        ; Clear / initialize register d1 to 0
	movea.l  $4.w,a6                       ; Load Exec library base pointer (ExecBase) from address 4
	jsr      -$c6(a6)                      ; Call Exec AllocEntry to allocate memory blocks
	rts                                    ; Return from subroutine

; ============================================================================
; Function: AllocateHunkMemory_AllocRoutine
; Purpose : Allocates memory block for hunks using Exec AllocMem.
; Inputs  : d0 = Hunk size in longwords.
;           d1 = Memory flags (e.g. MEMF_FAST or MEMF_CHIP).
; Outputs : a0 = Allocated memory pointer.
; ============================================================================
AllocateHunkMemory_AllocRoutine:
	asl.l    #2,d0                         ; Convert size in longwords to bytes
	move.l   d0,d2                         ; Copy byte size to d2 for AllocMem
	movea.l  Var_DOSBase(pc),a6            ; Load ExecBase (reused Var_DOSBase slot)
	moveq    #0,d3                         ; Clear d3 for flags or attributes
	move.l   Var_ReadFileHandle(pc),d1     ; Load memory flags (FAST/CHIP) from file handle slot
	jsr      -66(a6)                       ; Call Exec AllocMem
	rts                                    ; Return from subroutine

; ============================================================================
; Function: AllocateHunkMemory_Check
; Purpose : Handles loading and allocation check for HUNK_DEBUG.
; ============================================================================
AllocateHunkMemory_Check:
	lea      Str_HunkType_Debug(pc),a5     ; Load "Hunk_Debug" segment name string
	bsr.w    PrintString                   ; Print segment name
	bsr.w    ReadLongFromFile              ; Read hunk size
	bra.w    AllocateHunkMemory_AllocRoutine ; Allocate memory using the main routine

; ============================================================================
; Function: AllocateHunkMemory_FastMem
; Purpose : Handles loading and allocation for HUNK_NAME.
; ============================================================================
AllocateHunkMemory_FastMem:
	lea      Str_HunkType_Name(pc),a5      ; Load "Hunk_Name" segment name string
	bsr.w    PrintString                   ; Print segment name
	bsr.w    ReadLongFromFile              ; Read hunk size
	bra.w    AllocateHunkMemory_AllocRoutine ; Allocate memory using the main routine

; ============================================================================
; Function: AllocateHunkMemory_ChipMem
; Purpose : Handles loading and allocation for HUNK_SYMBOL.
; ============================================================================
AllocateHunkMemory_ChipMem:
	lea      Str_HunkType_Symbol(pc),a5    ; Load "Hunk_Symbol" segment name string
	bsr.w    PrintString                   ; Print segment name
	bsr.w    ReadLongFromFile              ; Read first symbol name length
	bne.s    AllocateHunkMemory_ChipMem    ; Loop back if name is present (original quirk!)
	bsr.w    ReadLongFromFile              ; Read next hunk header type
	beq.s    .exit                         ; Exit if 0
	lea      4(a7),a7                      ; Pop return address to abort outer call
	bra.w    ParseExecutableHunks_HunkCode+4 ; Jump back to processing next hunk segment
.exit:
	rts

; ============================================================================
; Function: AllocateHunkMemory_Success
; Purpose : Handles absolute relocations for HUNK_RELOC32.
; ============================================================================
AllocateHunkMemory_Success:
	lea      Str_HunkType_Reloc32(pc),a5   ; Load "Reloc32" segment name string
	bsr.w    PrintString                   ; Print segment name
	movea.l  Var_AllocatedHunkList(pc),a4  ; Load allocated hunks table
	move.l   Var_HunkLoadStatus(pc),d6     ; Load current hunk index/status
	movea.l  (a4,d6.w),a4                  ; Load base address of current hunk to relocate
.next_reloc_block:
	bsr.w    ReadLongFromFile              ; Read relocation count
	beq.w    .exit                         ; If 0, relocation parsing is finished
	move.l   d0,d7                         ; Store relocations count in loop counter d7
	bsr.w    ReadLongFromFile              ; Read target hunk index
	asl.l    #2,d0                         ; Convert index to list offset (index * 4)
	movea.l  Var_AllocatedHunkList(pc),a5  ; Load allocated hunks list pointer
	adda.l   d0,a5                         ; Add target hunk offset in list
	subq.w   #1,d7                         ; Adjust count for dbra loop
.loop:
	move.l   (a5),d6                       ; Get target hunk base address
	sub.l    Var_WorkspaceBuffer(pc),d6    ; Translate to target file offset
	add.l    Var_SourceStartAddr(pc),d6
	subi.l   #$100,d6                      ; Adjust by header bias
.loop_read_offset:
	bsr.w    ReadLongFromFile              ; Read relocation offset in current hunk
	add.l    d6,(a4,d0.l)                  ; Apply relocation offset to target memory address
	dbra     d7,.loop_read_offset          ; Repeat relocations loop
	bra.w    .next_reloc_block             ; Proceed to next relocations block
.exit:
	rts

; ============================================================================
; Function: AllocateHunkMemory_Error
; Purpose : Handles loading and allocation/zeroing for HUNK_BSS.
; ============================================================================
AllocateHunkMemory_Error:
	bsr.w    ReadLongFromFile              ; Read hunk BSS size
	lea      Str_HunkType_Bss(pc),a5       ; Load "Hunk_BSS" segment name string
	bsr.w    PrintString                   ; Print segment name
	bsr.w    PrintHexLongScaledBy4         ; Print BSS segment size in hex
	movea.l  Var_AllocatedHunkList(pc),a4  ; Load allocated hunks table
	move.l   Var_HunkLoadStatus(pc),d1     ; Load current hunk index/status
	movea.l  (a4,d1.w),a0                  ; Load base address of allocated memory block
	subq.l   #1,d0                         ; Adjust longwords size for loop
	move.l   d0,-(a7)                      ; Save loop counter
	move.l   a0,d0                         ; Copy destination pointer to d0
	sub.l    Var_WorkspaceBuffer(pc),d0    ; Translate memory address to file offset
	add.l    Var_SourceStartAddr(pc),d0
	subi.l   #$100,d0                      ; Apply header bias
	bsr.w    PrintHexLong                  ; Print BSS memory base in hex
	move.l   (a7)+,d0                      ; Restore loop counter
.clear_loop:
	clr.l    (a0)+                         ; Zero-fill allocated BSS memory
	dbra     d0,.clear_loop                ; Continue until all longwords are cleared
	rts

; ============================================================================
; Function: AllocateHunkMemory_Exit
; Purpose : Handles loading and file reading for HUNK_DATA.
; ============================================================================
AllocateHunkMemory_Exit:
	lea      Str_HunkType_Data(pc),a5      ; Load "Hunk_Data" segment name string
	bsr.w    ReadLongFromFile              ; Read data segment size
	move.l   d0,d3                         ; Save size in d3
	bsr.w    PrintString                   ; Print segment name
	bsr.w    PrintHexLongScaledBy4         ; Print data segment size in hex
	movea.l  Var_AllocatedHunkList(pc),a5  ; Load allocated hunks table
	adda.l   Var_HunkLoadStatus(pc),a5     ; Point to current hunk pointer entry
	move.l   (a5),d2                       ; Load allocated memory block address to read into
	asl.l    #2,d3                         ; Convert size in longwords to bytes
	move.l   d0,-(a7)                      ; Save size
	move.l   d2,d0                         ; Copy destination pointer
	sub.l    Var_WorkspaceBuffer(pc),d0    ; Translate to target file offset
	add.l    Var_SourceStartAddr(pc),d0
	subi.l   #$100,d0                      ; Apply header bias
	bsr.w    PrintHexLong                  ; Print memory base address in hex
	move.l   (a7)+,d0                      ; Restore size
	bsr.w    ReadFromFile_Reused           ; Read segment data from file directly into memory
	rts

; ============================================================================
; Function: ParseExecutableHunks_CleanupAndError
; Purpose : Error handler/clean-up block for hunk loader.
; ============================================================================
ParseExecutableHunks_CleanupAndError:
	lea      Str_HunkType_Code(pc),a5      ; Load "Hunk_Code" segment name string (original quirk!)
	bra.s    AllocateHunkMemory_Exit+4     ; Proceed to common exit/abort routine

ReadLongFromFile:
	moveq    #$4,d3                        ; Quick load constant value #$4 into register d3
	move.l   #Var_ReadLongBuffer,d2        ; Load pointer address to read buffer globally
ReadFromFile_Reused:
	movea.l  Var_DOSBase(pc),a6            ; Load DOS library base pointer
	move.l   Var_ReadFileHandle(pc),d1     ; Load input file handle globally
	jsr      -$2a(a6)                      ; Call Exec/DOS vector -$2a(a6)
	cmp.l    d3,d0                         ; Verify if 4 bytes were read successfully
	beq.b    ReadLongFromFile_Success      ; Branch to ReadLongFromFile_Success if equal / zero condition is met
	lea      $4(a7),a7                     ; Pop return address from stack to exit subroutine
	bra.w    ParseExecutableHunks_Reloc32Loop ; Unconditional branch to ParseExecutableHunks_Reloc32Loop
ReadLongFromFile_Success:
	move.l   Var_ReadLongBuffer(pc),d0     ; Retrieve 32-bit longword value from read buffer
	rts                                    ; Return from subroutine

; ============================================================================
; Function: PrintHexLongScaledBy4
; Purpose : Multiplies a value by 4 and prints it as a 32-bit hex longword.
; Inputs  : d0 = Value to scale and print.
; ============================================================================
PrintHexLongScaledBy4:
	move.l   d0,-(a7)                      ; Preserve d0 on stack
	asl.l    #2,d0                         ; Multiply by 4 (shift left by 2)
	bsr.w    PrintHexLong                  ; Print as hex longword
	move.l   (a7)+,d0                      ; Restore original d0
	rts
Var_HexCharBuffer:
	ds.b     6                             ; Temporary hex character printing buffer
Var_SourceBuffer_Minus80:
	dc.l     0                             ; Source payload buffer pointer minus 80 bytes bias
Var_SourceBufferEnd:
	dc.l     0                             ; End pointer of source payload buffer
Str_LoadingMessage:
	dc.b     "Description    Length     Address",10
	dc.b     "--------------------------------------",10,0
Str_HunkType_Bss:
	dc.b     "Hunk_BSS    ",0
Str_HunkType_Code:
	dc.b     "Hunk_Code   ",0
Str_HunkType_Data:
	dc.b     "Hunk_Data   ",0
Str_HunkType_Debug:
	dc.b     "Hunk_Debug  ",0
Str_HunkType_Name:
	dc.b     "Hunk_Name   ",0
Str_HunkType_Symbol:
	dc.b     "Hunk_Symbol ",0
Str_HunkType_Reloc32:
	dc.b     "Reloc32     ",0
Str_HunkType_End:
	dc.b     "Hunk_End    ",0
Var_HexTable:
	dc.b     "0123456789ABCDEF0123456789abcdef"
Str_FastMemAllocPrompt:
	dc.b     10,"Allocated memory ",0
Str_ChipMemAllocPrompt:
	dc.b     "-",0
Str_DecompressPrompt:
	dc.b     10,"Run now? (Y/N) ",0
Str_DecompressSuccess:
	dc.b     10,"Offset: $",0
Str_OriginalLength:
	dc.b     10,"Length: $",0
Str_DecrunchError:
	dc.b     10,0
Var_ProDecruncherFlag:
	dc.w     0                             ; Pro-decruncher configuration flag
Var_TrackdiskMsg:
	ds.b     160                           ; Buffer reserved for Trackdisk message port / I/O structure
Var_TrackdiskIORequest:
	ds.b     80                            ; Trackdisk IOStdReq structure workspace
Var_TrackdiskError:
	dc.w     0                             ; Trackdisk I/O error status code
Var_TrackdiskIO:
	dc.b     "HejPort",0                   ; Trackdisk message port name
Var_TrackdiskPort:
	dc.b     "trackdisk.device",0,0        ; Trackdisk device driver name
Var_TrackdiskTrack:
	dc.l     0                             ; Trackdisk current cylinder / offset
Var_TrackdiskCmd:
	dc.l     0                             ; Trackdisk current I/O command code
Var_SourceStartAddr:
	dc.l     0                             ; Source start address pointer
Var_SourceEndAddr:
	dc.l     0                             ; Source end address pointer
Var_RleMarkerByte:
	dc.w     0                             ; RLE compression marker byte
Var_RlePayloadEnd:
	dc.l     0                             ; RLE payload end address pointer
Var_SourceSize:
	dc.w     0                             ; Uncompressed source payload size in words
Var_FileHandle:
	dc.l     0                             ; AmigaDOS current file handle pointer
Var_FilePayloadBuffer:
	dc.l     0                             ; File payload buffer start pointer
Var_FilePayloadEnd:
	dc.l     0                             ; File payload buffer end pointer
Var_FileLength:
	dc.l     $1000                         ; Current file length (initialized to 4096 bytes)
Var_IsEncrypted:
	dc.b     0                             ; Encryption state flag
Var_EncryptionKey:
	dc.b     0                             ; Encryption key byte
Str_RleHeader:
	dc.b     10,10,"Please wait... crunching",10,0
Str_SaveHeader:
	dc.b     12,10,9,9,"SAVE FILE.",10,9,9,"----------",10,10,"JMP (JSR) Address: $",0
Str_SaveAgain:
	dc.b     10,"Save again (y/n)? ",0
Str_SaveHeaderAgain:
	dc.b     10,"Filename: ",0
Str_Header_Tetrapack:
	dc.b     12,10,9,"            TETRAPACK V2.2",10
	dc.b     9,"      --------------------------",10
	dc.b     9,"         Written By AntiAction",10,10
	dc.b     9,"          ",$A9," 1988 By TETRAGON.",10,10
	dc.b     9,"100% Bugfree, Better than RSI & ByteKiller!!",10
	dc.b     9," AT ANY TIME TYPE  *command  to execute CLI",10
	dc.b     9,"        Command or another program.",10,10
	dc.b     "MEGA-CRUNCH? (Y/N): ",0
Str_AllocBuffer:
	dc.b     10,"MEGACRUNCH IS NOW ON, YOU CAN CRUNCH PROGRAMS",10
	dc.b     "UP TO $7ff00 BYTES LONG.",0
Str_NoMegacrunch_1MB:
	dc.b     10,"MEGA-CRUNCH IS NOT AVAILABLE. 1MB REQUIRED",0
Str_TurnFastmemOff:
	dc.b     10,"YOU GOT TO TURN FASTMEM OFF FIRST, WANT ",10
	dc.b     "TO DO IT NOW?? (All memory will be cleared",10
	dc.b     "and AMIGA will reset!) [Y/N]: ",0
Str_FastmemActiveWarning:
	dc.b     10,"Expansion memory still active, jumping into",10
	dc.b     "smallcrunch mode.",0
Str_FlashRegisterPrompt:
	dc.b     10,"ENTER FLASH REGISTER:",10
	dc.b     "$00=Background, $01=CLI Text, $02=Color 2, $03=Color 3",10
	dc.b     "$11=Pointer col.1, $12=Pointer col.2, $13=Pointer Col.3",10
	dc.b     "$10=None",10
	dc.b     "Flash-reg ($00-$1f): ",0
Str_ProDecruncherPrompt:
	dc.b     10,"DO YOU WANT PRO-DECRUNCHER? (Y/N): ",0
Str_Dmacon:
	dc.b     10,"DMACON : $",0
Str_Intena:
	dc.b     10,"INTENA : $",0
Str_Adkcon:
	dc.b     10,"ADKCON : $",0
Str_StackA7:
	dc.b     10,"Locate stack (A7) at: $",0
Str_LocateStack:
	dc.b     10,"Status Reg. (SR): $",0
Str_StackAlloc:
	dc.b     10,"Locate decruncher at: $",0
Str_MemAllocError:
	dc.b     10,"INSUFFICIENT MEMORY FOR WORKSPACE.",0
Str_StackError:
	dc.b     "NOT WITHIN RANGE!!!",10,0
Str_Success:
	dc.b     "WARNING: FILE ENDED OUTSIDE RANGE!!",10,0,0
Var_FilePayloadSize:
	dc.l     0                             ; File payload size globally
Var_SavedRegister:
	dc.l     0                             ; Global temporary register storage
Var_SavedSP:
	dc.l     0                             ; Global saved stack pointer (SP)
Str_PromptStackAddress:
	dc.b     10,10,"              Length    Begin     End",10
	dc.b     "------------------------------------------",10
	dc.b     "Crunched    ",0
Str_StackAddressInvalid:
	dc.b     10,"Uncrunched  ",0
Str_AllocatingStack:
	dc.b     10,"------------------------------------------",10
	dc.b     "Bytes won: ",0
Str_StackAllocSuccess:
	dc.b     10,10,"       Press RETURN to continue",0
Str_StartAddr:
	dc.b     10,10,"Low-mem:  $",0
Str_EndAddr:
	dc.b     10,"High-mem: $",0
Str_AddressTable:
	dc.b     10,"Clearing memory...",0
Str_Description:
	dc.b     10,"File reading phase, enter all filenames",10
	dc.b     "required, and their loading addresses,",10
	dc.b     "then press RETURN alone to crunch.",0
Str_PromptFlashRegister:
	dc.b     10,10,"Filename: ",0
Str_DescriptionTable:
	dc.b     10,"Load type (r=Reloc, o=Plain, t=TrackDisk): ",0
Str_DescriptionTable_Hex:
	dc.b     "Load-address: $",0
Str_SuccessAddress:
	dc.b     "End-address:",0
Str_AllocBufferHex:
	dc.b     " $",0
Str_SuccessLen:
	dc.b     10,10,"Scan-Width ($0010-$8000): $",0
Str_DecompressError:
	dc.b     10,"** ERROR: Cannot relocate!",10
	dc.b     "   Bad hunk structure.",0,0
Var_AllocatedHunkList:
	dc.l     0                             ; Global loaded hunks segments table list
Var_TotalHunkCount:
	dc.l     0                             ; Global total hunk segments count
Var_TotalHunkSize:
	dc.l     0                             ; Global total segments size counter
Var_CurrentHunkIdx:
	dc.l     0                             ; Global loaded hunk index offset
Var_TempHunkSize:
	dc.l     0                             ; Global temp hunk size register storage
Var_TempHunkType:
	dc.l     0                             ; Global temp hunk type register storage
Var_HunkLoadCount:
	dc.l     0                             ; Global hunk target load counter
Var_HunkLoadStatus:
	dc.l     0                             ; Global hunk load pointer / status
Var_AllocFlags:
	dc.l     0                             ; Hunk segment loader start / flags pointer
Var_ReadFileHandle:
	dc.l     0                             ; Input file read handle globally
Var_OpenLibraryVector:
	dc.l     0                             ; Hunk segment loader current end pointer
Var_ReadLongBuffer:
	dc.l     0                             ; Buffer for reading 32-bit longwords
Str_DosLibrary:
	dc.b     "dos.library",0
Var_DOSBase:
	dc.l     0                             ; AmigaDOS library base pointer globally
Var_StdinHandle:
	dc.l     0                             ; Standard Input stream file handle pointer
	dc.w     $FFFF                         ; Padding / termination flag

; ============================================================================
; Template: Standard Decruncher (Hunk Segment & Decompression Stub)
; Purpose : Embedded standard decompressor stub written to output executables.
; Notes   : Represents a full relocatable Amiga hunk (HUNK_HEADER + HUNK_CODE).
;           Coded as raw words to permit direct patching by the compressor
;           for sizes, stack limits, jump addresses, and visual color effects.
; ============================================================================
Template_Decruncher_Header:
	dc.l     $000003F3                     ; Amiga HUNK_HEADER magic cookie
	dc.l     0                             ; Hunk name string pointer (NULL)
	dc.l     1                             ; Total hunk count in executable
	dc.l     0                             ; First hunk slot number
	dc.l     0                             ; Last hunk slot number
Var_Decruncher_PayloadLen:
	dc.l     0                             ; Patched by compressor: crunched payload length in bytes
Var_Decruncher_HunkSize:
	dc.l     $000003E9                     ; Hunk size in longwords (allocated by OS loader)
Var_Decruncher_OrigLen:
	dc.l     0                             ; Patched by compressor: uncompressed payload length in bytes

Template_Decruncher_Start:
	dc.w     $7E00                         ; moveq    #0, d7 (Clear loop/color index)
	dc.w     $43FA,$00FC                   ; lea.l    $100(pc), a1 (Load source payload start)
	dc.w     $4BF9,$00DF                   ; lea.l    CUSTOM+$100(pc), a5 (Instruction body header)
	dc.b     $F1                           ; High byte of flash color register address ($F1)
Var_Decruncher_FlashReg:
	dc.b     $80                           ; Low byte of flash color register address (default: $80 = COLOR00)
	dc.w     $287A,$00C4                   ; movea.l  Var_Decruncher_StackA7(pc), a4 (Reads custom stack pointer address)
	dc.w     $204C                         ; movea.l  a4, a0
	dc.w     $D1FC                         ; adda.l   #<jmp_address>, a0 (Instruction body header)
Var_Decruncher_JmpAddr:
	dc.l     0                             ; Patched by compressor: execution jump (JSR) address
	dc.w     $B3CC                         ; cmpa.l   a4, a1
	dc.w     $6E08                         ; bgt.s    .standard_copy
	dc.w     $2049                         ; movea.l  a1, a0
	dc.w     $D1FA,$FFF4                   ; adda.l   Var_Decruncher_PayloadLen(pc), a0 (Computes payload end pointer)
	dc.w     $6006                         ; bra.s    .standard_decompress_start
.standard_copy:
	dc.w     $18D9                         ; move.b   (a1)+, (a4)+
	dc.w     $B9C8                         ; cmpa.l   a0, a4
	dc.w     $6DFA                         ; blt.s    .standard_copy
.standard_decompress_start:
	dc.w     $43F9                         ; lea.l    <stack_address>, a1 (Instruction body header)
Var_Decruncher_StackA7:
	dc.l     0                             ; Patched by compressor: stack pointer (A7) address
	dc.w     $2460                         ; movea.l  -(a0), a2
	dc.w     $D5C9                         ; adda.l   a1, a2
	dc.w     $2020                         ; move.l   -(a0), d0
	dc.w     $E288                         ; lsr.l    #1, d0
	dc.w     $6602                         ; bne.s    .bit_available_1
	dc.w     $6134                         ; bsr.s    ReadNextBit
.bit_available_1:
	dc.w     $656A                         ; bcs.s    .decompress_literal
	dc.b     $72                           ; moveq instruction opcode
Var_Decruncher_Dmacon:
	dc.b     $08                           ; Patched by compressor: DMACON configuration byte (default: $08)
	dc.w     $7601                         ; moveq    #1, d3
.bit_loop_match:
	dc.w     $E288                         ; lsr.l    #1, d0
	dc.w     $6602                         ; bne.s    .bit_available_2
	dc.w     $6128                         ; bsr.s    ReadNextBit
.bit_available_2:
	dc.w     $653C                         ; bcs.s    .match_or_rle
	dc.w     $7203                         ; moveq    #3, d1 (Constant shift value)
	dc.w     $7800                         ; moveq    #0, d4
	dc.w     $6146                         ; bsr.s    ReadBits
	dc.w     $3602                         ; move.w   d2, d3
	dc.w     $D644                         ; add.w    d4, d3
	dc.w     $7207                         ; moveq    #7, d1
.bit_loop_fetch:
	dc.w     $E288                         ; lsr.l    #1, d0
	dc.w     $6602                         ; bne.s    .bit_available_3
	dc.w     $6114                         ; bsr.s    ReadNextBit
.bit_available_3:
	dc.w     $E392                         ; roxl.l   #1, d2
	dc.w     $51C9,$FFF6                   ; dbra     d1, .bit_loop_fetch
	dc.w     $1502                         ; move.b   d2, -(a2)
	dc.w     $51CB,$FFEE                   ; dbra     d3, .bit_loop_match
	dc.w     $6026                         ; bra.s    .match_next
.rle_mode:
	dc.w     $7207                         ; moveq    #7, d1
	dc.w     $7808                         ; moveq    #8, d4
	dc.w     $60DE                         ; bra.s    .rle_fetch
ReadNextBit:
	dc.w     $2020                         ; move.l   -(a0), d0
	dc.w     $1E00                         ; move.b   d0, d7 (Copy color bit data)
	dc.w     $3A87                         ; move.w   d7, (a5) (Flash background color register)
	dc.w     $44FC,$0010                   ; move.w   #$10, ccr (Set extend bit / X flag)
	dc.w     $E290                         ; roxr.l   #1, d0
	dc.w     $4E75                         ; rts
.short_match:
	dc.b     $72                           ; moveq instruction opcode
Var_Decruncher_Intena:
	dc.b     $09                           ; Patched by compressor: default INTENA / shift value (default: $09)
	dc.w     $3602                         ; move.w   d2, d3
Var_Decruncher_IntenaNop:
	dc.w     $D242                         ; Default instruction: add.w d2, d1 (Patched to NOP $4E71 by compressor)
	dc.w     $5443                         ; addq.w   #2, d3
	dc.w     $610E                         ; bsr.s    ReadBits
	dc.w     $1532,$20FF                   ; move.b   -1(a2, d2.w), -(a2)
	dc.w     $51CB,$FFFA                   ; dbra     d3, -8(pc)
.match_next:
	dc.w     $B3CA                         ; cmpa.l   a2, a1
	dc.w     $6DA2                         ; blt.s    .bit_loop_match
	dc.w     $6038                         ; bra.s    .standard_decompress_exit
.read_bits_entry:
	dc.w     $5341                         ; subq.w   #1, d1
	dc.w     $7400                         ; moveq    #0, d2
.bit_loop_read:
	dc.w     $E288                         ; lsr.l    #1, d0
	dc.w     $6602                         ; bne.s    .bit_available_4
	dc.w     $61D0                         ; bsr.s    ReadNextBit
.bit_available_4:
	dc.w     $E392                         ; roxl.l   #1, d2
	dc.w     $51C9,$FFF6                   ; dbra     d1, .bit_loop_read
	dc.w     $4E75                         ; rts
.decompress_literal:
	dc.w     $7202                         ; moveq    #2, d1
	dc.w     $61EA                         ; bsr.s    .read_bits_entry
	dc.w     $0C02,$0002                   ; cmpi.b   #2, d2
	dc.w     $6DCC                         ; blt.s    .short_match
	dc.w     $0C02,$0003                   ; cmpi.b   #3, d2
	dc.w     $67B2                         ; beq.s    .rle_mode
	dc.w     $7208                         ; moveq    #8, d1
	dc.w     $61DA                         ; bsr.s    .read_bits_entry
	dc.w     $3602                         ; move.w   d2, d3
	dc.w     $5843                         ; addq.w   #4, d3
	dc.b     $72                           ; moveq instruction opcode
Var_Decruncher_Adkcon:
	dc.b     $0C                           ; Patched by compressor: ADKCON configuration byte (default: $0C)
	dc.w     $60C2                         ; bra.s    .match_or_rle
	dc.b     " TETRAGON ~"                  ; Signature marker string embedded in decompressor
Var_Decruncher_RleMarker:
	dc.b     $00                           ; Patched by compressor: default RLE marker byte
	dc.w     $41F9                         ; lea.l    <StartAddr>, a0 (Instruction body header)
Var_Decruncher_StartAddr:
	dc.l     0                             ; Patched by compressor: payload start address
	dc.w     $45F9                         ; lea.l    <EndAddr>, a2 (Instruction body header)
Var_Decruncher_EndAddr:
	dc.l     0                             ; Patched by compressor: payload end address
.rle_decompress_loop:
	dc.w     $1019                         ; move.b   (a1)+, d0
	dc.w     $B007                         ; cmp.b    d7, d0
	dc.w     $6610                         ; bne.s    .not_rle
	dc.w     $7200                         ; moveq    #0, d1
	dc.w     $1219                         ; move.b   (a1)+, d1
	dc.w     $670A                         ; beq.s    .not_rle
	dc.w     $1019                         ; move.b   (a1)+, d0
	dc.w     $5241                         ; addq.w   #1, d1
.rle_copy_loop:
	dc.w     $10C0                         ; move.b   d0, (a0)+
	dc.w     $51C9,$FFFC                   ; dbra     d1, .rle_copy_loop
.not_rle:
	dc.w     $3A80                         ; move.w   d0, (a5)                     ; Flash color
	dc.w     $10C0                         ; move.b   d0, (a0)+
	dc.w     $B3CA                         ; cmpa.l   a2, a1
	dc.w     $6DE2                         ; blt.s    .rle_decompress_loop
.standard_decompress_exit:
	dc.w     $4EF9                         ; jmp      <jmp_address> (Instruction body header)
Str_AskFilename:
	dc.l     0                             ; Patched by compressor: execution entry jump address
Str_WriteSuccess:
	dc.l     $000003F2                     ; Amiga HUNK_END magic cookie

; ============================================================================
; Template: Pro Decruncher (Hunk Segment & Decompression Stub)
; Purpose : Embedded premium decompressor stub with hardware state protection.
; Notes   : Takes complete control of custom registers, interrupts, DMA,
;           and CIA timers to maximize execution speed and decrunch space.
;           Coded as raw words to permit dynamic patch-relocations by the
;           compressor main body before writing out.
; ============================================================================
Str_AskSaveAgain:
	dc.l     $000003F3                     ; Amiga HUNK_HEADER magic cookie
	dc.l     0                             ; Hunk name string pointer (NULL)
	dc.l     1                             ; Total hunk count in executable
	dc.l     0                             ; First hunk slot number
	dc.l     0                             ; Last hunk slot number
Var_DecruncherPro_PayloadLen:
	dc.l     0                             ; Patched by compressor: crunched payload length in bytes
Var_DecruncherPro_HunkSize:
	dc.l     $000003E9                     ; Hunk size in longwords (allocated by OS loader)
Var_DecruncherPro_OrigLen:
	dc.l     0                             ; Patched by compressor: uncompressed payload length in bytes

Template_DecruncherPro_Start:
	dc.w     $4DF9,$00DF,$F000             ; lea.l    CUSTOM, a6
	dc.w     $7E00                         ; moveq    #0, d7
	dc.w     $303C,$7FFF                   ; move.w   #$7FFF, d0
	dc.w     $3D40,$0096                   ; move.w   d0, DMACON(a6)               ; Disable DMA
	dc.w     $3D40,$009A                   ; move.w   d0, INTENA(a6)               ; Disable Interrupts
	dc.w     $3D40,$009E                   ; move.w   d0, INTREQ(a6)               ; Disable Interrupt Requests
	dc.l     $13FC0087,$00BFD100           ; move.b   #$87, $bfd100.l              ; CIA control (stop timer B)
	dc.w     $41FA,$0006                   ; lea.l    6(pc), a0                    ; Point to safe vector
	dc.w     $21C8,$0020                   ; move.l   a0, $20.w                    ; Install exception vector
	dc.w     $46FC,$2700                   ; move.w   #$2700, sr                   ; Set SR (disable interrupts)
	dc.w     $4FF9                         ; lea.l    <stack_address>, a7 (Instruction body header)
Var_DecruncherPro_JmpAddr:
	dc.l     $0007FFFE                     ; Patched by compressor: custom stack pointer (A7) address (default)
	dc.w     $43F9                         ; lea.l    <jmp_address>, a1 (Instruction body header)
Var_DecruncherPro_StackA7:
	dc.l     0                             ; Patched by compressor: execution jump vector address
	dc.w     $2649                         ; movea.l  a1, a3
	dc.w     $41FA,$0058                   ; lea.l    .pro_subroutine(pc), a0
	dc.w     $4BF9,$00DF                   ; lea.l    $dff100.l+Var_DecruncherPro_FlashReg, a5 (Instruction body header)
	dc.b     $F1                           ; High byte of flash color register address ($F1)
Var_DecruncherPro_FlashReg:
	dc.b     $80                           ; Low byte of flash color register address (default: $80 = COLOR00)
	dc.w     $303C,$00CF                   ; move.w   #$CF, d0 (Copy 208 bytes of sub-routine)
.copy_loop:
	dc.w     $12D8                         ; move.b   (a0)+, (a1)+
	dc.w     $51C8,$FFFC                   ; dbra     d0, .copy_loop
	dc.w     $4879                         ; pea.l    <jmp_entry> (Instruction body header)
Str_AskFilenamePro:
	dc.l     0                             ; Patched by compressor: execution entry jump address
	dc.b     $48                           ; Mnemonic for pea absolute short
	dc.b     $78                           ; Mnemonic for pea absolute short
Str_WriteSuccessPro:
	dc.w     0                             ; Patched by compressor: second entry jump short / flag
	dc.w     $43FA,$010A                   ; lea.l    .payload_end(pc), a1
	dc.w     $287A,$003A                   ; movea.l  Var_DecruncherPro_Dmacon(pc), a4 (reads DMACON target)
	dc.w     $204C                         ; movea.l  a4, a0
	dc.w     $D1FC                         ; adda.l   #<intena>, a0 (Instruction body header)
Var_DecruncherPro_Dmacon:
	dc.l     0                             ; Patched by compressor: original DMACON state value
	dc.w     $B3CC                         ; cmpa.l   a4, a1
	dc.w     $6E08                         ; bgt.s    .pro_copy
	dc.w     $2049                         ; movea.l  a1, a0
	dc.w     $D1FA,$FFF4                   ; adda.l   Var_DecruncherPro_PayloadLen(pc), a0 (Computes payload end pointer)
	dc.w     $6006                         ; bra.s    .pro_decompress_start
.pro_copy:
	dc.w     $18D9                         ; move.b   (a1)+, (a4)+
	dc.w     $B9C8                         ; cmpa.l   a0, a4
	dc.w     $6DFA                         ; blt.s    .pro_copy
.pro_decompress_start:
	dc.w     $43F9                         ; lea.l    <stack_address>, a1 (Instruction body header)
Var_DecruncherPro_Intena:
	dc.l     0                             ; Patched by compressor: original INTENA state value
	dc.w     $2460                         ; movea.l  -(a0), a2
	dc.w     $D5C9                         ; adda.l   a1, a2
	dc.w     $2020                         ; move.l   -(a0), d0
	dc.w     $4EEB,$0040                   ; jmp      $40(a3) (Jump to copied sub-routine on stack)
	dc.b     " TETRAGON ~"                  ; Signature marker string embedded in decompressor
Var_DecruncherPro_RleMarker:
	dc.b     $00                           ; Patched by compressor: default RLE marker byte
	dc.w     $41F9                         ; lea.l    <StartAddr>, a0 (Instruction body header)
Var_DecruncherPro_StartAddr:
	dc.l     0                             ; Patched by compressor: payload start address
	dc.w     $45F9                         ; lea.l    <EndAddr>, a2 (Instruction body header)
Var_DecruncherPro_EndAddr:
	dc.l     0                             ; Patched by compressor: payload end address
.pro_rle_decompress_loop:
	dc.w     $1019                         ; move.b   (a1)+, d0
	dc.w     $B007                         ; cmp.b    d7, d0
	dc.w     $6610                         ; bne.s    .pro_not_rle
	dc.w     $7200                         ; moveq    #0, d1
	dc.w     $1219                         ; move.b   (a1)+, d1
	dc.w     $670A                         ; beq.s    .pro_not_rle
	dc.w     $1019                         ; move.b   (a1)+, d0
	dc.w     $5241                         ; addq.w   #1, d1
.pro_rle_copy_loop:
	dc.w     $10C0                         ; move.b   d0, (a0)+
	dc.w     $51C9,$FFFC                   ; dbra     d1, .pro_rle_copy_loop
.pro_not_rle:
	dc.w     $3A80                         ; move.w   d0, (a5)                     ; Flash color
	dc.w     $10C0                         ; move.b   d0, (a0)+
	dc.w     $B3CA                         ; cmpa.l   a2, a1
	dc.w     $6DE2                         ; blt.s    .pro_rle_decompress_loop
	dc.w     $3D7C                         ; move.w   #$009A, d0 (Dummy/placeholder word - patched by compressor)
Var_DecruncherPro_IntenaNop:
	dc.w     0                             ; Patched by compressor: original INTENA state (moves to INTREQ)
	dc.w     $009E                         ; Offset destination register INTREQ
	dc.w     $3D7C                         ; move.w   #<dmacon_val>, $0096(a6) (Instruction body header)
Var_DecruncherPro_Adkcon:
	dc.w     0                             ; Patched by compressor: original DMACON state
	dc.w     $0096                         ; Offset destination register DMACON
	dc.w     $3D7C                         ; move.w   #<intena_val>, $009A(a6) (Instruction body header)
Var_DecruncherPro_AdkconNop:
	dc.w     0                             ; Patched by compressor: original INTENA state
	dc.w     $009A                         ; Offset destination register INTENA
	dc.w     $4E73                         ; rte (Return from Exception)
	dc.w     $E288                         ; lsr.l    #1, d0
	dc.w     $6602                         ; bne.s    .pro_bit_avail_1
	dc.w     $6134                         ; bsr.s    ReadNextBit
.pro_bit_avail_1:
	dc.w     $656C                         ; bcs.s    .pro_decompress_literal
	dc.b     $72                           ; moveq instruction opcode
Var_RLE_Histogram:
	dc.b     $08                           ; Patched by compressor: DMACON configuration byte (default: $08)
	dc.w     $7601                         ; moveq    #1, d3
.pro_bit_loop_match:
	dc.w     $E288                         ; lsr.l    #1, d0
	dc.w     $6602                         ; bne.s    .pro_bit_available_2
	dc.w     $6128                         ; bsr.s    ReadNextBit
	dc.w     $653C                         ; bcs.s    .pro_match_or_rle
	dc.w     $7203                         ; moveq    #3, d1 (Constant shift value)
	dc.w     $7800                         ; moveq    #0, d4
	dc.w     $6148                         ; bsr.s    ReadBits
	dc.w     $3602                         ; move.w   d2, d3
	dc.w     $D644                         ; add.w    d4, d3
	dc.w     $7207                         ; moveq    #7, d1
.pro_bit_loop_fetch:
	dc.w     $E288                         ; lsr.l    #1, d0
	dc.w     $6602                         ; bne.s    .pro_bit_available_3
	dc.w     $6114                         ; bsr.s    ReadNextBit
.pro_bit_available_3:
	dc.w     $E392                         ; roxl.l   #1, d2
	dc.w     $51C9,$FFF6                   ; dbra     d1, .pro_bit_loop_fetch
	dc.w     $1502                         ; move.b   d2, -(a2)
	dc.w     $51CB,$FFEE                   ; dbra     d3, .pro_bit_loop_match
	dc.w     $6026                         ; bra.s    .pro_match_next
.pro_rle_mode:
	dc.w     $7207                         ; moveq    #7, d1
	dc.w     $7808                         ; moveq    #8, d4
	dc.w     $60DE                         ; bra.s    .pro_rle_fetch
.pro_read_next_bit:
	dc.w     $2020                         ; move.l   -(a0), d0
	dc.w     $1E00                         ; move.b   d0, d7
	dc.w     $3A87                         ; move.w   d7, (a5)                     ; Flash color
	dc.w     $44FC,$0010                   ; move.w   #$10, ccr
	dc.w     $E290                         ; roxr.l   #1, d0
	dc.w     $4E75                         ; rts
.pro_short_match:
	dc.b     $72                           ; moveq instruction opcode
Var_RLE_Histogram_End:
	dc.b     $09                           ; Patched by compressor: default INTENA value (default: $09)
	dc.w     $3602                         ; move.w   d2, d3
Var_RLE_EscapeChar:
	dc.w     $D242                         ; Default instruction: add.w d2, d1 (Patched to NOP $4E71 by compressor)
	dc.w     $5443                         ; addq.w   #2, d3
	dc.w     $6110                         ; bsr.s    ReadBits
	dc.w     $1532,$20FF                   ; move.b   -1(a2, d2.w), -(a2)
	dc.w     $51CB,$FFFA                   ; dbra     d3, -8(pc)
.pro_match_next:
	dc.w     $B3CA                         ; cmpa.l   a2, a1
	dc.w     $6DA2                         ; blt.s    .pro_bit_loop_match
	dc.w     $6000,$FF60                   ; bra.w    -$A0
.pro_read_bits_entry:
	dc.w     $5341                         ; subq.w   #1, d1
	dc.w     $7400                         ; moveq    #0, d2
.pro_bit_loop_read:
	dc.w     $E288                         ; lsr.l    #1, d0
	dc.w     $6602                         ; bne.s    .pro_bit_available_4
	dc.w     $61CE                         ; bsr.s    ReadNextBit
.pro_bit_available_4:
	dc.w     $E392                         ; roxl.l   #1, d2
	dc.w     $51C9,$FFF6                   ; dbra     d1, .pro_bit_loop_read
	dc.w     $4E75                         ; rts
.pro_decompress_literal:
	dc.w     $7202                         ; moveq    #2, d1
	dc.w     $61EA                         ; bsr.s    .pro_read_bits_entry
	dc.w     $0C02,$0002                   ; cmpi.b   #2, d2
	dc.w     $6DCA                         ; blt.s    .pro_short_match
	dc.w     $0C02,$0003                   ; cmpi.b   #3, d2
	dc.w     $67B0                         ; beq.s    .pro_rle_mode
	dc.w     $7208                         ; moveq    #8, d1
	dc.w     $61DA                         ; bsr.s    .pro_read_bits_entry
	dc.w     $3602                         ; move.w   d2, d3
	dc.w     $5843                         ; addq.w   #4, d3
	dc.b     $72                           ; moveq instruction opcode
Var_RLE_EscapeChar_End:
	dc.b     $0C                           ; Patched by compressor: default shift/ADKCON value (default: $0C)
	dc.w     $60C0                         ; bra.s    .pro_match_or_rle

Var_MegacrunchFlag:
	dc.w     0                             ; Megacrunch active flag globally
Var_WorkspaceBuffer:
	dc.l     0                             ; Workspace buffer base memory pointer
Var_WorkspaceSize:
	dc.l     0                             ; Workspace buffer capacity size
Var_IOBuffer:
	ds.b     10                            ; Temporary I/O path buffer space

; ========================================
	SECTION Hunk_1_Bss, BSS
Bss_Start:
	ds.b 4
