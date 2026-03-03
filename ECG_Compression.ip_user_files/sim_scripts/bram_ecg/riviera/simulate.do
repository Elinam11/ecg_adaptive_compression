transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

asim +access +r +m+bram_ecg  -L xil_defaultlib -L secureip -O5 xil_defaultlib.bram_ecg

do {bram_ecg.udo}

run 1000ns

endsim

quit -force
