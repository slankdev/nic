
module ether_ctrl(
	clk_2500K,
	mdc,
	mdio_z, mdio_in, mdio_out,
	loopback_en,
	trx_100Mbps_en,
	GbE_disable,
	fulldpx_en,
	linkup_en,
);

	input clk_2500K;
	output mdc;
	output mdio_z;
	input mdio_in;
	output mdio_out;

	output loopback_en;
	output trx_100Mbps_en;
	output GbE_disable;
	output fulldpx_en;
	output linkup_en;


	// assign loopback_en = 1'b0;
	// assign 100Mbps_en  = 1'b0;
	// assign GbE_disable = 1'b0;
	// assign fulldpx_en  = 1'b0;
	// assign linkup_en   = 1'b0;

endmodule









