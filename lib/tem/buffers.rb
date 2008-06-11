module Tem::Buffers
  def alloc_buffer(length)
    apdu = [0x00, 0x20, to_tem_short(length), 0x00].flatten
    response = issue_apdu apdu
    tem_error(response) if failure_code(response)
    return read_tem_byte(response, 0)
  end
  
  def release_buffer(buffer_id)
    apdu = [0x00, 0x21, to_tem_byte(buffer_id), 0x00, 0x00].flatten
    response = issue_apdu apdu
    tem_error(response) if failure_code(response)
    return true
  end

  def flush_buffers
    apdu = [0x00, 0x26, 0x00, 0x00, 0x00].flatten
    response = issue_apdu apdu
    tem_error(response) if failure_code(response)
    return true
  end
  
  def get_buffer_length(buffer_id)
    apdu = [0x00, 0x22, to_tem_byte(buffer_id), 0x00, 0x00].flatten
    response = issue_apdu apdu
    tem_error(response) if failure_code(response)
    return read_tem_short(response, 0)
  end
  
  def read_buffer(buffer_id)
    @buffer_chunk_size = guess_buffer_chunk_size unless defined? @buffer_chunk_size
    
    buffer = []
    chunk_id = 0
    while true do
      apdu = [0x00, 0x23, to_tem_byte(buffer_id), to_tem_byte(chunk_id), 0x00].flatten
      response = issue_apdu apdu
      tem_error(response) if failure_code(response)
      buffer += response[0...(response.length - 2)]
      break if response.length != @buffer_chunk_size + 2
      chunk_id += 1
    end
    return buffer
  end
  
  def write_buffer(buffer_id, data)
    @buffer_chunk_size = guess_buffer_chunk_size unless defined? @buffer_chunk_size
    
    chunk_id, offset = 0, 0
    while offset < data.length do
      write_size = (data.length - offset < @buffer_chunk_size) ?
          data.length - offset : @buffer_chunk_size
      apdu = [0x00, 0x24, to_tem_byte(buffer_id), to_tem_byte(chunk_id), to_tem_ubyte(write_size),
              data.values_at(offset...(offset+write_size))].flatten
      response = issue_apdu apdu
      tem_error(response) if failure_code(response)

      chunk_id += 1
      offset += write_size
    end
  end
  
  def guess_buffer_chunk_size
    apdu = [0x00, 0x25, 0x00, 0x00, 0x00].flatten
    response = issue_apdu apdu
    tem_error(response) if failure_code(response)
    return read_tem_short(response, 0)
  end
  
  def stat_buffers
    apdu = [0x00, 0x27, 0x00, 0x00, 0x00].flatten
    response = issue_apdu apdu
    tem_error(response) if failure_code(response)
    response = reply_data(response)
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
    buffer_id = alloc_buffer(data.length)
    write_buffer buffer_id, data
    return buffer_id
  end
end
