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

// `include "axi_if.v" // Assumed to be included by the project tool

module aib_axi_m2s2_top #(
    // --- Parameters for both Leader and Follower ---
    parameter ACTIVE_CHNLS      = 1,
    parameter NBR_CHNLS         = 24,
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
    parameter GEN2_MODE         = 1'b1
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
    input                   leader_i_osc_clk,
    // --- Control
    input  [NBR_CHNLS-1: 0] leader_ns_adapter_rstn,
    input  [NBR_CHNLS-1: 0] leader_ns_mac_rdy,
    output [NBR_CHNLS-1: 0] leader_fs_mac_rdy,
    output [NBR_CHNLS-1: 0] leader_m_rx_align_done,

    // --- Leader Avalon MM Interface ---
    input leader_avmm_clk,
    input leader_avmm_rst_n,
    input leader_i_cfg_avmm_clk,
    input leader_i_cfg_avmm_rst_n,
    input [16:0] leader_i_cfg_avmm_addr,
    input [3:0] leader_i_cfg_avmm_byte_en,
    input leader_i_cfg_avmm_read,
    input leader_i_cfg_avmm_write,
    input [31:0] leader_i_cfg_avmm_wdata,
    output leader_o_cfg_avmm_rdatavld,
    output [31:0] leader_o_cfg_avmm_rdata,
    output leader_o_cfg_avmm_waitreq,

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
    input  [NBR_CHNLS-1: 0] follower_ns_adapter_rstn,
    input  [NBR_CHNLS-1: 0] follower_ns_mac_rdy,
    output [NBR_CHNLS-1: 0] follower_fs_mac_rdy,
    output [NBR_CHNLS-1: 0] follower_m_rx_align_done,
    output [NBR_CHNLS-1:0] follower_ms_tx_transfer_en,
    output [NBR_CHNLS-1:0] follower_sl_tx_transfer_en,

    // --- Follower AXI-MM Clocks & Control ---
    input follower_clk_wr,
    input follower_rst_wr_n,
    input [7:0]  follower_init_r_credit,
    input [7:0]  follower_init_b_credit,
    input [15:0] follower_delay_x_value,
    input [15:0] follower_delay_y_value,
    input [15:0] follower_delay_z_value,

    input  follower_avmm_clk,
    input  follower_avmm_rst_n,
    input  follower_i_cfg_avmm_clk,
    input  follower_i_cfg_avmm_rst_n,
    input  [16:0] follower_i_cfg_avmm_addr,
    input  [3:0]  follower_i_cfg_avmm_byte_en,
    input         follower_i_cfg_avmm_read,
    input         follower_i_cfg_avmm_write,
    input  [31:0] follower_i_cfg_avmm_wdata,
    output        follower_o_cfg_avmm_rdatavld,
    output [31:0] follower_o_cfg_avmm_rdata,
    output        follower_o_cfg_avmm_waitreq,


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
    wire [LEADER_NBR_BUMPS-1:0]   m_ch_aib [0:23];
    wire [FOLLOWER_NBR_BUMPS-1:0] s_ch_aib [0:23];
    
    // Aux signals are 1-bit wide
    wire leader_device_detect;
    wire leader_power_on_reset;
    wire follower_device_detect;
    wire follower_power_on_reset;

    // ============================================================================
    // Leader (AIB Master) Bridge Instantiation
    // This module is an AIB MASTER, but an AXI SLAVE.
    // ============================================================================
    top_aib_axi_bridge_master_wrapper #(
        .ACTIVE_CHNLS    (ACTIVE_CHNLS),
        .NBR_CHNLS       (NBR_CHNLS),
        .NBR_BUMPS       (LEADER_NBR_BUMPS),
        .NBR_PHASES      (NBR_PHASES),
        .NBR_LANES       (NBR_LANES),
        .MS_SSR_LEN      (MS_SSR_LEN),
        .SL_SSR_LEN      (SL_SSR_LEN),
        .DWIDTH          (DWIDTH),
        .AXI_CHNL_NUM    (AXI_CHNL_NUM),
        .ADDRWIDTH       (ADDRWIDTH),
        .IDWIDTH         (IDWIDTH),
        .GEN2_MODE       (GEN2_MODE)
    ) u_leader_bridge (
        .vddc1(leader_vddc1),
        .vddc2(leader_vddc2),
        .vddtx(leader_vddtx),
        .vss(leader_vss),

        // EMIB Connections
        .iopad_ch0_aib(m_ch_aib[0]),
        .iopad_ch1_aib(m_ch_aib[1]),
        .iopad_ch2_aib(m_ch_aib[2]),
        .iopad_ch3_aib(m_ch_aib[3]),
        .iopad_ch4_aib(m_ch_aib[4]),
        .iopad_ch5_aib(m_ch_aib[5]),
        .iopad_ch6_aib(m_ch_aib[6]),
        .iopad_ch7_aib(m_ch_aib[7]),
        .iopad_ch8_aib(m_ch_aib[8]),
        .iopad_ch9_aib(m_ch_aib[9]),
        .iopad_ch10_aib(m_ch_aib[10]),
        .iopad_ch11_aib(m_ch_aib[11]),
        .iopad_ch12_aib(m_ch_aib[12]),
        .iopad_ch13_aib(m_ch_aib[13]),
        .iopad_ch14_aib(m_ch_aib[14]),
        .iopad_ch15_aib(m_ch_aib[15]),
        .iopad_ch16_aib(m_ch_aib[16]),
        .iopad_ch17_aib(m_ch_aib[17]),
        .iopad_ch18_aib(m_ch_aib[18]),
        .iopad_ch19_aib(m_ch_aib[19]),
        .iopad_ch20_aib(m_ch_aib[20]),
        .iopad_ch21_aib(m_ch_aib[21]),
        .iopad_ch22_aib(m_ch_aib[22]),
        .iopad_ch23_aib(m_ch_aib[23]),
        .iopad_device_detect(leader_device_detect),
        .iopad_power_on_reset(leader_power_on_reset),

        // AIB/MAC Interface
        .m_wr_clk(leader_m_wr_clk),
        .m_rd_clk(leader_m_rd_clk),
        .m_fwd_clk(leader_m_fwd_clk),
        .i_osc_clk(leader_i_osc_clk),
        .ns_adapter_rstn(leader_ns_adapter_rstn),
        .ns_mac_rdy(leader_ns_mac_rdy),
        .fs_mac_rdy(leader_fs_mac_rdy),
        .m_rx_align_done(leader_m_rx_align_done),

        // Avalon MM Interface
        .avmm_clk(leader_avmm_clk),
        .avmm_rst_n(leader_avmm_rst_n),
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
        .s_axi_rready(s_axi_rready)
    );


    // ============================================================================
    // Follower (AIB Slave) Bridge Instantiation
    // This module is an AIB SLAVE, but an AXI MASTER.
    // ============================================================================
    top_aib_axi_bridge_slave_wrapper #(
        .ACTIVE_CHNLS    (ACTIVE_CHNLS),
        .NBR_CHNLS       (NBR_CHNLS),
        .NBR_BUMPS       (FOLLOWER_NBR_BUMPS),
        .NBR_PHASES      (NBR_PHASES),
        .NBR_LANES       (NBR_LANES),
        .MS_SSR_LEN      (MS_SSR_LEN),
        .SL_SSR_LEN      (SL_SSR_LEN),
        .DWIDTH          (DWIDTH),
        .AXI_CHNL_NUM    (AXI_CHNL_NUM),
        .ADDRWIDTH       (ADDRWIDTH),
        .IDWIDTH         (IDWIDTH),
        .GEN2_MODE       (GEN2_MODE)
    ) u_follower_bridge (
        .vddc1(follower_vddc1),
        .vddc2(follower_vddc2),
        .vddtx(follower_vddtx),
        .vss(follower_vss),

        // EMIB Connections
        .iopad_ch0_aib(s_ch_aib[0]),
        .iopad_ch1_aib(s_ch_aib[1]),
        .iopad_ch2_aib(s_ch_aib[2]),
        .iopad_ch3_aib(s_ch_aib[3]),
        .iopad_ch4_aib(s_ch_aib[4]),
        .iopad_ch5_aib(s_ch_aib[5]),
        .iopad_ch6_aib(s_ch_aib[6]),
        .iopad_ch7_aib(s_ch_aib[7]),
        .iopad_ch8_aib(s_ch_aib[8]),
        .iopad_ch9_aib(s_ch_aib[9]),
        .iopad_ch10_aib(s_ch_aib[10]),
        .iopad_ch11_aib(s_ch_aib[11]),
        .iopad_ch12_aib(s_ch_aib[12]),
        .iopad_ch13_aib(s_ch_aib[13]),
        .iopad_ch14_aib(s_ch_aib[14]),
        .iopad_ch15_aib(s_ch_aib[15]),
        .iopad_ch16_aib(s_ch_aib[16]),
        .iopad_ch17_aib(s_ch_aib[17]),
        .iopad_ch18_aib(s_ch_aib[18]),
        .iopad_ch19_aib(s_ch_aib[19]),
        .iopad_ch20_aib(s_ch_aib[20]),
        .iopad_ch21_aib(s_ch_aib[21]),
        .iopad_ch22_aib(s_ch_aib[22]),
        .iopad_ch23_aib(s_ch_aib[23]),
        .iopad_device_detect(follower_device_detect),
        .iopad_power_on_reset(follower_power_on_reset),

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

        // AXI-MM Interface
        .clk_wr(follower_clk_wr),
        .rst_wr_n(follower_rst_wr_n),
        .init_r_credit(follower_init_r_credit),
        .init_b_credit(follower_init_b_credit),
        .delay_x_value(follower_delay_x_value),
        .delay_y_value(follower_delay_y_value),
        .delay_z_value(follower_delay_z_value),

        // Avalon MM Interface
        .avmm_clk(follower_avmm_clk),
        .avmm_rst_n(follower_avmm_rst_n),
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


    // ============================================================================
    // EMIB Interconnect Instantiation
    // ============================================================================
    emib_m2s2_wrapper u_emib_interconnect (
        // Connect Follower (slave) bridge to EMIB slave side
        .s_ch0_aib(s_ch_aib[0]),
        .s_ch1_aib(s_ch_aib[1]),
        .s_ch2_aib(s_ch_aib[2]),
        .s_ch3_aib(s_ch_aib[3]),
        .s_ch4_aib(s_ch_aib[4]),
        .s_ch5_aib(s_ch_aib[5]),
        .s_ch6_aib(s_ch_aib[6]),
        .s_ch7_aib(s_ch_aib[7]),
        .s_ch8_aib(s_ch_aib[8]),
        .s_ch9_aib(s_ch_aib[9]),
        .s_ch10_aib(s_ch_aib[10]),
        .s_ch11_aib(s_ch_aib[11]),
        .s_ch12_aib(s_ch_aib[12]),
        .s_ch13_aib(s_ch_aib[13]),
        .s_ch14_aib(s_ch_aib[14]),
        .s_ch15_aib(s_ch_aib[15]),
        .s_ch16_aib(s_ch_aib[16]),
        .s_ch17_aib(s_ch_aib[17]),
        .s_ch18_aib(s_ch_aib[18]),
        .s_ch19_aib(s_ch_aib[19]),
        .s_ch20_aib(s_ch_aib[20]),
        .s_ch21_aib(s_ch_aib[21]),
        .s_ch22_aib(s_ch_aib[22]),
        .s_ch23_aib(s_ch_aib[23]),

        // Connect Leader (master) bridge to EMIB master side
        .m_ch0_aib(m_ch_aib[0]),
        .m_ch1_aib(m_ch_aib[1]),
        .m_ch2_aib(m_ch_aib[2]),
        .m_ch3_aib(m_ch_aib[3]),
        .m_ch4_aib(m_ch_aib[4]),
        .m_ch5_aib(m_ch_aib[5]),
        .m_ch6_aib(m_ch_aib[6]),
        .m_ch7_aib(m_ch_aib[7]),
        .m_ch8_aib(m_ch_aib[8]),
        .m_ch9_aib(m_ch_aib[9]),
        .m_ch10_aib(m_ch_aib[10]),
        .m_ch11_aib(m_ch_aib[11]),
        .m_ch12_aib(m_ch_aib[12]),
        .m_ch13_aib(m_ch_aib[13]),
        .m_ch14_aib(m_ch_aib[14]),
        .m_ch15_aib(m_ch_aib[15]),
        .m_ch16_aib(m_ch_aib[16]),
        .m_ch17_aib(m_ch_aib[17]),
        .m_ch18_aib(m_ch_aib[18]),
        .m_ch19_aib(m_ch_aib[19]),
        .m_ch20_aib(m_ch_aib[20]),
        .m_ch21_aib(m_ch_aib[21]),
        .m_ch22_aib(m_ch_aib[22]),
        .m_ch23_aib(m_ch_aib[23])
    );

endmodule