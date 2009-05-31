require 'test/tem_test_case'

class TemBranchingTest < TemTestCase
  def test_branching
    secpack = @tem.assemble { |s|
      s.ldbc 24
      s.outnew
      
      s.jmp :to => :over_halt
      s.halt  # this gets jumped over
      s.label :over_halt
      s.ldbc 4
      s.label :test_loop
      s.dupn :n => 1
      s.outb
      s.ldbc 1
      s.sub
      s.dupn :n=> 1
      s.jae :to => :test_loop

      failed = 0xFA - (1 << 8)
      [
        [:ja,  [1, 1, failed],  [0, failed, 2],  [-1, failed, 3]],
        [:jae, [1, 4, failed],  [0, 5, failed],  [-1, failed, 6]], 
        [:jb,  [1, failed, 7],  [0, failed, 8],  [-1, 9, failed]],
        [:jbe, [1, failed, 10], [0, 11, failed], [-1, 12, failed]],
        [:jz,  [1, failed, 13], [0, 14, failed], [-1, failed, 15]],
        [:jne, [1, 16, failed], [0, failed, 17], [-1, 18, failed]], 
      ].each do |op_line|
        op = op_line.shift
        op_line.each_index do |i|
          then_label = "#{op}_l#{i}_t".to_sym
          out_label  = "#{op}_l#{i}_o".to_sym
          
          s.ldbc op_line[i][0]        
          s.send op, :to => then_label
          s.ldbc op_line[i][2]
          s.jmp :to => out_label
          s.label then_label
          s.ldbc op_line[i][1]
          s.label out_label
          s.outb          
        end
      end
      
      s.halt
      # Test automated stack placement.
      s.zeros :tem_ubyte, 10
    }
    result = @tem.execute secpack
    assert_equal [0x04, 0x03, 0x02, 0x01, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05,
                  0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F,
                  0x10, 0x11, 0x12],
                 result, 'the branching unit isn\'t working well'        
  end
  
  def test_calls
    secpack = @tem.assemble { |s|
      s.ldbc 4
      s.outnew
      s.call :proc1
      s.call :proc1
      s.call :proc1
      s.call :proc1
      s.halt
      
      s.label :proc1
      s.ldw :proc1var
      s.dupn :n => 1
      s.outb
      s.ldbc 1
      s.add
      s.stw :proc1var
      s.ret
      s.label :proc1var
      s.data :tem_short, 5
      s.stack 3
    }
    result = @tem.execute secpack
    assert_equal [5, 6, 7, 8], result, 'the branching unit isn\'t working well'    
  end
end
