# AXI-MM AIB Bridge Generation (Custom AXI Data Width)

This workspace uses `llink_gen.py` from `aib-protocols` to generate AXI-MM bridge RTL from a cfg file.

## New cfg templates

- `util/axi_mm_a32_d32.cfg`  (AXI address 32, AXI data 32)
- `util/axi_mm_a32_d64.cfg`  (AXI address 32, AXI data 64)

Both are based on the existing `util/axi_mm.cfg` template and differ mainly by:

- `output user_wdata <WIDTH>`
- `output user_wstrb <WIDTH/8>`
- `input  user_rdata <WIDTH>`

---

## Prerequisites

- Workspace root: `/home/luismendes/aib-folders`
- Generator script: `/home/luismendes/aib-folders/rtl/vendor/aib-protocols/llink/script/llink_gen.py`
- Python 3 available

---

## Generate 32-bit AXI-MM bridge

```bash
python3 /home/luismendes/aib-folders/rtl/vendor/aib-protocols/llink/script/llink_gen.py \
  --cfg /home/luismendes/aib-folders/util/axi_mm_a32_d32.cfg \
  --odir /home/luismendes/aib-folders/rtl/axi4_aib_tools/rtl/axi_mm_d32
```

## Generate 64-bit AXI-MM bridge

```bash
python3 /home/luismendes/aib-folders/rtl/vendor/aib-protocols/llink/script/llink_gen.py \
  --cfg /home/luismendes/aib-folders/util/axi_mm_a32_d64.cfg \
  --odir /home/luismendes/aib-folders/rtl/axi4_aib_tools/rtl/axi_mm_d64
```

---

## Generate both (single script)

Use:

```bash
/home/luismendes/aib-folders/scripts/gen_axi_d32_d64.sh
```

By default it writes into a timestamped folder under:

`/home/luismendes/aib-folders/build/generated_axi_mm/<timestamp>/d32`
`/home/luismendes/aib-folders/build/generated_axi_mm/<timestamp>/d64`

To choose a custom base output folder:

```bash
/home/luismendes/aib-folders/scripts/gen_axi_d32_d64.sh /home/luismendes/aib-folders/build/generated_axi_mm/my_run
```

---

## Output files

For cfg `MODULE <name>`, generated files are in `--odir` and include:

- `<name>_master_top.sv`
- `<name>_master_name.sv`
- `<name>_master_concat.sv`
- `<name>_slave_top.sv`
- `<name>_slave_name.sv`
- `<name>_slave_concat.sv`
- `<name>_master.f`, `<name>_slave.f`
- `<name>_info.txt`

---

## How to create other AXI-MM widths

1. Copy one cfg file (for example `axi_mm_a32_d64.cfg`).
2. Change only these fields consistently:
   - `user_wdata = W`
   - `user_rdata = W`
   - `user_wstrb = W/8`
3. Keep AXI address width fields (e.g. `user_araddr`, `user_awaddr`) as desired.
4. Update `MODULE` name so generated files are unique.
5. Run `llink_gen.py` with a dedicated `--odir`.

### Common width examples

- AXI data 32  -> `wstrb 4`
- AXI data 64  -> `wstrb 8`
- AXI data 128 -> `wstrb 16`
- AXI data 256 -> `wstrb 32`

---

## Notes

- `axi_lite_a32_d32.cfg` (in `rtl/vendor/aib-protocols/llink/script/cfg/`) is AXI-Lite, not full AXI-MM.
- If link bandwidth is insufficient for larger widths, adjust PHY/channel settings (`NUM_CHAN`, `TX_RATE`, `RX_RATE`) and/or packetization options in cfg.
