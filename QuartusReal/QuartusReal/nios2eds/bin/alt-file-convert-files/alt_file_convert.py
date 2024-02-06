#!/usr/bin/python

import os
import sys
import getopt
import hex_memory
from hex_memory import HexMemory, HexRecord, parse_hex_record
import subprocess
import tempfile

#list of supported data widths
_SUPPORTED_DATA_WIDTHS=[8, 16, 32, 64, 128, 256]

def usage():
    print("alt-file-convert (BETA): General file conversion tool. In 14.1, primarily used for generating Nios II application image for Max Onchip Flash and EPCQ.")
    print()
    print("Usage: alt-file-convert -I <input_type> -O <output_type> [option(s)] --input=<input_file> --output=<output_file>")
    print()
    print("For 14.1, this tool is limited to the following uses: ")
    print("\t1. Convert between Intel HEX (byte addressed) and Quartus HEX (word addressed)")
    print("\t2. Convert between Quartus HEX files of various widths")
    print("\t3. Convert an ELF file to a HEX file and append a bootcopier (used for application flash image for Max Onchip Flash and EPCQ")
    print("\n\tMore to come in later releases! Stay tuned...")
    print()
    print("Options:")
    print("-h, --help - prints usage")
    print("-I - input type")
    print("-O - output type")
    print("--base - base address (in hex) f target memory (default 0x0)")
    print("--end - end address (in hex) of target memory (default 0xFFFFFFFF)")
    print("--reset - reset address (in hex) of target memory (default None)")
   
    print("--input - path to input file")
    print("--output - path to output file")
    print("--in-data-width - data width of inputfile", \
            _SUPPORTED_DATA_WIDTHS, "(default 8)")
    print("--out-data-width - data width of target memory", \
            _SUPPORTED_DATA_WIDTHS, "(default None)")
    print("--boot - location of boot file to be appended (srec format)")

long_options = ["help", "input=", "output=", "base=", "end=", "reset=", "in-data-width=",\
        "out-data-width=", "boot="]

_INPUT_FILE_TYPES = ["ihex", "hex", "elf", "elf32-littlenios2"]
_HIDDEN_INPUT_FILE_TYPES = ["byte_per_line_hex"]

def main():
    if sys.version_info[0] != 3:
        print("alt-file-convert should be run using quartus_py")
        sys.exit(2)

    #option parsing
    try:
        opts, args = getopt.getopt(
                sys.argv[1:], "hI:O:", long_options)
    except getopt.GetoptError as e:
        print("Argument ERROR! : " + str(e) + "\n")
        usage()
        sys.exit(2)

    infilename, outfilename = None, None 

    in_type, out_type = None, None

    data_width_in, data_width_out = 8, None

    base_address, end_address, reset_address = 0x0, 0xFFFFFFFF, None

    boot_file = None

    #option handling
    for o, a in opts:
        if o in ("-h", "--help"):
            usage()
            sys.exit()
        elif o == "-I":
            in_type = process_type_param(a)
        elif o == "-O":
            out_type = process_type_param(a)
        elif o == "--input":
            infilename = a
        elif o == "--output":
            outfilename = a
        elif o == "--out-data-width":
            data_width_out = process_width_param(a)
        elif o == "--in-data-width":
            data_width_in = process_width_param(a)
        elif o == "--base":
            base_address = process_address_param(a)
        elif o == "--end":
            end_address = process_address_param(a)
        elif o == "--reset":
            reset_address = process_address_param(a)
        elif o == "--boot":
            boot_file = a
        else:
            print("Unhandled option: ", a)
            usage()
            sys.exit(2)

    for option in [infilename, outfilename, in_type, out_type]:
        if option == None:
            print("Missing argument!\n")
            usage()
            sys.exit()


    #some sanity validation
    if base_address >= end_address:
        print("Base address can't be less then end address")
        sys.exit(2)
    
    if reset_address and (reset_address < base_address or reset_address > end_address):
        print("If reset address is specified, it must be between end and base address")
        sys.exit(2)

    #check for valid input and output type combination
    #call appropriate conversion mechanism
    if in_type == "hex"  and out_type == "hex":
        print("Converting data width of Quartus HEX file")
        if not data_width_in or not data_width_out:
            print("Missing out-data-width or in-data-width argument!")
            sys.exit(2)
        do_hex_conversion(base_address, end_address, data_width_in, data_width_out, infilename, outfilename)
    
    elif in_type == "ihex" and out_type == "hex":
        if not data_width_out:
            print("Missing out-data-width argument!")
            sys.exit(2)
        print("Converting Intel HEX to Quartus HEX file")
        do_hex_conversion(base_address, end_address, 8, data_width_out, infilename, outfilename)
    
    elif in_type == "hex" and out_type == "ihex":
        if not data_width_in:
            print("Missing in-data-width argument!")
            sys.exit(2)
        print("Converting Quartus HEX file to Intel HEX file")
        do_hex_conversion(base_address, end_address, data_width_in, 8, infilename, outfilename)
    
    elif in_type == "ihex" and out_type == "byte_per_line_hex":
        print("Converting from Intel HEX to Byte Per Line HEX. This feature is meant for internal use only.")
        do_ihex_to_byte_per_line_conversion(infilename, outfilename)

    elif (in_type == "elf32-littlenios2" or in_type == "elf") and out_type == "hex":
        if in_type == "elf":
            in_type = "elf32-littlenios2"
            
        #For 14.1, alt-file-convert is only used when a bootcopier is needed
        if boot_file == None:
            print("Use elf2hex if you don't have a boot file to append.")

       
        print("Converting Nios II ELF file to HEX file. Appending boot file.")
        do_elf2hex_conversion(base_address, end_address, reset_address, data_width_out,
                boot_file, infilename, outfilename)
        

    else:
        print("Converting from", in_type, " to ", out_type, " is currently unsupported.")

    
