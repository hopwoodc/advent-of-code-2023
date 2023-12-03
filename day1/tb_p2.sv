module tb;

integer fd;

//dut input signals
logic clk, rst_n;
logic [7:0] din;
logic din_rdy;

//dut output signals
logic [31:0] dout;
logic dout_valid;
logic din_re;
logic done;

day1p2 dut (
	//inputs
    clk,
    rst_n,
    din,
    din_rdy,
	//outputs
    dout,
    dout_valid,
    din_re,
	done
);


reg [8*32:0] filename= "input.txt";
logic [31:0] cycle_count;
initial begin
	$dumpfile("dut.vcd");
	$dumpvars(0, tb);
	//Have to explicitly dump arrays for debug
    for (integer i=0; i<5; i++) begin
        $dumpvars(0, dut.shift_reg[i], dut.nxt_shift_reg[i]);
    end

	cycle_count = 0;
	rst_n=0;
	din = 0;
	din_rdy = 0;
	clk=0;
	fd = $fopen(filename,"rb");
	if (fd==0)
	begin
	   $display("%m @%0t: Could not open file '%s'",$time,filename);
	   $finish;
	end
	else
	begin
	   $display("%m @%0t: Opened %s for reading",$time,filename);
	end
	
	//$display("%c", $fgetc(fd));

end


always @ (posedge clk) begin
	cycle_count <= cycle_count+1;
	rst_n <= 1;
	if (din_re) begin
		din <= $fgetc(fd);
		din_rdy <= 1;
	end
	if (dout_valid)
			$display("%d", dout);

	if (done || cycle_count > 10000000) begin
		$finish;
	end
end

always
	#5 clk = !clk;

endmodule