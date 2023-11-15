# POF (Posit Operators Framework) - Documentation

## Table of Contents
1. [Overview](#overview)
2. [Project Structure](#project-structure)
3. [Getting Started](#getting-started)
4. [Authors](#authors)

## Overview
The Posit Operators Framework (POF) is an advanced library intended to empower arithmetic calculations and neural network operations using Posit notation on FPGA technology. POF includes a comprehensive suite of hardware description language (HDL) files and corresponding software to execute and substantiate high-precision and efficient arithmetic computations, with a supportive focus on neural network applications. Through POF, it is possible to employ and test multi-layer perceptrons, described as 'positrons,' which capitalize on the Posit numerical format for superior accuracy and performance enhancements.

## Project Structure

```
POF/
├── pynq_soft/                  # Python scripts and datasets for PYNQ
│   ├── MNIST_posit.py          # MNIST recognition script using posits
│   └── *.raw                   # Posit test vectors and dataset files
├── python_tb/                  # Python testbench script generators
│   └── adder_vector_generator.py
├── README.md                   # Project documentation
├── src/                        # HDL source files
│   ├── *.sv                    # SystemVerilog modules
│   ├── *.v                     # Verilog modules
│   └── *.vhd                   # VHDL modules
├── tb/                         # Testbenches for HDL verification
│   ├── tb_*.sv                 # SystemVerilog testbench modules
│   └── vectors/                # Input and output test vectors
└── weights/                    # Text files of Posit neuron weights
    ├── *_0/
    │   ├── hidden_weights_*_0/
    │   │   └── hidden_weights_*
    │   └── output_weights_*_0/
    │       └── output_weights_*
└── ...
```

Each sub-folder is briefly described below:

- `pynq_soft/`: This directory houses the Python software for the execution of Posit-related computations on PYNQ (Artix FPGA) hardware.
- `python_tb/`: Contains scripts for the generation of testbench vectors that are utilized within the `tb` folder.
- `src/`: The source files crafted in various HDLs containing the foundations of arithmetic operations, including support for Posit-format calculations.
- `tb/`: This is where the test benches ensure the reliability and functionality of the HDL modules found in the `src` directory.
- `weights/`: Aligning with neural network architecture, this set of folders keeps the neuron weights for multi-layer perceptrons in text format, arranged for different Posit configurations.

## Getting Started

To get started with POF:

1. Clone the repository to your local system which should have the necessary FPGA development environment installed (e.g., Xilinx Vivado).
2. Launch the FPGA development application and incorporate the `src` directory's source files for a new FPGA project setup.
3. Proceed with the project synthesis and configure your target FPGA device with the resultant bitstream.
4. Assure that the bitstream flashed onto the FPGA includes the Posit neuron weights from the `weights` directory.
5. Utilize the PYNQ platform to run the Python scripts located in `pynq_soft`, which engage in Posit-based operations.

## Authors
For any inquiries concerning the Posit Operators Framework, the authors are available for contact:

- Me / Bynaryman / Louis Ledoux [@Bynaryman](https://github.com/Bynaryman)
- Marc Casas [@Marccg1](https://github.com/Marccg1)

Please consider reaching out to the authors regarding contribution proposals, usage queries, or academic collaborations.

