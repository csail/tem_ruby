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
  def time_devchip_decrypt
    pubek = @tem.pubek
    data = (1...120).map { |i| (i * i * 217 + i * 661 + 393) % 256 }
    encrypted_data = pubek.encrypt data
    print "Encrypted blob has #{encrypted_data.length} bytes\n"
    do_timing { @tem.devchip_decrypt encrypted_data, 0 }
  end
end
