require 'test/tem_test_case.rb'


class CryptoEngineTest < TemTestCase
  def test_crypto_pks
    garbage = (0...415).map { |i| (i * i * 217 + i * 661 + 393) % 256 } 
    key_pair = @tem.devchip_generate_key_pair
    pubkey = @tem.devchip_save_key key_pair[:pubkey_id]
    
    encrypted_garbage = @tem.devchip_encrypt garbage, key_pair[:privkey_id]
    decrypted_garbage = pubkey.decrypt encrypted_garbage
    assert_equal garbage, decrypted_garbage,
                 'Onchip-encryption + offchip-decryption messed up the data.' 
  
    encrypted_garbage = pubkey.encrypt garbage
    decrypted_garbage = @tem.devchip_decrypt encrypted_garbage,
                                             key_pair[:privkey_id]  
    assert_equal garbage, decrypted_garbage,
                 'Offchip-encryption + onchip-decryption messed up the data.'
    
    key_stat = @tem.stat_keys
    assert key_stat[:keys], 'Key stat does not contain key information.'
    assert_equal :public, key_stat[:keys][key_pair[:pubkey_id]][:type],
                 'Key stat reports wrong type for public key.'
    assert_equal :private, key_stat[:keys][key_pair[:privkey_id]][:type],
                 'Key stat reports wrong type for private key.'
    assert_in_delta 2, 2048, key_stat[:keys][key_pair[:pubkey_id]][:bits],
                    'Key stat reports wrong size for public key.'
    assert_in_delta 2, 2048, key_stat[:keys][key_pair[:privkey_id]][:bits],
                    'Key stat reports wrong size for private key.'
    
    [:pubkey_id, :privkey_id].each do |key|
      @tem.devchip_release_key key_pair[key]
    end
  end
  
  def test_crypto_symmetric
    garbage = (0...415).map { |i| (i * i * 217 + i * 661 + 393) % 256 } 
    key_pair = @tem.devchip_generate_key_pair true
    assert_equal(-1, key_pair[:pubkey_id],
                 'Key generation should yield INVALID_KEY for the public key')
    key = @tem.devchip_save_key key_pair[:privkey_id]
    
    encrypted_garbage = @tem.devchip_encrypt garbage, key_pair[:privkey_id]
    decrypted_garbage = key.decrypt encrypted_garbage
    assert_equal garbage, decrypted_garbage,
                 'Onchip-encryption + offchip-decryption messed up the data' 

    encrypted_garbage = key.encrypt garbage
    decrypted_garbage = @tem.devchip_decrypt encrypted_garbage,
                                             key_pair[:privkey_id]
    assert_equal garbage, decrypted_garbage,
                 'Offchip-encryption + onchip-decryption messed up the data.'

    key_stat = @tem.stat_keys
    assert key_stat[:keys], 'Key stat does not contain key information.'
    assert_equal :symmetric, key_stat[:keys][key_pair[:privkey_id]][:type],
                 'Key stat reports wrong type for symmetric key.'
    assert_equal 128, key_stat[:keys][key_pair[:privkey_id]][:bits],
                 'Key stat reports wrong size for symmetric key.'
    
    @tem.devchip_release_key key_pair[:privkey_id]
  end
  
  def test_crypto_abi
    ekey = OpenSSL::PKey::RSA.generate(2048, 65537)
    pubk = Tem::Key.new_from_ssl_key ekey.public_key
    privk = Tem::Key.new_from_ssl_key ekey
    
    skey = OpenSSL::Cipher::Cipher.new('DES-EDE-CBC').random_key
    symk = Tem::Key.new_from_ssl_key skey
    
    # Array and string encryption/decryption.
    garbage = (1...569).map { |i| (i * i * 217 + i * 661 + 393) % 256 }
    [garbage, garbage.pack('C*')].each do |g|
      encrypted_garbage = pubk.encrypt g
      decrypted_garbage = privk.decrypt encrypted_garbage
      assert_equal g, decrypted_garbage,
                   'Pub-encryption + priv-decryption messed up the data'
      encrypted_garbage = privk.encrypt g
      decrypted_garbage = pubk.decrypt encrypted_garbage
      assert_equal g, decrypted_garbage,
                   'Priv-encryption + pub-decryption messed up the data'

      encrypted_garbage = symk.encrypt g[0, 560]
      decrypted_garbage = symk.decrypt encrypted_garbage
      assert_equal g[0, 560], decrypted_garbage,
                   'Symmetric encryption + decryption messed up the data'
    end
    
    # Test key serialization/deserialization through encryption/decryption.
    pubk_ys = pubk.to_yaml_str
    pubk2 = Tem::Keys::Asymmetric.new_from_yaml_str pubk_ys
    privk_ys = privk.to_yaml_str
    privk2 = Tem::Keys::Asymmetric.new_from_yaml_str privk_ys
    encrypted_garbage = pubk.encrypt garbage
    decrypted_garbage = privk2.decrypt encrypted_garbage
    assert_equal garbage, decrypted_garbage,
                 'YAML pub-encryption + priv-decryption messed up the data.'
    encrypted_garbage = privk.encrypt garbage
    decrypted_garbage = pubk2.decrypt encrypted_garbage
    assert_equal garbage, decrypted_garbage,
                 'YAML priv-encryption + pub-decryption messed up the data.'

    symk_ys = symk.to_yaml_str
    symk2 = Tem::Keys::Symmetric.new_from_yaml_str symk_ys
    encrypted_garbage = symk.encrypt garbage[0, 560]
    decrypted_garbage = symk2.decrypt encrypted_garbage
    assert_equal garbage[0, 560], decrypted_garbage,
                 'Symmetric encryption + YAML decryption messed up the data'
    encrypted_garbage = symk2.encrypt garbage[0, 560]
    decrypted_garbage = symk.decrypt encrypted_garbage
    assert_equal garbage[0, 560], decrypted_garbage,
                 'YAML symmetric encryption + decryption messed up the data'
  end
end
