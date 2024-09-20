## 12 MHz Clock Signal
set_property -dict {PACKAGE_PIN L17 IOSTANDARD LVCMOS33} [get_ports clk]
#create_clock -period 83.330 -name sys_clk_pin -waveform {0.000 41.660} -add [get_ports clk]

## Reset Button
set_property -dict {PACKAGE_PIN A18 IOSTANDARD LVCMOS33} [get_ports rst]
set_property -dict { PACKAGE_PIN A17   IOSTANDARD LVCMOS33 } [get_ports { led[0] }]; #IO_L12N_T1_MRCC_16 Sch=led[1]

## Baud Select Button
set_property -dict {PACKAGE_PIN B18 IOSTANDARD LVCMOS33} [get_ports sel]
set_property -dict { PACKAGE_PIN C16   IOSTANDARD LVCMOS33 } [get_ports { led[1] }]; #IO_L13P_T2_MRCC_16 Sch=led[2]

## UART TX and RX Pins
set_property -dict {PACKAGE_PIN J18 IOSTANDARD LVCMOS33} [get_ports tx]
set_property -dict {PACKAGE_PIN J17 IOSTANDARD LVCMOS33} [get_ports rx]

#error solve
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]