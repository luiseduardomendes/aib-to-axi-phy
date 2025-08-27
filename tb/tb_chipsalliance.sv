`timescale 1ns/1ps

supply1 HI;  // Global logic '1' (connects to vdd)
supply0 LO;  // Global logic '0' (connects to gnd)

module top_tb_modif();

// --- Parameters ---
parameter CLK_SCALING 		= 4;
parameter WR_CYCLE   		= 2*CLK_SCALING;
parameter RD_CYCLE   		= 2*CLK_SCALING;
parameter FWD_CYCLE  		= 1*CLK_SCALING;
parameter AVMM_CYCLE 		= 4;
parameter OSC_CYCLE  		= 1*CLK_SCALING;
parameter TOTAL_CHNL_NUM 	= 24;
parameter DWIDTH 		    = 40; // Corresponds to DWIDTH in DUT
parameter DATAWIDTH 		= 64;
parameter FULL 			    = 1;
parameter HALF 			    = 2;
parameter CLKL_HALF_CYCLE 	= 0.5;

// --- Local CSR Addresses ---
localparam REG_MM_WR_CFG_ADDR		= 32'h50001000;
localparam REG_MM_WR_RD_ADDR	 	= 32'h50001004;
localparam REG_MM_BUS_STS_ADDR	 	= 32'h50001008;
localparam REG_LINKUP_STS_ADDR		= 32'h5000100C;
localparam REG_DOUT_FIRST1_ADDR		= 32'h50004000;
localparam REG_DOUT_LAST1_ADDR		= 32'h50004010;
localparam REG_DIN_FIRST1_ADDR		= 32'h50004020;
localparam REG_DIN_LAST1_ADDR		= 32'h50004030;
localparam REG_MM_RD_CFG_ADDR		= 32'h50001010;

// --- DUT Clocks and Resets ---
reg 	ms_wr_clk;
reg 	ms_rd_clk;
reg 	ms_fwd_clk;
reg 	sl_wr_clk;
reg 	sl_rd_clk;
reg 	sl_fwd_clk;
reg		avmm_clk;
reg 	osc_clk;
reg     clk_phy;
reg     clk_p_div2;
reg     clk_p_div4;
reg     rst_phy_n;
reg     tb_w_m_wr_rst_n;
reg     tb_w_s_wr_rst_n;

// --- DUT Power and Ground ---
wire    vddc1;
wire    vddc2;
wire    vddtx;
wire    vss;

assign vddc1 = HI;
assign vddc2 = HI;
assign vddtx = HI;
assign vss   = LO;

// --- CSR Interface Signals ---
reg  [31:0] tb_wr_addr, tb_wrdata;
reg 		tb_wren, tb_rden;
reg  [31:0]	tb_read_data;       		
wire [31:0]	tb_master_readdata;     	
wire 		tb_master_readdatavalid;

// --- Leader AVMM Configuration Interface Signals ---
reg         tb_cfg_avmm_clk;
reg         tb_cfg_avmm_rst_n;
reg [16:0]  tb_cfg_avmm_addr;
reg [3:0]   tb_cfg_avmm_byte_en;
reg         tb_cfg_avmm_read;
reg         tb_cfg_avmm_write;
reg [31:0]  tb_cfg_avmm_wdata;
wire        tb_o_cfg_avmm_rdatavld;
wire [31:0] tb_o_cfg_avmm_rdata;
wire        tb_o_cfg_avmm_waitreq;

// --- Testbench Internal Signals ---
reg [DWIDTH-1:0] t_data_out_128b;
reg [DWIDTH-1:0] data_out_first;
reg [DWIDTH-1:0] data_out_last;
reg [DWIDTH-1:0] data_in_first;
reg [DWIDTH-1:0] data_in_last;
reg [3:0] 		 mask_reg;
reg	[31:0]		 tb_32b_rd_addr;
int 			 i;

// --- DUT Instantiation ---
aximm_aib_m2s2_top #(
    .AXI_CHNL_NUM(1),
    .LEADER_MODE(HALF), 
    .FOLLOWER_MODE(HALF),
    .DATAWIDTH(DATAWIDTH), 
    .TOTAL_CHNL_NUM(TOTAL_CHNL_NUM),
    .DWIDTH(DWIDTH)
) aximm_aib_dut(
    // Power and Ground
    .vddc1(vddc1),
    .vddc2(vddc2),
    .vddtx(vddtx),
    .vss(vss),

    // Clocks and Resets
    .i_w_m_wr_rst_n(tb_w_m_wr_rst_n),
    .i_w_s_wr_rst_n(tb_w_s_wr_rst_n),
    .lane_clk_a({2{ms_wr_clk}}),
    .lane_clk_b({2{sl_wr_clk}}),
    .rst_phy_n(rst_phy_n),
    .clk_phy(clk_phy),
    .clk_p_div2(clk_p_div2),
    .clk_p_div4(clk_p_div4),
    .ms_wr_clk(ms_wr_clk),
    .ms_rd_clk(ms_rd_clk),
    .ms_fwd_clk(ms_fwd_clk),
    .sl_wr_clk(sl_wr_clk),
    .sl_rd_clk(sl_rd_clk),
    .sl_fwd_clk(sl_fwd_clk),
    .avmm_clk(avmm_clk), 
    .osc_clk(osc_clk), 

    // Status Outputs
    .tx_online(),
    .rx_online(),
    .test_done(),
    
    // CSR Interface
    .i_wr_addr(tb_wr_addr), 
    .i_wrdata(tb_wrdata), 
    .i_wren(tb_wren), 
    .i_rden(tb_rden),
    .o_master_readdatavalid(tb_master_readdatavalid),
    .o_master_readdata(tb_master_readdata),
    .o_master_waitrequest(),

    // Leader AVMM Configuration Interface
    .i_cfg_avmm_clk(tb_cfg_avmm_clk),
    .i_cfg_avmm_rst_n(tb_cfg_avmm_rst_n),
    .i_cfg_avmm_addr(tb_cfg_avmm_addr),
    .i_cfg_avmm_byte_en(tb_cfg_avmm_byte_en),
    .i_cfg_avmm_read(tb_cfg_avmm_read),
    .i_cfg_avmm_write(tb_cfg_avmm_write),
    .i_cfg_avmm_wdata(tb_cfg_avmm_wdata),
    .o_cfg_avmm_rdatavld(tb_o_cfg_avmm_rdatavld),
    .o_cfg_avmm_rdata(tb_o_cfg_avmm_rdata),
    .o_cfg_avmm_waitreq(tb_o_cfg_avmm_waitreq)
);

// --- Clock Generation ---
initial begin
	ms_wr_clk	= 1'b0;
	ms_rd_clk	= 1'b0;
	ms_fwd_clk	= 1'b0;
	sl_wr_clk	= 1'b0;
	sl_rd_clk	= 1'b0;
	sl_fwd_clk	= 1'b0;
	avmm_clk	= 1'b0;
	osc_clk		= 1'b0;
    tb_cfg_avmm_clk = 1'b0;
end

always #(WR_CYCLE/2)   ms_wr_clk   	= ~ms_wr_clk;
always #(RD_CYCLE/2)   ms_rd_clk   	= ~ms_rd_clk;
always #(FWD_CYCLE/2)  ms_fwd_clk  	= ~ms_fwd_clk;
always #(WR_CYCLE/2)   sl_wr_clk   	= ~sl_wr_clk;
always #(RD_CYCLE/2)   sl_rd_clk   	= ~sl_rd_clk;
always #(FWD_CYCLE/2)  sl_fwd_clk  	= ~sl_fwd_clk;
always #(AVMM_CYCLE/2) avmm_clk 	= ~avmm_clk;
always #(OSC_CYCLE/2)  osc_clk  	= ~osc_clk;
always #(AVMM_CYCLE/2) tb_cfg_avmm_clk = ~tb_cfg_avmm_clk;

initial begin
  repeat (5) #(CLKL_HALF_CYCLE);
  forever @(clk_phy) begin
    #(CLKL_HALF_CYCLE); clk_phy <= ~clk_phy; clk_p_div2 <= ~clk_p_div2; clk_p_div4 <= ~clk_p_div4;
    #(CLKL_HALF_CYCLE); clk_phy <= ~clk_phy;
    #(CLKL_HALF_CYCLE); clk_phy <= ~clk_phy; clk_p_div2 <= ~clk_p_div2;
    #(CLKL_HALF_CYCLE); clk_phy <= ~clk_phy;
    #(CLKL_HALF_CYCLE); clk_phy <= ~clk_phy; clk_p_div2 <= ~clk_p_div2; clk_p_div4 <= ~clk_p_div4;
    #(CLKL_HALF_CYCLE); clk_phy <= ~clk_phy;
    #(CLKL_HALF_CYCLE); clk_phy <= ~clk_phy; clk_p_div2 <= ~clk_p_div2;
    #(CLKL_HALF_CYCLE); clk_phy <= ~clk_phy;
  end
end

initial begin
  repeat (10) #(CLKL_HALF_CYCLE);
  rst_phy_n <= 1'b0;
  repeat (10) #(CLKL_HALF_CYCLE);
  clk_phy <= 1'b0;
end

// --- Reset Sequence ---
initial begin
  clk_p_div2 		= 1'bx;
  clk_p_div4 		= 1'bx;
  clk_phy 		    = 1'bx;
  rst_phy_n  		= 1'bx;
  tb_w_m_wr_rst_n 	= 1'bx;
  tb_w_s_wr_rst_n 	= 1'bx;
  tb_cfg_avmm_rst_n = 1'bx;

  repeat (10) #(CLKL_HALF_CYCLE);
  rst_phy_n 		 = 1'b0;
  tb_w_m_wr_rst_n 	<= 1'b0;
  tb_w_s_wr_rst_n 	<= 1'b0;
  tb_cfg_avmm_rst_n <= 1'b0;

  repeat (10) #(CLKL_HALF_CYCLE);
  clk_p_div4 		<= 1'b0;
  clk_p_div2 		<= 1'b0;
  
  repeat (500) @(posedge clk_phy);
  repeat (1) @(posedge ms_wr_clk);
  tb_w_m_wr_rst_n 	<= 1;
  
  repeat (1) @(posedge sl_wr_clk);
  tb_w_s_wr_rst_n 	<= 1;
  
  repeat (1) @(posedge tb_cfg_avmm_clk);
  tb_cfg_avmm_rst_n <= 1;

  repeat (1) @(posedge clk_phy);
  rst_phy_n 		<= 1'b1;
  $display ("######## Exit Reset @ %0t ns ########", $time);
end

// --- Random Seed Initialization ---
integer random_seed;
initial begin
  if (!$value$plusargs("VERILOG_RANDOM_SEED=%h",random_seed))
    if (!$value$plusargs("SEED=%h",random_seed))
      random_seed = 0;

  $display ("Using Random Seed (random_seed) = %0x",random_seed);
  $display ("To reproduce, add:  +VERILOG_RANDOM_SEED=%0x",random_seed);
end

// --- Main Test Sequence ---
initial begin
	t_data_out_128b		= 0;
	mask_reg		= 0;
	tb_wren			= 0;
	data_out_first		= 0;
	data_out_last		= 0;
	data_in_first		= 0;
	tb_32b_rd_addr		= 0;
	tb_wrdata		= 0;
	data_in_last		= 0;
	tb_read_data		= 0;
	tb_rden			= 0;
	tb_wr_addr		= 0;
    tb_cfg_avmm_addr = 0;
    tb_cfg_avmm_byte_en = 0;
    tb_cfg_avmm_read = 0;
    tb_cfg_avmm_write = 0;
    tb_cfg_avmm_wdata = 0;
	
	$display("Wait for AXI MM online");
	wait (rst_phy_n == 1'b1);
	repeat (10) @(posedge avmm_clk);

	//Delay X,Y and Z values
	avmm_write(32'h50002000, 32'h0000000C); //Delay X value = 12
	avmm_write(32'h50002004, 32'h00000020); //Delay Y value = 32
	avmm_write(32'h50002008, 32'h00001770); //Delay Z value = 6000
	
	//wait for AIB online
	avmm_read(REG_LINKUP_STS_ADDR);
	while (tb_read_data[3:0] != 4'hf) begin
		avmm_read(REG_LINKUP_STS_ADDR);
	end
	avmm_read(REG_LINKUP_STS_ADDR);
	
	//check for AIB online
	if(tb_read_data[3:0]== 4'hF) begin
		$display("\n");
		$display("////////////////////////////////////////////////////////");
		$display("AXI-MM TX and RX online is high");
		$display("///////////////////////////////////////////////////////\n");
	end
	else $display("AXI-MM TX/RX is offline\n");
	repeat (200) @(posedge ms_wr_clk);
	
	//Random pattern test 
	avmm_write(REG_MM_WR_RD_ADDR, 32'h10000000);
	avmm_write(REG_MM_WR_CFG_ADDR, 32'h00041804);
	$display("///////////////////////////////////////////////////");
	$display("%0t AXI-MM Incremental pattern test for 128 burst packet ",$time);
	$display("//////////////////////////////////////////////////\n");
	repeat (10) @(posedge ms_wr_clk);
	
	//wait for AXI MM write complete
	avmm_read(REG_MM_BUS_STS_ADDR);
	while (tb_read_data[4] != 1'b1) begin
		avmm_read(REG_MM_BUS_STS_ADDR);
	end
	avmm_read(REG_MM_BUS_STS_ADDR);	
	repeat(20) @(posedge ms_wr_clk);

	//read first data after write initiate
	read_aximm_128bit_data(REG_DOUT_FIRST1_ADDR);
	data_out_first = t_data_out_128b;
	$display("AXI-MM send pattern1 burst  1 : 0x%h", data_out_first);

   	repeat (5) begin
		repeat(20) @(posedge ms_wr_clk);
		$display(".");
	end

	//read last data after write complete
	read_aximm_128bit_data(REG_DOUT_LAST1_ADDR);
	data_out_last = t_data_out_128b;
	$display("AXI-MM send pattern1 burst 128 : 0x%h", data_out_last);
	
	//Initiate Read
	avmm_write(REG_MM_WR_RD_ADDR, 32'h10000000);
	avmm_write(REG_MM_RD_CFG_ADDR, 32'h00041804);	
	repeat (20) @(posedge ms_wr_clk);

	//wait for AXI MM read complete
	avmm_read(REG_MM_BUS_STS_ADDR);
	while (tb_read_data[5] != 1'b1) begin
		avmm_read(REG_MM_BUS_STS_ADDR);
	end
	avmm_read(REG_MM_BUS_STS_ADDR);
	repeat (20) @(posedge ms_wr_clk);
	
	//read first data axi read initiate 
	read_aximm_128bit_data(REG_DIN_FIRST1_ADDR);
	data_in_first = t_data_out_128b;
	$display("AXI-MM Receive pattern1 burst  1 : 0x%h", data_in_first);

    repeat (5) begin
		repeat(20) @(posedge ms_wr_clk);
		$display(".");
	end
	repeat (20) @(posedge ms_wr_clk);

	//read last data after axi read initiate
	read_aximm_128bit_data(REG_DIN_LAST1_ADDR);
	data_in_last = t_data_out_128b;
	$display("AXI-MM Receive pattern1 burst 128 : 0x%h", data_in_last);
	$display("\n");

	//Read test report	
	repeat (20) @(posedge ms_wr_clk);
	aximm_test_report;
	
	$finish(0);
end

// --- Tasks ---
task avmm_write (input [31:0] wr_addr, [31:0] wrdata);
begin	
	tb_wr_addr 	= wr_addr;
	tb_wrdata  	= wrdata;
	tb_wren   	= 1'b0;
	@(posedge ms_wr_clk);
	tb_wren   = 1'b1;
	@(posedge ms_wr_clk);
	tb_wren		= 1'b0;
end
endtask

task avmm_read (input [31:0] rd_addr);
begin
	tb_wr_addr 	= rd_addr;
	tb_rden   	= 1'b0;
	@(posedge ms_wr_clk);
	tb_rden   = 1'b1;
	@(posedge ms_wr_clk);
	tb_rden		= 1'b0;
	wait (tb_master_readdatavalid==1'b1);
	tb_read_data	= tb_master_readdata;
end 
endtask

task read_aximm_128bit_data (input [31:0] rd_staddr);
begin
    tb_32b_rd_addr	= rd_staddr;
    t_data_out_128b = 0; // Clear before reading
    for(i=0; i < (DWIDTH/32); i=i+1) begin
        avmm_read(tb_32b_rd_addr);
        t_data_out_128b = (t_data_out_128b << 32) | tb_read_data;
        tb_32b_rd_addr	= tb_32b_rd_addr + 4;
    end 
end
endtask

task aximm_test_report;
begin
	avmm_read(REG_MM_BUS_STS_ADDR);
	mask_reg = {tb_read_data[3:0]}&4'hf;
	case(mask_reg)
		4'b0xxx : $display("AXI-MM Align error\n");
		4'bx0xx : $display("AXI-MM Align error\n");
		4'b1110 : $display("AXI-MM test Fail\n");
		4'b1111 : begin
			$display("*******************");
			$display("* AXI-MM test Pass *");
			$display("*******************");
		end 
		4'b110x : $display("Test not complete\n");
		default	: $display("Invalid test condition\n");
	endcase
end 
endtask

endmodule
