// Description: AIB to AXI Bridge Slave
/*
    * Single AXI Channel (No Channel Alignment needed)
    * 1 AXI MM Lite Master
    * 1 AIB Gen2 PHY
*/

/*
    Macros:
    * NBR_BUMPS: Number of bumps in the AIB
    * NBR_LANES: Number of lanes in the AIB
    * NBR_PHASES: Number of phases in the AIB
    * NBR_CHNLS: Number of channels in the AIB
*/

supply1 HI;  // Global logic '1' (connects to vdd)
supply0 LO;  // Global logic '0' (connects to gnd)

`include "../interfaces/axi_if.v"


module aib_axi_bridge_slave #(
    parameter ACTIVE_CHNLS = 1,
    parameter NBR_CHNLS = 24,       // Total number of channels 
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
    inout   [NBR_BUMPS-1:0] iopad_ch0_aib,   // IO pad channel 00
    inout   [NBR_BUMPS-1:0] iopad_ch1_aib,   // IO pad channel 01
    inout   [NBR_BUMPS-1:0] iopad_ch2_aib,   // IO pad channel 02
    inout   [NBR_BUMPS-1:0] iopad_ch3_aib,   // IO pad channel 03
    inout   [NBR_BUMPS-1:0] iopad_ch4_aib,   // IO pad channel 04
    inout   [NBR_BUMPS-1:0] iopad_ch5_aib,   // IO pad channel 05
    inout   [NBR_BUMPS-1:0] iopad_ch6_aib,   // IO pad channel 06
    inout   [NBR_BUMPS-1:0] iopad_ch7_aib,   // IO pad channel 07
    inout   [NBR_BUMPS-1:0] iopad_ch8_aib,   // IO pad channel 08
    inout   [NBR_BUMPS-1:0] iopad_ch9_aib,   // IO pad channel 09
    inout   [NBR_BUMPS-1:0] iopad_ch10_aib,  // IO pad channel 10
    inout   [NBR_BUMPS-1:0] iopad_ch11_aib,  // IO pad channel 11
    inout   [NBR_BUMPS-1:0] iopad_ch12_aib,  // IO pad channel 12
    inout   [NBR_BUMPS-1:0] iopad_ch13_aib,  // IO pad channel 13
    inout   [NBR_BUMPS-1:0] iopad_ch14_aib,  // IO pad channel 14
    inout   [NBR_BUMPS-1:0] iopad_ch15_aib,  // IO pad channel 15
    inout   [NBR_BUMPS-1:0] iopad_ch16_aib,  // IO pad channel 16
    inout   [NBR_BUMPS-1:0] iopad_ch17_aib,  // IO pad channel 17
    inout   [NBR_BUMPS-1:0] iopad_ch18_aib,  // IO pad channel 18
    inout   [NBR_BUMPS-1:0] iopad_ch19_aib,  // IO pad channel 19
    inout   [NBR_BUMPS-1:0] iopad_ch20_aib,  // IO pad channel 20
    inout   [NBR_BUMPS-1:0] iopad_ch21_aib,  // IO pad channel 21
    inout   [NBR_BUMPS-1:0] iopad_ch22_aib,  // IO pad channel 22
    inout   [NBR_BUMPS-1:0] iopad_ch23_aib,  // IO pad channel 23

    // Aux IO pads
    inout  iopad_device_detect,  // Indicates the presence of a valid leader
    inout  iopad_power_on_reset, // Perfoms a power-on-reset in the adapter
    
    // ======= AIB <=> MAC ========
    // Clock Signals
    input                  m_wr_clk,     
    input                  m_rd_clk,    
    input                  m_fwd_clk,     

    // Control Signals
    input  [NBR_CHNLS-1:0] ns_adapter_rstn,
    input  [NBR_CHNLS-1:0] ns_mac_rdy,
    output [NBR_CHNLS-1:0] fs_mac_rdy, 
    output [NBR_CHNLS-1:0] m_rx_align_done, 
    output [NBR_CHNLS-1:0] ms_tx_transfer_en,
    output [NBR_CHNLS-1:0] sl_tx_transfer_en,

    input  [NBR_CHNLS-1:0] ms_rx_dcc_dll_lock_req,
    input  [NBR_CHNLS-1:0] ms_tx_dcc_dll_lock_req,
    input  [NBR_CHNLS-1:0] sl_rx_dcc_dll_lock_req,
    input  [NBR_CHNLS-1:0] sl_tx_dcc_dll_lock_req,

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
    input   [7:0]       init_r_credit,
    input   [7:0]       init_b_credit,
    

    // Configuration 
    input   [15:0]      delay_x_value,
    input   [15:0]      delay_y_value,
    input   [15:0]      delay_z_value,
        
    // axi channel 
    axi_if.master       user_axi_if     
);

    dut_if_mac #(.DWIDTH (DWIDTH)) intf_s1 (
        .wr_clk(m_wr_clk), 
        .rd_clk(m_rd_clk), 
        .fwd_clk(m_fwd_clk), 
        .osc_clk(i_osc_clk)
    );

    logic [DWIDTH*2-1:0] tx_phy0;
    logic [DWIDTH*2-1:0] rx_phy0;
    logic [NBR_LANES*NBR_PHASES*2*NBR_CHNLS-1:0] data_in_f;
    logic [NBR_LANES*NBR_PHASES*2*NBR_CHNLS-1:0] data_out_f;
    logic [NBR_LANES*2*NBR_CHNLS-1:0] data_in;
    logic [NBR_LANES*2*NBR_CHNLS-1:0] data_out;

    assign fs_mac_rdy = intf_s1.fs_mac_rdy;

    assign rx_phy0   [79:0] = rst_wr_n ? data_out   [79:0] : '0;
    assign data_in_f [79:0] = rst_wr_n ? tx_phy0    [79:0] : '0;
    assign data_in   [79:0] = rst_wr_n ? tx_phy0    [79:0] : '0;

    avalon_mm_if #(.AVMM_WIDTH(AVMM_WIDTH), .BYTE_WIDTH(BYTE_WIDTH)) avmm_if_s1  (
        .clk    (i_cfg_avmm_clk)
    );
    assign avmm_if_s1.rst_n = i_cfg_avmm_rst_n;

    assign avmm_if_s1.address      = i_cfg_avmm_addr;
    assign avmm_if_s1.byteenable   = i_cfg_avmm_byte_en;
    assign avmm_if_s1.read         = i_cfg_avmm_read;
    assign avmm_if_s1.write        = i_cfg_avmm_write;
    assign avmm_if_s1.writedata    = i_cfg_avmm_wdata;
    assign o_cfg_avmm_rdatavld     = avmm_if_s1.readdatavalid;
    assign o_cfg_avmm_rdata        = avmm_if_s1.readdata;
    assign o_cfg_avmm_waitreq      = avmm_if_s1.waitrequest;

    assign ms_tx_transfer_en = intf_s1.ms_tx_transfer_en;
    assign sl_tx_transfer_en = intf_s1.sl_tx_transfer_en;


    aib_model_top #(
        // Assuming default parameters are acceptable.
    ) dut_phy_slave1 (
        // AIB IO Pad Connections (Channels 0-23)
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
        
        // IO pads, AUX channel
        .iopad_device_detect(iopad_device_detect),
        .iopad_power_on_reset(iopad_power_on_reset),
        
        // Data Interface
        .data_in_f(data_in_f),                      
        .data_out_f(data_out_f),                     
        .data_in(data_in),
        .data_out(data_out),                         
                
        // Clock Interface
        .m_ns_fwd_clk(intf_s1.m_ns_fwd_clk),
        .m_ns_rcv_clk(intf_s1.m_ns_rcv_clk),                         
        .m_fs_rcv_clk(intf_s1.m_fs_rcv_clk),                         
        .m_fs_fwd_clk(intf_s1.m_fs_fwd_clk),                         
        .m_wr_clk(intf_s1.m_wr_clk),                              
        .m_rd_clk(intf_s1.m_rd_clk),
        .tclk_phy(),

        // Control and Status Signals
        .ns_adapter_rstn(ns_adapter_rstn),  
        .ns_mac_rdy(ns_mac_rdy),       
        .fs_mac_rdy(intf_s1.fs_mac_rdy),  
        .i_conf_done(ns_mac_rdy[0]),
        //.i_osc_clk(1'b0), // Slave does not drive oscillator clock
        
        // Handshake and Sideband Signals
        .ms_rx_dcc_dll_lock_req(ms_rx_dcc_dll_lock_req),
        .ms_tx_dcc_dll_lock_req(ms_tx_dcc_dll_lock_req),
        .sl_rx_dcc_dll_lock_req(sl_rx_dcc_dll_lock_req),
        .sl_tx_dcc_dll_lock_req(sl_tx_dcc_dll_lock_req),
        .ms_tx_transfer_en(intf_s1.ms_tx_transfer_en),                   
        .ms_rx_transfer_en(intf_s1.ms_rx_transfer_en),                   
        .sl_tx_transfer_en(intf_s1.sl_tx_transfer_en),
        .sl_rx_transfer_en(intf_s1.sl_rx_transfer_en),
        .sr_ms_tomac(intf_s1.ms_sideband),          
        .sr_sl_tomac(intf_s1.sl_sideband),           
        .m_rx_align_done(m_rx_align_done),   
        
        // Mode Select
        .dual_mode_select(1'b0), // Slave mode
        .m_gen2_mode(1'b1),

        // AVMM Interface
        .i_cfg_avmm_clk(avmm_if_s1.clk),
        .i_cfg_avmm_rst_n(avmm_if_s1.rst_n),
        .i_cfg_avmm_addr(avmm_if_s1.address),
        .i_cfg_avmm_byte_en(avmm_if_s1.byteenable),
        .i_cfg_avmm_read(avmm_if_s1.read),
        .i_cfg_avmm_write(avmm_if_s1.write),
        .i_cfg_avmm_wdata(avmm_if_s1.writedata),
        .o_cfg_avmm_rdatavld(avmm_if_s1.readdatavalid),
        .o_cfg_avmm_rdata(avmm_if_s1.readdata),
        .o_cfg_avmm_waitreq(avmm_if_s1.waitrequest),

        // Aux Channel
        .m_por_ovrd             (m_por_ovrd),
        .m_device_detect_ovrd   (m_device_detect_ovrd),
        .i_m_power_on_reset     (i_m_power_on_reset),
        .m_device_detect        (m_device_detect),
        .o_m_power_on_reset     (o_m_power_on_reset),

        // JTAG Ports
        .i_jtag_clkdr(1'b0),
        .i_jtag_clksel(1'b0),
        .i_jtag_intest(1'b0),
        .i_jtag_mode(1'b0),
        .i_jtag_rstb(1'b1),
        .i_jtag_rstb_en(1'b0),
        .i_jtag_tdi(1'b0),
        .i_jtag_tx_scanen(1'b0),
        .i_jtag_weakpdn(1'b0),
        .i_jtag_weakpu(1'b0),
        .o_jtag_tdo(),
        
        // ATPG Scan Ports
        .i_scan_clk(1'b0),
        .i_scan_clk_500m(1'b0),
        .i_scan_clk_1000m(1'b0),
        .i_scan_en(1'b0),
        .i_scan_mode(1'b0),
        .i_scan_din('0),
        .i_scan_dout(),

        // External Control Signals (Tied off)
        .sl_external_cntl_26_0('0),
        .sl_external_cntl_30_28('0),
        .sl_external_cntl_57_32('0),
        .ms_external_cntl_4_0('0),
        .ms_external_cntl_65_8('0)
    );
  
    
    axi_mm_slave_top  aximm_follower(
        .clk_wr              (clk_wr ),
        .rst_wr_n            (rst_wr_n),
        .tx_online           (intf_s1.fs_mac_rdy[0]),
        .rx_online           (intf_s1.fs_mac_rdy[0]),
        .init_r_credit      (init_r_credit)  ,
        .init_b_credit      (init_b_credit)  ,
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