module day1p2(
    input clk,
    input rst_n,
    input [7:0] din,
    input din_rdy,
    output logic [31:0] dout,
    output logic dout_valid,
    output logic din_re,
    output logic done
);
/*
Interface assumptions:
When din_rdy is "ready", din is also valid without needing to pulse din_re.
Every clock cycle that we have din_re high, when there is data, it will read.
When din_re is high and din_rdy is not ready, it is "fine". The din will just not be valid until din_rdy is high.
*/

typedef enum logic[2:0] { 
    UNDEF='x,
    RESET=0,
    WAIT_ONES, //001
    ADD_ONES,  //010
    WAIT_TENS, //011
    ADD_TENS,  //100
    DISP,      //101
    HALT       //110
} state_t;

state_t state, nxt_state;

logic [7:0] shift_reg [0:4];
logic [7:0] nxt_shift_reg [0:4];

//saves shift_reg_value when shift_reg_valid is high
logic [3:0] sav_reg;
logic [3:0] nxt_sav_reg;

//decoded value of the shift reg for identifying valid tokens in the stream
logic [3:0] shift_reg_value;
logic shift_reg_valid;
assign shift_reg_valid = shift_reg_value != 15;

//can't compare bytesliced shiftreg to string, so make slices of common lengths here

always_comb begin
    /*
    check the shift_reg shift register for valid values.
    Use opposite order indicies for string comparison so
    I don't have to spell numbers backwards.
    */
/*    if (shift_reg[0] == "0" || (
                                        shift_reg[3] == "z" &&
                                        shift_reg[2] == "e" &&
                                        shift_reg[1] == "r" &&
                                        shift_reg[0] == "o"))
        shift_reg_value = 0;
    else*/ if (shift_reg[0] == "1" || (
                                        shift_reg[2] == "o" &&
                                        shift_reg[1] == "n" &&
                                        shift_reg[0] == "e"))
        shift_reg_value = 1;
    else if (shift_reg[0] == "2" || (
                                        shift_reg[2] == "t" &&
                                        shift_reg[1] == "w" &&
                                        shift_reg[0] == "o"))
        shift_reg_value = 2;
    else if (shift_reg[0] == "3" || (
                                        shift_reg[4] == "t" &&
                                        shift_reg[3] == "h" &&
                                        shift_reg[2] == "r" &&
                                        shift_reg[1] == "e" &&
                                        shift_reg[0] == "e"))
        shift_reg_value = 3;
    else if (shift_reg[0] == "4" || (
                                        shift_reg[3] == "f" &&
                                        shift_reg[2] == "o" &&
                                        shift_reg[1] == "u" &&
                                        shift_reg[0] == "r"))
        shift_reg_value = 4;
    else if (shift_reg[0] == "5" || (
                                        shift_reg[3] == "f" &&
                                        shift_reg[2] == "i" &&
                                        shift_reg[1] == "v" &&
                                        shift_reg[0] == "e"))
        shift_reg_value = 5;
    else if (shift_reg[0] == "6" || (
                                        shift_reg[2] == "s" &&
                                        shift_reg[1] == "i" &&
                                        shift_reg[0] == "x"))
        shift_reg_value = 6;
    else if (shift_reg[0] == "7" || (
                                        shift_reg[4] == "s" &&
                                        shift_reg[3] == "e" &&
                                        shift_reg[2] == "v" &&
                                        shift_reg[1] == "e" &&
                                        shift_reg[0] == "n"))
        shift_reg_value = 7;
    else if (shift_reg[0] == "8" || (
                                        shift_reg[4] == "e" &&
                                        shift_reg[3] == "i" &&
                                        shift_reg[2] == "g" &&
                                        shift_reg[1] == "h" &&
                                        shift_reg[0] == "t"))
        shift_reg_value = 8;
    else if (shift_reg[0] == "9" || (
                                        shift_reg[3] == "n" &&
                                        shift_reg[2] == "i" &&
                                        shift_reg[1] == "n" &&
                                        shift_reg[0] == "e"))
        shift_reg_value = 9;
    else
        shift_reg_value = 15;
end


wire din_was_nl;
wire din_was_null;

logic onesplace;
logic tensplace;

logic rst_sum;

assign din_was_nl = din_rdy && shift_reg[0] == "\n";
assign din_was_null = din_rdy && shift_reg[0] == 8'hFF;

/*
Advance the state to the next state
*/
always_ff @(posedge clk, negedge rst_n) begin : advance_state
    if (!rst_n) begin 
        state <= RESET;
        for (integer i=0; i<5; i++)
            shift_reg[i] = 0;
        sav_reg <= 0;
        dout <= 0;
    end
    else begin 
        state <= nxt_state;
        sav_reg <= nxt_sav_reg;
        for (integer i=0; i<5; i++)
            shift_reg[i] <= nxt_shift_reg[i];
            //{shift_reg[0], shift_reg[1], shift_reg[2], shift_reg[3], shift_reg[4]} <= {nxt_shift_reg[0], nxt_shift_reg[1], nxt_shift_reg[2], nxt_shift_reg[3], nxt_shift_reg[4]};
        if (onesplace) dout <= dout + sav_reg;
        else if (tensplace) dout <= dout + (sav_reg*10);
        else if (rst_sum) dout <= 0;
        else dout <= dout;
    end
end

always_comb begin : state_logic
    nxt_state = UNDEF;
    nxt_sav_reg = sav_reg;
    for (integer i=0; i<5; i++)
        nxt_shift_reg[i] = shift_reg[i];
    onesplace = 0;
    tensplace = 0;
    dout_valid = 0;
    din_re = 0;
    done = 0;
    rst_sum = 0;

    case (state)
        RESET: begin
            nxt_state = WAIT_TENS;
        end
        WAIT_TENS: begin
            if (shift_reg_valid)         nxt_state=ADD_TENS;
            else if(din_was_null)    nxt_state=HALT;
            else                    nxt_state=WAIT_TENS;
            /*  signal that we'll consume it if valid
                we only advance to next state if it was a num,
                so no check needed here*/
            nxt_sav_reg = shift_reg_value;
            for (integer i=0; i<4; i++)
                nxt_shift_reg[i+1] = shift_reg[i];
            nxt_shift_reg[0] = din;
            
            //signal that we'll consume that if it was valid
            din_re = 1;
            //debug so we output only current line, not sum...
            //rst_sum=1;
        end

        ADD_TENS: begin
            if (din_was_nl)          nxt_state=ADD_ONES;
            if (din_was_null)        nxt_state=HALT;
            else                    nxt_state=WAIT_ONES;
            tensplace=1'b1;
        end

        WAIT_ONES: begin
            //next state
            if (din_was_nl)          nxt_state=ADD_ONES;
            else if (din_was_null)   nxt_state=HALT;
            else                    nxt_state=WAIT_ONES;
            //save read data if number
            if (shift_reg_valid) nxt_sav_reg=shift_reg_value;
            for (integer i=0; i<4; i++)
                nxt_shift_reg[i+1] = shift_reg[i];
            nxt_shift_reg[0] = din;
            //signal that we'll consume that if it was valid
            din_re=1;
        end

        ADD_ONES: begin
            nxt_state=DISP;
            onesplace=1'b1;
        end
        DISP: begin
            nxt_state=WAIT_TENS;
            dout_valid=1;
        end

        HALT: begin
                                    nxt_state=HALT;
            dout_valid=1'b1;
            done=1'b1;
        end

    endcase
end

endmodule