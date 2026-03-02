`timescale 1ps/1ps

module blackjack_tb;

    logic CLOCK_50;
    logic [3:0] KEY;
    logic [9:0] SW;
    logic [9:0] LEDR;
    logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
    logic [7:0] VGA_R, VGA_G, VGA_B;
    logic VGA_HS, VGA_VS, VGA_CLK;
    logic [7:0] VGA_X;
    logic [6:0] VGA_Y;
    logic [2:0] VGA_COLOUR;
    logic VGA_PLOT;

    blackjack dut (
        .CLOCK_50(CLOCK_50),
        .KEY(KEY),
        .SW(SW),
        .LEDR(LEDR),
        .HEX0(HEX0),
        .HEX1(HEX1),
        .HEX2(HEX2),
        .HEX3(HEX3),
        .HEX4(HEX4),
        .HEX5(HEX5),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_CLK(VGA_CLK),
        .VGA_X(VGA_X),
        .VGA_Y(VGA_Y),
        .VGA_COLOUR(VGA_COLOUR),
        .VGA_PLOT(VGA_PLOT)
    );

    always #5 CLOCK_50 = ~CLOCK_50;
    initial begin
        CLOCK_50 = 0;
        KEY = 4'b1111;
        SW = 10'b0;
        $readmemb("../pix_mem/pix.txt", dut.pr.pix.altsyncram_component.m_default.altsyncram_inst.mem_data);
        #10 KEY[3] = 0; // Reset the game by pressing KEY3
        #10 KEY[3] = 1; // Release KEY3
        #10 KEY[2] = 0; // Start the game by pressing KEY0
        #10 KEY[2] = 1; // Release KEY0
        wait(dut.gl.state == dut.gl.PLAYER); // Wait until the first hand is dealt
        #10 KEY[1] = 0; // Simulate a "HIT" by pressing KEY1
        #10 KEY[1] = 1; // Release KEY1
        #500
        #10 KEY[0] = 0; // Simulate a "STAND" by pressing KEY2
        #10 KEY[0] = 1; // Release KEY2
        wait(dut.gl.state == dut.gl.TERM); // Wait until the game is over
        wait(dut.waitrequest == 0); // Wait until the final print is done
        assert (dut.gl.msg == 2'd2) else $error("Test failed: Expected WIN, got %b", dut.gl.msg);
        
        $stop;
    end

    

endmodule
