`timescale 1ns / 1ps

module memory(CLK, DIN, DOUT, EN, WR, ADDR);

	input CLK;
	input [31:0] DIN;
	output [31:0] DOUT;
	input EN;
	input WR;
	input [8:0] ADDR;

	reg [31:0] mem[0:511];
//	reg [7:0] mem0[0:511];
//	reg [7:0] mem1[0:511];
//	reg [7:0] mem2[0:511];
//	reg [7:0] mem3[0:511];

	reg [31:0] dout_reg;
	assign DOUT = dout_reg;
//	reg [8:0] addr_reg;
//	assign DOUT = mem[addr_reg];

	reg en_old;

always @(posedge CLK)
begin
	if (EN != en_old)
	begin
		en_old <= EN;
		if (WR == 1'b1)
		begin
			mem[ADDR] <= DIN;
//			mem0[ADDR] <= DIN[ 7: 0];
//			mem1[ADDR] <= DIN[15: 8];
//			mem2[ADDR] <= DIN[23:16];
//			mem3[ADDR] <= DIN[31:24];
		end
		dout_reg <= mem[ADDR];
//		dout_reg[ 7: 0] <= mem0[ADDR];
//		dout_reg[15: 8] <= mem1[ADDR];
//		dout_reg[23:16] <= mem2[ADDR];
//		dout_reg[31:24] <= mem3[ADDR];
//		addr_reg <= ADDR;
	end
end

endmodule
