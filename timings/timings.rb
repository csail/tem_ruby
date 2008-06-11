require 'tem_ruby'

require 'timings/blank_bound_secpack.rb'
require 'timings/blank_sec.rb'
require 'timings/devchip_decrypt.rb'
require 'timings/post_buffer.rb'
require 'timings/simple_apdu.rb'
require 'timings/vm_perf.rb'
require 'timings/vm_perf_bound.rb'

class TemTimings
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
    @tem.emit
  end
  
  def teardown
    @tem.kill
    @terminal.disconnect unless @terminal.nil?
  end
  
  def do_timing
    @tem.flush_buffers
    
    n = 10
    loop do
      timings = (0...3).map do |i|
        t_start = Time.now
        n.times do
          yield
        end
        t_delta = Time.now - t_start
      end
      avg_time = timings.inject { |a,v| a + v } / timings.length
      max_diff = timings.map { |t| (t - avg_time).abs }.max
      print "%8d: %3.8fs per run, %3.8fs uncertainty (%2.5f%%)\n" % [n, avg_time / n, max_diff / n, 100 * max_diff / avg_time]
      
      return avg_time unless max_diff / avg_time >= 0.01
      n *= 2
    end
  end
  
  def self.all_timings
    t = TemTimings.new
    t.setup
    t.methods.select { |m| m =~ /time_/ }.each do |m|
      print "Timing: #{m[5..-1]}...\n"
      t.send m.to_sym
    end
    t.teardown
  end
end

if __FILE__ == $0
  TemTimings.all_timings
end
