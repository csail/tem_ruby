require 'test/tem_test_case'

class TemTest < TemTestCase
  def test_alu
    sec = @tem.assemble { |s|
      s.ldbc 10
      s.outnew
      s.ldwc 0x1234
      s.ldwc 0x5678
      s.dupn :n => 2
      s.add
      s.outw
      s.sub
      s.outw
      s.ldwc 0x0155
      s.ldwc 0x02AA
      s.mul
      s.outw
      s.ldwc 0x390C
      s.ldwc 0x00AA
      s.dupn :n => 2
      s.div
      s.outw
      s.mod
      s.outw
      s.halt
      s.extra 10
    }
    result = @tem.execute sec
    assert_equal [0x68, 0xAC, 0xBB, 0xBC, 0x8C, 0x72, 0x00, 0x55, 0x00, 0x9A],
                  result, 'the ALU isn\'t working well'
  end
  
  def test_memory
    sec = @tem.assemble { |s|
      s.label :clobber
      s.ldbc 32
      s.label :clobber2
      s.outnew
      s.ldwc 0x55AA
      s.stw :clobber
      s.ldb :clobber
      s.outw
      s.ldw :clobber
      s.outw
      s.ldbc 0xA5 - (1 << 8)
      s.stb :clobber
      s.ldw :clobber
      s.outw
      s.ldwc :clobber2
      s.dupn :n => 1
      s.dupn :n => 2
      s.ldwc 0x9966 - (1 << 16)
      s.stwv
      s.ldbv
      s.outw
      s.ldbc 0x98 - (1 << 8)
      s.stbv
      s.ldwv
      s.outw
      s.ldwc 0x1122
      s.ldwc 0x3344
      s.ldwc 0x5566
      s.flipn :n => 3
      s.outw
      s.outw
      s.outw        
      s.halt
      s.stack
      s.extra 10
    }
    result = @tem.execute sec
    assert_equal [0x00, 0x55, 0x55, 0xAA, 0xA5, 0xAA, 0xFF, 0x99, 0x98, 0x66, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66],
                  result, 'the memory unit isn\'t working well'    
  end
  
  def test_output
    sec = @tem.assemble { |s|
      s.ldbc 32
      s.outnew
      s.outfxb :size => 3, :from => :area1
      s.ldbc 5
      s.outvlb :from => :area2
      s.ldbc 4
      s.ldwc :area3
      s.outvb
      s.ldwc 0x99AA - (1 << 16)
      s.ldwc 0xFA55 - (1 << 16)
      s.outb
      s.outw        
      s.halt
      s.label :area1
      s.immed :ubyte, [0xFE, 0xCD, 0x9A]
      s.label :area2
      s.immed :ubyte, [0xAB, 0x95, 0xCE, 0xFD, 0x81]
      s.label :area3
      s.immed :ubyte, [0xEC, 0xDE, 0xAD, 0xCF]
      s.stack
      s.extra 10
    }
    result = @tem.execute sec
    assert_equal [0xFE, 0xCD, 0x9A, 0xAB, 0x95, 0xCE, 0xFD, 0x81, 0xEC, 0xDE, 0xAD, 0xCF, 0x55, 0x99, 0xAA],
                  result, 'the output unit isn\'t working well'    
  end
  
  def test_branching
    secpack = @tem.assemble { |s|
      s.ldbc 24
      s.outnew
      
      s.jmp :to => :over_halt
      s.halt  # this gets jumped over
      s.label :over_halt
      s.ldbc 4
      s.label :test_loop
      s.dupn :n => 1
      s.outb
      s.ldbc 1
      s.sub
      s.dupn :n=> 1
      s.jae :to => :test_loop

      failed = 0xFA - (1 << 8)
      [
        [:ja,  [1, 1, failed],  [0, failed, 2],  [-1, failed, 3]],
        [:jae, [1, 4, failed],  [0, 5, failed],  [-1, failed, 6]], 
        [:jb,  [1, failed, 7],  [0, failed, 8],  [-1, 9, failed]],
        [:jbe, [1, failed, 10], [0, 11, failed], [-1, 12, failed]],
        [:jz,  [1, failed, 13], [0, 14, failed], [-1, failed, 15]],
        [:jne, [1, 16, failed], [0, failed, 17], [-1, 18, failed]], 
      ].each do |op_line|
        op = op_line.shift
        op_line.each_index do |i|
          then_label = "#{op}_l#{i}_t".to_sym
          out_label  = "#{op}_l#{i}_o".to_sym
          
          s.ldbc op_line[i][0]        
          s.send op, :to => then_label
          s.ldbc op_line[i][2]
          s.jmp :to => out_label
          s.label then_label
          s.ldbc op_line[i][1]
          s.label out_label
          s.outb          
        end
      end
      
      s.halt
      s.extra 10
    }
    result = @tem.execute secpack
    assert_equal [0x04, 0x03, 0x02, 0x01, 0x00, 0x01, 0x02, 0x03, 0x04,
        0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10, 0x11, 0x12],
                  result, 'the branching unit isn\'t working well'        
  end
  
  def test_memory_copy_compare(yaml_roundtrip = false)    
    sec = @tem.assemble { |s|
      s.ldwc :const => 16
      s.outnew
      s.ldwc :const => 6
      s.ldwc :cmp_med
      s.ldwc :cmp_lo
      s.mcmpvb
      s.outw
      s.mcmpfxb :size => 6, :op1 => :cmp_med, :op2 => :cmp_hi
      s.outw
      s.ldwc :const => 4
      s.ldwc :cmp_lo
      s.ldwc :cmp_med
      s.mcmpvb
      s.outw      
      
      s.mcfxb :size => 6, :from => :cmp_hi, :to => :copy_buf
      s.pop
      s.outfxb :size => 6, :from => :copy_buf      
      s.ldwc :const => 4
      s.ldwc :cmp_hi
      s.ldwc :copy_buf2
      s.mcvb
      s.pop      
      s.outfxb :size => 4, :from => :copy_buf2            
    
      s.halt
      s.label :cmp_lo
      s.immed :ubyte, [0xA3, 0x2C, 0x51, 0x63, 0x2C, 0x12]
      s.label :cmp_med
      s.immed :ubyte, [0xA3, 0x2C, 0x51, 0x63, 0x2D, 0x11]
      s.label :cmp_hi
      s.immed :ubyte, [0xA3, 0x2C, 0x51, 0x63, 0x2E, 0x10]
      s.label :cmp_hi2
      s.immed :ubyte, [0xA3, 0x2C, 0x51, 0x63, 0x2E, 0x10]
      s.label :copy_buf
      s.filler :ubyte, 6
      s.label :copy_buf2
      s.filler :ubyte, 4
      s.stack
      s.extra 10
    }

    if yaml_roundtrip
      # same test, except the SECpack is serialized/deserialized
      yaml_sec = sec.to_yaml_str
      sec = Tem::SecPack.new_from_yaml_str(yaml_sec)
    end
    result = @tem.execute sec
    assert_equal [0x00, 0x01, 0xFF, 0xFF, 0x00, 0x00, 0xA3, 0x2C, 0x51, 0x63, 0x2E, 0x10, 0xA3, 0x2C, 0x51, 0x63],
                  result, 'memory copy/compare isn\'t working well'        
  end
  
  def test_crypto_hash
    garbage1 = (0...8).map { |x| (31 * x * x + 5 * x + 3) % 256 }
    garbage2 = (0...11).map { |x| (69 * x * x + 62 * x + 10) % 256 }
    hash_size = 20
    
    sec = @tem.assemble { |s|
      s.ldwc hash_size * 3
      s.outnew
      s.mdfxb :size => garbage1.length, :from => :garbage1, :to => :hash_area
      s.outfxb :size => hash_size, :from => :hash_area
      s.mdfxb :size => garbage2.length, :from => :garbage2, :to => 0xFFFF
      s.ldwc garbage2.length
      s.ldwc :garbage2
      s.ldwc :hash_area
      s.mdvb
      s.outfxb :size => hash_size, :from => :hash_area
      s.halt
      s.label :garbage1
      s.immed :ubyte, garbage1
      s.label :garbage2
      s.immed :ubyte, garbage2
      s.label :hash_area
      s.filler :ubyte, hash_size
      s.stack
      s.extra 10
    }
    
    result = @tem.execute sec
    assert_equal [garbage1, garbage2, garbage2].map { |d| @tem.tem_hash d}.
                                                flatten,
                  result, 'cryptographic hashing isn\'t working well'
  end
  
  def test_crypto_pstore
    addr1 = (0...(@tem.tem_ps_addr_length)).map { |x| (61 * x * x + 62 * x + 10) % 256 }
    addr2 = addr1.dup; addr2[addr2.length - 1] += 1
    random_value = (0...(@tem.tem_ps_value_length)).map { |x| (69 * x * x + 62 * x + 10) % 256 }
    
    sec = @tem.assemble { |s|
      s.ldwc 3 * @tem.tem_ushort_length + @tem.tem_ps_value_length * 2
      s.outnew
      
      # check that the location is blank
      s.ldwc :pstore_addr
      s.pshkvb
      s.outw
          
      # write to create the location
      s.pswrfxb :addr => :pstore_addr, :from => :s_value
      # check that the location isn't blank anymore
      s.pshkfxb :addr => :pstore_addr
      s.outw
      # re-read (should get what was written)
      s.ldwc :pstore_addr
      s.ldwc :s_value2
      s.psrdvb
      s.ldwc :s_value2
      s.outvb
      
      # drop the location
      s.ldwc :pstore_addr
      s.dupn :n => 1
      s.psrm
      # check that the location is blank again
      s.pshkvb
      s.outw
            
      s.halt
    
      s.label :pstore_addr
      s.immed :ubyte, addr1
      s.label :s_value
      s.immed :ubyte, random_value
      s.label :s_value2
      s.filler :ps_value
      s.stack
      s.extra 16
    }    
    expected = @tem.to_tem_ushort(0) + @tem.to_tem_ushort(1) + random_value + @tem.to_tem_ushort(0)
    result = @tem.execute sec
    assert_equal expected, result, 'persistent store locations aren\'t working well'    
  end
  
  def test_crypto_random
    sec = @tem.assemble { |s|
      s.ldbc 16
      s.outnew
      s.ldbc 8
      s.dupn :n => 1
      s.ldwc :rnd_area
      s.dupn :n => 2
      s.rnd       
      s.outvb
      s.ldbc(-1)
      s.rnd
      s.halt
      s.label :rnd_area
      s.filler :ubyte, 8
      s.stack
      s.extra 10
    }
    
    result = @tem.execute sec
    assert_equal 16, result.length, 'monotonic counters aren\'t working well'    
  end
  
  def i_crypt(data, key_id, authz, mode = :encrypt, direct_io = true, max_output = nil)
    if max_output.nil?
      max_output = case mode
      when :encrypt
        ((data.length + 239) / 240) * 256
      when :decrypt
        data.length
      when :sign
        256
      end
    end
    
    crypt_opcode = {:encrypt => :kefxb, :decrypt => :kdfxb, :sign => :ksfxb}[mode]
    ex_sec = @tem.assemble { |s|
      # buffer
      s.ldwc :const => max_output
      s.outnew
      s.ldbc :const => key_id
      s.authk :auth => :key_auth
      s.send crypt_opcode, :from => :data, :size => data.length, :to => (direct_io ? 0xFFFF : :outdata) 
      s.outvlb :from => :outdata unless direct_io
      s.halt
      
      s.label :key_auth
      s.immed :ubyte, authz
      s.label :data
      s.immed :ubyte, data
      unless direct_io
        s.label :outdata
        s.filler :ubyte, max_output
      end
      s.stack
      s.extra 10
    }
    return @tem.execute(ex_sec)    
  end
  
  def i_verify(data, signature, key_id, authz)
    sign_sec = @tem.assemble { |s|
      # buffer
      s.ldbc :const => 1
      s.outnew
      s.ldbc :const => key_id
      s.authk :auth => :key_auth
      s.kvsfxb :from => :data, :size => data.length, :signature => :signature 
      s.outb
      s.halt
      
      s.label :key_auth
      s.immed :ubyte, authz
      s.label :data
      s.immed :ubyte, data
      s.label :signature
      s.immed :ubyte, signature
      s.stack
      s.extra 10
    }
    return @tem.execute(sign_sec)[0] == 1    
  end
  
  def i_test_crypto_pki_ops(pubk_id, privk_id, pubk, privk, authz)
    garbage = (1...569).map { |i| (i * i * 217 + i * 661 + 393) % 256 }

    # SEC/priv-sign + CPU/pub-verify, direct IO
    signed_garbage = i_crypt(garbage, privk_id, authz, :sign, true)
    assert privk.verify(garbage, signed_garbage), 'SEC priv-signing + CPU pub-verify failed on good data'

    # SEC/priv-sign + CPU/pub-verify, indirect IO
    signed_garbage = i_crypt(garbage, privk_id, authz, :sign, false)
    assert privk.verify(garbage, signed_garbage), 'SEC priv-signing + CPU pub-verify failed on good data'

    # CPU/priv-sign + SEC/pub-verify
    signed_garbage = privk.sign garbage 
    assert i_verify(garbage, signed_garbage, pubk_id, authz), 'CPU priv-signing + SEC pub-verify failed on good data'

    # CPU/priv-encrypt + SEC/pub-decrypt, indirect IO
    encrypted_garbage = privk.encrypt garbage 
    decrypted_garbage = i_crypt(encrypted_garbage, pubk_id, authz, :decrypt, false)
    assert_equal garbage, decrypted_garbage, 'SEC priv-encryption + CPU pub-decryption messed up the data'  

    # SEC/pub-encrypt + CPU/priv-decrypt, indirect IO
    encrypted_garbage = i_crypt(garbage, pubk_id, authz, :encrypt, false)
    decrypted_garbage = privk.decrypt encrypted_garbage
    assert_equal garbage, decrypted_garbage, 'SEC priv-encryption + CPU pub-decryption messed up the data'  
    
    # CPU/pub-encrypt + SEC/priv-decrypt, direct-IO
    encrypted_garbage = pubk.encrypt garbage 
    decrypted_garbage = i_crypt(encrypted_garbage, privk_id, authz, :decrypt, true)
    assert_equal garbage, decrypted_garbage, 'CPU pub-encryption + SEC priv-decryption messed up the data' 

    # SEC/priv-encrypt + CPU/pub-decrypt, direct-IO
    encrypted_garbage = i_crypt(garbage, privk_id, authz, :encrypt, true)
    decrypted_garbage = pubk.decrypt encrypted_garbage
    assert_equal garbage, decrypted_garbage, 'SEC priv-encryption + CPU pub-decryption messed up the data'    
  end
  
  def test_crypto_pki
    # crypto run with an internally generated key
    keyd = @tem.tk_gen_key :asymmetric
    pubk = @tem.tk_read_key keyd[:pubk_id], keyd[:authz]
    privk = @tem.tk_read_key keyd[:privk_id], keyd[:authz]
    i_test_crypto_pki_ops(keyd[:pubk_id], keyd[:privk_id], pubk, privk, keyd[:authz])
    
    # crypto run with an externally generated key
    ekey = OpenSSL::PKey::RSA.generate(2048, 65537)
    pubk = Tem::Key.new_from_ssl_key ekey.public_key
    privk = Tem::Key.new_from_ssl_key ekey
    pubk_id = @tem.tk_post_key pubk, keyd[:authz] 
    privk_id = @tem.tk_post_key privk, keyd[:authz]
    i_test_crypto_pki_ops(pubk_id, privk_id, pubk, privk, keyd[:authz])    
  end
    
  def test_bound_secpack(yaml_roundtrip = false)
    keyd = @tem.tk_gen_key
    pubk = @tem.tk_read_key keyd[:pubk_id], keyd[:authz]
    
    secret = (0...16).map { |i| (99 * i * i + 51 * i + 33) % 256 }
    bound_sec = @tem.assemble { |s|
        s.ldbc secret.length
        s.outnew
        s.label :mess_place
        s.outfxb :size => secret.length, :from => :secret
        s.halt
        s.label :secret
        s.immed :ubyte, secret
        s.label :plain
        s.stack
        s.extra 8
    }

    sb = bound_sec.body
    secret_found = false
    0.upto(sb.length - 1) { |i| if secret == sb[i, secret.length] then secret_found = true; break; end }
    assert secret_found, 'test_bound_secpack needs rethinking: the unbound secpack does not contain the secret'

    bound_sec.bind pubk, :secret, :plain
    if yaml_roundtrip
      # same test, except the SECpack is serialized/deserialized
      yaml_bound_sec = bound_sec.to_yaml_str
      bound_sec = Tem::SecPack.new_from_yaml_str(yaml_bound_sec)
    end    
    result = @tem.execute bound_sec, keyd[:privk_id]
    assert_equal secret, result, 'TEM failed to decrypt secpack'

    sb = bound_sec.body
    0.upto(sb.length - 1) { |i| assert_not_equal secret, sb[i, secret.length], 'secret found unencrypted in bound secpack' }

    bound_sec.body[bound_sec.label_address(:mess_place)] += 1
    assert_raise(RuntimeError, 'secpack validation isn\'t working') { @tem.execute bound_sec }
  end
  
  def test_yaml_secpack
    # simple test to ensure that the body is preserved
    sec = @tem.assemble { |s|
      s.ldbc 10
      s.outnew
      s.ldwc 0x1234
      s.ldwc 0x5678
      s.dupn :n => 2
      s.add
      s.outw
      s.sub
      s.outw
      s.ldwc 0x0155
      s.ldwc 0x02AA
      s.mul
      s.outw
      s.ldwc 0x390C
      s.ldwc 0x00AA
      s.dupn :n => 2
      s.div
      s.outw
      s.mod
      s.outw
      s.halt
      s.stack
      s.extra 10
    }
    yaml_sec = sec.to_yaml_str
    sec2 = Tem::SecPack.new_from_yaml_str(yaml_sec)
    assert_equal sec.body, sec2.body, 'SECpack body corrupted during serialization'
    
    # re-run the memory test (reasonably large SECpack) to ensure that de-serialized SECpacks are equivalent to the originals
    test_memory_copy_compare(true)
    # re-run the memory test (reasonably large SECpack) to ensure that serialization works on bound SECpacks
    test_bound_secpack(true)
  end
  
  def test_emit
    # try to emit
    er = @tem.emit
    assert er != nil, 'TEM emitting failed'
    
    # now verify that the private key is good and the authorization matches
    privek = @tem.tk_read_key 0, er[:privek_auth]
    assert((not privek.is_public?), 'TEM emission failed to produce a proper PrivEK')

    # verify that the public key can be read from the ECert
    pubek = @tem.pubek
    assert pubek.is_public?, 'TEM emission failed to produce a proper PubEK'

    # verify the PrivEK against the ECert
    ecert = @tem.endorsement_cert
    ecert.verify privek.ssl_key
    
    @tem.tk_delete_key 0, er[:privek_auth]
  end  
end
