transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

vlib work
vlib activehdl/xil_defaultlib

vmap xil_defaultlib activehdl/xil_defaultlib

vcom -work xil_defaultlib -93  \
"c:/Users/elina/CapstoneVHDL/ECG_Compression/ECG_Compression.gen/sources_1/ip/bram_ecg/bram_ecg_sim_netlist.vhdl" \


