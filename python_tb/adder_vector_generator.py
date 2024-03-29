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
POSIT_WIDTH = 6
POSIT_ES = 0
set_posit_env(POSIT_WIDTH, POSIT_ES)
# A = Posit()
# A.set_bit_pattern("00000001")
# print(float(A+A))

def generate_vectors_forloop(nb_test=100):
    opA = Posit()
    opB = Posit()
    opC = Posit()
    with open(INPUT_PATH, "w") as in_file:
        with open(OUTPUT_PATH, "w") as out_file:
            for i in range(nb_test):
                bitstring = format(i, '#0' + str(POSIT_WIDTH+2) + 'b')[2:] # create a string of unsigned binary representation 0paded to left and remove the '0b'
                opA.set_bit_pattern(bitstring)
                opB.set_bit_pattern(bitstring)
                in_file.write(bitstring*2) # replicate twice
                in_file.write('\n')        # add new line for sv TB 
                opC = opA + opB
                out_bitstring = format(opC.number,'#0' + str(POSIT_WIDTH+2) + 'b')[2:]
                out_file.write(out_bitstring)
                out_file.write('\n')

def generate_vectors_ALL():
    opA = Posit()
    opB = Posit()
    opC = Posit()
    with open(INPUT_PATH, "w") as in_file:
        with open(OUTPUT_PATH, "w") as out_file:
            for i in [x for x in range(0,(2**POSIT_WIDTH)) if x != (2**POSIT_WIDTH)/2]:
                for j in [y for y in range(0,(2**POSIT_WIDTH)) if y != (2**POSIT_WIDTH)/2]:
                    bitstringA = format(i, '#0' + str(POSIT_WIDTH+2) + 'b')[2:] # create a string of unsigned binary representation 0paded to left and remove the '0b'
                    bitstringB = format(j, '#0' + str(POSIT_WIDTH+2) + 'b')[2:] # create a string of unsigned binary representation 0paded to left and remove the '0b'
                    opA.set_bit_pattern(bitstringA)
                    opB.set_bit_pattern(bitstringB)
                    in_file.write(bitstringA)
                    in_file.write(bitstringB)
                    strin = '  // ' + str(opA) + ' + ' +  str(opB) + '\n'
                    in_file.write(strin)
                    opC = opA + opB
                    out_bitstring = format(opC.number,'#0' + str(POSIT_WIDTH+2) + 'b')[2:]
                    out_file.write(out_bitstring)
                    strout = '  // ' + str(opC) + '\n'
                    out_file.write(strout)

def generate_vectors_ALL_split(nsplit=4):
    opA = Posit()
    opB = Posit()
    opC = Posit()
    for k in range(0,nsplit):
        with open(INPUT_PATH+str(k), "w") as in_file:
            with open(OUTPUT_PATH+str(k), "w") as out_file:
                for i in [x for x in range(k*((2**POSIT_WIDTH)//nsplit),(k+1)*((2**POSIT_WIDTH)//nsplit)) if x != (2**POSIT_WIDTH)/2]:
                    for j in [y for y in range(0,(2**POSIT_WIDTH)) if y != (2**POSIT_WIDTH)/2]:
                        bitstringA = format(i, '#0' + str(POSIT_WIDTH+2) + 'b')[2:] # create a string of unsigned binary representation 0paded to left and remove the '0b'
                        bitstringB = format(j, '#0' + str(POSIT_WIDTH+2) + 'b')[2:] # create a string of unsigned binary representation 0paded to left and remove the '0b'
                        opA.set_bit_pattern(bitstringA)
                        opB.set_bit_pattern(bitstringB)
                        in_file.write(bitstringA)
                        in_file.write(bitstringB)
                        strin = '  // ' + str(opA) + ' + ' +  str(opB) + '\n'
                        in_file.write(strin)
                        opC = opA + opB
                        out_bitstring = format(opC.number,'#0' + str(POSIT_WIDTH+2) + 'b')[2:]
                        out_file.write(out_bitstring)
                        strout = '  // ' + str(opC) + '\n'
                        out_file.write(strout)

def main():
    # generate_vectors_forloop(1000)
    generate_vectors_ALL()
    #generate_vectors_ALL_split(6)

if __name__ == '__main__':
    main()
