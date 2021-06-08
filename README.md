# Intermittent Multidimensional Discrite Cosine Transform

This core implements a multidimensional cosine transform accelerator with
effective response to a transient based envirronment.   

## Description

The core is supposed to operate under non standard power level conditions so the computation is expected to halt depending on power availability, hence the name intermittent.
After a halt the core is expected to reprise computation from the last saved
checkopoint, leaving a transparent interface to the end user.

The effective intermittent properties of this core are only emulated and not
hardware synthesizable since current FPGA technology doesn't embedd high speed
non volatile memory hardware.  

The scope of this core is to demonstrate the use of this
[framework](https://github.com/simoneruffini/NORM). 

## Dependencies
For plug and play usage this dependencies are requeired:
- [VSG](https://github.com/jeremiah-c-leary/vhdl-style-guide) > 3.1.0
- [GO](https://golang.org/) > 1.16.5
- [VIVADO 2020.2](https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools/2020-2.html)

Otherwise the code is fully opensource and can be simulated with any HDL toolchain supporting VHDL 2008.

## Copyrights 
This code is based on previous work of Michal Krepa on opencores.org licensed under MIT:
[MDCT](https://opencores.org/projects/mdct)

This code is MIT licensed.