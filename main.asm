; ==============================================================================
; Unbiased Cosmic Character Swarm (3K Particles - 256x192 8-Bit)
; Target: ZX Spectrum Next (Z80N) - Layer 2 256x192 8bpp Graphics Mode
; 3,000 dots start at random positions across the full screen, fly inward at
; random speeds to form centered font characters, hold, then dissolve toward
; freshly generated unbiased scatter positions at independent random speeds.
; All symbol names strictly <= 10 characters (CamelCase)
; Every single line abundantly commented for pedagogical clarity
; ==============================================================================

    DEVICE ZXSPECTRUMNEXT
    OPT --zxnext=on

    ORG $C000               ; Program executable origin in Bank 0 RAM
    JP Start                ; Jump directly to entry point (Astrum / direct run)

    ; --- Include Universal Graphics Suite Libraries ---
    INCLUDE "Libraries/lib/hw.inc"
    INCLUDE "Libraries/inc/config.inc"

; --- Global Timing & Swarm Constants ---
Stars:      EQU 3000        ; 3,000 glowing particles in cosmic swarm
HalfDots:   EQU Stars/2     ; Update 1,500 alternating dots per frame
GradSpd:    EQU 2           ; Frames per 1-step gradient shift (~10s full wave)
CnvFrms:    EQU 40          ; 20 updates per dot at stable 25 Hz
HoldFrms:   EQU 0           ; Instant transition (0 frames wait between form/explode)
ExpFrms:    EQU 40          ; Dissolve completes in about 1.6 seconds

    INCLUDE "Libraries/lib/palette.asm"
    INCLUDE "Libraries/lib/dma.asm"
    INCLUDE "Libraries/lib/layer2.asm"
    INCLUDE "ClExit.asm"   ; Reusable host-state entry and clean exit

; --- Packed Coordinate Arrays in MMU Slots 4 and 5 ($8000-$BFFF) ---
; Colors and speed classes are derived from particle order, saving 6,000 bytes.
DotX:       EQU $8000       ; 3000 bytes: Current X coordinate (0..255)
DotY:       EQU $8C00       ; 3000 bytes: Current Y coordinate (0..191)
DotTX:      EQU $9800       ; 3000 bytes: Target X coordinate (0..255)
DotTY:      EQU $A400       ; 3000 bytes: Target Y coordinate (0..191)
    ASSERT DotTY+Stars <= $B000 ; Keep at least 4K for the downward stack

; ==============================================================================
; Main Program Entry Point
; ==============================================================================
Start:
    JP ClStart              ; Capture host state before touching the machine
ClReady:
    ; --- Dynamic Hardware Entropy Seeding ---
    LD BC,PortNext          ; NextReg register select port ($243B)
    LD A,RegLineLo          ; Select raster line LSB register ($1F)
    OUT (C),A               ; Send select
    INC B                   ; Data port ($253B)
    IN A,(C)                ; A = exact hardware raster scanline (0..255)
    LD H,A                  ; High byte of seed = live video raster line
    LD A,R                  ; Read Z80 7-bit memory refresh register
    XOR H                   ; Mix raster line with Z80 instruction cycle
    LD L,A                  ; Low byte of seed
    OR H                    ; Ensure seed is strictly non-zero
    JR NZ,SeedOk
    LD HL,$ACE1             ; Non-zero fallback
SeedOk:
    LD (RndSeed),HL         ; Store dynamic PRNG seed seed

    NEXTREG RegMMU4,8       ; Map particle RAM before stack use in slot 4
    NEXTREG RegMMU5,9       ; Map particle RAM before stack use in slot 5
    LD SP,StackTop          ; Stack stays above DotTY in bank 9
    NEXTREG RegSpeed,3      ; Set CPU speed to 28 MHz for maximum performance

    CALL InitL2             ; Configure Layer 2 256x192 8bpp display mode

    CALL GenPal             ; Generate 254-color continuous rainbow in RAM
    CALL SetPal             ; Upload generated palette to Layer 2 hardware
    CALL ClrBack            ; Clear back buffer with velvet black via DMA
    CALL SwapBuf            ; Flip cleared back buffer to front
    CALL ClrBack            ; Clear front buffer with velvet black via DMA

    LD A,GradSpd            ; Load initial gradient speed counter value
    LD (SpdCnt),A           ; Initialize speed divider counter in RAM
    XOR A                   ; A = deterministic even-particle phase on re-run
    LD (MovOdd),A           ; Reset persistent interleaved-motion phase state

    CALL InitDots           ; Generate 3,000 unbiased scatter positions

