
module LEARN_PRJ
(	
	input sys_clk,
	input sys_rst_n,
	//led
	output wire [3:0] ledreg,
	//uart
	input UART_RX_PIN,
	output UART_TX_PIN,
	

	output TEST_PIN_T3,
	output TEST_PIN_T4,
	output TEST_PIN_T5,
	output TEST_PIN_P3

);
//parameter define
parameter  CLK_FREQ = 100000000;   
parameter  UART_BPS = 115200;    

// main wire or reg for function module
wire locked;
wire rst_n;
wire CLK_100M/*synthesis keep*/;
wire CLK_1M/*synthesis keep*/;
wire UART_SR;
wire [7:0] UART_RX_LockData;

wire RX_Rise;
wire TC/*synthesis keep*/;
reg [31:0] CLK_10MS_Cnt;
reg [7:0] SendBuff;

// Test reg or wire
reg RDEN;
wire LockTDR;
reg CLK_RDEN;
wire [3:0]ReadCOuter;
wire TXReq/*synthesis keep*/;

wire [1:0] CLK_DIV_4/*synthesis keep*/;
//reg TXReq;

reg TESTRDEN;
reg [1:0]TESTRFENStatus;

//main function deal
assign rst_n = sys_rst_n & locked;

//debug deal
assign TEST_PIN_T3 = UART_RX_PIN;

assign TEST_PIN_P3 = UART_SR;

assign TEST_PIN_T5 = CLK_1M;

assign TXReq = {~TESTRFENStatus[0],TESTRFENStatus[1]};

assign CLK_DIV_4 = CLK_DIV_4 + CLK_100M;


//assign SendBuff = (TESTRDEN?UART_RX_LockData:SendBuff);
always @ (negedge rst_n or posedge TXReq) begin
	if(!rst_n)
		SendBuff <= 8'd0;
	else
		SendBuff <= UART_RX_LockData;
end

always @ (negedge rst_n or posedge CLK_100M) begin
	if(!rst_n)
		TESTRFENStatus <= 2'b0;
	else
		TESTRFENStatus <= {TESTRFENStatus[0],TESTRDEN};
end

//main module 

PLL_CLK USER_PLL_CLK_MODEL1
(
		.areset	(~sys_rst_n),
		.inclk0	(sys_clk),
		.c0		(CLK_100M),
		.c1		(CLK_1M),
		.locked	(locked)
);

LED USER_LED_MODEL
(
    .CLK_1US		(CLK_1M),
    .SYS_RST		(rst_n),

    .LEDReg			(ledreg)
);


UART_TOP UART_1_MODEL
(
	.RST_N	(rst_n),
	.CLK		(CLK_100M),
	
	.RX_PIN	(UART_RX_PIN),
	.TX_PIN	(UART_TX_PIN),
	
	.RDEN		(TESTRDEN),				//异步 读取使能一个上升沿更新一次RDR 这个信号的频率必须低于输入的CLK 不然会导致模块异常
	.TC		(TC),					//缓存的都发送完成了
	.RX_SR	(UART_SR),			//高电平代表有数据没读完,
	
	.lockTDR	(TXReq),			//上升沿锁存TDR
	.TDR		(SendBuff),
	.RDCouter (ReadCOuter),
	.RDR		(UART_RX_LockData)
);

// module top's deal

always @ (negedge rst_n or posedge CLK_1M) begin
	if(!rst_n)
		CLK_10MS_Cnt <= 32'd0;
	else
		CLK_10MS_Cnt <= CLK_10MS_Cnt+1'b1;
end

always @ (negedge rst_n or posedge CLK_10MS_Cnt[8]) begin
	if(!rst_n) begin
		CLK_RDEN <= 1'b0;
		RDEN <= 1'b0;
		end
	else if(UART_SR) begin
		RDEN <= UART_SR;
	end
	else begin
		RDEN <= 1'b0;
		end
end

always @ (negedge rst_n or posedge sys_clk) begin
	if(!rst_n) begin
		TESTRDEN <= 1'b0;
		end
	else if(RDEN && (ReadCOuter > 0)) begin
		TESTRDEN <= TESTRDEN + 1'b1;
		end
	else 
		TESTRDEN <= 1'b0;

end


endmodule
