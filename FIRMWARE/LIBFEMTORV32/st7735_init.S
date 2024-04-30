.include "femtorv32.inc"
.include "ssd1351_1331.inc"
	
################################################################################
	
# initialize oled display
.global	st7735_init
.type	st7735_init, @function
st7735_init:
	add sp,sp,-4
        sw ra, 0(sp)

# .ifdef st7735
	# Initialization sequence / RESET
	# li a0,5
	# sw a0,IO_LEDS(gp)
    #     li a0,1                      # reset low during 0.25 s
	# sw a0,IO_SSD1351_CNTL(gp)
	# li a0,250
	# call milliwait
	# li a0,10
	# sw a0,IO_LEDS(gp)
    #     li a0,3                      # reset high during 0.25 s
	# sw a0,IO_SSD1351_CNTL(gp)
	# li a0,250
	# call milliwait
	# li a0,15
	# sw a0,IO_LEDS(gp)
    #     li a0,0                      # normal operation
	# sw a0,4(gp)

	#  parameter CMD_SWRESET_DELAY = 300000; //150ms delay (150*2000)
#  parameter CMD_SLPOUT_DELAY = 510000; //255ms delay
#  parameter CMD_NORON_DELAY = 20000; //10ms delay
#  parameter CMD_DISPON_DELAY = 200000; //100ms delay

	# Initialization sequence / configuration
	OLED0 0x01 #software reset CMD_SWRESET = 8'h01
	li a0,150
	call milliwait
	OLED0 0x11 #exit sleep mode CMD_SLPOUT = 8'h11
	li a0,255
	call milliwait
	OLED1 0xb4, 0x07 #display inversion control CMD_INVCTR = 8'hb4 //normal mode CMD_PARAM_INVCTR = 8'h07; //normal mode 
    OLED3 0xc0, 0xa2, 0x02, 0x84 # CMD_PARAM3_PWCTR1 = 8'h84;
    OLED2 0xc3, 0x8A, 0x2a # CMD_PARAM2_PWCTR4 = 8'h2A;//8'h2E;
    OLED2 0xc4, 0x8A, 0xee # CMD_PARAM2_PWCTR5 = 8'hEE;//8'hAA;
    OLED1 0xc5, 0x0e # CMD_PARAM_VMCTR1 = 8'h0E; 
    OLED0 0x21 # CMD_INVON = 8'h21;
    OLED1 0x36, 0xc8 # CMD_PARAM_MADCTL = 8'hC8;
    OLED1 0x3A, 0x05 # CMD_PARAM_COLMOD = 8'h05;

      # x  Top left corner x coordinate
      # y  Top left corner x coordinate
      # w  Width of window
      # h  Height of window

    OLED4 0x2a, 0x00, 0x1a, 0x00, 0x6a # CMD_PARAM4_CASET = 8'h6A;
      #start and end of row position to draw on the screen
      #the drawable area is starting at 0
    OLED4 0x2B, 0x00, 0x01, 0x00, 0xa1 # CMD_PARAM4_RASET = 8'hA1;
    OLED0 0x13 # CMD_NORON = 8'h13;
	li a0,10
	call milliwait
    OLED0 0x29 # CMD_DISPON = 8'h29;
	li a0,100
	call milliwait
    OLED0 0x2C #CMD_RAMWR = 8'h2C;
	
	li s2,12720	
	li s3,0
	li t0,0xffffffff #init color

# loop_y:	li s0,0
init_loop:	add s0,s0,1

	# li t0,0x55555555

	sw t0, IO_SSD1351_DAT16(gp)
	# sw t0, IO_SSD1351_DAT16(gp)
	
	bne s0,s2,init_loop
	# add s1,s1,1
	# bne s1,s0,loop_y
	# add s3,s3,1


	sw s3, 0(gp)
	# OLED0 0x2C #CMD_RAMWR = 8'h2C;

	# PIXEL_DATA 0xff, 0xff, 0xff, 0xff
	


	# OLED1 0xfd, 0x12             # unlock driver
	# OLED1 0xfd, 0xb1             # unlock commands
	# OLED0 0xae                   # display off
	# OLED0 0xa4                   # display mode off
	# OLED2 0x15,0x00,0x7f         # column address
	# OLED2 0x75,0x00,0x7f         # row address
	# OLED1 0xb3,0xf1              # front clock divider (see section 8.5 of manual)
	# OLED1 0xca, 0x7f             # multiplex
	# OLED1 0xa0, 0x74             # remap, data format, increment
	# OLED1 0xa1, 0x00             # display start line
	# OLED1 0xa2, 0x00             # display offset
	# OLED1 0xab, 0x01             # VDD regulator ON
	# OLED3 0xb4, 0xa0, 0xb5, 0x55 # segment voltage ref pins
	# OLED3 0xc1, 0xc8, 0x80, 0xc0 # contrast current for colors A,B,C
	# OLED1 0xc7, 0x0f             # master contrast current
	# OLED1 0xb1, 0x32             # length of segments 1 and 2 waveforms
	# OLED3 0xb2, 0xa4, 0x00, 0x00 # display enhancement
	# OLED1 0xbb, 0x17             # first pre-charge voltage phase 2
	# OLED1 0xb6, 0x01             # second pre-charge period (see table 9-1 of manual)
	# OLED1 0xbe, 0x05             # Vcomh voltage
	# OLED0 0xa6                   # display on
	# OLED0 0xaf                   # display mode on
# .endif

# animate:

#     OLED4 0x2a, 0x00, 0x1a, 0x00, 0x6a # CMD_PARAM4_CASET = 8'h6A;
#       #start and end of row position to draw on the screen
#       #the drawable area is starting at 0
#     OLED4 0x2B, 0x00, 0x01, 0x00, 0xa1 
# 	OLED0 0x2C #CMD_RAMWR = 8'h2C

# 		li s2,128	
# 		li s3,0
# 		li t0,0x00 #init color

# 	loop_y_2:	li s0,0
# 	loop_x_2:	add s0,s0,1

# 		# li t0,0x55555555
# 		add t0,s0,s3
# 		sll t0,t0,3
		
# 		srl t1,s0,5
# 		and t1,t1,7
# 		or  t0,t0,t1

# 		sw t0, IO_SSD1351_DAT16(gp)
# 		# sw t0, IO_SSD1351_DAT16(gp)
		
# 		bne s0,s2,loop_x_2
# 		add s1,s1,1
# 		bne s1,s0,loop_y_2
# 		add s3,s3,1


# 		sw s3, 0(gp)

# 		call animate

	lw ra, 0(sp)
	add sp,sp,4
	ret

##############################################################
