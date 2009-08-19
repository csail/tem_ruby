# Benchmarks SECpack loading. 
#
# Any SECpack execution will take the overhead of loading the SECpack. Loading a
# SECpack requires placing the SECpack's contents into a buffer. The difference
# between the time it takes to post a buffer and the time it takes to load a
# SECpack is overhead in the TEM firmware. This overhead should be kept to a
# minimum.
#
# Author:: Victor Costan
# Copyright:: Copyright (C) 2008 Massachusetts Institute of Technology
# License:: MIT


# :nodoc:
class Tem::Benchmarks
  def time_blank_sec
    secpack = @tem.assemble { |s|
      s.ldbc 0
      s.outnew
      s.halt
      s.zeros :tem_ubyte, 70
      s.stack 1
    }

    print "SECpack has #{secpack.body.length} bytes, runs 3 instructions and produces 0 bytes\n"
    do_timing { @tem.execute secpack }
  end
end
