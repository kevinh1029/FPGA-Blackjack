`define BACK 4'd0;
`define ACE 4'd1;
`define TWO 4'd2;
`define THREE 4'd3;
`define FOUR 4'd4;
`define FIVE 4'd5;
`define SIX 4'd6;
`define SEVEN 4'd7;
`define EIGHT 4'd8;
`define NINE 4'd9;
`define TEN 4'd10;
`define JACK 4'd11;
`define QUEEN 4'd12;
`define KING 4'd13;

`define BUST = 2'd1;
`define WIN = 2'd2;
`define TIE = 2'd3;

module gamelogic(input logic clk, input logic rst_n, input logic start, 
                input logic hit, input logic stand, output logic [1:0] msg,
                input logic waitrequest, output logic writeprint, output logic init, 
                output logic [5:0] cardprint, output logic [14:0] orig);

    enum{WAIT, SHUFFLE, DEAL, PLAY, GAME} state, statenext;

    logic [31:0] randnum;
    logic [5:0] deck [0:51];
    logic [5:0] deckcount, deckcountnext;

    logic [5:0] i;
    logic [5:0] randindex;

    logic [4:0] cardscore;
    logic [4:0] pscore, pscorenext;
    logic [4:0] dscore, dscorenext;

    logic [5:0] dcardhidden, dcardhiddennext;

    logic signed [3:0] paces, pacesnext;

    lfsr random(.clk(clk),
                .rst_n(rst_n),
                .randnum(randnum));

    always_comb begin
        msg = 2'd0;
        writeprint = 1'd0;
        init = 1'd0;
        card = 6'd0;
        orig = 15'd0;
        cardscore = (deck[deckcount][5:2] == `ACE) ? 5'd11 : ((deck[deckcount][5:2] == `JACK || deck[deckcount][5:2] == `QUEEN || deck[deckcount][5:2] == `KING) ? 5'd10 : {1'd0, deck[deckcount][5:2]});
        
        statenext = state;
        deckcountnext = deckcount;
        pscorenext = pscore;
        dscorenext = dscore;
        dcardhiddennext = dcardhidden;
        pacesnext = paces;

        randindex = randnum % (deckcount + 1);

        unique case (state)
            WAIT: begin
                if (start) begin
                    statenext = SHUFFLE;
                    writeprint = 1'd1;
                    init = 1'd1;
                end
            end
            SHUFFLE: begin
                if (deckcount == 6'd0) begin
                    statenext = DEAL;
                end
                else deckcountnext = deckcount - 6'd1;
            end
            DEAL: begin
                deckcountnext = deckcount + 6'd1;
                writeprint = 1'd1;

                case (deckcount)
                    6'd0: begin
                        cardprint = deck[deckcount];
                        orig = {8'd2, 7'd2};
                        pscorenext = pscore + cardscore;
                        if (deck[deckcount][5:2] == `ACE) begin
                            pacesnext = paces + 4'd1;
                        end
                    end
                    6'd1: begin
                        cardprint = deck[deckcount];
                        orig = {8'd2, 7'd23};
                        dscorenext = dscore + cardscore;
                    end
                    6'd2: begin
                        cardprint = deck[deckcount];
                        orig = {8'd15, 7'd2};
                        pscorenext = pscore + cardscore;
                        if (deck[deckcount][5:2] == `ACE) begin
                            pacesnext = paces + 4'd1;
                        end
                    end
                    6'd3: begin
                        cardprint = 6'd0;
                        orig = {8'd15, 7'd23};
                        dscorenext = (dscore + cardscore > 5'd21) ? dscore + cardscore - 5'd10 : dscore + cardscore;
                        dcardhiddennext = deck[deckcount];
                        statenext = PLAY;
                    end
                    default: begin
                        statenext = GAME;
                    end
                endcase
            end
            PLAY: begin
                if (pscore > 5'd21) begin
                    if (paces > 3'd0) begin
                        pacesnext = paces - 3'd1;
                        pscorenext = pscore - 5'd10;
                    end
                    else begin
                        statenext = GAME;
                        msg = `BUST;
                    end
                end
                else if (pscore == 5'd21) begin
                    statenext = GAME;
                    msg = `WIN;
                end
                else if (hit) begin
                    writeprint = 1'd1;
                    cardprint = deck[deckcount];
                    deckcountnext = deckcount + 6'd1;
                    orig = {8'd2 + (8'd13 * deckcount>>1), 7'd2};
                    pscorenext = pscore + cardscore;
                    if (deck[deckcount][5:2] == `ACE) begin
                        pacesnext = paces + 3'd1;
                    end
                end
                else if (stand) begin
                    writeprint = 1'd1;
                    cardprint = dcardhidden;
                    orig = {8'd15, 7'd23};
                    statenext = GAME;
                    msg = (pscore > dscore) ? `WIN : ((pscore < dscore) ? `BUST : `TIE);
                end
            end
            GAME: begin
            end
        endcase
    end

    always_ff @( posedge clk ) begin
       if (state == SHUFFLE) begin
            deck[deckcount] <= deck[randindex];
            deck[randindex] <= deck[deckcount];
       end 
    end

    always_ff @( posedge clk ) begin
        if (!rst_n) begin
            state <= WAIT;
            deckcount <= 6'd51;
            for (i = 0; i < 52; i++) deck[i] <= i+6'd4;
            pscore <= 5'd0;
            dscore <= 5'd0;
            dcardhidden <= 6'd0;
            paces <= 4'd0;
        end
        else begin
            state <= statenext;
            deckcount <= deckcountnext;
            pscore <= pscorenext;
            dscore <= dscorenext;
            dcardhidden <= dcardhiddennext;
            paces <= pacesnext;
        end
    end

endmodule: gamelogic