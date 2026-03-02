// Pseudo-random number generator for deck shuffling 

module lfsr(input logic clk, input logic rst_n, output logic [31:0] randnum);
    logic linfn;                        // Linear feedback bit (XOR result)
    logic [31:0] randnext;              // Next random number (shifted + feedback)

    assign linfn = randnum[31]^randnum[21]^randnum[1]^randnum[0];
    assign randnext = {randnum[30:0], linfn};

    // On clock, shift and insert feedback bit
    always_ff @( posedge clk ) begin
        if (!rst_n) begin
            // Initialize to non-zero
            randnum <= 32'hfffffff1;
        end
        else begin
            randnum <= randnext;
        end
    end
endmodule: lfsr