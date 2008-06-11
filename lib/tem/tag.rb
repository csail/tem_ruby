module Tem::Tag
  def set_tag(tag_data)
    buffer_id = post_buffer(tag_data)
    response = issue_apdu [0x00, 0x30, to_tem_byte(buffer_id), 0x00, 0x00].flatten
    tem_error(response) if failure_code(response)
    release_buffer(buffer_id)
  end
  
  def get_tag_length
    response = issue_apdu [0x00, 0x31, 0x00, 0x00, 0x00].flatten
    tem_error(response) if failure_code(response)
    return read_tem_short(response, 0)
  end
  
  def get_tag_data(offset, length)
    buffer_id = alloc_buffer(length)
    response = issue_apdu [0x00, 0x32, to_tem_byte(buffer_id), 0x00, 0x04, to_tem_short(offset), to_tem_short(length)].flatten
    tem_error(response) if failure_code(response)
    tag_data = read_buffer(buffer_id)
    release_buffer(buffer_id)
    return tag_data
  end

  def get_tag
    tag_length = self.get_tag_length
    get_tag_data(0, tag_length)
  end
end
