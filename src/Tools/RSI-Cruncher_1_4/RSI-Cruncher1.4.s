; ============================================================================
; Source  : RSI-Cruncher1.4.s
;
; Red Sector Cruncher by Flash/Red Sector Version 1.4
;
; Reconstructed by Volker Schwaberow <volker@schwaberow.de>
; ============================================================================
ExecBase        EQU     $00000004               ; Exec library base pointer stored at address 4.
CUSTOM          EQU     $dff000                 ; Base address of the Amiga Custom Chip registers.
CIAA            EQU     $bfe001                 ; Base address of the first CIA chip (CIAA).
OpenLibrary     EQU     -408                    ; Exec OpenLibrary vector offset.
CloseLibrary    EQU     -414                    ; Exec CloseLibrary vector offset.
AllocMem        EQU     -198                    ; Exec AllocMem vector offset.
FreeMem         EQU     -210                    ; Exec FreeMem vector offset.
Forbid          EQU     -132                    ; Exec Forbid vector offset.
Permit          EQU     -138                    ; Exec Permit vector offset.
Open            EQU     -30                     ; DOS Open vector offset.
Close           EQU     -36                     ; DOS Close vector offset.
Read            EQU     -42                     ; DOS Read vector offset.
Write           EQU     -48                     ; DOS Write vector offset.
Input           EQU     -60                     ; DOS Input vector offset.
Output          EQU     -54                     ; DOS Output vector offset.
FPuts           EQU     -222                    ; DOS FPuts vector offset.

; ============================================================================
; Function: Start
; Purpose : Initialize the DOS library and open standard input/output streams.
; ============================================================================
Start:
	movea.l  ExecBase.l,a6                  ; Load ExecBase for the following Exec calls.
	lea      Str_DosLibrary(pc),a1          ; Point a1 to "dos.library" string for OpenLibrary.
	jsr      -$198(a6)                      ; Call OpenLibrary to get dos.library base.
	move.l   d0,Var_DOSBase.l               ; Save opened DOSBase library pointer for file/CLI routines.
	beq.w    LZ77_CompressEnd               ; Abort execution if dos.library failed to open.
	movea.l  Var_DOSBase(pc),a6             ; Set up DOSBase pointer in a6 for library call.
	jsr      -$3c(a6)                       ; Call Input() to retrieve standard input handle.
	move.l   d0,Var_StdinHandle.l           ; Save retrieved standard input stream handle.
	jsr      -$36(a6)                       ; Call Output() to retrieve standard output handle.
	move.l   d0,Var_StdoutHandle.l          ; Save retrieved standard output stream handle.
	movea.l  Var_DOSBase(pc),a6             ; Set up DOSBase pointer in a6 for library call.
	move.l   Var_StdinHandle(pc),d1         ; Load standard input stream handle.
	move.l   #Str_Header,d2                 ; Point d2 to application information header banner string.
	move.l   #$72,d3                        ; Specify Str_Header message size for output (114 bytes).
	jsr      -$30(a6)                       ; Write message string to standard output stream via Write().
CheckFastMemLoop:
	movea.l  Var_DOSBase(pc),a6             ; Set up DOSBase pointer in a6 for library call.
	move.l   Var_StdinHandle(pc),d1         ; Load standard input stream handle.
	move.l   #Str_MegaPack,d2               ; Point d2 to "MEGA-PACK [y/n]: " prompt string.
	move.l   #$11,d3                        ; Specify prompt message size for output (17 bytes).
	jsr      -$30(a6)                       ; Write message string to standard output stream via Write().
	move.l   Var_StdoutHandle(pc),d1        ; Load standard output stream handle.
	move.l   #Var_InputBuffer,d2            ; Point d2 to the input buffer for user response.
	moveq    #$1e,d3                        ; Set maximum expected character read size to 30 bytes.
	jsr      -$2a(a6)                       ; Read user input string from standard input stream via Read().
	cmpi.l   #$1,d0                         ; Check if any characters were actually read.
	bls.b    CheckFastMemLoop               ; Loop back to Mega-Pack prompt if no input was entered.
	subq.l   #$1,d0                         ; Decrement byte count to point to the last character.
	lea      Var_InputBuffer(pc),a0         ; Point a0 to the input buffer.
	adda.l   d0,a0                          ; Add byte count to reach the end of the input string.
	clr.b    (a0)                           ; Null-terminate the string by replacing the newline.
	lea      Var_InputBuffer(pc),a0         ; Point a0 back to the start of the input buffer.
	cmpi.b   #$79,(a0)                      ; Check if the user entered 'y' for Mega-Pack.
	bne.w    AskWorkspace                   ; Jump to standard workspace prompt if user did not choose Mega-Pack.
	movea.l  ExecBase.l,a6                  ; Load ExecBase to check memory limits.
	cmpa.l   #$c00000,a6                    ; Check if the expansion memory area is available.
	bcs.b    TestSlowMem                    ; If condition met, proceed to test slow memory.
	movea.l  Var_DOSBase(pc),a6             ; Set up DOSBase pointer in a6 for library call.
	move.l   Var_StdinHandle(pc),d1         ; Load standard input stream handle.
	move.l   #Str_FastMemNotFree,d2         ; Point d2 to "FAST-MEMORY IS NOT FREE" warning string.
	move.l   #$3a,d3                        ; Specify size of fast memory warning string (58 bytes).
	jsr      -$30(a6)                       ; Write warning message to standard output stream.
	bra.w    AskWorkspace                   ; Prompt user again for valid workspace size.

; ============================================================================
; Function: TestSlowMem
; Purpose : Test if slow expansion memory at $c00000 is present and writable.
; ============================================================================
TestSlowMem:
	lea      $c00000.l,a0                   ; Point a0 to the start of slow expansion memory ($c00000).
	move.w   (a0),d0                        ; Read back original word value from the memory address.
	move.w   d0,d1                          ; Back up original word value to d1 for restoration later.
	eori.w   #$ffff,d0                      ; Invert the word bits to create a test pattern.
	move.w   d0,(a0)                        ; Write the test pattern to the memory address.
	move.w   (a0),d0                        ; Read back the value from the tested memory address.
	eori.w   #$ffff,d0                      ; Invert the word bits back to the original value.
	move.w   d1,(a0)                        ; Restore the original word value at the memory address.
	cmp.w    d0,d1                          ; Check if the restored value matches the original value.
	beq.b    InitSlowMem                    ; If memory is writable and retains values, proceed to initialize.
	movea.l  Var_DOSBase(pc),a6             ; Set up DOSBase pointer in a6 for library call.
	move.l   Var_StdinHandle(pc),d1         ; Load standard input stream handle.
	move.l   #Str_NoFastMem,d2              ; Point d2 to "YOU HAVE NO FAST-MEMORY" warning string.
	move.l   #$39,d3                        ; Specify size of no-fast-memory warning string (57 bytes).
	jsr      -$30(a6)                       ; Write warning message to standard output stream.
	bra.b    AskWorkspace                   ; Prompt user again for valid workspace size.

; ============================================================================
; Function: InitSlowMem
; Purpose : Clear slow memory buffer and configure pointers for Mega-Pack.
; ============================================================================
InitSlowMem:
	bset     #$0,Var_SlowMemFlag.l          ; Set flag indicating slow memory Mega-Pack mode is active.
	lea      $c00000.l,a0                   ; Point a0 to the start of slow memory expansion buffer.
	lea      $c80000.l,a1                   ; Point a1 to the end of the 512KB slow memory expansion area.
ClearSlowMemLoop:
	clr.w    (a0)+                          ; Clear one word of slow memory to zero.
	cmpa.l   a1,a0                          ; Check if we have reached the end of the expansion area.
	bcs.b    ClearSlowMemLoop               ; Loop until the entire slow memory expansion buffer is cleared.
	move.l   #$c00000,Var_PackedBuffer.l    ; Set packed output buffer pointer to the start of slow memory.
	move.l   #$c00080,Var_SourceBuffer.l    ; Set source file buffer pointer just past the packed buffer start.
	move.l   #$80000,Var_WorkspaceSize.l    ; Set workspace buffer size to 512KB for Mega-Pack mode.
	movea.l  Var_DOSBase(pc),a6             ; Set up DOSBase pointer in a6 for library call.
	move.l   Var_StdinHandle(pc),d1         ; Load standard input stream handle.
	move.l   #Str_FastMemAvailable,d2       ; Point d2 to fast memory status confirmation string.
	move.l   #$2b,d3                        ; Specify size of fast memory confirmation string (43 bytes).
	jsr      -$30(a6)                       ; Write confirmation message to standard output stream.
	bra.w    MainLoop                       ; Return to main filename input loop.

; ============================================================================
; Function: AskWorkspace
; Purpose : Prompt user for workspace size (KB) when Mega-Pack is disabled.
; ============================================================================
AskWorkspace:
	movea.l  Var_DOSBase(pc),a6             ; Set up DOSBase pointer in a6 for library call.
	move.l   Var_StdinHandle(pc),d1         ; Load standard input stream handle.
	move.l   #Str_Workspace,d2              ; Point d2 to workspace allocation size prompt string.
	move.l   #$b,d3                         ; Specify size of workspace prompt string (11 bytes).
	jsr      -$30(a6)                       ; Write message string to standard output stream.
	bsr.w    ClearInputBuffer               ; Clear the input buffer to prevent reading old data.
	move.l   Var_StdoutHandle(pc),d1        ; Load standard output stream handle.
	move.l   #Var_InputBuffer,d2            ; Point d2 to the input buffer for user response.
	moveq    #$4,d3                         ; Set maximum expected workspace character read size to 4 bytes.
	jsr      -$2a(a6)                       ; Read user input string from standard input stream via Read().
	cmpi.l   #$1,d0                         ; Check if any characters were actually read.
	bls.b    AskWorkspace                   ; Prompt user again for valid workspace size.
	subq.l   #$1,d0                         ; Decrement byte count to point to the last character.
	movea.l  #Var_InputBuffer,a0            ; Point a0 to the input buffer.
	adda.l   d0,a0                          ; Add byte count to reach the end of the input string.
	move.b   -(a0),d1                       ; Fetch previous character from input buffer (units digit).
	subq.l   #$1,d0                         ; Decrement character count.
	bsr.w    FindCharInHexTable             ; Convert ASCII character to hexadecimal digit value.
	cmpi.b   #$a,d1                         ; Check if the character was a valid digit (0-9).
	bcc.b    AskWorkspace                   ; Prompt user again for valid workspace size.
	moveq    #$0,d2                         ; Clear d2 for accumulating the workspace size value.
	move.b   d1,d2                          ; Move parsed digit value to d2 for accumulation.
	tst.b    d0                             ; Check if there are more characters to parse.
	beq.b    CalcWorkspaceSize              ; If no more characters, proceed to calculate workspace size.
	move.b   -(a0),d1                       ; Fetch previous character from input buffer (tens digit).
	subq.l   #$1,d0                         ; Decrement character count.
	bsr.w    FindCharInHexTable             ; Convert ASCII character to hexadecimal digit value.
	cmpi.b   #$a,d1                         ; Check if the character was a valid digit (0-9).
	bcc.b    AskWorkspace                   ; Prompt user again for valid workspace size.
	andi.w   #$f,d1                         ; Mask out the ASCII offset, keeping only the digit value.
	mulu.w   #$a,d1                         ; Multiply the tens digit by 10.
	add.w    d1,d2                          ; Add the multiplied tens digit to the accumulated value.
	tst.b    d0                             ; Check if there are more characters to parse.
	beq.b    CalcWorkspaceSize              ; If no more characters, proceed to calculate workspace size.
	move.b   -(a0),d1                       ; Fetch previous character from input buffer (hundreds digit).
	bsr.w    FindCharInHexTable             ; Convert ASCII character to hexadecimal digit value.
	cmpi.b   #$a,d1                         ; Check if the character was a valid digit (0-9).
	bcc.w    AskWorkspace                   ; Prompt user again for valid workspace size.
	andi.w   #$f,d1                         ; Mask out the ASCII offset, keeping only the digit value.
	mulu.w   #$64,d1                        ; Multiply the hundreds digit by 100.
	add.w    d1,d2                          ; Add the multiplied hundreds digit to the accumulated value.
	tst.w    d2                             ; Test if the accumulated workspace size in KB is greater than zero.
	beq.w    AskWorkspace                   ; Prompt user again for valid workspace size.
