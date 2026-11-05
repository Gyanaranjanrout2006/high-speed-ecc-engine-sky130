# High-Speed Silicon-Ready ECC Subsystem on SkyWater 130nm

A high-reliability, tapeout-ready Error Correction Code (ECC) IP subsystem supporting 32-bit Hamming SEC-DED logic, multi-bit BCH error correction, a 300 MHz 3-stage pipelined engine, and an autonomous Built-In Self-Test (BIST) & Hardware Fault Injection Unit (FIU).

Implemented from behavioral RTL modeling down to complete GDSII physical sign-off using open-source semiconductor toolflows on the SkyWater 130nm (`sky130_fd_sc_hd`) standard cell library.

---

## Architecture Highlights

1. **32-Bit Hamming SEC-DED Engine**
   - Single Error Correction, Double Error Detection covering 32-bit data using 7 parity bits (39-bit codeword).
   - Optimized parallel XOR parity generation and fast syndrome matrix decoding.

2. **AXI4-Lite Bus Protocol Interface**
   - Standard 32-bit memory-mapped AXI4-Lite slave wrapper for seamless integration into RISC-V and ARM SoC memory architectures.

3. **Multi-Bit BCH (15,7) Engine**
   - Implements Galois Field $GF(2^4)$ arithmetic for correcting up to 2 random bit errors in high-density non-volatile memory (NVM/Flash).

4. **3-Stage High-Speed Pipelined Core (300 MHz)**
   - Datapath pipelining separating parity generation, syndrome calculation, and error correction logic.
   - Eliminates combinatorial bottlenecks, achieving zero timing violations at a 3.33 ns clock period.

5. **Hardware BIST & Fault Injection Unit (FIU)**
   - Autonomous on-chip self-testing targeted for mission-critical and ISO 26262 ASIL-D automotive safety requirements.
   - Built-in 32-bit LFSR (Pseudo-Random Pattern Generator) and deterministic single/double-bit fault injector with automated self-checking FSM.

---

## Physical Implementation & Sign-off Results (SkyWater 130nm)

| Block / Architecture | Target Clock | Setup Slack (WNS) | Hold Slack (WHS) | Magic DRC | KLayout XOR vs Magic |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Hamming SEC-DED Base** | 10.0 ns (100 MHz) | 0.00 ns (Met) | 0.00 ns (Met) | 0 Violations | Clean |
| **AXI4-Lite Bus Core** | 10.0 ns (100 MHz) | 0.00 ns (Met) | 0.00 ns (Met) | 0 Violations | Clean |
| **Multi-Bit BCH Engine** | 10.0 ns (100 MHz) | 0.00 ns (Met) | 0.00 ns (Met) | 0 Violations | Clean |
| **3-Stage Pipeline Core** | **3.33 ns (300 MHz)** | **0.00 ns (Met)** | **0.00 ns (Met)** | **0 Violations** | **Clean** |
| **BIST & Fault Injection Unit** | 10.0 ns (100 MHz) | 0.00 ns (Met) | 0.00 ns (Met) | 0 Violations | Clean |

---

## Project Structure

```text
├── rtl/
│   ├── ecc_encoder.v         # 32-to-39 bit Hamming parity generator
│   ├── ecc_decoder.v         # Syndrome decoder and single-bit corrector
│   ├── ecc_engine_top.v      # Integrated SEC-DED top module
│   ├── axi_ecc_engine.v      # AXI4-Lite SoC slave interface
│   ├── bch_encoder_15_7.v    # BCH Galois Field parity encoder
│   ├── bch_decoder_15_7.v    # BCH multi-bit syndrome search and corrector
│   ├── bch_engine_top.v      # Multi-bit BCH top module
│   ├── ecc_pipelined_top.v   # 3-stage high-throughput 300 MHz core
│   └── ecc_bist_fiu_top.v    # Self-test controller with LFSR & FIU
├── tb/
│   ├── tb_ecc_engine.v       # Base testbench verifying SEC & DED flags
│   ├── tb_ecc_pipelined.v    # Pipeline latency and throughput verification
│   └── tb_ecc_bist_fiu.v     # BIST automated verification testbench
├── gds/
│   ├── ecc_pipelined_top.gds # 300 MHz silicon mask layout
│   └── ecc_bist_fiu_top.gds  # BIST diagnostic unit layout
└── README.md
