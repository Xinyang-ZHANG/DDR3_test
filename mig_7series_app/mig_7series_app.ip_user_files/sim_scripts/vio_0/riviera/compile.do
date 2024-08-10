vlib work
vlib riviera

vlib riviera/xil_defaultlib
vlib riviera/xpm

vmap xil_defaultlib riviera/xil_defaultlib
vmap xpm riviera/xpm

vlog -work xil_defaultlib  -sv2k12 "+incdir+../../../../mig_7series_app.srcs/sources_1/ip/vio_0/hdl/verilog" "+incdir+../../../../mig_7series_app.srcs/sources_1/ip/vio_0/hdl" \
"D:/Vivado2019.1/Vivado/2019.1/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"D:/Vivado2019.1/Vivado/2019.1/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -93 \
"D:/Vivado2019.1/Vivado/2019.1/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../mig_7series_app.srcs/sources_1/ip/vio_0/hdl/verilog" "+incdir+../../../../mig_7series_app.srcs/sources_1/ip/vio_0/hdl" \
"../../../../mig_7series_app.srcs/sources_1/ip/vio_0/sim/vio_0.v" \

vlog -work xil_defaultlib \
"glbl.v"

