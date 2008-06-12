class TemTimings
  def time_blank_bound_secpack
    secpack = @tem.assemble { |s|
      s.ldbc 0
      s.outnew
      s.halt
      s.label :secret
      s.filler :ubyte, 50
      s.label :plain
      s.filler :ubyte, 220
      s.stack
      s.extra 2
    }
    secpack.bind @tem.pubek, :secret, :plain

    print "SECpack has #{secpack.body.length} bytes, runs 3 instructions and produces 0 bytes\n"
    do_timing { @tem.execute secpack }
    
  end
end
