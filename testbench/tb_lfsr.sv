`timescale 1ps / 1ps

module lfsr_tb;
    logic clk = 0;
    logic rst_n;
    logic [31:0] randnum;

    lfsr dut (
        .clk(clk),
        .rst_n(rst_n),
        .randnum(randnum)
    );

    always #5 clk = ~clk; 

    initial begin
        rst_n = 0;
        #10;
        rst_n = 1;

        repeat (1000) @(posedge clk);
        $stop;
    end

    always @(posedge clk) begin
        $display($time, " clk=%b, rst_n=%b, randnum=%h", clk, rst_n, randnum);
    end

endmodule: lfsr_tb
