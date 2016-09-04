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
					addr[15:14] <= 2'b01; // �X�^�[�g�I�u�t���[��
					addr[13:12] <= 2'b01; // ���C�g�T�C�N��
					addr[11: 7] <= 5'd0;  // PHY�A�h���X
					addr[ 6: 2] <= 5'd0;  // ���W�X�^�A�h���X
					addr[ 1: 0] <= 2'b10; // �^�[���A��E���h
					wdata[15] <= 1'b1; // ���Z�b�g
					wdata[14:0] <= 15'b0;
					count <= 14;
					wr <= 1;
					ectl_mdio_z_reg <= 1'b0;
					ectl_mdio_out_reg <= 1'b1;
					status <= STATUS_ADDR;
				end
				ECTL_CMD_SETMODE:
				begin
					addr[15:14] <= 2'b01; // �X�^�[�g�I�u�t���[��
					addr[13:12] <= 2'b01; // ���C�g�T�C�N��
					addr[11: 7] <= 5'd0;  // PHY�A�h���X
					addr[ 6: 2] <= 5'd0;  // ���WX�^�A�h���X
					addr[ 1: 0] <= 2'b10; // �^�[��A���E���h
					wdata[15] <= 1'b0; // ���Z�b�g���Ȃ�
					wdata[14] <= 1'b0; // ���[�v�o�b�N����
//					wdata[14] <= 1'b1; // ���[�v�o�b�N�L��
					wdata[13] <= 1'b1; // 100M
					wdata[ 6] <= 1'b0; // 100M
					wdata[12] <= 1'b0; // �I�[�g�l�S����
					wdata[11] <= 1'b0; // �ȓd�͖���
					wdata[10] <= 1'b0; // PHY�؂藣������
					wdata[ 9] <= 1'b0; // �I�[�g�l�S�J�n���Ȃ�
					wdata[ 8] <= 1'b1; // �S��d
					wdata[ 7] <= 1'b0; // �Փˎ�������
					wdata[5:0] <= 6'b000000; // �\��
					count <= 14;
					wr <= 1;
					ectl_mdio_z_reg <= 1'b0;
					ectl_mdio_out_reg <= 1'b1;
					status <= STATUS_ADDR;
				end
				ECTL_CMD_GETSTAT:
				begin
					addr[15:14] <= 2'b01; // �X�^�[�g�I�u�t���[��
					addr[13:12] <= 2'b10; // ���[�h�T�C�N��
					addr[11: 7] <= 5'd0;  // PHY�A�h���X
					addr[ 6: 2] <= 5'd1;  // ���W�X�^�A�h���X
					addr[ 1: 0] <= 2'b10; // �^�[���A���E���h
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
