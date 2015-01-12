/*
 * p5.sv 
 *
 * Author:    Kais Kudrolli
 * Andrew ID: kkudroll
 *
 * This file contains the description for a matrix multiplier that takes
 * a 64 byte x 64 byte matrix M and multiplies it by a 64 byte x 1 byte 
 * matrix X to receive the result Y = M * X, where Y is 64 bytes x 1 byte.
 * The sum of the bytes in Y is the result. The system also reports how many
 * clock cycles this operation took. M and X are stored in ROMs, which are 
 * initialized separately by matA.mif and matB.mif, respectively. 
 *
 */


/*
 * Top module for the matrix multiplier system. It will perform the calculation
 * at reset and hold the value of the result and clock ticks until it is
 * reset again. The system employs parallelism in order to reduce the number
 * of clock cycles required to complete the calculation. This is done by 
 * instantiating 8 images of ROM A and 8 images of ROM B. Since each ROM can
 * take in two addresses, 16 operations are carried out in parallel per clock
 * cycle. The resulting 16 multiplications are summed and added to a registered
 * total sum until all the multiplications are finished. To perform the full 
 * sum calculation, the system relies on the fact that the sum will be equal to the
 * sum of all the separate multiplications. So, it does not ever actually store the
 * result Y.
 * 
 * Inputs: 
 *  - clk: the system clock (50 MHz)
 *  - sw0: controls what value is displayed on the hex displays, when it is 1
 *         the clock ticks are displayed, when it is 0 the sum is displayed
 *  - but0: the reset button of the system
 * Outputs:
 *  - hexDisplays: the displays that show the result or clock ticks in hex
 *
 */
