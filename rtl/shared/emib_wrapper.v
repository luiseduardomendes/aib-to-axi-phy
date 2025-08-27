// ============================================================================
// Description: Verilog Wrapper for emib_m2s2
//
// Purpose:
// This wrapper module simplifies the instantiation of the 'emib_m2s2'
// module in a top-level design. It provides a clean interface layer,
// allowing the core EMIB module to be connected easily within a larger system.
//
// Usage:
// Instantiate this wrapper in your design and connect the master and slave
// channel signals to the appropriate components.
// ============================================================================

module emib_m2s2_wrapper #(
    parameter ROTATE = 0
) (
    // --- Slave Side Channels ---
    inout [101:0] s_ch0_aib,
    inout [101:0] s_ch1_aib,
    inout [101:0] s_ch2_aib,
    inout [101:0] s_ch3_aib,
    inout [101:0] s_ch4_aib,
    inout [101:0] s_ch5_aib,
    inout [101:0] s_ch6_aib,
    inout [101:0] s_ch7_aib,
    inout [101:0] s_ch8_aib,
    inout [101:0] s_ch9_aib,
    inout [101:0] s_ch10_aib,
    inout [101:0] s_ch11_aib,
    inout [101:0] s_ch12_aib,
    inout [101:0] s_ch13_aib,
    inout [101:0] s_ch14_aib,
    inout [101:0] s_ch15_aib,
    inout [101:0] s_ch16_aib,
    inout [101:0] s_ch17_aib,
    inout [101:0] s_ch18_aib,
    inout [101:0] s_ch19_aib,
    inout [101:0] s_ch20_aib,
    inout [101:0] s_ch21_aib,
    inout [101:0] s_ch22_aib,
    inout [101:0] s_ch23_aib,

    // --- Master Side Channels ---
    inout [101:0] m_ch0_aib,
    inout [101:0] m_ch1_aib,
    inout [101:0] m_ch2_aib,
    inout [101:0] m_ch3_aib,
    inout [101:0] m_ch4_aib,
    inout [101:0] m_ch5_aib,
    inout [101:0] m_ch6_aib,
    inout [101:0] m_ch7_aib,
    inout [101:0] m_ch8_aib,
    inout [101:0] m_ch9_aib,
    inout [101:0] m_ch10_aib,
    inout [101:0] m_ch11_aib,
    inout [101:0] m_ch12_aib,
    inout [101:0] m_ch13_aib,
    inout [101:0] m_ch14_aib,
    inout [101:0] m_ch15_aib,
    inout [101:0] m_ch16_aib,
    inout [101:0] m_ch17_aib,
    inout [101:0] m_ch18_aib,
    inout [101:0] m_ch19_aib,
    inout [101:0] m_ch20_aib,
    inout [101:0] m_ch21_aib,
    inout [101:0] m_ch22_aib,
    inout [101:0] m_ch23_aib
);

    // ============================================================================
    // Core EMIB Module Instantiation
    // ============================================================================
    // Instantiates the core emib_m2s2 module and connects its ports directly
    // to the wrapper's ports.
    emib_m2s2 #(
        .ROTATE(ROTATE)
    )
    u_emib_m2s2 (
        // --- Slave Side Connections ---
        .s_ch0_aib(s_ch0_aib),
        .s_ch1_aib(s_ch1_aib),
        .s_ch2_aib(s_ch2_aib),
        .s_ch3_aib(s_ch3_aib),
        .s_ch4_aib(s_ch4_aib),
        .s_ch5_aib(s_ch5_aib),
        .s_ch6_aib(s_ch6_aib),
        .s_ch7_aib(s_ch7_aib),
        .s_ch8_aib(s_ch8_aib),
        .s_ch9_aib(s_ch9_aib),
        .s_ch10_aib(s_ch10_aib),
        .s_ch11_aib(s_ch11_aib),
        .s_ch12_aib(s_ch12_aib),
        .s_ch13_aib(s_ch13_aib),
        .s_ch14_aib(s_ch14_aib),
        .s_ch15_aib(s_ch15_aib),
        .s_ch16_aib(s_ch16_aib),
        .s_ch17_aib(s_ch17_aib),
        .s_ch18_aib(s_ch18_aib),
        .s_ch19_aib(s_ch19_aib),
        .s_ch20_aib(s_ch20_aib),
        .s_ch21_aib(s_ch21_aib),
        .s_ch22_aib(s_ch22_aib),
        .s_ch23_aib(s_ch23_aib),

        // --- Master Side Connections ---
        .m_ch0_aib(m_ch0_aib),
        .m_ch1_aib(m_ch1_aib),
        .m_ch2_aib(m_ch2_aib),
        .m_ch3_aib(m_ch3_aib),
        .m_ch4_aib(m_ch4_aib),
        .m_ch5_aib(m_ch5_aib),
        .m_ch6_aib(m_ch6_aib),
        .m_ch7_aib(m_ch7_aib),
        .m_ch8_aib(m_ch8_aib),
        .m_ch9_aib(m_ch9_aib),
        .m_ch10_aib(m_ch10_aib),
        .m_ch11_aib(m_ch11_aib),
        .m_ch12_aib(m_ch12_aib),
        .m_ch13_aib(m_ch13_aib),
        .m_ch14_aib(m_ch14_aib),
        .m_ch15_aib(m_ch15_aib),
        .m_ch16_aib(m_ch16_aib),
        .m_ch17_aib(m_ch17_aib),
        .m_ch18_aib(m_ch18_aib),
        .m_ch19_aib(m_ch19_aib),
        .m_ch20_aib(m_ch20_aib),
        .m_ch21_aib(m_ch21_aib),
        .m_ch22_aib(m_ch22_aib),
        .m_ch23_aib(m_ch23_aib)
    );

endmodule
