class TemTimings
  def time_blank_sec
    secpack = @tem.assemble { |s|
      s.ldbc 0
      s.outnew
      s.halt
      s.filler :ubyte, 70
      s.stack
      s.extra 2
    }

    print "SECpack has #{secpack.body.length} bytes, runs 3 instructions and produces 0 bytes\n"
    do_timing { @tem.execute secpack }
  end
end
