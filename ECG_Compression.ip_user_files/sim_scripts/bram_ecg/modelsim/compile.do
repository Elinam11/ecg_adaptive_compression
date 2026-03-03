vlib modelsim_lib/work
vlib modelsim_lib/msim

vlib modelsim_lib/msim/xil_defaultlib

vmap xil_defaultlib modelsim_lib/msim/xil_defaultlib

vcom -work xil_defaultlib  -93  \
"c:/Users/elina/CapstoneVHDL/ECG_Compression/ECG_Compression.gen/sources_1/ip/bram_ecg/bram_ecg_sim_netlist.vhdl" \