; ==============================================================================
; Main Morphing Constellation Loop
; Fly to character -> Immediate fresh random scatter -> Repeat
; ==============================================================================
MainLp:
    ; --- 1. Form Phase: Set character targets and fly inward from scatter ---
    CALL PickChr            ; Pick a random printable character (ASCII 33..90)
    CALL DecodeChr          ; Decode 8x8 font matrix into active pixel blocks
    CALL GenTargets         ; Set Target = Character position & assign random speeds
    LD HL,CnvFrms           ; HL = 40 frames; every dot reaches the glyph
    CALL RunFrames          ; Animate dots flying from scatter -> character

    ; --- 2. Dissolve Phase: Fly to fresh unbiased random positions immediately ---
    CALL Dissolve           ; Create fresh scatter targets and random speeds
    LD HL,ExpFrms           ; HL = 40 frames; every dot reaches its target
    CALL RunFrames          ; Animate glyph -> fresh random star field

    JP MainLp               ; Morph endlessly into the next character!

; ==============================================================================
; Run N Animation Frames Subroutine (Stable 25 FPS Double-Buffered)
; Executes HL frames with DMA clear, physics step, rasterization, and page flip
; Inputs: HL = Number of displayed 25 Hz frames to execute
; Outputs: None
; Clobbers: AF, BC, DE, HL
; ==============================================================================
RunFrames:
    LD A,H                  ; Check high byte of frame counter
    OR L                    ; Test if frame counter is zero on entry
    RET Z                   ; Return immediately if 0 frames requested
FrmLp:
    PUSH HL                 ; Preserve 16-bit frame counter on stack

    ; Check if Space key is pressed to quit cleanly
    LD BC,PortKey           ; BC = Keyboard port $7FFE (Space half-row)
    IN A,(C)                ; Read physical keyboard status
    BIT 0,A                 ; Test bit 0 (Space key: 0 when pressed)
    JP Z,QuitPrg            ; If Space is pressed, exit program cleanly

    CALL ClrBack            ; Clear back buffer with velvet black via DMA
    CALL UpdDots            ; Move 1,500 and render all 3,000 dots
    CALL WaitFrm            ; Synchronize the finished page to VBlank
    CALL SwapBuf            ; Flip back buffer to display instantly
    CALL UpdGrad            ; Advance slow palette rainbow gradient shift

    POP HL                  ; Restore 16-bit frame counter from stack
    DEC HL                  ; Decrement remaining animation frames
    LD A,H                  ; Check high byte of frame counter
    OR L                    ; Test if frame counter reached zero (HL == 0)
    JP NZ,FrmLp             ; Loop for all requested frames
    RET                     ; Return after running frame sequence

; ==============================================================================
; Memory Initialization Subroutine
; Maps 8K RAM Banks 8 and 9 into Slots 4 and 5
; Outputs: MMU Slots configured
; Clobbers: AF
; ==============================================================================
InitMem:
    NEXTREG RegMMU4,8       ; Map Bank 8 to Slot 4 ($8000-$9FFF)
    NEXTREG RegMMU5,9       ; Map Bank 9 to Slot 5 ($A000-$BFFF)
    RET                     ; Return with particle memory mapped

; ==============================================================================
; Dot Initializer Subroutine
; Generates 3,000 uniformly distributed random starting positions
; Outputs: DotX and DotY arrays filled
; Clobbers: AF, BC, DE, HL
; ==============================================================================
InitDots:
    LD HL,DotX              ; Initialize running pointer for DotX array
    LD (PtrX),HL            ; Store pointer in RAM
    LD HL,DotY              ; Initialize running pointer for DotY array
    LD (PtrY),HL            ; Store pointer in RAM
    LD BC,Stars             ; BC = 3,000 dots to initialize
IniLp:
    PUSH BC                 ; Preserve loop counter on stack

    CALL GetRndXY           ; Return one unbiased random (X,Y) pair
    LD HL,(PtrX)            ; Point HL to current DotX entry
    LD (HL),C               ; Store the initial full-width X coordinate
    INC HL                  ; Advance pointer to next entry
    LD (PtrX),HL            ; Store updated pointer

    LD HL,(PtrY)            ; Point HL to current DotY entry
    LD (HL),D               ; Store the initial unbiased Y coordinate
    INC HL                  ; Advance pointer to next entry
    LD (PtrY),HL            ; Store updated pointer

    POP BC                  ; Restore loop counter from stack
    DEC BC                  ; Decrement remaining dots counter
    LD A,B                  ; Inspect high byte of counter
    OR C                    ; Test if counter reached zero (BC == 0)
    JR NZ,IniLp             ; Loop until all 3,000 dots are initialized
    RET                     ; Return with 3,000 scattered dots ready

; ==============================================================================
; Dissolve Subroutine: Generate Fresh Uniform Scatter Targets
; Generates new destinations in one pass over both target arrays
; Outputs: DotTX and DotTY contain fresh unbiased positions
; Clobbers: AF, BC, DE, HL
; ==============================================================================
Dissolve:
    LD HL,DotTX             ; Running pointer to DotTX array
    LD (PtrTX),HL           ; Store pointer in RAM
    LD HL,DotTY             ; Running pointer to DotTY array
    LD (PtrTY),HL           ; Store pointer in RAM
    LD BC,Stars             ; BC = 3,000 dots to process
