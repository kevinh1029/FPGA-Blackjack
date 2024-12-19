module blackjack(input logic CLOCK_50, input logic [3:0] KEY,
                input logic [9:0] SW, output logic [9:0] LEDR,
                output logic [6:0] HEX0, output logic [6:0] HEX1, output logic [6:0] HEX2,
                output logic [6:0] HEX3, output logic [6:0] HEX4, output logic [6:0] HEX5,
                output logic [7:0] VGA_R, output logic [7:0] VGA_G, output logic [7:0] VGA_B,
                output logic VGA_HS, output logic VGA_VS, output logic VGA_CLK,
                output logic [7:0] VGA_X, output logic [6:0] VGA_Y,
                output logic [2:0] VGA_COLOUR, output logic VGA_PLOT);

    logic [3:0] sync_ff1, sync_ff2;
    logic rst_n, start, hit, stand;

    always_ff @(posedge clk) begin
        sync_ff1 <= KEY;
        sync_ff2 <= sync_ff1;
    end

    always_comb begin : blockName
        rst_n = sync_ff2[3];
        start = sync_ff2[2];
        hit = sync_ff2[1];
        stand = sync_ff2[0];
    end
 
 
endmodule: blackjack