module matrixmult
    (input  bit          clk, sw0, but0,
     output bit [4][7:0] hexDisplays);

    // Internal signals and registers
    bit [7:0]     stop;
    bit [15:0]    hex, clockTicks, sum, interSum;
    bit [8][15:0] result;
    bit [8][11:0] startValsA;
    bit [8][5:0]  startValsB;

    // Set initial starting address of computation of each multiplying module
    always_comb begin
        startValsA = {12'd0, 12'd2, 12'd4, 12'd6, 12'd8, 12'd10, 12'd12, 12'd14};
        startValsB = {6'd0, 6'd2, 6'd4, 6'd6, 6'd8, 6'd10, 6'd12, 6'd14};
    end

    // Drive the hex displays
    hexToSevenSegment hex0 (.hex(hex[3:0]),   .segment(hexDisplays[0])),
                      hex1 (.hex(hex[7:4]),   .segment(hexDisplays[1])),
                      hex2 (.hex(hex[11:8]),  .segment(hexDisplays[2])),
                      hex3 (.hex(hex[15:12]), .segment(hexDisplays[3]));

    // Generate 8 instances of the multiplying module
    generate 
        genvar i;
        for (i = 0; i < 8; i++) begin: L1
            multiplyTwo mult (.clk(clk), .but0(but0), .startA(startValsA[i]), 
                              .startB(startValsB[i]), .stop(stop[i]), 
                              .result(result[i]));
        end
    endgenerate
    
    // Update running total based on results of last clock cycle's calcualtions
    always_ff @(posedge clk, negedge but0) begin
        if (~but0) begin
            interSum <= 16'd0;
        end
        else begin
            interSum <= (~stop) ?
                        interSum +
                        result[0] + result[1] + result[2] + result[3] +
                        result[4] + result[5] + result[6] + result[7] :
                        interSum;
        end
    end

    // Choose what to display
    assign hex = (sw0) ? clockTicks : interSum;

    // FSM to control clock tick counter and sum
    always_ff @(posedge clk, negedge but0) begin
        if (~but0) begin
            clockTicks <= 16'd0;
        end
        else begin
            clockTicks <= (stop == 8'hff) ? clockTicks : clockTicks + 16'd1;
        end
    end

endmodule: matrixmult

/*
 * Module that performs two multiplications and the sum of the two resultant
 * products in one clock cycle. There are 8 of these modules used in order to
 * perform 16 multiplications in one clock cycle. 
 * 
 * Inputs:
 *  - clk: system clock
 *  - but0: system reset
 *  - startA: the address at which the module should start reading ROM A
 *  - startB: the address at which the module should start reading ROM B
 * Outputs:
 *  - stop: indicates the module is down performing all of its calculations
 *  - result: the 16-bit result of two products summed together 
 *
 */
module multiplyTwo
    (input  bit        clk, but0, 
     input  bit [11:0] startA,
     input  bit [5:0]  startB,
     output bit        stop,
     output bit [15:0] result);

    // Internal connections
    bit [11:0] mRomAddrA, mRomAddrB;
    bit [5:0]  xRomAddrA, xRomAddrB;
    bit [7:0]  q_a1, q_a2, q_b1, q_b2;
    bit [15:0] resultA, resultB;

    // Instantiate an FSM, 2 ROMs, 2 multipliers, and an adder
    addrFsm fsm (.clk(clk), .but0(but0), .startA(startA), .startB(startB),
                 .stop(stop), .mRomAddrA(mRomAddrA), .mRomAddrB(mRomAddrB),
                 .xRomAddrA(xRomAddrA), .xRomAddrB(xRomAddrB));

    romA ra (.address_a(mRomAddrA), .address_b(mRomAddrB), .clock(clk), 
             .q_a(q_a1), .q_b(q_b1));
    
    romB rb (.address_a(xRomAddrA), .address_b(xRomAddrB), .clock(clk), 
             .q_a(q_a2), .q_b(q_b2));

    multiplier ma (.dataa(q_a1), .datab(q_a2), .result(resultA)),
               mb (.dataa(q_b1), .datab(q_b2), .result(resultB));

    adder sum (.A(resultA), .B(resultB), .result(result));

endmodule: multiplyTwo

/*
 * A simple 16-bit adder that does not worry about overflow or carry
 * out bits.
 *
 * Inputs:
 *  - A: first 16-bit addend
 *  - B: second 16-bit addend
 * Outputs: 
 *  - result: the 16-bit sum of A and B 
 *
 */
module adder
    (input  bit [15:0] A, B,
     output bit [15:0] result);

    assign result = A + B;

endmodule: adder

/*
 * The FSM that feeds the appropriate addresses to the ROMs A and B. Since
 * there are 8 ROMs, the address is incremented by 16 each cycle. So, all the
 * 8 separate modules perform two calculations of the 16 in parallel.
 *
 * Inputs:
 *  - clk: system clock
 *  - but0: system reset
 *  - startA: where to start reading ROM A
 *  - startB: where to start reading ROM B
 * Outputs:
 *  - stop: indicates the calculations are done
 *  - mRomAddrA: the first address of ROM A to read in a given cycle
 *  - mRomAddrB: the second address of ROM B to read in a given cycle
 *  - xRomAddrA: the first address of ROM B to read in a cycle
 *  - xRomAddrB: the second address of ROM B to read in a cycle
 *
 */
module addrFsm 
    (input  bit        clk, but0, 
     input  bit [11:0] startA,
     input  bit [5:0]  startB,
     output bit        stop,
     output bit [11:0] mRomAddrA, mRomAddrB,
     output bit [5:0]  xRomAddrA, xRomAddrB);

    bit [11:0] aCount, a1, a2; 
    bit [5:0]  b1, b2;
    bit        inc;

    enum bit [1:0] {init, go, done} cs, ns;

    // Adds 16 to the addresses each cycle so that there is no double
    // calculations between the 8 instances of multiplyTwo
    always_ff @(posedge clk, negedge but0) begin
        if (~but0) begin
            aCount <= 12'd0;
            mRomAddrA <= startA;
            mRomAddrB <= startA + 12'd1;
            xRomAddrA <= startB;
            xRomAddrB <= startB + 6'd1;
            cs <= init;
        end
        else begin
            aCount <= (inc) ? aCount + 12'd1 : aCount;
            mRomAddrA <= (inc) ? mRomAddrA + 12'd16 : mRomAddrA;
            mRomAddrB <= (inc) ? mRomAddrB + 12'd16 : mRomAddrB;
            xRomAddrA <= (inc) ? xRomAddrA + 6'd16 : xRomAddrA;
            xRomAddrB <= (inc) ? xRomAddrB + 6'd16 : xRomAddrB;
            cs <= ns;
        end
    end

    // Combined next state and output logic
    always_comb begin
        inc = 0;
        stop = 0;
        case (cs) 
            init: begin
                ns = go;
                inc = 1;
                stop = 1;
            end
            go: begin
                ns = (aCount != 12'd256) ? go : done;
                inc = (aCount != 12'd256) ? 1 : 0;
            end
            done: begin
                ns = done;
                stop = 1;
            end
        endcase
    end
 
endmodule: addrFsm

/*
 * This module takes an 4-bit value and converts it to the appropriate
 * 8-bit value needed to display it on the board's HEX displays, taking
 * into account that the segments of the display are asserted low.
 *
 * Inputs:
 *  - hex: the 4-bit hex number that is to be encoded
 * Outputs:
 *  - segment: the 8-bit encoding for the given hex to light the correct
 *             panels of the 7-segment display
 *
 */
module hexToSevenSegment
    (input  bit [3:0] hex,
	 output bit [7:0] segment);
	  
	 always_comb begin
	     case (hex) 
             4'h0: segment = 8'b1100_0000;
             4'h1: segment = 8'b1111_1001;
             4'h2: segment = 8'b1010_0100;
             4'h3: segment = 8'b1011_0000;
             4'h4: segment = 8'b1001_1001;
             4'h5: segment = 8'b1001_0010;
             4'h6: segment = 8'b1000_0010;
             4'h7: segment = 8'b1111_1000;
             4'h8: segment = 8'b1000_0000;
             4'h9: segment = 8'b1001_0000;
             4'ha: segment = 8'b1000_1000;
             4'hb: segment = 8'b1000_0011;
             4'hc: segment = 8'b1100_0110;
             4'hd: segment = 8'b1010_0001;
             4'he: segment = 8'b1000_0110;
             4'hf: segment = 8'b1000_1110;
         endcase
	 end

endmodule: hexToSevenSegment
