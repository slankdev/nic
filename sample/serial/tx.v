`timescale 1ns / 1ps

module tx(CLK_50M, RS232_DCE_TXD, LED, BTN_SOUTH);

	input CLK_50M;
	output RS232_DCE_TXD;
	output [7:0] LED;
	input BTN_SOUTH;

	wire reset;
	assign reset = BTN_SOUTH;
	reg reset_pushed;

	reg txd_out;
	assign RS232_DCE_TXD = txd_out;

	reg [15:0] clock_count;
	reg serclk;

	reg [3:0] ch;

	reg [9:0] buffer;
	reg [3:0] sendcnt;
	assign LED[7:0] = buffer[7:0];

always @(posedge CLK_50M)
begin
	if (clock_count < 5208)
	begin
		serclk <= 1'b0;
		clock_count <= clock_count + 1;
	end
	else
	begin
		serclk <= 1'b1;
		clock_count <= 0;
	end
end

always @(posedge serclk)
begin
	txd_out <= buffer[0];
	if ((reset == 1'b1) && (sendcnt == 0))
	begin
		buffer[0]   <= 1'b0;
		buffer[8:5] <= 4'h4;
		buffer[4:1] <= ch;
		buffer[9]   <= 1'b1;
		ch          <= ch + 1;
		sendcnt     <= 1;
	end
	else
	begin
		if (sendcnt != 0)
			sendcnt <= sendcnt + 1;
		buffer[8:0] <= buffer[9:1];
		buffer[9]   <= 1'b1;
	end
end

endmodule