CalcWorkspaceSize:
	moveq    #$0,d0                         ; Initialize workspace size accumulator d0 to 0.
	subq.w   #$1,d2                         ; Adjust loop counter (count - 1) for DBRA instruction.
CalcWorkspaceLoop:
	addi.l   #$400,d0                       ; Add 1KB (1024 bytes) to the accumulated workspace size.
	dbra     d2,CalcWorkspaceLoop           ; Loop until the requested number of kilobytes is accumulated.
	move.l   d0,Var_WorkspaceSize.l         ; Save calculated workspace buffer size.
	movea.l  ExecBase.l,a6                  ; Load ExecBase for the following Exec calls.
	move.l   #$10000,d1                     ; Specify memory requirement flags (MEMF_CLEAR).
	move.l   Var_WorkspaceSize(pc),d0       ; Load the requested workspace buffer size.
	jsr      -$c6(a6)                       ; Call AllocMem to allocate the workspace memory.
	move.l   d0,Var_PackedBuffer.l          ; Save the allocated memory pointer as the packed buffer.
	beq.w    AskWorkspace                   ; Prompt user again if memory allocation failed.
	addi.l   #$80,d0                        ; Advance pointer past the initial 128-byte safety margin.
	move.l   d0,Var_SourceBuffer.l          ; Save the adjusted pointer as the source file buffer.
; ============================================================================
; Function: MainLoop
; Purpose : Prompt the user for the input filename and handle basic commands.
; ============================================================================
MainLoop:
	movea.l  Var_DOSBase(pc),a6             ; Set up DOSBase pointer in a6 for library call.
	move.l   Var_StdinHandle(pc),d1         ; Load standard input stream handle.
	move.l   #Str_Load,d2                   ; Point d2 to filename load prompt string.
	move.l   #$6,d3                         ; Specify size of load prompt string (6 bytes).
	jsr      -$30(a6)                       ; Write prompt message to standard output stream.
	move.l   Var_StdoutHandle(pc),d1        ; Load standard output stream handle.
	move.l   #Var_InputBuffer,d2            ; Point d2 to the input buffer for user response.
	moveq    #$1e,d3                        ; Set maximum expected character read size to 30 bytes.
	jsr      -$2a(a6)                       ; Read user input string from standard input stream.
	cmpi.l   #$1,d0                         ; Check if any characters were actually read.
	bls.b    MainLoop                       ; Return to main filename input loop if empty.
	subq.l   #$1,d0                         ; Decrement byte count to point to the last character.
	lea      Var_InputBuffer(pc),a0         ; Point a0 to the input buffer.
	adda.l   d0,a0                          ; Add byte count to reach the end of the input string.
	clr.b    (a0)                           ; Null-terminate the string by replacing the newline.
	lea      Var_InputBuffer(pc),a0         ; Point a0 back to the start of the input buffer.
	cmpi.b   #$2d,(a0)                      ; Check if the input starts with '-' indicating a command.
	bne.b    CheckCommands                  ; Jump to command parser if input does not start with prefix.
	addq.l   #$1,a0                         ; Skip the '-' prefix to read the following command string.
	move.l   a0,d1                          ; Pass the command string pointer to FPuts.
	moveq    #$0,d2                         ; Clear d2 for FPuts (unused parameter).
	move.l   Var_StdinHandle.l,d3           ; Pass standard input stream handle (or standard output if intended).
	jsr      -$de(a6)                       ; Print the command string to output.
	bra.b    MainLoop                       ; Return to main filename input loop.

; ============================================================================
; Function: CheckCommands
; Purpose : Parse input commands ("exit") or process the specified filename.
; ============================================================================
CheckCommands:
	cmpi.l   #$65786974,(a0)                ; Check if the input string is "exit" (hex for "exit").
	beq.w    CleanUpAndExit                 ; Jump to exit routine if the user wants to quit.
	move.l   #Var_InputBuffer,d1            ; Pass the input buffer containing the filename.
	move.l   #$3ed,d2                       ; Set file open mode to MODE_OLDFILE (shared read, $3ed = 1005).
	jsr      -$1e(a6)                       ; Open the specified source file.
	move.l   d0,Var_FileHandle.l            ; Save the returned file handle.
	beq.w    MainLoop                       ; Jump back to CLI loop if file open failed.
	move.l   Var_FileHandle(pc),d1          ; Load the opened file handle.
	move.l   Var_SourceBuffer(pc),d2        ; Load the source file buffer pointer.
	move.l   Var_WorkspaceSize(pc),d3       ; Load the workspace buffer size.
	subi.l   #$80,d3                        ; Reserve 128 bytes of safety margin in the buffer.
	jsr      -$2a(a6)                       ; Read the file contents into the source buffer.
	move.l   d0,Var_OriginalLength.l        ; Save the actual read file size as original length.
	move.l   Var_FileHandle(pc),d1          ; Load the opened file handle.
	jsr      -$24(a6)                       ; Close the file handle after reading.
	move.l   Var_WorkspaceSize(pc),d0       ; Load the workspace buffer size.
	subi.l   #$80,d0                        ; Subtract the 128-byte safety margin.
	cmp.l    Var_OriginalLength(pc),d0      ; Check if the file is larger than the available buffer.
	bls.w    MainLoop                       ; Jump back to CLI loop if the file is too big to fit.
	movea.l  Var_DOSBase(pc),a6             ; Set up DOSBase pointer in a6 for library call.
	move.l   Var_StdinHandle(pc),d1         ; Load standard input stream handle.
	move.l   #Str_OrigLen,d2                ; Point d2 to "ORIGINAL LENGTH: " status label string.
	move.l   #$11,d3                        ; Specify prompt message size for output (17 bytes).
	jsr      -$30(a6)                       ; Write message string to standard output stream.
	move.l   Var_OriginalLength(pc),d0      ; Load the original file size.
	bsr.w    ConvertLongToHex               ; Convert the size to a hexadecimal string and print it.

; ============================================================================
; Function: AskDepackAddress
; Purpose : Prompt user for the decompression address.
; ============================================================================
AskDepackAddress:
	movea.l  Var_DOSBase(pc),a6             ; Set up DOSBase pointer in a6 for library call.
	move.l   Var_StdinHandle(pc),d1         ; Load standard input stream handle.
	move.l   #Str_DepackAt,d2               ; Point d2 to "DEPACK AT: " prompt string.
	move.l   #$b,d3                         ; Specify size of prompt string (11 bytes).
	jsr      -$30(a6)                       ; Write prompt message to standard output stream.
	bsr.w    ClearInputBuffer               ; Clear the input buffer.
	move.l   Var_StdoutHandle(pc),d1        ; Load standard output stream handle.
	move.l   #Var_InputBuffer,d2            ; Point d2 to the input buffer for user response.
	moveq    #$1e,d3                        ; Set maximum expected character read size to 30 bytes.
	jsr      -$2a(a6)                       ; Read user input string from standard input stream.
	cmpi.l   #$1,d0                         ; Check if any characters were actually read.
	bls.b    AskDepackAddress               ; Prompt again if input was empty.
	moveq    #$5,d0                         ; Set expected hexadecimal string length.
	bsr.w    ConvertHexToLong               ; Convert the input hex string to a longword address.
	move.l   d0,Var_DepackAddress.l         ; Save the target decompression address.
	move.l   d0,Var_DepackAddressCopy.l     ; Save a copy of the target decompression address.
	move.l   d0,Var_DepackAddressCopy2.l    ; Save a second copy of the target decompression address.

; ============================================================================
; Function: AskLocateAddress
; Purpose : Prompt user for the load address.
; ============================================================================
AskLocateAddress:
	movea.l  Var_DOSBase(pc),a6             ; Set up DOSBase pointer in a6 for library call.
	move.l   Var_StdinHandle(pc),d1         ; Load standard input stream handle.
	move.l   #Str_LocateFile,d2             ; Point d2 to "LOCATE FILE AT: " prompt string.
	move.l   #$10,d3                        ; Specify size of prompt string (16 bytes).
	jsr      -$30(a6)                       ; Write prompt message to standard output stream.
	move.l   Var_StdoutHandle(pc),d1        ; Load standard output stream handle.
	move.l   #Var_InputBuffer,d2            ; Point d2 to the input buffer for user response.
	moveq    #$1e,d3                        ; Set maximum expected character read size to 30 bytes.
	jsr      -$2a(a6)                       ; Read user input string from standard input stream.
	cmpi.l   #$1,d0                         ; Check if any characters were actually read.
	bls.b    AskLocateAddress               ; Prompt again if input was empty.
	moveq    #$5,d0                         ; Set expected hexadecimal string length.
	bsr.w    ConvertHexToLong               ; Convert the input hex string to a longword address.
	move.l   d0,Var_LoadAddress.l           ; Save the target load address.
	lea      Depacker_ConfigTable(pc),a3    ; Point a3 to the decruncher loader configuration block.
	subq.l   #$1,d0                         ; Adjust load address for block start.
	move.l   d0,$2(a3)                      ; Patch target decompression address into loader instruction.

; ============================================================================
; Function: AskJmpAddress
; Purpose : Prompt user for the execution jump address after decompression.
; ============================================================================
AskJmpAddress:
	movea.l  Var_DOSBase(pc),a6             ; Set up DOSBase pointer in a6 for library call.
	move.l   Var_StdinHandle(pc),d1         ; Load standard input stream handle.
	move.l   #Str_JmpTo,d2                  ; Point d2 to "JMP TO: " prompt string.
	move.l   #$8,d3                         ; Specify size of prompt string (8 bytes).
	jsr      -$30(a6)                       ; Write prompt message to standard output stream.
	move.l   Var_StdoutHandle(pc),d1        ; Load standard output stream handle.
	move.l   #Var_InputBuffer,d2            ; Point d2 to the input buffer for user response.
	moveq    #$1e,d3                        ; Set maximum expected character read size to 30 bytes.
	jsr      -$2a(a6)                       ; Read user input string from standard input stream.
	cmpi.l   #$1,d0                         ; Check if any characters were actually read.
	bls.b    AskJmpAddress                  ; Prompt user again for valid program entry point if empty.
	moveq    #$5,d0                         ; Set expected hexadecimal string length.
	bsr.w    ConvertHexToLong               ; Convert the input hex string to a longword address.
	move.l   d0,Var_JmpAddress.l            ; Save the execution jump address.
	move.l   Var_LoadAddress(pc),d0         ; Load the target load address.
	add.l    Var_OriginalLength(pc),d0      ; Calculate the end address of the original data block.
	lea      Depacker_ConfigTable(pc),a3    ; Point a3 to the decruncher loader configuration block.
	move.l   d0,$8(a3)                      ; Patch program end address into loader instruction.
	movea.l  Var_SourceBuffer(pc),a0        ; Load the source file buffer pointer.
	movea.l  Var_OriginalLength(pc),a1      ; Load the original file size.
	adda.l   Var_SourceBuffer(pc),a1        ; Point a1 to the end of the source file buffer.
	movea.l  ExecBase.l,a6                  ; Load ExecBase for the following Exec calls.
	lea      CUSTOM.l,a5                    ; Point a5 to the Custom Chip register base.
	jsr      -$84(a6)                       ; Disable Exec multi-tasking (Forbid) to prevent race conditions during packing.
	move.w   #$4000,$9a(a5)                 ; Disable system custom interrupts (INTENA) during compression.
	move.w   #$7ff,$96(a5)                  ; Disable system DMA channels (DMACON) during compression.
	clr.w    $dff100.l                      ; Set BPLCON0 to zero to turn off screen display.
	bsr.w    RLE_Compress                   ; Call subroutine to RLE compress the data.
	lea      Depacker_ConfigTable(pc),a3    ; Point a3 to the decruncher loader configuration block.
	move.b   d7,$15(a3)                     ; Patch optimal RLE escape marker byte into decruncher.
	move.l   d0,d7                          ; Save final crunched payload end address.
	sub.l    Var_PackedBuffer(pc),d7        ; Calculate the size of the packed payload.
	subi.l   #$80,d7                        ; Subtract the 128-byte safety margin.
	add.l    Var_LoadAddress(pc),d7         ; Add the load address to get the absolute packed end address.
	move.l   d7,$e(a3)                      ; Patch compressed data source start address into loader.
	btst     #$0,d0                         ; Check if the end address is on an odd byte boundary.
	beq.b    PatchDepacker                  ; If even, proceed to apply depacker header setup and alignment.
	addq.l   #$1,d7                         ; Round up the packed end address to an even boundary.
	addq.l   #$1,d0                         ; Round up the output buffer pointer to an even boundary.
