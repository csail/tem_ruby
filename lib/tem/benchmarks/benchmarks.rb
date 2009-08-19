# Master file for running the TEM benchmarks. 
#
# Author:: Victor Costan
# Copyright:: Copyright (C) 2008 Massachusetts Institute of Technology
# License:: MIT

require 'tem_ruby'

require 'tem/benchmarks/blank_bound_secpack.rb'
require 'tem/benchmarks/blank_sec.rb'
require 'tem/benchmarks/devchip_decrypt.rb'
require 'tem/benchmarks/post_buffer.rb'
require 'tem/benchmarks/simple_apdu.rb'
require 'tem/benchmarks/vm_perf.rb'
require 'tem/benchmarks/vm_perf_bound.rb'


class Tem::Benchmarks
  def setup
    @tem = Tem.auto_tem
    
    @tem.kill
    @tem.activate
    @tem.emit
  end
  
  def teardown
    @tem.kill
    @tem.disconnect if @tem
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
      uncertainty = 100 * max_diff / avg_time
      print "%8d: %3.8fs per run, %3.8fs uncertainty (%2.5f%%)\n" %
          [n, avg_time / n, max_diff / n, 100 * uncertainty]
      
      return avg_time / n unless max_diff / avg_time >= 0.01
      n *= 2
    end
  end
  
  def self.all_benchmarks
    benchmarks = {}
    t = Tem::Benchmarks.new
    t.setup
    t.methods.select { |m| m =~ /time_/ }.each do |m|
      print "Timing: #{m[5..-1]}...\n"
      benchmarks[m] = t.send m.to_sym
    end
    t.teardown
    benchmarks
  end
  
  def self.display_all_benchmarks
    benchmarks = Tem::Benchmarks.all_benchmarks
    benchmarks.map { |k, v| [k.to_s, v] }.sort.each do |benchmark|
      print "#{benchmark.first}: #{'%.5f' % benchmark.last}s\n"
    end    
  end
end
