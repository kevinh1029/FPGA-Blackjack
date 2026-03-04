// Card rank macros
`define ACE 4'd1
`define JACK 4'd11
`define QUEEN 4'd12
`define KING 4'd13

// Game message macros
`define BUST 2'd1 // Player bust (dealer wins)
`define WIN 2'd2 // Player wins
`define PUSH 2'd3 // Push (tie)

module gamelogic(input logic clk, input logic rst_n, 

                input logic start, //start new game
                input logic hit, 
                input logic stand, 
                output logic [1:0] msg,

                input logic waitrequest, output logic writeprint, output logic initscreen, 
                output logic [5:0] card_id, output logic [14:0] orig);

    // WAIT  : Idle, waiting for start signal. Transition to SHUFFLE upon start signal asserted and send initscreen command to print module to clear screen.
    // SHUFFLE: Durstenfeld deck shuffle using LFSR random index. Transition to DEAL after shuffling is complete.
    // DEAL  : Deal 4 initial cards (player 2, dealer 2)
    // PLAYER  : Game loop, handle hit/stand, check win/bust
    // DEALER_REVEAL : Reveal dealer's hidden card after player stands or hits 21, then transition to DEALER
    // DEALER  : Dealer's turn - hit until 17 or higher, check win/bust
    // TERM  : Game over, display result
    enum{WAIT, SHUFFLE, DEAL, PLAYER, DEALER_REVEAL, DEALER, TERM} state, statenext;
    
    logic [5:0] deck [0:51]; // Deck of 52 cards, each represented as 6 bits [rank(5:2), suit(1:0)]
    logic [5:0] deckindex, deckindexnext; // Universal index used for shuffling and dealing cards from the deck
    logic [1:0] suit;
    logic [3:0] rank;

    logic [31:0] randnum;
    logic [5:0] randindex;

    logic [4:0] cardscore;
    logic [4:0] pscore, pscorenext;
    logic [4:0] dscore, dscorenext;

    logic [5:0] dcardhidden, dcardhiddennext;

    logic signed [3:0] playeraces, playeracesnext; 
    logic signed [3:0] dealeraces, dealeracesnext;

    logic [1:0] msgnext;

    logic [3:0] carddisplayindex, carddisplayindexnext; // Used to keep track of the horizontal index of the card being displayed

    lfsr random(.clk(clk),
                .rst_n(rst_n),
                .randnum(randnum));

    // debug signals
    logic [7:0] DEBUG_ORIG_X;
    logic [6:0] DEBUG_ORIG_Y;
    assign DEBUG_ORIG_X = orig[14:7];
    assign DEBUG_ORIG_Y = orig[6:0];

    always_comb begin
        writeprint = 1'd0;
        initscreen = 1'd0;
        card_id = 6'd0;
        orig = 15'd0;

        suit = deck[deckindex][1:0]; // Decode
        rank = deck[deckindex][5:2];
        cardscore = (rank == `ACE) ? 5'd11 : ((rank == `JACK || rank == `QUEEN || rank == `KING) ? 5'd10 : {1'd0, rank}); // Start with Ace as 11, will adjust to 1 if player busts with it in hand
        
        randindex = randnum % (deckindex + 1);

        // Previous values
        statenext = state;
        deckindexnext = deckindex;
        pscorenext = pscore;
        dscorenext = dscore;
        dcardhiddennext = dcardhidden;
        playeracesnext = playeraces;
        dealeracesnext = dealeraces;
        msgnext = msg;
        carddisplayindexnext = carddisplayindex;

        unique case (state)
            WAIT: begin
                if (start) begin
                    statenext = SHUFFLE;
                    writeprint = 1'd1;
                    initscreen = 1'd1;
                end
            end
            // Durstenfeld shuffle: for each card from the end to the start of the deck, swap with a random index card from the unshuffled portion then shrink the unshuffled portion by 1
            SHUFFLE: begin
                if (deckindex == 6'd0) begin
                    statenext = DEAL;
                end
                else deckindexnext = deckindex - 6'd1;
            end
            // Deal cards and accumulate initial scores only. Further score updates and win/bust checks will be handled in the PLAYER and DEALER states
            DEAL: begin
                card_id = deck[deckindex];
                if (!waitrequest) begin
                    writeprint = 1'd1;
                    deckindexnext = deckindex + 6'd1;
                end

                case (deckindex)
                    6'd0: begin
                        orig = {8'd2, 7'd2}; // Player first card top-left corner
                        if (!waitrequest) begin // Don't advance anything until waitrequest is deasserted
                            pscorenext = pscore + cardscore;
                            carddisplayindexnext = carddisplayindex + 4'd1;
                            if (rank == `ACE) playeracesnext = playeraces + 4'd1;
                        end
                    end
                    6'd1: begin
                        orig = {8'd2, 7'd23}; // Dealer first card underneath player card
                        if (!waitrequest) begin
                            dscorenext = dscore + cardscore;
                            if (rank == `ACE) dealeracesnext = dealeraces + 4'd1;
                        end
                    end
                    6'd2: begin
                        orig = {8'd13, 7'd2}; // Player second card to the right of first card
                        if (!waitrequest) begin
                            pscorenext = pscore + cardscore;
                            carddisplayindexnext = carddisplayindex + 4'd1;
                            if (rank == `ACE) playeracesnext = playeraces + 4'd1;
                        end
                    end
                    6'd3: begin
                        card_id = 6'd14 << 2; // Back of card for hidden dealer card
                        orig = {8'd13, 7'd23}; // Dealer second card to the right of first card
                        if (!waitrequest) begin
                            dscorenext = dscore + cardscore;
                            dcardhiddennext = deck[deckindex]; // Store the hidden card to reveal later
                            statenext = PLAYER;
                            if (rank == `ACE) dealeracesnext = dealeraces + 4'd1;
                        end
                    end
                    default: begin
                        statenext = TERM; // Should never reach here. Transition to TERM state such that a reset is required.
                    end
                endcase
            end
            // Order of play: Player can stand or hit until they bust or get 21. Once they stand, transition to DEALER state. 
            PLAYER: begin
                if (pscore > 5'd21) begin
                    if (playeraces > 3'd0) begin
                        playeracesnext = playeraces - 3'd1; // Count one ace as 1 instead of 11
                        pscorenext = pscore - 5'd10;
                        if (pscorenext == 5'd21) begin
                            carddisplayindexnext = 4'd1; // Set card display index to 1 for dealer reveal
                            statenext = DEALER_REVEAL; // Reveal dealer card if player hits 21 to prepare for dealer's turn. Transition to TERM state after revealing since the player has a blackjack and wins unless the dealer also has a blackjack
                        end
                    end
                    else begin
                        statenext = TERM;
                        msgnext = `BUST;
                    end
                end
                else if (pscore == 5'd21) begin
                    carddisplayindexnext = 4'd1;
                    statenext = DEALER_REVEAL;
                end
                else if (hit) begin
                    card_id = deck[deckindex];
                    orig = {8'd2 + (8'd11 * carddisplayindexnext), 7'd2}; // New player cards are stacked horizontally directly to the right of the previous cards
                    if (!waitrequest) begin
                        writeprint = 1'd1;
                        deckindexnext = deckindex + 6'd1;
                        pscorenext = pscore + cardscore;
                        if (deck[deckindex][5:2] == `ACE) begin
                            playeracesnext = playeraces + 3'd1;
                        end
                    end
                end
                else if (stand) begin
                    carddisplayindexnext = 4'd1;
                    statenext = DEALER_REVEAL;
                end
            end
            // Simply draw the dealer's hidden card only, then transition to DEALER state to handle the dealer's play logic
            DEALER_REVEAL: begin
                card_id = dcardhidden;
                orig = {8'd13, 7'd23};
                if (!waitrequest) begin
                    writeprint = 1'd1;
                    carddisplayindexnext = 4'd2; 
                    statenext = DEALER;
                end
            end
            // If dealer has less than 17, they must hit until they reach 17 or higher. Then determine win/bust/push and transition to TERM state.
            DEALER: begin
                if (dscore > 5'd21) begin
                    if (dealeraces > 3'd0) begin
                        dealeracesnext = dealeraces - 3'd1; 
                        dscorenext = dscore - 5'd10;
                    end
                    else begin
                        statenext = TERM;
                        msgnext = `WIN; //Player always wins here since player goes first and would have already lost if player had busted
                    end
                end
                else if (dscore == 5'd21) begin
                    statenext = TERM;
                    msgnext = (pscore == 5'd21) ? `PUSH : `BUST; // If dealer has blackjack, player must also have blackjack to tie, otherwise dealer wins
                end
                else if (dscore >= 5'd17) begin
                    statenext = TERM;
                    msgnext = (pscore > dscore) ? `WIN : ((pscore < dscore) ? `BUST : `PUSH);
                end
                else begin
                    card_id = deck[deckindex];
                    orig = {8'd2 + (8'd11 * carddisplayindexnext), 7'd23}; // New dealer cards are stacked horizontally directly to the right of the previous cards

                    if (!waitrequest) begin
                        writeprint = 1'd1;
                        deckindexnext = deckindex + 6'd1;
                        carddisplayindexnext = carddisplayindex + 4'd1;
                        dscorenext = dscore + cardscore;
                        if (deck[deckindex][5:2] == `ACE) begin
                            dealeracesnext = dealeraces + 3'd1;
                        end
                    end
                end
            end
            TERM: begin
            end
        endcase
    end

    // Swap current deckindex card with random index card
    // always_ff @( posedge clk ) begin
    //    if (state == SHUFFLE) begin
            
    //    end 
    // end

    always_ff @( posedge clk ) begin
        if (!rst_n) begin
            state <= WAIT;
            deckindex <= 6'd51;
            for (int i = 0; i < 52; i++) deck[i] <= i+6'd4; //Rank of ACE is 1 (Hence we add 6'd4 = 6'b000100; makes it easier to calculate score), so ACE of suit 0 (Spades), 1 (Hearts), 2 (Clubs), 3 (diamonds), followed by 2-10, JACK, QUEEN, KING of each suit, then finally the sprite for the back of cards with rank 14 used for the hidden dealer card
            pscore <= 5'd0;
            dscore <= 5'd0;
            dcardhidden <= 6'd0;
            playeraces <= 4'd0;
            dealeraces <= 4'd0;
            msg <= 2'd0;
            carddisplayindex <= 4'd0;
        end
        // Swap current deckindex card with random index card
        else if (state == SHUFFLE) begin
            deck[deckindex] <= deck[randindex];
            deck[randindex] <= deck[deckindex];
        end
        else begin
            state <= statenext;
            deckindex <= deckindexnext;
            pscore <= pscorenext;
            dscore <= dscorenext;
            dcardhidden <= dcardhiddennext;
            playeraces <= playeracesnext;
            dealeraces <= dealeracesnext;
            msg <= msgnext;
            carddisplayindex <= carddisplayindexnext;
        end
    end

endmodule: gamelogic