/*
 * tb.sv
 * 
 * Author:    Kais Kudrolli
 * Andrew ID: kkudroll
 *
 * Description for a testbench that drives the inputs of the matrix
 * multiplier system in p5.sv.
 *
 */ 

/*
 * Testbench module that just clears the inputs, resets the system, and
 * drives the clock.
 */
module matrix_tb;
   
    // Inputs and outputs to dut
    bit          clk, sw0, but0;
    bit [4][7:0] hexDisplays;   

    // Instantiate device under test
    matrixmult dut (.*);

    initial begin
        $monitor($stime,, "hex: %h", dut.hex);
        clk = 0;
        but0 = 0;
        sw0 = 0;
     
        but0 <= #5 1;
        forever #5 clk = ~clk;
    end

    initial begin
        #10000 $finish;
    end

endmodule: matrix_tb
