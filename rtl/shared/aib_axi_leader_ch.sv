// Description: AIB to AXI Bridge Master
/*
    * Single AXI Channel (No Channel Alignment needed)
    * 1 AXI MM Lite Slave
    * 1 AIB Gen2 PHY
*/

/*
    Macros:
    * NBR_BUMPS: Number of bumps in the AIB
    * NBR_LANES: Number of lanes in the AIB
    * NBR_PHASES: Number of phases in the AIB
*/

supply1 HI;  // Global logic '1' (connects to vdd)
supply0 LO;  // Global logic '0' (connects to gnd)

`include "../interfaces/axi_if.v"


module aib_axi_leader_ch #(
    parameter NBR_BUMPS = 102,      // Number of BUMPs
    parameter NBR_PHASES = 4,       // Number of phases
    parameter NBR_LANES = 40,       // Number of lanes
    parameter MS_SSR_LEN = 81,      // Data size for leader side band
    parameter SL_SSR_LEN = 73,      // Data size for follower side band
    parameter DWIDTH = 40,
    parameter AXI_CHNL_NUM = 1,     // Number of AXI channels
    parameter ADDRWIDTH = 32,       // Address width
    parameter GEN2_MODE = 1'b1,
    parameter AVMM_WIDTH = 32,
    parameter BYTE_WIDTH = 4
) (

    // ======= EMIB interface =======
    inout vddc1,  // vddc1 power supply pin (low noise for clock circuits)
    inout vddc2,  // vddc2 power supply pin for IOs circuits
    inout vddtx,  // vddtx power supply pin for high-speed data
    inout vss,    // Ground

    // IO pads for each channel
    inout   [NBR_BUMPS-1:0] iopad_aib,   // IO pad channel 00

    // Aux IO pads
    inout  iopad_device_detect,  // Indicates the presence of a valid leader
    inout  iopad_power_on_reset, // Perfoms a power-on-reset in the adapter

    // ======= AIB <=> MAC ========
    // Clock Signals
    input  m_wr_clk,
    input  m_rd_clk,
    input  m_fwd_clk,
    input  i_osc_clk,

    // Control Signals
    input   ns_adapter_rstn,
    input   ns_mac_rdy,
    output  fs_mac_rdy,
    output  m_rx_align_done,

    input   ms_rx_dcc_dll_lock_req,
    input   ms_tx_dcc_dll_lock_req,
    input   sl_rx_dcc_dll_lock_req,
    input   sl_tx_dcc_dll_lock_req,

    // Aux Channel
    input                  m_por_ovrd,
    input                  m_device_detect_ovrd,
    input                  i_m_power_on_reset,
    output                 m_device_detect,
    output                 o_m_power_on_reset,

    // Avalon MM interface
    // input               avmm_clk,
    // input               avmm_rst_n,
    input               i_cfg_avmm_clk,
    input               i_cfg_avmm_rst_n,
    input  [16:0]       i_cfg_avmm_addr,
    input  [BYTE_WIDTH-1:0]       i_cfg_avmm_byte_en,
    input               i_cfg_avmm_read,
    input               i_cfg_avmm_write,
    input  [AVMM_WIDTH-1:0]       i_cfg_avmm_wdata,
    output              o_cfg_avmm_rdatavld,
    output [AVMM_WIDTH-1:0]       o_cfg_avmm_rdata,
    output              o_cfg_avmm_waitreq,

    // ====== MAC <=> AXI-MM =======
    input               clk_wr,
    input               rst_wr_n,

    // Control signals
    input   [7:0]       init_aw_credit,
    input   [7:0]       init_ar_credit,
    input   [7:0]       init_w_credit,

    // Configuration
    input   [15:0]      delay_x_value,
    input   [15:0]      delay_y_value,
    input   [15:0]      delay_z_value,

    // axi channel
    axi_if.slave        user_axi_if
);

    dut_if_mac #(.DWIDTH (DWIDTH)) intf_m1 (
        .wr_clk(m_wr_clk),
        .rd_clk(m_rd_clk),
        .fwd_clk(m_fwd_clk),
        .osc_clk(i_osc_clk)
    );

    logic [DWIDTH*2-1:0] tx_phy0;
    logic [DWIDTH*2-1:0] rx_phy0;
    logic [DWIDTH*8-1:0] data_in_f;
    logic [DWIDTH*8-1:0] data_out_f;
    logic [DWIDTH*2-1:0] data_in;
    logic [DWIDTH*2-1:0] data_out;

    assign fs_mac_rdy = intf_m1.fs_mac_rdy[0]; // Loopback for single device testing

    assign rx_phy0   [79:0] = rst_wr_n ? data_out   [79:0] : '0;
    assign data_in_f [79:0] = rst_wr_n ? tx_phy0    [79:0] : '0;
    assign data_in   [79:0] = rst_wr_n ? tx_phy0    [79:0] : '0;

    avalon_mm_if #(.AVMM_WIDTH(AVMM_WIDTH), .BYTE_WIDTH(BYTE_WIDTH)) avmm_if_m1  (
        .clk    (i_cfg_avmm_clk)
    );
    assign avmm_if_m1.rst_n = i_cfg_avmm_rst_n;

    assign avmm_if_m1.address    = i_cfg_avmm_addr;
    assign avmm_if_m1.byteenable = i_cfg_avmm_byte_en;
    assign avmm_if_m1.read       = i_cfg_avmm_read;
    assign avmm_if_m1.write      = i_cfg_avmm_write;
    assign avmm_if_m1.writedata  = i_cfg_avmm_wdata;
    assign o_cfg_avmm_rdatavld   = avmm_if_m1.readdatavalid;
    assign o_cfg_avmm_rdata      = avmm_if_m1.readdata;
    assign o_cfg_avmm_waitreq    = avmm_if_m1.waitrequest;

    // Instantiation template for aib_channel
    aib_channel #(
        .MAX_SCAN_LEN(200),
        .DATAWIDTH(DWIDTH)
    ) u_aib_channel_0 (
        // IO Pads
        .iopad_aib                (iopad_aib), // Only channel 0

        // Data interfaces
        .data_in_f                (data_in_f[79:0]),   // 8*DATAWIDTH for ch0
        .data_out_f               (data_out_f[79:0]),
        .data_in                  (data_in[79:0]),     // 2*DATAWIDTH for ch0
        .data_out                 (data_out[79:0]),

        // Clocks
        .m_ns_fwd_clk             (intf_m1.m_ns_fwd_clk),
        .m_ns_rcv_clk             (intf_m1.m_ns_rcv_clk),
        .m_fs_rcv_clk             (intf_m1.m_fs_rcv_clk),
        .m_fs_fwd_clk             (intf_m1.m_fs_fwd_clk),
        .m_wr_clk                 (intf_m1.m_wr_clk),
        .m_rd_clk                 (intf_m1.m_rd_clk),
        .tclk_phy                 (), // Not used

        // Control
        .ns_adapter_rstn          (ns_adapter_rstn),
        .ns_mac_rdy               (ns_mac_rdy),
        .fs_mac_rdy               (intf_m1.fs_mac_rdy[0]),

        // Status/Handshake
        .i_conf_done              (ns_mac_rdy),
        .ms_rx_dcc_dll_lock_req   (ms_rx_dcc_dll_lock_req),
        .ms_tx_dcc_dll_lock_req   (ms_tx_dcc_dll_lock_req),
        .sl_tx_dcc_dll_lock_req   (sl_tx_dcc_dll_lock_req),
        .sl_rx_dcc_dll_lock_req   (sl_rx_dcc_dll_lock_req),
        .ms_tx_transfer_en        (intf_m1.ms_tx_transfer_en[0]),
        .ms_rx_transfer_en        (intf_m1.ms_rx_transfer_en[0]),
        .sl_tx_transfer_en        (intf_m1.sl_tx_transfer_en[0]),
        .sl_rx_transfer_en        (intf_m1.sl_rx_transfer_en[0]),
        .m_rx_align_done          (m_rx_align_done),
        .sr_ms_tomac              (intf_m1.ms_sideband[80:0]),
        .sr_sl_tomac              (intf_m1.sl_sideband[72:0]),

        // Sideband user input
        .sl_external_cntl_26_0    (27'b0),
        .sl_external_cntl_30_28   (3'b0),
        .sl_external_cntl_57_32   (26'b0),
        .ms_external_cntl_4_0     (5'b0),
        .ms_external_cntl_65_8    (58'b0),

        // Mode select
        .dual_mode_select         (1'b1),
        .m_gen2_mode              (1'b1),

        // Aux channel
        .por                      (m_por_ovrd),
        .i_osc_clk                (intf_m1.osc_clk),

        // JTAG
        .jtag_clkdr_in            (1'b0),
        .scan_out                 (),
        .jtag_intest              (1'b0),
        .jtag_mode_in             (1'b0),
        .jtag_rstb                (1'b1),
        .jtag_rstb_en             (1'b0),
        .jtag_weakpdn             (1'b0),
        .jtag_weakpu              (1'b0),
        .jtag_tx_scanen_in        (1'b0),
        .scan_in                  (1'b0),

        // Scan IO
        .i_scan_clk               (1'b0),
        .i_scan_clk_500m          (1'b0),
        .i_scan_clk_1000m         (1'b0),
        .i_scan_en                (1'b0),
        .i_scan_mode              (1'b0),
        .i_scan_din               (400'b0),
        .i_scan_dout              (),

        // Channel ID
        .i_channel_id             (6'd0),

        // AVMM config
        .i_cfg_avmm_clk           (avmm_if_m1.clk),
        .i_cfg_avmm_rst_n         (avmm_if_m1.rst_n),
        .i_cfg_avmm_addr          (avmm_if_m1.address),
        .i_cfg_avmm_byte_en       (avmm_if_m1.byteenable),
        .i_cfg_avmm_read          (avmm_if_m1.read),
        .i_cfg_avmm_write         (avmm_if_m1.write),
        .i_cfg_avmm_wdata         (avmm_if_m1.writedata),
        .o_cfg_avmm_rdatavld      (avmm_if_m1.readdatavalid),
        .o_cfg_avmm_rdata         (avmm_if_m1.readdata),
        .o_cfg_avmm_waitreq       (avmm_if_m1.waitrequest)
    );

    aib_aux_channel  aib_aux_channel(
        // AIB IO Bidirectional
        .iopad_dev_dect(iopad_device_detect),
        .iopad_dev_dectrdcy(iopad_device_detect),
        .iopad_dev_por(iopad_power_on_reset),
        .iopad_dev_porrdcy(iopad_power_on_reset),

        //  .device_detect_ms(ms_device_detect),
        .m_por_ovrd(m_por_ovrd),
        .m_device_detect_ovrd(m_device_detect_ovrd),
        .por_ms(o_m_power_on_reset),
        .m_device_detect(m_device_detect),
        .por_sl(i_m_power_on_reset),
        //  .osc_clk(i_osc_clk),
        .ms_nsl(1'b1),
        .irstb(1'b1) // Output buffer tri-state enable
    );

    axi_mm_master_top  aximm_leader(
        .clk_wr              (clk_wr ),
        .rst_wr_n            (rst_wr_n),
        .tx_online           (intf_m1.fs_mac_rdy[0]),
        .rx_online           (intf_m1.fs_mac_rdy[0]),
        .init_ar_credit      (init_ar_credit),
        .init_aw_credit      (init_aw_credit),
        .init_w_credit       (init_w_credit ),
        .tx_phy0             (tx_phy0),
        .rx_phy0             (rx_phy0),

        .user_arid           (user_axi_if.arid    ),
        .user_arsize         (user_axi_if.arsize  ),
        .user_arlen          (user_axi_if.arlen   ),
        .user_arburst        (user_axi_if.arburst ),
        .user_araddr         (user_axi_if.araddr  ),
        .user_arvalid        (user_axi_if.arvalid ),
        .user_arready        (user_axi_if.arready ),

        .user_awid           (user_axi_if.awid   ),
        .user_awsize         (user_axi_if.awsize ),
        .user_awlen          (user_axi_if.awlen  ),
        .user_awburst        (user_axi_if.awburst),
        .user_awaddr         (user_axi_if.awaddr ),
        .user_awvalid        (user_axi_if.awvalid),
        .user_awready        (user_axi_if.awready),

        .user_wid            (user_axi_if.wid     ),
        .user_wdata          (user_axi_if.wdata   ),
        .user_wstrb          (user_axi_if.wstrb[15:0]   ),
        .user_wlast          (user_axi_if.wlast   ),
        .user_wvalid         (user_axi_if.wvalid  ),
        .user_wready         (user_axi_if.wready  ),

        .user_rid            (user_axi_if.rid     ),
        .user_rdata          (user_axi_if.rdata   ),
        .user_rlast          (user_axi_if.rlast   ),
        .user_rresp          (user_axi_if.rresp   ),
        .user_rvalid         (user_axi_if.rvalid  ),
        .user_rready         (user_axi_if.rready  ),

        .user_bid            (user_axi_if.bid     ),
        .user_bresp          (user_axi_if.bresp   ),
        .user_bvalid         (user_axi_if.bvalid  ),
        .user_bready         (user_axi_if.bready  ),

        .m_gen2_mode         (GEN2_MODE),
        .delay_x_value       (delay_x_value),
        .delay_y_value       (delay_y_value),
        .delay_z_value       (delay_z_value)
    );

endmodule
