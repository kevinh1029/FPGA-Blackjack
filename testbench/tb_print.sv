`timescale 1ps/1ps

module print_tb;
    logic clk = 0;
    logic rst_n;
    logic write;
    logic init;
    logic [5:0] card;
    logic [14:0] orig;
    logic waitrequest;
    logic [7:0] vga_x;
    logic [6:0] vga_y;
    logic [2:0] vga_colour;
    logic vga_plot;

    print dut (
        .clk(clk),
        .rst_n(rst_n),
        .write(write),
        .init(init),
        .card(card),
        .orig(orig),
        .waitrequest(waitrequest),
        .vga_x(vga_x),
        .vga_y(vga_y),
        .vga_colour(vga_colour),
        .vga_plot(vga_plot)
    );

    always #5 clk = ~clk;

    task reset_dut();
        begin
            rst_n = 0;
            #20;
            rst_n = 1;
        end
    endtask

    task write_card(input [5:0] test_card, input [14:0] test_orig);
        begin
            @(negedge clk);
            write = 1;
            card = test_card;
            orig = test_orig;
            init = 0;
            @(negedge clk);
            write = 0;
            wait(!waitrequest);
        end
    endtask

    task init_screen();
        begin
            @(negedge clk);
            write = 1;
            init = 1;
            @(negedge clk);
            write = 0;
            wait(!waitrequest);
        end
    endtask

    initial begin
        write = 0;
        init = 0;
        card = 6'd0;
        orig = 15'd0;

        rst_n = 0;
        #10;
        rst_n = 1;

        init_screen();

        $stop;
    end

    always @(posedge clk) begin
        if (dut.state == dut.IDLE && write)
            $display("Card written: %b, Origin: %d", card, orig);
        if (dut.state == dut.INIT)
            $display("Initializing VGA at X: %d, Y: %d", dut.vga_x, dut.vga_y);
        if (dut.state == dut.CARD)
            $display("Plotting card at X: %d, Y: %d, Colour: %d", dut.vga_x, dut.vga_y, dut.vga_colour);
    end

endmodule: print_tb
