`timescale 1ns / 1ps

module rx(CLK_50M, RS232_DCE_RXD, LED, BTN_SOUTH);

	input CLK_50M;
	input RS232_DCE_RXD;
	output [7:0] LED;
	input BTN_SOUTH;

	wire reset;
	assign reset = BTN_SOUTH;

	wire rxd;
	assign rxd = RS232_DCE_RXD;

	reg [7:0] led_out;
	assign LED = led_out;

	reg [15:0] clock_count;
	reg clk_reset;
	reg clk_reset_old;
	reg serclk;
	reg serclk_old;

	reg receiving;
	reg parity;
	reg rxd_old;

	reg [15:0] buffer;

always @(posedge CLK_50M)
begin
	if (clk_reset != clk_reset_old)
	begin
		clock_count <= 0;
		clk_reset_old <= clk_reset;
	end
	// ストップビットが1.5ビット長の場合に受信開始と受信線読み込みが
	// タイミング的にぶつかるのを極力避けるために，ちょうど半分(2604)
	// ではなく 5/8 の位置でクロックを立ち下げて受信線読み込みを行う．
	else if (clock_count < 3255)
	begin
		serclk <= 1'b1;
		clock_count <= clock_count + 1;
	end
	else if (clock_count < 5208)
	begin
		serclk <= 1'b0;
		clock_count <= clock_count + 1;
	end
	else
	begin
		clock_count <= 0;
	end
end

always @(posedge reset or negedge CLK_50M)
begin
	if (reset == 1'b1)
	begin
		led_out    <=  8'b00000000;
		buffer     <= 16'b1111111111111111;
		receiving  <= 1'b0;
		parity     <= 1'b0;
		rxd_old    <= rxd;
	end
	else
	begin
		// ストップビットが1.5ビット長の場合に受信開始と受信線読み込み
		// が同時に起きた場合を考慮して，必ず serclk_old に代入する．
		serclk_old <= serclk;
		if (rxd_old != rxd)
		begin
			clk_reset <= 1'b1;
			rxd_old   <= rxd;
		end
		else if ((serclk_old == 1'b1) && (serclk == 1'b0)) // negedge
		begin
			if (buffer[0] == 1'b0)
			begin
				receiving    <= 1'b0;
				buffer[8:0]  <= 9'b111111111;
				buffer[14:9] <= buffer[15:10];
				buffer[15]   <= rxd;
				if (buffer[9] == 1'b1) // stop bit
					led_out <= buffer[8:1];
				else
					led_out <= 8'b11111111;

					// odd parity check
					// if (parity != 1'b1) error;
			end
			else
			begin
				if (receiving)
					parity <= parity ^ buffer[9];
				else if (buffer[9] == 1'b0) // start bit
				begin
					parity    <= 1'b0;
					receiving <= 1'b1;
				end
				buffer[14:0] <= buffer[15:1];
				buffer[15]   <= rxd;
			end
		end
	end
end

endmodule
