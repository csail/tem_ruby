# :nodoc: namespace
module Tem::Builders  

# Builder class and namespace for the ABI builder.
class Abi
  
  # Creates a builder targeting a module / class.
  #
  # The given parameter should be a class or module
  def self.define_abi(class_or_module) # :yields: abi
    yield new(class_or_module)
  end
  
  # Defines the methods for handling a value type in an ABI.
  # 
  # The |options| hash supports the following keys:
  #   signed:: if false, the value type cannot hold negative numbers;
  #            signed values are stored using 2s-complement; defaults to true
  #   big_endian:: if true, bytes are sent over the wire in big-endian order
  #
  # The following methods are defined for a value type named 'name':
  #   * read_name(array) -> number
  #   * to_name(number) -> array
  #   * signed_to_name(number) -> array  # takes signed inputs on unsigned types
  def fixed_width_type(name, bytes, options = {})
    signed = options.fetch :signed, true
    big_endian = options.fetch :big_endian, true
    
    range = 1 << (8 * bytes)
    if signed
      min, max = -(range >> 1), (range >> 1) - 1
    else
      min, max = 0, range - 1
    end
    
    defines = Proc.new do 
      define_method :"read_#{name}" do |array, offset|
        array = array.reverse unless big_endian
        n = (0...bytes).inject(0) { |v, i| (v << 8) | array[offset + i] }
        rv = (options[:signed] and n > max) ? n - range : n
        return rv
      end
      define_method :"to_#{name}" do |n|
        n = n.to_i
        if n < min or n > max 
          raise "Value #{n} of type #{name} out of range #{min}-#{max}"
        end
        n += range if signed and n < 0      
        array = []
        bytes.times { array.push(n & 0xFF); n >>= 8 }
        array.reverse! if big_endian
        return array
      end
      define_method :"signed_to_#{name}" do |n|
        n = n.to_i
        n += range if (n < 0 and !signed)
        array = []
        bytes.times { array.push(n & 0xFF); n >>= 8 }
        array.reverse! if big_endian
        return array
      end
      define_method(:"#{name}_length") { bytes }
    end
    
    @target.class_eval &defines
    (class << @target; self; end).module_eval &defines
  end
    
  # The module / class impacted by the builder.
  attr_reader :target

  # Creates a builder targeting a module / class. 
  def initialize(target)
    @target = target
  end
  private_class_method :new  
end  # class Abi

end  # namespace Tem::Builders
