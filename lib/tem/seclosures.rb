require 'yaml'

module Tem::SeClosures
  module MixedMethods
    def assemble(&sec_block)
      return Tem::SecAssembler.new(self).assemble(&sec_block)
    end
  end
  
  include MixedMethods
  def self.included(klass)
    klass.extend MixedMethods
  end
  
  def sec_trace
    #begin      
      response = issue_apdu [0x00, 0x54, 0x00, 0x00, 0x00].flatten
      trace = reply_data(response)
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
    response = issue_apdu [0x00, 0x53, to_tem_ushort(next_cell), 0x00].flatten
    tem_error(response) if failure_code(response)    
  end
  
  def execute(secpack, key_id = 0)
    # load SECpack
    buffer_id = post_buffer(secpack.tem_formatted_body)
    response = issue_apdu [0x00, 0x50, to_tem_byte(buffer_id), to_tem_byte(key_id), 0x00].flatten
    release_buffer(buffer_id)
    tem_error(response) if failure_code(response)
    tem_secpack_error(response) if read_tem_byte(response, 0) != 1
    
    # execute SEC
    sec_exception = nil
    loop do 
      response = issue_apdu [0x00, 0x52, 0x00, 0x00, 0x00].flatten
      tem_error(response) if failure_code(response)
      sec_status = read_tem_byte(response, 0)
      case sec_status
      when 2 # success
        break
      when 3 # exception
        # there is an exception, try to collect the trace
        b_stat = stat_buffers() rescue nil
        k_stat = stat_keys() rescue nil
        trace = sec_trace()        
        backtrace = (trace && trace[:ip]) ? secpack.stack_for_ip(trace[:ip]) : Kernel.caller
        sec_exception = Tem::SecExecError.new backtrace, trace, b_stat, k_stat
        break
      when 4 # persistent store fault
        solve_psfault
      else
        raise "Unrecognized execution engine status #{sec_status}"
      end
    end
  
    # TODO: handle response to figure out if we need to do page faults or something
    
    # unbind SEC
    response = issue_apdu [0x00, 0x51, 0x00, 0x00, 0x00].flatten
    raise sec_exception if sec_exception
    buffer_id, buffer_length = read_tem_byte(response, 0), read_tem_short(response, 1)
    data_buffer = read_buffer buffer_id
    release_buffer buffer_id
    
    return data_buffer[0...buffer_length]
  end
end