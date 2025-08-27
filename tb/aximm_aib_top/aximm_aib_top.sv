// SPDX-License-Identifier: Apache-2.0
// Copyright (C) 2021 Intel Corporation.
/////////////////////////////////////////////////////////////////////////////////////////
//--------------------------------------------------------------------------------------
// Description: AXIMM AIB top
//
//              This version has been modified to remove the 'top_aib' and
//              'aximm_d128_h2h_wrapper_top' simulation modules. The AXI
//              application logic is now connected directly to the
//              'aib_axi_top_wrapper'.
//
// Change log
// 
/////////////////////////////////////////////////////////////////////////////////////////
`timescale 1ps/1ps
`define SIMULATION
module aximm_aib_m2s2_top#(
    parameter AXI_CHNL_NUM = 1, 
    parameter LEADER_MODE = 1, 
    parameter FOLLOWER_MODE = 2,
    parameter DATAWIDTH = 64, 
    parameter TOTAL_CHNL_NUM = 24, 
    parameter ADDRWIDTH = 32, 
    parameter DWIDTH = 40, 
    parameter SYNC_FIFO = 0
) (
    // Power and Ground
    inout           vddc1,
    inout           vddc2,
    inout           vddtx,
    inout           vss,

    // Clocks and Resets
    input           i_w_m_wr_rst_n,
    input           i_w_s_wr_rst_n,
    input [1:0]     lane_clk_a, 
    input [1:0]     lane_clk_b,
    input           rst_phy_n,
    input           clk_phy,
    input           clk_p_div2,
    input           clk_p_div4,
    
    input           ms_wr_clk,
    input           ms_rd_clk,
    input           ms_fwd_clk,
    
    input           sl_wr_clk,
    input           sl_rd_clk,
    input           sl_fwd_clk,

    // Status Outputs
    output          tx_online,
    output          rx_online,
    output [1:0]    test_done,
    
    // CSR Interface
    input  [31:0]   i_wr_addr, 
    input  [31:0]   i_wrdata, 
    input           i_wren, 
    input           i_rden,
    output          o_master_readdatavalid,
    output [31:0]   o_master_readdata,  
    output          o_master_waitrequest,
    
    // AIB Clocks
    input           avmm_clk, 
    input           osc_clk,

    // Leader AVMM Configuration Interface
    input           i_cfg_avmm_clk,
    input           i_cfg_avmm_rst_n,
    input [16:0]    i_cfg_avmm_addr,
    input [3:0]     i_cfg_avmm_byte_en,
    input           i_cfg_avmm_read,
    input           i_cfg_avmm_write,
    input [31:0]    i_cfg_avmm_wdata,
    output          o_cfg_avmm_rdatavld,
    output [31:0]   o_cfg_avmm_rdata,
    output          o_cfg_avmm_waitreq
);

// Wires for aib_axi_top_wrapper status and control
wire                        leader_ns_adapter_rstn;
wire                        leader_ns_mac_rdy;
wire                        leader_fs_mac_rdy;
wire                        leader_m_rx_align_done;
wire                        leader_avmm_rst_n;
wire                        follower_ns_adapter_rstn;
wire                        follower_ns_mac_rdy;
wire                        follower_fs_mac_rdy;
wire                        follower_m_rx_align_done;

// Wires for CSR and application logic
wire [31:0]                 delay_x_value;
wire [31:0]                 delay_y_value;
wire [31:0]                 delay_z_value;
wire [7:0]                  w_axi_rw_length;
wire [1:0]                  w_axi_rw_burst;
wire [2:0]                  w_axi_rw_size;
wire [ADDRWIDTH-1:0]        w_axi_rw_addr;
wire                        w_axi_wr;
wire                        w_axi_rd;

