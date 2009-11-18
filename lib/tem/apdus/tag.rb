# TEM tag management using the APDU API. 
#
# Author:: Victor Costan
# Copyright:: Copyright (C) 2007 Massachusetts Institute of Technology
# License:: MIT

# :nodoc: namespace
module Tem::Apdus
  
  
module Tag
  # Writes an array of bytes to the TEM's tag.
  #
  # The TEM's tag can only be written once, when the TEM is emitted.
  #
  # Args:
  #   tag_data:: the array of bytes to write to the TEM's tag
  #
  # The return value is unspecified. 
  def set_raw_tag_data(tag_data)    
    buffer_id = post_buffer tag_data
    begin
      @transport.iso_apdu! :ins => 0x30, :p1 => buffer_id
    ensure
      release_buffer buffer_id
    end
  end
  
  # The number of bytes in the TEM's tag.
  #
  # This method issues an APDU when it's called (i.e. no caching is done).
  def get_raw_tag_length
    response = @transport.iso_apdu! :ins => 0x31
    return read_tem_short(response, 0)
  end
  
  # Reads raw bytes in the TEM's tag.
  #
  # Args:
  #   offset:: the offset of the first byte to be read from the TEM's tag
  #   length:: the number of bytes to be read from the TEM's tag.
  #
  # Returns an array of bytes containing the requested TEM tag data.  
  def get_raw_tag_data(offset, length)
    buffer_id = alloc_buffer length
    begin
      @transport.iso_apdu! :ins => 0x32, :p1 => buffer_id,
                           :data => [to_tem_short(offset),
                                     to_tem_short(length)].flatten
      tag_data = read_buffer buffer_id
    ensure
      release_buffer buffer_id
    end
    tag_data
  end

  # Encodes structured tag data into raw TLV tag data.
  #
  # Args:
  #   data:: a hash whose keys are numbers (tag keys), and whose values are
  #          arrays of bytes (values associated with the tag keys)
  #
  # Returns an array of bytes with the raw data.
  def self.encode_tag(data)
    data.keys.sort.map { |key|
      value = data[key]
      [Tem::Abi.to_tem_ubyte(key), Tem::Abi.to_tem_short(value.length), value]
    }.flatten
  end
  
  # Decodes raw TLV tag data into its structured form.
  #
  # Args:
  #  raw_data:: an array of bytes containing the raw data in the TEM tag
  #
  # Returns a hash whose keys are numbers (tag keys), and whose values are
  # arrays of bytes (values associated with the tag keys). 
  def self.decode_tag(raw_data)    
    data = {}
    index = 0
    while index < raw_data.length
      key = Tem::Abi.read_tem_ubyte raw_data, index
      value_length = Tem::Abi.read_tem_short raw_data, index + 1
      data[key] = raw_data[index + 3, value_length]
      index += 3 + value_length
    end
    data
  end

  # Writes an structured data to the TEM's tag.
  #
  # The TEM's tag can only be written once, when the TEM is emitted.
  #
  # Args:
  #   tag_data:: the array of bytes to write to the TEM's tag
  #
  # The return value is unspecified. 
  def set_tag(data)
    raw_data = Tem::Apdus::Tag.encode_tag data
    set_raw_tag_data raw_data
    icache[:tag] = Tem::Apdus::Tag.decode_tag raw_data
  end

  # The TEM's tag data.
  #
  # Returns a hash whose keys are numbers (tag keys), and whose values are
  # arrays of bytes (values associated with the tag keys). The result of this
  # method is cached. 
  def tag
    return icache[:tag] if icache[:tag]

    raw_tag_data = get_raw_tag_data 0, get_raw_tag_length
    icache[:tag] = Tem::Apdus::Tag.decode_tag raw_tag_data
  end
end

end  # namespace Tem::Apdus