DisLp:
    PUSH BC                 ; Preserve loop counter on stack

    ; Generate one new unbiased full-screen target pair
    CALL GetRndXY           ; C = X 0..255 and D = Y 0..191
    LD HL,(PtrTX)           ; Load DotTX pointer
    LD (HL),C               ; Store the freshly generated target X
    INC HL                  ; Advance pointer
    LD (PtrTX),HL           ; Store updated pointer

    LD HL,(PtrTY)           ; Load DotTY pointer
    LD (HL),D               ; Store the freshly generated target Y
    INC HL                  ; Advance pointer
    LD (PtrTY),HL           ; Store updated pointer

    POP BC                  ; Restore loop counter from stack
    DEC BC                  ; Decrement remaining dots counter
    LD A,B                  ; Inspect high byte of counter
    OR C                    ; Test if counter reached zero (BC == 0)
    JP NZ,DisLp             ; Loop until all 3,000 dots are configured
    RET                     ; Return ready to dissolve to the new star field

; ==============================================================================
; Random Character Picker Subroutine
; Selects a random ASCII character in range 33 ('!') to 122 ('z')
; Covers uppercase, lowercase, numbers, and punctuation marks
; Outputs: CurChr updated in memory (ASCII 33..122)
; Clobbers: AF, HL
; ==============================================================================
PickChr:
    CALL RndNum             ; Generate fresh 16-bit random word in HL
    LD A,L                  ; Load random low byte into accumulator
    CP 180                  ; 180 is exactly two complete groups of 90 (33..122)
    JR NC,PickChr           ; Reject 180..255 tail without modulo bias
PickLp:
    CP 90                   ; Test if value < 90
    JR C,PickOk             ; If < 90, valid offset found
    SUB 90                  ; Subtract 90 to reduce into range 0..89
    JR PickLp               ; Repeat until within 0..89
PickOk:
    ADD A,33                ; Add base ASCII offset 33 ('!'.. 'z')
    LD (CurChr),A           ; Store selected random character in memory
    RET                     ; Return with selected character

; ==============================================================================
; Character Matrix Decoder Subroutine
; Decodes 8x8 bitmap of CurChr directly from Sinclair ROM at $3D00
; Finds all set bits ('1's) and builds centered GlyphBlk table
; Outputs: GlyphBlk, NumBlk, and exact centered BaseX/BaseY values
; Clobbers: AF, BC, DE, HL, IX
; ==============================================================================
DecodeChr:
    LD A,(CurChr)           ; Load selected ASCII character code (33..122)
    SUB 32                  ; Convert ASCII 32..127 to font index 0..95
    LD D,A                  ; D = font index
    LD E,8                  ; E = 8 bytes per character bitmap
    MUL D,E                 ; DE = index * 8 byte offset into Sinclair ROM
    LD HL,$3D00             ; HL points to base of Sinclair ROM font at $3D00
    ADD HL,DE               ; HL points to 8-byte glyph bitmap for CurChr in ROM

    LD IX,GlyphBlk          ; IX points to active block coordinates table
    XOR A                   ; A = 0
    LD (NumBlk),A           ; Reset active blocks counter to 0
    LD (MaxX),A             ; Start maximum column at the lowest value
    LD (MaxY),A             ; Start maximum row at the lowest value
    LD A,8                  ; Use one-past-grid as the initial minimum
    LD (MinX),A             ; Start minimum column above every valid column
    LD (MinY),A             ; Start minimum row above every valid row

    LD C,0                  ; C = row index Y (0..7)
DecRow:
    LD A,(HL)               ; Read current 8-pixel row byte from font
    LD B,8                  ; B = bit counter (8 columns X: 0..7)
    LD D,0                  ; D = column index X (0..7)
DecBit:
    RLCA                    ; Rotate leftmost pixel bit into Carry flag
    JR NC,BitSkp            ; If pixel is 0 (empty), skip recording
    ; Pixel is 1 (solid stroke): record (column X, row Y)
    PUSH AF                 ; Preserve font row shift accumulator
    LD (IX+0),D             ; Store column X in GlyphBlk[K].X
    LD (IX+1),C             ; Store row Y in GlyphBlk[K].Y
    INC IX                  ; Advance block pointer by 2 bytes
    INC IX                  ; (X byte + Y byte)
    LD A,(NumBlk)           ; Load current active blocks counter
    INC A                   ; Increment blocks count K
    LD (NumBlk),A           ; Store updated active blocks count

    ; Expand the active-pixel bounding box with this solid cell
    LD A,(MinX)             ; Read the smallest column found so far
    CP D                    ; Compare the old minimum with this column
    JR C,MinXOk             ; Keep it when the old minimum is already lower
    LD A,D                  ; Copy this new smaller-or-equal column
    LD (MinX),A             ; Save the new horizontal minimum
