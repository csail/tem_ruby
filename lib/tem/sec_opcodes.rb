class Tem::SecAssembler
  # 2 ST -> 1 ST
  opcode :add,    0x10
  # 2 ST -> 1 ST
  opcode :sub,    0x11
  # 2 ST -> 1 ST
  opcode :mul,    0x12
  # 2 ST -> 1 ST
  opcode :div,    0x13
  # 2 ST -> 1 ST
  opcode :mod,    0x14
  # 2 ST -> 1 ST 
  opcode :rnd,    0x1E
  

  # 2 ST -> 1 ST
  opcode :stbv,    0x3A
  # 2 ST -> 1 ST
  opcode :stwv,    0x3B

  # 2 ST -> 1 ST
  opcode :stk,     0x5B
  

  # 1 ST, 1 IM -> 1 ST
  opcode :stb ,    0x38, {:name => :to, :type => :ushort}
  # 1 ST, 1 IM -> 1 ST
  opcode :stw ,    0x39, {:name => :to, :type => :ushort}
  

  # 2 IM -> 1 ST
  opcode(:psupfxb, 0x48, {:name => :addr, :type => :ushort}, {:name => :from, :type => :ushort})
  # 2 ST -> 1 ST
  opcode :psupvb,  0x49
  # 2 IM -> 1 ST
  opcode(:pswrfxb, 0x4A, {:name => :addr, :type => :ushort}, {:name => :from, :type => :ushort})
  # 2 ST -> 1 ST
  opcode :pswrvb,  0x4B
  # 2 IM -> 1 ST
  opcode(:psrdfxb, 0x4C, {:name => :addr, :type => :ushort}, {:name => :to, :type => :ushort})
  # 2 ST -> 1 ST
  opcode :psrdvb,  0x4D
  # 2 IM -> 1 ST
  opcode :pshkfxb, 0x4E, {:name => :addr, :type => :ushort}
  # 2 ST -> 1 ST
  opcode :pshkvb,  0x4F
  
  
  # 3 IM -> 1 ST
  opcode(:mdfxb,  0x18, {:name => :size, :type => :ushort}, {:name => :from, :type => :ushort}, {:name => :to, :type => :ushort})
  # 3 ST -> 1 ST
  opcode :mdvb,   0x19
  # 3 IM -> 1 ST
  opcode(:mcmpfxb,0x1A, {:name => :size, :type => :ushort}, {:name => :op1, :type => :ushort}, {:name => :op2, :type => :ushort})
  # 3 ST -> 1 ST  
  opcode :mcmpvb, 0x1B
  # 3 IM -> 1 ST
  opcode(:mcfxb,  0x1C, {:name => :size, :type => :ushort}, {:name => :from, :type => :ushort}, {:name => :to, :type => :ushort})
  # 3 ST -> 1 ST
  opcode :mcvb,   0x1D
  
  # 1 ST, 3 IM -> 1 ST   
  opcode(:kefxb,   0x50, {:name => :size, :type => :ushort}, {:name => :from, :type => :ushort}, {:name => :to, :type => :ushort})
  # 4 ST -> 1 ST
  opcode :kevb,    0x51
  # 1 ST, 3 IM -> 1 ST   
  opcode(:kdfxb,   0x52, {:name => :size, :type => :ushort}, {:name => :from, :type => :ushort}, {:name => :to, :type => :ushort})
  # 4 ST -> 1 ST
  opcode :kdvb,    0x53
  # 1 ST, 3 IM -> 1 ST   
  opcode(:ksfxb,   0x54, {:name => :size, :type => :ushort}, {:name => :from, :type => :ushort}, {:name => :to, :type => :ushort})
  # 4 ST -> 1 ST
  opcode :ksvb,    0x55
  # 1 ST, 3 IM -> 1 ST   
  opcode(:kvsfxb,  0x56, {:name => :size, :type => :ushort}, {:name => :from, :type => :ushort}, {:name => :signature, :type => :ushort})
  # 4 ST -> 1 ST
  opcode :kvsvb,   0x57
    

  # 0 ST -> 0 ST; IP
  opcode :jmp,    0x27, {:name => :to, :type => :ushort, :reladdr => 2}
  # 1 ST -> 0 ST; IP
  opcode :jz,     0x21, {:name => :to, :type => :ushort, :reladdr => 2}
  opcode :je,     0x21, {:name => :to, :type => :ushort, :reladdr => 2}
  # 1 ST -> 0 ST; IP
  opcode :jnz,    0x26, {:name => :to, :type => :ushort, :reladdr => 2}
  opcode :jne,    0x26, {:name => :to, :type => :ushort, :reladdr => 2}
  # 1 ST -> 0 ST; IP
  opcode :ja,     0x22, {:name => :to, :type => :ushort, :reladdr => 2}
  opcode :jg,     0x22, {:name => :to, :type => :ushort, :reladdr => 2}
  # 1 ST -> 0 ST; IP
  opcode :jae,    0x23, {:name => :to, :type => :ushort, :reladdr => 2}
  opcode :jge,    0x23, {:name => :to, :type => :ushort, :reladdr => 2}
  # 1 ST -> 0 ST; IP
  opcode :jb,     0x24, {:name => :to, :type => :ushort, :reladdr => 2}
  opcode :jl,     0x24, {:name => :to, :type => :ushort, :reladdr => 2}
  # 1 ST -> 0 ST; IP
  opcode :jbe,    0x25, {:name => :to, :type => :ushort, :reladdr => 2}
  opcode :jle,    0x25, {:name => :to, :type => :ushort, :reladdr => 2}

  # 1 IM_B -> 1 ST
  opcode :ldbc,    0x30, {:name => :const, :type => :byte}
  # 1 IM -> 1 ST
  opcode :ldwc,    0x31, {:name => :const, :type => :short}
  # 1 ST -> 1 ST
  opcode :ldb ,    0x32, {:name => :from, :type => :ushort}
  # 1 ST -> 1 ST
  opcode :ldw ,    0x33, {:name => :from, :type => :ushort}
  # 1 ST -> 1 ST
  opcode :ldbv,    0x36
  # 1 ST -> 1 ST
  opcode :ldwv,    0x37

  # 1 ST -> 0 ST
  opcode :outnew,  0x42
  # 1 ST -> 0 ST
  opcode :outb,    0x44
  # 1 ST -> 0 ST
  opcode :outw,    0x45  

  # 1 ST -> 0 ST
  opcode :pop,     0x34
  # 2 ST -> 0 ST
  opcode :pop2,    0x35

  # 1 IM, x ST -> 2x ST  
  opcode :dupn,    0x3C, {:name => :n, :type => :ubyte}
  # 1 IM, x ST -> x ST
  opcode :flipn,   0x3D, {:name => :n, :type => :ubyte}

  # 2 IM -> 0 ST
  opcode(:outfxb,  0x40, {:name => :size, :type => :ushort}, {:name => :from, :type => :ushort})
  # 2 ST -> 0 ST
  opcode(:outvlb,  0x41, {:name => :from, :type => :ushort}) 

  
  # 1 IM, 1 ST -> 0 ST
  opcode :outvb,   0x43
  # 0 ST -> 0 ST;;
  opcode :halt,    0x46
  # 1 ST -> 0 ST
  opcode :psrm,    0x47
  
  # 1 ST -> 1 ST
  opcode :rdk,     0x5A
  # 1 ST -> 0 ST
  opcode :relk,    0x5C
  
  opcode :ldkl,    0x5D
  # 1 IM_B -> 2 ST
  opcode :genkp,   0x5E, {:name => :type, :type => :ubyte }
  # 1 ST, 1 IM -> 1 ST
  opcode :authk,   0x5F, {:name => :auth, :type => :ushort }
end
