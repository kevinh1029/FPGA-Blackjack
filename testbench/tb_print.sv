`timescale 1ps/1ps

module print_tb;

    logic [7:0] VGA_R;
    logic [7:0] VGA_G;
    logic [7:0] VGA_B;

    logic VGA_HS;
    logic VGA_VS;
    logic VGA_CLK;

    logic [7:0] VGA_X;
    logic [6:0] VGA_Y;

    logic [2:0] VGA_COLOUR;
    logic VGA_PLOT;

    logic clk = 0;
    logic rst_n;
    logic writeprint;
    logic initscreen;
    logic [5:0] card_id;
    logic [14:0] orig;
    logic waitrequest;
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

    vga_adapter #(.RESOLUTION("160x120")) vga (
        .resetn(rst_n),
        .clock(clk),

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

    print dut (
        .clk(clk),
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

    always #5 clk = ~clk;

    task init_screen();
        begin
            @(negedge clk);
            writeprint = 1;
            initscreen = 1;
            @(negedge clk);
            writeprint = 0;
            wait(!waitrequest);         // Wait for init to complete
        end
    endtask

    task write_card(input [5:0] test_card, input [14:0] test_orig);
        begin
            card_id = test_card;
            orig = test_orig;
            @(negedge clk);
            writeprint = 1;
            initscreen = 0;
            @(negedge clk);
            writeprint = 0;
            wait(!waitrequest);         // Wait for card render complete
        end
    endtask

    initial begin
        writeprint = 0;
        initscreen = 0;
        $readmemb("../pix_mem/pix.txt", dut.pix.altsyncram_component.m_default.altsyncram_inst.mem_data);
        rst_n = 0;
        #10;
        rst_n = 1;

        //init_screen();
        card_id = 6'b1110_00; //Back of card (rank 14, suit 0)
        orig = 15'b00000010_0000010;
        write_card(card_id, orig);
        card_id = 6'b0001_00; // Ace of Spades (rank 0, suit 0)
        orig = orig + 15'b00010000_0000000; 
        write_card(card_id, orig);
        card_id = 6'b0001_01;
        orig = orig + 15'b00010000_0000000;
        write_card(card_id, orig);
        card_id = 6'b0001_10;
        orig = orig + 15'b00010000_0000000;
        write_card(card_id, orig);
        card_id = 6'b0001_11;
        orig = orig + 15'b00010000_0000000;
        write_card(card_id, orig);

        $stop;
    end

    always @(posedge clk) begin
        if (dut.state == dut.IDLE && writeprint)
            $display("Card written: %b, Origin: %d", card_id, orig);
        if (dut.state == dut.INIT)
            $display("Initializing VGA at X: %d, Y: %d", dut.vga_x, dut.vga_y);
        if (dut.state == dut.CARD)
            $display("Plotting card at X: %d, Y: %d, Colour: %d", dut.vga_x, dut.vga_y, dut.vga_colour);
    end

endmodule: print_tb
