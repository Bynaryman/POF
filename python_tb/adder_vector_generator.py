#!/usr/bin/python3

# Import the libraries
from PySigmoid import *
from math import *

# set path of vectors for testbench
BASE_PATH   = "/home/lledoux/Desktop/PhD/fpga/P9_OPC/my_posits/tb/vectors/"
INPUT_PATH  = BASE_PATH + "adder_input_vector.txt"
OUTPUT_PATH = BASE_PATH + "adder_output_vector.txt" 

# set env
NB_TEST = 10
POSIT_WIDTH = 8
POSIT_ES = 0
set_posit_env(POSIT_WIDTH, POSIT_ES)

def generate_vectors_forloop():
    opA = Posit()
    opB = Posit()
    opC = Posit()
    with open(INPUT_PATH, "w") as in_file:
        with open(OUTPUT_PATH, "w") as out_file:
            for i in range(NB_TEST):
                bitstring = format(i, '#0' + str(POSIT_WIDTH+2) + 'b')[2:] # create a string of unsigned binary representation 0paded to left and remove the '0b'
                opA.set_bit_pattern(bitstring)
                opB.set_bit_pattern(bitstring)
                in_file.write(bitstring*2) # replicate twice
                in_file.write('\n')        # add new line for sv TB 
                opC = opA + opB
                out_bitstring = format(opC.number,'#0' + str(POSIT_WIDTH+2) + 'b')[2:]
                out_file.write(out_bitstring)
                out_file.write('\n')
def main():
    generate_vectors_forloop()

if __name__ == '__main__':
    main()
