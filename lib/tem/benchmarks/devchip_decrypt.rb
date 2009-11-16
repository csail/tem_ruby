# Benchmarks the TEM hardware's decryption facility. 
#
# This is the chip's native decryption speed. The difference between this time
# and the time it takes to decrypt a bound SECpack is overhead added by the TEM
# firmware. That overhead should be kept to a minimum.  
#
# Author:: Victor Costan
# Copyright:: Copyright (C) 2008 Massachusetts Institute of Technology
# License:: MIT


# :nodoc:
class Tem::Benchmarks
  def time_devchip_decrypt_rsa_long
    pubek = @tem.pubek
    data = (1...120).map { |i| (i * i * 217 + i * 661 + 393) % 256 }
    encrypted_data = pubek.encrypt data
    print "RSA-encrypted blob has #{encrypted_data.length} bytes\n"
    do_timing { @tem.devchip_decrypt encrypted_data, 0 }
  end

  def time_devchip_decrypt_3des
    key = Tem::Keys::Symmetric.generate
    authz = [1] * 20
    key_id = @tem.tk_post_key key, authz
    data = (1...23).map { |i| (i * i * 217 + i * 661 + 393) % 256 }
    encrypted_data = key.encrypt data
    print "3DES-encrypted blob has #{encrypted_data.length} bytes\n"
    do_timing { @tem.devchip_decrypt encrypted_data, key_id }
    @tem.tk_delete_key key_id, authz
  end

  def time_devchip_decrypt_3des_long
    key = Tem::Keys::Symmetric.generate
    authz = [1] * 20
    key_id = @tem.tk_post_key key, authz
    data = (1...120).map { |i| (i * i * 217 + i * 661 + 393) % 256 }
    encrypted_data = key.encrypt data
    print "3DES-encrypted blob has #{encrypted_data.length} bytes\n"
    do_timing { @tem.devchip_decrypt encrypted_data, key_id }
    @tem.tk_delete_key key_id, authz
  end
end
