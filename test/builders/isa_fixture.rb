# Fixture ISA used for unit tests.
#
# Author:: Victor Costan
# Copyright:: Copyright (C) 2009 Massachusetts Institute of Technology
# License:: MIT

require 'test/builders/abi_fixture.rb'

# :nodoc: namespace
module Fixtures
  
module Isa
  Tem::Builders::Isa.define_isa self, Fixtures::Abi,
                                :opcode_type => :ubyte do |isa|    
    # No argument.
    isa.instruction 0x10, :add
    
    # Single argument.
    isa.instruction 0x3C, :dupn, {:name => :n, :type => :ubyte}
                                 
    # Multiple arguments.
    isa.instruction 0x1C, :mc, {:name => :size, :type => :word},
                               {:name => :from, :type => :word},
                               {:name => :to, :type => :word}

    # Relative address argument.
    isa.instruction 0x27, :jmp, {:name => :to, :type => :word,
                                 :reladdr => 2}
  end
end

end  # namespace Fixtures
