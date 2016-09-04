`timescale 1ns / 1ps

module ether_ctrl(
	ectl_mdc_out,
	ectl_mdio_z, ectl_mdio_in, ectl_mdio_out,
	clk, ectl_cs, ectl_ready,
	ectl_cmd, ectl_rdata, ectl_wdata
	);

	output ectl_mdc_out;
	output ectl_mdio_z;
	input ectl_mdio_in;
	output ectl_mdio_out;
	input clk;
	input ectl_cs;
	output ectl_ready;
	input [3:0] ectl_cmd;
	output [15:0] ectl_rdata;
	input [15:0] ectl_wdata;

	parameter ECTL_CMD_NOP     = 0;
	parameter ECTL_CMD_RESET   = 1;
	parameter ECTL_CMD_SETMODE = 2;
	parameter ECTL_CMD_GETSTAT = 3;

	reg ectl_mdio_z_reg;
	assign ectl_mdio_z = ectl_mdio_z_reg;
	reg ectl_mdio_out_reg;
	assign ectl_mdio_out = ectl_mdio_out_reg;
	reg ectl_ready_reg;
	assign ectl_ready = ectl_ready_reg;
	reg [15:0] ectl_rdata_reg;
	assign ectl_rdata = ectl_rdata_reg;

	reg ethclk;
	assign ectl_mdc_out = ethclk;
	reg [7:0] clk_count;
	parameter CLOCK    = 50000000;
	parameter ETHCLOCK =  2500000;

always @(posedge clk)
begin
	if (clk_count >= ((CLOCK / ETHCLOCK) / 2 - 1))
	begin
		ethclk <= ~ethclk;
		clk_count <= 0;
	end
	else
	begin
		clk_count <= clk_count + 1;
	end
end

	reg start;
	reg start2;
	reg [3:0] status;

	parameter STATUS_READY      = 1;
	parameter STATUS_PREAMBLE   = 2;
	parameter STATUS_IDLE       = 3;
	parameter STATUS_ADDR       = 4;
	parameter STATUS_TURNAROUND = 5;
	parameter STATUS_DATA       = 6;

	reg wr;
	reg [4:0] count;
	reg [15:0] addr;
	reg [15:0] rdata;
	reg [15:0] wdata;

always @(negedge ethclk)
begin
	if (start == start2)
	begin
		start      <= ~start;
		status     <= STATUS_READY;
	end
	else
	begin
		case (status)
		STATUS_READY:
		begin
			ectl_mdio_z_reg <= 1'b1;
			ectl_mdio_out_reg <= 1'b1;
			count           <= 31;
			status          <= STATUS_PREAMBLE;
		end
		STATUS_PREAMBLE:
		begin
			if (count)
				count <= count - 1;
			else
				status <= STATUS_IDLE;
		end
		STATUS_IDLE:
		begin
			if (ectl_cs)
			begin
				case (ectl_cmd)
				ECTL_CMD_NOP:
				begin
				end
				ECTL_CMD_RESET:
				begin
					addr[15:14] <= 2'b01; // スタートオブフレーム
					addr[13:12] <= 2'b01; // ライトサイクル
					addr[11: 7] <= 5'd0;  // PHYアドレス
					addr[ 6: 2] <= 5'd0;  // レジスタアドレス
					addr[ 1: 0] <= 2'b10; // ターンアラEンド
					wdata[15] <= 1'b1; // リセット
					wdata[14:0] <= 15'b0;
					count <= 14;
					wr <= 1;
					ectl_mdio_z_reg <= 1'b0;
					ectl_mdio_out_reg <= 1'b1;
					status <= STATUS_ADDR;
				end
				ECTL_CMD_SETMODE:
				begin
					addr[15:14] <= 2'b01; // スタートオブフレーム
					addr[13:12] <= 2'b01; // ライトサイクル
					addr[11: 7] <= 5'd0;  // PHYアドレス
					addr[ 6: 2] <= 5'd0;  // レジXタアドレス
					addr[ 1: 0] <= 2'b10; // ター塔Aラウンド
					wdata[15] <= 1'b0; // リセットしない
					wdata[14] <= 1'b0; // ループバック無効
//					wdata[14] <= 1'b1; // ループバック有効
					wdata[13] <= 1'b1; // 100M
					wdata[ 6] <= 1'b0; // 100M
					wdata[12] <= 1'b0; // オートネゴ無効
					wdata[11] <= 1'b0; // 省電力無効
					wdata[10] <= 1'b0; // PHY切り離し無効
					wdata[ 9] <= 1'b0; // オートネゴ開始しない
					wdata[ 8] <= 1'b1; // 全二重
					wdata[ 7] <= 1'b0; // 衝突試験無効
					wdata[5:0] <= 6'b000000; // 予約
					count <= 14;
					wr <= 1;
					ectl_mdio_z_reg <= 1'b0;
					ectl_mdio_out_reg <= 1'b1;
					status <= STATUS_ADDR;
				end
				ECTL_CMD_GETSTAT:
				begin
					addr[15:14] <= 2'b01; // スタートオブフレーム
					addr[13:12] <= 2'b10; // リードサイクル
					addr[11: 7] <= 5'd0;  // PHYアドレス
					addr[ 6: 2] <= 5'd1;  // レジスタアドレス
					addr[ 1: 0] <= 2'b10; // ターンアラウンド
					count <= 14;
					wr <= 0;
					ectl_mdio_z_reg <= 1'b0;
					ectl_mdio_out_reg <= 1'b1;
					status <= STATUS_ADDR;
				end
				endcase
			end
		end
		STATUS_ADDR:
		begin
			if (count)
			begin
				ectl_mdio_out_reg <= addr[15];
				addr[15:1] <= addr[14:0];
				addr[0] <= 1'b1;
				count <= count - 1;
			end
			else
			begin
				status <= STATUS_TURNAROUND;
				if (wr == 0)
				begin
					ectl_mdio_z_reg <= 1'b1;
					ectl_mdio_out_reg <= 1'b1;
				end
				else
				begin
					ectl_mdio_z_reg <= 1'b0;
					ectl_mdio_out_reg <= 1'b1;
				end
			end
		end
		STATUS_TURNAROUND:
		begin
			count <= 16;
			status <= STATUS_DATA;
			if (wr == 0)
			begin
//				if (ectl_mdio_in != 1'b0)
//				begin
//					// error
//				end
			end
			else
			begin
				ectl_mdio_out_reg <= 1'b0;
			end
		end
		STATUS_DATA:
		begin
			if (count)
			begin
				if (wr == 0)
				begin
					rdata[15:1] <= rdata[14:0];
					rdata[0] <= ectl_mdio_in;
//					rdata[0] <= ~rdata[0]; // for test
				end
				else
				begin
					ectl_mdio_out_reg <= wdata[15];
					wdata[15:1] <= wdata[14:0];
					wdata[0] <= 1'b1;
				end
				count <= count - 1;
			end
			else
			begin
				status <= STATUS_READY;
				ectl_ready_reg <= ~ectl_ready_reg;
				if (wr == 0)
				begin
					ectl_rdata_reg <= rdata;
				end
				else
				begin
					ectl_mdio_z_reg <= 1'b1;
					ectl_mdio_out_reg <= 1'b1;
				end
			end
		end
		endcase
	end
end

endmodule
