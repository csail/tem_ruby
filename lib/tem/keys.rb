module Tem::Keys
  def devchip_generate_key_pair
    response = issue_apdu [0x00, 0x40, 0x00, 0x00, 0x00].flatten
    tem_error(response) if failure_code(response)
    return { :privkey_id => read_tem_byte(response, 0), :pubkey_id => read_tem_byte(response, 1) }    
  end
  
  def devchip_release_key(key_id)
    response = issue_apdu [0x00, 0x41, to_tem_byte(key_id), 0x00, 0x00].flatten
    tem_error(response) if failure_code(response)
    return true
  end
  
  def devchip_save_key(key_id)
    response = issue_apdu [0x00, 0x43, to_tem_byte(key_id), 0x00, 0x00].flatten
    tem_error(response) if failure_code(response)
    
    buffer_id, buffer_length = read_tem_byte(response, 0), read_tem_short(response, 1)
    key_buffer = read_buffer buffer_id
    release_buffer buffer_id
    
    read_tem_key key_buffer[0...buffer_length], 0
  end
  
  def devchip_encrypt_decrypt(data, key_id, opcode)
    buffer_id = post_buffer data
    response = issue_apdu [0x00, opcode, to_tem_byte(key_id), to_tem_byte(buffer_id), 0x00].flatten
    release_buffer buffer_id
    tem_error(response) if failure_code(response)

    buffer_id, buffer_length = read_tem_byte(response, 0), read_tem_short(response, 1)
    data_buffer = read_buffer buffer_id
    release_buffer buffer_id
    
    return data_buffer[0...buffer_length]
  end
  def devchip_encrypt(data, key_id)
    devchip_encrypt_decrypt(data, key_id, 0x44)
  end
  def devchip_decrypt(data, key_id)
    devchip_encrypt_decrypt(data, key_id, 0x45)
  end
  
  def stat_keys
    apdu = [0x00, 0x27, 0x01, 0x00, 0x00].flatten
    response = issue_apdu apdu
    tem_error(response) if failure_code(response)
    response = reply_data(response)
    key_types = {0x99 => :symmetric, 0x55 => :private, 0xAA => :public}
    stat = {:keys => {}}
    offset = 0
    while offset < response.length do
      stat[:keys][read_tem_ubyte(response, offset)] =
        {:type => key_types[read_tem_ubyte(response, offset + 1)],
        :bits => read_tem_ushort(response, offset + 2)}
      offset += 4
    end
    return stat
  end  
end
