// ============================================================================
// Description: Top-Level AIB to AXI Integration Module
//
// Purpose:
// This module integrates the AIB leader (master) and follower (slave) AXI
// bridges with an EMIB interconnect. It serves as the complete top-level
// file for the AIB-AXI system, exposing the AXI interfaces and control
// signals for both sides.
//
// Instantiates:
// 1. top_aib_axi_bridge_master_wrapper (Leader)
// 2. aib_axi_slave_gen1_wrapper (Follower)
// 3. emib_m2s1_wrapper (EMIB Interconnect)
// ============================================================================

`include "axi_if.v" // Assumed to be included by the project tool

module aib_axi_ch_top #(
    // --- Parameters for both Leader and Follower ---
    parameter LEADER_NBR_BUMPS  = 102,
    parameter FOLLOWER_NBR_BUMPS= 102,
    parameter NBR_PHASES        = 4,
    parameter NBR_LANES         = 40,
    parameter MS_SSR_LEN        = 81,
    parameter SL_SSR_LEN        = 73,
    parameter DWIDTH            = 40,
    parameter AXI_CHNL_NUM      = 1,
    parameter ADDRWIDTH         = 32,
    parameter IDWIDTH           = 4,
    parameter GEN2_MODE         = 1'b1,
    parameter AVMM_WIDTH        = 32,
    parameter BYTE_WIDTH        = 4
) (
    // ========================================================================
    // Leader (AIB Master) Side Interface
    // Exposes an AXI SLAVE interface to the user.
    // ========================================================================

    // --- Leader Power ---
    inout leader_vddc1,
    inout leader_vddc2,
    inout leader_vddtx,
    inout leader_vss,

    // --- Leader AIB/MAC Clocks & Resets ---
    input   leader_m_wr_clk,
    input   leader_m_rd_clk,
    input   leader_m_fwd_clk,
    input   leader_i_osc_clk,
    // --- Control
    input   leader_ns_adapter_rstn,
    input   leader_ns_mac_rdy,
    output  leader_fs_mac_rdy,
    output  leader_m_rx_align_done,
    input   leader_ms_rx_dcc_dll_lock_req,
    input   leader_ms_tx_dcc_dll_lock_req,
    input   leader_sl_rx_dcc_dll_lock_req,
    input   leader_sl_tx_dcc_dll_lock_req,
    input   leader_m_por_ovrd,
    input   leader_m_device_detect_ovrd,
    input   leader_i_m_power_on_reset,
    output  leader_m_device_detect,
    output  leader_o_m_power_on_reset,

    // --- Leader Avalon MM Interface ---
    // input leader_avmm_clk,
    // input leader_avmm_rst_n,
    input                   leader_i_cfg_avmm_clk,
    input                   leader_i_cfg_avmm_rst_n,
    input [16:0]            leader_i_cfg_avmm_addr,
    input [BYTE_WIDTH-1:0]  leader_i_cfg_avmm_byte_en,
    input                   leader_i_cfg_avmm_read,
    input                   leader_i_cfg_avmm_write,
    input [AVMM_WIDTH-1:0]  leader_i_cfg_avmm_wdata,
    output                  leader_o_cfg_avmm_rdatavld,
    output [AVMM_WIDTH-1:0] leader_o_cfg_avmm_rdata,
    output                  leader_o_cfg_avmm_waitreq,

    // --- Leader AXI-MM Clocks & Control ---
    input leader_clk_wr,
    input leader_rst_wr_n,
    input [7:0] leader_init_ar_credit,
    input [7:0] leader_init_aw_credit,
    input [7:0] leader_init_w_credit,
    input [15:0] leader_delay_x_value,
    input [15:0] leader_delay_y_value,
    input [15:0] leader_delay_z_value,

    // --- Leader's AXI Slave Interface (s_axi_*) ---
    input  [IDWIDTH-1:0]     s_axi_awid,
    input  [ADDRWIDTH-1:0]   s_axi_awaddr,
    input  [7:0]             s_axi_awlen,
    input  [2:0]             s_axi_awsize,
    input  [1:0]             s_axi_awburst,
    input                    s_axi_awvalid,
    output                   s_axi_awready,
    input  [IDWIDTH-1:0]     s_axi_wid,
    input  [127:0]           s_axi_wdata,
    input  [15:0]            s_axi_wstrb,
    input                    s_axi_wlast,
    input                    s_axi_wvalid,
    output                   s_axi_wready,
    output [IDWIDTH-1:0]     s_axi_bid,
    output [1:0]             s_axi_bresp,
    output                   s_axi_bvalid,
    input                    s_axi_bready,
    input  [IDWIDTH-1:0]     s_axi_arid,
    input  [ADDRWIDTH-1:0]   s_axi_araddr,
    input  [7:0]             s_axi_arlen,
    input  [2:0]             s_axi_arsize,
    input  [1:0]             s_axi_arburst,
    input                    s_axi_arvalid,
    output                   s_axi_arready,
    output [IDWIDTH-1:0]     s_axi_rid,
    output [127:0]           s_axi_rdata,
    output [1:0]             s_axi_rresp,
    output                   s_axi_rlast,
    output                   s_axi_rvalid,
    input                    s_axi_rready,


    // ========================================================================
    // Follower (AIB Slave) Side Interface
    // Exposes an AXI MASTER interface to the user.
    // ========================================================================

    // --- Follower Power ---
    inout follower_vddc1,
    inout follower_vddc2,
    inout follower_vddtx,
    inout follower_vss,

    // --- Follower AIB/MAC Clocks & Resets ---
    input   follower_m_wr_clk,
    input   follower_m_rd_clk,
    input   follower_m_fwd_clk,
    input   follower_ns_adapter_rstn,
    input   follower_ns_mac_rdy,
    output  follower_fs_mac_rdy,
    output  follower_m_rx_align_done,
    output  follower_ms_tx_transfer_en,
    output  follower_sl_tx_transfer_en,
    input   follower_ms_rx_dcc_dll_lock_req,
    input   follower_ms_tx_dcc_dll_lock_req,
    input   follower_sl_rx_dcc_dll_lock_req,
    input   follower_sl_tx_dcc_dll_lock_req,
    input   follower_m_por_ovrd,
    input   follower_m_device_detect_ovrd,
    input   follower_i_m_power_on_reset,
    output  follower_m_device_detect,
    output  follower_o_m_power_on_reset,

    // --- Follower AXI-MM Clocks & Control ---
    input follower_clk_wr,
    input follower_rst_wr_n,
    input [7:0]  follower_init_r_credit,
    input [7:0]  follower_init_b_credit,
    input [15:0] follower_delay_x_value,
    input [15:0] follower_delay_y_value,
    input [15:0] follower_delay_z_value,

    // input  follower_avmm_clk,
    // input  follower_avmm_rst_n,
    input                   follower_i_cfg_avmm_clk,
    input                   follower_i_cfg_avmm_rst_n,
    input  [16:0]           follower_i_cfg_avmm_addr,
    input  [BYTE_WIDTH-1:0] follower_i_cfg_avmm_byte_en,
    input                   follower_i_cfg_avmm_read,
    input                   follower_i_cfg_avmm_write,
    input  [AVMM_WIDTH-1:0] follower_i_cfg_avmm_wdata,
    output                  follower_o_cfg_avmm_rdatavld,
    output [AVMM_WIDTH-1:0] follower_o_cfg_avmm_rdata,
    output                  follower_o_cfg_avmm_waitreq,


    // --- Follower's AXI Master Interface (m_axi_*) ---
    output [IDWIDTH-1:0]     m_axi_awid,
    output [ADDRWIDTH-1:0]   m_axi_awaddr,
    output [7:0]             m_axi_awlen,
    output [2:0]             m_axi_awsize,
    output [1:0]             m_axi_awburst,
    output                   m_axi_awvalid,
    input                    m_axi_awready,
    output [IDWIDTH-1:0]     m_axi_wid,
    output [127:0]           m_axi_wdata,
    output [15:0]            m_axi_wstrb,
    output                   m_axi_wlast,
    output                   m_axi_wvalid,
    input                    m_axi_wready,
    input  [IDWIDTH-1:0]     m_axi_bid,
    input  [1:0]             m_axi_bresp,
    input                    m_axi_bvalid,
    output                   m_axi_bready,
    output [IDWIDTH-1:0]     m_axi_arid,
    output [ADDRWIDTH-1:0]   m_axi_araddr,
    output [7:0]             m_axi_arlen,
    output [2:0]             m_axi_arsize,
    output [1:0]             m_axi_arburst,
    output                   m_axi_arvalid,
    input                    m_axi_arready,
    input  [IDWIDTH-1:0]     m_axi_rid,
    input  [127:0]           m_axi_rdata,
    input  [1:0]             m_axi_rresp,
    input                    m_axi_rlast,
    input                    m_axi_rvalid,
    output                   m_axi_rready
);

    // ============================================================================
    // Internal Wires for EMIB Connection
    // ============================================================================
    wire [LEADER_NBR_BUMPS-1:0]   m_ch_aib;
    wire [FOLLOWER_NBR_BUMPS-1:0] s_ch_aib;
    
    // Aux signals are 1-bit wide
    wire device_detect;
    wire power_on_reset;

    axi_if #(

    ) ld_axi_if();

    axi_if #(

    ) fl_axi_if();

    // ============================================================================
    // Leader (AIB Master) Bridge Instantiation
    // This module is an AIB MASTER, but an AXI SLAVE.
    // ============================================================================
    aib_axi_leader_ch #(
        .NBR_BUMPS       (LEADER_NBR_BUMPS),
        .NBR_PHASES      (NBR_PHASES),
        .NBR_LANES       (NBR_LANES),
        .MS_SSR_LEN      (MS_SSR_LEN),
        .SL_SSR_LEN      (SL_SSR_LEN),
        .DWIDTH          (DWIDTH),
        .AXI_CHNL_NUM    (AXI_CHNL_NUM),
        .ADDRWIDTH       (ADDRWIDTH),
        //.IDWIDTH         (IDWIDTH),
        .GEN2_MODE       (GEN2_MODE),
        .AVMM_WIDTH      (AVMM_WIDTH),
        .BYTE_WIDTH      (BYTE_WIDTH)
    ) u_leader_bridge (
        .vddc1(leader_vddc1),
        .vddc2(leader_vddc2),
        .vddtx(leader_vddtx),
        .vss(leader_vss),

        // EMIB Connections
        .iopad_aib(m_ch_aib),
        .iopad_device_detect(device_detect),
        .iopad_power_on_reset(power_on_reset),

        // AIB/MAC Interface
        .m_wr_clk(leader_m_wr_clk),
        .m_rd_clk(leader_m_rd_clk),
        .m_fwd_clk(leader_m_fwd_clk),
        .i_osc_clk(leader_i_osc_clk),
        .ns_adapter_rstn(leader_ns_adapter_rstn),
        .ns_mac_rdy(leader_ns_mac_rdy),
        .fs_mac_rdy(leader_fs_mac_rdy),
        .m_rx_align_done(leader_m_rx_align_done),
        .ms_rx_dcc_dll_lock_req(leader_ms_rx_dcc_dll_lock_req),
        .ms_tx_dcc_dll_lock_req(leader_ms_tx_dcc_dll_lock_req),
        .sl_rx_dcc_dll_lock_req(leader_sl_rx_dcc_dll_lock_req),
        .sl_tx_dcc_dll_lock_req(leader_sl_tx_dcc_dll_lock_req),

        .m_por_ovrd(leader_m_por_ovrd),
        .m_device_detect_ovrd(leader_m_device_detect_ovrd),
        .i_m_power_on_reset(leader_i_m_power_on_reset),
        .m_device_detect(leader_m_device_detect),
        .o_m_power_on_reset(leader_o_m_power_on_reset),

        // Avalon MM Interface
        // .avmm_clk(leader_avmm_clk),
        // .avmm_rst_n(leader_avmm_rst_n),
        .i_cfg_avmm_clk(leader_i_cfg_avmm_clk),
        .i_cfg_avmm_rst_n(leader_i_cfg_avmm_rst_n),
        .i_cfg_avmm_addr(leader_i_cfg_avmm_addr),
        .i_cfg_avmm_byte_en(leader_i_cfg_avmm_byte_en),
        .i_cfg_avmm_read(leader_i_cfg_avmm_read),
        .i_cfg_avmm_write(leader_i_cfg_avmm_write),
        .i_cfg_avmm_wdata(leader_i_cfg_avmm_wdata),
        .o_cfg_avmm_rdatavld(leader_o_cfg_avmm_rdatavld),
        .o_cfg_avmm_rdata(leader_o_cfg_avmm_rdata),
        .o_cfg_avmm_waitreq(leader_o_cfg_avmm_waitreq),

        // AXI-MM Interface
        .clk_wr(leader_clk_wr),
        .rst_wr_n(leader_rst_wr_n),
        .init_ar_credit(leader_init_ar_credit),
        .init_aw_credit(leader_init_aw_credit),
        .init_w_credit(leader_init_w_credit),
        .delay_x_value(leader_delay_x_value),
        .delay_y_value(leader_delay_y_value),
        .delay_z_value(leader_delay_z_value),

        // AXI Slave Interface
        .user_axi_if(ld_axi_if)
    );


    // ============================================================================
    // Follower (AIB Slave) Bridge Instantiation
    // This module is an AIB SLAVE, but an AXI MASTER.
    // ============================================================================
    aib_axi_follower_ch #(
        .NBR_BUMPS       (FOLLOWER_NBR_BUMPS),
        .NBR_PHASES      (NBR_PHASES),
        .NBR_LANES       (NBR_LANES),
        .MS_SSR_LEN      (MS_SSR_LEN),
        .SL_SSR_LEN      (SL_SSR_LEN),
        .DWIDTH          (DWIDTH),
        .AXI_CHNL_NUM    (AXI_CHNL_NUM),
        .ADDRWIDTH       (ADDRWIDTH),
        //.IDWIDTH         (IDWIDTH),
        .GEN2_MODE       (GEN2_MODE),
        .AVMM_WIDTH      (AVMM_WIDTH),
        .BYTE_WIDTH      (BYTE_WIDTH)
    ) u_follower_bridge (
        .vddc1(follower_vddc1),
        .vddc2(follower_vddc2),
        .vddtx(follower_vddtx),
        .vss(follower_vss),

        // EMIB Connections
        .iopad_aib(s_ch_aib),
        .iopad_device_detect(device_detect),
        .iopad_power_on_reset(power_on_reset),

        // AIB/MAC Interface
        .m_wr_clk(follower_m_wr_clk),
        .m_rd_clk(follower_m_rd_clk),
        .m_fwd_clk(follower_m_fwd_clk),
        .ns_adapter_rstn(follower_ns_adapter_rstn),
        .ns_mac_rdy(follower_ns_mac_rdy),
        .fs_mac_rdy(follower_fs_mac_rdy),
        .m_rx_align_done(follower_m_rx_align_done),
        .ms_tx_transfer_en(follower_ms_tx_transfer_en),
        .sl_tx_transfer_en(follower_sl_tx_transfer_en),
        .ms_rx_dcc_dll_lock_req(follower_ms_rx_dcc_dll_lock_req),
        .ms_tx_dcc_dll_lock_req(follower_ms_tx_dcc_dll_lock_req),
        .sl_rx_dcc_dll_lock_req(follower_sl_rx_dcc_dll_lock_req),
        .sl_tx_dcc_dll_lock_req(follower_sl_tx_dcc_dll_lock_req),
        
        .m_por_ovrd(follower_m_por_ovrd),
        .m_device_detect_ovrd(follower_m_device_detect_ovrd),
        .i_m_power_on_reset(follower_i_m_power_on_reset),
        .m_device_detect(follower_m_device_detect),
        .o_m_power_on_reset(follower_o_m_power_on_reset),

        // AXI-MM Interface
        .clk_wr(follower_clk_wr),
        .rst_wr_n(follower_rst_wr_n),
        .init_r_credit(follower_init_r_credit),
        .init_b_credit(follower_init_b_credit),
        .delay_x_value(follower_delay_x_value),
        .delay_y_value(follower_delay_y_value),
        .delay_z_value(follower_delay_z_value),

        // Avalon MM Interface
        // .avmm_clk(follower_avmm_clk),
        // .avmm_rst_n(follower_avmm_rst_n),
        .i_cfg_avmm_clk(follower_i_cfg_avmm_clk),
        .i_cfg_avmm_rst_n(follower_i_cfg_avmm_rst_n),
        .i_cfg_avmm_addr(follower_i_cfg_avmm_addr),
        .i_cfg_avmm_byte_en(follower_i_cfg_avmm_byte_en),
        .i_cfg_avmm_read(follower_i_cfg_avmm_read),
        .i_cfg_avmm_write(follower_i_cfg_avmm_write),
        .i_cfg_avmm_wdata(follower_i_cfg_avmm_wdata),
        .o_cfg_avmm_rdatavld(follower_o_cfg_avmm_rdatavld),
        .o_cfg_avmm_rdata(follower_o_cfg_avmm_rdata),
        .o_cfg_avmm_waitreq(follower_o_cfg_avmm_waitreq),

        // AXI Master Interface
        .user_axi_if(fl_axi_if)
    );


    // ============================================================================
    // EMIB Interconnect Instantiation
    // ============================================================================
    emib_m2s2_wrapper u_emib_interconnect (
        // Connect Follower (slave) bridge to EMIB slave side
        .s_ch0_aib(s_ch_aib),

        // Connect Leader (master) bridge to EMIB master side
        .m_ch0_aib(m_ch_aib)
    );


    assign m_axi_awid          = fl_axi_if.awid;
    assign m_axi_awaddr        = fl_axi_if.awaddr;
    assign m_axi_awlen         = fl_axi_if.awlen;
    assign m_axi_awsize        = fl_axi_if.awsize;
    assign m_axi_awburst       = fl_axi_if.awburst;
    assign m_axi_awvalid       = fl_axi_if.awvalid;
    assign fl_axi_if.awready   = m_axi_awready;
    assign m_axi_wid           = fl_axi_if.wid;
    assign m_axi_wdata         = fl_axi_if.wdata;
    assign m_axi_wstrb         = fl_axi_if.wstrb;
    assign m_axi_wlast         = fl_axi_if.wlast;
    assign m_axi_wvalid        = fl_axi_if.wvalid;
    assign fl_axi_if.wready    = m_axi_wready;
    assign fl_axi_if.bid       = m_axi_bid;
    assign fl_axi_if.bresp     = m_axi_bresp;
    assign fl_axi_if.bvalid    = m_axi_bvalid;
    assign m_axi_bready        = fl_axi_if.bready;
    assign m_axi_arid          = fl_axi_if.arid;
    assign m_axi_araddr        = fl_axi_if.araddr;
    assign m_axi_arlen         = fl_axi_if.arlen;
    assign m_axi_arsize        = fl_axi_if.arsize;
    assign m_axi_arburst       = fl_axi_if.arburst;
    assign m_axi_arvalid       = fl_axi_if.arvalid;
    assign fl_axi_if.arready   = m_axi_arready;
    assign fl_axi_if.rid       = m_axi_rid;
    assign fl_axi_if.rdata     = m_axi_rdata;
    assign fl_axi_if.rresp     = m_axi_rresp;
    assign fl_axi_if.rlast     = m_axi_rlast;
    assign fl_axi_if.rvalid    = m_axi_rvalid;
    assign m_axi_rready        = fl_axi_if.rready;

    assign ld_axi_if.awid      = s_axi_awid;
    assign ld_axi_if.awaddr    = s_axi_awaddr;
    assign ld_axi_if.awlen     = s_axi_awlen;
    assign ld_axi_if.awsize    = s_axi_awsize;
    assign ld_axi_if.awburst   = s_axi_awburst;
    assign ld_axi_if.awvalid   = s_axi_awvalid;
    assign s_axi_awready       = ld_axi_if.awready;
    assign ld_axi_if.wid       = s_axi_wid;
    assign ld_axi_if.wdata     = s_axi_wdata;
    assign ld_axi_if.wstrb     = s_axi_wstrb;
    assign ld_axi_if.wlast     = s_axi_wlast;
    assign ld_axi_if.wvalid    = s_axi_wvalid;
    assign s_axi_wready        = ld_axi_if.wready;
    assign s_axi_bid           = ld_axi_if.bid;
    assign s_axi_bresp         = ld_axi_if.bresp;
    assign s_axi_bvalid        = ld_axi_if.bvalid;
    assign ld_axi_if.bready    = s_axi_bready;
    assign ld_axi_if.arid      = s_axi_arid;
    assign ld_axi_if.araddr    = s_axi_araddr;
    assign ld_axi_if.arlen     = s_axi_arlen;
    assign ld_axi_if.arsize    = s_axi_arsize;
    assign ld_axi_if.arburst   = s_axi_arburst;
    assign ld_axi_if.arvalid   = s_axi_arvalid;
    assign s_axi_arready       = ld_axi_if.arready;
    assign s_axi_rid           = ld_axi_if.rid;
    assign s_axi_rdata         = ld_axi_if.rdata;
    assign s_axi_rresp         = ld_axi_if.rresp;
    assign s_axi_rlast         = ld_axi_if.rlast;
    assign s_axi_rvalid        = ld_axi_if.rvalid;
    assign ld_axi_if.rready    = s_axi_rready;

endmodule