// ============================================================================
// Description: Verilog Wrapper for top_aib_axi_bridge_master
// ============================================================================

module top_aib_axi_bridge_master_wrapper #(
    parameter ACTIVE_CHNLS      = 24,
    parameter NBR_CHNLS         = 24,
    parameter NBR_BUMPS         = 102,
    parameter NBR_PHASES        = 4,
    parameter NBR_LANES         = 40,
    parameter MS_SSR_LEN        = 81,
    parameter SL_SSR_LEN        = 73,
    parameter DWIDTH            = 40,
    parameter AXI_CHNL_NUM      = 1,
    parameter ADDRWIDTH         = 32,
    parameter IDWIDTH           = 4,  // AXI ID Width
    parameter GEN2_MODE         = 1'b1,
    parameter AVMM_WIDTH        = 32, 
    parameter BYTE_WIDTH        = 4 
) (
    // ======= EMIB interface =======
    inout vddc1,
    inout vddc2,
    inout vddtx,
    inout vss,

    inout [NBR_BUMPS-1:0] iopad_ch0_aib,
    inout [NBR_BUMPS-1:0] iopad_ch1_aib,
    inout [NBR_BUMPS-1:0] iopad_ch2_aib,
    inout [NBR_BUMPS-1:0] iopad_ch3_aib,
    inout [NBR_BUMPS-1:0] iopad_ch4_aib,
    inout [NBR_BUMPS-1:0] iopad_ch5_aib,
    inout [NBR_BUMPS-1:0] iopad_ch6_aib,
    inout [NBR_BUMPS-1:0] iopad_ch7_aib,
    inout [NBR_BUMPS-1:0] iopad_ch8_aib,
    inout [NBR_BUMPS-1:0] iopad_ch9_aib,
    inout [NBR_BUMPS-1:0] iopad_ch10_aib,
    inout [NBR_BUMPS-1:0] iopad_ch11_aib,
    inout [NBR_BUMPS-1:0] iopad_ch12_aib,
    inout [NBR_BUMPS-1:0] iopad_ch13_aib,
    inout [NBR_BUMPS-1:0] iopad_ch14_aib,
    inout [NBR_BUMPS-1:0] iopad_ch15_aib,
    inout [NBR_BUMPS-1:0] iopad_ch16_aib,
    inout [NBR_BUMPS-1:0] iopad_ch17_aib,
    inout [NBR_BUMPS-1:0] iopad_ch18_aib,
    inout [NBR_BUMPS-1:0] iopad_ch19_aib,
    inout [NBR_BUMPS-1:0] iopad_ch20_aib,
    inout [NBR_BUMPS-1:0] iopad_ch21_aib,
    inout [NBR_BUMPS-1:0] iopad_ch22_aib,
    inout [NBR_BUMPS-1:0] iopad_ch23_aib,

    inout iopad_device_detect,
    inout iopad_power_on_reset,

    // ======= AIB <=> MAC ========
    input   m_wr_clk,
    input   m_rd_clk,
    input   m_fwd_clk,
    input                   i_osc_clk,
    input  [NBR_CHNLS-1: 0] ns_adapter_rstn,
    input  [NBR_CHNLS-1: 0] ns_mac_rdy,
    output [NBR_CHNLS-1: 0] fs_mac_rdy,
    output [NBR_CHNLS-1: 0] m_rx_align_done,
    input  [NBR_CHNLS-1: 0] ms_rx_dcc_dll_lock_req,
    input  [NBR_CHNLS-1: 0] ms_tx_dcc_dll_lock_req,
    input  [NBR_CHNLS-1: 0] sl_rx_dcc_dll_lock_req,
    input  [NBR_CHNLS-1: 0] sl_tx_dcc_dll_lock_req,

    // Aux Channel
    input                  m_por_ovrd,
    input                  m_device_detect_ovrd,
    input                  i_m_power_on_reset,
    output                 m_device_detect,
    output                 o_m_power_on_reset,

    // Avalon MM interface
    input i_cfg_avmm_clk,
    input i_cfg_avmm_rst_n,
    input [16:0] i_cfg_avmm_addr,
    input [BYTE_WIDTH-1:0] i_cfg_avmm_byte_en,
    input i_cfg_avmm_read,
    input i_cfg_avmm_write,
    input [AVMM_WIDTH-1:0] i_cfg_avmm_wdata,
    output o_cfg_avmm_rdatavld,
    output [AVMM_WIDTH-1:0] o_cfg_avmm_rdata,
    output o_cfg_avmm_waitreq,

    // ====== MAC <=> AXI-MM =======
    input clk_wr,
    input rst_wr_n,
    input [7:0] init_aw_credit,
    input [7:0] init_ar_credit,
    input [7:0] init_w_credit,
    input [15:0] delay_x_value,
    input [15:0] delay_y_value,
    input [15:0] delay_z_value,

    // --- AXI Slave Interface ---
    input  [IDWIDTH-1:0]      s_axi_awid,
    input  [ADDRWIDTH-1:0]    s_axi_awaddr,
    input  [7:0]              s_axi_awlen,
    input  [2:0]              s_axi_awsize,
    input  [1:0]              s_axi_awburst,
    input                     s_axi_awvalid,
    output                    s_axi_awready,

    input  [IDWIDTH-1:0]      s_axi_wid,
    input  [127:0]            s_axi_wdata,
    input  [15:0]             s_axi_wstrb,
    input                     s_axi_wlast,
    input                     s_axi_wvalid,
    output                    s_axi_wready,

    output [IDWIDTH-1:0]      s_axi_bid,
    output [1:0]              s_axi_bresp,
    output                    s_axi_bvalid,
    input                     s_axi_bready,

    input  [IDWIDTH-1:0]      s_axi_arid,
    input  [ADDRWIDTH-1:0]    s_axi_araddr,
    input  [7:0]              s_axi_arlen,
    input  [2:0]              s_axi_arsize,
    input  [1:0]              s_axi_arburst,
    input                     s_axi_arvalid,
    output                    s_axi_arready,

    output [IDWIDTH-1:0]      s_axi_rid,
    output [127:0]            s_axi_rdata,
    output [1:0]              s_axi_rresp,
    output                    s_axi_rlast,
    output                    s_axi_rvalid,
    input                     s_axi_rready
);

    // === Internal tie-off wires ===
    wire [NBR_CHNLS-1:0] ns_adapter_rstn_int;
    wire [NBR_CHNLS-1:0] ns_mac_rdy_int;
    wire [NBR_CHNLS-1:0] sl_rx_dcc_dll_lock_req_int;
    wire [NBR_CHNLS-1:0] sl_tx_dcc_dll_lock_req_int;

    wire [16:0] i_cfg_avmm_addr_int;
    wire [BYTE_WIDTH-1:0] i_cfg_avmm_byte_en_int;
    wire i_cfg_avmm_read_int;
    wire i_cfg_avmm_write_int;
    wire [AVMM_WIDTH-1:0] i_cfg_avmm_wdata_int;
    wire o_cfg_avmm_rdatavld_int;
    wire [AVMM_WIDTH-1:0] o_cfg_avmm_rdata_int;
    wire o_cfg_avmm_waitreq_int;
    wire calib_done;

    // === FSM instance (using *_int) ===
    calib_master_fsm #(
        .TOTAL_CHNL_NUM(NBR_CHNLS),
        .ACTIVE_CHNLS(2),
        .GEN2_MODE(1'b1)
    ) u_calib_fsm (
        .clk   (i_cfg_avmm_clk),
        .rst_n (i_cfg_avmm_rst_n),
        .sl_tx_transfer_en({24{1'b1}}),
        .sl_rx_transfer_en({24{1'b1}}),
        .calib_done(calib_done),
        .i_conf_done(),
        .ns_adapter_rstn(),
        .ns_mac_rdy(),
        .ms_rx_dcc_dll_lock_req(),
        .ms_tx_dcc_dll_lock_req(),
        .avmm_address_o(i_cfg_avmm_addr_int),
        .avmm_read_o(i_cfg_avmm_read_int),
        .avmm_write_o(i_cfg_avmm_write_int),
        .avmm_writedata_o(i_cfg_avmm_wdata_int),
        .avmm_byteenable_o(i_cfg_avmm_byte_en_int),
        .avmm_readdata_i(o_cfg_avmm_rdata_int),
        .avmm_readdatavalid_i(o_cfg_avmm_rdatavld_int),
        .avmm_waitrequest_i(o_cfg_avmm_waitreq_int)
    );

    // Internal AXI Interface
    axi_if user_axi_if ();

    // === Core Instance (using *_int) ===
    aib_axi_bridge_master #(
        .NBR_CHNLS(NBR_CHNLS),
        .NBR_BUMPS(NBR_BUMPS),
        .NBR_PHASES(NBR_PHASES),
        .NBR_LANES(NBR_LANES),
        .MS_SSR_LEN(MS_SSR_LEN),
        .SL_SSR_LEN(SL_SSR_LEN),
        .DWIDTH(DWIDTH),
        .AXI_CHNL_NUM(AXI_CHNL_NUM),
        .ADDRWIDTH(ADDRWIDTH),
        .GEN2_MODE(GEN2_MODE),
        .AVMM_WIDTH(AVMM_WIDTH),
        .BYTE_WIDTH(BYTE_WIDTH)
    )
    u_top_aib_axi_bridge_master (
        .vddc1(vddc1),
        .vddc2(vddc2),
        .vddtx(vddtx),
        .vss(vss),
        .iopad_ch0_aib(iopad_ch0_aib),
        .iopad_ch1_aib(iopad_ch1_aib),
        .iopad_ch2_aib(iopad_ch2_aib),
        .iopad_ch3_aib(iopad_ch3_aib),
        .iopad_ch4_aib(iopad_ch4_aib),
        .iopad_ch5_aib(iopad_ch5_aib),
        .iopad_ch6_aib(iopad_ch6_aib),
        .iopad_ch7_aib(iopad_ch7_aib),
        .iopad_ch8_aib(iopad_ch8_aib),
        .iopad_ch9_aib(iopad_ch9_aib),
        .iopad_ch10_aib(iopad_ch10_aib),
        .iopad_ch11_aib(iopad_ch11_aib),
        .iopad_ch12_aib(iopad_ch12_aib),
        .iopad_ch13_aib(iopad_ch13_aib),
        .iopad_ch14_aib(iopad_ch14_aib),
        .iopad_ch15_aib(iopad_ch15_aib),
        .iopad_ch16_aib(iopad_ch16_aib),
        .iopad_ch17_aib(iopad_ch17_aib),
        .iopad_ch18_aib(iopad_ch18_aib),
        .iopad_ch19_aib(iopad_ch19_aib),
        .iopad_ch20_aib(iopad_ch20_aib),
        .iopad_ch21_aib(iopad_ch21_aib),
        .iopad_ch22_aib(iopad_ch22_aib),
        .iopad_ch23_aib(iopad_ch23_aib),
        .iopad_device_detect(iopad_device_detect),
        .iopad_power_on_reset(iopad_power_on_reset),
        .m_wr_clk(m_wr_clk),
        .m_rd_clk(m_rd_clk),
        .m_fwd_clk(m_fwd_clk),
        .i_osc_clk(i_osc_clk),
        .ns_adapter_rstn({24{calib_done}}),
        .m_por_ovrd(m_por_ovrd),
        .m_device_detect_ovrd(m_device_detect_ovrd),
        .i_m_power_on_reset(i_m_power_on_reset),
        .m_device_detect(m_device_detect),
        .o_m_power_on_reset(o_m_power_on_reset),
        .ns_mac_rdy({24{calib_done}}),
        .fs_mac_rdy(fs_mac_rdy),
        .m_rx_align_done(m_rx_align_done),
        .ms_rx_dcc_dll_lock_req(ms_rx_dcc_dll_lock_req),
        .ms_tx_dcc_dll_lock_req(ms_tx_dcc_dll_lock_req),
        .sl_rx_dcc_dll_lock_req(sl_rx_dcc_dll_lock_req),
        .sl_tx_dcc_dll_lock_req(sl_tx_dcc_dll_lock_req),
        .i_cfg_avmm_clk(i_cfg_avmm_clk),
        .i_cfg_avmm_rst_n(i_cfg_avmm_rst_n),
        .i_cfg_avmm_addr(i_cfg_avmm_addr_int),
        .i_cfg_avmm_byte_en(i_cfg_avmm_byte_en_int),
        .i_cfg_avmm_read(i_cfg_avmm_read_int),
        .i_cfg_avmm_write(i_cfg_avmm_write_int),
        .i_cfg_avmm_wdata(i_cfg_avmm_wdata_int),
        .o_cfg_avmm_rdatavld(o_cfg_avmm_rdatavld_int),
        .o_cfg_avmm_rdata(o_cfg_avmm_rdata_int),
        .o_cfg_avmm_waitreq(o_cfg_avmm_waitreq_int),
        .clk_wr(clk_wr),
        .rst_wr_n(rst_wr_n),
        .init_aw_credit(init_aw_credit),
        .init_ar_credit(init_ar_credit),
        .init_w_credit(init_w_credit),
        .delay_x_value(delay_x_value),
        .delay_y_value(delay_y_value),
        .delay_z_value(delay_z_value),
        .user_axi_if(user_axi_if.slave)
    );

    // === AXI port mapping ===
    assign user_axi_if.awid    = s_axi_awid;
    assign user_axi_if.awaddr  = s_axi_awaddr;
    assign user_axi_if.awlen   = s_axi_awlen;
    assign user_axi_if.awsize  = s_axi_awsize;
    assign user_axi_if.awburst = s_axi_awburst;
    assign user_axi_if.awvalid = s_axi_awvalid;
    assign s_axi_awready       = user_axi_if.awready;

    assign user_axi_if.wid     = s_axi_wid;
    assign user_axi_if.wdata   = s_axi_wdata;
    assign user_axi_if.wstrb   = s_axi_wstrb;
    assign user_axi_if.wlast   = s_axi_wlast;
    assign user_axi_if.wvalid  = s_axi_wvalid;
    assign s_axi_wready        = user_axi_if.wready;

    assign s_axi_bid           = user_axi_if.bid;
    assign s_axi_bresp         = user_axi_if.bresp;
    assign s_axi_bvalid        = user_axi_if.bvalid;
    assign user_axi_if.bready  = s_axi_bready;

    assign user_axi_if.arid    = s_axi_arid;
    assign user_axi_if.araddr  = s_axi_araddr;
    assign user_axi_if.arlen   = s_axi_arlen;
    assign user_axi_if.arsize  = s_axi_arsize;
    assign user_axi_if.arburst = s_axi_arburst;
    assign user_axi_if.arvalid = s_axi_arvalid;
    assign s_axi_arready       = user_axi_if.arready;

    assign s_axi_rid           = user_axi_if.rid;
    assign s_axi_rdata         = user_axi_if.rdata;
    assign s_axi_rresp         = user_axi_if.rresp;
    assign s_axi_rlast         = user_axi_if.rlast;
    assign s_axi_rvalid        = user_axi_if.rvalid;
    assign user_axi_if.rready  = s_axi_rready;

endmodule
