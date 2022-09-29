
module UART_RX
(
    input RST_N,
    input CLK,                
    input PIN_UART_RX,
	 
    inout reg RXFLAG,          // 输出数据就绪标志
    output reg [7:0] RDR		//
);

//parameter define
parameter  CLK_FREQ = 100000000;                //系统时钟频率
parameter  UART_BPS = 115200;                   //串口波特率
localparam  BPS_CNT  = CLK_FREQ/UART_BPS;      	//为得到指定波特率，

//参数定义
reg [1:0] RXStatus; //用来捕获起始位

wire StartFlag;
reg Receiving;
reg StopBit;

reg [3:0] RXCnt;      //接收了多少bit 
reg [15:0] CLK_Cnt;   //当前实际计数个数
reg [7:0] RX_DATA;		// /*synthesis noprune*/
// test
reg BPSCLK/*synthesis noprune*/;

assign StartFlag = RXStatus[1] & (~RXStatus[0]);

//监听RX是否出现下降沿
always @(negedge RST_N or posedge CLK)
begin
    if(!RST_N)
        RXStatus <= 2'b00;
    else
        RXStatus[1:0] <= {RXStatus[0],PIN_UART_RX};
end

always @ (negedge RST_N or posedge CLK)
begin
    if(!RST_N)
        Receiving <= 0;
    else   
    begin 
        if(StartFlag) 						//捕获到起始位
            Receiving <= 1'b1;			//启动接收程序
        else if( (RXCnt == 4'd9) && (CLK_Cnt == BPS_CNT/2) ) //停止位结束
            Receiving <= 1'b0;
        else
            Receiving <= Receiving;
    end
end

//波特率CLK计数器
always @ (negedge RST_N or posedge CLK) begin
	if(!RST_N)
		CLK_Cnt <= 16'd0;
	else if(Receiving)
		if(CLK_Cnt < BPS_CNT)	//小于波特率需要的个数
			CLK_Cnt <= CLK_Cnt +1'b1;
		else
			CLK_Cnt <= 16'd0;
	else 
		CLK_Cnt <= 16'd0;
end

//接收位数计数
always @ (negedge RST_N or posedge CLK) begin
	if(!RST_N)
		RXCnt <=4'd0;
	else if(Receiving)
		if(CLK_Cnt == BPS_CNT)
			RXCnt <= RXCnt+1'b1;
		else 
			RXCnt <= RXCnt;
	else
		RXCnt <=4'd0;
end
//获取数据到缓冲寄存器中
always @ (negedge RST_N or posedge CLK) begin
	if(!RST_N)
		RX_DATA <= 8'd0;
	else if(Receiving)
		if(CLK_Cnt == BPS_CNT/2)
			case(RXCnt)
			4'd0: ;
			4'd1:	RX_DATA[0] <= RXStatus[0];
			4'd2:	RX_DATA[1] <= RXStatus[0];
			4'd3:	RX_DATA[2] <= RXStatus[0];	
			4'd4:	RX_DATA[3] <= RXStatus[0];
			4'd5:	RX_DATA[4] <= RXStatus[0];
			4'd6:	RX_DATA[5] <= RXStatus[0];
			4'd7:	RX_DATA[6] <= RXStatus[0];
			4'd8:	RX_DATA[7] <= RXStatus[0];
			4'd9:	;//停止位		
			default: ;
			endcase
		else
			RX_DATA <= RX_DATA;
	else
		RX_DATA <= 8'd0;
end

always @ (negedge RST_N or posedge CLK) begin
	if(!RST_N) begin
		RDR <= 8'd0;
		RXFLAG <= 1'b0;
		end
	else if(Receiving ) begin	//接收中
		if(RXCnt == 4'd9) begin
			if(CLK_Cnt < BPS_CNT/8) begin
				RDR <= RX_DATA;
				RXFLAG <= 1'b0;
				end
			else begin
				RDR <= RDR;
				RXFLAG <= 1'b1;
				end
			end
		else begin
			RDR <= RDR;
			RXFLAG <= RXFLAG;
			end
		end
	else begin
		RDR <= RDR;
		RXFLAG <= 1'b0;;
		end
end	

endmodule

