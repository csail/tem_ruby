require 'test/tem_test_case'

module TemMemoryCompareTestCase
  # This is also called from TemYamlSecpackTest.  
  def _test_memory_copy_compare(yaml_roundtrip = false)    
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
      s.data :tem_ubyte, [0xA3, 0x2C, 0x51, 0x63, 0x2C, 0x12]
      s.label :cmp_med
      s.data :tem_ubyte, [0xA3, 0x2C, 0x51, 0x63, 0x2D, 0x11]
      s.label :cmp_hi
      s.data :tem_ubyte, [0xA3, 0x2C, 0x51, 0x63, 0x2E, 0x10]
      s.label :cmp_hi2
      s.data :tem_ubyte, [0xA3, 0x2C, 0x51, 0x63, 0x2E, 0x10]
      s.label :copy_buf
      s.zeros :tem_ubyte, 6
      s.label :copy_buf2
      s.zeros :tem_ubyte, 4
      s.stack 5
    }

    if yaml_roundtrip
      # same test, except the SECpack is serialized/deserialized
      yaml_sec = sec.to_yaml_str
      sec = Tem::SecPack.new_from_yaml_str(yaml_sec)
    end
    result = @tem.execute sec
    assert_equal [0x00, 0x01, 0xFF, 0xFF, 0x00, 0x00, 0xA3, 0x2C, 0x51, 0x63,
                  0x2E, 0x10, 0xA3, 0x2C, 0x51, 0x63],
                 result, 'memory copy/compare isn\'t working well'        
  end  
end

class TemMemoryCompareTest < TemTestCase
  include TemMemoryCompareTestCase
  def test_memory_copy_compare
    _test_memory_copy_compare false
  end
end
