module Tem::Toolkit
  def tk_gen_key(type = :asymmetric, authz = nil)
    gen_sec = assemble do |s|
      s.ldbc authz.nil? ? 24 : 4
      s.outnew
      if authz.nil?
        # No authorization given, must generate one.
        s.ldbc 20
        s.ldwc :key_auth
        s.dupn :n => 2
        s.rnd
        s.outvb
      end
      s.genkp :type => (type == :asymmetric) ? 0x00 : 0x80
      s.authk :auth => :key_auth
      s.outw
      if type == :asymmetric
        s.authk :auth => :key_auth 
        s.outw
      end
      s.halt
      s.label :key_auth
      if authz.nil?
        s.zeros :tem_ubyte, 20
      else
        s.data :tem_ubyte, authz
      end
      s.stack 4
    end
    
    kp_buffer = execute gen_sec
    keys_offset = authz.nil? ? 20 : 0
    k1id = read_tem_ushort kp_buffer, keys_offset    
    k2id = read_tem_ushort kp_buffer, keys_offset + 2 if type == :asymmetric
    if type == :asymmetric 
      return_val = { :pubk_id => k1id, :privk_id => k2id }
    else
      return_val = { :key_id => k1id }
    end
    return { :authz => authz || kp_buffer[0...20] }.merge!(return_val)
  end
  
  def tk_read_key(key_id, authz)
    read_sec = assemble do |s|
      s.ldbc :const => key_id
      s.authk :auth => :key_auth
      s.ldkl
      s.outnew
      s.ldbc :const => key_id
      s.ldbc(-1)
      s.stk
      s.halt
      s.label :key_auth
      s.data :tem_ubyte, authz
      s.stack 4
    end
    
    key_string = execute read_sec
    return read_tem_key(key_string, 0)
  end
  
  def tk_post_key(key, authz)
    post_sec = assemble do |s|
      s.ldbc :const => 1
      s.outnew
      s.ldwc :const => :key_data
      s.rdk
      s.authk :auth => :key_auth
      s.outb
      s.halt
      s.label :key_data
      s.data :tem_ubyte, key.to_tem_key
      s.label :key_auth
      s.data :tem_ubyte, authz
      s.stack 4
    end
    id_string = execute post_sec
    return read_tem_ubyte(id_string, 0)
  end
end