MinXOk:
    LD A,(MaxX)             ; Read the largest column found so far
    CP D                    ; Compare the old maximum with this column
    JR NC,MaxXOk            ; Keep it when the old maximum is already larger
    LD A,D                  ; Copy this new larger column
    LD (MaxX),A             ; Save the new horizontal maximum
MaxXOk:
    LD A,(MinY)             ; Read the smallest row found so far
    CP C                    ; Compare the old minimum with this row
    JR C,MinYOk             ; Keep it when the old minimum is already lower
    LD A,C                  ; Copy this new smaller-or-equal row
    LD (MinY),A             ; Save the new vertical minimum
MinYOk:
    LD A,(MaxY)             ; Read the largest row found so far
    CP C                    ; Compare the old maximum with this row
    JR NC,MaxYOk            ; Keep it when the old maximum is already larger
    LD A,C                  ; Copy this new larger row
    LD (MaxY),A             ; Save the new vertical maximum
MaxYOk:
    POP AF                  ; Restore font row accumulator
BitSkp:
    INC D                   ; Advance column index X (0..7)
    DJNZ DecBit             ; Loop for all 8 pixel columns in this row

    INC HL                  ; Advance pointer to next font row byte
    INC C                   ; Advance row index Y (0..7)
    LD A,C                  ; Check current row index
    CP 8                    ; Test if all 8 rows processed
    JR NZ,DecRow            ; Loop for all 8 rows

    ; Safety check: ensure character has at least 1 set pixel
    LD A,(NumBlk)           ; Load active blocks count K
    OR A                    ; Test if K == 0 (e.g. blank space)
    JR NZ,DecDone           ; If K > 0, character is valid!
    CALL PickChr            ; If blank, pick another character
    JR DecodeChr            ; Re-decode fresh character
DecDone:
    ; BaseX = 128 - width*8 - MinX*16 for exact visual centering
    LD A,(MaxX)             ; A = rightmost active grid column
    LD B,A                  ; B keeps the maximum during subtraction
    LD A,(MinX)             ; A = leftmost active grid column
    LD C,A                  ; C keeps MinX for the origin correction
    LD A,B                  ; Restore MaxX into the accumulator
    SUB C                   ; A = MaxX - MinX
    INC A                   ; A = active glyph width in cells
    RLCA                    ; Multiply width by 2
    RLCA                    ; Multiply width by 4
    RLCA                    ; Multiply width by 8, its half pixel width
    LD B,A                  ; B = half of width*16
    LD A,128                ; A = horizontal screen center
    SUB B                   ; A = centered left edge of the active bounds
    LD B,A                  ; Preserve the centered left edge
    LD A,C                  ; Restore the glyph's source minimum column
    RLCA                    ; Multiply MinX by 2
    RLCA                    ; Multiply MinX by 4
    RLCA                    ; Multiply MinX by 8
    RLCA                    ; Multiply MinX by 16 pixels per source cell
    LD C,A                  ; C = source-column origin correction
    LD A,B                  ; Restore the centered active left edge
    SUB C                   ; Offset the untrimmed 8-cell coordinate system
    LD (BaseX),A            ; Save exact per-glyph horizontal base

    ; BaseY = 96 - height*8 - MinY*16 for exact visual centering
    LD A,(MaxY)             ; A = bottommost active grid row
    LD B,A                  ; B keeps the maximum during subtraction
    LD A,(MinY)             ; A = topmost active grid row
    LD C,A                  ; C keeps MinY for the origin correction
    LD A,B                  ; Restore MaxY into the accumulator
    SUB C                   ; A = MaxY - MinY
    INC A                   ; A = active glyph height in cells
    RLCA                    ; Multiply height by 2
    RLCA                    ; Multiply height by 4
    RLCA                    ; Multiply height by 8, its half pixel height
    LD B,A                  ; B = half of height*16
    LD A,96                 ; A = vertical screen center
    SUB B                   ; A = centered top edge of the active bounds
    LD B,A                  ; Preserve the centered top edge
    LD A,C                  ; Restore the glyph's source minimum row
    RLCA                    ; Multiply MinY by 2
    RLCA                    ; Multiply MinY by 4
    RLCA                    ; Multiply MinY by 8
    RLCA                    ; Multiply MinY by 16 pixels per source cell
    LD C,A                  ; C = source-row origin correction
    LD A,B                  ; Restore the centered active top edge
    SUB C                   ; Offset the untrimmed 8-cell coordinate system
    LD (BaseY),A            ; Save exact per-glyph vertical base
    RET                     ; Return with populated GlyphBlk table

