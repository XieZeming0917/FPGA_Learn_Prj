module LED
(
    input CLK_1US,	//输入1us的时钟
    input SYS_RST,
    //input reg [3:0] ContorlReg,  
    output reg [3:0] LEDReg
);

reg [24:0] cnt;
reg  [1:0]  led_control;

always @ (posedge CLK_1US or negedge SYS_RST) 
begin
    if(!SYS_RST) //SYS_RST == 0
        begin
            cnt <= 24'd199999;
            led_control <= 0;
        end
    else if(cnt<24'd200000)
        cnt<= cnt+1'b1;
    else
        begin
            cnt <= 0;
            led_control <= led_control+1'b1;
        end
end

always @ (SYS_RST or led_control)
begin
    if(!SYS_RST) //SYS_RST == 0
        LEDReg <= 4'b0000;
    else
        case (led_control)
        2'b00 : LEDReg <= 4'b0001;
        2'b01 : LEDReg <= 4'b1000;
        2'b10 : LEDReg <= 4'b0100;
        2'b11 : LEDReg <= 4'b0010;
        default: LEDReg <= 4'b0000;
		  endcase
end

endmodule




