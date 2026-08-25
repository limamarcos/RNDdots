# Universal ZX Spectrum Next Graphics Library Suite

A modular, high-performance graphics library suite for the **ZX Spectrum Next (Z80N)**.

Designed to be **100% universal** across all future graphical Next projects, with native compatibility for both **Astrum Assembler** (on the Next) and **SjASMPlus** (cross-compiler).

---

## Directory Architecture

```text
Libraries/
├── lib/                    ; Reusable library modules
│   ├── hw.inc              ; Pure Next hardware equates (ports & NextRegs)
│   ├── sine.asm            ; 256-entry signed sine/cosine lookup table
│   ├── dma.asm             ; zxnDMA controller (clear, stream palette, copy)
│   ├── copper.asm          ; Copper coprocessor manager & uploader
│   ├── layer2.asm          ; Layer 2 driver, double-buffering & Bresenham
│   └── palette.asm         ; Natural spectral rainbow & velvet backdrops
├── inc/
│   └── config.inc          ; Project-specific configuration template
├── test/
│   └── test_main.asm       ; Verification test harness
└── README.md               ; Documentation and integration guide
```

---

## Library Standards & Coding Conventions

All modules adhere to strict 8-bit & Astrum compatibility rules:
1. **Symbol / Label Length**: Strictly `<= 10 characters` in `CamelCase` (e.g. `InitL2`, `ClrBack`, `PlotPix`, `DrawLine`, `DmaClear`, `InitCop`, `GenPal`).
2. **Pedagogical Line-by-Line Comments**: Every line of assembly code is commented with explanations of the *how* and *why*.
3. **No Proprietary Directives**: Library source files contain only standard `EQU`, `DB`, `DW`, `DS`, and pure Z80 / Z80N opcodes.
4. **Decoupled Configuration**: All memory bank allocations (`FrontBase`, `BackBase`, `BankCnt`) and stack configurations are specified in `config.inc`.

---

## Module Overview & API Reference

### 1. `hw.inc`
Universal hardware definitions for Next I/O ports and NextRegs:
- **Ports**: `PortNext` (`$243B`), `PortData` (`$253B`), `PortL2` (`$123B`), `PortDma` (`$006B`), `PortUla` (`$00FE`), `PortKey` (`$7FFE`).
- **Registers**: CPU speed (`RegSpeed`), Soft reset (`RegReset`), Layer 2 control (`RegL2Ctl`, `RegL2Bank`, `RegL2Clip`, `RegClipCt`, `RegScrXLo`, `RegScrXHi`, `RegScrY`), Palette (`RegPalIdx`, `RegPalVal`, `RegPalCtl`), MMU slots (`RegMMU0`..`RegMMU7`), Copper (`RegCopLo`, `RegCopHi`, `RegCopDat`), and Raster line (`RegLineHi`, `RegLineLo`).

### 2. `sine.asm`
- **Table**: `SineTab` (256 bytes, signed values `-127` to `+127`).
- **Sine lookup**: Index with angle `0..255`.
- **Cosine lookup**: Index with `(Angle + 64) & 255`.

### 3. `dma.asm`
- **`DmaClear`**: Fills the 16 KiB bank mapped at `$4000-$7FFF` with `FillVal` byte via zxnDMA continuous mode.
- **`DmaPal`**: Fast transfers 256 bytes from `PalBuf` in RAM to NextReg `$41` (palette data).
- **`DmaCopy`**: High-speed 16 KiB memory-to-memory block transfer from `DmaSrc` to `DmaDst`.

### 4. `copper.asm`
- **`InitCop`**: Builds a standard Copper list in `CopBuf`.
- **`SetCopBg`**: Sets backdrop color byte (`A` = `RRRGGGBB`).
- **`SendCop`**: Uploads `CopBuf` to hardware Copper RAM and arms VBlank automatic restart.
- **`StopCop`**: Safely halts the Copper coprocessor.

### 5. `layer2.asm`
- **`InitL2`**: Configures 320x256 8bpp mode, sets clip window (`0..159, 0..255`), resets scroll, sets layer priority, and enables port `$123B`.
- **`ClrBack`**: Clears all configured back buffer banks (`BankCnt` × 16 KiB) using `DmaClear`.
- **`SwapBuf`**: Performs page flipping at VBlank and invalidates MMU bank caching.
- **`PlotPix`**: Column-major pixel plotter (`BC` = X 0..319, `D` = Y 0..255, `E` = Color 1..255) with automatic MMU2/MMU3 bank caching.
- **`DrawLine`**: 16-bit Bresenham connected line algorithm (`BC` = X0, `D` = Y0, `HL` = X1, `A` = Y1, `E` = Color).

### 6. `palette.asm`
- **`GenPal`**: Generates a smooth 254-color natural light spectrum in `PalBuf` with selected velvet background (`BgRec` = `0..15`).
- **`SetPal`**: Streams 256-byte palette to hardware Layer 2 palette 0 during VBlank.
- **`ShimPal`**: Rotates color entries `1..254` left by 1 step at 50 FPS for a shimmering effect.
- **`BgTable`**: 16 curated velvet background hues (Obsidian, Midnight Navy, Burgundy Wine, Emerald Forest, etc.).

---

## Integration Example

### Using with Astrum Assembler (on ZX Spectrum Next)
```assembly
    INCLUDE "hw.inc"
    INCLUDE "config.inc"
    ORG $C000
    JP Start

    INCLUDE "sine.asm"
    INCLUDE "palette.asm"
    INCLUDE "dma.asm"
    INCLUDE "copper.asm"
    INCLUDE "layer2.asm"

Start:
    DI
    LD SP,StackTop
    NEXTREG RegSpeed,3
    CALL InitCop
    CALL InitL2
    CALL ClrBack
    CALL GenPal
    CALL SetPal
    CALL SendCop

MainLoop:
    ; Draw graphics here...
    JP MainLoop
```

### Using with SjASMPlus (Cross-Assembly)
```assembly
    DEVICE ZXSPECTRUMNEXT
    OPT --zxnext=on
    ORG $C000

    INCLUDE "hw.inc"
    INCLUDE "config.inc"
    INCLUDE "sine.asm"
    INCLUDE "palette.asm"
    INCLUDE "dma.asm"
    INCLUDE "copper.asm"
    INCLUDE "layer2.asm"

Start:
    DI
    LD SP,StackTop
    NEXTREG RegSpeed,3
    CALL InitCop
    CALL InitL2
    CALL ClrBack
    CALL GenPal
    CALL SetPal
    CALL SendCop

MainLoop:
    ; Draw graphics here...
    JP MainLoop

    SAVENEX OPEN "output.nex", Start, StackTop
    SAVENEX CORE 3, 1, 2
    SAVENEX CFG 0, 0, 0, 0
    SAVENEX AUTO
    SAVENEX CLOSE
```
