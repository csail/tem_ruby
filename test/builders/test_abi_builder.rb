require 'openssl'
require 'test/unit'

require 'tem_ruby'

class AbiBuilderTest < Test::Unit::TestCase
  module Abi
    Tem::Builders::Abi.define_abi self do |abi|
      abi.fixed_length_number :byte, 1, :signed => true
      abi.fixed_length_number :ubyte, 1, :signed => false

      abi.fixed_length_number :word, 2, :signed => true, :big_endian => false
      abi.fixed_length_number :netword, 2, :signed => true, :big_endian => true
                           
      abi.fixed_length_number :dword, 4, :signed => true, :big_endian => true
      abi.fixed_length_number :udword, 4, :signed => false, :big_endian => false
      
      abi.variable_length_number :vln, :word, :signed => false,
                                 :big_endian => false
      abi.variable_length_number :net_vln, :netword, :signed => false,
                                 :big_endian => true
      abi.packed_variable_length_numbers :packed, :word, [:p, :q, :n],
                                         :signed => false,
                                         :big_endian => false
      abi.packed_variable_length_numbers :net_packed, :netword,
                                         [:x, :y, :z, :a],
                                         :signed => false,
                                         :big_endian => true
    end
  end
  
  def setup
    @garbage = [0xFD, 0xFC, 0xFD, 0xFC, 0xFD] * 5    
  end
  
  def test_fixed_and_variable_length_encoding
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
     [:udword, 0xFFFFFFFE, [254, 255, 255, 255]],
     
     [:vln, 0, [0x01, 0x00, 0x00]], [:vln, 1, [0x01, 0x00, 0x01]],
     [:vln, 256, [0x02, 0x00, 0x00, 0x01]],
     [:vln, 65537, [0x03, 0x00, 0x01, 0x00, 0x01]],
     [:vln, 0x12345678, [0x04, 0x00, 0x78, 0x56, 0x34, 0x12]],
     [:vln, 0xFFFFFFFF, [0x04, 0x00, 255, 255, 255, 255]],
     [:vln, 0xFFFFFFFE, [0x04, 0x00, 254, 255, 255, 255]],

     [:net_vln, 0, [0x00, 0x01, 0x00]], [:net_vln, 1, [0x00, 0x01, 0x01]],
     [:net_vln, 256, [0x00, 0x02, 0x01, 0x00]],
     [:net_vln, 65537, [0x00, 0x03, 0x01, 0x00, 0x01]],
     [:net_vln, 0x12345678, [0x00, 0x04, 0x12, 0x34, 0x56, 0x78]],
     [:net_vln, 0xFFFFFFFF, [0x00, 0x04, 255, 255, 255, 255]],
     [:net_vln, 0xFFFFFFFE, [0x00, 0x04, 255, 255, 255, 254]]
    ].each do |test_line|
      type, number, array = *test_line
      if array
        assert_equal array, Abi.send(:"to_#{type}", number),
                     "#{type} failed on Ruby number -> array"
        assert_equal array, Abi.send(:"to_#{type}",
                                     OpenSSL::BN.new(number.to_s)),
                     "#{type} failed on OpenSSL number -> array"
        assert_equal number, Abi.send(:"read_#{type}", @garbage + array,
                                      @garbage.length)
      else
        assert_raise RuntimeError do
          assert_equal array, Abi.send(:"to_#{type}", number)
        end
        assert_raise RuntimeError do
          assert_equal array, Abi.send(:"to_#{type}",
                                       OpenSSL::BN.new(number.to_s))
        end
      end
    end
    
    assert_equal [255, 255, 255, 255], Abi.signed_to_udword(-1),
                 'Failed on signed_to_udword'
  end
  
  def test_packed_number_encoding
    packed = { :p => 0x123, :q => 0xABCDEF, :n => 5 }
    gold_packed = [0x02, 0x00, 0x03, 0x00, 0x01, 0x00, 0x23, 0x01, 0xEF, 0xCD,
                   0xAB, 0x05]
    assert_equal gold_packed, Abi.to_packed(packed), 'packed'
    assert_equal packed, Abi.read_packed(@garbage + gold_packed,
                                         @garbage.length), 'packed'
    
    net_packed = { :x => 0x271, :y => 0x314159, :z => 0, :a => 0x5AA5 }
    gold_net_packed = [0x00, 0x02, 0x00, 0x03, 0x00, 0x01, 0x00, 0x02,
                       0x02, 0x71, 0x31, 0x41, 0x59, 0x00, 0x5A, 0xA5 ]
    assert_equal gold_net_packed, Abi.to_net_packed(net_packed), 'net-packed'
    assert_equal net_packed, Abi.read_net_packed(@garbage + gold_net_packed,
                                                 @garbage.length),
                 'net_packed'
  end
  
  def test_length
    [[:byte, 1], [:ubyte, 1],
     [:word, 2], [:netword, 2],
     [:dword, 4], [:udword, 4]
    ].each do |test_line|
      assert_equal test_line.last, Abi.send(:"#{test_line.first}_length")
    end
  end
end