PatchDepacker:
	move.l   d7,Depacker_Entry.l            ; Set decruncher loading/relocation entry address.
	lea      Depacker_StubData(pc),a0       ; Point a0 to the decruncher bootstrap stub data.
	lea      RLE_Compress(pc),a1            ; Point a1 to the end of the decruncher stub data.
	movea.l  d0,a2                          ; Point a2 to destination output crunched buffer.
CopyDepackerStubLoop:
	move.w   (a0)+,(a2)+                    ; Copy decruncher bootstrap stub word to destination buffer.
	cmpa.l   a1,a0                          ; Check if we have copied all the stub data.
	bcs.b    CopyDepackerStubLoop           ; Loop to copy self-relocating bootstrap stub.
	move.l   a2,d2                          ; Save output buffer write end pointer.
	sub.l    Var_SourceBuffer(pc),d2        ; Calculate the new size.
	move.l   d2,Var_OriginalLength.l        ; Update original length with the newly packed size.
	move.l   Var_LoadAddress(pc),Depacker_PackedLen.l ; Patch the load address into the loader.
	movea.l  ExecBase.l,a6                  ; Load ExecBase for the following Exec calls.
	lea      CUSTOM.l,a5                    ; Point a5 to the Custom Chip register base.
	move.w   #$c000,$9a(a5)                 ; Re-enable master and vertical blank interrupts (INTENA).
	move.w   #$83f0,$96(a5)                 ; Re-enable essential custom DMA channels (DMACON: copper, blitter, sprites).
	jsr      -$8a(a6)                       ; Re-enable Exec multi-tasking (Permit) upon compression process completion.
	bsr.w    ClearInputBuffer               ; Clear the input buffer.
	movea.l  Var_DOSBase(pc),a6             ; Set up DOSBase pointer in a6 for library call.
	move.l   Var_StdinHandle(pc),d1         ; Load standard input stream handle.
	move.l   #Str_PackedLen,d2              ; Point d2 to "PACKED LENGTH: " display string.
	move.l   #$11,d3                        ; Specify prompt message size for output (17 bytes).
	jsr      -$30(a6)                       ; Write message string to standard output stream.
	move.l   Var_OriginalLength(pc),d0      ; Load the packed file size.
	bsr.w    ConvertLongToHex               ; Convert the size to a hexadecimal string and print it.

; ============================================================================
; Function: AskOffsetMax
; Purpose : Prompt user for the maximum LZ77 match offset distance.
; ============================================================================
AskOffsetMax:
	movea.l  Var_DOSBase(pc),a6             ; Set up DOSBase pointer in a6 for library call.
	move.l   Var_StdinHandle(pc),d1         ; Load standard input stream handle.
	move.l   #Str_OffsetMax,d2              ; Point d2 to "MAX. OFFSET(100-8000):" prompt string.
	move.l   #$16,d3                        ; Specify size of prompt string (22 bytes).
	jsr      -$30(a6)                       ; Write prompt message to standard output stream.
	bsr.w    ClearInputBuffer               ; Clear the input buffer.
	move.l   Var_StdoutHandle(pc),d1        ; Load standard output stream handle.
	move.l   #Var_InputBuffer,d2            ; Point d2 to the input buffer for user response.
	moveq    #$5,d3                         ; Set maximum expected input characters limit.
	jsr      -$2a(a6)                       ; Read user input string from standard input stream.
	cmpi.l   #$1,d0                         ; Check if any characters were actually read.
	bls.b    AskOffsetMax                   ; Prompt user again for valid maximum offset if empty.
	moveq    #$3,d0                         ; Set hexadecimal parsing limit to 3 characters.
	bsr.w    ConvertHexToLong               ; Convert the input hex string to a longword value.
	cmpi.w   #$8000,d0                      ; Check if the requested offset is within the 32KB ($8000) limit.
	bhi.b    AskOffsetMax                   ; Prompt user again if maximum offset is too high.
	bclr     #$0,d0                         ; Ensure the maximum offset is an even number (clear bit 0).
	move.l   d0,Var_WindowSize.l            ; Save search history window limit.
	clr.l    d1                             ; Clear d1 to count the number of bits needed for the offset.
	move.l   d0,d2                          ; Store computed max offset bits value in d2.
	mulu.w   #$2,d2                         ; Multiply window size by 2 to get maximum search distance.
	lea      LZ77_BitsTable(pc),a0          ; Point a0 to the LZ77 parameters configuration table.
	move.w   d2,$6(a0)                      ; Patch max offset parameter into loader bits table.
	divu.w   #$2,d2                         ; Halve max distance to derive match length bit threshold.
	divu.w   #$2,d2                         ; Halve again to derive match length threshold.
	move.w   d2,$4(a0)                      ; Patch match length bits into loader config table.
	divu.w   #$2,d2                         ; Halve one more time to get the default window bit size.
	move.w   d2,$2(a0)                      ; Patch window size bits into loader config table.
	move.w   #$100,$0(a0)                   ; Set default history window boundary value ($100).
CalcOffsetBitsLoop:
	addq.w   #$1,d1                         ; Increment bit counter.
	lsr.w    #$1,d0                         ; Shift right by 1 to count bits.
	cmpi.w   #$1,d0                         ; Loop until the value is shifted out.
	bne.b    CalcOffsetBitsLoop             ; Continue shifting until d0 equals 1.
	addq.w   #$1,d1                         ; Adjust bit count by +1.
	move.w   d1,$e(a0)                      ; Patch maximum offset bits configuration into decruncher loader.
	move.b   d1,Depacker_SmallMatchBits.l   ; Save small match offset bit size parameter.
	subq.w   #$2,d1                         ; Subtract 2 to calculate small match parameter.
	move.w   d1,$c(a0)                      ; Patch small match parameter into loader table.
	subq.w   #$1,d1                         ; Subtract 1 more to calculate large match parameter.
	move.w   d1,$a(a0)                      ; Patch large match parameter into loader table.
	move.b   d1,Depacker_LargeMatchBits.l   ; Save large match offset bit size parameter.
	subq.w   #$1,d1                         ; Final decrement for escape marker.
	move.w   #$8,$8(a0)                     ; Patch default marker/escape threshold parameter to 8 bits.
	move.b   #$8,Depacker_MarkerByte.l      ; Save escape marker bit size parameter (8 bits).
	bsr.w    ClearInputBuffer               ; Clear the input buffer.
	movea.l  ExecBase.l,a6                  ; Load ExecBase for the following Exec calls.
	lea      CUSTOM.l,a5                    ; Point a5 to the Custom Chip register base.
	jsr      -$84(a6)                       ; Disable Exec multi-tasking (Forbid) to prevent race conditions during packing.
	move.w   #$4000,$9a(a5)                 ; Disable system custom interrupts (INTENA) during compression.
	move.w   #$7ff,$96(a5)                  ; Disable system DMA channels (DMACON) during compression.
	clr.w    $dff100.l                      ; Set BPLCON0 to zero to turn off screen display.
	bsr.w    LZ77_Compress                  ; Call subroutine to perform LZ77 compression on the data.
	movea.l  Var_PackedBuffer(pc),a0        ; Load packed output buffer pointer.
	move.l   Var_PackedLength(pc),(a0)      ; Save the actual packed length at the start of the output buffer.
	movea.l  ExecBase.l,a6                  ; Load ExecBase for the following Exec calls.
	lea      CUSTOM.l,a5                    ; Point a5 to the Custom Chip register base.
	move.w   #$c000,$9a(a5)                 ; Re-enable master and vertical blank interrupts (INTENA).
	move.w   #$83f0,$96(a5)                 ; Re-enable essential custom DMA channels (DMACON: copper, blitter, sprites).
	jsr      -$8a(a6)                       ; Re-enable Exec multi-tasking (Permit) upon compression process completion.
	movea.l  Var_DOSBase(pc),a6             ; Set up DOSBase pointer in a6 for library call.
	move.l   Var_StdinHandle(pc),d1         ; Load standard input stream handle.
	move.l   #Str_PackedLen,d2              ; Point d2 to "PACKED LENGTH: " display string.
	move.l   #$11,d3                        ; Specify prompt message size for output (17 bytes).
	jsr      -$30(a6)                       ; Write message string to standard output stream.
	move.l   Var_PackedLength(pc),d0        ; Load the raw packed payload size (excludes the 12-byte metadata header).
	addi.l   #$c,d0                         ; Add 12 bytes ($c) to include the payload's 3-longword metadata header block.
	bsr.w    ConvertLongToHex               ; Convert the total packed block size to hex and print to CLI.
	move.l   Var_DepackAddress(pc),d0       ; Load the decompression address.
	move.l   d0,Depacker_OrigLen.l          ; Inject original uncompressed size (used here to temporarily hold depack address).
	move.l   d0,Depacker_JmpAddr.l          ; Inject target program entry jump address into loader.

; ============================================================================
; Function: AskExeOrData
; Purpose : Prompt user to choose between executable (E) or data (D) output format.
; ============================================================================
AskExeOrData:
	movea.l  Var_DOSBase(pc),a6             ; Set up DOSBase pointer in a6 for library call.
	move.l   Var_StdinHandle(pc),d1         ; Load standard input stream handle.
	move.l   #Str_ExeOrData,d2              ; Point d2 to "(E)XE. OR (D)ATA ?:" prompt string.
	move.l   #$20,d3                        ; Set string length for Str_ExeOrData (32 bytes).
	jsr      -$30(a6)                       ; Write prompt message to standard output stream.
	move.l   Var_StdoutHandle(pc),d1        ; Load standard output stream handle.
	move.l   #Var_InputBuffer,d2            ; Point d2 to the input buffer for user response.
	moveq    #$1e,d3                        ; Set maximum expected character read size to 30 bytes.
	jsr      -$2a(a6)                       ; Read user input string from standard input stream.
	cmpi.l   #$1,d0                         ; Check if any characters were actually read.
	bls.b    AskExeOrData                   ; Prompt user again for valid file type mode if empty.
	lea      Var_InputBuffer(pc),a0         ; Point a0 to the input buffer.
	cmpi.b   #$64,(a0)                      ; Check if user entered 'd' for DATA.
	beq.w    AskSaveFilename                ; If 'd', skip prepending executable decruncher header.
	cmpi.b   #$65,(a0)                      ; Check if user entered 'e' for EXE.
	bne.b    AskExeOrData                   ; If neither, ask again.
	movea.l  Var_PackedBuffer(pc),a0        ; Load packed output buffer pointer.
	adda.l   Var_PackedLength(pc),a0        ; Point a0 to the end of the packed data.
	adda.l   #$c,a0                         ; Adjust pointer past the first 12 bytes of payload header space.
	movea.l  a0,a1                          ; Copy end pointer of packed payload to a1.
	adda.l   #$134,a1                       ; Add 308 bytes ($134) to a1 to reserve space for the decruncher header stub.
	movea.l  a1,a2                          ; Back up loader destination end pointer to a2.
	move.l   Var_PackedLength(pc),d0        ; Load the raw packed payload size.
	addi.l   #$c,d0                         ; Add 12 bytes to include the payload's metadata header in the backward shift.
	move.l   d0,d1                          ; Copy total shift block size (Var_PackedLength + 12) to d1.
	swap     d1                             ; Swap halves to split the 32-bit count into two 16-bit counts.
	bra.b    AskExeOrData_ShiftLoopEntry    ; Jump to the shift loop entry condition.
