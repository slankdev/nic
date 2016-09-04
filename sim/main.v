
`timescale 1ns / 1ps
module main;
	reg clk;
	wire out;

	parameter STEP = 100;
	always #(STEP/2) clk = ~clk;
	initial
	begin
		#0    clk = 0;
		#STEP clk = 1;
		#(STEP * 20)
		$finish;
	end

	div_2 div_2(
		.in_clk  (clk),
		.out_clk (out)
	);

	initial
	begin
		$dumpfile("wave.vcd");
		$dumpvars(0, main);
	end
	initial $monitor ($stime, "clk=%b out=%b", clk, out);

endmodule
