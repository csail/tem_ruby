# TEM tag management using the APDU API. 
#
# Author:: Victor Costan
# Copyright:: Copyright (C) 2007 Massachusetts Institute of Technology
# License:: MIT

# :nodoc: namespace
module Tem::Apdus
  
  
module Tag
  def set_tag(tag_data)    
    buffer_id = post_buffer tag_data
    begin
      @transport.iso_apdu! :ins => 0x30, :p1 => buffer_id
    ensure
      release_buffer buffer_id
    end
  end
  
  def get_tag_length
    response = @transport.iso_apdu! :ins => 0x31
    return read_tem_short(response, 0)
  end
  
  def get_tag_data(offset, length)
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

  def get_tag
    tag_length = self.get_tag_length
    get_tag_data 0, tag_length
  end
end

end  # namespace Tem::Apdus