DepackerCopyLoop:
	move.b   -(a0),-(a1)                    ; Shift the packed block backwards in memory to make room at the front.
AskExeOrData_ShiftLoopEntry:
	dbra     d0,DepackerCopyLoop            ; Inner loop to copy bottom 16 bits of size count.
	dbra     d1,DepackerCopyLoop            ; Outer loop to copy top 16 bits of size count.
 
	; --- Copy Decruncher Headers and Executable Stub to Output Buffer ---
	lea      Depacker_HunkStart+2(pc),a0    ; Point a0 to the start of AmigaDOS Hunk headers template.
	movea.l  Var_PackedBuffer(pc),a1        ; Point a1 to the beginning of the output buffer.
	move.w   #$133,d0                       ; Set copy counter to 308 bytes ($133 + 1) for the decruncher header and loader stub.
.copy_stub_loop:
	move.b   (a0)+,(a1)+                    ; Copy one byte of the decruncher header/stub into the output buffer.
	dbra     d0,.copy_stub_loop             ; Loop until all 308 header bytes are copied.
	move.l   a2,d0                          ; Store the address of the end of the written data.
	sub.l    Var_PackedBuffer(pc),d0        ; Calculate the total size in bytes (headers + compressed payload).
	subi.l   #$24,d0                        ; Subtract 36 ($24) bytes to exclude the initial Amiga DOS hunk headers.
	move.l   d0,d1                          ; Copy payload size in bytes to d1 for alignment and size calculations.
	divu.w   #$4,d1                         ; Divide size by 4: quotient (longwords) to low word, remainder (0-3 bytes) to high.
	swap     d1                             ; Swap halves so the remainder is in the low word for testing.
	tst.b    d1                             ; Test if the remainder is non-zero (i.e. not longword aligned).
	beq.b    .aligned                       ; If the remainder is zero, the payload is already longword aligned.
	addi.l   #$2,d0                         ; Add 2 bytes to round up (since compressed data is always word/even-aligned).
	move.l   d0,d1                          ; Store the rounded payload size in bytes back to d1.
	divu.w   #$4,d1                         ; Divide the rounded size by 4 to get the padded quotient in the low word.
	swap     d1                             ; Swap quotient to high word so it is aligned with the branch target.
.aligned:
	swap     d1                             ; Swap back so d1 contains the final hunk payload size in longwords (low word).
	movea.l  Var_PackedBuffer(pc),a0        ; Load base address of the output buffer containing the hunk headers.
	move.l   d1,$14(a0)                     ; Patch the Code hunk size in HUNK_HEADER (offset $14 = 20).
	move.l   d1,$20(a0)                     ; Patch the Code hunk size in HUNK_CODE block header (offset $20 = 32).
	addi.l   #$24,d0                        ; Re-add the 36 ($24) bytes of hunk headers to get the actual total file size.
	movea.l  d0,a2                          ; Store actual final byte size into a2 temporarily.
	adda.l   a0,a2                          ; Point a2 to the end of the packed data in the buffer.
	addi.l   #$18,d0                        ; Add $18 to final size.
	subi.l   #$c,d0                         ; Subtract $c to final size.
	move.l   d0,Var_PackedLength.l          ; Store the final calculated file length to write out.
	lea      Depacker_RelocStart(pc),a0     ; Point a0 to the relocator entry stub code.
	movea.l  a2,a1                          ; Point a1 to the end of the packed data.
	moveq    #$17,d0                        ; Set copy counter to 24 bytes for relocator stub.
.copy_entry_loop:
	move.b   (a0)+,(a1)+                    ; Copy relocator stub to the very end of the packed file.
	dbra     d0,.copy_entry_loop            ; Loop until stub is fully copied.

; ============================================================================
; Function: AskSaveFilename
; Purpose : Prompt user for the output filename to save the crunched data.
; ============================================================================
AskSaveFilename:
	movea.l  Var_DOSBase(pc),a6             ; Set up DOSBase pointer in a6 for library call.
	move.l   Var_StdinHandle(pc),d1         ; Load standard input stream handle.
	move.l   #Str_Save,d2                   ; Point d2 to "SAVE AS : " prompt string.
	move.l   #$6,d3                         ; Specify size of load prompt string (6 bytes).
	jsr      -$30(a6)                       ; Write prompt message to standard output stream.
	move.l   Var_StdoutHandle(pc),d1        ; Load standard output stream handle.
	move.l   #Var_InputBuffer,d2            ; Point d2 to the input buffer for user response.
	moveq    #$1e,d3                        ; Set maximum expected character read size to 30 bytes.
	jsr      -$2a(a6)                       ; Read user input string from standard input stream.
	cmpi.l   #$1,d0                         ; Check if any characters were actually read.
	bls.b    AskSaveFilename                ; Prompt user again for output save filename if empty.
	subq.l   #$1,d0                         ; Decrement byte count to point to the last character.
	lea      Var_InputBuffer(pc),a0         ; Point a0 to the input buffer.
	adda.l   d0,a0                          ; Add byte count to reach the end of the input string.
	clr.b    (a0)                           ; Null-terminate the string by replacing the newline.
	lea      Var_InputBuffer(pc),a0         ; Point a0 back to the start of the input buffer.
	cmpi.b   #$2d,(a0)                      ; Check if the input starts with '-' indicating a command.
	bne.b    SaveCrunchedFile               ; Proceed to save if it is a normal filename.
	addq.l   #$1,a0                         ; Skip the '-' prefix to read the following command string.
	move.l   a0,d1                          ; Pass the command string pointer to FPuts.
	moveq    #$0,d2                         ; Clear d2 for FPuts (unused parameter).
	move.l   Var_StdinHandle(pc),d3         ; Pass standard input stream handle.
	jsr      -$de(a6)                       ; Print the command string to output.
	bra.b    AskSaveFilename                ; Prompt user again for output save filename.

; ============================================================================
; Function: SaveCrunchedFile
; Purpose : Open the output file, write the compressed data, and close it.
; ============================================================================
SaveCrunchedFile:
	cmpi.l   #$65786974,(a0)                ; Check if the input string is "exit" (hex for "exit").
	beq.w    CleanUpAndExit                 ; Jump to exit routine if the user wants to quit.
	move.l   #Var_InputBuffer,d1            ; Pass the input buffer containing the filename.
	move.l   #$3ee,d2                       ; Set file open mode to MODE_NEWFILE (create new, $3ee = 1006).
	jsr      -$1e(a6)                       ; Open the specified output file for writing.
	move.l   d0,Var_FileHandle.l            ; Save the returned file handle.
	move.l   d0,d1                          ; Copy file handle for write operation.
	move.l   Var_PackedBuffer(pc),d2        ; Load the packed output buffer pointer.
	move.l   Var_PackedLength(pc),d3        ; Load the calculated packed file length.
	addi.l   #$c,d3                         ; Add 12 bytes for decruncher headers (not applicable if DATA).
	jsr      -$30(a6)                       ; Write packed data payload to output file.
	cmpi.l   #$ffffffff,d0                  ; Check if the file write failed (-1).
	beq.w    AskSaveFilename                ; Prompt user again if the write operation failed.
	move.l   Var_FileHandle(pc),d1          ; Load the opened file handle.
	jsr      -$24(a6)                       ; Close the output file handle.

; ============================================================================
; Function: AskSaveAgain
; Purpose : Ask the user if they want to load and crunch another file.
; ============================================================================
AskSaveAgain:
	movea.l  Var_DOSBase(pc),a6             ; Set up DOSBase pointer in a6 for library call.
	move.l   Var_StdinHandle(pc),d1         ; Load standard input stream handle.
	move.l   #Str_SaveAgain,d2              ; Point d2 to "CRUNCH ANOTHER (Y/N) ? :" prompt string.
	move.l   #$12,d3                        ; Specify size of prompt string (18 bytes).
	jsr      -$30(a6)                       ; Write prompt message to standard output stream.
	move.l   Var_StdoutHandle(pc),d1        ; Load standard output stream handle.
	move.l   #Var_InputBuffer,d2            ; Point d2 to the input buffer for user response.
	moveq    #$1e,d3                        ; Set maximum expected character read size to 30 bytes.
	jsr      -$2a(a6)                       ; Read user input string from standard input stream.
	cmpi.l   #$1,d0                         ; Check if any characters were actually read.
	bls.b    AskSaveAgain                   ; Prompt again if input was empty.
	subq.l   #$1,d0                         ; Decrement byte count to point to the last character.
	lea      Var_InputBuffer(pc),a0         ; Point a0 to the input buffer.
	adda.l   d0,a0                          ; Add byte count to reach the end of the input string.
	clr.b    (a0)                           ; Null-terminate the string by replacing the newline.
	lea      Var_InputBuffer(pc),a0         ; Point a0 back to the start of the input buffer.
	cmpi.b   #$79,(a0)                      ; Check if user entered 'y' for YES.
	beq.w    AskSaveFilename                ; If 'y', loop back to prompt for output filename again.

; ============================================================================
; Function: CleanUpAndExit
; Purpose : Free all allocated memory and exit the program gracefully.
; ============================================================================
CleanUpAndExit:
	btst     #$0,Var_SlowMemFlag.l          ; Check if we allocated from Slow memory.
	bne.b    FreeAllMem                     ; Branch directly to freeing Exec memory.
	movea.l  ExecBase.l,a6                  ; Load ExecBase for the following Exec calls.
	move.l   Var_WorkspaceSize(pc),d0       ; Load the size of the allocated workspace buffer.
	movea.l  Var_PackedBuffer(pc),a1        ; Load the pointer to the workspace buffer.
	jsr      -$d2(a6)                       ; Call FreeMem to release the main workspace memory.
FreeAllMem:
	movea.l  ExecBase.l,a6                  ; Load ExecBase for the following Exec calls.
	movea.l  Var_DOSBase(pc),a1             ; Load DOSBase pointer.
	jsr      -$19e(a6)                      ; Call CloseLibrary to close dos.library.
	clr.l    d0                             ; Clear d0 to indicate successful exit code 0.
	rts                                     ; Return to caller (OS).

; ============================================================================
; Function: ConvertHexToLong
; Purpose : Convert an ASCII hexadecimal string to a long integer.
; ============================================================================
ConvertHexToLong:
	movem.l  d1-d7/a0-a6,-(a7)              ; Save all registers to stack.
	move.l   d0,d3                          ; Copy string length to d3 for loop counter.
	clr.l    d0                             ; Clear d0.
	clr.l    d1                             ; Clear d1 (current character value).
	clr.l    d2                             ; Clear d2 (accumulator).
	lea      Var_InputBuffer(pc),a0         ; Point a0 to the string to convert.
