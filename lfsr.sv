module lfsr(input logic clk, input logic rst_n, output logic randnum);
    logic linfn;
    logic [31:0] randnext;

    assign randnext = randnum[31]^randnum[21]^randnum[1]^randnum[0];
    assign randnext = {randnum[30:0], linfn};
    
    always_ff @( posedge clk ) begin
        if (!rst_n) begin
            randnum <= 32'hf;
        end
        else begin
            randnum <= randnext;
        end
    end
endmodule: lfsr