#
# altera_ro_zipfs_driver.tcl
#

# Create a new software package and name it "altera_ro_zipfs"
create_sw_package altera_ro_zipfs

# The version of this software
set_sw_property version 18.1

# Initialize the driver in alt_sys_init()
set_sw_property auto_initialize true

# Location in generated BSP that above sources will be copied into
set_sw_property bsp_subdirectory drivers

#
# Source file listings...
#

# C/C++ source files
add_sw_property c_source HAL/src/altera_ro_zipfs.c

# Include files
add_sw_property include_source HAL/inc/altera_ro_zipfs.h

# Add to public makefile C-pre-processor definitions
add_sw_property alt_cppflags_addition "-DRO_ZIPFS"

# This driver supports HAL & UCOSII BSP (OS) types
add_sw_property supported_bsp_type HAL
add_sw_property supported_bsp_type UCOSII

# Add the following configuration options to the BSP:
add_sw_setting quoted_string system_h_define ro_zipfs_name ALTERA_RO_ZIPFS_NAME "/mnt/rozipfs" "Mount point"

add_sw_setting hex_number system_h_define ro_zipfs_offset ALTERA_RO_ZIPFS_OFFSET 0x100000 "Offset of file system from base of flash"

add_sw_setting hex_number system_h_define ro_zipfs_base ALTERA_RO_ZIPFS_BASE 0x0 "Base address of flash memory device"

# End of file
