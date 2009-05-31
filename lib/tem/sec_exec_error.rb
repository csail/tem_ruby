# raised when executing a SEC 
class Tem::SecExecError < StandardError
  attr_reader :line_info
  attr_reader :buffer_state, :key_state
  attr_reader :trace
  
  def initialize(line_info, tem_trace, buffer_state, key_state)
    super 'SEC execution failed on the TEM'
    @line_info = line_info
    line_ip, atom, backtrace = *line_info
    @atom = atom
    if tem_trace and tem_trace[:ip]
      @ip_delta = tem_trace[:ip] - line_ip
    else
      @ip_delta = 0
    end
    @trace = tem_trace
    @buffer_state = buffer_state
    @key_state = key_state
    set_backtrace backtrace
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
    string = <<ENDSTRING
SECpack execution generated an exception on the TEM

TEM Trace: #{trace_str}
TEM Buffer Status:#{bstat_str}
TEM Key Status:#{kstat_str}

TEM execution error at #{@atom}+#{@ip_delta}
ENDSTRING
    string.strip
  end
  
  def inspect
    trace_str + "\n" + bstat_str + "\n" + kstat_str
  end
end
