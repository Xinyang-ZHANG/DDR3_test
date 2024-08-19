onbreak {quit -force}
onerror {quit -force}

asim -t 1ps +access +r +m+syncfifo_dist_cmd -L xil_defaultlib -L xpm -L fifo_generator_v13_2_4 -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.syncfifo_dist_cmd xil_defaultlib.glbl

do {wave.do}

view wave
view structure

do {syncfifo_dist_cmd.udo}

run -all

endsim

quit -force
