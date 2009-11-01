# Benchmarks decrypting a bound SECpack. 
#
# This is a lower bound on the time it takes to execute any bound SECpack.
#
# Author:: Victor Costan
# Copyright:: Copyright (C) 2008 Massachusetts Institute of Technology
# License:: MIT


# :nodoc:
class Tem::Benchmarks
  def time_blank_bound_secpack
    secpack = @tem.assemble { |s|
      s.ldbc 0
      s.outnew
      s.halt
      s.label :secret
      s.zeros :tem_ubyte, 50
      s.label :plain
      s.zeros :tem_ubyte, 220
      s.stack 1
    }
    secpack.bind @tem.pubek, :secret, :plain

    print "SECpack has #{secpack.body.length} bytes, runs 3 instructions and produces 0 bytes\n"
    do_timing { @tem.execute secpack }
  end
end