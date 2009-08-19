# TEM buffer management using the APDU API. 
#
# Author:: Victor Costan
# Copyright:: Copyright (C) 2009 Massachusetts Institute of Technology
# License:: MIT

# :nodoc: namespace
module Tem::Apdus


module Buffers
  def alloc_buffer(length)
    response = @transport.iso_apdu! :ins => 0x20,
                                       :p12 => to_tem_short(length)
    return read_tem_byte(response, 0)
  end
  
  def release_buffer(buffer_id)
    @transport.iso_apdu! :ins => 0x21, :p1 => buffer_id
  end

  def flush_buffers
    @transport.iso_apdu! :ins => 0x26
  end
  
  def get_buffer_length(buffer_id)
    response = @transport.iso_apdu! :ins => 0x22, :p1 => buffer_id
    return read_tem_short(response, 0)
  end
  
  def read_buffer(buffer_id)
    guess_buffer_chunk_size
    
    buffer = []
    chunk_id = 0
    while true do
      response = @transport.iso_apdu! :ins => 0x23, :p1 => buffer_id,
                                        :p2 => chunk_id
      buffer += response
      break if response.length != @buffer_chunk_size
      chunk_id += 1
    end
    return buffer
  end
  
  def write_buffer(buffer_id, data)
    guess_buffer_chunk_size
    
    chunk_id, offset = 0, 0
    while offset < data.length do
      write_size = [data.length - offset, @buffer_chunk_size].min
      @transport.iso_apdu! :ins => 0x24, :p1 => buffer_id, :p2 => chunk_id,
                              :data => data[offset, write_size]
      chunk_id += 1
      offset += write_size
    end
  end
  
  def guess_buffer_chunk_size
    @buffer_chunk_size ||= guess_buffer_chunk_size!
  end
  
  def guess_buffer_chunk_size!
    response = @transport.iso_apdu! :ins => 0x25
    return read_tem_short(response, 0)
  end
  
  def stat_buffers
    response = @transport.iso_apdu! :ins => 0x27
    
    memory_types = [:persistent, :clear_on_reset, :clear_on_deselect]
    stat = {:free => {}, :buffers => []}
    memory_types.each_with_index { |mt, i| stat[:free][mt] = read_tem_short(response, i * 2) }
    offset = 6
    i = 0
    while offset < response.length do
      stat[:buffers][i] =
        {:type => memory_types[read_tem_ubyte(response, offset) & 0x3f],
        :pinned => (read_tem_ubyte(response, offset) & 0x80) != 0,
        :free => (read_tem_ubyte(response, offset) & 0x40) == 0,
        :length => read_tem_ushort(response, offset + 1), 
        :xlength => read_tem_ushort(response, offset + 3)}
      offset += 5
      i += 1
    end
    return stat
  end
  
  def post_buffer(data)
    buffer_id = alloc_buffer data.length
    write_buffer buffer_id, data
    return buffer_id
  end
end

end  # namespace Tem::Apdus
