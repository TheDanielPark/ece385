#
# uC/OS-II driver source file listings...
#

# uC/OS-III-specific C sources
add_sw_property c_source UCOSIII/src/alt_usleep.c
add_sw_property c_source UCOSIII/src/os_cpu_c.c

# uC/OS-III-specific includes
add_sw_property include_source UCOSIII/inc/includes.h
# JDS - April 30, 2015 - removed when fixing case 296180
#add_sw_property include_source UCOSIII/inc/app_cfg.h
add_sw_property include_source UCOSIII/inc/os_cpu.h

# uC/OS-II-specific ASM sources
add_sw_property asm_source UCOSIII/src/os_cpu_a.S

# End of file

