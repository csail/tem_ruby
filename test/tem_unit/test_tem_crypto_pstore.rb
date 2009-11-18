require 'test/tem_test_case.rb'

class TemCryptoPstoreTest < TemTestCase
  def test_crypto_pstore
    addr1 = (0...(Tem::Abi.tem_ps_addr_length)).map { |x| (61 * x * x + 62 * x + 10) % 256 }
    addr2 = addr1.dup; addr2[addr2.length - 1] += 1
    random_value = (0...(Tem::Abi.tem_ps_value_length)).map { |x| (69 * x * x + 62 * x + 10) % 256 }
    
    sec = @tem.assemble { |s|
      s.ldwc 2 * @tem.tem_ushort_length + @tem.tem_ps_value_length
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
      s.halt

      s.label :pstore_addr
      s.data :tem_ubyte, addr1
      s.label :s_value
      s.data :tem_ubyte, random_value
      s.label :s_value2
      s.zeros :tem_ps_value
      s.stack 8
    }
    expected = @tem.to_tem_ushort(0) + @tem.to_tem_ushort(1) + random_value
    result = @tem.execute sec
    assert_equal expected, result,
                 "Persistent store locations aren\'t working well"   
      
    sec = @tem.assemble { |s|
      s.ldwc 2 * @tem.tem_ushort_length + @tem.tem_ps_value_length
      s.outnew
    
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
      s.data :tem_ubyte, addr1
      s.label :s_value
      s.data :tem_ubyte, random_value
      s.label :s_value2
      s.zeros :tem_ps_value
      s.stack 8
    }    
    expected = @tem.to_tem_ushort(1) + random_value + @tem.to_tem_ushort(0)
    result = @tem.execute sec
    assert_equal expected, result,
                 "Persistent store data didn't survive across SECpack execution"   
  end
end
