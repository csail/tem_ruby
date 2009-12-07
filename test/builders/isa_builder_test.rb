# Author:: Victor Costan
# Copyright:: Copyright (C) 2009 Massachusetts Institute of Technology
# License:: MIT

require 'tem_ruby'
require 'test/builders/isa_fixture.rb'
require 'test/unit'
require 'openssl'


class IsaBuilderTest < Test::Unit::TestCase
  include Fixtures
  
  
  
  def setup
    @golden_add = {:emit => [0x10], :link_directives => []}
    @golden_dup = {:emit => [0x3C, 0x02], :link_directives => []}
    @golden_dup_label = {:emit => [0x3C, 0x00],
        :link_directives => [{:type => :ubyte, :offset => 1, :relative => false,
                              :label => :dupn_lbl}]}
    @golden_jmp = {:emit => [0x27, 0x00, 0x00],
        :link_directives => [{:type => :word, :offset => 1, :relative => 2,
                              :address => 8}]}
    @golden_jmp_label = {:emit => [0x27, 0x00, 0x00],
        :link_directives => [{:type => :word, :offset => 1, :relative => 2,
                              :label => :jmp_lbl}]}
    @golden_mc = {:emit => [0x1C, 0x06, 0x00, 0x0A, 0x00, 0x14, 0x00],
                  :link_directives => []}
    @golden_mc_labels = {:emit => [0x1C, 0x00, 0x00, 0x0A, 0x00, 0x00, 0x00],
        :link_directives => [{:type => :word, :offset => 1, :relative => false,
                              :label => :size_lbl},
                             {:type => :word, :offset => 5, :relative => false,
                              :label => :to_lbl}]}
  end

  def test_no_args
    assert_equal @golden_add, Isa.emit_add
  end
  
  def test_positional_arg
    assert_equal @golden_dup, Isa.emit_dupn(2)
  end

  def test_named_arg
    assert_equal @golden_dup, Isa.emit_dupn(:n => 2)
  end

  def test_positional_arg_label
    assert_equal @golden_dup_label, Isa.emit_dupn(:dupn_lbl)
  end
  
  def test_named_arg_label
    assert_equal @golden_dup_label, Isa.emit_dupn(:n => :dupn_lbl)
  end
  
  def test_reladdr_positional_arg
    assert_equal @golden_jmp, Isa.emit_jmp(8)
  end
  
  def test_reladdr_named_arg
    assert_equal @golden_jmp, Isa.emit_jmp(:to => 8)
  end

  def test_reladdr_positional_arg_label
    assert_equal @golden_jmp_label, Isa.emit_jmp(:jmp_lbl)
  end
  
  def test_reladdr_named_arg_label
    assert_equal @golden_jmp_label, Isa.emit_jmp(:to => :jmp_lbl)
  end
  
  def test_positional_args
    assert_equal @golden_mc, Isa.emit_mc(6, 10, 20)
  end

  def test_named_args
    assert_equal @golden_mc, Isa.emit_mc(:size => 6, :to => 20, :from => 10)
  end

  def test_mixed_args
    assert_equal @golden_mc, Isa.emit_mc(6, :to => 20, :from => 10),
                 '1 positional, 2 named'
    assert_equal @golden_mc, Isa.emit_mc(6, 10, :to => 20),
                 '1 named, 2 positional'
  end
  
  def test_mixed_args_labels
    assert_equal @golden_mc_labels, Isa.emit_mc(:size_lbl, 10, :to => :to_lbl)    
  end
end
