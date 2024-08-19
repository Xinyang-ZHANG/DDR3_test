onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib syncfifo_dist_cmd_opt

do {wave.do}

view wave
view structure
view signals

do {syncfifo_dist_cmd.udo}

run -all

quit -force