ConvertHexToLongLoop:
	move.b   (a0)+,d1                       ; Read a character from the string.
	bsr.b    FindCharInHexTable             ; Call helper to get numeric value of hex character.
	andi.w   #$f,d1                         ; Mask to keep only the 4 bits of the hex digit.
	lsl.l    #$4,d2                         ; Shift accumulator left by 1 nibble (4 bits).
	or.w     d1,d2                          ; Or the new digit into the accumulator.
	cmpi.b   #$a,(a0)                       ; Check if the next character is a newline.
	beq.b    ConvertHexToLongEnd            ; If newline, conversion is complete.
	dbra     d3,ConvertHexToLongLoop        ; Loop for all expected characters.
ConvertHexToLongEnd:
	move.l   d2,d0                          ; Move the accumulated result to d0.
	movem.l  (a7)+,d1-d7/a0-a6              ; Restore all registers from stack.
	rts                                     ; Return from subroutine.

; ============================================================================
; Function: FindCharInHexTable
; Purpose : Helper to map ASCII character to its hex value using Str_HexTable.
; ============================================================================
FindCharInHexTable:
	movem.l  d0/a0,-(a7)                    ; Save d0 and a0 to stack.
	moveq    #$0,d0                         ; Clear d0 (table index).
	lea      Str_HexTable(pc),a0            ; Point a0 to the hex character lookup table.
FindCharInHexTableLoop:
	cmp.b    (a0,d0.l),d1                   ; Compare current character (d1) with table entry.
	beq.b    FindCharInHexTableEnd          ; If matched, exit loop.
	addq.l   #$1,d0                         ; Increment table index.
	cmpi.l   #$10,d0                        ; Check if we checked all 16 hex digits.
	bcs.b    FindCharInHexTableLoop         ; If not, continue checking next digit in table.
FindCharInHexTableEnd:
	move.l   d0,d1                          ; Return the numeric value in d1.
	movem.l  (a7)+,d0/a0                    ; Restore d0 and a0 from stack.
	rts                                     ; Return from subroutine.

; ============================================================================
; Function: ConvertLongToHex
; Purpose : Convert a long integer to an ASCII hexadecimal string and print it.
; ============================================================================
ConvertLongToHex:
	movem.l  d0-d7/a0-a6,-(a7)              ; Save all registers to stack.
	lea      Var_InputBuffer(pc),a0         ; Point a0 to the output buffer.
	adda.l   #$a,a0                         ; Adjust pointer to the end of the 8-digit buffer + 2 bytes for \n and '$'.
	lea      Str_HexTable(pc),a1            ; Point a1 to the hex character lookup table.
	move.b   #$a,-(a0)                      ; Write newline character at the end of the string.
	moveq    #$8,d2                         ; Set loop counter for 8 hex digits (1 longword).
ConvertLongToHexLoop:
	move.l   d0,d1                          ; Copy value to d1.
	andi.l   #$f,d1                         ; Extract the lowest 4 bits (1 nibble).
	move.b   (a1,d1.l),-(a0)                ; Lookup hex character and write it to the buffer backwards.
	lsr.l    #$4,d0                         ; Shift right by 4 bits for the next nibble.
	dbra     d2,ConvertLongToHexLoop        ; Loop until all 8 digits are converted.
	move.b   #$24,(a0)                      ; Prepend '$' character to indicate hexadecimal.
	move.l   Var_StdinHandle(pc),d1         ; Load standard input stream handle (or standard output if intended).
	move.l   #Var_InputBuffer,d2            ; Point d2 to the formatted string buffer.
	moveq    #$a,d3                         ; Set string length to 10 bytes (1 for '$', 8 digits, 1 for \n).
	jsr      -$30(a6)                       ; Write formatted message string to standard output stream.
	movem.l  (a7)+,d0-d7/a0-a6              ; Restore all registers from stack.
	rts                                     ; Return from subroutine.

; ============================================================================
; Function: LZ77_Compress
; Purpose : Primary compression routine implementing LZ77 algorithm logic.
; ============================================================================
LZ77_Compress:
	movea.l  Var_SourceBuffer.l,a0          ; Point a0 to the uncompressed source buffer.
	movea.l  Var_SourceBuffer.l,a1          ; Point a1 to the source buffer (used to calculate end address).
	adda.l   Var_OriginalLength.l,a1        ; Point a1 to the end of the uncompressed source buffer.
	movea.l  Var_PackedBuffer.l,a2          ; Point a2 to the compressed output buffer.
	move.l   #$0,(a2)+                      ; Initialize temporary size/stats placeholder in output stream.
	move.l   Var_OriginalLength(pc),(a2)+   ; Store original uncompressed file size in output stream.
	move.l   #$0,(a2)+                      ; Initialize second temporary size/stats placeholder.
	moveq    #$1,d2                         ; Initialize control bit stream register, pre-set marker bit.
	clr.w    d1                             ; Clear d1 (current literal count).
	clr.l    d7                             ; Clear d7 (general counter).
LZ77_CompressLoop:
	bsr.w    LZ77_FindMatch                 ; Search for repeating byte sequences in the sliding window.
	tst.b    d0                             ; Check if a literal was encoded (d0 = 1) or a match was encoded (d0 = 0).
	beq.b    .next_iteration                ; If a match was encoded, skip literal buffering and proceed to next byte.
	addq.w   #$1,d1                         ; If a literal was encoded, increment the pending literal counter.
	cmpi.w   #$108,d1                       ; Check if the pending literal count has reached maximum capacity (264 bytes).
	bne.b    .next_iteration                ; If the literal counter is below the limit, proceed to the next iteration.
	bsr.w    LZ77_OutputLiterals            ; Flush the accumulated literals to the output stream to prevent overflow.
.next_iteration:
	cmpa.l   a0,a1                          ; Check if we have processed all uncompressed source bytes.
	bgt.b    LZ77_CompressLoop              ; If more bytes remain, continue the compression loop.
	bsr.w    LZ77_OutputLiterals            ; Finalize compression by flushing any remaining literal bytes.
	bsr.w    LZ77_OutputBitsFillWord        ; Pad the remaining bits in the control word to align to next boundary.
	move.l   a2,d0                          ; Get final pointer to the end of compressed output.
	sub.l    Var_PackedBuffer(pc),d0        ; Calculate total size of compressed payload.
	subi.l   #$c,d0                         ; Subtract 12 bytes for header placeholders to get raw compressed size.
	move.l   d0,Var_PackedLength.l          ; Save the final compressed payload length.
	movea.l  Var_PackedBuffer(pc),a3        ; Point a3 back to the start of the compressed output buffer.
	move.l   d7,$8(a3)                      ; Save total match count / statistics parameter.
	move.l   d0,$0(a3)                      ; Save final compressed size parameter.
	clr.l    d0                             ; Clear temporary register.
	clr.l    d1                             ; Clear temporary register.
	clr.l    d2                             ; Clear temporary register.
	clr.l    d3                             ; Clear temporary register.
	clr.l    d4                             ; Clear temporary register.
	clr.l    d5                             ; Clear temporary register.
	lea      Var_CompressStats(pc),a3       ; Point a3 to compression statistics/configuration block.
	movem.w  (a3)+,d0-d5                    ; Load various configuration parameters for potential post-processing.
	movea.l  a2,a3                          ; Save final output pointer to a3.
	suba.l   a0,a3                          ; Unused logic (likely dead code calculating pointer differences).
	movea.l  Var_SourceBuffer(pc),a4        ; Unused logic.
	adda.l   Var_OriginalLength(pc),a4      ; Unused logic.
	suba.l   a2,a4                          ; Unused logic.
	rts                                     ; Return from subroutine.

; ============================================================================
; Function: LZ77_FindMatch
; Purpose : Search the LZ77 sliding dictionary window for a matching byte sequence.
; ============================================================================
LZ77_FindMatch:
	movea.l  a0,a3                          ; Point a3 to current position in source buffer.
	adda.l   Var_WindowSize(pc),a3          ; Add sliding window limit to calculate max search distance.
	cmpa.l   a1,a3                          ; Check if the max distance exceeds the end of the source buffer.
	ble.b    LZ77_FindMatchInit             ; If not, keep the calculated distance.
	movea.l  a1,a3                          ; If it does, limit the search distance to the end of the buffer.
LZ77_FindMatchInit:
	moveq    #$1,d5                         ; Initialize best match length counter to 1 byte.
	movea.l  a0,a5                          ; Point a5 to current position (start of dictionary history).
	addq.w   #$1,a5                         ; Increment a5 to start searching ahead.
LZ77_FindMatchLoop:
	move.b   (a0),d3                        ; Load the first byte of the sequence we want to find.
	move.b   $1(a0),d4                      ; Load the second byte of the sequence.
LZ77_CompareLoop:
	cmp.b    (a5)+,d3                       ; Scan the dictionary history for the first byte.
	bne.b    .check_search_bounds           ; If not found, skip to loop check.
	cmp.b    (a5),d4                        ; If first byte found, check if the second byte matches too.
	beq.b    LZ77_MatchFound                ; If both match, jump to sequence length comparison.
.check_search_bounds:
	cmpa.l   a5,a3                          ; Check if we've searched the entire allowed distance.
	bgt.b    LZ77_CompareLoop               ; If not, continue scanning history.
	bra.w    LZ77_EncodeMatch               ; If end of search distance reached, encode the best match found.
LZ77_MatchFound:
	subq.w   #$1,a5                         ; Adjust pointer back to the start of the matching sequence in history.
	movea.l  a0,a4                          ; Point a4 to the current position in the source buffer for comparison.
LZ77_CompareLenLoop:
	move.b   (a4)+,d3                       ; Fetch next byte from source buffer.
	cmp.b    (a5)+,d3                       ; Compare it with the next byte in the history dictionary.
	bne.b    LZ77_CheckBestMatch            ; If they differ, sequence match ends, check if it's the best one.
	cmpa.l   a5,a3                          ; Check if we've reached the search boundary.
	bgt.b    LZ77_CompareLenLoop            ; If not, continue comparing bytes to find full sequence length.
LZ77_CheckBestMatch:
	move.l   a4,d3                          ; Calculate the length of the matched sequence.
	sub.l    a0,d3                          ; Subtract start pointer from current pointer.
	subq.l   #$1,d3                         ; Adjust length by 1.
	cmp.l    d3,d5                          ; Compare new match length with the current best match length.
	bge.w    LZ77_NextHistoryByte           ; If new match is not longer, continue searching history.
	move.l   a5,d4                          ; Calculate the relative offset of the match in the dictionary.
	sub.l    a0,d4                          ; Subtract start pointer from dictionary match pointer.
	sub.l    d3,d4                          ; Adjust offset by sequence length.
	subq.w   #$1,d4                         ; Adjust offset by 1.
	cmpi.l   #$4,d3                         ; Check if the match is a "small match" (length 2 to 4).
	ble.b    LZ77_SmallMatchOffset          ; If small match, jump to calculate specific encoding offset.
	moveq    #$6,d6                         ; Initialize configuration variable d6 for a long match offset.
	cmpi.l   #$101,d3                       ; Check if match length exceeds the 256-byte maximum standard encoding.
	blt.b    LZ77_CheckBestMatchOffset      ; If within limits, jump to verify encoding offsets.
	move.w   #$100,d3                       ; Cap the match length at 256 bytes for this encoding scheme.
	bra.b    LZ77_CheckBestMatchOffset      ; Jump to verify encoding offsets.
LZ77_SmallMatchOffset:
	move.w   d3,d6                          ; Copy match length to d6.
	subq.w   #$2,d6                         ; Adjust match length.
	lsl.w    #$1,d6                         ; Multiply by 2 to align with offset threshold configuration tables.
LZ77_CheckBestMatchOffset:
	lea      LZ77_BitsTable(pc),a6          ; Point a6 to the LZ77 offset configuration tables.
	cmp.w    (a6,d6.w),d4                   ; Check if the match offset fits within the configured limit.
	bge.b    LZ77_NextHistoryByte           ; If offset is too large, the match is invalid; keep searching.
	move.l   d3,d5                          ; Match is valid. Save the new best matched length to d5.
	move.l   d4,Var_MatchOffset.l           ; Save the offset of this new best match.
	move.b   d6,Var_MatchLength.l           ; Save the length class configuration index.
