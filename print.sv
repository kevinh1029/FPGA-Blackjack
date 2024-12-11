module print(input logic clk, input logic rst_n, input logic write, 
            input logic init, input logic [5:0] card, 
            input logic [14:0] orig, output logic waitrequest, 
            output logic [7:0] vga_x, output logic [6:0] vga_y, 
            output logic [2:0] vga_colour, output logic vga_plot);

    enum {IDLE, INIT, CARD} state, statenext;

    logic [13:0] pix_addr;
    logic [2:0] pix_q, pix_data;
    logic pix_wren;

    logic [7:0] vga_xnext;
    logic [6:0] vga_ynext;
    logic [2:0] vga_colournext;
    logic vga_plotnext;

    logic [5:0] cardbuf, cardbufnext;
    logic [1:0] suit;
    logic [3:0] rank;
    logic [7:0] cardscan, cardscannext;
    logic [14:0] origbuf, origbufnext;
    logic [7:0] orig_x;
    logic [6:0] orig_y;

    pix_mem pix(.address(pix_addr),
                .clock(clk),
                .data(pix_data),
                .wren(pix_wren),
                .q(pix_q));

    always_comb begin
        //Default values
        pix_addr = 13'd0;
        pix_data = 3'd0;
        pix_wren = 1'd0;
        waitrequest = 1'd0;

        //Previous values
        statenext = state;
        vga_xnext = vga_x;
        vga_ynext = vga_y;
        vga_colournext = vga_colour;
        vga_plotnext = vga_plot;
        origbufnext = origbuf;
        cardbufnext = cardbuf;
        cardscannext = cardscan;

        //Decode
        suit = cardbuf[1:0];
        rank = cardbuf[5:2];
        orig_x = origbuf[14:7];
        orig_y = origbuf[6:0];

        unique case (state)
            IDLE: begin
                if (write) begin
                    if (init) begin
                        statenext = INIT;
                        vga_colournext = 3'd2;
                        vga_plotnext = 1'd1;
                    end
                    else begin
                        statenext = CARD;
                        cardbufnext = card;
                        origbufnext = orig;
                        cardscannext = cardscan + 8'd1;
                        pix_addr = ({12'd0, card[1:0]} * 14'd13 + {10'd0, card[5:2]}) * 14'd176 + {6'd0, cardscan};
                        vga_xnext = orig_x;
                        vga_ynext = orig_y;
                    end
                end
            end

            INIT: begin
                waitrequest = 1'd1;
                
                vga_colournext = 3'd2;
                vga_plotnext = 1'd1;
                vga_xnext = vga_x + 8'd1;
                if (vga_x == 8'd159 && vga_y == 7'd119) begin
                    vga_plotnext = 1'd0;
                    vga_xnext = 8'd0;
                    vga_ynext = 7'd0;
                    vga_colournext = 3'd0;
                    statenext = IDLE;
                end
                else if (vga_x == 8'd159) begin
                    vga_ynext = vga_y + 7'd1;
                    vga_xnext = 8'd0;
                end
            end

            CARD: begin
                waitrequest = 1'd1;

                cardscannext = cardscan + 8'd1;
                pix_addr = ({12'd0, cardbuf[1:0]} * 14'd13 + {10'd0, cardbuf[5:2]}) * 14'd176 + {6'd0, cardscan};
                vga_plotnext = 1'd1;
                vga_colournext = pix_q;

                vga_xnext = vga_x + 8'd1;
                if (vga_x == orig_x + 8'd10 && vga_y == orig_y + 7'd15) begin
                    vga_plotnext = 1'd0;
                    vga_xnext = 8'd0;
                    vga_ynext = 7'd0;
                    vga_colournext = 3'd0;
                    origbufnext = 15'd0;
                    cardbufnext = 6'd0;
                    cardscannext = 8'd0;
                    statenext = IDLE;
                end
                else if (vga_x == orig_x + 8'd10) begin
                    vga_ynext = vga_y + 7'd1;
                    vga_xnext = orig_x;
                end
            end
        endcase
    end

    always_ff @( posedge clk ) begin
        if (!rst_n) begin
            state <= IDLE;
            vga_x <= 8'd0;
            vga_y <= 7'd0;
            vga_colour <= 3'd0;
            vga_plot <= 1'd0;
            origbuf <= 15'd0;
            cardbuf <= 6'd0;
            cardscan <= 8'd0;
        end
        else begin
            state <= statenext;
            vga_x <= vga_xnext;
            vga_y <= vga_ynext;
            vga_colour <= vga_colournext;
            vga_plot <= vga_plotnext;
            origbuf <= origbufnext;
            cardbuf <= cardbufnext;
            cardscan <= cardscannext;
        end
    end
endmodule: print