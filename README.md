# POF (Posit Operators Framework) - Documentation

## Overview
The Posit Operators Framework (POF) is a comprehensive library designed to facilitate arithmetic computations and neural network operations using the Posit numerical format on FPGAs. POF provides a set of custom-built hardware description language (HDL) files and software to implement and test precise and efficient arithmetic operations. With a focus on neural network applications, POF includes necessary components to deploy and run multi-layer perceptrons, termed 'positrons,' utilizing the benefits of the Posit format for optimized accuracy and performance.

## Project Structure
The POF project is organized into several key directories, each serving a specific purpose in the workflow for FPGA representation and computation of Posit arithmetic and neural network operations.

### `pynq_soft`
Contains the Python scripts and datasets required for interfacing with the Xilinx PYNQ environment. The files here execute on a PYNQ-compatible FPGA board, such as the Artix series, and drive the hardware resources utilizing the Posit operations.

- `MNIST_posit.py`: A Python script that runs an MNIST digit recognition algorithm using posits.
- `posit_mnist_test_*.raw`: Test vectors and datasets in raw format, utilized by the Posit arithmetic scripts.

### `python_tb`
Includes the Python testbench scripts for generating test vectors that are further used to validate the HDL modules in the `tb` directory.

- `adder_vector_generator.py`: Generates test vectors for validating Posit adder modules.

### `src`
Holds all the HDL source files implemented in SystemVerilog, Verilog, and VHDL. These files define the low-level logic for Posit arithmetic operations, the quire data structure, and various utilities required for Posit computations and neural network layers.

### `tb`
Contains the SystemVerilog test benches for verifying the HDL modules defined in the `src` directory. Accompanying the testbenches are input and output vectors for comprehensive testing of each module.

- `tb_*`: Individual testbenches for the modules found in `src`.
- `vectors`: Contains text files with the input and output vectors used by testbenches.

### `weights`
This directory structure mirrors the architecture of a multi-layer perceptron. It includes subdirectories corresponding to different posit widths, each containing text files representing the Posit-encoded weights for individual neurons.

- `*_0`: Folders labeled with a number followed by `_0` correspond to posit configurations (e.g., `8_0` for an 8-bit posit with 0 exponent bits).
- `hidden_weights_*`: Contain the weights used in hidden layers of the neural network.
- `output_weights_*`: Contain the weights used in the output layer of the neural network.

## Getting Started
To utilize POF, a user must clone the repository onto a local machine with the necessary FPGA development toolkit installed (e.g., Xilinx Vivado). It is also required to have a PYNQ-compatible FPGA board for running the `pynq_soft` Python scripts.

1. Clone the POF repository to your local environment.
2. Open the FPGA development environment and import the source files from the `src` directory to create a new project.
3. Synthesize the design and generate the bitstream for your target FPGA device.
4. Flash the device with the generated bitstream, including the Posit neuron weights from the `weights` directory.
5. Run the Python scripts from `pynq_soft` on the PYNQ platform to execute Posit-based computations.

## Contributions
POF invites contributions from the academic and research community. For contributions related to improvements, optimizations, and novel applications of Posit arithmetic within FPGA contexts, please follow the standard Git workflow for proposing changes:

1. Fork the repository.
2. Create a branch for your feature (`git checkout -b your-new-feature`).
3. Commit your changes (`git commit -am 'Add some feature'`).
4. Push to the branch (`git push origin your-new-feature`).
5. Submit a pull request.

## License
This project is released under the [MIT License](LICENSE).

## Contact
For queries related to the Posit Operators Framework, please contact the maintainers at [your-email@domain.com].