LZ77_NextHistoryByte:
	cmpa.l   a5,a3                          ; Check if we have exhausted the sliding window history limit.
	bgt.b    LZ77_FindMatchLoop             ; If not, loop back and continue scanning history.
LZ77_EncodeMatch:
	cmpi.l   #$1,d5                         ; Check if the best match found was only 1 byte long.
	beq.w    LZ77_EncodeLiteral             ; If 1 byte, it's inefficient to compress; encode it as a literal.
	bsr.w    LZ77_OutputLiterals            ; If we have a valid match (>1 byte), flush any pending literals first.
	move.b   Var_MatchLength(pc),d6         ; Load the length class index to determine encoding parameters.
	move.l   Var_MatchOffset(pc),d3         ; Load the match offset for bitstream output.
	move.w   $8(a6,d6.w),d0                 ; Fetch the number of required offset bits from the config table.
	bsr.w    LZ77_OutputBits                ; Output the match offset bits to the compressed stream.
	move.w   $10(a6,d6.w),d0                ; Fetch the required extra length bits (if any) from the table.
	beq.b    .skip_extra_length_bits        ; If zero extra bits required (fixed length class), skip length encoding.
	move.l   d5,d3                          ; For variable length class, prepare the length value for encoding.
	subq.w   #$1,d3                         ; Adjust length value for zero-based encoding.
	bsr.w    LZ77_OutputBits                ; Output the extra match length bits to the stream.
.skip_extra_length_bits:
	move.w   $18(a6,d6.w),d0                ; Fetch the flag pattern bit-size for this match class.
	move.w   $20(a6,d6.w),d3                ; Fetch the actual flag pattern bitmask.
	bsr.w    LZ77_OutputBits                ; Output the flag pattern bits to indicate a match block.
	addi.w   #$1,$28(a6,d6.w)               ; Increment the statistics counter for this specific match class.
	bchg     #$1,CIAA.l                     ; Toggle CIA-A port A bit 1 (power LED) to show compression activity.
	adda.l   d5,a0                          ; Advance the source buffer pointer past the matched sequence.
	clr.b    d0                             ; Clear d0 to indicate a match was successfully encoded.
	rts                                     ; Return from subroutine.

; ============================================================================
; Function: LZ77_EncodeLiteral
; Purpose : Output a single uncompressed literal byte to the holding buffer.
; ============================================================================
LZ77_EncodeLiteral:
	move.b   (a0)+,d3                       ; Fetch the next literal character from the source buffer.
	moveq    #$8,d0                         ; Prepare to output 8 bits for the literal byte.
	bsr.b    LZ77_OutputBits                ; Push the 8 bits into the literal buffer stream.
LZ77_CompressEnd:
	moveq    #$1,d0                         ; Set d0 to 1 to indicate a literal byte was buffered.
	rts                                     ; Return from subroutine.

; ============================================================================
; Function: LZ77_OutputLiterals
; Purpose : Flush pending uncompressed literals to the main compressed bitstream.
; ============================================================================
LZ77_OutputLiterals:
	tst.w    d1                             ; Check if there are any literals waiting in the buffer.
	beq.b    .exit                          ; If zero, nothing to do, return.
	move.w   d1,d3                          ; Copy the literal count to d3 for encoding.
	clr.w    d1                             ; Reset the pending literal counter.
	cmpi.w   #$9,d3                         ; Check if it is a large run of literals (>8 bytes).
	bge.b    LZ77_OutputLargeLiterals       ; If large, jump to large literal run encoding block.
	addq.w   #$1,Var_SmallLiteralCount.l    ; Increment statistics counter for small literal runs.
	subq.w   #$1,d3                         ; Adjust literal count (1-8 becomes 0-7) for 3-bit encoding.
	moveq    #$5,d0                         ; Set output size to 5 bits (3 bits for count, 2 flag bits).
	bra.b    LZ77_OutputBits                ; Output the literal block header to the stream.
.exit:
	rts                                     ; Return from subroutine.

; ============================================================================
; Function: LZ77_OutputLargeLiterals
; Purpose : Encode headers for a large run of literal bytes (>= 9).
; ============================================================================
LZ77_OutputLargeLiterals:
	addq.w   #$1,Depacker_HunkStart.l       ; Increment statistics counter for large literal runs.
	subi.w   #$9,d3                         ; Adjust large literal count offset.
	ori.w    #$700,d3                       ; Apply the large literal flag pattern (binary 111).
	moveq    #$b,d0                         ; Output 11 bits (8 for count, 3 for flag).

; ============================================================================
; Function: LZ77_OutputBits
; Purpose : Shift a specified number of bits into the compressed output word.
; ============================================================================
LZ77_OutputBits:
	subq.w   #$1,d0                         ; Adjust bit count for dbra loop (n-1).
LZ77_OutputBitsLoop:
	lsr.l    #$1,d3                         ; Shift the next bit of data out of d3 into X flag.
	roxl.l   #$1,d2                         ; Rotate the bit from X flag into the accumulator register d2.
	bcs.b    LZ77_OutputBitsWriteLong       ; If carry set (accumulator is full/32-bits), write out the longword.
	dbra     d0,LZ77_OutputBitsLoop         ; Loop until all required bits are shifted in.
	rts                                     ; Return from subroutine.

; ============================================================================
; Function: LZ77_OutputBitsFillWord
; Purpose : Pad the bit accumulator to longword boundary at end of compression.
; ============================================================================
LZ77_OutputBitsFillWord:
	clr.w    d0                             ; Clear bit counter to force shifting.
LZ77_OutputBitsWriteLong:
	move.l   d2,(a2)+                       ; Write the fully assembled 32-bit word to the output buffer.
	eor.l    d2,d7                          ; XOR the output longword into the running checksum/stats register (d7).
	moveq    #$1,d2                         ; Re-initialize the accumulator with the marker bit at position 0.
	dbra     d0,LZ77_OutputBitsLoop         ; Continue shifting any remaining bits from the previous call.
	rts                                     ; Return from subroutine.

; ============================================================================
; Variables Block
; ============================================================================
Var_WindowSize:
	dc.l     0                              ; Sliding window size limit for LZ77 dictionary search (long)
Var_MatchOffset:
	dc.l     0                              ; Best dictionary match offset found (long)
Var_MatchLength:
	dc.w     0                              ; Best match length class index (word)
Var_DepackAddress:
	dc.l     0                              ; Address where payload will be decompressed (long)

; ============================================================================
; Table   : LZ77_BitsTable
; Purpose : Configures search limits, bit budgets, encoding flag patterns, and
;           gathers runtime compression statistics for the four LZ77 match classes.
; Structure:
;   - Words 0-3  : Maximum dictionary search offset limit per match length class.
;   - Words 4-7  : Initial prefix + offset bit budget size.
;   - Words 8-11 : Additional length bits needed for dynamic encoding (0 or 8).
;   - Words 12-15: Bitwise flag pattern for the offset representation.
;   - Words 16-19: Bit-width of the flag pattern.
;   - Words 20-23: Dynamic match usage counters (statistics).
; ============================================================================
LZ77_BitsTable:
	; Max dictionary offset limit per match length class (words 0-3)
	dc.w     $0100                          ; Max offset for length 2 matches (256)
	dc.w     $0200                          ; Max offset for length 3 matches (512)
	dc.w     $0400                          ; Max offset for length 4 matches (1024)
	dc.w     $8000                          ; Max offset for length >= 5 matches (32768)

	; Bit budget size per match length class (words 4-7)
	dc.w     $0008                          ; Budget for length 2 (8 bits offset)
	dc.w     $0009                          ; Budget for length 3 (9 bits offset)
	dc.w     $000A                          ; Budget for length 4 (10 bits offset)
	dc.w     $000F                          ; Budget for length >= 5 (15 bits)

	; Extra length bits required per match length class (words 8-11)
	dc.w     $0000                          ; Extra bits for length 2 (0 bits)
	dc.w     $0000                          ; Extra bits for length 3 (0 bits)
	dc.w     $0000                          ; Extra bits for length 4 (0 bits)
	dc.w     $0008                          ; Extra bits for length >= 5 (8 bits)

	; Offset bit pattern per match length class (words 12-15)
	dc.w     $0002                          ; Offset pattern for length 2
	dc.w     $0003                          ; Offset pattern for length 3
	dc.w     $0003                          ; Offset pattern for length 4
	dc.w     $0003                          ; Offset pattern for length >= 5

	; Offset pattern bit size per match length class (words 16-19)
	dc.w     $0001                          ; Offset pattern size for length 2 (1 bit)
	dc.w     $0004                          ; Offset pattern size for length 3 (4 bits)
	dc.w     $0005                          ; Offset pattern size for length 4 (5 bits)
	dc.w     $0006                          ; Offset pattern size for length >= 5 (6 bits)

	; Statistics counters for each match class (words 20-23)
Var_CompressStats:
	dc.w     0                              ; Class 0 (length 2) match counter
	dc.w     0                              ; Class 1 (length 3) match counter
	dc.w     0                              ; Class 2 (length 4) match counter
	dc.w     0                              ; Class 3 (length >= 5) match counter

Var_SmallLiteralCount:
	dc.w     0                              ; Count of small literal runs written (word 24)
; ============================================================================
; Block   : Depacker_HunkStart
; Purpose : Structured template of the self-extracting Amiga hunk executable image.
;           Contains the magic headers, Code hunk, BSS hunk, and relocations.
;           The packer dynamically patches target offsets and RLE/LZ77 parameters.
; ============================================================================
Depacker_HunkStart:
	dc.w     0                              ; Temporary packer stats: Count of large literal runs
	dc.l     $000003F3                      ; Amiga Hunk Magic Identifier (HUNK_HEADER)
	dc.l     $00000000                      ; Library name table reference (none)
	dc.l     $00000002                      ; Total hunk count (2 hunks: Code and BSS)
	dc.l     $00000000                      ; First hunk index (Hunk 0)
	dc.l     $00000001                      ; Last hunk index (Hunk 1)
	dc.l     $00000047                      ; Size of Hunk 0 (Code: 71 longwords = 284 bytes)
	dc.l     $00000001                      ; Size of Hunk 1 (BSS: 1 longword = 4 bytes)

	; --- Hunk 0 (Code Hunk Magic Headers) ---
	dc.l     $000003E9                      ; Hunk 0 type (HUNK_CODE)
	dc.l     $00000047                      ; Hunk 0 size (71 longwords)

	; --- Decruncher Stub Machine Code ---
	dc.w     $2C79, $0000, $0004            ; movea.l  $4.w, a6             - Load ExecBase
	dc.w     $4EAE, $FF6A                   ; jsr      Forbid(a6)           - Disable task switching
	dc.w     $4FF9, $0000, $4000            ; lea      $4000.w, a7          - Set temporary stack pointer
	dc.w     $13FC, $0087, $00BF, $D100     ; move.b   #$87, $BFD100        - Configure CIA-A Port A direction (power LED)
	dc.w     $41FA, $00F6                   ; lea      Start(pc), a0        - Point a0 to the start of packed data
	dc.w     $43F9                          ; lea      Destination, a1      - Point a1 to the end of decompression buffer
Depacker_PackedLen:
	dc.l     0                              ; Dynamically patched: Size of compressed payload
	dc.w     $47FA, $0016                   ; lea      PayloadEnd(pc), a3   - Point a3 to the start of the final copy routine
	dc.w     $49F9                          ; lea      OriginalLength, a4   - Point a4 to the execution jump address
