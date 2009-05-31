require 'yaml'

module Tem::SeClosures
  module MixedMethods
    def assemble(&block)
      return Tem::Assembler.assemble(&block)
    end
  end
  
  include MixedMethods
  def self.included(klass)
    klass.extend MixedMethods
  end
  
  def sec_trace
    #begin      
      trace = @transport.applet_apdu! :ins => 0x54
      if trace.length > 2
        case read_tem_short(trace, 0) # trace version
        when 1
          return {:sp => read_tem_short(trace, 2), :ip => read_tem_short(trace, 4),
                  :out => read_tem_short(trace, 6), :pscell =>  read_tem_short(trace, 8)}
        end        
      end
      return nil # unreadable trace
    #rescue
    #  return nil
    #end
  end
  
  def solve_psfault
    # TODO: better strategy, lol
    next_cell = rand(16)
    @transport.applet_apdu! :ins => 0x53, :p12 => to_tem_ushort(next_cell)
  end
  
  def execute(secpack, key_id = 0)
    # load SECpack
    buffer_id = post_buffer(secpack.tem_formatted_body)
    response = @transport.applet_apdu! :ins => 0x50, :p1 => buffer_id,
                                                     :p2 => key_id
    tem_secpack_error(response) if read_tem_byte(response, 0) != 1
    
    # execute SEC
    sec_exception = nil
    loop do 
      response = @transport.applet_apdu! :ins => 0x52
      sec_status = read_tem_byte(response, 0)
      case sec_status
      when 2 # success
        break
      when 3 # exception
        # there is an exception, try to collect the trace
        b_stat = stat_buffers() rescue nil
        k_stat = stat_keys() rescue nil
        trace = sec_trace()
        sec_exception = Tem::SecExecError.new secpack, trace, b_stat, k_stat
        break
      when 4 # persistent store fault
        solve_psfault
      else
        raise "Unrecognized execution engine status #{sec_status}"
      end
    end
  
    # unbind SEC
    response = @transport.applet_apdu! :ins => 0x51
    raise sec_exception if sec_exception
    buffer_id = read_tem_byte(response, 0)
    buffer_length = read_tem_short(response, 1)
    data_buffer = read_buffer buffer_id
    release_buffer buffer_id
    
    return data_buffer[0...buffer_length]
  end
end
