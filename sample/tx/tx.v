`timescale 1ns / 1ps

module tx(clk, txd, tch, cs, busy, reset);

	input clk;
	output txd;
	input [7:0] tch;
	input cs;
	output busy;
	input reset;

	parameter CLOCK = 50000000;
	parameter RATE = 9600;

	reg txd_out;
	assign txd = txd_out;
	reg busy_out;
	assign busy = busy_out;

	reg [15:0] clock_count;
	reg serclk;

	reg [9:0] buffer;
	reg [3:0] sendcnt;

always @(posedge clk)
begin
	if (clock_count < (CLOCK / RATE))
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
	if (reset)
	begin
		txd_out  <= 1'b1;
		busy_out <= 1'b0;
	end
	else if (busy_out == 1'b0)
	begin
		if (cs)
		begin
			buffer[0]   <= 1'b0;
			buffer[8:1] <= tch[7:0];
			buffer[9]   <= 1'b1;
			sendcnt     <= 0;
			busy_out    <= 1'b1;
		end
	end
	else
	begin
		if (sendcnt == 4'b1111)
		begin
			busy_out <= 1'b0;
		end
		else
		begin
			sendcnt <= sendcnt + 1;
		end
		txd_out     <= buffer[0];
		buffer[8:0] <= buffer[9:1];
		buffer[9]   <= 1'b1;
	end
end

endmodule
