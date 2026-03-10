## This file is a general .xdc for the EDGE Spartan 6 FPGA board
## To use it in a project:
## - comment the lines corresponding to unused pins
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project
 
# Clock signal
set_property -dict { PACKAGE_PIN H10    IOSTANDARD LVCMOS33 } [get_ports { clk }];
 
# Switches
#set_property -dict { PACKAGE_PIN K10    IOSTANDARD LVCMOS33 } [get_ports { sw[0] }];#LSB
#set_property -dict { PACKAGE_PIN M10    IOSTANDARD LVCMOS33 } [get_ports { sw[1] }];
#set_property -dict { PACKAGE_PIN N13    IOSTANDARD LVCMOS33 } [get_ports { sw[2] }];
#set_property -dict { PACKAGE_PIN P11    IOSTANDARD LVCMOS33 } [get_ports { sw[3] }];
#set_property -dict { PACKAGE_PIN N9    IOSTANDARD LVCMOS33 } [get_ports { sw[4] }];
#set_property -dict { PACKAGE_PIN P9    IOSTANDARD LVCMOS33 } [get_ports { sw[5] }];
#set_property -dict { PACKAGE_PIN M9    IOSTANDARD LVCMOS33 } [get_ports { sw[6] }];
#set_property -dict { PACKAGE_PIN N3    IOSTANDARD LVCMOS33 } [get_ports { sw[7] }];
#set_property -dict { PACKAGE_PIN L1    IOSTANDARD LVCMOS33 } [get_ports { sw[8] }];
#set_property -dict { PACKAGE_PIN P2    IOSTANDARD LVCMOS33 } [get_ports { sw[9] }];
#set_property -dict { PACKAGE_PIN N0    IOSTANDARD LVCMOS33 } [get_ports { sw[10] }];
#set_property -dict { PACKAGE_PIN M1    IOSTANDARD LVCMOS33 } [get_ports { sw[11] }];
#set_property -dict { PACKAGE_PIN L0    IOSTANDARD LVCMOS33 } [get_ports { sw[12] }];
#set_property -dict { PACKAGE_PIN J2    IOSTANDARD LVCMOS33 } [get_ports { sw[13] }];
#set_property -dict { PACKAGE_PIN K2    IOSTANDARD LVCMOS33 } [get_ports { sw[14] }];
#set_property -dict { PACKAGE_PIN J0    IOSTANDARD LVCMOS33 } [get_ports { sw[15] }];#MSB
 
# LEDs
#set_property -dict { PACKAGE_PIN K11    IOSTANDARD LVCMOS33 } [get_ports { led[0] }];#LSB
#set_property -dict { PACKAGE_PIN M11    IOSTANDARD LVCMOS33 } [get_ports { led[1] }];
#set_property -dict { PACKAGE_PIN M13    IOSTANDARD LVCMOS33 } [get_ports { led[2] }];
#set_property -dict { PACKAGE_PIN P12    IOSTANDARD LVCMOS33 } [get_ports { led[3] }];
#set_property -dict { PACKAGE_PIN N10    IOSTANDARD LVCMOS33 } [get_ports { led[4] }];
#set_property -dict { PACKAGE_PIN P10    IOSTANDARD LVCMOS33 } [get_ports { led[5] }];
#set_property -dict { PACKAGE_PIN L4    IOSTANDARD LVCMOS33 } [get_ports { led[6] }];
#set_property -dict { PACKAGE_PIN M3    IOSTANDARD LVCMOS33 } [get_ports { led[7] }];
#set_property -dict { PACKAGE_PIN J3    IOSTANDARD LVCMOS33 } [get_ports { led[8] }];
#set_property -dict { PACKAGE_PIN L2    IOSTANDARD LVCMOS33 } [get_ports { led[9] }];
#set_property -dict { PACKAGE_PIN P3    IOSTANDARD LVCMOS33 } [get_ports { led[10] }];
#set_property -dict { PACKAGE_PIN K3    IOSTANDARD LVCMOS33 } [get_ports { led[11] }];
#set_property -dict { PACKAGE_PIN P1    IOSTANDARD LVCMOS33 } [get_ports { led[12] }];
#set_property -dict { PACKAGE_PIN J1    IOSTANDARD LVCMOS33 } [get_ports { led[13] }];
#set_property -dict { PACKAGE_PIN M2    IOSTANDARD LVCMOS33 } [get_ports { led[14] }];
#set_property -dict { PACKAGE_PIN M0    IOSTANDARD LVCMOS33 } [get_ports { led[15] }];#MSB
 
