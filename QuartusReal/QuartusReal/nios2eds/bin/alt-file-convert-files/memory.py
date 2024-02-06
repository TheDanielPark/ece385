class Memory(object):
    '''
    Memory describe the contents of a memory. It consists of a dictionary 
    mapping Segment base addresses to Segments. add_data and get_data allow
    users to add and get data from these segments. The list of segment base 
    addresses can be retrieved with get_segment_address_list
    '''

    def __init__(self, base_address, end_address):
        self.memory = {}
        
        self.base_address = base_address
        self.end_address = end_address

        self.current_segment = None


    def add_data(self, address, data, bytes_per_word = 1, big_endian = False):
        '''Add new_bytes to memory. Must be within memory range. Memory is 
        added in continguous segments. If address is different then next empty
        address of current segment, then a new segment is created. If 
        bytes_per_word is not 1 and little endian ordering is used, the bytes 
        will be reversed.

        param address: address of first byte in new_bytes
        param data_bytes: bytes to add to memory
        param bytes_per_word: number of bytes in a word (default 1)
        param big_endian: is data added big endian format (default False)
        '''
       
        #if bytes_per_word is 1, then address == byte_address
        byte_address = address * bytes_per_word

        #ensure addresses of added bytes is within memory range
        if byte_address < self.base_address or \
                (byte_address + len(data) - 1) > self.end_address:
            raise Exception("Memory address outside of address range.")
 
        if self.current_segment == None:
            self.__switch_segment(byte_address)

        #create new segment if address is different then segment's next address
        if byte_address != self.current_segment.get_next_address():
            self.__switch_segment(byte_address)
       
        if big_endian:
            #if big endian, then bytes in data is already in correct order
            data_bytes = data
        else:
            #if little endian, we need to reverse the bytes of each word
            data_bytes, data_offset = [], 0
            while len(data_bytes) < len(data):
                temp_bytes = data[data_offset: data_offset + bytes_per_word]
                temp_bytes.reverse()
                data_bytes.extend(temp_bytes) 
                data_offset += bytes_per_word

        self.current_segment.add_data(data_bytes)

    
    def get_data(self, seg_address, offset,  numb_bytes, bytes_per_word, 
            big_endian = False):
        '''Returns up to numb_bytes of data from seg_address + offset. May 
        return less then numb_bytes. Number of bytes in segment must be 
        divisible by bytes_per_word or an error is thrown. numb_bytes should 
        be divisible by bytes_per_word
        
        param seg_address: base address of segment to get data from
        param offset: offset into segment
        param numb_bytes: number of bytes to return. May return less
        param bytes_per_word: number of bytes in word (data width)
        param little_endian: use big endian byte ordering (default False)
        '''

        if numb_bytes % bytes_per_word != 0:
            raise Exception("Number of bytes not divisible by bytes per word")

        segment = self.memory[seg_address]
        segment_data = segment.get_data()
        
        #Try to get numb_bytes from seg_address + offset
        data_bytes, segment_offset = [], offset
        while len(data_bytes) < numb_bytes and \
                segment_offset < len(segment_data):

            temp_bytes = \
                    segment_data[segment_offset: segment_offset + bytes_per_word]
            
            #pad if fewer bytes then needed for word
            self.__pad_data_to_get_word(temp_bytes, bytes_per_word, 0)

            #Reverse bytes if little endian
            if not big_endian:
                temp_bytes.reverse()
                     
            data_bytes.extend(temp_bytes)
            segment_offset += bytes_per_word
       
        return data_bytes


    def get_segment_address_list(self):
        '''Retrun sorted list of segment addresses.'''
        return sorted(self.memory.keys())

    def get_overlapping_regions(self):
        #TODO: should return list of pairs of overlapping segments
        #sufficient condition to test overlap
        #x1 <= y2 && y1 <= x2, assuming x1 <= x2 and y1 <= y2 
        pass
 
    def __switch_segment(self, segment_base):
        '''Creates a new segment with base address "segment_base"'''
        self.current_segment = Segment(segment_base)
        self.memory[segment_base] = self.current_segment 

    def __pad_data_to_get_word(self, data, bytes_per_word, pad_value):
        if len(data) < bytes_per_word:
            bytes_to_add = bytes_per_word - len(data)
            data.extend([pad_value]*bytes_to_add)

class Segment:
    '''
    A segment is a chunk of contiguous bytes starting at a base address.
    It's described by a base_address and a array of bytes
    '''

    def __init__(self, base_address):
        self.base_address = base_address
        self.byte_array = []

    def add_data(self, new_bytes):
        '''Add bytes to segment'''
        self.byte_array.extend(new_bytes)

    def get_next_address(self):
        '''Returns next empty address of segment'''
        return self.base_address + len(self)

    def get_data(self):
        '''Returns data bytes'''
        return self.byte_array
    
    def __len__(self):
        return len(self.byte_array)
