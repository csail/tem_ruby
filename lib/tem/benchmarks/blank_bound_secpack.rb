# Benchmarks decrypting a bound SECpack. 
#
# This is a lower bound on the time it takes to execute any bound SECpack.
#
# Author:: Victor Costan
# Copyright:: Copyright (C) 2008 Massachusetts Institute of Technology
# License:: MIT


# :nodoc:
class Tem::Benchmarks
  def time_blank_bound_secpack_rsa
    secpack = blank_seclosure
    secpack.bind @tem.pubek, :secret, :plain
    print "RSA-bound SECpack has #{secpack.body.length} bytes, " +
          "executes #{blank_seclosure_opcount} instructions and produces " +
          "#{blank_seclosure_outcount} bytes\n"
    do_timing { @tem.execute secpack }
  end
  
  def time_blank_bound_secpack_3des
    key = Tem::Keys::Symmetric.generate
    authz = [1] * 20
    key_id = @tem.tk_post_key key, authz
    
    secpack = blank_seclosure
    secpack.bind key, :secret, :plain
    print "3DES-bound SECpack has #{secpack.body.length} bytes, " +
          "executes #{blank_seclosure_opcount} instructions and produces " +
          "#{blank_seclosure_outcount} bytes\n"
    do_timing { @tem.execute secpack, key_id }

    @tem.release_key key_id
  end  
end
