require 'test/unit'

require 'tem_ruby'

class AbiBuilderTest
  module Abi
    Tem::Builders::Abi.define_abi self do |abi|
      abi.fixed_width_type :byte, 1, :signed => true
      abi.fixed_width_type :ubyte, 1, :signed => false

      abi.fixed_width_type :word, 2, :signed => true, :big_endian => false
      abi.fixed_width_type :netword, 2, :signed => true, :big_endian => true
                           
      abi.fixed_width_type :dword, 4, :signed => true, :big_endian => true
      abi.fixed_width_type :udword, 4, :signed => false, :big_endian => false
    end
  end
  
  def test_encoding
    [
     [:byte, 0, [0]], [:byte, 127, [127]],
     [:byte, -1, [255]], [:byte, -127, [129]], [:byte, -128, [128]],
     [:byte, 128, nil], [:byte, -129, nil],
      
     [:word, 0, [0, 0]], [:word, 127, [127, 0]], [:word, 128, [128, 0]],
     [:word, 256, [0, 1]], [:word, 32767, [255, 127]], 
     [:word, -1, [255, 255]], [:word, -127, [129, 255]],
     [:word, -128, [128, 255]], [:word, -256, [0, 255]],
     [:word, -32767, [1, 128], [:word, -32768, [0, 128]]],
     [:word, 32768, nil], [:byte, -32769, nil],
      
     [:netword, 0, [0, 0]], [:netword, 127, [0, 127]], 
     [:netword, 128, [0, 128]],
     [:netword, 256, [1, 0]], [:netword, 32767, [127, 255]], 
     [:netword, -1, [255, 255]], [:netword, -127, [255, 129]],
     [:netword, -128, [255, 128]], [:netword, -256, [255, 0]],
     [:netword, -32767, [128, 1], [:netword, -32768, [128, 0]]],
     [:netword, 32768, nil], [:netword, -32769, nil],
      
     [:dword, 0x12345678, [0x12, 0x34, 0x56, 0x78]],
     [:udword, 0x12345678, [0x78, 0x56, 0x34, 0x12]],
     [:udword, 0xFFFFFFFF, [255, 255, 255, 255]],
     [:udword, 0xFFFFFFFE, [254, 255, 255, 255]]
    ].each do |test_line|
      type, number, array = *test_line
      if array
      else
        assert_raise RuntimeError do
          assert_equal array, Abi.send(:"to_#{type}", number)
          assert_equal number, Abi.send(:"read_#{type}", array)
       end
      end
    end
    
    assert_equal [255, 255, 255, 255], Abi.signed_to_udword(-1),
                 'Failed on signed_to_udword'
  end
  
  def test_length
    [:byte, 1, :ubyte, 1,
     :word, 2, :netword, 2,
     :dword, 4, :udword, 4
    ].each do |test_line|
      assert_equal test_line.last, Abi.send(:"#{test_line.first}_length")
    end
  end
end