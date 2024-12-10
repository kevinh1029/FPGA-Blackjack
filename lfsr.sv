module lfsr(input logic clk, input logic rst_n, output logic [31:0] randnum);
    logic linfn;
    logic [31:0] randnext;

    assign linfn = randnum[31]^randnum[21]^randnum[1]^randnum[0];
    assign randnext = {randnum[30:0], linfn};

    always_ff @( posedge clk ) begin
        if (!rst_n) begin
            randnum <= 32'hfffffff1;
        end
        else begin
            randnum <= randnext;
        end
    end
endmodule: lfsr