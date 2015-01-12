# Matrix-Multiplier
A matrix multiplier system that multiplies a 64 byte x 64 byte matrix by a 64 byte by 1 byte vector in hardware. This was placed and routed onto an Altera FPGA.

matA.mif - Matrix A memory initialization file
matB.mif - Matrix B memory initialization file
matA_1.mif - Matrix A memory initialization file (option 1)
matA_2.mif - Matrix A memory initialization file (option 2)
matB_1.mif - Matrix B memory initialization file (option 1)
matB_2.mif - Matrix B memory initialization file (option 2)
matrixmult.qsf - Quartus II project file
multiplier.v - Verilog multiplier library component
romA.v - Verilog 64 x 64 byte ROM library component
romB.v - Verilog 64 x 1 byte ROM library component
tb.sv - System Verilog testbench for the system
p5.sv - System Verilog description of the matrix multiplier system
