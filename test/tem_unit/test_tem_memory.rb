require 'test/tem_test_case'

class TemMemoryTest < TemTestCase
  def test_memory
    sec = @tem.assemble { |s|
      s.label :clobber
      s.ldbc 32
      s.label :clobber2
      s.outnew
      s.ldwc 0x55AA
      s.stw :clobber
      s.ldb :clobber
      s.outw
      s.ldw :clobber
      s.outw
      s.ldbc 0xA5 - (1 << 8)
      s.stb :clobber
      s.ldw :clobber
      s.outw
      s.ldwc :clobber2
      s.dupn :n => 1
      s.dupn :n => 2
      s.ldwc 0x9966 - (1 << 16)
      s.stwv
      s.ldbv
      s.outw
      s.ldbc 0x98 - (1 << 8)
      s.stbv
      s.ldwv
      s.outw
      s.ldwc 0x1122
      s.ldwc 0x3344
      s.ldwc 0x5566
      s.flipn :n => 3
      s.outw
      s.outw
      s.outw
      s.halt
      # Test stack without arguments.
      s.stack
      s.zeros :tem_short, 5
    }
    result = @tem.execute sec
    assert_equal [0x00, 0x55, 0x55, 0xAA, 0xA5, 0xAA, 0xFF, 0x99, 0x98, 0x66,
                  0x11, 0x22, 0x33, 0x44, 0x55, 0x66],
                 result, 'the memory unit isn\'t working well'    
  end
end
