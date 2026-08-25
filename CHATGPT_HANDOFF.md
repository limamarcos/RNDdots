# ZX Spectrum Next: Cosmic Particle Swarm (2,000 Dots) - Handoff Guide

## 1. Project Overview & Objective

This project is a high-performance **Layer 2 256x192 8bpp assembly demo** for the **ZX Spectrum Next (Z80N @ 28 MHz)**, assembled using `sjasmplus`.

### Core Visual Concept
1. **Cosmic Starfield (Home State)**: 2,000 glowing particles are uniformly distributed across the full $256 \times 192$ screen with unique rainbow colors and independent speeds.
2. **Character Formation**: The particles rapidly fly inward from their scattered positions to congregate at the center of the screen, forming a giant scaled Sinclair font character (e.g. 'A'..'Z', '0'..'9', '!').
3. **Hold & Shimmer**: The solid giant character holds in place at the center for ~1.2 seconds while a 254-color continuous rainbow palette smoothly cycles through the particles.
4. **Dissolution / Explosion**: The character breaks apart/dissolves as all 2,000 particles fly away at individual speeds back to their home starfield positions (or explode radially into new positions).
5. **Infinite Morphing**: The cycle repeats seamlessly with fresh characters and fresh cosmic distributions.

---

## 2. Technical Environment & Build System

- **Target Architecture**: ZX Spectrum Next (Z80N CPU @ 28 MHz, NextRegs enabled).
- **Display Resolution**: Layer 2 **256x192 8bpp**, Double-Buffered (50 FPS VBlank synchronized).
  - $X \in 0..255$ (single 8-bit unsigned integer).
  - $Y \in 0..191$ (single 8-bit unsigned integer).
- **Assembler**: `sjasmplus` v1.20.3
  - Build command: `sjasmplus main.asm`
  - Output binary: `rnddots.nex`
- **Coding Constraints (Retro-Code Standards)**:
  - **All symbol and label names MUST be $\le 10$ characters** (CamelCase, e.g. `GenTargets`, `DecodeChr`, `PlotPix`).
  - **Every single assembly line MUST be fully commented** explaining registers and pedagogical intent.
  - Z80N extended instructions are fully supported (`NEXTREG`, `MUL D,E`, `LDIR`, `ADD HL,BC`, `PUSH/POP`, etc.).

---

## 3. Memory Map & Particle Data Buffers

The demo runs at `$C000-$FFFF` (Slot 6 & 7 in Bank 0). Particle data for all **2,000 particles** is stored in dedicated mapped 8K RAM banks:

| Bank | CPU Slot | Address Range | Array Name | Size | Purpose |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Bank 8** | **Slot 0** | `$0000-$07CF` | `DotX` | 2,000 B | Current $X$ coordinate ($0..255$) |
| **Bank 8** | **Slot 0** | `$0800-$0FCF` | `DotY` | 2,000 B | Current $Y$ coordinate ($0..191$) |
| **Bank 8** | **Slot 0** | `$1000-$17CF` | `HomeX` | 2,000 B | Home scatter origin $X$ ($0..255$) |
| **Bank 8** | **Slot 0** | `$1800-$1FCF` | `HomeY` | 2,000 B | Home scatter origin $Y$ ($0..191$) |
| **Bank 9** | **Slot 1** | `$2000-$27CF` | `DotTX` | 2,000 B | Target $X$ destination ($0..255$) |
| **Bank 9** | **Slot 1** | `$2800-$2FCF` | `DotTY` | 2,000 B | Target $Y$ destination ($0..191$) |
| **Bank 9** | **Slot 1** | `$3000-$37CF` | `DotCol` | 2,000 B | Particle palette color index ($1..254$) |
| **Bank 9** | **Slot 1** | `$3800-$3FCF` | `DotSpd` | 2,000 B | Individual particle speed shift code ($1..3$) |
| — | **Slot 2-3** | `$4000-$7FFF` | *Layer 2 Back* | 16 KB | Mapped on-demand by `PlotPix` and `ClrBack` |
| — | **Slot 5** | Top at `$BFFF`| `StackTop` | — | CPU Stack Pointer |
| **Bank 0** | **Slot 6-7** | `$C000-$FFFF` | *Code & Font* | 16 KB | Main program code, library routines, Font table |

---

## 4. Universal Library System

The project relies on modular assembly libraries located in `Libraries/`:

### A. `Libraries/inc/config.inc`
Sets up Layer 2 double-buffering presets:
```z80
FrontBase:  EQU 16          ; Front buffer base 16K bank (Banks 16..18 = 48K)
BackBase:   EQU 19          ; Back buffer base 16K bank (Banks 19..21 = 48K)
BankCnt:    EQU 3           ; 3 banks of 16K = 48 KiB total per buffer
StackTop:   EQU $BFFF       ; Safe stack pointer location
FillByte:   EQU $00         ; Background clear color (0 = black)
```