// Leader AXI-like User Interface Wires
wire [   3:   0]                w_user_arid          ;
wire [   2:   0]                w_user_arsize        ;
wire [   7:   0]                w_user_arlen         ;
wire [   1:   0]                w_user_arburst       ;
wire [  31:   0]                w_user_araddr        ;
wire                            w_user_arvalid       ;
wire                            w_user_arready       ;
wire [   3:   0]                w_user_awid           ;
wire [   2:   0]                w_user_awsize         ;
wire [   7:   0]                w_user_awlen          ;
wire [   1:   0]                w_user_awburst        ;
wire [  31:   0]                w_user_awaddr         ;
wire                            w_user_awvalid        ;
wire                            w_user_awready        ;
wire [   3:   0]                w_user_wid            ;
wire [ (DATAWIDTH)-1:   0]        w_user_wdata          ;
wire [  (DATAWIDTH/8)-1:   0]      w_user_wstrb          ;
wire                            w_user_wlast          ;
wire                            w_user_wvalid         ;
wire                            w_user_wready         ;
wire [   3:   0]                w_user_rid            ;
wire [ (DATAWIDTH)-1: 0]           w_user_rdata          ;
wire                            w_user_rlast          ;
wire [   1:   0]                w_user_rresp          ;
wire                            w_user_rvalid         ;
wire                            w_user_rready         ;
wire [   3:   0]                w_user_bid            ;
wire [   1:   0]                w_user_bresp          ;
wire                            w_user_bvalid         ;
wire                            w_user_bready         ;

// Follower AXI-like User Interface Wires
wire [3:0]                  w_F_user_arid   ;
wire [2:0]                  w_F_user_arsize ;
wire [7:0]                  w_F_user_arlen  ;
wire [1:0]                  w_F_user_arburst;
wire [31:0]                 w_F_user_araddr ;
wire                        w_F_user_arvalid;
wire                        w_F_user_arready;
wire [3:0]                  w_F_user_awid   ;
wire [2:0]                  w_F_user_awsize ;
wire [7:0]                  w_F_user_awlen  ;
wire [1:0]                  w_F_user_awburst ;
wire [31:0]                 w_F_user_awaddr ;
wire                        w_F_user_awvalid ;
wire                        w_F_user_awready ;
wire [3:0]                  w_F_user_wid    ;
wire [(DATAWIDTH)-1:0]         w_F_user_wdata  ;
wire [(DATAWIDTH/8)-1:0]       w_F_user_wstrb  ;
wire                        w_F_user_wlast  ;
wire                        w_F_user_wvalid ;
wire                        w_F_user_wready ;
wire [3:0]                  w_F_user_rid    ;
wire [(DATAWIDTH)-1:0]         w_F_user_rdata  ;
wire                        w_F_user_rlast  ;
wire [1:0]                  w_F_user_rresp  ;
wire                        w_F_user_rvalid ;
wire                        w_F_user_rready ;
wire [3:0]                  w_F_user_bid    ;
wire [1:0]                  w_F_user_bresp  ;
wire                        w_F_user_bvalid ;
wire                        w_F_user_bready ;

// Wires for Follower Application Memory Interface
wire [7:0]                  w_mem_wr_addr;
wire [7:0]                  w_mem_rd_addr;
wire [(DATAWIDTH)-1:0]         w_mem_wr_data;
wire [(DATAWIDTH)-1:0]         w_mem_rd_data;
wire                        w_mem_wr_en  ;
wire                        w_patgen_data_wr ;
wire                        w_read_complete ;
wire                        w_write_complete ;
wire [(DATAWIDTH)-1:0]         w_patgen_exp_dout;
wire [1:0]                  chkr_out;
wire [(DATAWIDTH)-1:0]         w_data_out_first;
wire                        w_data_out_first_valid;
wire [(DATAWIDTH)-1:0]         w_data_out_last;
wire                        w_data_out_last_valid;
wire [(DATAWIDTH)-1:0]         w_data_in_first;
wire                        w_data_in_first_valid;
wire [(DATAWIDTH)-1:0]         w_data_in_last;
wire                        w_data_in_last_valid;
wire [1:0]                  patchkr_out;
wire                        w_axist_rstn;


// Status signals based on AIB wrapper outputs
assign tx_online = leader_fs_mac_rdy & follower_fs_mac_rdy;
assign rx_online = leader_m_rx_align_done & follower_m_rx_align_done;
assign test_done = patchkr_out;

// Tie-off unused inputs for the wrapper
assign leader_ns_adapter_rstn = i_w_m_wr_rst_n;
assign leader_avmm_rst_n      = i_w_m_wr_rst_n; // Or a dedicated AVMM reset
assign leader_ns_mac_rdy      = 1'b1; // Assuming MAC is ready
assign follower_ns_adapter_rstn = i_w_s_wr_rst_n;
assign follower_ns_mac_rdy      = 1'b1; // Assuming MAC is ready