Depacker_OrigLen:
	dc.l     0                              ; Dynamically patched: Address where decompressed output resides
	dc.w     $2448                          ; movea.l  a0, a2               - Copy source start pointer to a2
	dc.w     $38DB                          ; move.w   (a3)+, d4            - Load magic marker word
	dc.w     $B7CA                          ; cmpa.l   a2, a3               - Check if we reached the payload
	dc.w     $65FA                          ; bcs.s    ...                  - Loop if not
	dc.w     $4EF9                          ; jmp      <absolute_long>      - Opcode to jump to patched entry
Depacker_JmpAddr:
	dc.l     0                              ; Dynamically patched: Entry point of decrunched program
	dc.w     $2018                          ; move.l   (a0)+, d0            - Read packed longword size
	dc.w     $2218                          ; move.l   (a0)+, d1            - Read offset/marker parameter
	dc.w     $2A18                          ; move.l   (a0)+, d5            - Read checksum/header longword
	dc.w     $2449                          ; movea.l  a1, a2               - Set destination pointer
	dc.w     $D1C0                          ; adda.l   d0, a0               - Advance packed pointer by size
	dc.w     $D5C1                          ; adda.l   d0, a2               - Advance unpack pointer by size
	dc.w     $2020                          ; move.l   -(a0), d0            - Load next packed longword (backwards)
	dc.w     $B185                          ; eor.l    d0, d5               - Compute checksum for verification
	dc.w     $E288                          ; lsr.l    #1, d0               - Shift flag bit into carry
	dc.w     $6604                          ; bne.s    ...                  - Branch if more bits remain
	dc.w     $6100, $009A                   ; bsr.w    ...                  - Fetch next block/flags
	dc.w     $653A                          ; bcs.s    ...                  - Branch if match flag is set
	dc.b     $72                            ; moveq opcode
Depacker_MarkerByte:
	dc.b     $08                            ; Dynamically patched: RLE escape marker character
	dc.w     $7601                          ; moveq    #1, d3               - Prepare bit count for next shift
	dc.w     $E288                          ; lsr.l    #1, d0               - Shift next flag bit
	dc.w     $6604                          ; bne.s    ...                  - Branch if more bits
	dc.w     $6100, $008C                   ; bsr.w    ...                  - Fetch next block
	dc.w     $6500, $0052                   ; bcs.w    ...                  - Handle large match sequence
	dc.w     $7203                          ; moveq    #3, d1               - Set short literal count limit
	dc.w     $4244                          ; clr.w    d4                   - Clear scratch register
	dc.w     $6100, $008C                   ; bsr.w    ...                  - Fetch short sequence length
	dc.w     $3602                          ; move.w   d2, d3               - Transfer length to counter
	dc.w     $D644                          ; add.w    d4, d3               - Add offset base
	dc.w     $7207                          ; moveq    #7, d1               - Setup bit shift limit for literal
	dc.w     $E288                          ; lsr.l    #1, d0               - Shift literal flag bit
	dc.w     $6604                          ; bne.s    ...                  - Branch if more bits
	dc.w     $6100, $0072                   ; bsr.w    ...                  - Fetch block
	dc.w     $E392                          ; asl.l    d1, d2               - Shift value to format byte
	dc.w     $51C9, $FFF4                   ; dbra     d1, ...              - Loop for all bits
	dc.w     $1502                          ; move.b   d2, -(a2)            - Write literal byte to destination
	dc.w     $51CB, $FFEC                   ; dbra     d3, ...              - Loop for sequence length
	dc.w     $603A                          ; bra.s    ...                  - Branch back to main loop
	dc.w     $7208                          ; moveq    #8, d1               - Prepare bit count
	dc.w     $7808                          ; moveq    #8, d4               - Prepare another count
	dc.w     $60DA                          ; bra.s    ...                  - Branch
	dc.w     $7202                          ; moveq    #2, d1               - Prepare bit count
	dc.w     $6100, $0064                   ; bsr.w    ...                  - Fetch block
	dc.w     $0C02, $0002                   ; cmpi.b   #2, d2               - Check sequence length flag
	dc.w     $6D12                          ; blt.s    ...                  - Handle small sequence
	dc.w     $0C02, $0003                   ; cmpi.b   #3, d2               - Check medium sequence flag
	dc.w     $67E8                          ; beq.s    ...                  - Handle medium sequence
	dc.w     $7208                          ; moveq    #8, d1               - Prepare literal read count
	dc.w     $6100, $0052                   ; bsr.w    ...                  - Fetch block
	dc.w     $3602                          ; move.w   d2, d3               - Transfer literal count
	dc.b     $72                            ; moveq opcode
Depacker_SmallMatchBits:
	dc.b     $0C                            ; Dynamically patched: Small match offset bit-width
	dc.w     $6008                          ; bra.s    ...                  - Skip large bits config
	dc.b     $72                            ; moveq opcode
Depacker_LargeMatchBits:
	dc.b     $09                            ; Dynamically patched: Large match offset bit-width
	dc.w     $D242                          ; add.w    d2, d1               - Combine match size config
	dc.w     $5442                          ; addq.w   #2, d2               - Adjust count offset
	dc.w     $3602                          ; move.w   d2, d3               - Transfer configured count
	dc.w     $6100, $0040                   ; bsr.w    ...                  - Fetch match sequence offset
	dc.w     $534A                          ; subq.w   #1, a2               - Pre-decrement output pointer
	dc.w     $14B2                          ; move.b   (a2,d2.w), (a2)      - Copy byte from sliding window history
	dc.w     $2000                          ; move.l   d0, d0               - NOP (timing or padding)
	dc.w     $51CB, $FFF8                   ; dbra     d3, ...              - Loop for all matched bytes
	dc.w     $33C8, $00DF, $F1A2            ; move.w   a0, $DFF1A2          - Flash custom chip background color (visual feedback)
	dc.w     $B3CA                          ; cmpa.l   a2, a1               - Check if target output bounds reached
	dc.w     $6D00, $FF7E                   ; blt.w    ...                  - Loop if decompression not finished
	dc.w     $4A85                          ; tst.l    d5                   - Check if checksum matches expected (0)
	dc.w     $6606                          ; bne.s    ...                  - Branch if checksum failed
	dc.w     $4EF9                          ; jmp      <absolute_long>      - Opcode to jump
Depacker_Entry:
	dc.l     0                              ; Dynamically patched: Jump address on decompression failure or exit
	dc.w     $303C, $FFFF                   ; move.w   #$FFFF, d0           - Setup color restore value
	dc.w     $33C0, $00DF, $F180            ; move.w   d0, $DFF180          - Restore original background color 0
	dc.w     $51C8, $FFF8                   ; dbra     d0, ...              - Small delay loop
	dc.w     $70FF                          ; moveq    #-1, d0              - Return error state in d0
	dc.w     $4E75                          ; rts                           - Return to OS
	dc.w     $2020                          ; move.l   -(a0), d0            - Load next 32-bit chunk backwards
	dc.w     $B185                          ; eor.l    d0, d5               - Update checksum value
	dc.w     $44FC, $0010                   ; move.w   #$10, ccr            - Reset condition codes
	dc.w     $E290                          ; roxl.l   #1, d0               - Shift in next bit block flag
	dc.w     $4E75                          ; rts                           - Return
	dc.w     $5341                          ; subq.w   #1, a1               - Decrement pointer (unused stub)
	dc.w     $4242                          ; clr.w    d2                   - Clear data register
	dc.w     $E288, $660A                   ; lsr.l    #1, d0 / bne.s       - Multi-instruction packed sequence for flag handling
	dc.w     $2020                          ; move.l   -(a0), d0            - Load chunk
	dc.w     $B185                          ; eor.l    d0, d5               - Checksum
	dc.w     $44FC, $0010                   ; move.w   #$10, ccr            - Clear flags
	dc.w     $E290                          ; roxl.l   #1, d0               - Shift flag
	dc.w     $E392                          ; roxl.l   #1, d2               - Transfer flag
	dc.w     $51C9, $FFEE                   ; dbra     d1, ...              - Loop for bits
	dc.w     $4E75                          ; rts                           - Return

Depacker_RelocStart:
	; --- Hunk 0 Relocations ---
	dc.l     $000003EC                      ; Hunk type: HUNK_RELOC32
	dc.l     $00000000                      ; End of relocation block specifier

	; --- Hunk 0 End ---
	dc.l     $000003F2                      ; Hunk end identifier (HUNK_END)

	; --- Hunk 1 (BSS Hunk) ---
	dc.l     $000003EB                      ; Hunk type: HUNK_BSS
	dc.l     $00000001                      ; BSS hunk size (1 longword)
	dc.l     $000003F2                      ; Hunk end identifier (HUNK_END)
	dc.l     $FFFFFFFF, $FFFFFFFF, $FFFFFFFF ; Padding for alignment / Hunk safety margins
; ============================================================================
; Function: ClearInputBuffer
; Purpose : Zero out the keyboard input buffer before requesting user input.
; ============================================================================
ClearInputBuffer:
	movem.l  d0/a0,-(a7)                    ; Save d0 and a0 to stack.
	lea      Var_InputBuffer(pc),a0         ; Point a0 to the input buffer.
	moveq    #$e,d0                         ; Prepare loop counter to clear 15 words (30 bytes).
ClearInputBufferLoop:
	clr.w    (a0)+                          ; Write 0 (word) and advance pointer.
	dbra     d0,ClearInputBufferLoop        ; Loop until buffer is cleared.
	movem.l  (a7)+,d0/a0                    ; Restore d0 and a0.
	rts                                     ; Return from subroutine.

; ============================================================================
; Global Variables
; ============================================================================
Var_OriginalLength:
	dc.l     0                              ; Store original file size (long).
Var_InputBuffer:
	ds.b     30                             ; Keyboard standard input character buffer (30 bytes).
Var_WorkspaceSize:
	dc.l     0                              ; Store dynamic workspace memory block size (long).
Var_PackedBuffer:
	dc.l     0                              ; Store packed data destination buffer pointer (long).
Var_SourceBuffer:
	dc.l     0                              ; Store source file buffer pointer (long).
Var_LoadAddress:
	dc.l     0                              ; Store destination load address for the decruncher (long).
Var_PackedLength:
	dc.l     0                              ; Store calculated final packed data length (long).
Str_HexTable:
	dc.b "0123456789abcdef"
; ==============================================================================
; DEPACKER STUB DATA (BOOTSTRAP COPY LOOP)
; ==============================================================================
; This bootstrap loader stub is appended to the compressed file. When the packed
; program is run, this stub copies the actual decruncher routine from its position
; inside the packed executable to a safe temporary location in RAM (specified
; dynamically at patch time), and then jumps to it.
; ==============================================================================
Depacker_StubData:
	lea      Depacker_ConfigTable(pc),a0    ; a0 = Source address of decruncher routine
	lea      RLE_Compress(pc),a2            ; a2 = End marker pointer of decruncher routine
	dc.w     $43F9                          ; Opcode for 'lea <absolute_long>, a1'
Var_DepackAddressCopy:
	dc.l     Start                          ; Patched: Decruncher destination RAM address
.copy_loop:
	move.w   (a0)+,(a1)+                    ; Copy decruncher routine word-by-word
	cmpa.l   a2,a0                          ; Check if entire decruncher routine is copied
	bcs.b    .copy_loop                     ; Loop until decruncher is completely in RAM
	dc.w     $4EF9                          ; Opcode for 'jmp <absolute_long>'
Var_DepackAddressCopy2:
	dc.l     Start                          ; Patched: Target decruncher execution address

