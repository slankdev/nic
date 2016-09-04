
module main(
	clk, led,
	mdc, mdio_z, mdio_in, mdio_out,
	tx_en, tx_d,
	rx_dv, rx_d
);
	input clk;
	input [9:0] led;

	// STA
	output mdc;
	output mdio_z;
	input mdio_in;
	output mdio_out;

	// TX
	output tx_en;
	output [1:0] tx_d;
	
	// RX
	input rx_dv;
	input [1:0] rx_d;

	wire clk_2500K;
	assign clk_2500K = clk;

	ether_ctrl ctrl( 
		.clk_2500K(clk_2500K), 
		.mdc           (mdc     ),
		.mdio_z        (mdio_z  ),
		.mdio_in       (mdio_in ),
		.mdio_out      (mdio_out),
		.loopback_en   (led[9]),
		.trx_100Mbps_en(led[6]),
		.GbE_disable   (led[5]),
		.fulldpx_en    (led[4]),
		.linkup_en     (led[0])
	);
	ether_tx tx(
		.clk_50M(clk  ), 
		.tx_en  (tx_en),
		.tx_d   (tx_d )
	);	
	ether_rx rx(
		.clk_50M(clk  ), 
		.rx_dv  (rx_dv), 
		.rx_d   (rx_d )
	);	
	assign led[1] = tx_en;
	assign led[2] = rx_dv;
	
endmodule
