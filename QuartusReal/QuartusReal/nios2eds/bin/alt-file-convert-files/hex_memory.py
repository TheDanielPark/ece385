from memory import Memory
import re

#constants for hex record type
_DATA=0 
_END_OF_FILE=1
_EXT_SEGMENT_ADDRESS=2 #extended segment address record
_START_SEGMENT_ADDRESS=3 #for 80x86 processors, init content of CS:IP
_EXT_LINEAR_ADDRESS=4 #extender linear address record
_START_LINEAR_ADDRESS=5 #start linear address record (MDK-ARM)

#other constants
_BYTES_PER_RECORD = 32 #bytes per hex record
_MAX_OFFSET = 0xFFFF #largest possible address without using a extended record
_MAX_ADDRESS = 0xFFFFFFFF #hex format only supports 32 bit address space

class HexMemory(Memory):
    '''HexMemory represents the contents of a intel or altera hex file. It 
    stores the contents in a format agnostic way (MemoryContent class) and can 
    generate either format from its stored contents.
    '''
    def __init__(self, base_address, end_address, data_width_in, 
            data_width_out):
        '''Initialize HexMemory.

        param base_address - positive integer
        param end_address - positive integer less then 2^32-1
        param data_width_in - data width of hex in field
        param data_width_out - data width of hex out field 
        ''' 
        if end_address > _MAX_ADDRESS:
            raise Exception("Hex files only supports a 32 bit address space")

        if end_address < 0 or base_address < 0 or end_address < base_address:
            raise Exception("Base and end address must be positive. " + \
                    "Base address must be less then end address.")

        Memory.__init__(self, base_address, end_address)

        self.data_width_in, self.data_width_out = data_width_in, data_width_out
        
        #this address will be added to the offset of every data record
        self.extended_address = 0

        #if not None, we need to add a Start Segment Address record to the output file
        self.start_segment_address = None
        
        #if not None, we need to add a Start Linear Address record to the output file
        self.start_linear_address = None

    def add_hex_record(self, hex_record):
        '''Add the contents of a hex record to the HexMemory structure if its 
        a data record. Otherwise it performs address modification indicated by 
        record type / data.

        param hex_record - HexRecord object
        '''
        hr = hex_record

        if hr.record_type == _DATA:
            modified_address = hr.address + self.extended_address
            bytes_per_word = self.data_width_in // 8 
            self.add_data(modified_address, hr.data, bytes_per_word)
        
        elif hr.record_type == _END_OF_FILE:
            #do nothing
            return

        elif hr.record_type == _EXT_SEGMENT_ADDRESS:
            #further data record will be modified by this address
            self.extended_address = ((hr.data[0] << 8) | (hr.data[1])) << 4
        
        elif hr.record_type == _START_SEGMENT_ADDRESS:
            #a start segment record was found in input file
            #an identical record will be placed before the end of the output file
            #if there's more then one such record, only the last one will be placed
            self.start_segment_address = hr.data
            return
        
        #TODO check the shifting
        elif hr.record_type == _EXT_LINEAR_ADDRESS:
            #further data records will be modified by this address
            self.extended_address = ((hr.data[0] << 8) | (hr.data[1])) << 16
        
        elif hr.record_type == _START_LINEAR_ADDRESS:
            #a start linear address record was found in input file
            #an identical record will be placed before the end of the output file
            #if there's more then one such record, only the last one will be placed
            self.start_linear_address = hr.data
            return

        else:
            raise Exception("Unknown hex record type: " + str(hr.record_type))
    
    def __iter__(self):
        '''Iterator returns a HexGenerator. HexGenerator is a iterator that 
        can be used to write the hex file a HexMemory represents.
        '''
        return HexGenerator(self)


