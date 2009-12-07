# Fixture ABI used for unit tests.
#
# Author:: Victor Costan
# Copyright:: Copyright (C) 2009 Massachusetts Institute of Technology
# License:: MIT

# :nodoc: namespace
module Fixtures
  class Wrapped
    attr_accessor :p, :q, :n
    attr_accessor :d  # Derived value.
    attr_accessor :c  # Constructor value.
    
    def initialize(ctor_value = 'ctor default')
      self.c = ctor_value
    end
  end
  
  class Multi
    attr_accessor :p, :q, :n
    attr_accessor :a, :b, :c
    attr_accessor :str, :const
  end
  
  module Abi
    Tem::Builders::Abi.define_abi self do |abi|
      abi.fixed_length_number :byte, 1, :signed => true
      abi.fixed_length_number :ubyte, 1, :signed => false

      abi.fixed_length_number :word, 2, :signed => true, :big_endian => false
      abi.fixed_length_number :netword, 2, :signed => true, :big_endian => true
                           
      abi.fixed_length_number :dword, 4, :signed => true, :big_endian => true
      abi.fixed_length_number :udword, 4, :signed => false, :big_endian => false
      
      abi.variable_length_number :vln, :word, :signed => false,
                                 :big_endian => false
      abi.variable_length_number :net_vln, :netword, :signed => false,
                                 :big_endian => true
      abi.packed_variable_length_numbers :packed, :word, [:p, :q, :n],
                                         :signed => false,
                                         :big_endian => false
      abi.packed_variable_length_numbers :net_packed, :netword,
                                         [:x, :y, :z, :a],
                                         :signed => false,
                                         :big_endian => true
      abi.fixed_length_string :mac_id, 6
      abi.object_wrapper :wrapped_raw, Wrapped, [:packed, nil]
      abi.object_wrapper :wrapped, Wrapped, [:packed, nil],
          :to => lambda { |o| w = Wrapped.new
                              w.p, w.q, w.n = o.p, o.q, o.n * 100
                              w },
          :read => lambda { |o| w = Wrapped.new(o.c); w.d = o.p * o.q; w },
          :new => lambda { |klass| klass.new('hook-new') }
      abi.object_wrapper :multi, Multi,
                         [:packed, nil,:packed, { :p => :a, :q => :b, :n => :c},
                          :mac_id, :str, 'constant string', :const]
    
      abi.conditional_wrapper :conditional, 2,
          [{:tag => [0x59, 0xAF], :class => String, :type => :mac_id},
           {:tag => [0x59, 0xAC], :class => Integer, :type => :net_vln,
            :predicate => lambda { |n| n % 2 == 1 } },
           {:tag => [0x59, 0xAD], :type => :dword,
            :predicate => lambda { |n| n % 3 == 1 } }]
    end
  end
end  # namespace Fixtures
