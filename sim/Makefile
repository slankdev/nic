

IVERILOG = iverilog
VVP      = vvp

TOPMOD   = main
SRC      = main.v divider_circuit.v

all:
	$(IVERILOG) -o $(TOPMOD) -s $(TOPMOD) $(SRC) 


test:
	$(VVP) $(TOPMOD)


clean:
	rm -f $(TOPMOD) wave.vcd
