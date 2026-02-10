![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg) ![](../../workflows/fpga/badge.svg)

# Herald - DSP Accelerator for TinyTapeout

**Herald** is a hardware digital signal processing (DSP) accelerator combining CORDIC trigonometric functions and multiply-accumulate (MAC) operations in a compact silicon design. Perfect for embedded math-intensive applications where software computation is too slow.

**[Complete Technical Documentation](docs/info.md)**

---

## What Does Herald Do?

Herald provides **8 hardware-accelerated mathematical operations** through a simple serial interface:

### CORDIC Trigonometry
- **sin/cos** - Compute sine and cosine simultaneously from an angle
- **atan2** - Find angle from x,y coordinates 
- **sqrt** - Calculate vector magnitude √(x² + y²)
- **normalize** - Get unit vector + magnitude in one operation

### MAC Arithmetic
- **multiply** - Fast fixed-point multiplication
- **mac** - Multiply-accumulate for dot products and filters
- **msu** - Multiply-subtract for adaptive algorithms
- **clear** - Reset accumulator

---

## Key Features

- **Hardware-accelerated math** - CORDIC and MAC operations in silicon  
- **Fixed-point arithmetic** - Q12.12 format (24-bit: 12 integer, 12 fractional)  
- **Simple serial interface** - 8-bit data bus with write/read strobes  
- **Low resource usage** - Optimized for TinyTapeout 2×2 tile design  
- **50 MHz operation** - Fast computation with deterministic latency  
- **Busy flag** - Easy polling for operation completion  

---

## Quick Start

### Interface Summary

| Signal | Direction | Purpose |
|--------|-----------|---------|
| `ui[7:0]` | Input | Data/command input bus |
| `uo[7:0]` | Output | Data output bus (**uo[7] = BUSY**) |
| `uio[0]` | Input | **WR** strobe (write data) |
| `uio[1]` | Input | **RD** strobe (read data) |

### Basic Usage

1. **Write command byte** (e.g., `0x10` for sin/cos)
2. **Write operand(s)** - 3 bytes each, LSB-first
3. **Poll BUSY flag** - Wait for `uo[7] = 0`
4. **Read result** - 3, 6, or 9 bytes depending on command

## Commands Reference

| Opcode | Command | Operands | Result Size | Description |
|--------|---------|----------|-------------|-------------|
| `0x10` | SINCOS | angle (3B) | 6 bytes | sin and cos of angle |
| `0x11` | ATAN2 | y (3B), x (3B) | 3 bytes | angle from coordinates |
| `0x12` | SQRT | x (3B), y (3B) | 3 bytes | magnitude √(x²+y²) |
| `0x13` | NORMALIZE | x (3B), y (3B) | 9 bytes | unit vector + magnitude |
| `0x20` | MULTIPLY | a (3B), b (3B) | 3 bytes | a × b |
| `0x21` | MAC | a (3B), b (3B) | 3 bytes | acc += a × b |
| `0x22` | CLEAR | none | none | reset accumulator |
| `0x23` | MSU | a (3B), b (3B) | 3 bytes | acc -= a × b |

All values are **Q12.12 fixed-point** (24-bit): 12 integer bits + 12 fractional bits  
**Range:** -2048.0 to +2047.999755859375  
**Resolution:** 1/4096 ≈ 0.000244

---

## Use Cases

- **Robotics** - Fast kinematics, inverse kinematics, trajectory planning
- **Signal Processing** - FIR/IIR filters using MAC operations
- **Computer Graphics** - Rotation matrices, vector normalization
- **Navigation** - Heading calculations, distance computations
- **Control Systems** - PID controllers with multiply-accumulate
- **Communication** - Phase calculations, modulation/demodulation

---

## Architecture

Herald consists of three main components:

1. **Control FSM** - Manages serial protocol (IDLE → CMD → DATA → EXECUTE → RESULT)
2. **CORDIC Engine** - Iterative rotation algorithm using only shifts/adds
3. **MAC Engine** - Fixed-point multiplier with internal accumulator

All computations use **Bluespec-generated Verilog** modules for optimal hardware utilization.

---

## Documentation

- **[Complete Technical Documentation](docs/info.md)** - Full command reference, protocol specs, examples  
- **[Testing Guide](test/README.md)** - How to run cocotb testbenches  
- **[Project Info](info.yaml)** - Pin mappings and metadata  

---