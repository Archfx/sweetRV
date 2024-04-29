
module st7735_clk #(
   parameter width=1
)(
   input  wire clk,               // input system clock
   output wire oled_clk,               // st7735 clock
   output wire oled_clk_falling_edge   // pulses at each falling edge of oled_clk		   
);
   reg [width-1:0] slow_cnt;
   always @(posedge clk) begin
      slow_cnt <= slow_cnt + 1;
   end
   assign oled_clk = slow_cnt[width-1];
   assign oled_clk_falling_edge = (slow_cnt == (1 << width)-1);
endmodule   

module st7735_controller(
    input wire 	      clk,       // system clock
    input wire 	      wstrb,     // write strobe (use one of sel_xxx to select dest)
    input wire 	      sel_cntl,  // wdata[0]: !oled_cs;  wdata[1]: reset
    input wire 	      sel_cmd,   // send 8-bits command to display
    input wire 	      sel_dat,   // send 8-bits data to display
    input wire 	      sel_dat16, // send 16-bits data to display

    input wire [31:0] wdata,    // data to be written

    output wire       wbusy,    // asserted if the driver is busy senoled_mosig data

                        // st7735 pins	       
    output 	            oled_mosi, // data in
    output 	            oled_clk, // clock
    output reg 	      oled_cs,  // chip select (active low)
    output reg 	      oled_dc,  // data (high) / command (low)
    output reg 	      reset  // reset (active low)
);
  
   initial begin
      oled_dc  = 1'b0;
      reset = 1'b0;
      oled_cs  = 1'b1;
   end

   /********* The clock ****************************************************/
   // Note: SSD1351 expects the raising edges of the clock in the middle of
   // the data bits.
   // TODO: try to have a 'waveform' instead, that is shifted (simpler and
   //       more elegant).
   // Page 52 of the doc: 4-wire SPI timing:
   //   Unclear what 'Clock Cycle Time' (220 ns) means,
   //   Clock Low Time (20ns) + Clock High Time (20ns) = 40ns
   //   max freq = 1/(40ns) = 25 MHz
   //   experimentally, seems to work up to 30 Mhz (but not more)
   
   wire oled_clk_falling_edge;
   
   generate
   
   if(`NRV_FREQ <= 12) begin           // Divide by 2 -> 6 MHz
         st7735_clk #(
            .width(1)
         )slow_clk(
            .clk(clk),
            .oled_clk(oled_clk),
            .oled_clk_falling_edge(oled_clk_falling_edge)
	);

   end else if(`NRV_FREQ <= 60) begin           // Divide by 2-> 30 MHz
         st7735_clk #(
            .width(1)
         )slow_clk(
            .clk(clk),
            .oled_clk(oled_clk),
            .oled_clk_falling_edge(oled_clk_falling_edge)
	);
      end else if(`NRV_FREQ <= 120) begin // Divide by 4
         st7735_clk #(
            .width(2)
         )slow_clk(
            .clk(clk),
            .oled_clk(oled_clk),
            .oled_clk_falling_edge(oled_clk_falling_edge)
         );
      end else begin                      // Divide by 8
         st7735_clk #(
            .width(3)
         )slow_clk(
            .clk(clk),
            .oled_clk(oled_clk),
            .oled_clk_falling_edge(oled_clk_falling_edge)
         );
      end
    endgenerate

   // Currently sent bit, 1-based index
   // (0000 config. corresponds to idle)
   reg[4:0]  bitcount = 5'b0000;
   reg[15:0] shifter  = 0;
   wire      senoled_mosig  = (bitcount != 0);

   assign oled_mosi = shifter[15];
   assign wbusy = senoled_mosig;

   /*************************************************************************/
   
   always @(posedge clk) begin
      if(wstrb) begin
	 if(sel_cntl) begin
	    oled_cs  <= !wdata[0];
	    reset <= wdata[1];
	 end
	 if(sel_cmd) begin
	    reset <= 1'b1;
	    oled_dc <= 1'b0;
	    shifter <= {wdata[7:0],8'b0};
	    bitcount <= 8;
	    oled_cs  <= 1'b1;
	 end
	 if(sel_dat) begin
 	    reset <= 1'b1;
	    oled_dc <= 1'b1;
	    shifter <= {wdata[7:0],8'b0};
	    bitcount <= 8;
	    oled_cs  <= 1'b1;
	 end
	 if(sel_dat16) begin
 	    reset <= 1'b1;
	    oled_dc <= 1'b1;
	    shifter <= wdata[15:0];
	    bitcount <= 16;
	    oled_cs  <= 1'b1;
	 end
      end else begin 
	 // detect falling edge of slow_clk
	 if(oled_clk_falling_edge) begin 
	    if(senoled_mosig) begin
	       if(oled_cs) begin    // first tick activates oled_cs (low)
		      oled_cs <= 1'b0;
	       end else begin  // shift on falling edge
            bitcount <= bitcount - 5'd1;
            shifter <= {shifter[14:0], 1'b0};
	       end
	    end else begin     // last tick deactivates oled_cs (high) 
	       oled_cs  <= 1'b1;  
	    end
	 end
      end
   end
endmodule

// module st7735_controller(
//     input wire 	      clk,       // system clock
//    //  input wire 	      wstrb,     // write strobe (use one of sel_xxx to select dest)
//    //  input wire 	      sel_cntl,  // wdata[0]: !oled_cs;  wdata[1]: reset
//    //  input wire 	      sel_cmd,   // send 8-bits command to display
//    //  input wire 	      sel_dat,   // send 8-bits data to display
//    //  input wire 	      sel_dat16, // send 16-bits data to display

//     input wire [31:0] wdata,    // data to be written

//     output wire       wbusy,    // asserted if the driver is busy senoled_mosig data

//                            // oled pins	       
//     output oled_clk, 
//     output oled_mosi, 
//     output oled_dc, 
//     output oled_cs, 
//     output reset
// );


// wire  [7:0] x;
// wire [6:0] y;
  
 



// //the state machine will first send the init commands to set up the screen, then it will be
// //stuck in the send pixels mode and wait the pixels from the outside to send to the screen one by one


// // time delay values calculated correctly. Look at the adafruit library for specific configurations


// module st7735(
//    input clk, 
//    output reg oled_clk, 
//    output reg oled_mosi, 
//    output reg oled_dc, 
//    output reg oled_cs, 
//    output reg reset,
   
//    output reg  [7:0] x,
//    output reg  [6:0] y,
//    output reg  next_pixel, // 1 when x/y changes
//    input  wire [15:0] color
   
   
//    );

//    parameter FREQ_MAIN_HZ = 12000000; // Pulse width (1/12)us
//    parameter FREQ_TARGET_SPI_HZ = 4000000; // Pulse width (1/3)us = (1/3000)ms // Pulse width (1/2)us = (1/2000)ms
//    parameter HALF__PERIOD = (FREQ_MAIN_HZ/FREQ_TARGET_SPI_HZ)/2;

//    parameter SCREEN_WIDTH = 161; //x - pixel size displayed on screen
//    parameter SCREEN_HEIGHT = 81; //y - pixel size displayed on screen

//    // parameter SCREEN_WIDTH = 80; //pixel size displayed on screen
//    // parameter SCREEN_HEIGHT = 160; //pixel size displayed on screen

   
//    reg [3:0] clk_counter_tx;
//    reg [24:0] counter_send_interval; //to wait between the commands

//    reg [4:0] current_byte_pos;
//    reg [19:0] current_pixel;

//    // reg [15:0] buffer_pixel_write;
//    // wire [15:0] buffer_pixel_write;

//    reg advertise_pixel_consume;
//    reg advertise_pixel_consume_buffer;
//    reg [15:0] pixel_display;

//    reg [1:0] state;
//    parameter SEND_CMD = 0, CMD_WAIT = 1, STATE_WAITING_PIXEL = 2,
//              STATE_FRAME = 3;

//    // parameter CMD_SWRESET_DELAY = 300000; //150ms delay (150*2000)
//    // parameter CMD_SLPOUT_DELAY = 510000; //255ms delay
//    // parameter CMD_NORON_DELAY = 20000; //10ms delay
//    // parameter CMD_DISPON_DELAY = 200000; //100ms delay


//    reg [23:0] delay_counter;
//    reg is_init;

//    reg buffer_free;
//    reg wr_en;
//    reg enable;


//    reg [7:0] param_array [34];
//    reg [5:0] cmd_selector;
//    reg [24:0] wait_time;

//    // assign buffer_pixel_write = color;
  


//    initial begin
//       clk_counter_tx <= 0;

//       current_byte_pos <= 7;
//       // current_pixel = 0;
//       x = 0;
//       y = 0;
//       counter_send_interval <= 0;

//       oled_clk <= 1;
//       oled_mosi <= 0;
//       oled_dc <= 0;
//       oled_cs <= 1;

// ;
//       // buffer_pixel_write = 16'hffff;

//       is_init <= 0;
//       next_pixel <= 0;

//       buffer_free <= 1;
//       // pixel_write_free = 0;

//       advertise_pixel_consume = 0;
//       advertise_pixel_consume_buffer = 0;
//       pixel_display = 0;

//       delay_counter = 0;
//       enable <= 0;

//       state = SEND_CMD;

//       reset = 0;
//       oled_dc = 0;
//       oled_cs = 1;

//       // pixel_write = 16'hffff;
//       wr_en = 1;

//       param_array[0] = 8'h01; //software reset CMD_SWRESET = 8'h01; //software reset
//       param_array[1] = 8'h11; //sleep out CMD_SLPOUT = 8'h11; //sleep out
//       param_array[2] = 8'hb4; //display inversion control CMD_INVCTR = 8'hb4; //display inversion control
//       param_array[3] = 8'h07; //normal mode CMD_PARAM_INVCTR = 8'h07; //normal mode 
//       param_array[4] = 8'hC0; // CMD_PWCTR1 = 8'hC0;
//       param_array[5] = 8'hA2;//8'h82; CMD_PARAM1_PWCTR1 = 8'hA2;//8'h82;
//       param_array[6] = 8'h02;// CMD_PARAM2_PWCTR1 = 8'h02;
//       param_array[7] = 8'h84;// CMD_PARAM3_PWCTR1 = 8'h84;
//       param_array[8] = 8'hC3; //CMD_PWCTR4 = 8'hC3;
//       param_array[9] = 8'h8A; // CMD_PARAM1_PWCTR4 = 8'h8A;
//       param_array[10] = 8'h2A;// CMD_PARAM2_PWCTR4 = 8'h2A;//8'h2E;
//       param_array[11] = 8'hC4;// CMD_PWCTR5 = 8'hC4;
//       param_array[12] = 8'h8A;// CMD_PARAM1_PWCTR5 = 8'h8A;
//       param_array[13] = 8'hEE;// CMD_PARAM2_PWCTR5 = 8'hEE;//8'hAA;
//       param_array[14] = 8'hC5;// CMD_VMCTR1 = 8'hC5;
//       param_array[15] = 8'h0E; // CMD_PARAM_VMCTR1 = 8'h0E; 
//       param_array[16] = 8'h21;// CMD_INVON = 8'h21;
//       param_array[17] = 8'h36;// CMD_MAoled_dcTL = 8'h36;
//       param_array[18] = 8'hC8;// CMD_PARAM_MAoled_dcTL = 8'hC8;
//       param_array[19] = 8'h3A;// CMD_COLMOD = 8'h3A;
//       param_array[20] = 8'h05;// CMD_PARAM_COLMOD = 8'h05;

//       // // x  Top left corner x cooroled_mosiate
//       // // y  Top left corner x cooroled_mosiate
//       // // w  Width of window
//       // // h  Height of window

//       param_array[21]  = 8'h2A;// CMD_CASET = 8'h2A;
//       // //start and end of column position to draw on the screen
//       // //the drawable area is starting at 0 // Rmcd2green160x80 from Adafruit library
//       param_array[22] = 8'h00;// CMD_PARAM1_CASET = 8'h00;
//       param_array[23] = 8'h1A;// CMD_PARAM2_CASET = 8'h1A;
//       param_array[24] = 8'h00;// CMD_PARAM3_CASET = 8'h00;
//       param_array[25] = 8'h6A;// CMD_PARAM4_CASET = 8'h6A;
//       // //start and end of row position to draw on the screen
//       // //the drawable area is starting at 0
//       param_array[26] = 8'h2B;// CMD_RASET =  8'h2B;
//       param_array[27] = 8'h00;// CMD_PARAM1_RASET = 8'h00;
//       param_array[28] = 8'h01;// CMD_PARAM2_RASET = 8'h01;//01;
//       param_array[29] = 8'h00;// CMD_PARAM3_RASET = 8'h00;
//       param_array[30]  = 8'hA1;// CMD_PARAM4_RASET = 8'hA1;

//       param_array[31] = 8'h13;// CMD_NORON = 8'h13;

//       param_array[32] = 8'h29;// CMD_DISPON = 8'h29;

//       param_array[33]  = 8'h2C;// CMD_RAMWR = 8'h2C;

//       cmd_selector = 0;
//       wait_time = 0;
//    end



//    always @(posedge clk)
//    begin

//       if(delay_counter < 24'h780000) begin //screen in reset mode
//          delay_counter <= delay_counter + 1;
         
//          if(delay_counter == 24'h400000) begin
//             reset <= 1;
//          end
//       end else begin
//          enable <= 1;
//       end

//       if(enable == 1) begin
//          clk_counter_tx <= clk_counter_tx+1;
//       end

//       //generate clock for the spi
//       if(clk_counter_tx == HALF__PERIOD) begin
//          clk_counter_tx <= 0;
//          oled_clk <= ~oled_clk;
//       end

      
//       // if (is_init) buffer_pixel_write <= color;
//       // else buffer_pixel_write <= 16'hffff;

      
      

//       //read pixel, will be consumed by the SPI state machine
//       if(wr_en == 1) begin
//          buffer_free <= 0;
//       end

//       // get info that the spi has read the buffer (synchronised)
//       advertise_pixel_consume_buffer <= advertise_pixel_consume;

//       if(advertise_pixel_consume_buffer != advertise_pixel_consume) begin
//          buffer_free <= 1;
//       end

//    end

//    always @(negedge oled_clk)
//    begin
//       oled_dc <= 0; //set mosi as "command"
//       oled_cs <= 1;

//       current_byte_pos <= current_byte_pos-1;

//       case (state) //send the config data, then the screen data
//       SEND_CMD : begin
//          oled_mosi <= param_array[cmd_selector][current_byte_pos];
//          oled_cs <= 0;
//          if(current_byte_pos == 0) begin
//             current_byte_pos <= 7;
//             counter_send_interval <= 0;

//             if(cmd_selector == 0) begin
//                state <= CMD_WAIT;
//                wait_time <= (FREQ_TARGET_SPI_HZ/12);
//                oled_dc <= 0;
//                current_byte_pos <= 7;
//             end
//             else if(cmd_selector == 1) begin
//                state <= CMD_WAIT;
//                wait_time <= (FREQ_TARGET_SPI_HZ/4);
//                oled_dc <= 0;
//                current_byte_pos <= 7;
//             end
//             else if(    cmd_selector == 3  || cmd_selector == 5  || cmd_selector == 6  || cmd_selector == 7  || cmd_selector == 9
//                      || cmd_selector == 10 || cmd_selector == 12 || cmd_selector == 13 || cmd_selector == 15 || cmd_selector == 18
//                      || cmd_selector == 20 || cmd_selector == 22 || cmd_selector == 23 || cmd_selector == 24 || cmd_selector == 25
//                      || cmd_selector == 27 || cmd_selector == 28 || cmd_selector == 29 ) begin
//                wait_time <= 0;
//                current_byte_pos <= 7;
//                cmd_selector <= cmd_selector + 1;
//                // state <= SEND_CMD;
//                oled_dc <= 1; //params are seen as data
//             end
//             else if( cmd_selector == 30 ) begin
//                wait_time <= 0;
//                current_byte_pos <= 7;
//                if(is_init) begin
//                   cmd_selector <= 35;
//                end
//                else begin
//                   cmd_selector <= cmd_selector + 1;
//                end
//                // state <= SEND_CMD;
//                oled_dc <= 1; //params are seen as data
//             end
//             else if(cmd_selector == 31) begin
//                state <= CMD_WAIT;
//                wait_time <= (FREQ_TARGET_SPI_HZ/200);
//                oled_dc <= 0;
//                current_byte_pos <= 7;
//             end
//             else if(cmd_selector == 33) begin
//                state <= CMD_WAIT;
//                wait_time <= (FREQ_TARGET_SPI_HZ/20);
//                oled_dc <= 0;
//                current_byte_pos <= 7;
//             end
//             else if(cmd_selector == 35 ) begin //STATE_SEND_RAMWR
//                if (is_init) begin
//                   state <= STATE_WAITING_PIXEL;
//                end
//                else begin
//                   state <= STATE_FRAME;
//                   is_init <= 0;
//                   pixel_display <= 0;
//                end
//                current_byte_pos <= 15;
//                counter_send_interval <= 0;
//                oled_dc <= 0;
//             end
//             else begin
//                cmd_selector <= cmd_selector + 1;
//                current_byte_pos <= 7;
//                counter_send_interval <= 0;
//                oled_dc <= 0;
//             end
//             // case (cmd_selector)
//             //    0: begin
//             //       state <= CMD_WAIT;
//             //       wait_time <= (FREQ_TARGET_SPI_HZ/12);
//             //       oled_dc <= 0;
//             //       current_byte_pos <= 7;
//             //    end
//             //    1: begin
//             //       state <= CMD_WAIT;
//             //       wait_time <= (FREQ_TARGET_SPI_HZ/4);
//             //       oled_dc <= 0;
//             //       current_byte_pos <= 7;
//             //    end
//             //    3, 5, 6, 7, 9
//             //    , 10 , 12 , 13 , 15 , 18
//             //    , 20 , 22 , 23 , 24 , 25
//             //    , 27 , 28 , 29 : begin
//             //       wait_time <= 0;
//             //       current_byte_pos <= 7;
//             //       cmd_selector <= cmd_selector + 1;
//             //       // state <= SEND_CMD;
//             //       oled_dc <= 1; //params are seen as data
//             //    end
//             //    30: begin
//             //       wait_time <= 0;
//             //       current_byte_pos <= 7;
//             //       if(is_init) begin
//             //          cmd_selector <= 35;
//             //       end
//             //       else begin
//             //          cmd_selector <= cmd_selector + 1;
//             //       end
//             //       // state <= SEND_CMD;
//             //       oled_dc <= 1; //params are seen as data
//             //    end
//             //    31: begin
//             //       state <= CMD_WAIT;
//             //       wait_time <= (FREQ_TARGET_SPI_HZ/200);
//             //       oled_dc <= 0;
//             //       current_byte_pos <= 7;
//             //    end
//             //    33: begin
//             //       state <= CMD_WAIT;
//             //       wait_time <= (FREQ_TARGET_SPI_HZ/20);
//             //       oled_dc <= 0;
//             //       current_byte_pos <= 7;
//             //    end
//             //    35: begin //STATE_SEND_RAMWR
//             //       if (is_init) begin
//             //          state <= STATE_WAITING_PIXEL;
//             //       end
//             //       else begin
//             //          state <= STATE_FRAME;
//             //          is_init <= 0;
//             //          pixel_display <= 0;
//             //       end
//             //       current_byte_pos <= 15;
//             //       counter_send_interval <= 0;
//             //       oled_dc <= 0;
//             //    end
//             //    default: begin
//             //       cmd_selector <= cmd_selector + 1;
//             //       current_byte_pos <= 7;
//             //       counter_send_interval <= 0;
//             //       oled_dc <= 0;
//             //    end

//             // endcase
//          end
//       end
//       CMD_WAIT : begin
//          counter_send_interval <= counter_send_interval + 1;
//          if(counter_send_interval == wait_time) begin //wait
//                current_byte_pos <= 7;
//                state <= SEND_CMD;
//                cmd_selector <= cmd_selector + 1;
//          end
//       end

//       STATE_WAITING_PIXEL: begin
//          oled_cs <= 1;
//          next_pixel <= 1;
//          if(buffer_free == 0) begin
//             state <= STATE_FRAME;   
//             //consume next pixel and advertise the register system
//             pixel_display <= color;
//             advertise_pixel_consume <= ~advertise_pixel_consume;
//             current_byte_pos <= 15;
//          end
//       end
//       STATE_FRAME: begin
//          oled_cs <= 0;
//          next_pixel <= 0;
//          if(current_byte_pos == 0) begin
//             current_byte_pos <= 15;
//             if (x<SCREEN_WIDTH-1) begin
//                if(y == (SCREEN_HEIGHT-1)) begin
//                   y = 0;
//                   x = x + 1;
//                end else begin
//                   y = y + 1;
//                end               
//             end

//             if(x == (SCREEN_WIDTH-1)) begin //image finished
//                x = 0;
//                y = 0;
//                // current_pixel <= 0;
//                // state <= STATE_SEND_RAMWR; //send a new frame
//                state <= SEND_CMD;
//                if (is_init) begin
//                   cmd_selector <= 35;
//                end
//                else begin
//                   cmd_selector <= 23;
//                   is_init <= 1; //finish the init sequence, advertise to the upper modules  
//                end
               
//             end
//             else begin
//                state <= STATE_WAITING_PIXEL;
//             end
            
//          end
//          oled_dc <= 1; //set mosi as "data"
//          oled_mosi <= pixel_display[current_byte_pos];
//       end

//       endcase
//    end
// endmodule

