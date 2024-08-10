-makelib xcelium_lib/xil_defaultlib -sv \
  "D:/Vivado2019.1/Vivado/2019.1/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
  "D:/Vivado2019.1/Vivado/2019.1/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \
-endlib
-makelib xcelium_lib/xpm \
  "D:/Vivado2019.1/Vivado/2019.1/data/ip/xpm/xpm_VCOMP.vhd" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  "../../../../mig_7series_app.srcs/sources_1/ip/clk_wiz_50_200/clk_wiz_50_200_clk_wiz.v" \
  "../../../../mig_7series_app.srcs/sources_1/ip/clk_wiz_50_200/clk_wiz_50_200.v" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  glbl.v
-endlib

