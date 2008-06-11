# raised when executing a SEC 
class Tem::SecExecError < StandardError
  attr_reader :buffer_state, :key_state
  attr_reader :trace
  
  def initialize(backtrace, tem_trace, buffer_state, key_state)
    super 'SEC execution failed on the TEM'
    set_backtrace backtrace
    @trace = tem_trace
    @buffer_state = buffer_state
    @key_state = key_state
  end
  
  def bstat_str
    if @buffer_state.nil?
      "no buffer state available"
    else
      @buffer_state.inspect
    end
  end

  def kstat_str
    if @key_state.nil?
      "no key state available"
    else
      @key_state.inspect
    end
  end
  
  def trace_str
    if @trace.nil?
      "no trace available"
    else
      "ip=#{'%04x' % @trace[:ip]} sp=#{'%04x' % @trace[:sp]} out=#{'%04x' % @trace[:out]} pscell=#{'%04x' % @trace[:pscell]}"
    end
  end
  
  def to_s
    "SECpack execution generated an exception on the TEM\nTEM Trace: " + trace_str + "\nTEM Buffer Status:\n" + bstat_str + "\nTEM Key Status:\n" + kstat_str
  end
  
  def inspect
    trace_str + "\n" + bstat_str + "\n" + kstat_str
  end
end
