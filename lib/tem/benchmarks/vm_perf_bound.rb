# Benchmarks the TEM virtual machine's execution speed on bound SECpacks.
#
# The difference between this time and the time it takes to execute a blank
# bound SECpack is pure VM execution time. This execution time should not be
# significantly different from the execution time for unbound SECpacks.
#
# Author:: Victor Costan
# Copyright:: Copyright (C) 2008 Massachusetts Institute of Technology
# License:: MIT


# :nodoc:
class Tem::Benchmarks
  def time_vm_perf_bound_rsa
    secpack = vm_perf_seclosure
    secpack.bind @tem.pubek, :done, :stack
    print "RSA-bound SECpack has #{secpack.body.length} bytes, " +
          "executes #{vm_perf_seclosure_opcount} instructions and produces " +
          "#{vm_perf_seclosure_outcount} bytes\n"
    do_timing { @tem.execute secpack }
  end
  
  def time_vm_perf_bound_3des
    key = Tem::Keys::Symmetric.generate
    authz = [1] * 20
    key_id = @tem.tk_post_key key, authz
    
    secpack = vm_perf_seclosure
    secpack.bind key, :done, :stack
    print "3DES-bound SECpack has #{secpack.body.length} bytes, " +
          "executes #{vm_perf_seclosure_opcount} instructions and produces " +
          "#{vm_perf_seclosure_outcount} bytes\n"
    do_timing { @tem.execute secpack, key_id }

    @tem.release_key key_id    
  end
end
