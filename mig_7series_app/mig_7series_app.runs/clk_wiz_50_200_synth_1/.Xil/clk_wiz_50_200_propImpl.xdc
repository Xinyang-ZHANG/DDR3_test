set_property SRC_FILE_INFO {cfile:d:/self_learning/hulang/hulang001_plus/2_projects/mig_7series_app/mig_7series_app.srcs/sources_1/ip/clk_wiz_50_200/clk_wiz_50_200.xdc rfile:../../../mig_7series_app.srcs/sources_1/ip/clk_wiz_50_200/clk_wiz_50_200.xdc id:1 order:EARLY scoped_inst:inst} [current_design]
current_instance inst
set_property src_info {type:SCOPED_XDC file:1 line:57 export:INPUT save:INPUT read:READ} [current_design]
set_input_jitter [get_clocks -of_objects [get_ports clk_in1]] 0.2
