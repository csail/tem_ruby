require 'test/tem_test_case.rb'


class DriverTest < TemTestCase
  def test_tag_reading_before_writing
    assert_raise Smartcard::Iso::ApduError,
                 'Tag length returned before being set' do
      @tem.get_raw_tag_length
    end

    assert_raise Smartcard::Iso::ApduError,
                 'Tag data returned before being set' do
      @tem.get_raw_tag_data 0, 1
    end    
  end
  
  def test_raw_tag_io
    garbage = (1...569).map { |i| (i * i * 217 + i * 661 + 393) % 256 }
        
    @tem.set_raw_tag_data garbage    
    assert_equal garbage.length, @tem.get_raw_tag_length,
                 'Error in raw tag length'
    assert_equal garbage[19, 400], @tem.get_raw_tag_data(19, 400),
                 'Error in raw tag data partial read'    
    assert_equal garbage, @tem.get_raw_tag_data(0, garbage.length),
                 'Error in raw tag data full read'    
  end
  
  def test_structured_tag
    g1 = (1...569).map { |i| (i * i * 217 + i * 661 + 393) % 256 }
    g2 = (570...1032).map { |i| (i * i * 217 + i * 661 + 393) % 256 }
    tag_data = { 0x01 => g1, 0x11 => g2 }
    
    encoded = Tem::Apdus::Tag.encode_tag tag_data
    assert_equal tag_data, Tem::Apdus::Tag.decode_tag(encoded),
                 'Inconsistency in TLV encoding / decoding'
                 
    @tem.set_tag tag_data
    @tem.clear_icache
    assert_equal tag_data, @tem.tag
  end
end
