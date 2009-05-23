require 'openssl'
require 'test/unit'

require 'tem_ruby'

class AbiBuilderTest < Test::Unit::TestCase
  class Wrapped
    attr_accessor :p, :q, :n
    attr_accessor :d  # Derived value.
    attr_accessor :c  # Constructor value.
    
    def initialize(ctor_value = 'ctor default')
      self.c = ctor_value
    end
  end
  
  class Multi
    attr_accessor :p, :q, :n
    attr_accessor :a, :b, :c
    attr_accessor :str, :const
  end
  
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
      abi.fixed_length_string :mac_id, 6
      abi.object_wrapper :wrapped_raw, Wrapped, [:packed, nil]
      abi.object_wrapper :wrapped, Wrapped, [:packed, nil],
          :to => lambda { |o| w = Wrapped.new
                              w.p, w.q, w.n = o.p, o.q, o.n * 100
                              w },
          :read => lambda { |o| w = Wrapped.new(o.c); w.d = o.p * o.q; w },
          :new => lambda { |klass| klass.new('hook-new') }
      abi.object_wrapper :multi, Multi,
                         [:packed, nil,:packed, { :p => :a, :q => :b, :n => :c},
                          :mac_id, :str, 'constant string', :const]
    end
  end
  
  def setup
    @garbage = [0xFD, 0xFC, 0xFD, 0xFC, 0xFD] * 5    
  end
  
  def test_fixed_and_variable_length_number_encoding
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
        if Abi.respond_to? :"#{type}_length"
          assert_equal array.length, Abi.send(:"#{type}_length"),
                       "#{type} failed on length"
        elsif Abi.respond_to? :"read_#{type}_length"
          assert_equal array.length,
                       Abi.send(:"read_#{type}_length", @garbage + array,
                                @garbage.length),
                       "#{type} failed on read_#{type}_length"
        else
          flunk "#{type} does not provide _length or read_#{type}_length"
        end
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
    assert_equal gold_packed.length,
                 Abi.read_packed_length(@garbage + gold_packed,
                                        @garbage.length),
                 'read_packed_length'
    
    net_packed = { :x => 0x271, :y => 0x314159, :z => 0, :a => 0x5AA5 }
    gold_net_packed = [0x00, 0x02, 0x00, 0x03, 0x00, 0x01, 0x00, 0x02,
                       0x02, 0x71, 0x31, 0x41, 0x59, 0x00, 0x5A, 0xA5 ]
    assert_equal gold_net_packed, Abi.to_net_packed(net_packed), 'net-packed'
    assert_equal net_packed, Abi.read_net_packed(@garbage + gold_net_packed,
                                                 @garbage.length),
                 'net_packed'
    assert_equal gold_net_packed.length,
                 Abi.read_net_packed_length(@garbage + gold_net_packed,
                                            @garbage.length),
                 'read_net_packed_length'
    components = Abi.net_packed_components
    assert_equal [:x, :y, :z, :a], components,
                 'incorrect result from _components'
    assert_raise TypeError, '_components result is mutable' do    
      components[0] = :w
    end
  end
  
  def test_fixed_length_string_encoding
    [
      [:mac_id, "abcdef", nil, [?a, ?b, ?c, ?d, ?e, ?f]],
      [:mac_id, "abc", "abc\0\0\0", [?a, ?b, ?c, 0, 0, 0]],
      [:mac_id, "", "\0\0\0\0\0\0", [0, 0, 0, 0, 0, 0]],
      [:mac_id, "abcdefg", nil, nil],
      [:mac_id, [?a, ?b, ?c, ?d, ?e, ?f], "abcdef", [?a, ?b, ?c, ?d, ?e, ?f]],
      [:mac_id, [?a, ?b, ?c], "abc\0\0\0", [?a, ?b, ?c, 0, 0, 0]],
      [:mac_id, [], "\0\0\0\0\0\0", [0, 0, 0, 0, 0, 0]],
      [:mac_id, [?a, ?b, ?c, ?d, ?e, ?f, ?g], nil, nil],
    ].each do |line|
      type, source, string, array = *line
      string ||= source
      if array
        assert_equal array, Abi.send(:"to_#{type}", source),
                     "#{type} failed on string -> array"
        assert_equal string, Abi.send(:"read_#{type}", @garbage + array,
                                      @garbage.length)
      else
        assert_raise RuntimeError do
          assert_equal array, Abi.send(:"to_#{type}", source)
        end
      end      
    end    
  end
  
  def test_object_wrapper_directs
    packed = { :p => 2301, :q => 4141, :n => 60 } 
    gold_packed = Abi.to_packed packed
    wrapped = Abi.read_wrapped_raw @garbage + gold_packed, @garbage.length
    assert_equal Wrapped, wrapped.class,
                 'Reading wrapped object instantiated wrong class'
    assert_equal [packed[:p], packed[:q], packed[:n], nil, 'ctor default'],
                 [wrapped.p, wrapped.q, wrapped.n, wrapped.d, wrapped.c],
                 'Reading wrapped object gave wrong attributes'
    assert_equal gold_packed, Abi.to_wrapped_raw(wrapped),
                 'Wrapped object -> array'
  end
  
  def test_object_wrapper_schema
    packed = { :p => 2301, :q => 4141, :n => 60 } 
    xpacked = { :p => 6996, :q => 1331, :n => 22 }
    gold_packed = Abi.to_packed(packed) + Abi.to_packed(xpacked) +
                  Abi.to_mac_id("abc")
    multi = Abi.read_multi @garbage + gold_packed, @garbage.length
    assert_equal Multi, multi.class,
                'Reading wrapped object instantiated wrong class'
    assert_equal [packed[:p], packed[:q], packed[:n],
                  xpacked[:p], xpacked[:q], xpacked[:n], "abc\0\0\0",
                  "constant string"],
                 [multi.p, multi.q, multi.n, multi.a, multi.b, multi.c,
                  multi.str, multi.const],
                 'Reading wrapped object gave wrong attributes'
    assert_equal gold_packed, Abi.to_multi(multi),
                 'Wrapped object -> array'
  end

  def test_object_wrapper_hooks
    packed = { :p => 2301, :q => 4141, :n => 60 } 
    gold_packed = Abi.to_packed packed
    wrapped = Abi.read_wrapped @garbage + gold_packed, @garbage.length
    assert_equal Wrapped, wrapped.class,
                 'Reading wrapped object instantiated wrong class'
    assert_equal [nil, nil, nil, packed[:p] * packed[:q], 'hook-new'],
                 [wrapped.p, wrapped.q, wrapped.n, wrapped.d, wrapped.c],
                 'Reading wrapped object with hook gave wrong attributes'
                 
    wrapped = Abi.read_wrapped_raw gold_packed, 0
    packed[:n] *= 100
    gold_packed = Abi.to_packed packed
    assert_equal gold_packed, Abi.to_wrapped(wrapped),
                 'Wrapped object -> array (with hook)'
  end
  
  def test_length
    [[:byte, 1], [:ubyte, 1],
     [:word, 2], [:netword, 2],
     [:dword, 4], [:udword, 4],
     [:mac_id, 6]
    ].each do |test_line|
      assert_equal test_line.last, Abi.send(:"#{test_line.first}_length"),
                   "length failed for #{test_line.first}"
    end
  end
end
