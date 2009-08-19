require 'test/tem_test_case.rb'

class TemOutputTest < TemTestCase
  def test_output
    sec = @tem.assemble { |s|
      s.ldbc 32
      s.outnew
      s.outfxb :size => 3, :from => :area1
      s.ldbc 5
      s.outvlb :from => :area2
      s.ldbc 4
      s.ldwc :area3
      s.outvb
      s.ldwc 0x99AA - (1 << 16)
      s.ldwc 0xFA55 - (1 << 16)
      s.outb
      s.outw        
      s.halt
      s.label :area1
      s.data :tem_ubyte, [0xFE, 0xCD, 0x9A]
      s.label :area2
      s.data :tem_ubyte, [0xAB, 0x95, 0xCE, 0xFD, 0x81]
      s.label :area3
      s.data :tem_ubyte, [0xEC, 0xDE, 0xAD, 0xCF]
      s.stack 5
    }
    result = @tem.execute sec
    assert_equal [0xFE, 0xCD, 0x9A, 0xAB, 0x95, 0xCE, 0xFD, 0x81, 0xEC, 0xDE,
                  0xAD, 0xCF, 0x55, 0x99, 0xAA],
                 result, 'the output unit isn\'t working well'    
  end
end