### B. `Libraries/lib/layer2.asm`
Provides core double-buffering and plotting primitives:
- `InitL2`: Initializes Layer 2 256x192 8bpp mode, sets clip window ($0..255, 0..191$).
- `ClrBack`: Clears the 48 KB back buffer using fast zxnDMA fill.
- `SwapBuf`: Flips the back buffer to the front display at VBlank.
- `PlotPix`: Fast clipped pixel plotter in 256x192 row-major mode:
  - **Inputs**: `C = X (0..255)`, `D = Y (0..191)`, `E = Color (1..254)`.
  - **Clobbers**: `AF, HL`.
  - Maps appropriate 16K bank (`BackBase + (Y >> 6)`) into `$4000-$7FFF` via `CurBank` cache.
  - Address: `H = $40 | (Y & 63)`, `L = X`, then `LD (HL), E`.

### C. `Libraries/lib/palette.asm`
- `GenPal`: Generates a smooth 254-color continuous rainbow in RAM (`PalBuf`).
- `SetPal`: Uploads the palette to Layer 2 hardware palette registers.

### D. `Libraries/lib/dma.asm` & `copper.asm`
- `DmaClear`: High-speed zxnDMA memory fill of `$4000-$7FFF` with `FillByte`.
- `InitCop`, `SendCop`, `StopCop`: Copper coprocessor control.

---

## 5. Key Routines in `main.asm`

### 1. Main Execution Loop (`MainLp`)
```z80
MainLp:
    ; 1. Form Character Phase (~0.5s)
    CALL PickChr            ; Select random ASCII char (33..90)
    CALL DecodeChr          ; Decode 8x8 font matrix into active block table GlyphBlk
    CALL GenTargets         ; Assign target coordinates (DotTX, DotTY) and speeds (1..3)
    LD HL,CnvFrms           ; HL = 25 frames (~0.5s)
    CALL RunFrames          ; Animate dots flying from Home -> Character

    ; 2. Hold & Shimmer Phase (~1.2s)
    LD HL,HoldFrms          ; HL = 60 frames (~1.2s)
    CALL RunFrames          ; Hold solid character while palette shifts

    ; 3. Dissolve Phase (~0.5s)
    CALL Dissolve           ; Set Target = Home positions (HomeX, HomeY) & random speeds
    LD HL,ExpFrms           ; HL = 25 frames (~0.5s)
    CALL RunFrames          ; Animate dots flying from Character -> Home

    ; 4. Starfield Re-Seeding
    CALL NewHomes           ; Re-randomize HomeX and HomeY for next cycle

    JP MainLp               ; Loop infinitely
```

### 2. PRNG Routine (`RndNum`)
A verified, stack-safe **16-bit 8-shift Galois LFSR** with polynomial `$B400`:
- **Outputs**: `HL` = 16-bit pseudo-random word, `A` = `L`.
- `GetRndX`: Returns `C = L` ($0..255$, 100% uniform across all 256 screen columns).
- `GetRndY`: Returns `D = L % 192` ($0..191$, 100% uniform across all 192 screen rows).
- `GetCol`: Returns `E` ($1..254$, preserves black background `0`).
- `GetRndSpd`: Returns `A` ($1..3$, speed shift code).

### 3. Font Decoding & Scaling (`DecodeChr` & `GenTargets`)
- `FontData`: Complete Sinclair 8x8 font table (ASCII 32 ' ' to 95 '_', 512 bytes).
- `DecodeChr`: Scans the 8x8 font byte matrix for the selected character, extracts active solid pixel coordinates `(gridX, gridY)` ($0..7, 0..7$), and writes them to `GlyphBlk` (up to 64 blocks, count stored in `NumBlk`).
- `GenTargets`: For each of the 2,000 dots, picks a random active block from `GlyphBlk`, computes centered $(X, Y)$ with intra-block jitter, and stores into `DotTX` and `DotTY`.

### 4. Motion Physics Engine (`UpdDots`)
Iterates through all 2,000 dots each frame:
- Reads `CurSpd` ($1..3$).
- Ease-out step calculation:
  $$\Delta X = \max(1, |TargetX - CurrentX| \gg CurSpd)$$
  $$\Delta Y = \max(1, |TargetY - CurrentY| \gg CurSpd)$$
- Moves `DotX` and `DotY` toward `DotTX` and `DotTY`.
- Calls `PlotPix` at `(C=DotX, D=DotY)` with `E=DotCol`.

---

## 6. Tasks Addressed in Implementation

### Task 1: Eliminate Left-Bias in Character Centering
- In `DecodeChr`, the exact bounding box of the active glyph is determined ($MinX, MaxX, MinY, MaxY$).
- Exact centering offsets $BaseX$ and $BaseY$ are calculated dynamically so every glyph is dead-center on screen.

### Task 2: Refine Character Formation & Dissolution Dynamics
- Multi-velocity speed classes based on particle order.
- Direct Layer 2 write paging for high performance 3,000 dot rendering at 25 Hz motion pacing.
- Real-time 254-color continuous rainbow palette cycling.
