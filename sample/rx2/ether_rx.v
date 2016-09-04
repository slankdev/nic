`timescale 1ns / 1ps

module ether_rx(
	erx_clk, erx_rxd, erx_dv, erx_err,
	erx_cs, erx_ready, erx_cmd, erx_data, erx_debug
);

	input erx_clk;
	input [3:0] erx_rxd;
	input erx_dv;
	input erx_err;

	input erx_cs;
	output erx_ready;
	input [3:0] erx_cmd;
	output [31:0] erx_data;
	output [7:0] erx_debug;

	reg [31:0] erx_data_reg;
	assign erx_data = erx_data_reg;
	reg erx_ready_reg;
	assign erx_ready = erx_ready_reg;

	parameter ERX_CMD_GETSIZE = 1;
	parameter ERX_CMD_GETDATA = 2;

	reg [31:0] mem_din;
	wire [31:0] mem_dout;
	reg mem_en;
	reg mem_wr;
	reg [8:0] mem_addr;

memory memory_rx(erx_clk, mem_din, mem_dout, mem_en, mem_wr, mem_addr);

	reg [8:0] size;
	reg [8:0] addr;

	reg start;
	reg start2;
	reg [3:0] status;
	reg [15:0] count;
	reg [31:0] data;

//	assign erx_debug[7:0] = 8'b00000000;
	assign erx_debug[3:0] = status;
	assign erx_debug[7:4] = count[3:0];

	parameter STATUS_READY      = 1;
	parameter STATUS_WAIT       = 2;
	parameter STATUS_IDLE       = 3;
	parameter STATUS_SENDDATA   = 4;
	parameter STATUS_PREAMBLE   = 5;
	parameter STATUS_DATA       = 6;
	parameter STATUS_END        = 7;

always @(negedge erx_clk)
begin
	if (start == start2)
	begin
		start  <= ~start;
		size   <= 0;
		status <= STATUS_READY;
	end
	else
	begin
		case (status)
		STATUS_READY:
		begin
			count <= 16;
			status <= STATUS_WAIT;
		end
		STATUS_WAIT:
		begin
			if (count)
			begin
				count <= count - 1;
			end
			else
			begin
				if (!erx_dv)
					status <= STATUS_IDLE;
			end
		end
		STATUS_IDLE:
		begin
			if (erx_dv)
			begin
				status <= STATUS_PREAMBLE;
			end
			else if (erx_cs)
			begin
				case (erx_cmd)
				ERX_CMD_GETSIZE:
				begin
					erx_data_reg[31:9] <= 23'b0;
					erx_data_reg[ 8:0] <= size;
					addr <= 0;
					erx_ready_reg <= ~erx_ready_reg;
					status <= STATUS_READY;
				end
				ERX_CMD_GETDATA:
				begin
					mem_en <= ~mem_en;
					mem_wr <= 1'b0;
					mem_addr <= addr;
					addr <= addr + 1;
					status <= STATUS_SENDDATA;
				end
				endcase
			end
		end
		STATUS_SENDDATA:
		begin
			erx_data_reg <= mem_dout;
			erx_ready_reg <= ~erx_ready_reg;
			status <= STATUS_READY;
		end
		STATUS_PREAMBLE:
		begin
			if (erx_rxd == 4'b1101)
			begin
				size <= 0;
				count <= 0;
//				count <= 1; // ‚È‚ºIH
				mem_din <= 32'h00000000;
				status <= STATUS_DATA;
			end
			else if (!erx_dv)
			begin
				status <= STATUS_END;
			end
		end
		STATUS_DATA:
		begin
			mem_din[31:28] <= erx_rxd;
			mem_din[27: 0] <= mem_din[31:4];
			count <= count + 1;
			if (count[2:0] == 3'b111)
			begin
				mem_en <= ~mem_en;
				mem_wr <= 1'b1;
				mem_addr <= count[11:3];
			end
			if (!erx_dv)
			begin
				size <= count[11:3];
				status <= STATUS_END;
			end
		end
		STATUS_END:
		begin
			erx_ready_reg <= ~erx_ready_reg;
			status <= STATUS_READY;
		end
		endcase
	end
end

endmodule
