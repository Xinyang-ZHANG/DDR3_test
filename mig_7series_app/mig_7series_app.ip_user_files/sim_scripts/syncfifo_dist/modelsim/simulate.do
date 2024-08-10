onbreak {quit -f}
onerror {quit -f}

vsim -voptargs="+acc" -t 1ps -L xil_defaultlib -L xpm -L fifo_generator_v13_2_4 -L unisims_ver -L unimacro_ver -L secureip -lib xil_defaultlib xil_defaultlib.syncfifo_dist xil_defaultlib.glbl

do {wave.do}

view wave
view structure
view signals

do {syncfifo_dist.udo}

run -all

quit -force
