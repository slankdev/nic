

module div_2(
	in_clk,
	out_clk
);
	input  in_clk;
	output out_clk;

	reg [3:0] regs;

always @(posedge in_clk)
begin
	regs = regs + 1;
end
	
	assign out_clk = regs[1];

endmodule

