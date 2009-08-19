# The TEM's ISA (Instruction Set Architecture) definition.
#
# This code is the official specification, because Victor likes executable
# specifications.
#
# Author:: Victor Costan
# Copyright:: Copyright (C) 2007 Massachusetts Institute of Technology
# License:: MIT


module Tem::Isa
  Tem::Builders::Isa.define_isa self, Tem::Abi,
                                :opcode_type => :tem_ubyte do |isa|
    # 2 ST -> 1 ST
    isa.instruction 0x10, :add
    # 2 ST -> 1 ST
    isa.instruction 0x11, :sub
    isa.instruction 0x11, :cmp
    # 2 ST -> 1 ST
    isa.instruction 0x12, :mul
    # 2 ST -> 1 ST
    isa.instruction 0x13, :div
    # 2 ST -> 1 ST
    isa.instruction 0x14, :mod
    # 2 ST -> 1 ST 
    isa.instruction 0x1E, :rnd
    
  
    # 2 ST -> 1 ST
    isa.instruction 0x3A, :stbv
    # 2 ST -> 1 ST
    isa.instruction 0x3B, :stwv
  
    # 2 ST -> 1 ST
    isa.instruction 0x5B, :stk
    
  
    # 1 ST, 1 IM -> 1 ST
    isa.instruction 0x38, :stb, {:name => :to, :type => :tem_ushort}
    # 1 ST, 1 IM -> 1 ST
    isa.instruction 0x39, :stw, {:name => :to, :type => :tem_ushort}
    
  
    # 2 IM -> 1 ST
    isa.instruction 0x48, :psupfxb, {:name => :addr, :type => :tem_ushort},
                                    {:name => :from, :type => :tem_ushort}
    # 2 ST -> 1 ST
    isa.instruction 0x49, :psupvb
    # 2 IM -> 1 ST
    isa.instruction 0x4A, :pswrfxb, {:name => :addr, :type => :tem_ushort},
                                    {:name => :from, :type => :tem_ushort}
    # 2 ST -> 1 ST
    isa.instruction 0x4B, :pswrvb
    # 2 IM -> 1 ST
    isa.instruction 0x4C, :psrdfxb, {:name => :addr, :type => :tem_ushort},
                                    {:name => :to, :type => :tem_ushort}
    # 2 ST -> 1 ST
    isa.instruction 0x4D, :psrdvb
    # 2 IM -> 1 ST
    isa.instruction 0x4E, :pshkfxb, {:name => :addr, :type => :tem_ushort}
    # 2 ST -> 1 ST
    isa.instruction 0x4F, :pshkvb
    
    
    # 3 IM -> 1 ST
    isa.instruction 0x18, :mdfxb, {:name => :size, :type => :tem_ushort},
                                  {:name => :from, :type => :tem_ushort},
                                  {:name => :to, :type => :tem_ushort}
    # 3 ST -> 1 ST
    isa.instruction 0x19, :mdvb
    # 3 IM -> 1 ST
    isa.instruction 0x1A, :mcmpfxb, {:name => :size, :type => :tem_ushort},
                                    {:name => :op1, :type => :tem_ushort},
                                    {:name => :op2, :type => :tem_ushort}
    # 3 ST -> 1 ST  
    isa.instruction 0x1B, :mcmpvb
    # 3 IM -> 1 ST
    isa.instruction 0x1C, :mcfxb, {:name => :size, :type => :tem_ushort},
                                  {:name => :from, :type => :tem_ushort},
                                  {:name => :to, :type => :tem_ushort}
    # 3 ST -> 1 ST
    isa.instruction 0x1D, :mcvb
    
    # 1 ST, 3 IM -> 1 ST   
    isa.instruction 0x50, :kefxb, {:name => :size, :type => :tem_ushort},
                                  {:name => :from, :type => :tem_ushort},
                                  {:name => :to, :type => :tem_ushort}
    # 4 ST -> 1 ST
    isa.instruction 0x51, :kevb
    # 1 ST, 3 IM -> 1 ST   
    isa.instruction 0x52, :kdfxb, {:name => :size, :type => :tem_ushort},
                                  {:name => :from, :type => :tem_ushort},
                                  {:name => :to, :type => :tem_ushort}
    # 4 ST -> 1 ST
    isa.instruction 0x53, :kdvb
    # 1 ST, 3 IM -> 1 ST   
    isa.instruction 0x54, :ksfxb, {:name => :size, :type => :tem_ushort},
                                  {:name => :from, :type => :tem_ushort},
                                  {:name => :to, :type => :tem_ushort}
    # 4 ST -> 1 ST
    isa.instruction 0x55, :ksvb   
    # 1 ST, 3 IM -> 1 ST   
    isa.instruction 0x56, :kvsfxb, {:name => :size, :type => :tem_ushort},
                                   {:name => :from, :type => :tem_ushort},
                                   {:name => :signature, :type => :tem_ushort}
    # 4 ST -> 1 ST
    isa.instruction 0x57, :kvsvb
      
  
    # 0 ST -> 0 ST; IP
    isa.instruction 0x27, :jmp, {:name => :to, :type => :tem_ushort,
                                 :reladdr => 2}
    # 1 ST -> 0 ST; IP
    isa.instruction 0x21, :jz, {:name => :to, :type => :tem_ushort,
                                :reladdr => 2}
    isa.instruction 0x21, :je, {:name => :to, :type => :tem_ushort,
                                :reladdr => 2}
    # 1 ST -> 0 ST; IP
    isa.instruction 0x26, :jnz, {:name => :to, :type => :tem_ushort,
                                 :reladdr => 2}
    isa.instruction 0x26, :jne, {:name => :to, :type => :tem_ushort,
                                 :reladdr => 2}
    # 1 ST -> 0 ST; IP
    isa.instruction 0x22, :ja, {:name => :to, :type => :tem_ushort,
                                :reladdr => 2}
    isa.instruction 0x22, :jg, {:name => :to, :type => :tem_ushort,
                                :reladdr => 2}
    # 1 ST -> 0 ST; IP
    isa.instruction 0x23, :jae, {:name => :to, :type => :tem_ushort,
                                 :reladdr => 2}
    isa.instruction 0x23, :jge, {:name => :to, :type => :tem_ushort,
                                 :reladdr => 2}
    # 1 ST -> 0 ST; IP
    isa.instruction 0x24, :jb, {:name => :to, :type => :tem_ushort,
                                :reladdr => 2}
    isa.instruction 0x24, :jl, {:name => :to, :type => :tem_ushort,
                                :reladdr => 2}
    # 1 ST -> 0 ST; IP
    isa.instruction 0x25, :jbe, {:name => :to, :type => :tem_ushort,
                                 :reladdr => 2}
    isa.instruction 0x25, :jle, {:name => :to, :type => :tem_ushort,
                                 :reladdr => 2}
                                 
    # 0 ST -> 1 ST; IP
    isa.instruction 0x3E, :call, {:name => :proc, :type => :tem_ushort,
                                  :reladdr => 2}
    # 1 ST -> 0 ST; IP (without IM)
    isa.instruction 0x3F, :ret
  
    # 1 IM_B -> 1 ST
    isa.instruction 0x30, :ldbc, {:name => :const, :type => :tem_byte}
    # 1 IM -> 1 ST
    isa.instruction 0x31, :ldwc, {:name => :const, :type => :tem_short}
    # 0 ST -> 1 ST
    isa.instruction 0x32, :ldb, {:name => :from, :type => :tem_ushort}
    # 0 ST -> 1 ST
    isa.instruction 0x33, :ldw, {:name => :from, :type => :tem_ushort}
    # 1 ST -> 1 ST
    isa.instruction 0x36, :ldbv
    # 1 ST -> 1 ST
    isa.instruction 0x37, :ldwv
  
    # 1 ST -> 0 ST
    isa.instruction 0x42, :outnew
    # 1 ST -> 0 ST
    isa.instruction 0x44, :outb
    # 1 ST -> 0 ST
    isa.instruction 0x45, :outw
  
    # 1 ST -> 0 ST
    isa.instruction 0x34, :pop
    # 2 ST -> 0 ST
    isa.instruction 0x35, :pop2
  
    # 1 IM, x ST -> 2x ST  
    isa.instruction 0x3C, :dupn, {:name => :n, :type => :tem_ubyte}
    # 1 IM, x ST -> x ST
    isa.instruction 0x3D, :flipn, {:name => :n, :type => :tem_ubyte}
  
    # 2 IM -> 0 ST
    isa.instruction 0x40, :outfxb, {:name => :size, :type => :tem_ushort},
                                   {:name => :from, :type => :tem_ushort}
    # 2 ST -> 0 ST
    isa.instruction 0x41, :outvlb, {:name => :from, :type => :tem_ushort} 
  
    
    # 1 IM, 1 ST -> 0 ST
    isa.instruction 0x43, :outvb
    # 0 ST -> 0 ST;;
    isa.instruction 0x46, :halt
    # 1 ST -> 0 ST
    isa.instruction 0x47, :psrm
    
    # 1 ST -> 1 ST
    isa.instruction 0x5A, :rdk     
    # 1 ST -> 0 ST
    isa.instruction 0x5C, :relk
    
    isa.instruction 0x5D, :ldkl
    # 1 IM_B -> 2 ST
    isa.instruction 0x5E, :genkp, {:name => :type, :type => :tem_ubyte }
    # 1 ST, 1 IM -> 1 ST
    isa.instruction 0x5F, :authk, {:name => :auth, :type => :tem_ushort }
  end  
end