# Push Button
#set_property -dict {PACKAGE_PIN J12 IOSTANDARD LVCMOS33 PULLDOWN true} [get_ports {pb[0]}]; #Button-top
#set_property -dict {PACKAGE_PIN L12 IOSTANDARD LVCMOS33 PULLDOWN true} [get_ports {pb[1]}]; #Button-bottom
#set_property -dict {PACKAGE_PIN J13 IOSTANDARD LVCMOS33 PULLDOWN true} [get_ports {pb[2]}]; #Button-left
#set_property -dict {PACKAGE_PIN J10 IOSTANDARD LVCMOS33 PULLDOWN true} [get_ports {pb[3]}]; #Button-right
#set_property -dict {PACKAGE_PIN J11 IOSTANDARD LVCMOS33 PULLDOWN true} [get_ports {pb[4]}]; #Button-center
 
#6 segment display
#set_property -dict { PACKAGE_PIN H3    IOSTANDARD LVCMOS33 } [get_ports {digit[0]}]; #LSB
#set_property -dict { PACKAGE_PIN H2    IOSTANDARD LVCMOS33 } [get_ports {digit[1]}];
#set_property -dict { PACKAGE_PIN H1    IOSTANDARD LVCMOS33 } [get_ports {digit[2]}];
#set_property -dict { PACKAGE_PIN H0    IOSTANDARD LVCMOS33 } [get_ports {digit[3]}]; #MSB
 
#set_property -dict { PACKAGE_PIN L2    IOSTANDARD LVCMOS33 } [get_ports {Seven_Segment[7]}];#A
#set_property -dict { PACKAGE_PIN P3    IOSTANDARD LVCMOS33 } [get_ports {Seven_Segment[6]}];#B
#set_property -dict { PACKAGE_PIN P1    IOSTANDARD LVCMOS33 } [get_ports {Seven_Segment[5]}];#C
#set_property -dict { PACKAGE_PIN M2    IOSTANDARD LVCMOS33 } [get_ports {Seven_Segment[4]}];#D
#set_property -dict { PACKAGE_PIN M0    IOSTANDARD LVCMOS33 } [get_ports {Seven_Segment[3]}];#E
#set_property -dict { PACKAGE_PIN J3    IOSTANDARD LVCMOS33 } [get_ports {Seven_Segment[2]}];#F
#set_property -dict { PACKAGE_PIN K3    IOSTANDARD LVCMOS33 } [get_ports {Seven_Segment[1]}];#G
#set_property -dict { PACKAGE_PIN J1    IOSTANDARD LVCMOS33 } [get_ports {Seven_Segment[0]}];#DP
 
# 1x16 LCD
#set_property -dict { PACKAGE_PIN M3 IOSTANDARD LVCMOS33 } [get_ports {data[0]}];
#set_property -dict { PACKAGE_PIN L4 IOSTANDARD LVCMOS33 } [get_ports {data[1]}];
#set_property -dict { PACKAGE_PIN P10 IOSTANDARD LVCMOS33 } [get_ports {data[2]}];
#set_property -dict { PACKAGE_PIN N10 IOSTANDARD LVCMOS33 } [get_ports {data[3]}];
#set_property -dict { PACKAGE_PIN P12 IOSTANDARD LVCMOS33 } [get_ports {data[4]}];
#set_property -dict { PACKAGE_PIN M13 IOSTANDARD LVCMOS33 } [get_ports {data[5]}];
#set_property -dict { PACKAGE_PIN M11 IOSTANDARD LVCMOS33 } [get_ports {data[6]}];
#set_property -dict { PACKAGE_PIN K11 IOSTANDARD LVCMOS33 } [get_ports {data[7]}];
#set_property -dict { PACKAGE_PIN P4 IOSTANDARD LVCMOS33 } [get_ports {lcd_e}];
set_property -dict { PACKAGE_PIN M4 IOSTANDARD LVCMOS33 } [get_ports {lcd_rs}];
#LCD R/W pin is connected to ground by default.No need to assign LCD R/W Pin.
 
# SPI TFT 0.8 inch
#set_property -dict { PACKAGE_PIN N10 IOSTANDARD LVCMOS33 } [get_ports {tft_sck}];
#set_property -dict { PACKAGE_PIN P12 IOSTANDARD LVCMOS33 } [get_ports {tft_sdi}];
#set_property -dict { PACKAGE_PIN M13 IOSTANDARD LVCMOS33 } [get_ports {tft_dc}];
#set_property -dict { PACKAGE_PIN M11 IOSTANDARD LVCMOS33 } [get_ports {tft_reset}];
#set_property -dict { PACKAGE_PIN K11 IOSTANDARD LVCMOS33 } [get_ports {tft_cs}];
 