; ==============================================================================
; DEPACKER CONFIG TABLE (THE CORE RLE DECRUNCHER ENGINE)
; ==============================================================================
; This is the actual decruncher. It is copied to a safe, temporary memory location
; and executed from there to perform safe in-place decompression.
;
; The routine decrunches the RLE compressed payload from back to front, shifting
; the compressed data upwards to avoid overwriting yet-uncompressed bytes.
;
; Patch Parameters:
; - lea 0.l, a0   -> Patched with the target uncompressed program load address.
; - lea 0.l, a3   -> Patched with the compressed payload source end address.
; - lea 0.l, a2   -> Patched with the compressed payload source start address.
; - move.b #0, d7 -> Patched with the optimal RLE escape marker character.
; ==============================================================================
Depacker_ConfigTable:
	lea      0.l,a0                         ; Patched: Uncompressed target load start address
	lea      0.l,a3                         ; Patched: Compressed payload source end address
	lea      0.l,a2                         ; Patched: Compressed payload source start address
	move.b   #0,d7                          ; Patched: Specific RLE escape marker character byte
	movea.l  a3,a1                          ; a1 = Copy source end pointer for memory shift
.copy_mem_loop:
	move.b   -(a2),-(a1)                    ; Shift compressed payload upwards to end of buffer
	cmpa.l   a2,a0                          ; Check if entire payload relocation shift is complete
	bne.b    .copy_mem_loop                 ; Loop until shifted to safe memory boundary
	tst.b    (a1)+                          ; Adjust source pointer past potential alignment byte
	tst.b    (a0)+                          ; Adjust target destination pointer
.decrunch_loop:
	cmpa.l   a3,a1                          ; Check if decompression is complete (pointers meet)
	beq.b    .decrunch_done                 ; Jump to execute program if finished
	move.b   (a1)+,d0                       ; Read next byte from compressed stream
	cmp.b    d7,d0                          ; Check if byte matches the RLE escape marker
	beq.b    .is_rle                        ; Process RLE sequence if escape marker is hit
	move.b   d0,(a0)+                       ; Write raw literal byte to output buffer
	bra.b    .decrunch_loop                 ; Repeat decompression loop
.is_rle:
	move.b   (a1)+,d1                       ; Read sequence run-length count byte
	beq.b    .escape                        ; If count is 0, write escape marker itself as literal
	move.b   (a1)+,d0                       ; Read repeated character value
.rle_loop:
	move.b   d0,(a0)+                       ; Write repeated character to output buffer
	subq.b   #1,d1                          ; Decrement repeat sequence run counter
	bne.b    .rle_loop                      ; Loop until RLE run-length is fully written
	bra.b    .decrunch_loop                 ; Return to main decompression loop
.escape:
	move.b   d7,(a0)+                       ; Write RLE escape marker literal byte to output
	bra.b    .decrunch_loop                 ; Return to main decompression loop
.decrunch_done:
	dc.w     $4EF9                          ; Opcode for 'jmp <absolute_long>'
Var_JmpAddress:
	dc.l     0                              ; Patched: Entry point jump execution target address
RLE_Compress:
	lea      Var_RLE_Histogram(pc),a2       ; Point a2 to the 1024-byte (256 longs) histogram array.
	move.l   a0,-(a7)                       ; Push the source buffer pointer to stack.
RLE_HistogramLoop:
	clr.l    d0                             ; Clear d0 for byte access.
	move.b   (a0)+,d0                       ; Fetch next byte from source buffer.
	lsl.l    #$2,d0                         ; Multiply byte value by 4 to get longword array offset.
	addq.l   #$1,(a2,d0.l)                  ; Increment the frequency count for this byte.
	cmpa.l   a0,a1                          ; Check if we have scanned the entire source buffer.
	bne.b    RLE_HistogramLoop              ; Loop until EOF to build full character frequency map.
	movea.l  (a7)+,a0                       ; Pop the source buffer pointer back from stack.
	clr.l    d0                             ; Start scanning histogram from byte value 0.
	lea      Str_Header(pc),a3              ; Point a3 to the start of the histogram table (dummy reference point).
RLE_FindUnusedByte:
	lea      Var_RLE_Histogram(pc),a2       ; Point a2 back to the start of the histogram array.
RLE_FindUnusedByteLoop:
	cmpa.l   a3,a2                          ; Unused logic (bug in original code?).
	bcc.b    RLE_CheckNextByte              ; Scan next byte in source stream.
	move.l   (a2)+,d1                       ; Fetch frequency count for the current byte.
	cmp.l    d0,d1                          ; Check if frequency is 0.
	beq.b    RLE_FoundMarker                ; If 0 (unused), it's the perfect escape marker!
	bra.b    RLE_FindUnusedByteLoop         ; Loop to check all 256 possible byte values.
RLE_CheckNextByte:
	addq.l   #$1,d0                         ; Increment the target byte value.
	move.w   d0,$dff180.l                   ; Flash COLOR00 background to show progress.
	bra.b    RLE_FindUnusedByte             ; Continue scanning for optimal marker.
RLE_FoundMarker:
	tst.l    -(a2)                          ; Adjust array pointer back to the matched entry.
	lea      Var_RLE_Histogram(pc),a3       ; Point a3 to the start of the histogram.
	suba.l   a3,a2                          ; Calculate offset of the entry.
	move.l   a2,d7                          ; Copy the byte offset to d7.
	lsr.l    #$2,d7                         ; Divide by 4 to get the actual byte value.
	move.l   a0,d1                          ; Save source pointer to d1.
	move.l   a1,d2                          ; Save end pointer to d2.
	movea.l  a0,a2                          ; Point a2 to destination (in-place compression).
RLE_CompressLoop:
	cmpa.l   a0,a1                          ; Check if we reached the end of the source buffer.
	bls.w    RLE_CompressEnd                ; If yes, compression is finished.
	move.b   (a0),d0                        ; Fetch the next byte to compress.
	cmp.b    d0,d7                          ; Check if the byte matches our chosen escape marker.
	beq.w    RLE_ShiftEnd                   ; If it does, we must encode it safely.
	move.l   a0,d5                          ; Save pointer to start of potential run.
	addq.l   #$1,d5                         ; Check next byte.
	cmpa.l   d5,a1                          ; Did we reach the end of the buffer?
	bls.b    RLE_OutputByte                 ; If yes, just output the byte.
	cmp.b    $1(a0),d0                      ; Check if the next byte is identical (start of a run).
	beq.b    RLE_CheckRepeat                ; If identical, jump to run-length counting logic.
RLE_OutputByte:
	move.b   (a0)+,(a2)+                    ; Output as a raw literal byte.
	bra.b    RLE_CompressLoop               ; Loop back to process next byte.
RLE_CheckRepeat:
	clr.l    d6                             ; Clear the run-length counter.
	movea.l  a0,a3                          ; Point a3 to the start of the run.
RLE_CheckRepeatLoop:
	cmpa.l   a3,a1                          ; Check if we reached the end of the buffer.
	bls.b    RLE_EncodeRepeat               ; If yes, finish run encoding.
	cmpi.b   #$ff,d6                        ; Check if we hit the maximum run length (255).
	beq.b    RLE_EncodeRepeat               ; If yes, cap the run and encode it.
	cmp.b    (a3)+,d0                       ; Check if the next byte is still part of the run.
	bne.b    RLE_EncodeRepeat               ; If different, run has ended.
	addq.b   #$1,d6                         ; Increment the run-length counter.
	bra.b    RLE_CheckRepeatLoop            ; Loop to count entire run.
RLE_EncodeRepeat:
	cmpi.b   #$3,d6                         ; Check if the run is 3 bytes or less.
	bls.b    RLE_OutputByte                 ; If <= 3, it's smaller to write literals (escape + count + byte = 3).
	move.b   d7,(a2)+                       ; Write the RLE escape marker character.
	move.b   d6,(a2)+                       ; Write the run length count.
	move.b   d0,(a2)+                       ; Write the repeated byte value.
	adda.l   d6,a0                          ; Advance the source pointer past the compressed run.
	move.w   a0,$dff180.l                   ; Flash background color for visual feedback.
	bra.b    RLE_CompressLoop               ; Loop back for next chunk.
RLE_ShiftEnd:
	movea.l  a1,a3                          ; Save RLE payload shift source pointer.
	move.l   a1,d5                          ; Save RLE payload pointer.
	subq.l   #$1,a2                         ; Adjust destination pointer.
	addq.l   #$1,a3                         ; Adjust source pointer.
RLE_ShiftEndLoop:
	move.b   -(a1),-(a3)                    ; Shift RLE compressed payload upwards in RAM.
	cmpa.l   a1,a2                          ; Check if shift is complete.
	bne.b    RLE_ShiftEndLoop               ; Loop until payload is relocated safely.
	addq.l   #$1,a2                         ; Adjust destination pointer.
	move.b   d7,(a2)+                       ; Write the escape marker to indicate literal escape.
	clr.b    (a2)+                          ; Write 0 count to indicate a literal escape character.
	addq.l   #$2,a0                         ; Advance source pointer past escape literal.
	movea.l  d5,a1                          ; Point a1 to relocated payload start.
	addq.l   #$1,a1                         ; Adjust payload start pointer.
	bchg     #$1,CIAA.l                     ; Toggle CIA-A port A bit 1 (power LED).
	bra.b    RLE_CompressLoop               ; Loop back for next chunk.
RLE_CompressEnd:
	move.l   a2,d0                          ; Return the final compressed RLE stream size in d0.
	rts                                     ; Return from subroutine.
Var_RLE_Histogram:
	ds.b     1024,0                         ; RLE escape character byte frequency histogram table (256 longs)

Str_Header:
	dc.b $07
	dc.b $0C
	dc.b $1B
	dc.b "[3mHouse-Version 1.4 by FLASH for the RED SECTOR."
	dc.b $0A
	dc.b "The names have been changed"
	dc.b $0A
	dc.b "to protect the innocent... "
	dc.b $1B
	dc.b $5B
	dc.b $30
	dc.b $6D
	dc.b $0A
	dc.b $0A
Str_Workspace:
	dc.b "WORKSPACE: "
Str_Load:
	dc.b "LOAD: "
Str_OrigLen:
	dc.b "ORIGINAL LENGTH: "
Str_PackedLen:
	dc.b $1B
	dc.b $07
	dc.b "PACKED LENGTH: "
Str_Save:
	dc.b "SAVE: "
Str_OffsetMax:
	dc.b "OFFSET / "
	dc.b $BB
	dc.b "MAX $8000"
	dc.b $AB
	dc.b $20
	dc.b $24
Str_ExeOrData:
	dc.b "EXECUTEABLE OR DATA FILE [e/d] :"
Str_LocateFile:
	dc.b "LOCATE FILE AT $"
Str_JmpTo:
	dc.b "JMP TO $"
Str_MegaPack:
	dc.b "MEGA-PACK [y/n]: "
Str_FastMemNotFree:
	dc.b     $22, "FAST-MEMORY", $22, " IS NOT FREE."
	dc.b $0A
	dc.b "THIS MODE IS "
	dc.b $BB
	dc.b $4E
	dc.b $4F
	dc.b $54
	dc.b $AB
	dc.b " AVAILABLE !"
	dc.b $0A
Str_FastMemAvailable:
	dc.b "YOU ARE NOW ABLE TO PACK UP TO 512 KBYTE !"
	dc.b $0A
Str_NoFastMem:
	dc.b     "YOU HAVE NO ", $22, "FAST-MEMORY", $22
	dc.b $0A
	dc.b "THIS MODE IS "
	dc.b $BB
	dc.b $4E
	dc.b $4F
	dc.b $54
	dc.b $AB
	dc.b " AVAILABLE !"
	dc.b $0A
Str_DepackAt:
	dc.b "DEPACK AT $"
Str_SaveAgain:
	dc.b "SAVE AGAIN [y/n]: "
Var_SlowMemFlag:
	dc.b $00
Var_FileHandle:
  dc.l 0
Var_StdinHandle:
  dc.l 0
Var_StdoutHandle:
  dc.l 0
Var_DOSBase:
  dc.l 0
Str_DosLibrary:
	dc.b "dos.library"
	dc.b $00
	dc.b " IS "


; ========================================
	SECTION Hunk_1_Bss, BSS
Bss_Start:
	ds.b 4