aib_axi_top_wrapper #(
    // --- Parameters ---
    .ACTIVE_CHNLS       (AXI_CHNL_NUM),
    .NBR_CHNLS          (TOTAL_CHNL_NUM),
    .LEADER_NBR_BUMPS   (102),
    .FOLLOWER_NBR_BUMPS (102),
    .NBR_PHASES         (4),
    .NBR_LANES          (40),
    .MS_SSR_LEN         (81),
    .SL_SSR_LEN         (73),
    .DWIDTH             (DWIDTH),
    .DATAWIDTH          (DATAWIDTH),
    .AXI_CHNL_NUM       (AXI_CHNL_NUM),
    .ADDRWIDTH          (ADDRWIDTH),
    .IDWIDTH            (4),
    .GEN2_MODE          (1'b1)
) aib_axi_top_wrapper_inst (
    // ========================================================================
    // Leader (Master Bridge) Interface
    // ========================================================================
    .leader_vddc1               ( vddc1 ),
    .leader_vddc2               ( vddc2 ),
    .leader_vddtx               ( vddtx ),
    .leader_vss                 ( vss ),
    .leader_m_wr_clk            ( ms_wr_clk ),
    .leader_m_rd_clk            ( ms_rd_clk ),
    .leader_m_fwd_clk           ( ms_fwd_clk ),
    .leader_i_osc_clk           ( osc_clk ),
    .leader_ns_adapter_rstn     ( leader_ns_adapter_rstn ),
    .leader_ns_mac_rdy          ( leader_ns_mac_rdy ),
    .leader_fs_mac_rdy          ( leader_fs_mac_rdy ),
    .leader_m_rx_align_done     ( leader_m_rx_align_done ),
    .leader_avmm_clk            ( avmm_clk ),
    .leader_avmm_rst_n          ( leader_avmm_rst_n ),
    .leader_i_cfg_avmm_clk      ( i_cfg_avmm_clk ),
    .leader_i_cfg_avmm_rst_n    ( i_cfg_avmm_rst_n ),
    .leader_i_cfg_avmm_addr     ( i_cfg_avmm_addr ),
    .leader_i_cfg_avmm_byte_en  ( i_cfg_avmm_byte_en ),
    .leader_i_cfg_avmm_read     ( i_cfg_avmm_read ),
    .leader_i_cfg_avmm_write    ( i_cfg_avmm_write ),
    .leader_i_cfg_avmm_wdata    ( i_cfg_avmm_wdata ),
    .leader_o_cfg_avmm_rdatavld ( o_cfg_avmm_rdatavld ),
    .leader_o_cfg_avmm_rdata    ( o_cfg_avmm_rdata ),
    .leader_o_cfg_avmm_waitreq  ( o_cfg_avmm_waitreq ),
    .leader_clk_wr              ( ms_wr_clk ),
    .leader_rst_wr_n            ( i_w_m_wr_rst_n ),
    .leader_init_ar_credit      ( 8'h10 ),
    .leader_init_aw_credit      ( 8'h10 ),
    .leader_init_w_credit       ( 8'h10 ),
    .leader_delay_x_value       ( delay_x_value ),
    .leader_delay_y_value       ( delay_y_value ),
    .leader_delay_z_value       ( delay_z_value ),

    // --- Leader AXI Slave Interface ---
    .s_axi_awid                 ( w_user_awid    ),
    .s_axi_awaddr               ( w_user_awaddr  ),
    .s_axi_awlen                ( w_user_awlen   ),
    .s_axi_awsize               ( w_user_awsize  ),
    .s_axi_awburst              ( w_user_awburst ),
    .s_axi_awvalid              ( w_user_awvalid ),
    .s_axi_awready              ( w_user_awready ),
    .s_axi_wid                  ( w_user_wid     ),
    .s_axi_wdata                ( w_user_wdata   ),
    .s_axi_wstrb                ( w_user_wstrb   ),
    .s_axi_wlast                ( w_user_wlast   ),
    .s_axi_wvalid               ( w_user_wvalid  ),
    .s_axi_wready               ( w_user_wready  ),
    .s_axi_bid                  ( w_user_bid     ),
    .s_axi_bresp                ( w_user_bresp   ),
    .s_axi_bvalid               ( w_user_bvalid  ),
    .s_axi_bready               ( w_user_bready  ),
    .s_axi_arid                 ( w_user_arid    ),
    .s_axi_araddr               ( w_user_araddr  ),
    .s_axi_arlen                ( w_user_arlen   ),
    .s_axi_arsize               ( w_user_arsize  ),
    .s_axi_arburst              ( w_user_arburst ),
    .s_axi_arvalid              ( w_user_arvalid ),
    .s_axi_arready              ( w_user_arready ),
    .s_axi_rid                  ( w_user_rid     ),
    .s_axi_rdata                ( w_user_rdata   ),
    .s_axi_rresp                ( w_user_rresp   ),
    .s_axi_rlast                ( w_user_rlast   ),
    .s_axi_rvalid               ( w_user_rvalid  ),
    .s_axi_rready               ( w_user_rready  ),

    // ========================================================================
    // Follower (Slave Bridge) Interface
    // ========================================================================
    .follower_vddc1             ( vddc1 ),
    .follower_vddc2             ( vddc2 ),
    .follower_vddtx             ( vddtx ),
    .follower_vss               ( vss ),
    .follower_m_wr_clk          ( sl_wr_clk ),
    .follower_m_rd_clk          ( sl_rd_clk ),
    .follower_m_fwd_clk         ( sl_fwd_clk ),
    .follower_ns_adapter_rstn   ( follower_ns_adapter_rstn ),
    .follower_ns_mac_rdy        ( follower_ns_mac_rdy ),
    .follower_fs_mac_rdy        ( follower_fs_mac_rdy ),
    .follower_m_rx_align_done   ( follower_m_rx_align_done ),
    .follower_clk_wr            ( sl_wr_clk ),
    .follower_rst_wr_n          ( i_w_s_wr_rst_n ),
    .follower_init_r_credit     ( 8'h10 ),
    .follower_init_b_credit     ( 8'h10 ),
    .follower_delay_x_value     ( delay_x_value ),
    .follower_delay_y_value     ( delay_y_value ),
    .follower_delay_z_value     ( delay_z_value ),

    // --- Follower AXI Master Interface ---
    .m_axi_awid                 ( w_F_user_awid     ),
    .m_axi_awaddr               ( w_F_user_awaddr   ),
    .m_axi_awlen                ( w_F_user_awlen    ),
    .m_axi_awsize               ( w_F_user_awsize   ),
    .m_axi_awburst              ( w_F_user_awburst  ),
    .m_axi_awvalid              ( w_F_user_awvalid  ),
    .m_axi_awready              ( w_F_user_awready  ),
    .m_axi_wid                  ( w_F_user_wid      ),
    .m_axi_wdata                ( w_F_user_wdata    ),
    .m_axi_wstrb                ( w_F_user_wstrb    ),
    .m_axi_wlast                ( w_F_user_wlast    ),
    .m_axi_wvalid               ( w_F_user_wvalid   ),
    .m_axi_wready               ( w_F_user_wready   ),
    .m_axi_bid                  ( w_F_user_bid      ),
    .m_axi_bresp                ( w_F_user_bresp    ),
    .m_axi_bvalid               ( w_F_user_bvalid   ),
    .m_axi_bready               ( w_F_user_bready   ),
    .m_axi_arid                 ( w_F_user_arid     ),
    .m_axi_araddr               ( w_F_user_araddr   ),
    .m_axi_arlen                ( w_F_user_arlen    ),
    .m_axi_arsize               ( w_F_user_arsize   ),
    .m_axi_arburst              ( w_F_user_arburst  ),
    .m_axi_arvalid              ( w_F_user_arvalid  ),
    .m_axi_arready              ( w_F_user_arready  ),
    .m_axi_rid                  ( w_F_user_rid      ),
    .m_axi_rdata                ( w_F_user_rdata    ),
    .m_axi_rresp                ( w_F_user_rresp    ),
    .m_axi_rlast                ( w_F_user_rlast    ),
    .m_axi_rvalid               ( w_F_user_rvalid   ),
    .m_axi_rready               ( w_F_user_rready   )
);


aximm_leader_app#(
    .AXI_CHNL_NUM(AXI_CHNL_NUM),
    .ADDRWIDTH(ADDRWIDTH),
    .DWIDTH(DWIDTH)
) aximm_leader_user_intf(
    .clk(ms_wr_clk),
    .rst_n(i_w_m_wr_rst_n),
    .axi_rw_length       (w_axi_rw_length),
    .axi_rw_burst        (w_axi_rw_burst ),
    .axi_rw_size         (w_axi_rw_size  ),
    .axi_rw_addr         (w_axi_rw_addr  ),
    .axi_wr              (w_axi_wr        ),
    .axi_rd              (w_axi_rd        ),
    .data_out_first      (w_data_out_first),
    .data_out_first_valid(w_data_out_first_valid),
    .data_out_last       (w_data_out_last),
    .data_out_last_valid (w_data_out_last_valid),
    .patgen_data_wr      (w_patgen_data_wr ),
    .patgen_exp_dout     (w_patgen_exp_dout),
    .write_complete      (w_write_complete),
    .user_arid           (w_user_arid     ),
    .user_arsize         (w_user_arsize   ),
    .user_arlen          (w_user_arlen    ),
    .user_arburst        (w_user_arburst  ),
    .user_araddr         (w_user_araddr   ),
    .user_arvalid        (w_user_arvalid  ),
    .user_arready        (w_user_arready  ),
    .user_awid           (w_user_awid     ),
    .user_awsize         (w_user_awsize   ),
    .user_awlen          (w_user_awlen    ),
    .user_awburst        (w_user_awburst  ),
    .user_awaddr         (w_user_awaddr   ),
    .user_awvalid        (w_user_awvalid  ),
    .user_awready        (w_user_awready  ),
    .user_wid            (w_user_wid      ),
    .user_wdata          (w_user_wdata    ),
    .user_wstrb          (w_user_wstrb    ),
    .user_wlast          (w_user_wlast    ),
    .user_wvalid         (w_user_wvalid   ),
    .user_wready         (w_user_wready   ),
    .user_rid            (w_user_rid      ),
    .user_rdata          (w_user_rdata    ),
    .user_rlast          (w_user_rlast    ),
    .user_rresp          (w_user_rresp    ),
    .user_rvalid         (w_user_rvalid   ),
    .user_rready         (w_user_rready   ),
    .user_bid            (w_user_bid      ),
    .user_bresp          (w_user_bresp    ),
    .user_bvalid         (w_user_bvalid   ),
    .user_bready         (w_user_bready   )
);

aximm_follower_app #(
    .AXI_CHNL_NUM(AXI_CHNL_NUM),
    .DWIDTH(DWIDTH),
    .ADDRWIDTH (ADDRWIDTH)
) aximm_follower_user_intf(
    .clk(sl_wr_clk), // Follower app should use follower clock
    .rst_n(i_w_s_wr_rst_n), // and follower reset
    .mem_wr_addr        (w_mem_wr_addr),
    .mem_wr_data        (w_mem_wr_data),
    .mem_wr_en          (w_mem_wr_en  ),
    .mem_rd_data        (w_mem_rd_data),
    .mem_rd_addr        (w_mem_rd_addr),
    .read_complete      (w_read_complete),
    .data_in_first      (w_data_in_first),
    .data_in_first_valid(w_data_in_first_valid),
    .data_in_last       (w_data_in_last),
    .data_in_last_valid (w_data_in_last_valid),
    .F_user_arid           (w_F_user_arid   ),
    .F_user_arsize         (w_F_user_arsize ),
    .F_user_arlen          (w_F_user_arlen  ),
    .F_user_arburst        (w_F_user_arburst),
    .F_user_araddr         (w_F_user_araddr ),
    .F_user_arvalid        (w_F_user_arvalid),
    .F_user_arready        (w_F_user_arready),
    .F_user_awid           (w_F_user_awid   ),
    .F_user_awsize         (w_F_user_awsize ),
    .F_user_awlen          (w_F_user_awlen  ),
    .F_user_awburst        (w_F_user_awburst),
    .F_user_awaddr         (w_F_user_awaddr ),
    .F_user_awvalid        (w_F_user_awvalid),
    .F_user_awready        (w_F_user_awready),
    .user_wid              (w_F_user_wid   ),
    .user_wdata            (w_F_user_wdata ),
    .user_wstrb            (w_F_user_wstrb ),
    .user_wlast            (w_F_user_wlast ),
    .user_wvalid           (w_F_user_wvalid),
    .user_wready           (w_F_user_wready),
    .F_user_rid            (w_F_user_rid   ),
    .F_user_rdata          (w_F_user_rdata ),
    .F_user_rlast          (w_F_user_rlast ),
    .F_user_rresp          (w_F_user_rresp ),
    .F_user_rvalid         (w_F_user_rvalid),
    .F_user_rready         (w_F_user_rready),
    .F_user_bid            (w_F_user_bid   ),
    .F_user_bresp          (w_F_user_bresp ),
    .F_user_bvalid         (w_F_user_bvalid),
    .F_user_bready         (w_F_user_bready)
);

syncfifo_mem1r1w #(
    .FIFO_WIDTH_WID(DWIDTH),
    .FIFO_DEPTH_WID(256)
) ram_mem(
   .rddata(w_mem_rd_data),
   .clk_write(sl_wr_clk), // Memory should be on follower clock domain
   .clk_read(sl_wr_clk),
   .rst_write_n(i_w_s_wr_rst_n),
   .rst_read_n(i_w_s_wr_rst_n),
   .rdaddr(w_mem_rd_addr),
   .wraddr(w_mem_wr_addr),
   .wrdata(w_mem_wr_data),
   .wrstrobe(w_mem_wr_en)
);

axi_mm_patchkr_top #(.AXI_CHNL_NUM(AXI_CHNL_NUM)) 
aximm_patchkr(
    .rdclk (ms_wr_clk),
    .wrclk (ms_wr_clk),
    .rst_n (i_w_m_wr_rst_n),
    .patchkr_en (w_axi_wr),
    .patgen_cnt (w_axi_rw_length),
    .patgen_din(w_patgen_exp_dout),
    .patgen_din_wr(w_patgen_data_wr),
    .cntuspatt_en(1'b0),
    .chkr_fifo_full(),
    .axist_valid(w_F_user_rvalid),
    .axist_rcv_data(w_F_user_rdata),
    .axist_tready(w_F_user_rready),
    .patchkr_out(patchkr_out) // Changed from chkr_out to match output port
);

axi_mm_csr #(.AXI_CHNL_NUM(AXI_CHNL_NUM)) u_axi_mm_csr(
    .clk(ms_wr_clk),    
    .rst_n(i_w_m_wr_rst_n),
    .master_address(i_wr_addr),      
    .master_readdata(o_master_readdata),     
    .master_read(i_rden),         
    .master_write(i_wren),        
    .master_writedata(i_wrdata),    
    .master_waitrequest(o_master_waitrequest),  
    .master_readdatavalid(o_master_readdatavalid),
    .master_byteenable(),                           
    .data_out_first      (w_data_out_first       ),                     
    .data_out_first_valid(w_data_out_first_valid),                      
    .data_out_last       (w_data_out_last        ),                     
    .data_out_last_valid (w_data_out_last_valid ),  
    .data_in_first(w_data_in_first),
    .data_in_first_valid(w_data_in_first_valid),
    .data_in_last(w_data_in_last),
    .data_in_last_valid(w_data_in_last_valid),
    .o_delay_x_value(delay_x_value),            
    .o_delay_y_value(delay_y_value),             
    .o_delay_z_value(delay_z_value),             
    .chkr_pass(patchkr_out), // Changed from chkr_out
    .align_error(1'b0), // Tied off
    .f2l_align_error(1'b0), // Tied off
    .ldr_tx_online(leader_fs_mac_rdy),
    .ldr_rx_online(leader_m_rx_align_done),
    .fllr_tx_online(follower_fs_mac_rdy),
    .fllr_rx_online(follower_m_rx_align_done),
    .read_complete(w_read_complete),
    .write_complete(w_write_complete),
    .axist_rstn_out(w_axist_rstn),
    .aximm_wr(w_axi_wr),
    .aximm_rd(w_axi_rd),
    .aximm_rw_length(w_axi_rw_length),
    .aximm_rw_burst(w_axi_rw_burst),
    .aximm_rw_size(w_axi_rw_size),
    .aximm_rw_addr(w_axi_rw_addr)
);

endmodule
