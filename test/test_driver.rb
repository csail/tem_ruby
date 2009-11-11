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
  
  def test_tag
    garbage = (1...569).map { |i| (i * i * 217 + i * 661 + 393) % 256 }
    
    assert_raise Smartcard::Iso::ApduError, 'tag returned before being set' do
      @tem.get_tag
    end
    
    @tem.set_tag garbage
    assert_equal garbage, @tem.get_tag, 'error in posted tag data'    
  end

  def test_crypto
    garbage = (1...415).map { |i| (i * i * 217 + i * 661 + 393) % 256 } 
    key_pair = @tem.devchip_generate_key_pair
    pubkey = @tem.devchip_save_key key_pair[:pubkey_id]
    
    encrypted_garbage = @tem.devchip_encrypt garbage, key_pair[:privkey_id]
    decrypted_garbage = pubkey.decrypt encrypted_garbage
    assert_equal garbage, decrypted_garbage, 'priv-encryption+pub-decryption messed up the data' 
  
    encrypted_garbage = pubkey.encrypt garbage
    decrypted_garbage = @tem.devchip_decrypt encrypted_garbage, key_pair[:privkey_id]  
    assert_equal garbage, decrypted_garbage, 'pub-encryption+priv-decryption messed up the data'
    
    key_stat = @tem.stat_keys
    assert key_stat[:keys], 'key stat does not contain key information'
    assert_equal :public, key_stat[:keys][key_pair[:pubkey_id]][:type], 'key stat reports wrong type for public key'
    assert_equal :private, key_stat[:keys][key_pair[:privkey_id]][:type], 'key stat reports wrong type for private key'
    assert_in_delta 2, 2048, key_stat[:keys][key_pair[:pubkey_id]][:bits], 'key stat reports wrong size for public key'
    assert_in_delta 2, 2048, key_stat[:keys][key_pair[:privkey_id]][:bits], 'key stat reports wrong size for private key'
    
    [:pubkey_id, :privkey_id].each { |ki| @tem.devchip_release_key key_pair[ki] }
  end
  
  def test_crypto_abi
    ekey = OpenSSL::PKey::RSA.generate(2048, 65537)
    pubk = Tem::Key.new_from_ssl_key ekey.public_key
    privk = Tem::Key.new_from_ssl_key ekey
    
    # array and string encryption/decryption
    garbage = (1...569).map { |i| (i * i * 217 + i * 661 + 393) % 256 }
    [garbage, garbage.pack('C*')].each do |g|
      encrypted_garbage = pubk.encrypt g
      decrypted_garbage = privk.decrypt encrypted_garbage
      assert_equal g, decrypted_garbage, 'pub-encryption+priv-decryption messed up the data'
      encrypted_garbage = privk.encrypt g
      decrypted_garbage = pubk.decrypt encrypted_garbage
      assert_equal g, decrypted_garbage, 'priv-encryption+pub-decryption messed up the data'
    end
    
    # test key serialization/deserialization through encryption/decryption
    pubk_ys = pubk.to_yaml_str
    pubk2 = Tem::Keys::Asymmetric.new_from_yaml_str(pubk_ys)
    privk_ys = privk.to_yaml_str
    privk2 = Tem::Keys::Asymmetric.new_from_yaml_str(privk_ys)
    encrypted_garbage = pubk.encrypt garbage
    decrypted_garbage = privk2.decrypt encrypted_garbage
    assert_equal garbage, decrypted_garbage, 'pub-encryption+priv-decryption messed up the data'
    encrypted_garbage = privk.encrypt garbage
    decrypted_garbage = pubk2.decrypt encrypted_garbage
    assert_equal garbage, decrypted_garbage, 'priv-encryption+pub-decryption messed up the data'
  end
end
