`timescale 1ns/1ps

supply1 HI;
supply0 LO;

module tb_aib_axi_top_modif();

  // ========================================================================
  // Parameters
  // ========================================================================
  parameter CLK_SCALING       = 4;
  parameter WR_CYCLE          = 2 * CLK_SCALING;
  parameter RD_CYCLE          = 2 * CLK_SCALING;
  parameter FWD_CYCLE         = 1 * CLK_SCALING;
  parameter OSC_CYCLE         = 1 * CLK_SCALING;
  parameter AVMM_CYCLE        = 4;

  parameter ACTIVE_CHNLS      = 1;
  parameter NBR_CHNLS         = 24;
  parameter TOTAL_CHNL_NUM    = NBR_CHNLS;
  parameter DWIDTH            = 40;
  parameter ADDRWIDTH         = 32;
  parameter IDWIDTH           = 4;

  // ========================================================================
  // Testbench Signals
  // ========================================================================

  // --- Clocks and Resets ---
  reg  leader_m_wr_clk;
  reg  leader_m_rd_clk;
  reg  leader_m_fwd_clk;
  reg leader_i_osc_clk;
  reg leader_avmm_clk;
  reg leader_i_cfg_avmm_clk;
  reg [NBR_CHNLS-1:0] leader_ns_adapter_rstn;
  reg leader_avmm_rst_n;
  reg leader_i_cfg_avmm_rst_n;
  reg leader_clk_wr;
  reg leader_rst_wr_n;

  reg  follower_m_wr_clk;
  reg  follower_m_rd_clk;
  reg  follower_m_fwd_clk;
  reg follower_avmm_clk;
  reg follower_i_cfg_avmm_clk;
  reg [NBR_CHNLS-1:0] follower_ns_adapter_rstn;
  reg follower_avmm_rst_n;
  reg follower_i_cfg_avmm_rst_n;
  reg follower_clk_wr;
  reg follower_rst_wr_n;

  // --- DUT Interface Signals ---
  reg  [NBR_CHNLS-1: 0] leader_ns_mac_rdy;
  wire [NBR_CHNLS-1: 0] leader_fs_mac_rdy;
  wire [NBR_CHNLS-1: 0] leader_m_rx_align_done;

  // Leader AVMM Configuration Interface
  reg  [16:0] leader_i_cfg_avmm_addr;
  reg  [3:0]  leader_i_cfg_avmm_byte_en;
  reg         leader_i_cfg_avmm_read;
  reg         leader_i_cfg_avmm_write;
  reg  [31:0] leader_i_cfg_avmm_wdata;
  wire        leader_o_cfg_avmm_rdatavld;
  wire [31:0] leader_o_cfg_avmm_rdata;
  wire        leader_o_cfg_avmm_waitreq;

  // Leader AXI Slave Interface (driven by testbench)
  reg  [IDWIDTH-1:0]     s_axi_awid;
  reg  [ADDRWIDTH-1:0]   s_axi_awaddr;
  reg  [7:0]             s_axi_awlen;
  reg  [2:0]             s_axi_awsize;
  reg  [1:0]             s_axi_awburst;
  reg                    s_axi_awvalid;
  wire                   s_axi_awready;
  reg  [IDWIDTH-1:0]     s_axi_wid;
  reg  [127:0]           s_axi_wdata;
  reg  [15:0]            s_axi_wstrb;
  reg                    s_axi_wlast;
  reg                    s_axi_wvalid;
  wire                   s_axi_wready;
  wire [IDWIDTH-1:0]     s_axi_bid;
  wire [1:0]             s_axi_bresp;
  wire                   s_axi_bvalid;
  reg                    s_axi_bready;
  reg  [IDWIDTH-1:0]     s_axi_arid;
  reg  [ADDRWIDTH-1:0]   s_axi_araddr;
  reg  [7:0]             s_axi_arlen;
  reg  [2:0]             s_axi_arsize;
  reg  [1:0]             s_axi_arburst;
  reg                    s_axi_arvalid;
  wire                   s_axi_arready;
  wire [IDWIDTH-1:0]     s_axi_rid;
  wire [127:0]           s_axi_rdata;
  wire [1:0]             s_axi_rresp;
  wire                   s_axi_rlast;
  wire                   s_axi_rvalid;
  reg                    s_axi_rready;

  // Follower signals
  reg  [NBR_CHNLS-1: 0] follower_ns_mac_rdy;
  wire [NBR_CHNLS-1: 0] follower_fs_mac_rdy;
  wire [NBR_CHNLS-1: 0] follower_m_rx_align_done;
  wire [NBR_CHNLS-1: 0] follower_ms_tx_transfer_en;
  wire [NBR_CHNLS-1: 0] follower_sl_tx_transfer_en;

  
  reg  [16:0] follower_i_cfg_avmm_addr;
  reg  [3:0]  follower_i_cfg_avmm_byte_en;
  reg         follower_i_cfg_avmm_read;
  reg         follower_i_cfg_avmm_write;
  reg  [31:0] follower_i_cfg_avmm_wdata;
  wire        follower_o_cfg_avmm_rdatavld;
  wire [31:0] follower_o_cfg_avmm_rdata;
  wire        follower_o_cfg_avmm_waitreq;

  
  // Follower AXI Master Interface (monitored by testbench)
  wire [IDWIDTH-1:0]     m_axi_awid;
  wire [ADDRWIDTH-1:0]   m_axi_awaddr;
  wire [7:0]             m_axi_awlen;
  wire [2:0]             m_axi_awsize;
  wire [1:0]             m_axi_awburst;
  wire                   m_axi_awvalid;
  reg                    m_axi_awready;
  wire [IDWIDTH-1:0]     m_axi_wid;
  wire [127:0]           m_axi_wdata;
  wire [15:0]            m_axi_wstrb;
  wire                   m_axi_wlast;
  wire                   m_axi_wvalid;
  reg                    m_axi_wready;
  reg  [IDWIDTH-1:0]     m_axi_bid;
  reg  [1:0]             m_axi_bresp;
  reg                    m_axi_bvalid;
  wire                   m_axi_bready;
  wire [IDWIDTH-1:0]     m_axi_arid;
  wire [ADDRWIDTH-1:0]   m_axi_araddr;
  wire [7:0]             m_axi_arlen;
  wire [2:0]             m_axi_arsize;
  wire [1:0]             m_axi_arburst;
  wire                   m_axi_arvalid;
  reg                    m_axi_arready;
  reg  [IDWIDTH-1:0]     m_axi_rid;
  reg  [127:0]           m_axi_rdata;
  reg  [1:0]             m_axi_rresp;
  reg                    m_axi_rlast;
  reg                    m_axi_rvalid;
  wire                   m_axi_rready;

  // --- Internal Testbench Variables ---
  string  status;
  integer i_m1, i_s1;
  // These signals were brought up from inside the DUT
  // In a real scenario, these would likely be controlled via a configuration interface (e.g., AVMM)
  // For this testbench, we will control them directly if they are inputs to the wrapper.
  // If they are not inputs, this indicates a required change in the wrapper itself.
  // Assuming they are NOT part of the wrapper, we can't drive them.
  // Let's assume for now they are for configuration and should be handled by AVMM writes.
  // reg [1:0] ms1_tx_fifo_mode;
  // reg [1:0] sl1_tx_fifo_mode;
  // reg [1:0] ms1_rx_fifo_mode;
  // reg [1:0] sl1_rx_fifo_mode;
  // reg [4:0] ms1_tx_markbit;
  // reg [4:0] sl1_tx_markbit;
  // reg       ms1_gen1;
  // reg       sl1_gen1;

  integer run_for_n_pkts_ms1;
  integer run_for_n_pkts_sl1;


  // ========================================================================
  // DUT Instantiation
  // ========================================================================
  aib_axi_top_wrapper #(
      .ACTIVE_CHNLS      (ACTIVE_CHNLS),
      .NBR_CHNLS         (NBR_CHNLS),
      .DWIDTH            (DWIDTH),
      .ADDRWIDTH         (ADDRWIDTH),
      .IDWIDTH           (IDWIDTH),
      .GEN2_MODE         (1'b1)
  ) dut (
      // --- Leader (Master Bridge) Interface ---
      .leader_vddc1(HI),
      .leader_vddc2(HI),
      .leader_vddtx(HI),
      .leader_vss(LO),
      .leader_m_wr_clk(leader_m_wr_clk),
      .leader_m_rd_clk(leader_m_rd_clk),
      .leader_m_fwd_clk(leader_m_fwd_clk),
      .leader_i_osc_clk(leader_i_osc_clk),
      .leader_ns_adapter_rstn(leader_ns_adapter_rstn),
      .leader_ns_mac_rdy(leader_ns_mac_rdy),
      .leader_fs_mac_rdy(leader_fs_mac_rdy),
      .leader_m_rx_align_done(leader_m_rx_align_done),
      .leader_avmm_clk(leader_avmm_clk),
      .leader_avmm_rst_n(leader_avmm_rst_n),
      .leader_i_cfg_avmm_clk(leader_i_cfg_avmm_clk),
      .leader_i_cfg_avmm_rst_n(leader_i_cfg_avmm_rst_n),
      .leader_i_cfg_avmm_addr(leader_i_cfg_avmm_addr),
      .leader_i_cfg_avmm_byte_en(leader_i_cfg_avmm_byte_en),
      .leader_i_cfg_avmm_read(leader_i_cfg_avmm_read),
      .leader_i_cfg_avmm_write(leader_i_cfg_avmm_write),
      .leader_i_cfg_avmm_wdata(leader_i_cfg_avmm_wdata),
      .leader_o_cfg_avmm_rdatavld(leader_o_cfg_avmm_rdatavld),
      .leader_o_cfg_avmm_rdata(leader_o_cfg_avmm_rdata),
      .leader_o_cfg_avmm_waitreq(leader_o_cfg_avmm_waitreq),
      .leader_clk_wr(leader_clk_wr),
      .leader_rst_wr_n(leader_rst_wr_n),
      .follower_init_r_credit(8'd16), // Example value
      .follower_init_b_credit(8'd16), // Example value
      .leader_delay_x_value(16'd0),   // Example value
      .leader_delay_y_value(16'd0),   // Example value
      .leader_delay_z_value(16'd0),   // Example value
      .s_axi_awid(s_axi_awid),
      .s_axi_awaddr(s_axi_awaddr),
      .s_axi_awlen(s_axi_awlen),
      .s_axi_awsize(s_axi_awsize),
      .s_axi_awburst(s_axi_awburst),
      .s_axi_awvalid(s_axi_awvalid),
      .s_axi_awready(s_axi_awready),
      .s_axi_wid(s_axi_wid),
      .s_axi_wdata(s_axi_wdata),
      .s_axi_wstrb(s_axi_wstrb),
      .s_axi_wlast(s_axi_wlast),
      .s_axi_wvalid(s_axi_wvalid),
      .s_axi_wready(s_axi_wready),
      .s_axi_bid(s_axi_bid),
      .s_axi_bresp(s_axi_bresp),
      .s_axi_bvalid(s_axi_bvalid),
      .s_axi_bready(s_axi_bready),
      .s_axi_arid(s_axi_arid),
      .s_axi_araddr(s_axi_araddr),
      .s_axi_arlen(s_axi_arlen),
      .s_axi_arsize(s_axi_arsize),
      .s_axi_arburst(s_axi_arburst),
      .s_axi_arvalid(s_axi_arvalid),
      .s_axi_arready(s_axi_arready),
      .s_axi_rid(s_axi_rid),
      .s_axi_rdata(s_axi_rdata),
      .s_axi_rresp(s_axi_rresp),
      .s_axi_rlast(s_axi_rlast),
      .s_axi_rvalid(s_axi_rvalid),
      .s_axi_rready(s_axi_rready),

      // --- Follower (Slave Bridge) Interface ---
      .follower_vddc1(HI),
      .follower_vddc2(HI),
      .follower_vddtx(HI),
      .follower_vss(LO),
      .follower_m_wr_clk(follower_m_wr_clk),
      .follower_m_rd_clk(follower_m_rd_clk),
      .follower_m_fwd_clk(follower_m_fwd_clk),
      .follower_ns_adapter_rstn(follower_ns_adapter_rstn),
      .follower_ns_mac_rdy(follower_ns_mac_rdy),
      .follower_fs_mac_rdy(follower_fs_mac_rdy),
      .follower_m_rx_align_done(follower_m_rx_align_done),
      .follower_i_cfg_avmm_clk      (follower_i_cfg_avmm_clk),
      .follower_i_cfg_avmm_rst_n    (follower_i_cfg_avmm_rst_n),
      .follower_avmm_clk            (follower_avmm_clk),
      .follower_avmm_rst_n          (follower_avmm_rst_n),
      .follower_i_cfg_avmm_addr     (follower_i_cfg_avmm_addr),
      .follower_i_cfg_avmm_byte_en  (follower_i_cfg_avmm_byte_en),
      .follower_i_cfg_avmm_read     (follower_i_cfg_avmm_read),
      .follower_i_cfg_avmm_write    (follower_i_cfg_avmm_write),
      .follower_i_cfg_avmm_wdata    (follower_i_cfg_avmm_wdata),
      .follower_o_cfg_avmm_rdatavld (follower_o_cfg_avmm_rdatavld),
      .follower_o_cfg_avmm_rdata    (follower_o_cfg_avmm_rdata),
      .follower_o_cfg_avmm_waitreq  (follower_o_cfg_avmm_waitreq),
      .follower_clk_wr(follower_clk_wr),
      .follower_rst_wr_n(follower_rst_wr_n),
      .leader_init_ar_credit(8'd16),  // Example value
      .leader_init_aw_credit(8'd16),  // Example value
      .leader_init_w_credit(8'd32),   // Example value
      .follower_delay_x_value(16'd0), // Example value
      .follower_delay_y_value(16'd0), // Example value
      .follower_delay_z_value(16'd0), // Example value
      .follower_ms_tx_transfer_en(follower_ms_tx_transfer_en),
      .follower_sl_tx_transfer_en(follower_sl_tx_transfer_en),
      .m_axi_awid(m_axi_awid),
      .m_axi_awaddr(m_axi_awaddr),
      .m_axi_awlen(m_axi_awlen),
      .m_axi_awsize(m_axi_awsize),
      .m_axi_awburst(m_axi_awburst),
      .m_axi_awvalid(m_axi_awvalid),
      .m_axi_awready(m_axi_awready),
      .m_axi_wid(m_axi_wid),
      .m_axi_wdata(m_axi_wdata),
      .m_axi_wstrb(m_axi_wstrb),
      .m_axi_wlast(m_axi_wlast),
      .m_axi_wvalid(m_axi_wvalid),
      .m_axi_wready(m_axi_wready),
      .m_axi_bid(m_axi_bid),
      .m_axi_bresp(m_axi_bresp),
      .m_axi_bvalid(m_axi_bvalid),
      .m_axi_bready(m_axi_bready),
      .m_axi_arid(m_axi_arid),
      .m_axi_araddr(m_axi_araddr),
      .m_axi_arlen(m_axi_arlen),
      .m_axi_arsize(m_axi_arsize),
      .m_axi_arburst(m_axi_arburst),
      .m_axi_arvalid(m_axi_arvalid),
      .m_axi_arready(m_axi_arready),
      .m_axi_rid(m_axi_rid),
      .m_axi_rdata(m_axi_rdata),
      .m_axi_rresp(m_axi_rresp),
      .m_axi_rlast(m_axi_rlast),
      .m_axi_rvalid(m_axi_rvalid),
      .m_axi_rready(m_axi_rready)
  );

  // ========================================================================
  // Clock Generation
  // ========================================================================
  initial begin
    leader_m_wr_clk = 1'b0;
    leader_m_rd_clk = 1'b0;
    leader_m_fwd_clk = 1'b0;
    leader_i_osc_clk = 1'b0;
    leader_avmm_clk = 1'b0;
    leader_i_cfg_avmm_clk = 1'b0;
    leader_clk_wr = 1'b0;

    follower_m_wr_clk = 1'b0;
    follower_m_rd_clk = 1'b0;
    follower_m_fwd_clk = 1'b0;
    follower_avmm_clk = 1'b0;
    follower_i_cfg_avmm_clk = 1'b0;
    follower_clk_wr = 1'b0;
  end

  always #(WR_CYCLE/2)   leader_m_wr_clk <= ~leader_m_wr_clk;
  always #(RD_CYCLE/2)   leader_m_rd_clk <= ~leader_m_rd_clk;
  always #(FWD_CYCLE/2)  leader_m_fwd_clk <= ~leader_m_fwd_clk;
  always #(OSC_CYCLE/2)  leader_i_osc_clk <= ~leader_i_osc_clk;
  always #(AVMM_CYCLE/2) leader_avmm_clk <= ~leader_avmm_clk;
  always #(AVMM_CYCLE/2) leader_i_cfg_avmm_clk <= ~leader_i_cfg_avmm_clk;
  always #(WR_CYCLE/2)   leader_clk_wr <= ~leader_clk_wr;

  always #(WR_CYCLE/2)   follower_m_wr_clk <= ~follower_m_wr_clk;
  always #(RD_CYCLE/2)   follower_m_rd_clk <= ~follower_m_rd_clk;
  always #(FWD_CYCLE/2)  follower_m_fwd_clk <= ~follower_m_fwd_clk;
  always #(AVMM_CYCLE/2) follower_avmm_clk <= ~follower_avmm_clk;
  always #(AVMM_CYCLE/2) follower_i_cfg_avmm_clk <= ~follower_i_cfg_avmm_clk;
  always #(WR_CYCLE/2)   follower_clk_wr <= ~follower_clk_wr;


  // ========================================================================
  // Tasks
  // ========================================================================

  // --- Reset Task ---
  task reset_duts;
  begin
    $display("%0t: AIB : Asserting resets.", $time);
    leader_ns_adapter_rstn <= '0;
    leader_avmm_rst_n <= 1'b0;
    leader_i_cfg_avmm_rst_n <= 1'b0;
    leader_rst_wr_n <= 1'b0;

    follower_ns_adapter_rstn <= '0;
    follower_rst_wr_n <= 1'b0;

    // Initialize AXI interfaces
    s_axi_awvalid <= 1'b0;
    s_axi_wvalid  <= 1'b0;
    s_axi_bready  <= 1'b1; // Always ready to accept response
    s_axi_arvalid <= 1'b0;
    s_axi_rready  <= 1'b1; // Always ready to accept read data

    m_axi_awready <= 1'b1; // Testbench is ready
    m_axi_wready  <= 1'b1; // Testbench is ready
    m_axi_bvalid  <= 1'b0;
    m_axi_arready <= 1'b1; // Testbench is ready
    m_axi_rvalid  <= 1'b0;

    repeat (20) @(posedge leader_m_wr_clk);
    
    $display("%0t: AIB : De-asserting resets.", $time);
    leader_ns_adapter_rstn <= {24{1'b1}};
    leader_avmm_rst_n <= 1'b1;
    leader_i_cfg_avmm_rst_n <= 1'b1;
    leader_rst_wr_n <= 1'b1;
    
    follower_ns_adapter_rstn <= {24{1'b1}};
    follower_rst_wr_n <= 1'b1;
    
    repeat (5) @(posedge leader_m_wr_clk);
  end
  endtask

  // --- AVMM Write Task ---
  task cfg_write(input [16:0] addr, input [3:0] be, input [31:0] data);
  begin
    @(posedge leader_i_cfg_avmm_clk);
    leader_i_cfg_avmm_addr <= addr;
    leader_i_cfg_avmm_byte_en <= be;
    leader_i_cfg_avmm_wdata <= data;
    leader_i_cfg_avmm_write <= 1'b1;
    leader_i_cfg_avmm_read <= 1'b0;
    
    @(posedge leader_i_cfg_avmm_clk);
    // Wait for waitrequest to de-assert if it asserts
    while (leader_o_cfg_avmm_waitreq) begin
        @(posedge leader_i_cfg_avmm_clk);
    end
    
    leader_i_cfg_avmm_write <= 1'b0;
    leader_i_cfg_avmm_addr <= 'x;
    leader_i_cfg_avmm_byte_en <= 'x;
    leader_i_cfg_avmm_wdata <= 'x;
  end
  endtask
  
  // --- Follower AVMM Write Task ---
  task follower_cfg_write(input [16:0] addr, input [3:0] be, input [31:0] data);
  begin
    @(posedge follower_i_cfg_avmm_clk);
    follower_i_cfg_avmm_addr <= addr;
    follower_i_cfg_avmm_byte_en <= be;
    follower_i_cfg_avmm_wdata <= data;
    follower_i_cfg_avmm_write <= 1'b1;
    follower_i_cfg_avmm_read <= 1'b0;
    
    @(posedge follower_i_cfg_avmm_clk);
    while (follower_o_cfg_avmm_waitreq) begin
        @(posedge follower_i_cfg_avmm_clk);
    end
    
    follower_i_cfg_avmm_write <= 1'b0;
    follower_i_cfg_avmm_addr <= 'x;
    follower_i_cfg_avmm_byte_en <= 'x;
    follower_i_cfg_avmm_wdata <= 'x;
  end
  endtask

    // --- DUT Wakeup Task ---
    task duts_wakeup ();
    begin
        leader_ns_mac_rdy = {TOTAL_CHNL_NUM{1'b1}}; 
        follower_ns_mac_rdy = {TOTAL_CHNL_NUM{1'b1}}; 

        #1000ns;
        leader_ns_adapter_rstn = {TOTAL_CHNL_NUM{1'b1}};
        follower_ns_adapter_rstn = {TOTAL_CHNL_NUM{1'b1}};

        #1000ns;
    end
    endtask
  
  // --- Link Up Task ---
  task link_up;
  begin
    fork
        wait (follower_ms_tx_transfer_en == {TOTAL_CHNL_NUM{1'b1}});
        wait (follower_sl_tx_transfer_en == {TOTAL_CHNL_NUM{1'b1}});
    join;
  end
  endtask

  // --- AXI Write Transaction Task (Single Beat) ---
  task axi_write_transaction;
  begin
      $display("%0t: AIB : Starting single-beat AXI write transaction.", $time);

      // Address Write
      @(posedge leader_clk_wr);
      s_axi_awid    <= 4'h1;
      s_axi_awaddr  <= 32'h1000_0000;
      s_axi_awlen   <= 8'd0; // 1 beat (awlen+1)
      s_axi_awsize  <= 3'b100; // 16 bytes (128 bits)
      s_axi_awburst <= 2'b01;  // INCR
      s_axi_awvalid <= 1'b1;

      wait (s_axi_awready);
      @(posedge leader_clk_wr);
      s_axi_awvalid <= 1'b0;

      // Write Data (Single Beat)
      @(posedge leader_clk_wr);
      s_axi_wid    <= 4'h1;
      s_axi_wdata  <= 64'hA5A5_0000_0000_0000;
      s_axi_wstrb  <= 15'hFF;
      s_axi_wlast  <= 1'b1;
      s_axi_wvalid <= 1'b1;
      wait (s_axi_wready);
      @(posedge leader_clk_wr);
      s_axi_wvalid <= 1'b0;

      // Write Response
      wait (s_axi_bvalid);
      @(posedge leader_clk_wr);
      s_axi_bready <= 1'b1;
      $display("%0t: AIB : Write response: BRESP=%0h, BID=%0h", $time, s_axi_bresp, s_axi_bid);
      @(posedge leader_clk_wr);
      s_axi_bready <= 1'b0;

      $display("%0t: AIB : Finished single-beat AXI write transaction.", $time);
  end
  endtask

  // --- AXI Read Transaction Task (Example) ---
  task axi_read_transaction;
  begin
      // TODO: Implement a full AXI read transaction
      $display("%0t: AIB : Starting AXI read transaction.", $time);
      // ...
      $display("%0t: AIB : Finished AXI read transaction.", $time);
  end
  endtask


  // ========================================================================
  // Main Test Sequence
  // ========================================================================
  initial begin
    begin
      status = "Reset DUT";
      $display("\n////////////////////////////////////////////////////////////////////////////");
      $display("%0t: AIB : Get into Main initial", $time);
      $display("////////////////////////////////////////////////////////////////////////////\n");
      reset_duts ();
      $display("\n////////////////////////////////////////////////////////////////////////////");
      $display("%0t: AIB : Finish reset_duts", $time);
      $display("////////////////////////////////////////////////////////////////////////////\n");

      $display("\n////////////////////////////////////////////////////////////////////////////");
      $display("\n//                                                                       ///");
      $display("%0t: AIB : set to 2xFIFO mode for ms -> sl and sl -> ms 24 channel testing", $time);
      $display("%0t: AIB : Master is 2.0 AIB model in Gen1 mode", $time);
      $display("%0t: AIB : Slave is 1.0 FPGA", $time);
      $display("\n//                                                                       ///");
      $display("%0t: No dbi enabled", $time);
      $display("////////////////////////////////////////////////////////////////////////////\n");

      // The internal signals like fifo_mode, markbit, gen1 etc.
      // need to be controlled via a configuration bus like AVMM.
      // The writes below are based on the addresses from your original code.
      // These will now go through the wrapper's AVMM interface.
      for (i_m1=0; i_m1<ACTIVE_CHNLS; i_m1++) begin
          cfg_write({i_m1,11'h208}, 4'hf, 32'h0600_0000); // Corresponds to fifo_mode settings
          cfg_write({i_m1,11'h210}, 4'hf, 32'h0000_000b); // Corresponds to gen1 settings
          cfg_write({i_m1,11'h218}, 4'hf, 32'h60a1_0000); // Corresponds to markbit settings
      end

      run_for_n_pkts_ms1 = 40;
      run_for_n_pkts_sl1 = 40;

      $display("\n////////////////////////////////////////////////////////////////////////////");
      $display("%0t: AIB : Performing duts_wakeup", $time);
      $display("////////////////////////////////////////////////////////////////////////////\n");

      duts_wakeup ();
      status = "Waiting for link up";

      $display("\n////////////////////////////////////////////////////////////////////////////");
      $display("%0t: AIB : Waiting for link up", $time);
      $display("////////////////////////////////////////////////////////////////////////////\n");

      link_up ();
      status = "Starting data transmission";

      $display("\n////////////////////////////////////////////////////////////////////////////");
      $display("%0t: AIB : Starting data transmission", $time);
      $display("////////////////////////////////////////////////////////////////////////////\n");

      // Fork join to run transactions in parallel if needed
      fork
          begin
              // Master (Leader) sending data to Slave (Follower)
              repeat(run_for_n_pkts_ms1) begin
                  axi_write_transaction();
                  //ms1_aib2_reg2reg_xmit();
                  //sl1_aib2_regmod_rcv(); 
              end
          end
          // You could have another begin/end block here to model the follower sending data
      join

      status = "Finishing data transmission";
      $display("%0t: AIB : Data transmission finished.", $time);
      
      repeat(100) @(posedge leader_m_wr_clk);
      $finish;
    end
  end

endmodule
