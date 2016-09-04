`timescale 1ns / 1ps

module main(
	CLK_50M, LED,
	RS232_DCE_RXD, RS232_DCE_TXD, 
	E_TX_CLK, E_TXD, E_TX_EN, E_CRS, E_COL,
	E_RX_CLK, E_RXD, E_RX_DV, E_RX_ERR,
	E_MDC, E_MDIO, E_NRST //, E_NINT,
);

	input CLK_50M;
	output [7:0] LED;

	input RS232_DCE_RXD;
	output RS232_DCE_TXD;
 
	input E_TX_CLK;
	output [3:0] E_TXD;
	output E_TX_EN;
	input E_CRS;
	input E_COL;

	input E_RX_CLK;
	input [3:0] E_RXD;
	input E_RX_DV;
	input E_RX_ERR;

	output E_MDC;
	inout E_MDIO;
	output E_NRST;
	// E_NINT

	reg e_nrst_reg;
	assign E_NRST = e_nrst_reg;

	// ƒRƒ“ƒpƒCƒ‹‚Ì‚½‚ß‚Ébè‚Åƒ[ƒ‚ğoÍ
	assign E_TX_EN = 1'b0;
	assign E_TXD = 4'b0000;

	wire clk;
	wire txd;
	wire rxd;
	assign clk = CLK_50M;
	assign RS232_DCE_TXD = txd;
	assign rxd = RS232_DCE_RXD;

	reg reset;

// serial com.

	reg [7:0] tx_tch;
	reg tx_cs;
	wire tx_busy;
tx tx(~clk, txd, tx_tch, tx_cs, tx_busy, reset);

	wire [7:0] rx_rch;
	wire rx_rcv;
rx rx(~clk, rxd, rx_rch, rx_rcv, reset);

	reg rx_rcv_old;
	reg [7:0] rcv_cmd;
	reg [63:0] rcv_data;

// ether com.

	wire ether_ctrl_mdc_out;
	assign E_MDC = ether_ctrl_mdc_out;
	wire ether_ctrl_mdio_z;
	wire ether_ctrl_mdio_out;
	assign E_MDIO = ether_ctrl_mdio_z ? 1'bZ : ether_ctrl_mdio_out;
//	assign E_MDIO = ether_ctrl_mdio_out; // for test
	reg ether_ctrl_cs;
	wire ether_ctrl_ready;
	reg ether_ctrl_ready_save;
	reg [3:0] ether_ctrl_cmd;
	wire [15:0] ether_ctrl_rdata;
	reg [15:0] ether_ctrl_wdata;

ether_ctrl ether_ctrl(
	ether_ctrl_mdc_out,
	ether_ctrl_mdio_z, E_MDIO, ether_ctrl_mdio_out,
	~clk, ether_ctrl_cs, ether_ctrl_ready,
	ether_ctrl_cmd, ether_ctrl_rdata, ether_ctrl_wdata
	);

// state machine

	reg start;
	reg start2;
	reg [3:0] status;
	parameter STATUS_START       = 4'd1;
	parameter STATUS_INITIALIZE  = 4'd2;
	parameter STATUS_INITEND     = 4'd3;
	parameter STATUS_IDLE        = 4'd4;
	parameter STATUS_SETMODE_START = 4'd5;
	parameter STATUS_SETMODE_SETTING = 4'd6;
	parameter STATUS_GETSTAT_START = 4'd7;
	parameter STATUS_GETSTAT_GETTING = 4'd8;
//	parameter STATUS_READ_START  = 4'd5;
//	parameter STATUS_WRITE_START = 4'd6;
//	parameter STATUS_READING     = 4'd7;
//	parameter STATUS_WRITING     = 4'd8;
	parameter STATUS_SEND        = 4'd9;
	parameter STATUS_SENDING     = 4'd10;
	parameter STATUS_SENDED      = 4'd11;
	parameter STATUS_UNKNOWN     = 4'b1111;

	parameter START_WAIT   = 5000000; // 100ms
	parameter RESET_WAIT   = 5000000; // 100ms
	parameter INITEND_WAIT = 5000000; // 100ms
//	parameter START_WAIT   = 50000000; // 1s
//	parameter INITEND_WAIT = 50000000; // 1s

	reg [31:0] wait_count;
	reg [4:0] send_count;
	reg [127:0] send_ch;

// LED

	assign LED[7] = 0;
	assign LED[6] = 0;
	assign LED[5] = 0;
	assign LED[4] = 0;
	assign LED[3] = 0;
	assign LED[2] = 0;
	assign LED[1] = 0;
	assign LED[0] = 0;

// functions

function [3:0] a2b4;
input [7:0] a;
begin
	if ((a >= 8'h30) && (a <= 8'h39))
		a2b4 = (a - 8'h30);
	else if ((a >= 8'h61) && (a <= 8'h66))
		a2b4 = (a - 8'h57);
	else if ((a >= 8'h41) && (a <= 8'h46))
		a2b4 = (a - 8'h37);
	else
		a2b4 = 8'd0;
end
endfunction

function [7:0] a2b8;
input [15:0] a;
begin
	a2b8[7:4] = a2b4(a[15:8]);
	a2b8[3:0] = a2b4(a[ 7:0]);
end
endfunction

function [7:0] b2a4;
input [3:0] b;
begin
	if (b <= 4'd9)
	begin
		b2a4 = b + 8'h30;
	end
	else
	begin
		b2a4 = b + 8'h57;
	end
end
endfunction

function [15:0] b2a8;
input [7:0] b;
begin
	b2a8[15:8] = b2a4(b[7:4]);
	b2a8[ 7:0] = b2a4(b[3:0]);
end
endfunction

// main

always @(posedge clk)
begin
	if (start == start2)
	begin
		start      <= ~start;
		e_nrst_reg <= 1'b0;
		wait_count <= START_WAIT;
		status     <= STATUS_START;
	end
	else if (wait_count > 0)
	begin
		wait_count <= wait_count - 1;
	end
	else
	begin
		case (status)
		STATUS_START:
		begin
			e_nrst_reg     <= 1'b1;
			reset          <= 1'b1;
			tx_cs          <= 1'b1;
			ether_ctrl_cs  <= 1'b1;
			ether_ctrl_cmd <= 4'h1;
			ether_ctrl_ready_save <= ether_ctrl_ready;
			wait_count     <= RESET_WAIT;
			status         <= STATUS_INITIALIZE;
		end
		STATUS_INITIALIZE:
		begin
			if (ether_ctrl_ready_save != ether_ctrl_ready)
			begin
				reset          <= 1'b0;
				tx_cs          <= 1'b0;
				ether_ctrl_cs  <= 1'b0;
				ether_ctrl_cmd <= 4'h0;
				status         <= STATUS_INITEND;
			end
		end
		STATUS_INITEND:
		begin
//				status <= STATUS_IDLE;
				status <= STATUS_SEND;
				send_count <= 5;
				send_ch[ 7: 0] <= 8'h52; // 'R'
				send_ch[15: 8] <= 8'h45; // 'E'
				send_ch[23:16] <= 8'h41; // 'A'
				send_ch[31:24] <= 8'h44; // 'D'
				send_ch[39:32] <= 8'h59; // 'Y'
		end
		STATUS_IDLE:
		begin
			if (rx_rcv_old != rx_rcv)
			begin
				rx_rcv_old <= rx_rcv;
				case (rx_rch)
				8'h24: // '$'
				begin
					rcv_cmd <= 0;
					rcv_data <= 0;
					status <= STATUS_SEND;
					send_count <= 1;
					send_ch[7:0] <= rx_rch;
				end
				8'h2b: // '+'
				begin
					case (rcv_cmd)
					8'h53: // 'S'
					begin
						status <= STATUS_SETMODE_START;
					end
					8'h47: // 'G'
					begin
						status <= STATUS_GETSTAT_START;
					end
//					8'h52: // 'R'
//					begin
//						address[31:0] <= rcv_data[31:0];
//						status <= STATUS_READ_START;
//					end
//					8'h57: // 'W'
//					begin
//						address[31:0] <= rcv_data[63:32];
//						data[31:0]    <= rcv_data[31: 0];
//						status <= STATUS_WRITE_START;
//					end
					default:
					begin
						status <= STATUS_SEND;
						send_count <= 3;
						send_ch[ 7: 0] <= 8'h45; // 'E'
						send_ch[15: 8] <= 8'h52; // 'R'
						send_ch[23:16] <= 8'h52; // 'R'
					end
					endcase
				end
				default:
				begin
					status <= STATUS_SEND;
					send_count <= 1;
					send_ch[7:0] <= rx_rch;
					if (rcv_cmd == 8'h00)
						begin
						rcv_cmd <= rx_rch;
					end
					else
					begin
						rcv_data[63: 4] <= rcv_data[59:0];
						rcv_data[ 3: 0] <= a2b4(rx_rch);
					end
				end
				endcase
			end
		end
		STATUS_SETMODE_START:
		begin
			ether_ctrl_cs  <= 1'b1;
			ether_ctrl_cmd <= 4'h2;
			ether_ctrl_ready_save <= ether_ctrl_ready;
			status <= STATUS_SETMODE_SETTING;
		end
		STATUS_SETMODE_SETTING:
		begin
			if (ether_ctrl_ready_save != ether_ctrl_ready)
			begin
				ether_ctrl_cs  <= 1'b0;
				ether_ctrl_cmd <= 4'h0;
				status <= STATUS_SEND;
				send_count <= 4;
				send_ch[ 7: 0] <= 8'h2b; // '+'
				send_ch[15: 8] <= 8'h53; // 'S'
				send_ch[23:16] <= 8'h45; // 'E'
				send_ch[31:24] <= 8'h54; // 'T'
			end
		end
		STATUS_GETSTAT_START:
		begin
			ether_ctrl_cs  <= 1'b1;
			ether_ctrl_cmd <= 4'h3;
			ether_ctrl_ready_save <= ether_ctrl_ready;
			status <= STATUS_GETSTAT_GETTING;
		end
		STATUS_GETSTAT_GETTING:
		begin
			if (ether_ctrl_ready_save != ether_ctrl_ready)
			begin
				ether_ctrl_cs  <= 1'b0;
				ether_ctrl_cmd <= 4'h0;
				status <= STATUS_SEND;
				send_count <= 5;
				send_ch[ 7: 0] <= 8'h2b; // '+'
				send_ch[15: 8] <= b2a4(ether_ctrl_rdata[15:12]);
				send_ch[23:16] <= b2a4(ether_ctrl_rdata[11: 8]);
				send_ch[31:24] <= b2a4(ether_ctrl_rdata[ 7: 4]);
				send_ch[39:32] <= b2a4(ether_ctrl_rdata[ 3: 0]);
			end
		end
//		STATUS_READ_START:
//		begin
//			status <= STATUS_READING;
//		end
//		STATUS_WRITE_START:
//		begin
//			status <= STATUS_WRITING;
//		end
//		STATUS_READING:
//		begin
//			status <= STATUS_SEND;
//			send_count <= 1;
//			send_ch[ 7: 0] <= 8'h2b; // '+'
//		end
//		STATUS_WRITING:
//		begin
//			status <= STATUS_SEND;
//			send_count <= 3;
//			send_ch[ 7: 0] <= 8'h2b; // '+'
//			send_ch[15: 8] <= 8'h4f; // 'O'
//			send_ch[23:16] <= 8'h4b; // 'K'
//		end
		STATUS_SEND:
		begin
			if (send_count == 0)
			begin
				status <= STATUS_IDLE;
			end
			else if (tx_busy == 1'b0)
			begin
				send_count <= send_count - 1;
				send_ch[119:0] <= send_ch[127:8];
				tx_tch <= send_ch[7:0];
				tx_cs <= 1'b1;
				status <= STATUS_SENDING;
			end
		end
		STATUS_SENDING:
		begin
			if (tx_busy == 1'b1)
			begin
				tx_cs <= 1'b0;
				status <= STATUS_SENDED;
			end
		end
		STATUS_SENDED:
		begin
			if (tx_busy == 1'b0)
				status <= STATUS_SEND;
		end
		default:
		begin
			status <= STATUS_UNKNOWN;
		end
		endcase
	end
end
endmodule