class HexGenerator:
    '''HexGenerator is an iterator for the HexMemory it is intialized with. 
    Everytime next() is called, the next line in the hex file represented by 
    hex_memory is returned.
    '''
    def __init__(self, hex_memory):
        '''__init__() intializes this iterator with the starting segment 
        information.

        param hex_memory - HexMemory object
        '''
        self.hex_memory = hex_memory
        self.segment_address_list = hex_memory.get_segment_address_list()

        self.bytes_per_word = hex_memory.data_width_out // 8
        self.words_per_line = _BYTES_PER_RECORD // self.bytes_per_word

        self.segment_address = None #current segment base address
        self.segment_offset = None #offset into current segment
        self.hex_ofset = None #offset of next byte in hex file
        self.first_segment = True #flag to create initial linear record
        self.no_more_data = False #flag to indicate that there are no more data segments
        self.end_of_file = False #flag to indicate that end of file record has been placed
        #if start segment record is needed, this will be four bytes, otherwise None
        self.start_segment_address = self.hex_memory.start_segment_address
        #if start linear address record is needed, this will be four bytes, otherwise None
        self.start_linear_address = self.hex_memory.start_linear_address

        self.__switch_to_next_segment()

    def __next__(self):
        '''next() returns the next hex record in the file that is represented 
        by the HexMemory object that created this HexGenerator object.
        '''
        data_bytes = []

        #get data bytes if there is data
        if not self.no_more_data:
            #Need to lay out extended linear address record for first record
            if self.first_segment:
                self.first_segment = False
                return self.create_ext_linear_address_record(self.segment_address)
            
            #if hex offset is greater thsn the max offset, we need a extended 
            #linear record to set the upper bits
            if self.hex_offset > _MAX_OFFSET:
                address = self.__calculate_ext_linear_address()
                return self.create_ext_linear_address_record(address)

            #calculate number of data bytes to get for the next data record
            if self.hex_offset + self.words_per_line - 1 > _MAX_OFFSET:
                bytes_to_get = (_MAX_OFFSET + 1) - self.hex_offset
            else:
                bytes_to_get = _BYTES_PER_RECORD

            #try to get the data bytes
            data_bytes = self.hex_memory.get_data(self.segment_address, 
                    self.segment_offset, bytes_to_get, self.bytes_per_word)

        if not data_bytes:
            #if no data bytes were returned, we move to the next segment
            self.__switch_to_next_segment()

            if not self.segment_address:
                #no more segments, need to generate end of file record
                self.no_more_data = True
            else:
                #new segment, need a record to set upper bits of address
                return self.create_ext_linear_address_record(self.segment_address)
        else: 
            #create data record
            data_record = self.create_data_record(self.hex_offset, data_bytes)

            #update segment and hex file offsets
            self.segment_offset += len(data_bytes)
            self.hex_offset += len(data_bytes) // self.bytes_per_word

            return data_record

        #If there are no remaining data segments, we need to place end of file records
        if self.no_more_data:
            if not (self.start_segment_address == None):
                #first place a start segment record if required
                start_segment_address_record = \
                        self.create_start_segment_address_record(self.start_segment_address)
                self.start_segment_address = None
                return start_segment_address_record
            elif not (self.start_linear_address == None):
                #place a start linear address record if required
                start_linear_address_record = \
                        self.create_start_linear_address_record(self.start_linear_address)
                self.start_linear_address = None
                return start_linear_address_record
            elif not self.end_of_file:
                #finally place an end of file record
                self.end_of_file = True
                return self.create_end_of_file_record()
            else:
                #all done
                raise StopIteration


    def __switch_to_next_segment(self):
        '''Private method used to switch to next segment after the data from 
        a previous segment is done. Class variables are updated accordingly.
        '''
        if self.segment_address_list:
            self.segment_address = self.segment_address_list.pop(0)
            self.segment_offset = 0
            self.hex_offset = \
                    (self.segment_address // self.bytes_per_word) & _MAX_OFFSET
        else:
            self.segment_address, self.segment_offset, self.hex_offset = \
                    None, None, None
            self.no_more_data = True

    def __calculate_ext_linear_address(self):
        '''Private method that calculates the upper 16 bits of the address of 
        the next address to go into the hex file. This is used to generate a 
        extended linear address record.
        '''
        next_address = self.segment_address + self.segment_offset
        self.hex_offset = next_address & _MAX_OFFSET
        return (next_address & 0xFFFF0000) //  self.bytes_per_word


    def create_ext_linear_address_record(self, address):
        '''Returns a extended linear address record. The upper 16 bits of 
        address are used to create the record.
        
        param address: 32 bit address
        '''
        address >>= 16
        base_address = [(address >> 8) & 0xFF, address &  0xFF]
        return HexRecord(2, 0x0, _EXT_LINEAR_ADDRESS, base_address) 


    def create_start_segment_address_record(self, address_bytes):
        '''Returns a start segment address record. This record is used to initialize the 
        CS:IP reigster for 80x86 processors.
        
        param address_bytes: listof(bytes) - 4 bytes representing 32 bit CS:IP initiial value
        '''
        return HexRecord(4, 0x0, _START_SEGMENT_ADDRESS, address_bytes)

    def create_start_linear_address_record(self, address_bytes):
        '''Returns a start segment address record. This record is to specify the initial 32-bi 
        value of the EIP register of 80386 and higher CPU.
        
        param address_bytes: listof(bytes) - 4 bytes representing 32 bit EIP initiial value
        '''
        return HexRecord(4, 0x0, _START_LINEAR_ADDRESS, address_bytes)


    def create_data_record(self, data_address, data_bytes):
        '''Returns a data record.
        
        param data_address: 16 bit address (offset)
        param data_bytes: list of data bytes
        '''
        return HexRecord(len(data_bytes), data_address, _DATA, data_bytes) 
        

    def create_end_of_file_record(self):
        '''Returns an end of file record.'''
        return HexRecord(0, 0, _END_OF_FILE, [])


class HexRecord:
    '''
    The HexRecord class represent a single hex record (i.e hex file line).
    The format is identical for altera and intel hex except that the address is 
    a word offset for altera and a byte offset for intel. This difference 
    doesn't effect the implementation of this class. 
    '''
    def __init__(self, numb_bytes, address, record_type, data, checksum = None):
        '''Initialize HexRecord object.

        param numb_bytes - number of bytes in record
        param address - 16 bit address integer
        param record_type - integer from 0 to 5
        param data - list of bytes with size equal to numb_bytes
        param checksum - single byte equal to checksum of record (default None)
        '''
        self.numb_bytes, self.address, self.record_type, self.data, \
                self.checksum =\
                numb_bytes , address, record_type, data, checksum
        
        if checksum == None:
            self.checksum = self.calculate_checksum()

        elif self.calculate_checksum() != self.checksum:
            raise Exception("Bad checksum on record: \"" + str(self) \
                    + "\" - Should be 0x" + str(self.calculate_checksum()) \
                    + " and it was 0x" + str(self.checksum))
        
    def calculate_checksum(self):
        '''Calculates checksum of hex record. This is the two complements of 
        the sum of the bytes in the record modulo 256.
        '''
        checksum = sum(self.data) + self.numb_bytes + self.record_type
        checksum += (self.address & 0xFF) + ((self.address >> 8)  & 0xFF)
        checksum = ~checksum + 1
        checksum = checksum & 0xFF
        return checksum

    def __str__(self):
        '''Returns string representation of hex record used to print record to 
        file. No new line is appended.
        '''
        hex_string = ":" + ("%02X" % self.numb_bytes) + ("%04X" % self.address) \
                + ("%02X" % self.record_type)
        for byte in self.data:
            hex_string += "%02X" % byte
        hex_string += "%02X" % self.checksum
        return hex_string


#regular expression string and object for matching Hex Record
_hex_reg_string = \
    r":([0-9A-Fa-f]{2})" + r"([0-9A-Fa-f]{4})" + r"([0-9A-Fa-f]{2})" + \
    r"([0-9A-Fa-f]*)" + r"([0-9A-Fa-f]{2})"
_hex_regex = re.compile(_hex_reg_string)

def parse_hex_record(hex_string):
    '''Parses altera or intel hex record string and returns a HexRecord object.
    The hex record format is :llaaaatt[dd...]cc
    ll is the number of bytes (dd), aaaa is the address field, tt is the type of 
    record, [dd...] is the data bytes and cc is the checksum.
    read more here: http://www.keil.com/support/docs/1584/
    '''
    match = _hex_regex.match(hex_string.strip())
    
    if match == None:
        raise Exception("Hex record not formated properly: " + hex_string)

    #get values of various fields
    numb_bytes = int(match.group(1), 16)
    address = int(match.group(2), 16)
    record_type = int(match.group(3), 16)
    data_string = match.group(4)
    checksum = int(match.group(5), 16)
    
    #TODO: Endianess switch should go here upon parsing
    data = []
    try:
        for i in range(0, numb_bytes):
            data.append(int(data_string[2*i : 2 + 2*i] , 16))
    except IndexError:
        raise Exception("Number of data bytes less then number indicated.")

    return HexRecord(numb_bytes, address, record_type, data, checksum)
