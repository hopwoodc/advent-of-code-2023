module day1p1(
    input clk,
    input rst_n,
    input [7:0] din,
    input din_rdy,
    output logic [31:0] dout,
    output logic dout_valid,
    output logic din_re
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
    WAIT_ONES,
    ADD_ONES,
    WAIT_TENS,
    ADD_TENS,
    HALT
} state_t;

state_t state, nxt_state;

logic [7:0] sav_reg, nxt_sav_reg;


wire din_is_num;
wire din_is_nl;
wire din_is_null;

logic onesplace;
logic tensplace;

assign din_is_num = din_rdy && (din >= "0" && din <= "9");
assign din_is_nl = din_rdy && din == "\n";
assign din_is_null = din_rdy && din == 8'hFF;

/*
Advance the state to the next state
*/
always_ff @(posedge clk, negedge rst_n) begin : advance_state
    if (!rst_n) begin 
        state <= RESET;
        sav_reg <= 8'b0;
        
        dout <= 0;
    end
    else begin 
        state <= nxt_state;
        sav_reg <= nxt_sav_reg;
        if (onesplace) dout <= dout + (sav_reg & 4'b1111);
        else if (tensplace) dout <= dout + ((sav_reg&4'b1111)*10);
        else dout <= dout;
    end
end

always_comb begin : state_logic
    nxt_state = UNDEF;
    nxt_sav_reg = sav_reg;
    onesplace = 0;
    tensplace = 0;
    dout_valid = 0;
    din_re = 0;

    case (state)
        RESET: begin
            nxt_state = WAIT_TENS;
        end
        WAIT_TENS: begin
            if (din_is_num)         nxt_state=ADD_TENS;
            else if(din_is_null)    nxt_state=HALT;
            else                    nxt_state=WAIT_TENS;
            /*  signal that we'll consume it if valid
                we only advance to next state if it was a num,
                so no check needed here*/
            nxt_sav_reg = din;
            //signal that we'll consume that if it was valid
            din_re = 1;
        end

        ADD_TENS: begin
            nxt_state=WAIT_ONES;
            tensplace=1'b1;
        end

        WAIT_ONES: begin
            //next state
            if (din_is_nl)          nxt_state=ADD_ONES;
            else if (din_is_null)   nxt_state=HALT;
            else                    nxt_state=WAIT_ONES;
            //save read data if number
            if (din_is_num) nxt_sav_reg=din;
            //signal that we'll consume that if it was valid
            din_re=1;
        end

        ADD_ONES: begin
            nxt_state=WAIT_TENS;
            onesplace=1'b1;
        end

        HALT: begin
                                    nxt_state=HALT;
            dout_valid=1'b1;
        end

    endcase
end

endmodule