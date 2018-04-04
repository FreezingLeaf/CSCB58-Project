module final_project
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
        SW,
		LEDR,
		HEX0, HEX3, HEX1, HEX2, HEX4, HEX5, HEX6, HEX7,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);

	input	CLOCK_50;				//	50 MHz
	input   [17:0]  SW;
	input   [3:0]   KEY;
	output  [17:0]  LEDR;
	output  [6:0]   HEX0, HEX3, HEX1, HEX2, HEX4, HEX5, HEX6, HEX7;

	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	wire resetn;
	assign resetn = KEY[0];
	assign writeEn = SW[17];

	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(1'b1),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.
	wire ld_1, ld_2, ld_3, ld_4, ld_5, ld_6, ld_7, ld_8, ld_9;
	wire [8:0] vga_result;
    
    // Instansiate datapath
	 datapath d0(
		.clk(CLOCK_50), 
        	.reset(resetn),
        	.vga_result(vga_result),
        	.x(x), 
        	.y(y), 
        	.colour(colour)
        	);
        	
    positon_converter(
        .a(small_cheese),
        .b(medium_cheese),
        .c(large_cheese),
        .res(vga_result)
        );
        
    
    // main game modules
    wire [3:0] small_cheese, medium_cheese, large_cheese;
	wire [15:0] res;
	wire new_clk;
	wire step_limit_reached, time_limit_reached;
	wire [7:0] time_left;
	wire [7:0] step_used;
	
	assign LEDR[3:1] = res[6:4];
	assign LEDR[6:4] = res[10:8];
	assign LEDR[9:7] = res[14:12];
	
	rate_divider(
		.clk(CLOCK_50),
		.reset(resetn),
		.new_clk(new_clk)
		);
		
	step_counter(
		.go(~KEY[3]),
		.clk(new_clk),
		.reset(resetn),
		.step(step_used),
		.f(step_limit_reached)
		);
	
	time_counter(
		.new_clk(new_clk),
		.reset(KEY[0]),
		.time_left(time_left),
		.f(time_limit_reached)
		);
	
	display dis(
		.a(small_cheese),
		.b(medium_cheese),
		.c(large_cheese),
		.f1(step_limit_reached),
		.f2(time_limit_reached),
		.res(res)
		);
	
	// FSM for the game
	control ctrl(
		.go(~KEY[3]),
		.res(SW[1:0]),
		.tar(SW[3:2]),
		.resetn(KEY[0]),
		.clk(CLOCK_50),
		.a(small_cheese),
		.b(medium_cheese),
		.c(large_cheese)
		);

    // HEXs displays for game states
	hex_display0 hex0(
		.IN(res[3:0]),
		.OUT(HEX0[6:0])
		);

	hex_display1 hex1(
		.IN(res[7:4]),
		.OUT(HEX1[6:0])
		);
	
	hex_display2 hex2(
		.IN(res[11:8]),
		.OUT(HEX2[6:0])
		);
	
	hex_display3 hex3(
		.IN(res[15:12]),
		.OUT(HEX3[6:0])
		);
	
	// HEXs for time countdown
	hex_displayd hex4(
		.IN(time_left[3:0]),
		.OUT(HEX4[6:0])
		);
	
	hex_displayd hex5(
		.IN(time_left[7:4]),
		.OUT(HEX5[6:0])
		);
	
	// HEXs for step counter
	hex_displayd hex6(
		.IN(step_used[3:0]),
		.OUT(HEX6[6:0])
		);
	
	hex_displayd hex7(
		.IN(step_used[7:4]),
		.OUT(HEX7[6:0])
		);
	
endmodule

// convert the positions of cheeses into a 9-bit position code.
module positon_converter(
	input [3:0] a, b, c,
	output reg [8:0] res
	);
	
	always@(*)
	begin
		if(a==4'd1&&b==4'd2&&c==4'd3)
			res = 9'b000000111;
		else if(a==4'd1&&b==4'd2&&c==4'd6)
			res = 9'b000100011;
		else if(a==4'd1&&b==4'd2&&c==4'd9)
			res = 9'b100000011;
		else if(a==4'd1&&b==4'd5&&c==4'd3)
			res = 9'b000010101;
		else if(a==4'd1&&b==4'd5&&c==4'd6)
			res = 9'b00110001;
		else if(a==4'd1&&b==4'd5&&c==4'd9)
			res = 9'b100010001;
		else if(a==4'd1&&b==4'd8&&c==4'd3)
			res = 9'b010000101;
		else if(a==4'd1&&b==4'd8&&c==4'd6)
			res = 9'b010100001;
		else if(a==4'd1&&b==4'd8&&c==4'd9)
			res = 9'b110000001;
		else if(a==4'd4&&b==4'd2&&c==4'd3)
			res = 9'b000001110;
		else if(a==4'd4&&b==4'd2&&c==4'd6)
			res = 9'b000101010;
		else if(a==4'd4&&b==4'd2&&c==4'd9)
			res = 9'b100001010;
		else if(a==4'd4&&b==4'd5&&c==4'd3)
			res = 9'b000011100;
		else if(a==4'd4&&b==4'd5&&c==4'd6)
			res = 9'b000111000;
		else if(a==4'd4&&b==4'd5&&c==4'd9)
			res = 9'b100011000;
		else if(a==4'd4&&b==4'd8&&c==4'd3)
			res = 9'b010001100;
		else if(a==4'd4&&b==4'd8&&c==4'd6)
			res = 9'b010101000;
		else if(a==4'd4&&b==4'd8&&c==4'd9)
			res = 9'b110001000;
		else if(a==4'd7&&b==4'd2&&c==4'd3)
			res = 9'b001000110;
		else if(a==4'd7&&b==4'd2&&c==4'd6)
			res = 9'b001100010;
		else if(a==4'd7&&b==4'd2&&c==4'd9)
			res = 9'b101000010;
		else if(a==4'd7&&b==4'd5&&c==4'd3)
			res = 9'b001010100;
		else if(a==4'd7&&b==4'd5&&c==4'd6)
			res = 9'b00111000;
		else if(a==4'd7&&b==4'd5&&c==4'd9)
			res = 9'b100110000;
		else if(a==4'd7&&b==4'd8&&c==4'd3)
			res = 9'b011000100;
		else if(a==4'd7&&b==4'd8&&c==4'd6)
			res = 9'b011100000;
		else if(a==4'd7&&b==4'd8&&c==4'd9)
			res = 9'b1110000000;
	end
	
endmodule

// provide outputs for VGA display modules.
module datapath(
	input clk,
    input reset,
    //input ld_1, ld_2, ld_3, ld_4, ld_5, ld_6, ld_7, ld_8, ld_9,
    input [8:0] vga_result,
    output reg [7:0] x,
    output reg [6:0] y,
    output reg [2:0] colour
    );
	 
	reg [7:0] counter;
    
	always@(posedge clk) begin
       if(!reset)
            counter <= 0;
        else if(counter >= 8'd46)
            counter <= 0;
        else 
            counter <= counter + 1;
    end
    
    always@(*) begin
        if((counter >= 8'd1) & (counter <= 8'd3)) begin
			//if(ld_1 == 1) begin
				if(vga_result[8] == 1) begin
                x <= 8'd40;
                y <= 7'd90;
                colour <= 3'b100;
            end
			else begin
				x <= 8'd40;
                y <= 7'd90;
                colour <= 3'b000;
			end
        end
        else if((counter >= 8'd4) & (counter <= 8'd6))  begin
			//if(ld_2 == 1) begin
			if(vga_result[7] == 1) begin
                x <= 8'd40;
                y <= 7'd60;
                colour <= 3'b010;
			end
			else begin
				x <= 8'd40;
                y <= 7'd60;
                colour <= 3'b000;
			end
        end
        else if((counter >= 8'd7) & (counter <= 8'd9)) begin
			//if(ld_3 == 1) begin
			if(vga_result[6] == 1) begin
                x <= 8'd40;
                y <= 7'd30;
                colour <= 3'b001;
			end
			else begin
				x <= 8'd40;
                y <= 7'd30;
                colour <= 3'b000;
			end
        end
        else if((counter >= 8'd10) & (counter <= 8'd14)) begin
			//if(ld_4 == 1) begin
			if(vga_result[5] == 1) begin
                x <= 8'd80;
                y <= 7'd90;
                colour <= 3'b100;
			end
			else begin
				x <= 8'd80;
                y <= 7'd90;
                colour <= 3'b000;
			end
        end
        else if((counter >= 8'd15) & (counter <= 8'd19)) begin
			//if(ld_5 == 1) begin
			if(vga_result[4] == 1) begin
                x <= 8'd80;
                y <= 7'd60;
                colour <= 3'b010;
			end
			else begin
				x <= 8'd80;
                y <= 7'd60;
                colour <= 3'b000;
			end
        end
        else if((counter >= 8'd20) & (counter <= 8'd24)) begin
		  	//if(ld_6 == 1) begin
		  	if(vga_result[3] == 1) begin
                x <= 8'd80;
                y <= 7'd30;
                colour <= 3'b001;
			end
			else begin
				x <= 8'd80;
                y <= 7'd30;
                colour <= 3'b000;
			end
        end
        else if((counter >= 8'd25) & (counter <= 8'd31)) begin
            //if(ld_7 == 1) begin
            if(vga_result[2] == 1) begin
				x <= 8'd120;
                y <= 7'd90;
                colour <= 3'b100;
			end
			else begin
				x <= 8'd120;
                y <= 7'd90;
                colour <= 3'b000;
			end
        end
        else if((counter >= 8'd32) & (counter <= 8'd38)) begin
			//if(ld_8 == 1) begin
			if(vga_result[1] == 1) begin
                x <= 8'd120;
                y <= 7'd60;
                colour <= 3'b010;
			end
			else begin
				x <= 8'd120;
                y <= 7'd60;
                colour <= 3'b000;
			end
        end
        else if((counter >= 8'd39) & (counter <= 8'd45)) begin
            //if(ld_9 == 1) begin
            if(vga_result[0] == 1) begin
                x <= 8'd120;
                y <= 7'd30;
                colour <= 3'b001;
			end
			else begin
				x <= 8'd120;
                y <= 7'd30;
                colour <= 3'b000;
			end
        end
    end
    
endmodule

// a counter for time count down.
module time_counter(
	input new_clk,
	input reset,
	output reg [7:0] time_left,
	output reg f
	);

	always@(posedge new_clk) begin
		f = 1'b0;
		if(!reset)
			time_left <= 8'd60;
		else if(time_left != 8'd0)
			time_left <= time_left - 1;
		else if(time_left == 8'd0)
			f = 1'b1;
	end

endmodule

// a counter that counts the steps.
module step_counter(
	input go,
	input clk,
	input reset,
	output reg [7:0] step,
	output reg f
	);
	
	always@(posedge clk && go) begin
		f = 1'b0;
		if(!reset)
			step <= 8'd0;
		else if(step != 8'd10)
			step <= step + 1;
		else if(step == 8'd10)
			f = 1'b1;
	end
	
endmodule

// convert CLOCK_50 to a 1 sec clock.
module rate_divider(
	input clk,
	input reset,
	output new_clk
	);

	reg [31:0] count = 32'd0;

	always@(posedge clk) begin
		if(!reset)
			count <= 1'b0;
		else if(count >= 32'd50000000)
			count <= 1'b0;
		else
			count <= count + 1;
	end

	assign new_clk = (count == 32'd0) ? 1 : 0;
endmodule

module display(
	input [3:0] a, b, c,
	input f1, f2,
	output reg [15:0] res
	);
	
	always@(*)
	begin
		if(f1 == 1'b1 || f2 == 1'b1)
			res = 16'b1111111111111111;
		else if(a==4'd1&&b==4'd2&&c==4'd3)
			res = 16'b0000000001110000;
		else if(a==4'd1&&b==4'd2&&c==4'd6)
			res = 16'b0000010000110000;
		else if(a==4'd1&&b==4'd2&&c==4'd9)
			res = 16'b0100000000110000;
		else if(a==4'd1&&b==4'd5&&c==4'd3)
			res = 16'b0000001001010000;
		else if(a==4'd1&&b==4'd5&&c==4'd6)
			res = 16'b0000011000010000;
		else if(a==4'd1&&b==4'd5&&c==4'd9)
			res = 16'b0100001000010000;
		else if(a==4'd1&&b==4'd8&&c==4'd3)
			res = 16'b0010000001010000;
		else if(a==4'd1&&b==4'd8&&c==4'd6)
			res = 16'b0010010000010000;
		else if(a==4'd1&&b==4'd8&&c==4'd9)
			res = 16'b0110000000010000;
		else if(a==4'd4&&b==4'd2&&c==4'd3)
			res = 16'b0000000101100000;
		else if(a==4'd4&&b==4'd2&&c==4'd6)
			res = 16'b0000010100100000;
		else if(a==4'd4&&b==4'd2&&c==4'd9)
			res = 16'b0100000100100000;
		else if(a==4'd4&&b==4'd5&&c==4'd3)
			res = 16'b0000001101000000;
		else if(a==4'd4&&b==4'd5&&c==4'd6)
			res = 16'b0000011100000000;
		else if(a==4'd4&&b==4'd5&&c==4'd9)
			res = 16'b0100001100000000;
		else if(a==4'd4&&b==4'd8&&c==4'd3)
			res = 16'b0010000101000000;
		else if(a==4'd4&&b==4'd8&&c==4'd6)
			res = 16'b0010010100000000;
		else if(a==4'd4&&b==4'd8&&c==4'd9)
			res = 16'b0110000100000000;
		else if(a==4'd7&&b==4'd2&&c==4'd3)
			res = 16'b0001000001100000;
		else if(a==4'd7&&b==4'd2&&c==4'd6)
			res = 16'b0001010000100000;
		else if(a==4'd7&&b==4'd2&&c==4'd9)
			res = 16'b0101000000100000;
		else if(a==4'd7&&b==4'd5&&c==4'd3)
			res = 16'b0001001001000000;
		else if(a==4'd7&&b==4'd5&&c==4'd6)
			res = 16'b0001011000000000;
		else if(a==4'd7&&b==4'd5&&c==4'd9)
			res = 16'b0100011000000000;
		else if(a==4'd7&&b==4'd8&&c==4'd3)
			res = 16'b0011000001000000;
		else if(a==4'd7&&b==4'd8&&c==4'd6)
			res = 16'b0011010000000000;
		else if(a==4'd7&&b==4'd8&&c==4'd9)
			res = 16'b0111000000000000;
	end
endmodule

// FSM  for the game.
module control(
	input go,
	input [1:0] res,
	input [1:0] tar,
	input clk,
	input resetn,
	output reg [3:0] a, b, c
	);
	
	reg [5:0] curr, next;
	
	always@(*)
	begin: state_table
		case(curr)
			6'd1: next = go ? 6'd33 : 6'd1;
			6'd2: next = 6'd2;
			6'd3: next = 6'd3;
			6'd4: next = go ? 6'd36 : 6'd4;
			6'd5: next = go ? 6'd37 : 6'd5;
			6'd6: next = go ? 6'd38 : 6'd6;
			6'd7: next = go ? 6'd39 : 6'd7;
			6'd8: next = go ? 6'd40 : 6'd8;
			6'd9: next = go ? 6'd41 : 6'd9;
			6'd10: next = go ? 6'd42 : 6'd10;
			6'd11: next = go ? 6'd43 : 6'd11;
			6'd12: next = go ? 6'd44 : 6'd12;
			6'd13: next = go ? 6'd45 : 6'd13;
			6'd14: next = go ? 6'd46 : 6'd14;
			6'd15: next = go ? 6'd47 : 6'd15;
			6'd16: next = go ? 6'd48 : 6'd16;
			6'd17: next = go ? 6'd49 : 6'd17;
			6'd18: next = go ? 6'd50 : 6'd18;
			6'd19: next = go ? 6'd51 : 6'd19;
			6'd20: next = go ? 6'd52 : 6'd20;
			6'd21: next = go ? 6'd53 : 6'd21;
			6'd22: next = go ? 6'd54 : 6'd22;
			6'd23: next = go ? 6'd55 : 6'd23;
			6'd24: next = go ? 6'd56 : 6'd24;
			6'd25: next = go ? 6'd57 : 6'd25;
			6'd26: next = go ? 6'd58 : 6'd26;
			6'd27: next = go ? 6'd59 : 6'd27;
			6'd33: begin
				if(!go) begin
					if(res == 2'b01 && tar == 2'b10) begin
						next = 6'd4;
					end
					else if(res == 2'b01 && tar == 2'b11) begin
						next = 6'd5;
					end
					else begin
						next = 6'd33;
					end
				end
				else begin
					next = 6'd33;
				end
			end
			6'd36: begin
				if(!go) begin
					if(res == 2'b10 && tar == 2'b01) begin
						next = 6'd1;
					end
					else if(res == 2'b10 && tar == 2'b11) begin
						next = 6'd5;
					end
					else if(res == 2'b01 && tar == 2'b11) begin
						next = 6'd27;
					end
					else begin
						next = 6'd36;
					end
				end
				else begin
					next = 6'd36;
				end
			end
			6'd37: begin
				if(!go) begin
					if(res == 2'b11 && tar == 2'b01) begin
						next = 6'd1;
					end
					else if(res == 2'b11 && tar == 2'b10) begin
						next = 6'd4;
					end
					else if(res == 2'b01 && tar == 2'b10) begin
						next = 6'd26;
					end
					else begin
						next = 6'd37;
					end
				end
				else begin
					next = 6'd37;
				end
			end
			6'd38: begin
				if(!go) begin
					if(res == 2'b10 && tar == 2'b11) begin
						next = 6'd7;
					end
					else if(res == 2'b01 && tar == 2'b10) begin
						next = 6'd18;
					end
					else if(res == 2'b01 && tar == 2'b11) begin
						next = 6'd26;
					end
					else begin
						next = 6'd38;
					end
				end
				else begin
					next = 6'd38;
				end
			end
			6'd39: begin
				if(!go) begin
					if(res == 2'b11 && tar == 2'b10) begin
						next = 6'd6;
					end
					else if(res == 2'b01 && tar == 2'b11) begin
						next = 6'd20;
					end
					else if(res == 2'b01 && tar == 2'b10) begin
						next = 6'd27;
					end
					else begin
						next = 6'd39;
					end
				end
				else begin
					next = 6'd39;
				end
			end
			6'd40: begin
				if(!go) begin
					if(res == 2'b01 && tar == 2'b10) begin
						next = 6'd2;
					end
					else if(res == 2'b01 && tar == 2'b11) begin
						next = 6'd9;
					end
					else if(res == 2'b10 && tar == 2'b11) begin
						next = 6'd23;
					end
					else begin
						next = 6'd40;
					end
				end
				else begin
					next = 6'd40;
				end
			end
			6'd41: begin
				if(!go) begin
					if(res == 2'b11 && tar == 2'b10) begin
						next = 6'd2;
					end
					else if(res == 2'b11 && tar == 2'b01) begin
						next = 6'd8;
					end
					else if(res == 2'b10 && tar == 2'b01) begin
						next = 6'd25;
					end
					else begin
						next = 6'd41;
					end
				end
				else begin
					next = 6'd41;
				end
			end
			6'd42: begin
				if(!go) begin
					if(res == 2'b01 && tar == 2'b11) begin
						next = 6'd11;
					end
					else if(res == 2'b10 && tar == 2'b01) begin
						next = 6'd16;
					end
					else if(res == 2'b10 && tar == 2'b11) begin
						next = 6'd25;
					end
					else begin
						next = 6'd42;
					end
				end
				else begin
					next = 6'd42;
				end
			end
			6'd43: begin
				if(!go) begin
					if(res == 2'b11 && tar == 2'b01) begin
						next = 6'd10;
					end
					else if(res == 2'b10 && tar == 2'b11) begin
						next = 6'd21;
					end
					else if(res == 2'b10 && tar == 2'b01) begin
						next = 6'd23;
					end
					else begin
						next = 6'd43;
					end
				end
				else begin
					next = 6'd43;
				end
			end
			6'd44: begin
				if(!go) begin
					if(res == 2'b01 && tar == 2'b11) begin
						next = 6'd3;
					end
					else if(res == 2'b01 && tar == 2'b10) begin
						next = 6'd13;
					end
					else if(res == 2'b11 && tar == 2'b10) begin
						next = 6'd22;
					end
					else begin
						next = 6'd44;
					end
				end
				else begin
					next = 6'd44;
				end
			end
			6'd45: begin
				if(!go) begin
					if(res == 2'b10 && tar == 2'b11) begin
						next = 6'd3;
					end
					else if(res == 2'b10 && tar == 2'b01) begin
						next = 6'd12;
					end
					else if(res == 2'b11 && tar == 2'b01) begin
						next = 6'd24;
					end
					else begin
						next = 6'd45;
					end
				end
				else begin
					next = 6'd45;
				end
			end
			6'd46: begin
				if(!go) begin
					if(res == 2'b01 && tar == 2'b10) begin
						next = 6'd15;
					end
					else if(res == 2'b11 && tar == 2'b01) begin
						next = 6'd17;
					end
					else if(res == 2'b11 && tar == 2'b10) begin
						next = 6'd24;
					end
					else begin
						next = 6'd46;
					end
				end
				else begin
					next = 6'd46;
				end
			end
			6'd47: begin
				if(!go) begin
					if(res == 2'b10 && tar == 2'b01) begin
						next = 6'd14;
					end
					else if(res == 2'b11 && tar == 2'b10) begin
						next = 6'd19;
					end
					else if(res == 2'b11 && tar == 2'b01) begin
						next = 6'd22;
					end
					else begin
						next = 6'd47;
					end
				end
				else begin
					next = 6'd47;
				end
			end
			6'd48: begin
				if(!go) begin
					if(res == 2'b01 && tar == 2'b10) begin
						next = 6'd10;
					end
					else if(res == 2'b10 && tar == 2'b11) begin
						next = 6'd17;
					end
					else if(res == 2'b01 && tar == 2'b11) begin
						next = 6'd25;
					end
					else begin
						next = 6'd48;
					end
				end
				else begin
					next = 6'd48;
				end
			end
			6'd49: begin
				if(!go) begin
					if(res == 2'b01 && tar == 2'b11) begin
						next = 6'd14;
					end
					else if(res == 2'b11 && tar == 2'b10) begin
						next = 6'd16;
					end
					else if(res == 2'b01 && tar == 2'b10) begin
						next = 6'd24;
					end
					else begin
						next = 6'd49;
					end
				end
				else begin
					next = 6'd49;
				end
			end
			6'd50: begin
				if(!go) begin
					if(res == 2'b01 && tar == 2'b10) begin
						next = 6'd6;
					end
					else if(res == 2'b01 && tar == 2'b11) begin
						next = 6'd19;
					end
					else if(res == 2'b10 && tar == 2'b11) begin
						next = 6'd26;
					end
					else begin
						next = 6'd50;
					end
				end
				else begin
					next = 6'd50;
				end
			end
			6'd51: begin
				if(!go) begin
					if(res == 2'b10 && tar == 2'b11) begin
						next = 6'd15;
					end
					else if(res == 2'b11 && tar == 2'b01) begin
						next = 6'd18;
					end
					else if(res == 2'b10 && tar == 2'b01) begin
						next = 6'd22;
					end
					else begin
						next = 6'd51;
					end
				end
				else begin
					next = 6'd51;
				end
			end
			6'd52: begin
				if(!go) begin
					if(res == 2'b11 && tar == 2'b01) begin
						next = 6'd7;
					end
					else if(res == 2'b01 && tar == 2'b10) begin
						next = 6'd21;
					end
					else if(res == 2'b11 && tar == 2'b10) begin
						next = 6'd27;
					end
					else begin
						next = 6'd52;
					end
				end
				else begin
					next = 6'd52;
				end
			end
			6'd53: begin
				if(!go) begin
					if(res == 2'b11 && tar == 2'b10) begin
						next = 6'd11;
					end
					else if(res == 2'b10 && tar == 2'b01) begin
						next = 6'd20;
					end
					else if(res == 2'b11 && tar == 2'b01) begin
						next = 6'd23;
					end
					else begin
						next = 6'd53;
					end
				end
				else begin
					next = 6'd53;
				end
			end
			6'd54: begin
				if(!go) begin
					if(res == 2'b10 && tar == 2'b11) begin
						next = 6'd12;
					end
					else if(res == 2'b01 && tar == 2'b11) begin
						next = 6'd15;
					end
					else if(res == 2'b01 && tar == 2'b10) begin
						next = 6'd19;
					end
					else begin
						next = 6'd54;
					end
				end
				else begin
					next = 6'd54;
				end
			end
			6'd55: begin
				if(!go) begin
					if(res == 2'b11 && tar == 2'b10) begin
						next = 6'd8;
					end
					else if(res == 2'b01 && tar == 2'b10) begin
						next = 6'd11;
					end
					else if(res == 2'b01 && tar == 2'b11) begin
						next = 6'd21;
					end
					else begin
						next = 6'd55;
					end
				end
				else begin
					next = 6'd55;
				end
			end
			6'd56: begin
				if(!go) begin
					if(res == 2'b01 && tar == 2'b11) begin
						next = 6'd13;
					end
					else if(res == 2'b10 && tar == 2'b11) begin
						next = 6'd14;
					end
					else if(res == 2'b10 && tar == 2'b01) begin
						next = 6'd17;
					end
					else begin
						next = 6'd56;
					end
				end
				else begin
					next = 6'd56;
				end
			end
			6'd57: begin
				if(!go) begin
					if(res == 2'b01 && tar == 2'b10) begin
						next = 6'd9;
					end
					else if(res == 2'b11 && tar == 2'b10) begin
						next = 6'd10;
					end
					else if(res == 2'b11 && tar == 2'b01) begin
						next = 6'd16;
					end
					else begin
						next = 6'd57;
					end
				end
				else begin
					next = 6'd57;
				end
			end
			6'd58: begin
				if(!go) begin
					if(res == 2'b10 && tar == 2'b01) begin
						next = 6'd5;
					end
					else if(res == 2'b11 && tar == 2'b01) begin
						next = 6'd6;
					end
					else if(res == 2'b11 && tar == 2'b10) begin
						next = 6'd18;
					end
					else begin
						next = 6'd58;
					end
				end
				else begin
					next = 6'd58;
				end
			end
			6'd59: begin
				if(!go) begin
					if(res == 2'b11 && tar == 2'b01) begin
						next = 6'd4;
					end
					else if(res == 2'b10 && tar == 2'b01) begin
						next = 6'd7;
					end
					else if(res == 2'b10 && tar == 2'b11) begin
						next = 6'd20;
					end
					else begin
						next = 6'd59;
					end
				end
				else begin
					next = 6'd59;
				end
			end
			default: next = 6'd1;
		endcase
	end
	
	always@(*)
	begin: enable_signals
		case(curr)
			6'd1:begin
				a = 4'd1;
				b = 4'd2;
				c = 4'd3;
			end
			6'd2:begin
				a = 4'd4;
				b = 4'd5;
				c = 4'd6;
			end
			6'd3:begin
				a = 4'd7;
				b = 4'd8;
				c = 4'd9;
			end
			6'd4:begin
				a = 4'd4;
				b = 4'd2;
				c = 4'd3;
			end
			6'd5:begin
				a = 4'd7;
				b = 4'd2;
				c = 4'd3;
			end
			6'd6:begin
				a = 4'd1;
				b = 4'd5;
				c = 4'd3;
			end
			6'd7:begin
				a = 4'd1;
				b = 4'd8;
				c = 4'd3;
			end
			6'd8:begin
				a = 4'd1;
				b = 4'd5;
				c = 4'd6;
			end
			6'd9:begin
				a = 4'd7;
				b = 4'd5;
				c = 4'd6;
			end
			6'd10:begin
				a = 4'd4;
				b = 4'd2;
				c = 4'd6;
			end
			6'd11:begin
				a = 4'd4;
				b = 4'd8;
				c = 4'd6;
			end
			6'd12:begin
				a = 4'd1;
				b = 4'd8;
				c = 4'd9;
			end
			6'd13:begin
				a = 4'd4;
				b = 4'd8;
				c = 4'd9;
			end
			6'd14:begin
				a = 4'd7;
				b = 4'd2;
				c = 4'd9;
			end
			6'd15:begin
				a = 4'd7;
				b = 4'd5;
				c = 4'd9;
			end
			6'd16:begin
				a = 4'd1;
				b = 4'd2;
				c = 4'd6;
			end
			6'd17:begin
				a = 4'd1;
				b = 4'd2;
				c = 4'd9;
			end
			6'd18:begin
				a = 4'd4;
				b = 4'd5;
				c = 4'd3;
			end
			6'd19:begin
				a = 4'd4;
				b = 4'd5;
				c = 4'd9;
			end
			6'd20:begin
				a = 4'd7;
				b = 4'd8;
				c = 4'd3;
			end
			6'd21:begin
				a = 4'd7;
				b = 4'd8;
				c = 4'd6;
			end
			6'd22:begin
				a = 4'd1;
				b = 4'd5;
				c = 4'd9;
			end
			6'd23:begin
				a = 4'd1;
				b = 4'd8;
				c = 4'd6;
			end
			6'd24:begin
				a = 4'd4;
				b = 4'd2;
				c = 4'd9;
			end
			6'd25:begin
				a = 4'd7;
				b = 4'd2;
				c = 4'd6;
			end
			6'd26:begin
				a = 4'd7;
				b = 4'd5;
				c = 4'd3;
			end
			6'd27:begin
				a = 4'd4;
				b = 4'd8;
				c = 4'd3;
			end
		endcase
	end
	
	always@(posedge clk)
	begin: state_FFs
		if(!resetn)
			curr <= 6'd1;
		else
			curr <= next;
	end
endmodule

module hex_display0(IN, OUT);
	input [3:0] IN;
	output reg [6:0] OUT;
	 
	 always @(*)
	 begin
		case(IN[3:0])
			4'b0000: OUT = 7'b1111111;
			4'b1111: OUT = 7'b1000111;		
		endcase
	end
endmodule

module hex_display1(IN, OUT);
	input [3:0] IN;
	output reg [6:0] OUT;
	 
	 always @(*)
	 begin
		case(IN[3:0])
			4'b0000: OUT = 7'b1111111;
			4'b0001: OUT = 7'b1111110;
			4'b0010: OUT = 7'b0111111;
			4'b0011: OUT = 7'b0111110;
			4'b0100: OUT = 7'b1110111;
			4'b0101: OUT = 7'b1110110;
			4'b0110: OUT = 7'b0110111;
			4'b0111: OUT = 7'b0110110;
			4'b1111: OUT = 7'b1111001;		
		endcase
	end
endmodule

module hex_display2(IN, OUT);
	input [3:0] IN;
	output reg [6:0] OUT;
	 
	 always @(*)
	 begin
		case(IN[3:0])
			4'b0000: OUT = 7'b1111111;
			4'b0001: OUT = 7'b1111110;
			4'b0010: OUT = 7'b0111111;
			4'b0011: OUT = 7'b0111110;
			4'b0100: OUT = 7'b1110111;
			4'b0101: OUT = 7'b1110110;
			4'b0110: OUT = 7'b0110111;
			4'b0111: OUT = 7'b0110110;
			4'b1111: OUT = 7'b0001000;
		endcase
	end
endmodule

module hex_display3(IN, OUT);
	input [3:0] IN;
	output reg [6:0] OUT;
	 
	 always @(*)
	 begin
		case(IN[3:0])
			4'b0000: OUT = 7'b1111111;
			4'b0001: OUT = 7'b1111110;
			4'b0010: OUT = 7'b0111111;
			4'b0011: OUT = 7'b0111110;
			4'b0100: OUT = 7'b1110111;
			4'b0101: OUT = 7'b1110110;
			4'b0110: OUT = 7'b0110111;
			4'b0111: OUT = 7'b0110110;
			4'b1111: OUT = 7'b0001110;		
		endcase
	end
endmodule


module hex_displayd(IN, OUT);
	input [3:0] IN;
	output reg [6:0] OUT;
	 
	 always @(*)
	 begin
		case(IN[3:0])
			4'b0000: OUT = 7'b1000000;
			4'b0001: OUT = 7'b1111001;
			4'b0010: OUT = 7'b0100100;
			4'b0011: OUT = 7'b0110000;
			4'b0100: OUT = 7'b0011001;
			4'b0101: OUT = 7'b0010010;
			4'b0110: OUT = 7'b0000010;
			4'b0111: OUT = 7'b1111000;
			4'b1000: OUT = 7'b0000000;
			4'b1001: OUT = 7'b0011000;
			4'b1010: OUT = 7'b0001000;
			4'b1011: OUT = 7'b0000011;
			4'b1100: OUT = 7'b1000110;
			4'b1101: OUT = 7'b0100001;
			4'b1110: OUT = 7'b0000110;
			4'b1111: OUT = 7'b0001110;
			
			default: OUT = 7'b0111111;
		endcase
	end
endmodule


