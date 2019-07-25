#!/opt/python3.6/bin/python3.6
print('flashing MNIST MLP POSIT NN bitstream...')
from pynq import Overlay
import pynq.lib.dma
import numpy as np
from pynq import Xlnk
import time
import struct
import gzip
import sys

NB_FRAMES = 10_000
FRAME_H = 28
FRAME_W = 28

def read_compress_idx(filename):
    with gzip.open(filename, 'rb') as f:
        zero, data_type, dims = struct.unpack('>HBB', f.read(4))
        shape = tuple(struct.unpack('>I', f.read(4))[0] for d in range(dims))
        return np.fromstring(f.read(), dtype=np.uint8).reshape(shape)

def pretty_print_np_arr(np_arr):
    for i in np_arr:
        for j in i:
            if j==0:
                print('   ', end='')
            else :
                print("%03d" % j, end='')
        print()

def read_raw_28_28_posit_pic(filename):
    with open(filename, 'r') as f:
        t = f.readlines()
        t2 = []
        for i in t:
            t2.append(int(i, 16))
        return np.array(t2, dtype=np.uint32)

def read_train_arch_posit_16(filename):
    return np.frombuffer(open(filename, "rb").read().decode('hex'), dtype=numpy.uint32).byteswap()


t = np.fromfile("posit_mnist_test_4_0_p1_MSB.raw", dtype=np.uint8).reshape(int(NB_FRAMES*FRAME_H*FRAME_W/2)) #.byteswap()
t.dtype = np.uint32
#np_arr = read_compress_idx('./train-images-idx3-ubyte.gz')
#pretty_print_np_arr(np_arr[NUMBER_TO_CLASSIFY])

# load the Overlay
overlay = Overlay('/home/xilinx/pynq/overlays/mnist/mnist.bit')

# load the NN DMA
NN_DMA = overlay.DMA

# 32b words DMA
N = 196 * NB_FRAMES


# Allocate buffers for the input and output buffers
xlnk = Xlnk()
in_buffer = xlnk.cma_array(shape=(int(N/2),), dtype=np.uint32)
out_buffer = xlnk.cma_array(shape=(int(10000),), dtype=np.uint32)
#out_buffer = xlnk.cma_array(shape=(int(1.25*NB_FRAMES),), dtype=np.uint32)

# Copy the custom denormalized posits to the in buffer
np.copyto(in_buffer, t)
print(in_buffer)

# Triger the DMA transfer and wait for result
start_time = time.time()

NN_DMA.sendchannel.transfer(in_buffer)
NN_DMA.recvchannel.transfer(out_buffer)

NN_DMA.sendchannel.wait()
NN_DMA.recvchannel.wait()

stop_time = time.time()
hw_exec_time = stop_time - start_time
throughput = (NB_FRAMES*784)/(1024*1024)/hw_exec_time
fps = NB_FRAMES/hw_exec_time
print('HW time(s): ', hw_exec_time)
print('throughput: ', throughput, "mBps")
print('FPS: ', fps)

with open("values_posit_out.raw", "wb") as f:
    f.write(out_buffer)

# print("out posit values:")
# for count,i in enumerate(out_buffer[-5:]):
#     print(2*count, "0x{:04x}".format((i & 0xFFFF), '04x'))
#     print(2*count + 1,"0x{:04x}".format((i>>16 & 0xFFFF), '04x'))

print("out posit values:")
print("0", "0x{:02x}".format((out_buffer[0]>>0  & 0xFF), '02x'))
print("1", "0x{:02x}".format((out_buffer[0]>>8  & 0xFF), '02x'))
print("2", "0x{:02x}".format((out_buffer[0]>>16 & 0xFF), '02x'))
print("3", "0x{:02x}".format((out_buffer[0]>>24 & 0xFF), '02x'))
print("4", "0x{:02x}".format((out_buffer[1]>>0  & 0xFF), '02x'))
print("5", "0x{:02x}".format((out_buffer[1]>>8  & 0xFF), '02x'))
print("6", "0x{:02x}".format((out_buffer[1]>>16 & 0xFF), '02x'))
print("7", "0x{:02x}".format((out_buffer[1]>>24 & 0xFF), '02x'))
print("8", "0x{:02x}".format((out_buffer[2]>>0  & 0xFF), '02x'))
print("9", "0x{:02x}".format((out_buffer[2]>>8  & 0xFF), '02x'))

# Free the buffers
in_buffer.close()
out_buffer.close()
