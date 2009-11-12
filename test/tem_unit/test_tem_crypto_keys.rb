require 'test/tem_test_case.rb'

class TemCryptoKeysTest < TemTestCase
  def i_crypt(data, key_id, authz, mode = :encrypt, direct_io = true,
              symmetric = false)
    if symmetric
      max_output = case mode
      when :encrypt
        ((data.length + 8) / 8) * 8
      when :decrypt
        data.length
      when :sign
        8
      end
    else
      max_output = case mode
      when :encrypt
        ((data.length + 239) / 240) * 256
      when :decrypt
        data.length
      when :sign
        256
      end
    end
    
    crypt_opcode =
        {:encrypt => :kefxb, :decrypt => :kdfxb, :sign => :ksfxb}[mode]
    ex_sec = @tem.assemble { |s|
      s.ldwc :const => max_output
      s.outnew
      s.ldbc :const => key_id
      s.authk :auth => :key_auth
      s.send crypt_opcode, :from => :data, :size => data.length,
                           :to => (direct_io ? 0xFFFF : :outdata) 
      s.outvlb :from => :outdata unless direct_io
      s.halt
      
      s.label :key_auth
      s.data :tem_ubyte, authz
      s.label :data
      s.data :tem_ubyte, data
      unless direct_io
        s.label :outdata
        s.zeros :tem_ubyte, max_output
      end
      s.stack 5
    }
    return @tem.execute(ex_sec)
  end
  
  def i_verify(data, signature, key_id, authz)
    sign_sec = @tem.assemble { |s|
      s.ldbc :const => 1
      s.outnew
      s.ldbc :const => key_id
      s.authk :auth => :key_auth
      s.kvsfxb :from => :data, :size => data.length, :signature => :signature 
      s.outb
      s.halt
      
      s.label :key_auth
      s.data :tem_ubyte, authz
      s.label :data
      s.data :tem_ubyte, data
      s.label :signature
      s.data :tem_ubyte, signature
      s.stack 5
    }
    return @tem.execute(sign_sec)[0] == 1
  end
  
  def i_test_crypto_pks_ops(pubk_id, privk_id, pubk, privk, authz)
    garbage = (0...569).map { |i| (i * i * 217 + i * 661 + 393) % 256 }

    # SEC/priv-sign + CPU/pub-verify, direct IO.
    signed_garbage = i_crypt garbage, privk_id, authz, :sign, true
    assert privk.verify(garbage, signed_garbage),
           'SEC priv-signing + CPU pub-verify failed on good data'

    # SEC/priv-sign + CPU/pub-verify, indirect IO.
    signed_garbage = i_crypt garbage, privk_id, authz, :sign, false
    assert privk.verify(garbage, signed_garbage),
           'SEC priv-signing + CPU pub-verify failed on good data'

    # CPU/priv-sign + SEC/pub-verify.
    signed_garbage = privk.sign garbage 
    assert i_verify(garbage, signed_garbage, pubk_id, authz),
           'CPU priv-signing + SEC pub-verify failed on good data'

    # CPU/priv-encrypt + SEC/pub-decrypt, indirect IO.
    encrypted_garbage = privk.encrypt garbage 
    decrypted_garbage = i_crypt encrypted_garbage, pubk_id, authz, :decrypt,
                                false
    assert_equal garbage, decrypted_garbage,
                 'CPU priv-encryption + SEC pub-decryption/i messed up the data'  

    # SEC/pub-encrypt + CPU/priv-decrypt, indirect IO.
    encrypted_garbage = i_crypt garbage, pubk_id, authz, :encrypt, false
    decrypted_garbage = privk.decrypt encrypted_garbage
    assert_equal garbage, decrypted_garbage,
                 'SEC pub-encryption/i + CPU priv-decryption messed up the data'  
    
    # CPU/pub-encrypt + SEC/priv-decrypt, direct-IO.
    encrypted_garbage = pubk.encrypt garbage 
    decrypted_garbage = i_crypt encrypted_garbage, privk_id, authz, :decrypt,
                                true
    assert_equal garbage, decrypted_garbage,
                 'CPU pub-encryption + SEC priv-decryption messed up the data' 

    # SEC/priv-encrypt + CPU/pub-decrypt, direct-IO.
    encrypted_garbage = i_crypt garbage, privk_id, authz, :encrypt, true
    decrypted_garbage = pubk.decrypt encrypted_garbage
    assert_equal garbage, decrypted_garbage,
                 'SEC priv-encryption + CPU pub-decryption messed up the data'    
  end
  
  def test_crypto_asymmetric
    # Crypto run with an internally generated key.
    keyd = @tem.tk_gen_key :asymmetric
    pubk = @tem.tk_read_key keyd[:pubk_id], keyd[:authz]
    privk = @tem.tk_read_key keyd[:privk_id], keyd[:authz]
    i_test_crypto_pks_ops keyd[:pubk_id], keyd[:privk_id], pubk, privk,
                          keyd[:authz]
    
    # Crypto run with an externally generated key.
    ekey = OpenSSL::PKey::RSA.generate(2048, 65537)
    pubk = Tem::Key.new_from_ssl_key ekey.public_key
    privk = Tem::Key.new_from_ssl_key ekey
    pubk_id = @tem.tk_post_key pubk, keyd[:authz] 
    privk_id = @tem.tk_post_key privk, keyd[:authz]
    i_test_crypto_pks_ops pubk_id, privk_id, pubk, privk, keyd[:authz]
  end
  
  def i_test_crypto_sks_ops(skey_id, skey, authz)
    garbage = (0...569).map { |i| (i * i * 217 + i * 661 + 393) % 256 }

    # SEC/sign + CPU/verify, direct IO.
    signed_garbage = i_crypt garbage, skey_id, authz, :sign, true, true
    assert skey.verify(garbage, signed_garbage),
           'SEC signing + CPU verify failed on good data'

    # SEC/sign + CPU/verify, indirect IO.
    signed_garbage = i_crypt garbage, skey_id, authz, :sign, false, true
    assert skey.verify(garbage, signed_garbage),
           'SEC signing + CPU verify failed on good data'

    # CPU/sign + SEC/verify.
    signed_garbage = skey.sign garbage 
    assert i_verify(garbage, signed_garbage, skey_id, authz),
           'CPU signing + SEC verify failed on good data'

    # CPU/encrypt + SEC/decrypt, indirect IO.
    encrypted_garbage = skey.encrypt garbage
    decrypted_garbage = i_crypt encrypted_garbage, skey_id, authz, :decrypt,
                                false, true
    assert_equal garbage, decrypted_garbage,
                 'CPU encryption + SEC decryption/i messed up the data'  

    # SEC/encrypt + CPU/decrypt, indirect IO.
    encrypted_garbage = i_crypt garbage, skey_id, authz, :encrypt, false, true
    decrypted_garbage = skey.decrypt encrypted_garbage
    assert_equal garbage, decrypted_garbage,
                 'SEC encryption/i + CPU decryption messed up the data'  
    
    # CPU/encrypt + SEC/decrypt, direct IO.
    encrypted_garbage = skey.encrypt garbage
    decrypted_garbage = i_crypt encrypted_garbage, skey_id, authz, :decrypt,
                                true, true
    assert_equal garbage, decrypted_garbage,
                 'CPU encryption + SEC decryption messed up the data'  

    # SEC/encrypt + CPU/decrypt, direct IO.
    encrypted_garbage = i_crypt garbage, skey_id, authz, :encrypt, true, true
    decrypted_garbage = skey.decrypt encrypted_garbage
    assert_equal garbage, decrypted_garbage,
                 'SEC encryption + CPU decryption messed up the data'  
  end
  
  def test_crypto_symmetric
    keyd = @tem.tk_gen_key :symmetric
    skey = @tem.tk_read_key keyd[:key_id], keyd[:authz]
    i_test_crypto_sks_ops keyd[:key_id], skey, keyd[:authz]

    ekey = OpenSSL::Cipher::Cipher.new('DES-EDE-CBC').random_key
    skey = Tem::Key.new_from_ssl_key ekey
    skey_id = @tem.tk_post_key skey, keyd[:authz]
    i_test_crypto_sks_ops skey_id, skey, keyd[:authz]
  end
end
