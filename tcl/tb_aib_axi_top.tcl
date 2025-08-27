set IMPL_RTL_DIR /home/luismendes/aib-folders/rtl

read_verilog -sv ${IMPL_RTL_DIR}/test/tb_aib_axi_top.v
# read flists

set WAVEFORM "${IMPL_RTL_DIR}/axi4_aib_tools/wave/aib_axi_bridge_tb_behav.wcfg"

add_files -fileset [current_fileset -simset] -norecurse $WAVEFORM
set_property xsim.view { $WAVEFORM } [current_fileset -simset]

set_property xsim.simulate.runtime "10us" [current_fileset -simset]