; ==============================================================================
; Target Coordinates Generator Subroutine
; Scales only the active glyph bounds into exactly centered 16x16 pixel cells
; Cyclic cell assignment keeps every stroke within one particle of equal density
; Outputs: DotTX and DotTY populated for all 3,000 dots
; Clobbers: AF, BC, DE, HL
; ==============================================================================
GenTargets:
    LD HL,DotTX             ; Initialize running pointer for DotTX array
    LD (PtrTX),HL           ; Store pointer in RAM
    LD HL,DotTY             ; Initialize running pointer for DotTY array
    LD (PtrTY),HL           ; Store pointer in RAM
    ; Pick an unbiased phase so the at-most-one extra dot rotates per glyph
    LD A,(NumBlk)           ; A = number of active cells in this glyph
    LD C,A                  ; C = exclusive upper bound for the start index
TgtPick:
    CALL RndNum             ; Generate a fresh pseudo-random byte in L
    LD A,L                  ; A = candidate phase byte
    AND 63                  ; Restrict the candidate to the table's 0..63 span
    CP C                    ; Test the candidate against NumBlk
    JR NC,TgtPick           ; Reject out-of-range values instead of modulo bias
    LD (BlkIdx),A           ; Save the unbiased starting active-cell index

    LD BC,Stars             ; BC = 3,000 dots to assign
TgtLp:
    PUSH BC                 ; Preserve loop counter on stack

    ; 1. Select the next cell cyclically for balanced stroke density
    LD A,(BlkIdx)           ; A = current active-cell index
    ADD A,A                 ; Multiply by 2 (each block entry is 2 bytes: X, Y)
    LD E,A                  ; E = byte offset into GlyphBlk table
    LD D,0                  ; D = 0
    LD HL,GlyphBlk          ; HL points to base of GlyphBlk table
    ADD HL,DE               ; HL points to selected block entry
    LD A,(HL)               ; A = grid column X (0..7)
    LD (TmpGridX),A         ; Save grid column X
    INC HL                  ; Advance pointer to grid row Y
    LD A,(HL)               ; A = grid row Y (0..7)
    LD (TmpGridY),A         ; Save grid row Y

    ; Advance and wrap the balanced active-cell index for the next dot
    LD A,(BlkIdx)           ; Reload the current active-cell index
    INC A                   ; Advance to the next active source cell
    LD D,A                  ; D keeps the candidate next index
    LD A,(NumBlk)           ; A = number of active source cells
    CP D                    ; Test whether the candidate reached the end
    JR NZ,TgtKeep           ; Keep a candidate that is still inside the table
    LD D,0                  ; Wrap exactly at NumBlk back to cell zero
TgtKeep:
    LD A,D                  ; A = wrapped next active-cell index
    LD (BlkIdx),A           ; Save it for the following particle

    ; 2. Calculate target X from the bounding-box-derived BaseX
    LD A,(TmpGridX)         ; Load grid column X (0..7)
    RLCA                    ; Multiply grid column by 2
    RLCA                    ; Multiply grid column by 4
    RLCA                    ; Multiply grid column by 8
    RLCA                    ; Multiply grid column by 16 pixels
    LD D,A                  ; D = scaled source-grid X
    LD A,(BaseX)            ; A = exact per-glyph horizontal base
    ADD A,D                 ; A = left edge of this active cell
    LD D,A                  ; D preserves the cell edge across the PRNG call
    CALL RndNum             ; Get random jitter
    LD A,H                  ; Reuse the high random byte for Y jitter
    LD (TmpRndY),A          ; Save it across target-X pointer updates
    LD A,L                  ; Load random byte
    AND 15                  ; Power-of-two mask gives unbiased jitter 0..15
    ADD A,D                 ; A = exactly centered target X
    LD HL,(PtrTX)           ; Point HL to current DotTX entry
    LD (HL),A               ; Store Target X
    INC HL                  ; Advance pointer to next entry
    LD (PtrTX),HL           ; Store updated pointer

    ; 3. Calculate target Y from the bounding-box-derived BaseY
    LD A,(TmpGridY)         ; Load grid row Y (0..7)
    RLCA                    ; Shift left by 4 (multiply by 16)
    RLCA
    RLCA
    RLCA
    LD D,A                  ; D = scaled source-grid Y
    LD A,(BaseY)            ; A = exact per-glyph vertical base
    ADD A,D                 ; A = top edge of this active cell
    LD D,A                  ; D preserves the cell edge
    LD A,(TmpRndY)          ; Reuse the paired high-byte random value
    AND 15                  ; Intra-block jitter dy (0..15)
    ADD A,D                 ; A = exactly centered target Y
    LD HL,(PtrTY)           ; Point HL to current DotTY entry
    LD (HL),A               ; Store Target Y
    INC HL                  ; Advance pointer to next entry
    LD (PtrTY),HL           ; Store updated pointer

    POP BC                  ; Restore loop counter from stack
    DEC BC                  ; Decrement remaining dots counter
    LD A,B                  ; Inspect high byte of counter
    OR C                    ; Test if counter reached zero (BC == 0)
    JP NZ,TgtLp             ; Loop until all 3,000 targets are generated
    RET                     ; Return with the 3K target matrix ready

