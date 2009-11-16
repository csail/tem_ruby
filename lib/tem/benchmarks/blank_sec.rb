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
  # The SEClosure used in the blank benchmark.
  def blank_seclosure
    @tem.assemble { |s|
      s.ldbc 0
      s.outnew
      s.halt
      s.label :secret
      s.zeros :tem_ubyte, 50
      s.label :plain
      s.zeros :tem_ubyte, 220
      s.stack 1
    }
  end
  
  # Number of opcodes executed by the blank SEClosure.
  def blank_seclosure_opcount
    3
  end
  
  # Number of bytes output by the blank SEClosure.
  def blank_seclosure_outcount
    0
  end
  
  def time_blank_sec
    secpack = blank_seclosure
    print "SECpack has #{secpack.body.length} bytes, " +
          "executes #{blank_seclosure_opcount} instructions and produces " +
          "#{blank_seclosure_outcount} bytes\n"
    do_timing { @tem.execute secpack }
  end
end
