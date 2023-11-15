module top(
	input                       clk,
	input                       rst_n,
	output                       cmos_scl,          //cmos i2c clock
	inout                       cmos_sda,          //cmos i2c data
	input                       cmos_vsync,        //cmos vsync
	input                       cmos_href,         //cmos hsync refrence,data valid
	input                       cmos_pclk,         //cmos pxiel clock
    output                      cmos_xclk,         //cmos externl clock 
	input   [7:0]               cmos_db,           //cmos data
    //------------
	input                        uart_rx,
    input                        w,
    input                        z,
	output                       uart_tx,
    output        reg               jdq,
    output        reg               fmq111,
    //---------------
    output                      cmos_rst_n,        //cmos reset 
	output                      cmos_pwdn,         //cmos power down

	output [3:0] 				state_led,

	output [14-1:0]             ddr_addr,       //ROW_WIDTH=14
	output [3-1:0]              ddr_bank,       //BANK_WIDTH=3
	output                      ddr_cs,
	output                      ddr_ras,
	output                      ddr_cas,
	output                      ddr_we,
	output                      ddr_ck,
	output                      ddr_ck_n,
	output                      ddr_cke,
	output                      ddr_odt,
	output                      ddr_reset_n,
	output [2-1:0]              ddr_dm,         //DM_WIDTH=2
	inout [16-1:0]              ddr_dq,         //DQ_WIDTH=16
	inout [2-1:0]               ddr_dqs,        //DQS_WIDTH=2
	inout [2-1:0]               ddr_dqs_n,      //DQS_WIDTH=2

	output                      lcd_dclk,	
	output                      lcd_hs,            //lcd horizontal synchronization
	output                      lcd_vs,            //lcd vertical synchronization        
	output                      lcd_de,            //lcd data enable     
	output[3:0]                 lcd_r,             //lcd red
	output[4:0]                 lcd_g,             //lcd green
	output[4:0]                 lcd_b	           //lcd blue
);

//memory interface
wire                   memory_clk         ;
wire                   dma_clk         	  ;
wire                   pll_lock           ;
wire                   cmd_ready          ;
wire[2:0]              cmd                ;
wire                   cmd_en             ;
wire[5:0]              app_burst_number   ;
wire[ADDR_WIDTH-1:0]   addr               ;
wire                   wr_data_rdy        ;
wire                   wr_data_en         ;//
wire                   wr_data_end        ;//
wire[DATA_WIDTH-1:0]   wr_data            ;   
wire[DATA_WIDTH/8-1:0] wr_data_mask       ;   
wire                   rd_data_valid      ;  
wire                   rd_data_end        ;//unused 
wire[DATA_WIDTH-1:0]   rd_data            ;   
wire                   init_calib_complete;

//According to IP parameters to choose
`define	    WR_VIDEO_WIDTH_16
`define	DEF_WR_VIDEO_WIDTH 16

`define	    RD_VIDEO_WIDTH_16
`define	DEF_RD_VIDEO_WIDTH 16

