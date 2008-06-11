require 'tem_ruby'
require 'test/unit'

class ExceptionsTest < Test::Unit::TestCase
  def setup
    @terminal = Tem::SCard::JCOPRemoteTerminal.new
    unless @terminal.connect
      @terminal.disconnect
      @terminal = Tem::SCard::PCSCTerminal.new
      @terminal.connect
    end
    @javacard = Tem::SCard::JavaCard.new(@terminal)
    @tem = Tem::Session.new(@javacard)
    
    @tem.kill
    @tem.activate
  end
  
  def teardown
    @terminal.disconnect unless @terminal.nil?
  end
  
  def test_trace
    # test the exception handling mechanism
    bad_sec = @tem.assemble { |s|
      s.ldbc 2
      s.outnew
      s.ldbc 6
      s.outw
      # this exceeds the address space, so it should make the TEM die
      s.ldwc 0x7fff
      s.ldbv 
      s.label :bad_code 
      s.halt
      s.label :stack
      s.stack
      s.extra 10
    }
    assert_raise(Tem::SecExecError) { @tem.execute bad_sec }

    caught = false
    begin
      @tem.execute bad_sec
    rescue Tem::SecExecError => e
      caught = true
      assert_equal Hash, e.trace.class, "TEM exception does not have a TEM trace"
      assert_equal 2, e.trace[:out], "Bad output buffer position in TEM trace"
      assert_equal bad_sec.label_address(:bad_code), e.trace[:ip], "Bad instruction pointer in TEM trace"
      assert_equal bad_sec.label_address(:stack), e.trace[:sp], "Bad instruction pointer in TEM trace"
      assert_equal Hash, e.buffer_state.class, "TEM exception does not have buffer state information"
      assert_equal Hash, e.key_state.class, "TEM exception does not have key state information"
    end
    assert caught, "Executing a bad SECpack did not raise a SecExecError"
  end  
end