module top_aib_axi_bridge_slave_wrapper #(
    parameter ACTIVE_CHNLS      = 1,
    parameter NBR_CHNLS         = 24,
    parameter NBR_BUMPS         = 102,
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
    input  [NBR_CHNLS-1:0] ns_adapter_rstn, // kept for compatibility
    input  [NBR_CHNLS-1:0] ns_mac_rdy,      // kept for compatibility
    output [NBR_CHNLS-1:0] fs_mac_rdy,
    output [NBR_CHNLS-1:0] m_rx_align_done,
    output [NBR_CHNLS-1:0] ms_tx_transfer_en,
    output [NBR_CHNLS-1:0] sl_tx_transfer_en,

    input [NBR_CHNLS-1:0] ms_rx_dcc_dll_lock_req,
    input [NBR_CHNLS-1:0] ms_tx_dcc_dll_lock_req,
    input [NBR_CHNLS-1:0] sl_rx_dcc_dll_lock_req,
    input [NBR_CHNLS-1:0] sl_tx_dcc_dll_lock_req,

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
    input [7:0] init_r_credit,
    input [7:0] init_b_credit,
    input [15:0] delay_x_value,
    input [15:0] delay_y_value,
    input [15:0] delay_z_value,

    // --- AXI Master Interface (Individual Signals) ---
    output [IDWIDTH-1:0]      m_axi_awid,
    output [ADDRWIDTH-1:0]    m_axi_awaddr,
    output [7:0]              m_axi_awlen,
    output [2:0]              m_axi_awsize,
    output [1:0]              m_axi_awburst,
    output                    m_axi_awvalid,
    input                     m_axi_awready,
    output [IDWIDTH-1:0]      m_axi_wid,
    output [127:0]            m_axi_wdata,
    output [15:0]             m_axi_wstrb,
    output                    m_axi_wlast,
    output                    m_axi_wvalid,
    input                     m_axi_wready,
    input  [IDWIDTH-1:0]      m_axi_bid,
    input  [1:0]              m_axi_bresp,
    input                     m_axi_bvalid,
    output                    m_axi_bready,
    output [IDWIDTH-1:0]      m_axi_arid,
    output [ADDRWIDTH-1:0]    m_axi_araddr,
    output [7:0]              m_axi_arlen,
    output [2:0]              m_axi_arsize,
    output [1:0]              m_axi_arburst,
    output                    m_axi_arvalid,
    input                     m_axi_arready,
    input  [IDWIDTH-1:0]      m_axi_rid,
    input  [127:0]            m_axi_rdata,
    input  [1:0]              m_axi_rresp,
    input                     m_axi_rlast,
    input                     m_axi_rvalid,
    output                    m_axi_rready
);

    // === Internal replacement wires (ignore external inputs) ===
    wire [NBR_CHNLS-1:0] ns_adapter_rstn_int;
    wire [NBR_CHNLS-1:0] ns_mac_rdy_int;
    wire [NBR_CHNLS-1:0] sl_rx_dcc_dll_lock_req_int;
    wire [NBR_CHNLS-1:0] sl_tx_dcc_dll_lock_req_int;
    wire [16:0]          i_cfg_avmm_addr_int;
    wire [BYTE_WIDTH-1:0] i_cfg_avmm_byte_en_int;
    wire                  i_cfg_avmm_read_int;
    wire                  i_cfg_avmm_write_int;
    wire [AVMM_WIDTH-1:0] i_cfg_avmm_wdata_int;
    wire [AVMM_WIDTH-1:0] o_cfg_avmm_rdata_int;
    wire                  o_cfg_avmm_rdatavld_int;
    wire                  o_cfg_avmm_waitreq_int;
    wire                  i_m_power_on_reset_int;
    wire                  calib_done;


    calib_slave_fsm #(
        .TOTAL_CHNL_NUM(NBR_CHNLS),
        .ACTIVE_CHNLS(2),
        .GEN2_MODE(1'b1)
    ) u_calib_slave_fsm (
        .clk                (i_cfg_avmm_clk),
        .rst_n              (i_cfg_avmm_rst_n),
        .ms_tx_transfer_en  (),
        .ms_rx_transfer_en  (),
        .i_conf_done        (),
        .ns_mac_rdy         (),
        .ns_adapter_rstn    (),
        .sl_rx_dcc_dll_lock_req (),
        .sl_tx_dcc_dll_lock_req (),
        .calib_done        (calib_done),
        .avmm_address_o       (i_cfg_avmm_addr_int),
        .avmm_writedata_o     (i_cfg_avmm_wdata_int),
        .avmm_byteenable_o    (i_cfg_avmm_byte_en_int),
        .avmm_write_o         (i_cfg_avmm_write_int),
        .avmm_read_o          (i_cfg_avmm_read_int),
        .avmm_readdata_i      (o_cfg_avmm_rdata_int),
        .avmm_readdatavalid_i (o_cfg_avmm_rdatavld_int),
        .avmm_waitrequest_i   (o_cfg_avmm_waitreq_int),
        .i_m_power_on_reset   (i_m_power_on_reset_int)
    );

    // Internal AXI interface
    axi_if user_axi_if ();

    // Core instantiation
    aib_axi_bridge_slave #(
        .ACTIVE_CHNLS(ACTIVE_CHNLS),
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
    u_aib_axi_slave_gen1 (
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
        .ns_adapter_rstn({24{calib_done}}),
        .ns_mac_rdy({24{calib_done}}),
        .fs_mac_rdy(fs_mac_rdy),
        .m_rx_align_done(m_rx_align_done),
        .ms_tx_transfer_en(ms_tx_transfer_en),
        .sl_tx_transfer_en(sl_tx_transfer_en),
        .ms_rx_dcc_dll_lock_req(ms_rx_dcc_dll_lock_req),
        .ms_tx_dcc_dll_lock_req(ms_tx_dcc_dll_lock_req),
        .sl_rx_dcc_dll_lock_req(sl_rx_dcc_dll_lock_req),
        .sl_tx_dcc_dll_lock_req(sl_tx_dcc_dll_lock_req),
        .m_por_ovrd(m_por_ovrd),
        .m_device_detect_ovrd(m_device_detect_ovrd),
        .i_m_power_on_reset(i_m_power_on_reset),
        .m_device_detect(m_device_detect),
        .o_m_power_on_reset(o_m_power_on_reset),
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
        .init_r_credit(init_r_credit),
        .init_b_credit(init_b_credit),
        .delay_x_value(delay_x_value),
        .delay_y_value(delay_y_value),
        .delay_z_value(delay_z_value),
        .user_axi_if(user_axi_if.master)
    );

    // AXI port mapping...
    assign m_axi_awid          = user_axi_if.awid;
    assign m_axi_awaddr        = user_axi_if.awaddr;
    assign m_axi_awlen         = user_axi_if.awlen;
    assign m_axi_awsize        = user_axi_if.awsize;
    assign m_axi_awburst       = user_axi_if.awburst;
    assign m_axi_awvalid       = user_axi_if.awvalid;
    assign user_axi_if.awready = m_axi_awready;
    assign m_axi_wid           = user_axi_if.wid;
    assign m_axi_wdata         = user_axi_if.wdata;
    assign m_axi_wstrb         = user_axi_if.wstrb;
    assign m_axi_wlast         = user_axi_if.wlast;
    assign m_axi_wvalid        = user_axi_if.wvalid;
    assign user_axi_if.wready  = m_axi_wready;
    assign user_axi_if.bid     = m_axi_bid;
    assign user_axi_if.bresp   = m_axi_bresp;
    assign user_axi_if.bvalid  = m_axi_bvalid;
    assign m_axi_bready        = user_axi_if.bready;
    assign m_axi_arid          = user_axi_if.arid;
    assign m_axi_araddr        = user_axi_if.araddr;
    assign m_axi_arlen         = user_axi_if.arlen;
    assign m_axi_arsize        = user_axi_if.arsize;
    assign m_axi_arburst       = user_axi_if.arburst;
    assign m_axi_arvalid       = user_axi_if.arvalid;
    assign user_axi_if.arready = m_axi_arready;
    assign user_axi_if.rid     = m_axi_rid;
    assign user_axi_if.rdata   = m_axi_rdata;
    assign user_axi_if.rresp   = m_axi_rresp;
    assign user_axi_if.rlast   = m_axi_rlast;
    assign user_axi_if.rvalid  = m_axi_rvalid;
    assign m_axi_rready        = user_axi_if.rready;

endmodule
