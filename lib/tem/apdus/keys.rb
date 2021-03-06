# TEM cryptographic key manipulation using the APDU API. 
#
# Author:: Victor Costan
# Copyright:: Copyright (C) 2007 Massachusetts Institute of Technology
# License:: MIT

# :nodoc: namespace
module Tem::Apdus
  
module Keys
  def devchip_generate_key_pair(symmetric_key = false)
    response = @transport.iso_apdu! :ins => 0x40,
                                    :p1 => (symmetric_key ? 0x80 : 0x00)
    return { :privkey_id => read_tem_byte(response, 0),
             :pubkey_id => read_tem_byte(response, 1) }    
  end
  
  # NOTE: this is the only method that is not devchip-only. It needs to be in
  #       the production driver to prevent from DOSing the TEM by filling its
  #       key store.
  def release_key(key_id)
    @transport.iso_apdu! :ins => 0x28, :p1 => key_id
    return true
  end
  
  def devchip_save_key(key_id)
    response = @transport.iso_apdu! :ins => 0x42, :p1 => key_id
    buffer_id = read_tem_byte response, 0 
    buffer_length = read_tem_short response, 1
    key_buffer = read_buffer buffer_id
    release_buffer buffer_id
    
    read_tem_key key_buffer[0, buffer_length], 0
  end
  
  def devchip_encrypt_decrypt(data, key_id, opcode)
    buffer_id = post_buffer data
    begin
      response = @transport.iso_apdu! :ins => opcode, :p1 => key_id,
                                         :p2 => buffer_id
    ensure
      release_buffer buffer_id
    end

    buffer_id = read_tem_byte response, 0
    buffer_length = read_tem_short response, 1
    data_buffer = read_buffer buffer_id
    release_buffer buffer_id
    
    return data_buffer[0, buffer_length]
  end
  def devchip_encrypt(data, key_id)
    devchip_encrypt_decrypt data, key_id, 0x43
  end
  def devchip_decrypt(data, key_id)
    devchip_encrypt_decrypt data, key_id, 0x44
  end
  
  def stat_keys
    response = @transport.iso_apdu! :ins => 0x27, :p1 => 0x01
    key_types = { 0x99 => :symmetric, 0x55 => :private, 0xAA => :public }
    stat = {:keys => {}}
    offset = 0
    while offset < response.length do
      stat[:keys][read_tem_ubyte(response, offset)] =
        { :type => key_types[read_tem_ubyte(response, offset + 1)],
          :bits => read_tem_ushort(response, offset + 2) }
      offset += 4
    end
    return stat
  end  
end

end  # namespace Tem::Apdus
