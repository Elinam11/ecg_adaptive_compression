transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

asim +access +r +m+bram_ecg  -L xil_defaultlib -L xpm -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.bram_ecg xil_defaultlib.glbl

do {bram_ecg.udo}

run 1000ns

endsim

quit -force
