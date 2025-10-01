📌 Overview

This project is a custom CPU implementation written in Verilog HDL, designed with a modular and educational approach.
It follows a 5-stage pipeline architecture (Fetch, Decode, Execute, Memory, Write-Back) and integrates support for arithmetic, logic, multiplication, and division instructions.

The project can be used as:

A learning resource for computer architecture and digital design courses.

A reference CPU design for FPGA or simulation projects.

A foundation for further extensions such as caches, branch prediction, or out-of-order execution.

⚙️ Features

Pipeline design: 5-stage pipeline (IF → ID → EXE → MEM → WB).

ALU operations: Basic arithmetic and logic.

Multiplication & Division: Dedicated hardware units (multiply.v, division.v).

Top-level integration: Central control in mycpu_top.v.

Modular structure: Each stage is separated into its own Verilog module.

Scalable: Easy to extend with new instructions or optimizations.

📂 Project Structure
mycpu/
│── mycpu.xpr        # Vivado project file
│── mycpu_top.v      # Top-level CPU integration
│── fetch.v          # Instruction Fetch stage
│── decode.v         # Instruction Decode stage
│── exe.v            # Execute stage
│── alu.v            # Arithmetic Logic Unit
│── multiply.v       # Multiplier unit
│── division.v       # Divider unit
│── mem.v            # Memory access stage
│── wb.v             # Write-back stage

🚀 Getting Started
Requirements

Vivado (recommended for simulation and synthesis)

Or any Verilog simulator such as Icarus Verilog, ModelSim, or Verilator


# Run simulation
vvp cpu_sim

Run (Vivado)

Open mycpu.xpr in Vivado.

Run synthesis and implementation.

Simulate testbench or generate bitstream for FPGA deployment.
