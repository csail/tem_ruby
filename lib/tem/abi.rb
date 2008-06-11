module Tem::Abi
  def self.included(klass)
    klass.extend MixedMethods
    
    klass.tem_value_type :byte, 1, :signed => true, :endian => :big
    klass.tem_value_type :ubyte, 1, :signed => false, :endian => :big
    klass.tem_value_type :short, 2, :signed => true, :endian => :big
    klass.tem_value_type :ushort, 2, :signed => false, :endian => :big    
    klass.tem_value_type :ps_key, 20, :signed => false, :endian => :big
    klass.tem_value_type :ps_value, 20, :signed => false, :endian => :big
  end
  
  module MixedMethods
    def tem_value_type(name, bytes, options = {:signed => true, :endian => :big})
      range = 1 << (8 * bytes)
      if options[:signed]
        min, max = -(range >> 1), (range >> 1) - 1
      else
        min, max = 0, range - 1
      end
      
      badass_defines = Proc.new do 
        define_method("read_tem_#{name}".to_sym) do |array, offset|
          array = array.reverse unless options[:endian] == :big
          n = (0...bytes).inject(0) { |v, i| (v << 8) | array[offset + i] }
          rv = (options[:signed] and n > max) ? n - range : n
          # pp [:read, name, array, offset, rv]
          return rv
        end
        define_method("to_tem_#{name}".to_sym) do |n|
          n = n.to_i
          raise "Value #{n} not between #{min} and #{max}" unless (n <= max) and (n >= min)
          n += range if(options[:signed] and n < 0)      
          array = []
          bytes.times { array.push(n & 0xFF); n >>= 8 }
          array.reverse! if options[:endian] == :big
          # pp [:to, name, n, array]
          return array
        end
        define_method("to_tem_#{name}_reladdr".to_sym) do |n|
          n = n.to_i
          n += range if (n < 0 and (not options[:signed]))
          array = []
          bytes.times { array.push(n & 0xFF); n >>= 8 }
          array.reverse! if options[:endian] == :big
          return array
        end
        define_method("tem_#{name}_length".to_sym) { bytes }
      end
      
      self.class_eval(&badass_defines)      
      (class << self; self; end).module_eval(&badass_defines)
    end
  end
end