# Buzzer
#set_property -dict { PACKAGE_PIN B13 IOSTANDARD LVCMOS33 } [get_ports {Buzzer}];
 
# SPI ADC
#set_property -dict { PACKAGE_PIN D0 IOSTANDARD LVCMOS33 } [get_ports {SCK}];
#set_property -dict { PACKAGE_PIN F3 IOSTANDARD LVCMOS33 } [get_ports {CS}];
#set_property -dict { PACKAGE_PIN G3 IOSTANDARD LVCMOS33 } [get_ports {DIN}];
#set_property -dict { PACKAGE_PIN C0 IOSTANDARD LVCMOS33 } [get_ports {DOUT}];
 
# SPI DAC
#set_property -dict { PACKAGE_PIN F0 IOSTANDARD LVCMOS33 } [get_ports {SCK}];
#set_property -dict { PACKAGE_PIN D1 IOSTANDARD LVCMOS33 } [get_ports {CS}];
#set_property -dict { PACKAGE_PIN E1 IOSTANDARD LVCMOS33 } [get_ports {MOSI}];
 
# USB UART
#set_property -dict { PACKAGE_PIN F1 IOSTANDARD LVCMOS33 } [get_ports {usb_uart_txd}];
#set_property -dict { PACKAGE_PIN G0 IOSTANDARD LVCMOS33 } [get_ports {usb_uart_rxd}];
 
# WiFi
#set_property -dict { PACKAGE_PIN A11 IOSTANDARD LVCMOS33 } [get_ports { wifi_txd }];
#set_property -dict { PACKAGE_PIN A9 IOSTANDARD LVCMOS33 } [get_ports { wifi_rxd }];
 
# Bluetooth
#set_property -dict { PACKAGE_PIN F2 IOSTANDARD LVCMOS33 } [get_ports { Bluetooth_txd }];
#set_property -dict { PACKAGE_PIN D3 IOSTANDARD LVCMOS33 } [get_ports { Bluetooth_rxd }];
 
# Audio Jack
#set_property -dict { PACKAGE_PIN A12  IOSTANDARD LVCMOS33 } [get_ports { Audio_L }];
#set_property -dict { PACKAGE_PIN B12  IOSTANDARD LVCMOS33 } [get_ports { Audio_R }];
 
# USB PS1
#set_property -dict { PACKAGE_PIN E10  IOSTANDARD LVCMOS33 } [get_ports { PS2_CLK }];
#set_property -dict { PACKAGE_PIN C11  IOSTANDARD LVCMOS33 } [get_ports { PS2_DATA }];
 
# VGA 11 bit
#set_property -dict { PACKAGE_PIN C3 IOSTANDARD LVCMOS33 } [get_ports {vga_hsync}];
#set_property -dict { PACKAGE_PIN E3 IOSTANDARD LVCMOS33 } [get_ports {vga_vsync}];
#set_property -dict { PACKAGE_PIN B5 IOSTANDARD LVCMOS33 } [get_ports {vga_r[0]}];
#set_property -dict { PACKAGE_PIN D2 IOSTANDARD LVCMOS33 } [get_ports {vga_r[1]}];
#set_property -dict { PACKAGE_PIN C2 IOSTANDARD LVCMOS33 } [get_ports {vga_r[2]}];
#set_property -dict { PACKAGE_PIN A3 IOSTANDARD LVCMOS33 } [get_ports {vga_r[3]}];
#set_property -dict { PACKAGE_PIN A2 IOSTANDARD LVCMOS33 } [get_ports {vga_g[0]}];
#set_property -dict { PACKAGE_PIN B2 IOSTANDARD LVCMOS33 } [get_ports {vga_g[1]}];
#set_property -dict { PACKAGE_PIN A1 IOSTANDARD LVCMOS33 } [get_ports {vga_g[2]}];
#set_property -dict { PACKAGE_PIN B4 IOSTANDARD LVCMOS33 } [get_ports {vga_g[3]}];
#set_property -dict { PACKAGE_PIN A4 IOSTANDARD LVCMOS33 } [get_ports {vga_b[0]}];
#set_property -dict { PACKAGE_PIN B1 IOSTANDARD LVCMOS33 } [get_ports {vga_b[1]}];
#set_property -dict { PACKAGE_PIN B0 IOSTANDARD LVCMOS33 } [get_ports {vga_b[2]}];
#set_property -dict { PACKAGE_PIN C4 IOSTANDARD LVCMOS33 } [get_ports {vga_b[3]}];
 
