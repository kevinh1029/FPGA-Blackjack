// BLACKJACK TOP LEVEL MODULE

module blackjack(input logic CLOCK_50, 
                input logic [3:0] KEY,
                input logic [9:0] SW, 
                output logic [9:0] LEDR,
                output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,

                // VGA outputs
                output logic [7:0] VGA_R, VGA_G, VGA_B,
                output logic VGA_HS, VGA_VS, VGA_CLK,

                //debug signals
                output logic [7:0] VGA_X, output logic [6:0] VGA_Y,
                output logic [2:0] VGA_COLOUR, output logic VGA_PLOT);

    logic [3:0] sync_ff1, sync_ff2, sync_ff2_prev;     
    logic rst_n, start, hit, stand; 

    // Signals between gamelogic and print module
    logic writeprint, initscreen, waitrequest;
    logic [5:0] card_id;
    logic [14:0] orig;
    
    // Signals from print module to VGA adapter
    logic [7:0] vga_x;
    logic [6:0] vga_y;
    logic [2:0] vga_colour;
    logic vga_plot;

    logic [9:0] VGA_R_10;
    logic [9:0] VGA_G_10;
    logic [9:0] VGA_B_10;  

    //RGB signals are represented with 10 bits inside the adapter but the DE1-SoC DAC has only 8 bits of precision, so take the upper 8 bits for output
    assign VGA_R = VGA_R_10[9:2];
    assign VGA_G = VGA_G_10[9:2];
    assign VGA_B = VGA_B_10[9:2];

    assign VGA_X = vga_x;
    assign VGA_Y = vga_y;
    assign VGA_PLOT = vga_plot;
    assign VGA_COLOUR = vga_colour;

    gamelogic gl(
        .clk(CLOCK_50),
        .rst_n(rst_n),
        .start(start),
        .hit(hit),
        .stand(stand),
        
        .msg(LEDR[1:0]), // Game message (BUST, WIN, PUSH) -> LED output

        .waitrequest(waitrequest),
        .writeprint(writeprint),
        .initscreen(initscreen),
        .card_id(card_id),
        .orig(orig)
    );

    print pr(
        .clk(CLOCK_50),
        .rst_n(rst_n),

        .writeprint(writeprint),
        .initscreen(initscreen),
        .card_id(card_id),
        .orig(orig),
        .waitrequest(waitrequest),
        
        .vga_x(vga_x),
        .vga_y(vga_y),
        .vga_colour(vga_colour),
        .vga_plot(vga_plot)
    );

    vga_adapter #(.RESOLUTION("160x120")) vga (
        .resetn(rst_n),
        .clock(CLOCK_50),

        .colour(vga_colour),
        .x(vga_x),
        .y(vga_y),
        .plot(vga_plot),

        .VGA_R(VGA_R_10),
        .VGA_G(VGA_G_10),
        .VGA_B(VGA_B_10),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_CLK(VGA_CLK)
    );

    // 2-FF to prevent metastability from button inputs
    always_ff @(posedge CLOCK_50) begin
        sync_ff1 <= KEY;
        sync_ff2 <= sync_ff1;
        sync_ff2_prev <= sync_ff2;
    end

    // Buttons active low - detect falling edge (1->0) for one-cycle pulse
    // Rising edge of internal signal: (sync_ff2[i] == 0) && (sync_ff2_prev[i] == 1)
    always_comb begin
        rst_n = (sync_ff2[3] == 1'b0) && (sync_ff2_prev[3] == 1'b1);
        start = (sync_ff2[2] == 1'b0) && (sync_ff2_prev[2] == 1'b1);
        hit = (sync_ff2[1] == 1'b0) && (sync_ff2_prev[1] == 1'b1);
        stand = (sync_ff2[0] == 1'b0) && (sync_ff2_prev[0] == 1'b1);
    end
 
endmodule: blackjack

