ARCH=rv32i
OPTIMIZE=
ABI=ilp32
RAM_SIZE=0x80000
DEVICES= -DFGA=1 -DNRV_IO_UART=1 -DNRV_IO_SSD1351=1 -DNRV_IO_UART_RX=1  -DNRV_IO_UART_TX=1
BOARD=icesugar_nano