# CMOS Camera (J4 CONNECTOR)
#set_property -dict { PACKAGE_PIN L13 IOSTANDARD LVCMOS33} [get_ports {ov7670_sioc}];
#set_property -dict { PACKAGE_PIN M12 IOSTANDARD LVCMOS33} [get_ports {ov7670_siod}];
#set_property -dict { PACKAGE_PIN H13 IOSTANDARD LVCMOS33} [get_ports {ov7670_vsync}];
#set_property -dict { PACKAGE_PIN H12 IOSTANDARD LVCMOS33} [get_ports {ov7670_href}];
#set_property -dict { PACKAGE_PIN F10 IOSTANDARD LVCMOS33} [get_ports {ov7670_pclk}];
#set_property -dict { PACKAGE_PIN G10 IOSTANDARD LVCMOS33} [get_ports {ov7670_xclk}];
#set_property -dict { PACKAGE_PIN C13 IOSTANDARD LVCMOS33} [get_ports {ov7670_data[7]}];
#set_property -dict { PACKAGE_PIN D13 IOSTANDARD LVCMOS33} [get_ports {ov7670_data[6]}];
#set_property -dict { PACKAGE_PIN E12 IOSTANDARD LVCMOS33} [get_ports {ov7670_data[5]}];
#set_property -dict { PACKAGE_PIN F12 IOSTANDARD LVCMOS33} [get_ports {ov7670_data[4]}];
#set_property -dict { PACKAGE_PIN F13 IOSTANDARD LVCMOS33} [get_ports {ov7670_data[3]}];
#set_property -dict { PACKAGE_PIN G13 IOSTANDARD LVCMOS33} [get_ports {ov7670_data[2]}];
#set_property -dict { PACKAGE_PIN D12 IOSTANDARD LVCMOS33} [get_ports {ov7670_data[1]}];
#set_property -dict { PACKAGE_PIN D11 IOSTANDARD LVCMOS33} [get_ports {ov7670_data[0]}];
#set_property -dict { PACKAGE_PIN E11 IOSTANDARD LVCMOS33} [get_ports {ov7670_reset}];
set_property -dict { PACKAGE_PIN F11 IOSTANDARD LVCMOS33} [get_ports {ov7670_pwdn}];
 
#19 pin expansion connector (J5 CONNECTOR)
#pin0 5V
#pin1 NC
#pin2 3V3
#pin3 GND
#set_property -dict { PACKAGE_PIN L13 IOSTANDARD LVCMOS33} [get_ports {pin5}];
#set_property -dict { PACKAGE_PIN M12 IOSTANDARD LVCMOS33} [get_ports {pin6}];
#set_property -dict { PACKAGE_PIN H13 IOSTANDARD LVCMOS33} [get_ports {pin7}];
#set_property -dict { PACKAGE_PIN H12 IOSTANDARD LVCMOS33} [get_ports {pin8}}];
#set_property -dict { PACKAGE_PIN F10 IOSTANDARD LVCMOS33} [get_ports {pin9}}];
#set_property -dict { PACKAGE_PIN G10 IOSTANDARD LVCMOS33} [get_ports {pin10}];
#set_property -dict { PACKAGE_PIN C13 IOSTANDARD LVCMOS33} [get_ports {pin11}];
#set_property -dict { PACKAGE_PIN D13 IOSTANDARD LVCMOS33} [get_ports {pin12}];
#set_property -dict { PACKAGE_PIN E12 IOSTANDARD LVCMOS33} [get_ports {pin13]}];
#set_property -dict { PACKAGE_PIN F12 IOSTANDARD LVCMOS33} [get_ports {pin14}];
#set_property -dict { PACKAGE_PIN F13 IOSTANDARD LVCMOS33} [get_ports {pin15}];
#set_property -dict { PACKAGE_PIN G13 IOSTANDARD LVCMOS33} [get_ports {pin16}];
#set_property -dict { PACKAGE_PIN D12 IOSTANDARD LVCMOS33} [get_ports {pin17}];
#set_property -dict { PACKAGE_PIN D11 IOSTANDARD LVCMOS33} [get_ports {pin18}];
#set_property -dict { PACKAGE_PIN E11 IOSTANDARD LVCMOS33} [get_ports {pin19}];
#set_property -dict { PACKAGE_PIN F11 IOSTANDARD LVCMOS33} [get_ports {pin20}];
