module UART_TX
(
	input RST_N,			//复位信号
	input CLK,				//输入时钟 模块默认100M
	
	input ACT,				//启动发送信号
	
	input wire [7:0] TDR,		//输入发送的数据
	output reg FLAG_TXE,			//发送完成标志
	output reg UART_TX_PIN
	
);
//#define 常量定义
parameter  CLK_FREQ = 100000000;                //系统时钟频率
parameter  UART_BPS = 115200;                   //串口波特率
localparam  BPS_CNT  = CLK_FREQ/UART_BPS;      	//为得到指定波特率

//参数定义
reg [1:0] ACT_Status;
reg [7:0] SENDData;
reg [3:0] TXCnt;
reg [15:0] CLKCnt;
reg Sending; 



//模块

//记录ACT的边沿变化 通过ACT的上升沿启动TX
always @(negedge RST_N or posedge CLK) begin
	if(!RST_N)
		ACT_Status <= 2'd0;
	else
		ACT_Status <= {ACT_Status[0],ACT};
end

always @(negedge RST_N or posedge CLK) begin
	if(!RST_N)begin
		SENDData <= 8'd0;
		Sending <= 1'b0;
		FLAG_TXE <= 1'b1;
		end
	else if(ACT_Status == 2'b01) begin	//上升沿
		SENDData <= TDR;
		Sending <= 1'b1;
		FLAG_TXE <= 1'b0;
		end
	//else if((TXCnt == 4'd9) && (CLKCnt == (BPS_CNT/2)))begin
	else if((TXCnt == 4'd10))begin
		SENDData <= 8'd0;
		Sending <= 1'b0;
		FLAG_TXE <= 1'b1;
		end
	else begin
		SENDData <= SENDData;
		Sending <= Sending;
		FLAG_TXE <= FLAG_TXE;
		end
end

always @(negedge RST_N or posedge CLK) begin
	if(!RST_N) begin
		CLKCnt <= 16'd0;
		TXCnt <= 4'd0;
		end
		
	else if(Sending) begin	//正在发送
		if(CLKCnt < BPS_CNT)
			CLKCnt <= CLKCnt + 1'b1;
			
		else begin
			CLKCnt <= 16'd0;
			TXCnt <= TXCnt + 1'b1;
			end
			
	end
	
	else begin
		CLKCnt <= 16'd0;
		TXCnt <= 4'd0;

		end

end

always @(negedge RST_N or posedge CLK) begin
	if(!RST_N)
		UART_TX_PIN <= 1'b1;
		
	else if(Sending) begin
		if(CLKCnt == 1) begin
			case(TXCnt)
			4'd0: UART_TX_PIN <= 1'b0;
			4'd1: UART_TX_PIN <= SENDData[0];
			4'd2: UART_TX_PIN <= SENDData[1];
			4'd3: UART_TX_PIN <= SENDData[2];
			4'd4: UART_TX_PIN <= SENDData[3];
			4'd5: UART_TX_PIN <= SENDData[4];
			4'd6: UART_TX_PIN <= SENDData[5];
			4'd7: UART_TX_PIN <= SENDData[6];
			4'd8: UART_TX_PIN <= SENDData[7];
			4'd9: UART_TX_PIN <= 1'b1;
			default: UART_TX_PIN <= 1'b1;
			endcase
		end
		else
			UART_TX_PIN <= UART_TX_PIN;
	end
	else
		UART_TX_PIN <= 1'b1;
	
	
end 

endmodule