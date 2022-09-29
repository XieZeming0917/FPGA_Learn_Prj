module UART_TOP
(
	input RST_N,
	input CLK,
	input RX_PIN,
	output TX_PIN,
	
	input RDEN,		//读取使能一个上升沿更新一次RDR 这个信号的频率必须低于输入的CLK 不然会导致模块异常
	output TC,		//缓存的都发送完成了
	output RX_SR,		//只要缓存没有读取完全 这个RX_SR就一直是高电平
	input lockTDR,			//上升沿锁存TDR
	
	input wire [7:0] TDR,
	output wire [3:0] RDCouter,
	output wire [7:0] RDR
);

//parameter define
parameter  CLK_FREQ = 100000000;                //系统时钟频率
parameter  UART_BPS = 115200;                   //串口波特率
localparam  BPS_CNT  = CLK_FREQ/UART_BPS;      	//为得到指定波特率，


// Rx module's wire or reg

wire ReadReq;

wire GetRD;
wire RDNE;						//接收寄存器非空
wire [7:0]LockRDData/*synthesis keep*/;				//
//reg [7:0] ReadRAMData;
reg [3:0] ReadHead;			// "1111" 16个
reg [3:0] ReadTail;
reg [1:0] RDENStauts;
reg [1:0] RDNEStatus;

// TX module's wire or reg
wire TXE/*synthesis keep*/;
wire SendReq;					//发送动作信号
wire GetTDR;					//接收到TDR更新信号
wire [7:0] SendLockData;	//传递给TX模块的值

reg [3:0] SendHead;			// "1111" 16个
reg [3:0] SendTail;
reg [1:0] LockTDRStatus;

wire StartSend;
reg [1:0]SendReqStatus;


//Test wire or reg
wire GETTXE;
reg [1:0] TXEStatus;
//******************************************************************
// RX module top deal
//******************************************************************

assign RX_SR = ((ReadTail != ReadHead)?(1):(0) );
assign RDCouter = ((ReadHead - ReadTail) >= 0)? (ReadHead - ReadTail) : (16 + ReadHead - ReadTail);
//获取 请求更新RDR信息
assign ReadReq = RDENStauts[0] & (~RDENStauts[1]);

assign GetRD = RDNEStatus[0] & (~RDNEStatus[1]);

always @ (negedge RST_N or negedge RDEN) begin
	if(!RST_N)
		ReadTail <= 4'd0;
	else
		ReadTail <= ReadTail + 1'b1;
end


always @ (negedge RST_N or negedge RDNE) begin
	if(!RST_N)
		ReadHead <= 4'd0;
	else
		ReadHead <= ReadHead +1'b1;
end

//******************************************************************
//TX module top deal
//*******************************************************************
assign TC = (~SendReq);

//用于TX module 是否需要发送
assign SendReq = (TXE & ((SendTail != SendHead)?1:0));

assign StartSend = SendReqStatus[0] & (~SendReqStatus[1]);

//获取TDR锁存信息
assign GetTDR = LockTDRStatus[0] & (~LockTDRStatus[1]);

//获取TXE上升沿信号
assign GetTXE = (~TXEStatus[0]) & (TXEStatus[1]);

always @ (negedge RST_N or posedge CLK) begin
	if(!RST_N)	begin
		LockTDRStatus <= 2'd0;
		TXEStatus <= 2'd0;
		SendReqStatus <=2'd0;
		end
	else begin
		LockTDRStatus[1:0] <= {LockTDRStatus[0],lockTDR};
		TXEStatus[1:0] <= {TXEStatus[0],TXE};
		SendReqStatus[1:0] <= {SendReqStatus[0],SendReq};
		end
end

//TX 头指针
always @ (negedge RST_N or negedge lockTDR) begin
	if(!RST_N)begin
		SendHead <= 4'd0;
		end
	else
		SendHead <= SendHead + 1'b1;
end



always @ (negedge RST_N or negedge SendReq) begin
	if(!RST_N)begin
		SendTail <= 4'd0;
		end
	else
		SendTail <= SendTail +1'b1;
end


//***************************************************************
//以下是接收的部分 20220922 ZemingXie
//
//
//****************************************************************
DOUBLE_RAM_16byte RX_RAM(
	.clock(CLK),
	.data(LockRDData),
	.rdaddress(ReadTail),
	.wraddress(ReadHead),
	.wren(RDNE),
	.rden(RDEN),
	.q(RDR));

UART_RX#(
	.CLK_FREQ (CLK_FREQ),
	.UART_BPS (UART_BPS))
	
USER_UART_RX 
(
    .RST_N	(RST_N),
    .CLK	(CLK),                
    .PIN_UART_RX	(RX_PIN),
    .RXFLAG (RDNE),   	// 输出数据就绪标志  这个信号会持续一个bit的波特率宽度,是脉冲信号
    .RDR	(LockRDData)				//
);

//***************************************************************
//以下是发送的部分 20220922 ZemingXie
//经过测试使用IP和做缓存比自己定义reg 序列和定义时序更能节省资源
//这里做缓存其实是想实现类似于ARM的DMA的功能 
//例如当我组织完一帧16byte的报文的时候 那么我就通过16个lockTDR信号将数据移位
//到RAM缓存之后就不需要在管发送时序的问题了,只需要监听 TC信号
//就可以知道这一帧的数据是否完成发送 从而形成闭环
//****************************************************************
// 容量为 16 byte的 IP_Ram 缓存 更大的缓存需要修改IP设置

//发送缓存数据
DOUBLE_RAM_16byte TX_RAM(
	.clock(CLK),
	.data(TDR),
	.rdaddress(SendTail),
	.wraddress(SendHead),
	.wren(GetTDR),
	.rden(SendReq),
	.q(SendLockData));

UART_TX#(
	.CLK_FREQ (CLK_FREQ),
	.UART_BPS (UART_BPS) )
	
UART_TX
(
	.RST_N (RST_N),			//复位信号
	.CLK	(CLK),				//输入时钟 模块默认100M
	.ACT (StartSend),			//启动发送信号
	.TDR (SendLockData),		//输入发送的数据
	.FLAG_TXE (TXE),			//发送完成标志
	.UART_TX_PIN (TX_PIN)
);

endmodule