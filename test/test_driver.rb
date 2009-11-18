require 'test/tem_test_case.rb'


class DriverTest < TemTestCase
  def test_version
    version = @tem.fw_version
    assert version[:major].kind_of?(Numeric) &&
           version[:minor].kind_of?(Numeric),
           'Firmware version has wrong format'
  end
  
  def test_buffers_io
    garbage = (1...569).map { |i| (i * i * 217 + i * 661 + 393) % 256 }
    
    bid = @tem.post_buffer garbage
    assert_equal garbage.length, @tem.get_buffer_length(bid), 'error in posted buffer length'
    assert_equal garbage, @tem.read_buffer(bid), 'error in posted buffer data' 
  
    garbage.reverse!
    @tem.write_buffer bid, garbage
    assert_equal garbage, @tem.read_buffer(bid), 'error in (reverted) posted buffer data'
    @tem.release_buffer bid
    
    @tem.post_buffer [1]
    @tem.post_buffer [2]
    @tem.flush_buffers
    assert_equal 0, @tem.stat_buffers[:buffers].reject { |b| b[:free] }.length, 'flush_buffers left allocated buffers'
  end
  
  def test_buffers_alloc
    b_lengths = [569, 231, 455, 18, 499, 332, 47]
    b_ids = b_lengths.map { |len| @tem.alloc_buffer(len) }
    bstat = @tem.stat_buffers
    
    assert bstat[:free], 'buffer stat does not contain free memory information'
    assert bstat[:free][:persistent].kind_of?(Numeric), 'buffer stat does not show free persistent memory'
    assert bstat[:free][:persistent] >= 0, 'buffer stat shows negative free persistent memory'
    assert bstat[:free][:clear_on_reset].kind_of?(Numeric), 'buffer stat does not show free clear_on_reset memory'
    assert bstat[:free][:clear_on_reset] >= 0, 'buffer stat shows negative free clear_on_reset memory'
    assert bstat[:free][:clear_on_deselect].kind_of?(Numeric), 'buffer stat does not show free clear_on_deselect memory'
    assert bstat[:free][:clear_on_deselect] >= 0, 'buffer stat shows negative free clear_on_deselect memory'

    b_lengths.each_index do |i|
      assert bstat[:buffers][b_ids[i]], "buffer stat does not show an entry for a #{b_lengths[i]}-bytes buffer" 
      assert bstat[:buffers][b_ids[i]][:type].kind_of?(Symbol), "buffer stat does not show the memory type for a #{b_lengths[i]}-bytes buffer" 
      assert_equal b_lengths[i], bstat[:buffers][b_ids[i]][:length], "bad length in buffer stat entry for a #{b_lengths[i]}-bytes buffer" 
      assert_equal false, bstat[:buffers][b_ids[i]][:pinned], "bad pinned flag in buffer stat entry for a #{b_lengths[i]}-bytes buffer" 
      assert_equal true, bstat[:buffers][b_ids[i]][:public], "bad public flag in buffer stat entry for a #{b_lengths[i]}-bytes buffer" 
    end

    b_ids.each { |bid| @tem.release_buffer(bid) }
  end  
end
