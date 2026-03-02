// Does either:
//   1. Initialize VGA screen (fill with green)
//   2. Draw individual card sprites (11×16 pixels each)
// Handshakes with gamelogic via writeprint and waitrequest signals. Stalls gamelogic with waitrequest while processing commands.

module print(input logic clk, input logic rst_n, 

            input logic writeprint, 
            input logic initscreen, 
            input logic [5:0] card_id, 
            input logic [14:0] orig, 
            output logic waitrequest, 

            output logic [7:0] vga_x, output logic [6:0] vga_y, 
            output logic [2:0] vga_colour, output logic vga_plot);

    // IDLE : Waiting for writeprint command and checking for the initscreen signal, otherwise it's a card draw sequence
    // INIT : Initializing screen (filling with green)
    // CARD : Drawing a card sprite given the card ID and origin position (top-left corner)
    enum {IDLE, INIT, CARD} state, statenext;

    
    logic [13:0] pix_addr;              // Address into sprite memory
    logic [2:0] pix_q, pix_data;        // Read data, write data (3-bit color)
    logic pix_wren;                     // Write enable for sprite memory (Write signals unused)

    logic [7:0] vga_xnext;              // Next X coordinate (0-159)
    logic [6:0] vga_ynext;              // Next Y coordinate (0-119)

    // Buffers to hold current card ID and origin during drawing process
    logic [5:0] cardbuf, cardbufnext;   
    logic [14:0] origbuf, origbufnext;  

    logic [1:0] suit;                   // Card suit (bits 1:0 of card)
    logic [3:0] rank;                   // Card rank (bits 5:2 of card)
    logic [7:0] orig_x;                 // Origin X extracted from origbuf
    logic [6:0] orig_y;                 // Origin Y extracted from origbuf

    logic [7:0] pixcount, pixcountnext; // Pixel counter (0-175 for 11×16 card)


    // Altera synchronous RAM block containing 53 card sprites (52 cards + 1 back)
    // Indexed by suit (bits 1:0) * 13 + rank (bits 5:2)
    // Each sprite is 11×16 pixels = 176 pixels total, 3 bits per pixel
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
        waitrequest = 1'd0; // Only enabled in INIT and CARD states to stall gamelogic

        vga_plot = 1'd0; // Only enabled when actually plotting pixels
        vga_colour = 3'd0; // Default color (black) when not

        //Decode
        suit = cardbuf[1:0];
        rank = cardbuf[5:2] - 4'd1; // Card ranks are 1-13 but stored as 0-12 for easier indexing in memory
        orig_x = origbuf[14:7];
        orig_y = origbuf[6:0];

        //Previous values
        statenext = state;
        vga_xnext = vga_x;
        vga_ynext = vga_y;
        origbufnext = origbuf;
        cardbufnext = cardbuf;
        pixcountnext = pixcount;

        unique case (state)
            IDLE: begin
                if (writeprint) begin
                    if (initscreen) begin
                        statenext = INIT;
                    end
                    else begin // Set the address for the first pixel here so the color is ready in the CARD state
                        statenext = CARD;
                        cardbufnext = card_id;
                        origbufnext = orig;
                        pixcountnext = pixcount + 8'd1; //Increment pixcountnext now since pix_addr calculated combinationally from pixcount, so pix_q is 2 cycles behind pixcountnext.
                        pix_addr = ({10'd0, card_id[5:2]-4'd1} * 14'd4 + {12'd0, card_id[1:0]}) * 14'd176 + {6'd0, pixcount}; 
                        vga_xnext = orig[14:7]; // Set initial VGA position to one left of origin since it will be incremented at the start of CARD state
                        vga_ynext = orig[6:0];
                    end
                end
            end

            INIT: begin
                waitrequest = 1'd1; // Stall gamelogic until initialization is complete
                vga_colour = 3'd2;
                vga_plot = 1'd1;
                vga_xnext = vga_x + 8'd1;
                // After plotting last pixel (159,119), move to next state, disable plot and reset counters
                if (vga_x == 8'd159 && vga_y == 7'd119) begin
                    vga_xnext = 8'd0;
                    vga_ynext = 7'd0;
                    statenext = IDLE;
                end
                // Move to next pixel: increment X, and if at end of row, move down and reset X
                else if (vga_x == 8'd159) begin
                    vga_ynext = vga_y + 7'd1;
                    vga_xnext = 8'd0;
                end
            end

            CARD: begin //Entering this state, the colour is ready, but the vga outputs (vga_x, vga_y, vga_plot, vga_colour) will be delayed by one cycle
                waitrequest = 1'd1;
                pixcountnext = pixcount + 8'd1;
                pix_addr = ({10'd0, rank} * 14'd4 + {12'd0, suit}) * 14'd176 + {6'd0, pixcount}; 
                vga_colour = pix_q;
                vga_plot = 1'd1;
                vga_xnext = vga_x + 8'd1;
                if (vga_x == orig_x + 8'd10 && vga_y == orig_y + 7'd15) begin
                    vga_xnext = 8'd0;
                    vga_ynext = 7'd0;
                    origbufnext = 15'd0;
                    cardbufnext = 6'd0;
                    pixcountnext = 8'd0;
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
            origbuf <= 15'd0;
            cardbuf <= 6'd0;
            pixcount <= 8'd0;
        end
        else begin
            state <= statenext;
            vga_x <= vga_xnext;
            vga_y <= vga_ynext;
            origbuf <= origbufnext;
            cardbuf <= cardbufnext;
            pixcount <= pixcountnext;
        end
    end
endmodule: print