`define	USE_THREE_FRAME_BUFFER

`define	DEF_ADDR_WIDTH 28 
`define	DEF_SRAM_DATA_WIDTH 128
//
//=========================================================
//SRAM parameters
parameter ADDR_WIDTH          = `DEF_ADDR_WIDTH;    //存储单元是byte，总容量=2^27*16bit = 2Gbit,增加1位rank地址，{rank[0],bank[2:0],row[13:0],cloumn[9:0]}
parameter DATA_WIDTH          = `DEF_SRAM_DATA_WIDTH;   //与生成DDR3IP有关，此ddr3 2Gbit, x16， 时钟比例1:4 ，则固定128bit
parameter WR_VIDEO_WIDTH      = `DEF_WR_VIDEO_WIDTH;  
parameter RD_VIDEO_WIDTH      = `DEF_RD_VIDEO_WIDTH;  

wire                            video_clk;         //video pixel clock
//-------------------
//syn_code
wire                      syn_off0_re;  // ofifo read enable signal
wire                      syn_off0_vs;
wire                      syn_off0_hs;
                          
wire                      off0_syn_de  ;
wire [RD_VIDEO_WIDTH-1:0] off0_syn_data;

wire[15:0]                      cmos_16bit_data;
wire                            cmos_16bit_clk;
wire[15:0] 						write_data;

wire[9:0]                       lut_index;
wire[31:0]                      lut_data;

assign cmos_xclk = cmos_clk;
assign cmos_pwdn = 1'b0;
assign cmos_rst_n = 1'b1;
assign write_data = {cmos_16bit_data[4:0],cmos_16bit_data[10:5],cmos_16bit_data[15:11]};

//状态指示灯
// assign state_led[3] = 
// assign state_led[2] = 
assign state_led[1] = rst_n; //复位指示灯
assign state_led[0] = init_calib_complete; //DDR3初始化指示灯

//generate the CMOS sensor clock and the SDRAM controller clock
sys_pll sys_pll_m0(
	.clkin                     (cmos_clk                  ),
	.clkout                    (video_clk 	              )
	);
cmos_pll cmos_pll_m0(
	.clkin                     (clk                      		),
	.clkout                    (cmos_clk 	              		)
	);

mem_pll mem_pll_m0(
	.clkin                     (cmos_clk                        ),
	.clkout                    (memory_clk 	              		),
	.lock 					   (pll_lock 						)
	);

//串口------------------------------------------
uart_rx#
(
	.CLK_FRE(CLK_FRE),
	.BAUD_RATE(UART_FRE)
) uart_rx_inst
(
	.clk                        (clk                      ),
	.rst_n                      (rst_n                    ),
	.rx_data                    (rx_data                  ),
	.rx_data_valid              (rx_data_valid            ),
	.rx_data_ready              (rx_data_ready            ),
	.rx_pin                     (uart_rx                  )
);

uart_tx#
(
	.CLK_FRE(CLK_FRE),
	.BAUD_RATE(UART_FRE)
) uart_tx_inst
(
	.clk                        (clk                      ),
	.rst_n                      (rst_n                    ),
	.tx_data                    (tx_data                  ),
	.tx_data_valid              (tx_data_valid            ),
	.tx_data_ready              (tx_data_ready            ),
	.tx_pin                     (uart_tx                  )
);
wire xyanwu;
wire xcdian;
//reg xjdian=1;
parameter                        CLK_FRE  = 27;//Mhz
parameter                        UART_FRE = 115200;//Mhz
localparam                       IDLE =  0;
localparam                       SEND =  1;   //send 
localparam                       SEND1 =  2; 
localparam                       WAIT =  3;   //wait 1 second and send uart received data
reg[7:0]                         tx_data;
reg[7:0]                         tx_str;
reg                              tx_data_valid;
wire                             tx_data_ready;
reg[7:0]                         tx_cnt;
wire[7:0]                        rx_data;
wire                             rx_data_valid;
wire                             rx_data_ready;
reg[31:0]                        wait_cnt;
reg[3:0]                         state;

assign rx_data_ready = 1'b1;//always can receive data,
reg [4:0]  num=5'd26;

always@(posedge clk or negedge rst_n)
begin
	if(rst_n == 1'b0)
	begin
		wait_cnt <= 32'd0;
		tx_data <= 8'd0;
		state <= IDLE;
		tx_cnt <= 8'd0;
		tx_data_valid <= 1'b0;
	end
	else
	case(state)
		IDLE:
            if((xyanwu==0)||(xcdian==0))
             begin
//                flag<= 1;
              
             state<=SEND;
             end

		SEND:
		begin
			wait_cnt <= 32'd0;
			tx_data <= tx_str;

			if(tx_data_valid == 1'b1 && tx_data_ready == 1'b1 && (tx_cnt < (num- 1)))//Send 12 bytes data
			begin
				tx_cnt <= tx_cnt + 8'd1; //Send data counter
			end
			else if(tx_data_valid && tx_data_ready)//last byte sent is complete
			begin
				tx_cnt <= 8'd0;
				tx_data_valid <= 1'b0;
//                cxk<=cxk+1;
				state <= WAIT;
			end
			else if(~tx_data_valid)
			begin
				tx_data_valid <= 1'b1;
			end
		end
		WAIT:
		begin
			wait_cnt <= wait_cnt + 32'd1;

			if(rx_data_valid == 1'b1)
			begin
				tx_data_valid <= 1'b1;
				tx_data <= rx_data;   // send uart received data
			end
			else if(tx_data_valid && tx_data_ready)
			begin
				tx_data_valid <= 1'b0;
			end
			else if((wait_cnt >= CLK_FRE * 1000_000))// wait for 1 second
                begin
                state <= IDLE;
//                cxk<=0;
                end
		end
		default:
			state <= IDLE;
	endcase
end

//combinational logic
//parameter 	ENG_NUM  = 11;//非中文字符数
//parameter 	CHE_NUM  = 12;//  中文字符数
//parameter 	DA_NUM = 17; //中文字符使用UTF8，占用3个字节
//parameter 	DATA_NU = 53;
//wire [103:0] phone_num = 104'h22313737323033363433373322;
//wire [(DATA_NUM * 8-1):0] send_data0 = {{"AT+CMGS=", phone_num, " >DANGEROUS"}, 16'h0d0a};

//parameter 	ENG_NUM  = 20;//非中文字符数
//parameter 	CHE_NUM  = 3;//  中文字符数
parameter 	DATA_NUM = 26; //中文字符使用UTF8，占用3个字节

//
//#go back  回正
wire [ DATA_NUM* 8 - 1:0] send_data0 = {"#000P1500T1000!",16'h0d0a};
wire [ DATA_NUM * 8 - 1:0] send_data1 = {"#001P1500T1000!",16'h0d0a};
wire [ DATA_NUM * 8 - 1:0] send_data2 = {"#002P1500T1000!",16'h0d0a};
wire [ DATA_NUM * 8 - 1:0] send_data3 = {"#003P1500T1000!",16'h0d0a};
wire [ DATA_NUM * 8 - 1:0] send_data4 = {"#004P1500T1000!",16'h0d0a};
wire [ DATA_NUM * 8 - 1:0] send_data5 = {"AT+CAVIMS=1",16'h0d0a};
wire [ DATA_NUM * 8 - 1:0] send_data6 = {"AT+CAVIMS=1",16'h0d0a};
wire [ DATA_NUM * 8 - 1:0] send_data7 = {"AT+CSCA?",16'h0d0a};
wire [ DATA_NUM * 8 - 1:0] send_data8 = {"AT+CPMS=SM",16'h0d0a};
wire [ DATA_NUM * 8 - 1:0] send_data9 = {"AT+CNMI=2,1,0,0,0",16'h0d0a};
wire [ DATA_NUM * 8 - 1:0] send_data10 = {"AT+CMGF=0",16'h0d0a};
wire [ DATA_NUM * 8 - 1:0] send_data11 = {"AT+CMGS=29",16'h0d0a};
wire [ DATA_NUM * 8 - 1:0] send_data12 = {"0011640D91685126596468F90008AA0E514575355B8C6210002100210021",16'h0d0a};

wire [ DATA_NUM * 8 - 1:0] send_data13 = {"ATD17720364373;",16'h0d0a};
wire [ DATA_NUM * 8 - 1:0] send_data14 = {"#000P1500T1000!",16'h0d0a};
wire [ DATA_NUM * 8 - 1:0] send_data15 = {"#001P1500T1000!",16'h0d0a};
wire [ DATA_NUM * 8 - 1:0] send_data16 = {"#002P1500T1000!",16'h0d0a};
wire [ DATA_NUM * 8 - 1:0] send_data17 = {"#003P1500T1000!",16'h0d0a};
wire [ DATA_NUM * 8 - 1:0] send_data18 = {"#004P1500T1000!",16'h0d0a};
wire [ DATA_NUM * 8 - 1:0] send_data19 = {"$KMS:0,150,270,1000!",16'h0d0a};
wire [ DATA_NUM * 8 - 1:0] send_data20 = {"#000P0850T1000!",16'h0d0a};
wire [ DATA_NUM * 8 - 1:0] send_data21 = {"#000P1500T1000!",16'h0d0a};
wire [ DATA_NUM * 8 - 1:0] send_data22 = {"#000P2100T1000!",16'h0d0a};
wire [ DATA_NUM * 8 - 1:0] send_data23 = {"#000P1000T1000!",16'h0d0a};
wire [ DATA_NUM * 8 - 1:0] send_data24 = {"#000P1500T1000!",16'h0d0a};
wire [ DATA_NUM * 8 - 1:0] send_data25 = {"#000P2000T1000!",16'h0d0a};
wire [ DATA_NUM * 8 - 1:0] send_data26 = {"#000P0850T1000!",16'h0d0a};
wire [ DATA_NUM * 8 - 1:0] send_data27 = {"#000P1500T1000!",16'h0d0a};
wire [ DATA_NUM * 8 - 1:0] send_data28 = {"#000P2100T1000!",16'h0d0a};
wire [ DATA_NUM * 8 - 1:0] send_data29 = {"#000P0850T1000!",16'h0d0a};
wire [ DATA_NUM * 8 - 1:0] send_data30 = {"#000P1500T1000!",16'h0d0a};
wire [ DATA_NUM * 8 - 1:0] send_data31 = {"#000P2100T1000!",16'h0d0a};
wire [ DATA_NUM * 8 - 1:0] send_data32 = {"#000P0850T1000!",16'h0d0a};
wire [ DATA_NUM * 8 - 1:0] send_data33 = {"#000P1500T1000!",16'h0d0a};
wire [ DATA_NUM * 8 - 1:0] send_data34 = {"#000P2100T1000!",16'h0d0a};


//wire [ DATA_NUM* 8 - 1:0] send_data29 = {"AT+CMGF=0",16'h0d0a};
//ser.write('{#000P1500T1000!}'.encode('utf-8'))
//ser.write('{#001P1500T1000!}'.encode('utf-8'))
//ser.write('{#002P1500T1000!}'.encode('utf-8'))
//ser.write('{#003P1500T1000!}'.encode('utf-8'))
//ser.write('{#004P1500T1000!}'.encode('utf-8'))
//serGHT.write('AT+CAVIMS=1\r\n'.encode('utf-8'))
//serGHT.write('AT+CAVIMS=1\r\n'.encode('utf-8'))
//serGHT.write('AT+CSCA?\r\n'.encode('utf-8'))
//serGHT.write('AT+CPMS="SM"\r\n'.encode('utf-8'))
//serGHT.write('AT+CNMI=2,1,0,0,0\r\n'.encode('utf-8'))
//serGHT.write('AT+CMGF=0\r\n'.encode('utf-8'))
//serGHT.write('AT+CMGS=29\r\n'.encode('utf-8'))
//serGHT.write('0011640D91685126596468F90008AA0E514575355B8C6210002100210021\r\n'.encode('utf-8'))


//#go back  回正
//ser.write('{#000P1500T1000!}'.encode('utf-8'))
//ser.write('{#001P1500T1000!}'.encode('utf-8'))
//ser.write('{#002P1500T1000!}'.encode('utf-8'))
//ser.write('{#003P1500T1000!}'.encode('utf-8'))
//ser.write('{#004P1500T1000!}'.encode('utf-8'))
//########## 火情控制
//电话
//ser.write('$KMS:0,150,270,1000!'.encode('utf-8')
//ser.write('{#000P0850T1000!}'.encode('utf-8'))
//ser.write('{#000P1500T1000!}'.encode('utf-8'))
//ser.write('{#000P2100T1000!}'.encode('utf-8'))
//ser.write('{#000P0850T1000!}'.encode('utf-8'))
//ser.write('{#000P1500T1000!}'.encode('utf-8'))
//ser.write('{#000P2100T1000!}'.encode('utf-8'))
//ser.write('{#000P0850T1000!}'.encode('utf-8'))
//ser.write('{#000P1500T1000!}'.encode('utf-8'))
//ser.write('{#000P2100T1000!}'.encode('utf-8'))
//ser.write('{#000P0850T1000!}'.encode('utf-8'))
//ser.write('{#000P1500T1000!}'.encode('utf-8'))
//ser.write('{#000P2100T1000!}'.encode('utf-8'))

wire [ DATA_NUM * 8 - 1:0] send_data1 = {"#000P0800T1000!",16'h0d0a};


reg yw=0;
reg cd=0;
reg rs=0;
reg rf=0;
reg rfs=0;
always @(posedge clk)
	   yw <= xyanwu;
always @(posedge clk)
	   cd <= xcdian;
always @(posedge clk)
	   begin
//      rs<=key_n&(!kt);    //上升沿检测信号
       rf<=(!xyanwu)&yw;    //下降沿检测信号
       rs<=(!xcdian)&cd; 
       rfs<=xyanwu&(!yw);
	   end

reg [31:0] cnt;
reg [31:0] flag=0;
always@(posedge clk)
begin
    cnt=cnt+1;
    if((cnt==31'd 27000000))
    begin
        flag<=flag+1;
        cnt<=0;
    end
    if(rs)
    begin
        flag<=0;
        cnt<=0;
    end
    if(rf)
    begin
        flag<=13;
        jdq<=1'b0;
        fmq111<=1'b0;
        cnt<=0;
    end
    else if(rfs)
    begin
        jdq<=1'b1;
        fmq111<=1'b1;
    end
    
end

assign xyanwu=w;
assign xcdian=z;
//assign jdq=xjdian;

always@(posedge clk)
begin

  if((flag==0)&&(cd==0))
    tx_str <= send_data0[(DATA_NUM - 1 - tx_cnt) * 8 +: 8];
  if((flag==1)&&(cd==0))
    tx_str <= send_data1[(DATA_NUM - 1 - tx_cnt) * 8 +: 8];
  if((flag==2)&&(cd==0))
    tx_str <= send_data2[(DATA_NUM - 1 - tx_cnt) * 8 +: 8];
  if((flag==3)&&(cd==0))
    tx_str <= send_data3[(DATA_NUM - 1 - tx_cnt) * 8 +: 8];
  if((flag==4)&&(cd==0))
    tx_str <= send_data4[(DATA_NUM - 1 - tx_cnt) * 8 +: 8];
  if((flag==5)&&(cd==0))
    tx_str <= send_data5[(DATA_NUM - 1 - tx_cnt) * 8 +: 8];
  if((flag==6)&&(cd==0))
    tx_str <= send_data6[(DATA_NUM - 1 - tx_cnt) * 8 +: 8];
  if((flag==7)&&(cd==0))
    tx_str <= send_data7[(DATA_NUM - 1 - tx_cnt) * 8 +: 8];
  if((flag==8)&&(cd==0))
    tx_str <= send_data8[(DATA_NUM - 1 - tx_cnt) * 8 +: 8];
  if((flag==9)&&(cd==0))
    tx_str <= send_data9[(DATA_NUM - 1 - tx_cnt) * 8 +: 8];
  if((flag==10)&&(cd==0))
    tx_str <= send_data10[(DATA_NUM - 1 - tx_cnt) * 8 +: 8];
  if((flag==11)&&(cd==0))
    tx_str <= send_data11[(DATA_NUM - 1 - tx_cnt) * 8 +: 8];
  if((flag==12)&&(cd==0))
    tx_str <= send_data12[(DATA_NUM - 1 - tx_cnt) * 8 +: 8];
  if((flag==13)&&(yw==0))
    tx_str <= send_data13[(DATA_NUM - 1 - tx_cnt) * 8 +: 8];
  if((flag==14)&&(yw==0))
    tx_str <= send_data14[(DATA_NUM - 1 - tx_cnt) * 8 +: 8];
  if((flag==15)&&(yw==0))
    tx_str <= send_data15[(DATA_NUM - 1 - tx_cnt) * 8 +: 8];
  if((flag==16)&&(yw==0))
    tx_str <= send_data16[(DATA_NUM - 1 - tx_cnt) * 8 +: 8];
  if((flag==17)&&(yw==0))
    tx_str <= send_data17[(DATA_NUM - 1 - tx_cnt) * 8 +: 8];
  if((flag==18)&&(yw==0))
    tx_str <= send_data18[(DATA_NUM - 1 - tx_cnt) * 8 +: 8];
  if((flag==19)&&(yw==0))
    tx_str <= send_data19[(DATA_NUM - 1 - tx_cnt) * 8 +: 8];
  if((flag==20)&&(yw==0))
    tx_str <= send_data20[(DATA_NUM - 1 - tx_cnt) * 8 +: 8];
  if((flag==21)&&(yw==0))
    tx_str <= send_data21[(DATA_NUM - 1 - tx_cnt) * 8 +: 8];
  if((flag==22)&&(yw==0))
    tx_str <= send_data22[(DATA_NUM - 1 - tx_cnt) * 8 +: 8];
  if((flag==23)&&(yw==0))
    tx_str <= send_data23[(DATA_NUM - 1 - tx_cnt) * 8 +: 8];
  if((flag==24)&&(yw==0))
    tx_str <= send_data24[(DATA_NUM - 1 - tx_cnt) * 8 +: 8];
  if((flag==25)&&(yw==0))
    tx_str <= send_data25[(DATA_NUM - 1 - tx_cnt) * 8 +: 8];
  if((flag==26)&&(yw==0))
    tx_str <= send_data26[(DATA_NUM - 1 - tx_cnt) * 8 +: 8];
  if((flag==27)&&(yw==0))
    tx_str <= send_data27[(DATA_NUM - 1 - tx_cnt) * 8 +: 8];
  if((flag==28)&&(yw==0))
    tx_str <= send_data28[(DATA_NUM - 1 - tx_cnt) * 8 +: 8];
  if((flag==29)&&(yw==0))
    tx_str <= send_data29[(DATA_NUM - 1 - tx_cnt) * 8 +: 8];
  if((flag==30)&&(yw==0))
    tx_str <= send_data30[(DATA_NUM - 1 - tx_cnt) * 8 +: 8];
  if((flag==31)&&(yw==0))
    tx_str <= send_data31[(DATA_NUM - 1 - tx_cnt) * 8 +: 8];
  if((flag==32)&&(yw==0))
    tx_str <= send_data32[(DATA_NUM - 1 - tx_cnt) * 8 +: 8];
  if((flag==33)&&(yw==0))
    tx_str <= send_data33[(DATA_NUM - 1 - tx_cnt) * 8 +: 8];
  if((flag==34)&&(yw==0))
    tx_str <= send_data34[(DATA_NUM - 1 - tx_cnt) * 8 +: 8];
//    
end
//---------------------------------------------------


//IIC 延时约1s复位
reg [23:0] clk_delay = 0;
wire iic_rst = clk_delay != 9_000_000;
always@(posedge video_clk, negedge rst_n)
    if (!rst_n) 
        clk_delay = 0;
    else 
        clk_delay <=( clk_delay == 9_000_000)? clk_delay : clk_delay + 1;

//I2C master controller
iic_ctrl#(
 .CLK_FRE                (27     ),
 .IIC_FRE                (100    ),
 .IIC_SLAVE_REG_EX       (1      ),
 .IIC_SLAVE_ADDR_EX      (0      ),
 .IIC_SLAVE_ADDR         (16'h78 ),
 .INIT_CMD_NUM           (256    )
 ) iic_ctrl_m0(
 .clk                        (clk                      ),
 .rst_n                      (~iic_rst                  ),
 .iic_scl                    (cmos_scl                 ),
 .iic_sda                    (cmos_sda                 )
 );

cmos_8_16bit cmos_8_16bit_m0(
	.rst                        (~rst_n                   ),
	.pclk                       (cmos_pclk                ),
	.pdata_i                    (cmos_db                  ),
	.de_i                       (cmos_href                ),
	.pdata_o                    (cmos_16bit_data          ),
	.hblank                     (cmos_16bit_wr            ),
	.de_o                       (cmos_16bit_clk           )
);

//The video output timing generator and generate a frame read data request
wire out_de;
syn_gen syn_gen_inst
(                                   
    .I_pxl_clk   (video_clk       ),//9Mhz    //32Mhz    //40MHz      //65MHz      //74.25MHz    //148.5
    .I_rst_n     (rst_n           ),//480x272 //800x480  //800x600    //1024x768   //1280x720    //1920x1080    
    .I_h_total   (16'd525         ),//16'd525 //16'd1056 // 16'd1056  // 16'd1344  // 16'd1650   // 16'd2200  
    .I_h_sync    (16'd41          ),//16'd41  //16'd128  // 16'd128   // 16'd136   // 16'd40     // 16'd44   
    .I_h_bporch  (16'd2           ),//16'd2   //16'd88   // 16'd88    // 16'd160   // 16'd220    // 16'd148   
    .I_h_res     (16'd480         ),//16'd480 //16'd800  // 16'd800   // 16'd1024  // 16'd1280   // 16'd1920  
    .I_v_total   (16'd284         ),//16'd284 //16'd505  // 16'd628   // 16'd806   // 16'd750    // 16'd1125   
    .I_v_sync    (16'd10          ),//16'd10  //16'd3    // 16'd4     // 16'd6     // 16'd5      // 16'd5      
    .I_v_bporch  (16'd2           ),//16'd2   //16'd21   // 16'd23    // 16'd29    // 16'd20     // 16'd36      
    .I_v_res     (16'd272         ),//16'd272 //16'd480  // 16'd600   // 16'd768   // 16'd720    // 16'd1080   
    .I_rd_hres   (16'd480         ),
    .I_rd_vres   (16'd272         ),
    .I_hs_pol    (1'b1            ),//HS polarity , 0:负极性，1：正极性
    .I_vs_pol    (1'b1            ),//VS polarity , 0:负极性，1：正极性
    .O_rden      (syn_off0_re     ),
    .O_de        (out_de          ),   
    .O_hs        (syn_off0_hs     ),
    .O_vs        (syn_off0_vs     )
);


Video_Frame_Buffer_Top Video_Frame_Buffer_Top_inst
( 
    .I_rst_n              (init_calib_complete ),//rst_n            ),
    .I_dma_clk            (dma_clk          ),   //sram_clk         ),
`ifdef USE_THREE_FRAME_BUFFER 
    .I_wr_halt            (1'd0             ), //1:halt,  0:no halt
    .I_rd_halt            (1'd0             ), //1:halt,  0:no halt
`endif
    // video data input             
    .I_vin0_clk           (cmos_16bit_clk   ),
    .I_vin0_vs_n          (~cmos_vsync      ),//只接收负极性
    .I_vin0_de            (cmos_16bit_wr    ),
    .I_vin0_data          (write_data       ),
    .O_vin0_fifo_full     (                 ),
    // video data output            
    .I_vout0_clk          (video_clk        ),
    .I_vout0_vs_n         (~syn_off0_vs     ),//只接收负极性
    .I_vout0_de           (syn_off0_re      ),
    .O_vout0_den          (off0_syn_de      ),
    .O_vout0_data         (off0_syn_data    ),
    .O_vout0_fifo_empty   (                 ),
    // ddr write request
    .I_cmd_ready          (cmd_ready          ),
    .O_cmd                (cmd                ),//0:write;  1:read
    .O_cmd_en             (cmd_en             ),
    .O_app_burst_number   (app_burst_number   ),
    .O_addr               (addr               ),//[ADDR_WIDTH-1:0]
    .I_wr_data_rdy        (wr_data_rdy        ),
    .O_wr_data_en         (wr_data_en         ),//
    .O_wr_data_end        (wr_data_end        ),//
    .O_wr_data            (wr_data            ),//[DATA_WIDTH-1:0]
    .O_wr_data_mask       (wr_data_mask       ),
    .I_rd_data_valid      (rd_data_valid      ),
    .I_rd_data_end        (rd_data_end        ),//unused 
    .I_rd_data            (rd_data            ),//[DATA_WIDTH-1:0]
    .I_init_calib_complete(init_calib_complete)
); 

localparam N = 7; //delay N clocks
                          
reg  [N-1:0]  Pout_hs_dn   ;
reg  [N-1:0]  Pout_vs_dn   ;
reg  [N-1:0]  Pout_de_dn   ;

always@(posedge video_clk or negedge rst_n)
begin
    if(!rst_n)
        begin                          
            Pout_hs_dn  <= {N{1'b1}};
            Pout_vs_dn  <= {N{1'b1}}; 
            Pout_de_dn  <= {N{1'b0}}; 
        end
    else 
        begin                          
            Pout_hs_dn  <= {Pout_hs_dn[N-2:0],syn_off0_hs};
            Pout_vs_dn  <= {Pout_vs_dn[N-2:0],syn_off0_vs}; 
            Pout_de_dn  <= {Pout_de_dn[N-2:0],out_de}; 
        end
end

//---------------------------------------------
`ifdef RD_VIDEO_WIDTH_16     
    assign {lcd_r,lcd_g,lcd_b}    = off0_syn_de ? off0_syn_data[15:0] : 16'h0000;//{r,g,b}
    assign lcd_vs      			  = ~Pout_vs_dn[4];//syn_off0_vs;
    assign lcd_hs      			  = ~Pout_hs_dn[4];//syn_off0_hs;
    assign lcd_de      			  = Pout_de_dn[4];//off0_syn_de;
    assign lcd_dclk    			  = video_clk;//video_clk_phs;
`endif

`ifdef RD_VIDEO_WIDTH_24 
    assign {lcd_r,lcd_g,lcd_b}    = off0_syn_de ? off0_syn_data[23:0] : 24'h0000;//{r,g,b}
    assign lcd_vs      			  = ~Pout_vs_dn[4];//syn_off0_vs;
    assign lcd_hs      			  = ~Pout_hs_dn[4];//syn_off0_hs;
    assign lcd_de      			  = Pout_de_dn[4];//off0_syn_de;
    assign lcd_dclk    			  = video_clk;//video_clk_phs;
`endif

`ifdef RD_VIDEO_WIDTH_32 
    assign {lcd_r,lcd_g,lcd_b}    = off0_syn_de ? off0_syn_data[23:0] : 24'h0000;//{r,g,b}
    assign lcd_vs      			  = ~Pout_vs_dn[4];//syn_off0_vs;
    assign lcd_hs      			  = ~Pout_hs_dn[4];//syn_off0_hs;
    assign lcd_de      			  = Pout_de_dn[4];//off0_syn_de;
    assign lcd_dclk    			  = video_clk;//video_clk_phs;
`endif

DDR3MI DDR3_Memory_Interface_Top_inst 
(
    .clk                (video_clk          ),
    .memory_clk         (memory_clk         ),
    .pll_lock           (pll_lock           ),
    .rst_n              (rst_n              ), //rst_n
    .app_burst_number   (app_burst_number   ),
    .cmd_ready          (cmd_ready          ),
    .cmd                (cmd                ),
    .cmd_en             (cmd_en             ),
    .addr               (addr               ),
    .wr_data_rdy        (wr_data_rdy        ),
    .wr_data            (wr_data            ),
    .wr_data_en         (wr_data_en         ),
    .wr_data_end        (wr_data_end        ),
    .wr_data_mask       (wr_data_mask       ),
    .rd_data            (rd_data            ),
    .rd_data_valid      (rd_data_valid      ),
    .rd_data_end        (rd_data_end        ),
    .sr_req             (1'b0               ),
    .ref_req            (1'b0               ),
    .sr_ack             (                   ),
    .ref_ack            (                   ),
    .init_calib_complete(init_calib_complete),
    .clk_out            (dma_clk            ),
    .burst              (1'b1               ),
    // mem interface
    .ddr_rst            (                 ),
    .O_ddr_addr         (ddr_addr         ),
    .O_ddr_ba           (ddr_bank         ),
    .O_ddr_cs_n         (ddr_cs         ),
    .O_ddr_ras_n        (ddr_ras        ),
    .O_ddr_cas_n        (ddr_cas        ),
    .O_ddr_we_n         (ddr_we         ),
    .O_ddr_clk          (ddr_ck          ),
    .O_ddr_clk_n        (ddr_ck_n        ),
    .O_ddr_cke          (ddr_cke          ),
    .O_ddr_odt          (ddr_odt          ),
    .O_ddr_reset_n      (ddr_reset_n      ),
    .O_ddr_dqm          (ddr_dm           ),
    .IO_ddr_dq          (ddr_dq           ),
    .IO_ddr_dqs         (ddr_dqs          ),
    .IO_ddr_dqs_n       (ddr_dqs_n        )
);

endmodule