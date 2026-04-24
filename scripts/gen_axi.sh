export ROOT_DIR="/home/luismendes/aib-folders"
export PROJ_DIR="${ROOT_DIR}/rtl/vendor/aib-protocols"
export RTL_IMPL_DIR="${ROOT_DIR}/rtl"
python3 ${PROJ_DIR}/llink/script/llink_gen.py --cfg ${ROOT_DIR}/util/axi_mm.cfg --odir ${RTL_IMPL_DIR}/axi4_aib_tools/rtl/axi_mm