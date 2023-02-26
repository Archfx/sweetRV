FEMTORV_DIR=$(dir $(abspath $(lastword $(MAKEFILE_LIST))))
PROJECTNAME=femtosoc
VERILOGS=RTL/$(PROJECTNAME).v


include BOARDS/icesugar_nano.mk



.PHONY: all clean terminal testbench 

################################################################################

all:
	@echo "make one of ICESTICK, ICEFEATHER, ULX3S... (or .synth / .prog)"

clean:
	rm -f *.timings *.asc *.bin *.bit *config *.json *.svf \
              *~ *.vvp *.dfu *.rpt *.blif femtosoc.txt FIRMWARE/config.mk

TERMS=/dev/ttyUSB1 /dev/ttyUSB0 

# Uncomment one of the following lines (pick your favorite term emulator)
#terminal: terminal_miniterm
#terminal: terminal_screen
terminal: terminal_picocom

# # make terminal, rule for miniterm
# # exit: <ctrl> ]     package: sudo apt-get install python3-serial
# terminal_miniterm:
# 	for i in $(TERMS); do miniterm --dtr=0 $$i 115200; done

# # make terminal, rule for screen
# # exit: <ctrl> a \   package: sudo apt-get install screen
# terminal_screen:
# 	for i in $(TERMS); do screen $$i 115200; done

# make terminal, rule for picocom
# exit: <ctrl> a \   package: sudo apt-get install picocom
#terminal_picocom:
	for i in $(TERMS); do picocom -b 115200 $$i --imap lfcrlf,crcrlf --omap delbs,crlf --send-cmd "ascii-xfr -s -l 30 -n"; done
