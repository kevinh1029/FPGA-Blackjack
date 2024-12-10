module print(input logic clk, input logic rst_n, input logic write, 
            input logic init, input logic [5:0] card, 
            input logic [7:0] orig_x, input logic [6:0] orig_y,
            output logic waitrequest, output logic [7:0] vga_x, 
            output logic [6:0] vga_y, output logic [2:0] vga_colour, 
            output logic vga_plot);
endmodule: print