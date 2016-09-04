

module div_2(
	in_clk,
	out_clk
);
	input  in_clk;
	output out_clk;

	reg tmp;

always @(posedge in_clk)
begin
	tmp = ~tmp;
end

	assign out_clk = tmp;

endmodule