; ==============================================================================
; Particle Motion Update & Plot Subroutine (Pure 8-Bit High-Speed Architecture)
; Updates and directly plots 3,000 dots through the Layer 2 write window
; Outputs: DotX, DotY updated, pixels rasterized to back buffer
; Clobbers: AF, BC, DE, HL
; ==============================================================================
UpdDots:
    CALL MoveDots           ; Update one interleaved half of the swarm
    JP DrawDots             ; Tail-call the complete 3,000-dot renderer

; ==============================================================================
; Alternating-Half Motion Update
; Each particle advances at 25 Hz while display frames remain evenly paced.
; ==============================================================================
MoveDots:
    LD A,(MovOdd)           ; Read which interleaved half moved last
    XOR 1                   ; Toggle between even and odd particle indices
    LD (MovOdd),A           ; Save the half selected for this frame
    LD HL,DotX              ; HL walks current X coordinates
    LD DE,DotY              ; DE walks current Y coordinates
    LD IX,DotTX             ; IX walks target X coordinates
    LD IY,DotTY             ; IY walks target Y coordinates
    OR A                    ; Test whether the odd half was selected
    JR Z,MovEven            ; Even half begins at array element zero
    INC HL                  ; Odd current-X half begins at element one
    INC DE                  ; Odd current-Y half begins at element one
    INC IX                  ; Odd target-X half begins at element one
    INC IY                  ; Odd target-Y half begins at element one
MovEven:
    LD BC,HalfDots          ; BC = 1,500 particles updated this frame
MoveLp:
    PUSH BC                 ; Preserve the 16-bit update counter

    ; Hash particle order into stable fast /2 and /4 speed classes
    LD A,C                  ; A = low counter byte, stable per array index
    RRCA                    ; Move an adjacent counter bit into bit zero
    XOR C                   ; Mix both bits into a less patterned selector
    AND 1                   ; Select speed class zero or one evenly
    INC A                   ; A = Z80N shift count 1 or 2
    LD B,A                  ; B = common X/Y easing shift

    ; Update X toward target X with a minimum one-pixel step
    LD A,(HL)               ; A = current X
    CP (IX+0)               ; Compare current X with target X
    JR Z,MoveXEnd           ; Equal X coordinates require no movement
    JR C,MoveXAdd           ; Lower current X requires positive movement
    SUB (IX+0)              ; A = positive leftward distance
    PUSH DE                 ; Preserve the live current-Y pointer
    LD E,A                  ; E = low byte of unsigned distance
    LD D,0                  ; DE = zero-extended distance
    BSRL DE,B               ; Step = distance >> random speed class
    LD A,E                  ; A = resulting X step
    POP DE                  ; Restore the current-Y pointer
    OR A                    ; Test whether easing rounded to zero
    JR NZ,MoveXSub          ; Keep any non-zero proportional step
    INC A                   ; Force progress by at least one pixel
MoveXSub:
    LD C,A                  ; C preserves the step
    LD A,(HL)               ; Reload current X
    SUB C                   ; Move X left without overshooting
    LD (HL),A               ; Store the updated X coordinate
    JR MoveXEnd             ; Skip the positive-motion path
MoveXAdd:
    SUB (IX+0)              ; A = negative current-minus-target distance
    NEG                     ; A = positive rightward distance
    PUSH DE                 ; Preserve the live current-Y pointer
    LD E,A                  ; E = low byte of unsigned distance
    LD D,0                  ; DE = zero-extended distance
    BSRL DE,B               ; Step = distance >> random speed class
    LD A,E                  ; A = resulting X step
    POP DE                  ; Restore the current-Y pointer
    OR A                    ; Test whether easing rounded to zero
    JR NZ,MoveXPos          ; Keep any non-zero proportional step
    INC A                   ; Force progress by at least one pixel
MoveXPos:
    LD C,A                  ; C preserves the step
    LD A,(HL)               ; Reload current X
    ADD A,C                 ; Move X right without overshooting
    LD (HL),A               ; Store the updated X coordinate
