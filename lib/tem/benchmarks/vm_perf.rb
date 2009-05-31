class Tem::Benchmarks
  def time_vm_perf
    secpack = @tem.assemble { |s|
      s.ldwc 48 * 10
      s.outnew

      s.ldwc 10 # number of times to loop (4 instructions in loop)
      s.label :main_loop      

      # arithmetic (18 instructions, 10 bytes out)
      s.ldwc 0x1234
      s.ldwc 0x5678
      s.dupn :n => 2
      s.add
      s.outw
      s.sub
      s.outw
      s.ldwc 0x0155
      s.ldwc 0x02AA
      s.mul
      s.outw
      s.ldwc 0x390C
      s.ldwc 0x00AA
      s.dupn :n => 2
      s.div
      s.outw
      s.mod
      s.outw
      
      # memory (28 instructions, 16 bytes out)
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
      
      # memory comparisons (22 instructions, 16 bytes out)
      s.ldwc :const => 6
      s.ldwc :cmp_med
      s.ldwc :cmp_lo
      s.mcmpvb
      s.outw
      s.mcmpfxb :size => 6, :op1 => :cmp_med, :op2 => :cmp_hi
      s.outw
      s.ldwc :const => 4
      s.ldwc :cmp_lo
      s.ldwc :cmp_med
      s.mcmpvb
      s.outw            
      s.mcfxb :size => 6, :from => :cmp_hi, :to => :copy_buf
      s.pop
      s.outfxb :size => 6, :from => :copy_buf      
      s.ldwc :const => 4
      s.ldwc :cmp_hi
      s.ldwc :copy_buf2
      s.mcvb
      s.pop
      s.outfxb :size => 4, :from => :copy_buf2            
      
      # jumps (30 instructions, 6 bytes) from 6 * (5 instructions, 1 byte)
      failed = 0xFA - (1 << 8)
      [
        [:ja,  [1, 1, failed]],
        [:jae, [1, 4, failed]], 
        [:jb,  [1, failed, 7]],
        [:jbe, [1, failed, 10]],
        [:jz,  [1, failed, 13]],
        [:jne, [1, 16, failed]], 
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

      # loop back
      s.ldbc 1
      s.sub
      s.dupn :n => 1
      s.ja :to => :main_loop
      
      s.label :done
      s.halt
      
      s.label :cmp_lo
      s.data :tem_ubyte, [0xA3, 0x2C, 0x51, 0x63, 0x2C, 0x12]
      s.label :cmp_med
      s.data :tem_ubyte, [0xA3, 0x2C, 0x51, 0x63, 0x2D, 0x11]
      s.label :cmp_hi
      s.data :tem_ubyte, [0xA3, 0x2C, 0x51, 0x63, 0x2E, 0x10]
      s.label :cmp_hi2
      s.data :tem_ubyte, [0xA3, 0x2C, 0x51, 0x63, 0x2E, 0x10]
      s.label :copy_buf
      s.zeros :tem_ubyte, 6
      s.label :copy_buf2
      s.zeros :tem_ubyte, 4      
      s.label :clobber
      s.zeros :tem_ubyte, 2
      s.label :clobber2
      s.zeros :tem_ubyte, 2
      s.label :stack
      s.stack 12
    }
    print "SECpack has #{secpack.body.length} bytes, runs 1020 instructions and produces 470 bytes\n"
    do_timing { @tem.execute secpack }
  end  
end