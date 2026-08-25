# Cosmic Particle Swarm (3,000 Dots) for ZX Spectrum Next

![Platform](https://img.shields.io/badge/Platform-ZX%20Spectrum%20Next-red?style=flat-square)
![CPU](https://img.shields.io/badge/CPU-Z80N%20%40%2028%20MHz-blue?style=flat-square)
![Display](https://img.shields.io/badge/Graphics-Layer%202%20256x192%208bpp-purple?style=flat-square)
![Assembler](https://img.shields.io/badge/Assembler-SjASMPlus%20v1.20%2B-green?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-orange?style=flat-square)

An ultra-high-performance generative particle simulation and visual demo for the **ZX Spectrum Next (Z80N)**.

3,000 glowing particles uniformly scatter across a $256 \times 192$ cosmic starfield, accelerate inward along non-linear ease-out trajectories to congeal into giant centered font glyphs, shimmer across a continuous 254-color spectral gradient, and explode outward to fresh unbiased scatter coordinates in an infinite morphing cycle.

---

## Visual Concept & Mechanics

1. **Cosmic Starfield (Home State)**: 3,000 glowing particles are uniformly distributed across the full $256 \times 192$ screen with unique rainbow colors and multi-velocity speed classes.
2. **Character Formation**: The swarm rapidly flies inward from all directions, congregating at the center of the display to form scaled Sinclair font characters (ASCII 33 `'!'` through 122 `'z'`).
3. **Continuous Rainbow Shimmer**: A 254-color continuous spectral palette dynamically shifts across all active particles during flight and transitions.
4. **Organic Dissolution / Radial Scatter**: Dots break apart from the glyph and fly away toward fresh pseudo-random targets across the cosmos.
5. **Infinite Morphing**: The engine continuously cycles through characters with dynamic entropy-seeded trajectories.

---

## Technical Highlights & Architecture

- **High-Throughput Particle Engine**:
  - Simulates and renders **3,000 independent particles** in real time on 8-bit Z80N silicon @ 28 MHz.
  - Employs an interleaved motion updater (1,500 alternating particles per frame) to maintain smooth, jitter-free 25 Hz particle physics on a 50 Hz VBlank raster.
- **Layer 2 256x192 8bpp Double-Buffering**:
  - Full 48 KB front and back video buffers with hardware page flipping at vertical blanking.
  - Direct Layer 2 write paging (`OUT ($123B), $CB`) allowing one single write instruction per pixel without MMU remapping overhead.
  - Fast zxnDMA back-buffer clearing in $\sim 0.5\text{ ms}$.
- **Unbiased Mathematical Centering**:
  - Font decoder computes the exact bounding box $(\text{MinX}, \text{MaxX}, \text{MinY}, \text{MaxY})$ of each Sinclair font glyph in ROM ($3D00).
  - Calculates dynamic base offsets:
    $$\text{BaseX} = 128 - (\text{Width} \times 8) - (\text{MinX} \times 16)$$
    $$\text{BaseY} = 96 - (\text{Height} \times 8) - (\text{MinY} \times 16)$$
  - Ensures narrow characters (like `'I'`) and wide characters (like `'M'`) are placed dead-center on screen.
- **Galois LFSR PRNG with Hardware Entropy**:
  - 16-bit 8-shift Galois LFSR generator using polynomial `$B400`.
  - Rejection sampling guarantees 100% uniform distributions across $X \in [0..255]$ and $Y \in [0..191]$ without modulo distortion or banding.
  - Dynamic hardware entropy seed captured from the video raster scanline (`NextReg $1F`) and Z80 `R` register.
- **Clean Host-State Restorer (`ClExit.asm`)**:
  - Preserves initial machine state and MMU configuration.
  - Pressing `SPACE` halts the demo, restores NextRegs and interrupts, and safely returns to NextZXOS / NextBASIC.

---

## Memory Map & Coordinate Arrays

All coordinate data is packed within MMU slots 4 & 5 (`$8000-$BFFF`):

| Address Range | Array | Size | Description |
| :--- | :--- | :--- | :--- |
| `$8000-$8BB7` | `DotX` | 3,000 B | Current particle $X$ coordinate ($0..255$) |
| `$8C00-$97B7` | `DotY` | 3,000 B | Current particle $Y$ coordinate ($0..191$) |
| `$9800-$A3B7` | `DotTX` | 3,000 B | Target destination $X$ coordinate ($0..255$) |
| `$A400-$AFB7` | `DotTY` | 3,000 B | Target destination $Y$ coordinate ($0..191$) |
| `$B000-$BFFF` | `Stack` | 4 KiB | Downward CPU system stack |
| `$C000-$FFFF` | `Code` | 16 KiB | Main engine, libraries, and Sinclair ROM font decoder |

---

## Universal ZX Spectrum Next Graphics Library Suite

This project includes the modular **Universal Next Graphics Library Suite** (`Libraries/`):

- **`hw.inc`**: Complete hardware equates for Next I/O ports and NextRegs.
- **`layer2.asm`**: Layer 2 driver, double-buffering, bank caching, and pixel plotting.
- **`dma.asm`**: zxnDMA high-speed buffer clearing, palette streaming, and memory copying.
- **`palette.asm`**: 254-color natural light spectrum generator and smooth shimmer rotator.
- **`copper.asm`**: Copper coprocessor list builder and manager.
- **`sine.asm`**: 256-entry signed trigonometric table with 8-bit page indexing.

---

## Building and Running

### Prerequisites
- [SjASMPlus](https://github.com/z00m128/sjasmplus) (v1.20.3 or later)
- Make (optional)

### Build
To assemble the `.nex` executable:
```bash
sjasmplus main.asm
```
or simply:
```bash
make
```
This generates `rnddots.nex`.

### Running the Demo
- **Real Hardware**: Copy `rnddots.nex` to your SD card and launch via the NextZXOS browser.
- **CSpect Emulator**:
  ```bash
  CSpect.exe -w3 -zxnext -nextrom -mmc=your_sd_card.img rnddots.nex
  ```
- **ZEsarUX Emulator**:
  ```bash
  zesarux --machine TBBlue --enable-esxdos-handler rnddots.nex
  ```

### Controls
- <kbd>SPACE</kbd> : Cleanly exit the demo and return to NextZXOS / NextBASIC prompt.

---

## Project Structure

```text
.
├── CHATGPT_HANDOFF.md       # Architecture & handoff specification guide
├── ClExit.asm                # Host-state capture and clean exit system
├── Libraries/                # Universal ZX Spectrum Next Graphics Library
│   ├── inc/config.inc        # Project configuration preset (Layer 2 256x192)
│   ├── lib/
│   │   ├── copper.asm        # Copper coprocessor manager
│   │   ├── data.asm          # Demo variables and working buffers
│   │   ├── dma.asm           # zxnDMA driver
│   │   ├── hw.inc            # Hardware ports and NextReg equates
│   │   ├── layer2.asm        # Layer 2 double-buffering driver
│   │   ├── palette.asm       # Rainbow spectrum generator
│   │   └── sine.asm          # Sine / cosine lookup table
│   ├── test/                 # Test harness
│   │   └── test_main.asm     # Verification test program
│   └── README.md             # Library documentation
├── Makefile                  # Build automation
├── README.md                 # Project documentation
├── main.asm                  # Main demo source code
└── rnddots.nex               # Assembled executable binary
```

---

## License

Released under the [MIT License](LICENSE).
