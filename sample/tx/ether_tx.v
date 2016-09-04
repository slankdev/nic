`timescale 1ns / 1ps

module ether_tx(
	etx_clk, etx_txd, etx_en, etx_crs, etx_col,
	etx_cs, etx_ready, etx_cmd, etx_data, etx_debug
);

	input etx_clk;
	output [3:0] etx_txd;
	output etx_en;
	input etx_crs;
	input etx_col;

	input etx_cs;
	output etx_ready;
	input [3:0] etx_cmd;
	input [31:0] etx_data;
	output [7:0] etx_debug;

	reg [3:0] etx_txd_reg;
	assign etx_txd = etx_txd_reg;
	reg etx_en_reg;
	assign etx_en = etx_en_reg;
	reg etx_ready_reg;
	assign etx_ready = etx_ready_reg;

	parameter ETX_CMD_SETSIZE = 1;
	parameter ETX_CMD_SETDATA = 2;
	parameter ETX_CMD_SEND    = 3;
	parameter ETX_CMD_SETXOR  = 4;

	reg [31:0] mem_din;
	wire [31:0] mem_dout;
	reg mem_en;
	reg mem_wr;
	reg [8:0] mem_addr;

memory memory_tx(etx_clk, mem_din, mem_dout, mem_en, mem_wr, mem_addr);

	reg [8:0] size;
	reg [8:0] addr;

	reg start;
	reg start2;
	reg [3:0] status;
	reg [15:0] count;
	reg [31:0] data;
	reg [31:0] crc;
	reg [31:0] crcdata;
	reg [31:0] fcs;
	reg [31:0] xordata;

//	assign etx_debug[7:0] = 8'h00;
//	assign etx_debug[3:0] = status;
//	assign etx_debug[7:4] = count[3:0];
	assign etx_debug[7:0] = size[7:0];

	parameter STATUS_READY      =  1;
	parameter STATUS_INTERFRAME =  2;
	parameter STATUS_IDLE       =  3;
	parameter STATUS_READMEM    =  4;
	parameter STATUS_READMEM2   =  5;
	parameter STATUS_CALCCRC    =  6;
	parameter STATUS_PREAMBLE   =  7;
	parameter STATUS_SFD        =  8;
	parameter STATUS_DATA       =  9;
	parameter STATUS_EFD        = 10;
	parameter STATUS_SENDEND    = 11;

always @(negedge etx_clk)
begin
	if (start == start2)
	begin
		start  <= ~start;
		xordata <= 32'hffffffff;
		status <= STATUS_READY;
	end
	else
	begin
		case (status)
		STATUS_READY:
		begin
			// フレーム間にINTERFRAMEとして24クロックのウエイトを入れる
			etx_txd_reg <= 4'b0000;
			etx_en_reg  <= 1'b0;
			count       <= 24;
			status      <= STATUS_INTERFRAME;
		end
		STATUS_INTERFRAME:
		begin
			if (count)
				count <= count - 1;
			else
				status <= STATUS_IDLE;
		end
		STATUS_IDLE:
		begin
			if (etx_cs)
			begin
				case (etx_cmd)
				ETX_CMD_SETSIZE:
				begin
					size <= etx_data[8:0];
					addr <= 0;
					etx_ready_reg <= ~etx_ready_reg;
					status <= STATUS_READY;
				end
				ETX_CMD_SETDATA:
				begin
//					mem_din <= etx_data;
					mem_din[ 7: 0] <= etx_data[31:24];
					mem_din[15: 8] <= etx_data[23:16];
					mem_din[23:16] <= etx_data[15: 8];
					mem_din[31:24] <= etx_data[ 7: 0];
					mem_en <= ~mem_en;
					mem_wr <= 1'b1;
					mem_addr <= addr;
					etx_ready_reg <= ~etx_ready_reg;
					addr <= addr + 1;
					status <= STATUS_READY;
				end
				ETX_CMD_SETXOR:
				begin
					xordata <= etx_data;
					etx_ready_reg <= ~etx_ready_reg;
					status <= STATUS_READY;
				end
				ETX_CMD_SEND:
				begin
					crc    <= 32'hffffffff;
					count  <= 0;
					status <= STATUS_READMEM;
				end
				endcase
			end
		end
		STATUS_READMEM:
		begin
			if (count[13:5] == size)
			begin
				etx_txd_reg <= 4'b0101;
				etx_en_reg  <= 1'b1;
				count       <= 15;
				status <= STATUS_PREAMBLE;
			end
			// FCS格納部分はオールゼロとしてCRC計算するので、
			// ひとつ余分にv算する。
//			else if (count[13:5] >= size)
//			begin
//				// FCS格納部分はオールゼロとして計算
//				crcdata <= 32'h0;
//				status  <= STATUS_CALCCRC;
//			end
			else
			begin
				mem_en   <= ~mem_en;
				mem_wr   <= 1'b0;
				mem_addr <= count[13:5];
				status   <= STATUS_READMEM2;
			end
		end	
		STATUS_READMEM2:
		begin
			crcdata <= mem_dout;
			status  <= STATUS_CALCCRC;
		end
		STATUS_CALCCRC:
		begin
			crc <= {crc[30:0], 1'b0} ^ ((crc[31] ^ crcdata[0]) ? 32'h04c11db7 : 32'h0);
			crcdata[30:0] <= crcdata[31:1];
			crcdata[31] <= 1'b0;
			count <= count + 1;
			if (count[4:0] == 5'b11111)
			begin
				status <= STATUS_READMEM;
			end
		end
		STATUS_PREAMBLE:
		begin
			if (count)
				count <= count - 1;
			else
			begin
				status <= STATUS_SFD;
			end
		end
		STATUS_SFD:
		begin
			etx_txd_reg <= 4'b1101;
			count     <= 0;
			mem_en    <= ~mem_en;
			mem_wr    <= 1'b0;
			mem_addr  <= 0;
			status    <= STATUS_DATA;
		end
		STATUS_DATA:
		begin
			// 下位４ビット、上位４ビットの順で送信
			case (count[2:0])
			3'b000:
			begin
				etx_txd_reg <= mem_dout[3:0];
				data[27:0] <= mem_dout[31:4];
				count <= count + 1;
			end
			3'b111:
			begin
				etx_txd_reg <= data[3:0];
				data[27:0] <= data[31:4];
				if (count[11:3] + 1 == size)
				begin
					fcs <= crc ^ xordata;
					count <= 8;
					status <= STATUS_EFD;
				end
				else
				begin
					mem_addr <= count[11:3] + 1;
					mem_en <= ~mem_en;
					count <= count + 1;
				end
			end
			default:
			begin
				etx_txd_reg <= data[3:0];
				data[27:0] <= data[31:4];
				count <= count + 1;
			end
			endcase
		end
		STATUS_EFD:
		begin
			// ４バイトのFCSを上位から送信(MSBから送信)
			etx_txd_reg[0] <= fcs[31];
			etx_txd_reg[1] <= fcs[30];
			etx_txd_reg[2] <= fcs[29];
			etx_txd_reg[3] <= fcs[28];
			fcs[31:4] <= fcs[27:0];
			count <= count - 1;
			if (count == 1)
			begin
//				etx_en_reg  <= 1'b0; // ここでいいか？
				status <= STATUS_SENDEND;
			end
		end
		STATUS_SENDEND:
		begin
			etx_en_reg  <= 1'b0; // それともこっち？
			etx_ready_reg <= ~etx_ready_reg;
			status <= STATUS_READY;
		end
		endcase
	end
end

endmodule