def do_hex_conversion(base_address, end_address, data_width_in, data_width_out, infilename, outfilename):
    '''Converts a Quartus HEX file of data width equal to data_width_in to a Quartus HEX file of 
    data width equal to data_width_out. 
    
    By setting data_width_in or data_width_out to 8, you can convert to and from Intel HEX as well.
    '''
    #create file objects for input and output files
    try:
        infile = open(infilename,'r')
    except IOError:
        print("Can't find file:", infilename)
        sys.exit(2)
    
    outfile = open(outfilename, 'wb')#open in binary mode so we can force /r/n line endings
    
    #create HexMemory object that will hold contents of hex file
    hex_memory = HexMemory(base_address, end_address, 
            int(data_width_in), int(data_width_out))
    
    #read hex file into HexMemory object
    for line in infile:
        if isinstance(line,bytes):
            line = line.decode('utf-8')
        
        hex_record = parse_hex_record(line)
        hex_memory.add_hex_record(hex_record)

    #output HexMemory into ouput hex file
    for hex_record in hex_memory:
        line = str(hex_record) + "\r\n" #HEX files use dos line endings
        outfile.write(bytes(line, 'UTF-8'))
    
    #close file objects
    infile.close()
    outfile.close()

   
def do_elf2hex_conversion(base_address, end_address, reset_address, data_width_out, 
        boot_file, infilename, outfilename):
    '''Convert from an ELF file to a HEX file. 
    For 14.1, only outputs Intel HEX file (byte addressed). This is equivalent to a Quartus HEX 
    file with a data width of 8. Eventually, this will support arbritary data widths but for 14.1 
    byte-addressed is sufficient.
    '''

    temp_flash_file = tempfile.NamedTemporaryFile()
    temp_flash_file.close() #Windows requires this file to be closed before another process can access it

    subprocess.call(["elf2flash", "--base=" + hex(base_address), 
        "--reset=" + hex(reset_address), "--end=" + hex(end_address), "--boot=" + boot_file,
        "--input=" + infilename, "--output=" + temp_flash_file.name])

    subprocess.call(["nios2-elf-objcopy", "-I", "srec", "-O", "ihex", temp_flash_file.name, outfilename])
   
def do_ihex_to_byte_per_line_conversion(infilename, outfilename):
    '''Supports converting a Intel HEX file to a special internal file that has one byte of 
    data per line.
    '''
    #create file objects for input and output files
    try:
        infile = open(infilename,'r')
    except IOError:
        print("Can't find file:", infilename)
        sys.exit(2)
    
    outfile = open(outfilename, 'wb')
    
    #read file one hex record at a time
    for line in infile:
        if isinstance(line,bytes):
            line = line.decode('utf-8') 
        
        #parse each hex record
        hex_record = parse_hex_record(line)
       
        #if the hex record is a data record, write out each byte to the outfile
        if hex_record.record_type == hex_memory._DATA:
            for byte in hex_record.data:
                outfile.write(bytes(("%02X" % byte)+ "\n", 'UTF-8'))
    
    #close file objects
    infile.close()
    outfile.close()


def process_type_param(input_type):
    if (input_type in _INPUT_FILE_TYPES) or (input_type in _HIDDEN_INPUT_FILE_TYPES):
        return input_type
    else:
        print("Unknown type: ", input_type)
        print("Type values should be one of: ", _INPUT_FILE_TYPES)
        sys.exit(2)

def process_width_param(width):
    try:
        if int(width) not in _SUPPORTED_DATA_WIDTHS:
            print("Values for width must be one of: ", _SUPPORTED_DATA_WIDTHS)
            sys.exit(2)
        return width
    except ValueError:
        print("Invalid value for width: " + width)
        sys.exit(2)

def process_address_param(address):
    try:
        addr = int(address, 16) #For 14.1, only HEX values are accepted for addresses
        return addr
    except ValueError:
        print("Invalid hex value for address: " + address)

    
if __name__ == '__main__':   
    if os.environ["SOPC_KIT_NIOS2"] == "": 
        print("SOPC_KIT_NIOS2 is not definded. This should be set to the path of your nios2eds installation directory.")
        sys.exit(2)
    try:
        main()
    except Exception as e:
        print("ERROR! Unhandled alt-file-convert exception:", str(e))