MoveXEnd:
    INC HL                  ; Advance current X by two interleaved bytes
    INC HL                  ; Skip the other frame's particle half
    INC IX                  ; Advance target X by two interleaved bytes
    INC IX                  ; Skip the other frame's particle half

    ; Update Y toward target Y using the same speed class
    LD A,(DE)               ; A = current Y
    CP (IY+0)               ; Compare current Y with target Y
    JR Z,MoveYEnd           ; Equal Y coordinates require no movement
    JR C,MoveYAdd           ; Lower current Y requires positive movement
    SUB (IY+0)              ; A = positive upward distance
    PUSH DE                 ; Preserve the live current-Y pointer
    LD E,A                  ; E = low byte of unsigned distance
    LD D,0                  ; DE = zero-extended distance
    BSRL DE,B               ; Step = distance >> random speed class
    LD A,E                  ; A = resulting Y step
    POP DE                  ; Restore the current-Y pointer
    OR A                    ; Test whether easing rounded to zero
    JR NZ,MoveYSub          ; Keep any non-zero proportional step
    INC A                   ; Force progress by at least one pixel
MoveYSub:
    LD B,A                  ; B may hold the final Y step
    LD A,(DE)               ; Reload current Y
    SUB B                   ; Move Y upward without overshooting
    LD (DE),A               ; Store the updated Y coordinate
    JR MoveYEnd             ; Skip the positive-motion path
MoveYAdd:
    SUB (IY+0)              ; A = negative current-minus-target distance
    NEG                     ; A = positive downward distance
    PUSH DE                 ; Preserve the live current-Y pointer
    LD E,A                  ; E = low byte of unsigned distance
    LD D,0                  ; DE = zero-extended distance
    BSRL DE,B               ; Step = distance >> random speed class
    LD A,E                  ; A = resulting Y step
    POP DE                  ; Restore the current-Y pointer
    OR A                    ; Test whether easing rounded to zero
    JR NZ,MoveYPos          ; Keep any non-zero proportional step
    INC A                   ; Force progress by at least one pixel
MoveYPos:
    LD B,A                  ; B may hold the final Y step
    LD A,(DE)               ; Reload current Y
    ADD A,B                 ; Move Y downward without overshooting
    LD (DE),A               ; Store the updated Y coordinate
MoveYEnd:
    INC DE                  ; Advance current Y by two interleaved bytes
    INC DE                  ; Skip the other frame's particle half
    INC IY                  ; Advance target Y by two interleaved bytes
    INC IY                  ; Skip the other frame's particle half

    POP BC                  ; Restore the 16-bit update counter
    DEC BC                  ; Count one updated particle
    LD A,B                  ; Inspect the high counter byte
    OR C                    ; Test the complete counter for zero
    JP NZ,MoveLp            ; Continue through all 1,500 selected dots
    RET                     ; Return after this frame's motion half

; ==============================================================================
; Complete Direct Layer 2 Renderer
; Uses write-only paging so one OUT replaces two MMU changes per page switch.
; ==============================================================================
DrawDots:
    LD A,(BckBank)          ; A = true back-buffer base for this frame
    NEXTREG RegL2Shad,A     ; Point Layer 2 shadow paging at that buffer
    LD A,$CB                ; Shadow + visible + write, full 48K window
    LD BC,PortL2            ; BC = Layer 2 access port $123B
    OUT (C),A               ; Map Layer 2 writes across $0000-$BFFF

    EXX                     ; Select shadow registers for the draw counter
    LD DE,Stars             ; Shadow DE = 3,000 pixels to render
    EXX                     ; Return to the main draw registers
    LD IX,DotX              ; IX walks current X coordinates
    LD IY,DotY              ; IY walks current Y coordinates
DrawLp:
    LD L,(IX+0)             ; L = X, the low byte of the pixel offset
    LD H,(IY+0)             ; H = Y, the high byte of the pixel offset
    INC IX                  ; Advance the current-X pointer
    INC IY                  ; Advance the current-Y pointer
    EXX                     ; Select the shadow draw counter
    LD A,E                  ; A = stable color derived from particle order
    OR 1                    ; Avoid black while retaining 128 rainbow entries
    EXX                     ; Restore the direct pixel address in HL
    LD (HL),A               ; Write the pixel through Layer 2 write paging

    EXX                     ; Select the shadow 16-bit draw counter
    DEC DE                  ; Decrement remaining particles
    LD A,D                  ; Inspect the high counter byte
    OR E                    ; Test the complete counter for zero
    EXX                     ; Restore the main motion registers
    JP NZ,DrawLp            ; Loop for all 3,000 dots
    LD BC,PortL2            ; BC = Layer 2 access port $123B
    LD A,$02                ; Keep Layer 2 visible but remove write paging
    OUT (C),A               ; Restore normal CPU memory writes
    RET                     ; Return with all 3,000 particles rendered

; ==============================================================================
; Gradient Speed Divider Subroutine
; Throttles palette rotation to 1 step every GradSpd frames
; Outputs: Palette rotated when counter hits 0
; Clobbers: AF, BC, DE, HL
; ==============================================================================
UpdGrad:
    LD A,(SpdCnt)           ; Load current speed divider counter
    DEC A                   ; Decrement frame divider counter
    LD (SpdCnt),A           ; Store updated divider counter
    RET NZ                  ; If count > 0, wait for next frame

    LD A,GradSpd            ; Reload divider preset value (2 frames)
    LD (SpdCnt),A           ; Reset speed divider counter in RAM
    CALL SlowPal            ; Shift entire 254-color gradient left by 1 step
    RET                     ; Return after palette shift

