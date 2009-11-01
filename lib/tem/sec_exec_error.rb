# Raised when executing a SEC. 
class Tem::SecExecError < StandardError
  attr_reader :line_info
  attr_reader :buffer_state, :key_state
  attr_reader :trace
  
  def initialize(secpack, tem_trace, buffer_state, key_state)
    super 'SEC execution failed on the TEM'
    
    if tem_trace
      if tem_trace[:ip]
        @ip_line_info = secpack.line_info_for_addr tem_trace[:ip]
        @ip_label_info = secpack.label_info_for_addr tem_trace[:ip]
      end
      if tem_trace[:sp]
        @sp_line_info = secpack.line_info_for_addr tem_trace[:sp]
      end
    end
    @ip_line_info ||= [0, :unknown, []]
    @ip_label_info ||= [0, :unknown]
    @sp_line_info ||= [0, :unknown, []]
    
    line_ip, atom, backtrace = *@ip_line_info
    set_backtrace backtrace
    @ip_atom = atom
    @ip_label = @ip_label_info[1]
    if tem_trace and tem_trace[:ip]
      @ip_delta = tem_trace[:ip] - line_ip
      @ip_label_delta = tem_trace[:ip] - @ip_label_info[0]
    else
      @ip_delta = @ip_label_delta = 0
    end
    line_sp, atom, backtrace = *@sp_line_info
    @sp_atom = atom
    if tem_trace and tem_trace[:sp]
      @sp_delta = tem_trace[:sp] - line_sp
    else
      @sp_delta = 0
    end
    
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
      "ip=#{'%04x' % @trace[:ip]} (#{@ip_atom}+0x#{'%x' % @ip_delta}) " +
      "sp=#{'%04x' % @trace[:sp]} (#{@sp_atom}+0x#{'%x' % @sp_delta}) " +
      "out=#{'%04x' % @trace[:out]} " +
      "pscell=#{'%04x' % @trace[:pscell]}"
    end
  end
  
  def to_s
    string = <<ENDSTRING
SECpack execution generated an exception on the TEM

TEM Trace: #{trace_str}
TEM Buffer Status:#{bstat_str}
TEM Key Status:#{kstat_str}

TEM execution error at #{@ip_label}+0x#{'%x' % @ip_label_delta}:
ENDSTRING
    string.strip
  end
  
  def inspect
    trace_str + "\n" + bstat_str + "\n" + kstat_str
  end
end
