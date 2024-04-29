.include "femtorv32.inc"
.include "ssd1351_1331.inc"
	
##############################################################

# Oled window a0=x1 a1=y1 a2=x2 a3=y2
.global	st7735_write_window
.type	st7735_write_window, @function
st7735_write_window:
	OLED4 0x2a, 0x00, 0x1a, 0x00, 0x6a # CMD_PARAM4_CASET = 8'h6A;
	OLED4 0x2B, 0x00, 0x01, 0x00, 0xa1 # CMD_PARAM4_RASET = 8'hA1;
	OLED0 0x2C
	
	PIXEL_DATA 0xff, 0xff, 0xff, 0xff
	PIXEL_DATA 0xaa, 0xbb, 0xcc, 0xdd
	add sp,sp,-4
        sw ra, 0(sp)
	mv t0, a0
	mv t1, a2
	mv t2, a1
	mv t3, a3
	li a0, 0x2c
	mv a1, t0
	mv a2, t1
	call oled2
	li a0, 0x75
	mv a1, t2
	mv a2, t3
	call oled2
.ifdef SSD1351	
	li a0, 0x5c
	call oled0
.endif	
	lw ra, 0(sp)
	add sp,sp,4
	ret
	
#############################################################
	
# Oled display command, 0 argument, command in a0
.global	oled0
.type	oled0, @function
oled0:	add sp,sp,-4
        sw ra, 0(sp)
	sw a0, IO_SSD1351_CMD(gp)
	lw ra, 0(sp)
	add sp,sp,4
	ret

#################### Commands for SSD1351 #########################
	
.ifndef SSD1331

# Oled display command, 1 argument, command in a0, arg in a1	
.global	oled1
.type	oled1, @function
oled1:	add sp,sp,-4
        sw ra, 0(sp)
	sw a0, IO_SSD1351_CMD(gp)
	sw a1, IO_SSD1351_DAT(gp)
	lw ra, 0(sp)
	add sp,sp,4
	ret
	
# Oled display command, 2 arguments, command in a0, args in a1,a2
.global	oled2
.type	oled2, @function
oled2:	add sp,sp,-4
        sw ra, 0(sp)
	sw a0, IO_SSD1351_CMD(gp)
	sw a1, IO_SSD1351_DAT(gp)
	sw a2, IO_SSD1351_DAT(gp)
	lw ra, 0(sp)	
        add sp,sp,4
	ret

# Oled display command, 3 arguments, command in a0, args in a1,a2,a3
.global	oled3
.type	oled3, @function
oled3:	add sp,sp,-4
        sw ra, 0(sp)
	sw a0, IO_SSD1351_CMD(gp)
	sw a1, IO_SSD1351_DAT(gp)
	sw a2, IO_SSD1351_DAT(gp)
	sw a3, IO_SSD1351_DAT(gp)
	lw ra, 0(sp)
	add sp,sp,4
	ret
.endif

	
# .ifdef ST7735

# Oled display command, 4 arguments, command in a0, args in a1,a2,a3,a4
.global	oled4
.type	oled4, @function
oled4:	add sp,sp,-4
        sw ra, 0(sp)
	sw a0, IO_SSD1351_CMD(gp)
	sw a1, IO_SSD1351_DAT(gp)
	sw a2, IO_SSD1351_DAT(gp)
	sw a3, IO_SSD1351_DAT(gp)
	sw a4, IO_SSD1351_DAT(gp)
	lw ra, 0(sp)
	add sp,sp,4
	ret

# .endif

.global	pixel_data
.type	pixel_data, @function
pixel_data:	add sp,sp,-4
        sw ra, 0(sp)
	sw a0, IO_SSD1351_DAT16(gp)
	sw a1, IO_SSD1351_DAT(gp)
	sw a2, IO_SSD1351_DAT(gp)
	sw a3, IO_SSD1351_DAT(gp)
	sw a4, IO_SSD1351_DAT(gp)
	lw ra, 0(sp)
	add sp,sp,4
	ret