; ==============================================================================
; Slow Smooth Palette Gradient Shifter Subroutine
; Rotates 254-color continuous rainbow left by 1 step, preserving background (0)
; Outputs: PalBuf shifted by 1 position and uploaded to Layer 2 hardware
; Clobbers: AF, BC, DE, HL
; ==============================================================================
SlowPal:
    LD A,(PalBuf+1)         ; Read first gradient color byte (entry 1)
    LD (PalTmp),A           ; Save entry 1 into temporary byte
    LD HL,PalBuf+2          ; Source address: palette entry 2
    LD DE,PalBuf+1          ; Destination address: palette entry 1
    LD BC,253               ; BC = 253 bytes to shift (entries 2..254)
    LDIR                    ; Block transfer to shift entire gradient left by 1
    LD A,(PalTmp)           ; Load saved entry 1 color byte
    LD (PalBuf+254),A       ; Place wrapped color at entry 254
    CALL SetPal             ; Upload updated smooth palette to Layer 2 hardware
    RET                     ; Return with smooth 1-step shifted palette

; ==============================================================================
; VBlank Frame Synchronizer (25 Hz workload on a 50 Hz raster)
; Polls raster line register to synchronize execution with vertical blank
; Outputs: None
; Clobbers: AF, BC
; ==============================================================================
WaitFrm:
    LD BC,PortNext          ; NextReg register select port ($243B)
    LD A,RegLineLo          ; Select raster line LSB register ($1F)
    OUT (C),A               ; Send register select command
    INC B                   ; Advance to NextReg data port ($253B)
WaitF1:
    IN A,(C)                ; Read current raster line LSB
    OR A                    ; Check if beam is currently at line 0
    JR Z,WaitF1             ; Wait until raster beam leaves line 0
WaitF2:
    IN A,(C)                ; Read current raster line LSB
    OR A                    ; Check if raster beam wrapped to line 0
    JR NZ,WaitF2            ; Wait until raster beam hits top line 0
    RET                     ; Return synchronized to vertical blank

; ==============================================================================
; 16-Bit 8-Shift Galois LFSR Pseudo-Random Number Generator
; Performs 8 Galois shift iterations per call for full 2D byte decorrelation
; Outputs: HL = 16-bit pseudo-random value
; Clobbers: AF, HL
; ==============================================================================
RndNum:
    LD HL,(RndSeed)         ; Load current 16-bit seed
    LD A,H                  ; High byte
    OR L                    ; Test if seed is zero
    JR NZ,RndNz             ; If non-zero, proceed
    LD HL,$ACE1             ; Non-zero fallback seed
RndNz:
    PUSH BC                 ; Preserve BC register
    LD B,8                  ; Perform 8 LFSR shifts for full 8-bit decorrelation
RndLp:
    SRL H                   ; Shift high byte right by 1, bit 0 into carry
    RR L                    ; Shift low byte right by 1 with carry
    JR NC,RndNoX            ; If carry == 0, no feedback XOR needed
    LD A,H                  ; Load high byte
    XOR $B4                 ; Apply Galois feedback polynomial $B400
    LD H,A                  ; Store updated high byte
RndNoX:
    DJNZ RndLp              ; Repeat for all 8 bits
    POP BC                  ; Restore BC register
    LD (RndSeed),HL         ; Store updated 16-bit seed back to RAM
    RET                     ; Return with decorrelated 16-bit random word

; ==============================================================================
; Random Coordinate Helper Subroutines
; ==============================================================================

; --- Generate an Unbiased Full-Screen Coordinate Pair ---
; Outputs: C = X (0..255), D = Y (0..191)
; Clobbers: AF, HL
GetRndXY:
    CALL RndNum             ; Generate fresh random word in HL
    LD A,H                  ; Use the high byte as the Y candidate
    CP 192                  ; Test the candidate against screen height
    JR NC,GetRndXY          ; Reject 192..255 instead of folding bias
    LD C,L                  ; C = paired full-width X coordinate
    LD D,A                  ; D = accepted unbiased Y coordinate
    RET                     ; Return both coordinates from one PRNG word

    ; --- Include Program Variables & Character Font Tables ---
    INCLUDE "Libraries/lib/data.asm"

; ==============================================================================
; Nex Executable Generation Directives
; ==============================================================================
    SAVENEX OPEN "rnddots.nex", Start, StackTop
    SAVENEX CORE 3, 1, 2
    SAVENEX CFG 0, 0, 0, 0
    SAVENEX AUTO
    SAVENEX CLOSE
