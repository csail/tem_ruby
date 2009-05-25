require 'openssl'


# :nodoc: namespace
module Tem::Builders  

# Builder class and namespace for the ABI builder.
class Abi
  # Creates a builder targeting a module / class.
  #
  # The given parameter should be a class or module
  def self.define_abi(class_or_module)  # :yields: abi
    yield new(class_or_module)
  end
  
  # Defines the methods for handling a fixed-length number type in an ABI.
  # 
  # The |options| hash supports the following keys:
  #   signed:: if false, the value type cannot hold negative numbers;
  #            signed values are stored using 2s-complement; defaults to true
  #   big_endian:: if true, bytes are sent over the wire in big-endian order
  #
  # The following methods are defined for a type named 'name':
  #   * read_name(array, offset) -> number
  #   * to_name(number) -> array
  #   * signed_to_name(number) -> array  # takes signed inputs on unsigned types
  #   * name_length -> number  # the number of bytes in the number type
  def fixed_length_number(name, bytes, options = {})
    impl = Tem::Builders::Abi::Impl
    signed = options.fetch :signed, true
    big_endian = options.fetch :big_endian, true    
    
    defines = Proc.new do 
      define_method :"read_#{name}" do |array, offset|
        impl.number_from_array array, offset, bytes, signed, big_endian
      end
      define_method :"to_#{name}" do |n|
        impl.check_number_range n, bytes, signed
        impl.number_to_array n, bytes, signed, big_endian
      end
      define_method :"signed_to_#{name}" do |n|
        impl.number_to_array n, bytes, signed, big_endian
      end
      define_method(:"#{name}_length") { bytes }
    end
    
    @target.class_eval &defines
    (class << @target; self; end).module_eval &defines
  end
  
  # Defines the methods for handling a variable-length number type in an ABI.
  # 
  # The length_type argument holds the name of a fixed-length number type that
  # will be used to store the length of hte variable-length number.
  #
  # The |options| hash supports the following keys:
  #   signed:: if false, the value type cannot hold negative numbers;
  #            signed values are stored using 2s-complement; defaults to true
  #   big_endian:: if true, bytes are sent over the wire in big-endian order
  #
  # The following methods are defined for a type named 'name':
  #   * read_name(array, offset) -> number
  #   * read_name_length(array, offset) -> number
  #   * to_name(number) -> array
  def variable_length_number(name, length_type, options = {})
    impl = Tem::Builders::Abi::Impl
    signed = options.fetch :signed, true
    big_endian = options.fetch :big_endian, true
    length_bytes = @target.send :"#{length_type}_length"
    read_length_msg = :"read_#{length_type}"
    write_length_msg = :"to_#{length_type}"
    
    defines = Proc.new do 
      define_method :"read_#{name}" do |array, offset|
        length = self.send read_length_msg, array, offset
        impl.number_from_array array, offset + length_bytes, length, signed,
                               big_endian
      end
      define_method :"to_#{name}" do |n|
        number_data = impl.number_to_array n, nil, signed, big_endian
        length_data = self.send write_length_msg, number_data.length
        length_data + number_data
      end
      define_method :"read_#{name}_length" do |array, offset|
        length_bytes + self.send(read_length_msg, array, offset)
      end
    end
    
    @target.class_eval &defines
    (class << @target; self; end).module_eval &defines    
  end
  
  # Defines the methods for handling a group of packed variable-length numbers
  # in the ABI.
  #
  # When serializing a group of variable-length numbers, it's desirable to have
  # the lengths of all the numbers grouped before the number data. This makes
  # reading and writing easier & faster for embedded code. The optimization is
  # important enough that it's made its way into the API.
  #
  # All the numbers' lengths are assumed to be represented by the same
  # fixed-length type, whose name is given as the length_type parameter.
  # 
  # The numbers are de-serialized into a hash, where each number is associated
  # with a key. The components argument specifies the names of the keys, in the
  # order that the numbers are serialized in.
  # 
  # The |options| hash supports the following keys:
  #   signed:: if false, the value type cannot hold negative numbers;
  #            signed values are stored using 2s-complement; defaults to true
  #   big_endian:: if true, bytes are sent over the wire in big-endian order
  #
  # The following methods are defined for a type named 'name':
  #   * read_name(array, offset) -> hash
  #   * read_name_length(array, offset) -> number
  #   * to_name(hash) -> array
  #   * name_components -> array
  def packed_variable_length_numbers(name, length_type, components,
                                     options = {})
    impl = Tem::Builders::Abi::Impl
    sub_names = components.freeze
    signed = options.fetch :signed, true
    big_endian = options.fetch :big_endian, true
    length_bytes = @target.send :"#{length_type}_length"
    read_length_msg = :"read_#{length_type}"
    write_length_msg = :"to_#{length_type}"
    
    defines = Proc.new do 
      define_method :"read_#{name}" do |array, offset|
        response = {}
        data_offset = offset + length_bytes * sub_names.length
        sub_names.each_with_index do |sub_name, i|
          length = self.send read_length_msg, array, offset + i * length_bytes
          response[sub_name] =
              impl.number_from_array array, data_offset, length, signed,
                                     big_endian
          data_offset += length
        end
        response
      end
      define_method :"to_#{name}" do |numbers|
        number_data = sub_names.map do |sub_name|
          impl.number_to_array numbers[sub_name], nil, signed, big_endian
        end
        length_data = number_data.map do |number|
          self.send write_length_msg, number.length
        end
        # Concatenate all the arrays without using flatten.
        lengths = length_data.inject([]) { |acc, i| acc += i }
        number_data.inject(lengths) { |acc, i| acc += i }
      end
      define_method :"read_#{name}_length" do |array, offset|
        response = sub_names.length * length_bytes
        0.upto(sub_names.length - 1) do |i|
          response += self.send read_length_msg, array,
                                offset + i * length_bytes
        end
        response
      end
      define_method(:"#{name}_components") { sub_names }
    end
    
    @target.class_eval &defines
    (class << @target; self; end).module_eval &defines    
  end
  
  # Defines the methods for handling a fixed-length string type in an ABI.
  # 
  # The |options| hash supports the following keys:
  #   signed:: if false, the value type cannot hold negative numbers;
  #            signed values are stored using 2s-complement; defaults to true
  #   big_endian:: if true, bytes are sent over the wire in big-endian order
  #
  # The following methods are defined for a type named 'name':
  #   * read_name(array, offset) -> string
  #   * to_name(string or array) -> array
  #   * name_length -> number  # the number of bytes in the string type
  def fixed_length_string(name, bytes, options = {})
    impl = Tem::Builders::Abi::Impl
    signed = options.fetch :signed, true
    big_endian = options.fetch :big_endian, true    
    
    defines = Proc.new do 
      define_method :"read_#{name}" do |array, offset|      
        impl.string_from_array array, offset, bytes
      end
      define_method :"to_#{name}" do |n|
        impl.string_to_array n, bytes
      end
      define_method(:"#{name}_length") { bytes }
    end
    
    @target.class_eval &defines
    (class << @target; self; end).module_eval &defines
  end
  
  # Defines methods for handling a complex ABI structure wrapped into an object.
  #
  # Objects are assumed to be of the object_class type. The objects are
  # serialized according to a schema, which is an array of 2-element directives.
  # The first element in a directive indicates the lower-level ABI type to be
  # serialized, and the 2nd element indicates the mapping between the object and
  # the higher level ABI. The mapping can be:
  #   * a symbol - the lower level ABI output is assigned to an object property
  #   * a hash - the keys in the lower level ABI output are assigned to the
  #              object properties indicated by the values
  #   * nil - the components of the lower level ABI type (which should act like
  #           packed_variable_length_numbers types) are mapped to identically
  #           named object properties
  #  
  # The following methods are defined for a type named 'name':
  #   * read_name(array, offset) -> object
  #   * read_name_length(array, offset) -> number
  #   * to_name(object) -> array
  #   * name_class -> Class
  #
  # The following hooks (Procs in the hooks argument) are supported:
  #   new(object_class) -> object:: called to instantiate a new object in read_;
  #       if the hook is not present, object_class.new is used instead
  #   read(object) -> object:: called after the object is de-serialized using
  #       the lower-level ABI; if the hook is present, its value is returned
  #       from the read_ method
  #   to(object) -> object:: called before the object is serialized using the
  #       lower-level ABI; if the hook is present, its value is used for
  #       serialization
  def object_wrapper(name, object_class, schema, hooks = {})
    if hooks[:new]
      read_body = "r = #{name}_newhook(#{name}_class);"
    else
      read_body = "r = #{name}_class.new;"
    end    

    to_body = "r = [];"
    to_body << "value = #{name}_tohook(value);" if hooks[:to]
    
    readlen_body = "old_offset = offset;"
    
    0.upto schema.length / 2 - 1 do |i|
      abi_type = schema[i * 2]
      type_mapping = schema[i * 2 + 1]
      
      # Set up the translation table.
      if type_mapping.nil?
        type_mapping = {}
        components = @target.send :"#{abi_type}_components"
        components.each { |c| type_mapping[c] = c }
      end
      
      # Set up the read_ and read_name_length methods.
      if abi_type.kind_of? Symbol
        read_body << "v = read_#{abi_type}(array,offset);"
      else
        read_body << "v = #{abi_type.inspect};"
      end    
      case type_mapping
      when Symbol
        read_body << "r.#{type_mapping} = v;"
      when Hash, nil        
        type_mapping.each do |k, v|
          read_body << "r.#{v} = v[:#{k}];"
        end
      end
      if abi_type.kind_of? Symbol
        if @target.respond_to? :"#{abi_type}_length"
          read_body << "offset += #{@target.send :"#{abi_type}_length"};"
          readlen_body << "offset += #{@target.send :"#{abi_type}_length"};"
        elsif @target.respond_to? :"read_#{abi_type}_length"
          read_body << "offset += read_#{abi_type}_length(array,offset);"        
          readlen_body << "offset += read_#{abi_type}_length(array,offset);"        
        else
          raise "#{abi_type} doesn't support _length or read_#{abi_type}_length"
        end
      end
      
      # Set up the to_ method.
      next unless abi_type.kind_of? Symbol
      to_body << "r += to_#{abi_type}("
      case type_mapping
      when Symbol
        to_body << "value.#{type_mapping}"
      when Hash
        to_body << type_mapping.map { |k, v| ":#{k} => value.#{v}" }.join(', ')
      end
      to_body << ");"
    end
    read_body << "r = self.#{name}_readhook(r);" if hooks[:read]
    read_body << "r;"
    to_body << "r;"
    readlen_body << "offset - old_offset;"

    define_str = "def read_#{name}(array,offset);#{read_body}end;"
    define_str << "def read_#{name}_length(array,offset);#{readlen_body}end;"
    define_str << "def to_#{name}(value);#{to_body}end;"
    
    defines = Proc.new do 
      define_method(:"#{name}_class") { object_class }
      define_method(:"#{name}_newhook", &hooks[:new]) if hooks[:new]      
      define_method(:"#{name}_readhook", &hooks[:read]) if hooks[:read]
      define_method(:"#{name}_tohook", &hooks[:to]) if hooks[:to]      
    end
    
    @target.class_eval &defines
    @target.class_eval define_str
    (class << @target; self; end).module_eval &defines
    (class << @target; self; end).module_eval define_str
  end
  
  # Defines methods for handling an 'enum'-like ABI type whose type is
  # determined by a fixed-length tag that is prefixed to the data.
  # 
  # tag_length indicates the tag's length, in bytes. The mapping between tags
  # and lower-level ABI types is expressed as an array of rules. Each rule is a
  # hash, and the following attributes are supported.
  #   tag:: an array of numbers; the tag must match this array (de-serializing)
  #   type:: the lower-level ABI type used for serialization/de-serialization
  #   class:: a ruby Class; if present, the value must be a kind of the given
  #       class to match the rule (serializing)
  #   predicate:: a Proc; if present, the Proc is given the value, and must
  #       return a true value for the value to match the rule (serializing)  
  def conditional_wrapper(name, tag_length, rules)
    impl = Tem::Builders::Abi::Impl
    
    defines = Proc.new do 
      define_method :"read_#{name}" do |array, offset|      
        tag = array[offset, tag_length]
        matching_rule = rules.find { |rule| rule[:tag] == tag }
        raise "Rules don't cover tag #{tag.inspect}" unless matching_rule
        self.send :"read_#{matching_rule[:type]}", array, offset + tag_length
      end
      define_method :"read_#{name}_length" do |array, offset|      
        tag = array[offset, tag_length]
        matching_rule = rules.find { |rule| rule[:tag] == tag }
        raise "Rules don't cover tag #{tag.inspect}" unless matching_rule
        if self.respond_to? :"#{matching_rule[:type]}_length"
          tag_length + self.send(:"#{matching_rule[:type]}_length")
        else
          tag_length + self.send(:"read_#{matching_rule[:type]}_length", array,
                                 offset + tag_length)
        end
      end
      define_method :"to_#{name}" do |value|
        matching_rule = rules.find do |rule|
          next false if rule[:class] && !value.kind_of?(rule[:class])
          next false if rule[:predicate] && !rule[:predicate].call(value)
          true
        end

        raise "Rules don't cover #{value.inspect}" unless matching_rule
        matching_rule[:tag] + self.send(:"to_#{matching_rule[:type]}", value)
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


# Implementation code for the ABI methods.
module Abi::Impl
  # Reads a variable-length number serialized to an array.
  #
  # The source is indicated by the array and offset parameters. The number's
  # length is given in bytes.
  def self.number_from_array(array, offset, length, is_signed, is_big_endian)
    # Read the raw number from the array.    
    number = 0
    if is_big_endian
      0.upto length - 1 do |i|
        number = (number << 8) | array[offset + i]
      end
    else
      (length - 1).downto 0 do |i|
        number = (number << 8) | array[offset + i]
      end
    end
    
    if is_signed  # Add the sign if necessary.
      range = 1 << (8 * length)
      max_value = (range >> 1) - 1
      number -= range if number > max_value
    end
        
    number
  end
  
  # Writes a fixed or variable-length number to an array.
  #
  # The source is indicated by the array and offset parameters. The number's
  # length is given in bytes.  
  def self.number_to_array(number, length, is_signed, is_big_endian)
    bytes = []
    if number.kind_of? OpenSSL::BN  # OpenSSL key material
      if is_signed and number < 0  # normalize number
        range = OpenSSL::BN.new("1") << (8 * length)
        number += range
      end
      
      length ||= [number.num_bytes, 1].max
      v = 0
      (length * 8 - 1).downto 0 do |i|
        v = (v << 1) | (number.bit_set?(i) ? 1 : 0)
        if i & 7 == 0
          bytes << v
          v = 0
        end
      end
      bytes.reverse! unless is_big_endian
    else  # Ruby number.
      if length
        length.times do
          bytes << (number & 0xFF)
          number >>= 8
        end
      else
        loop do
          bytes << (number & 0xFF)
          number >>= 8
          break if number == 0
        end
      end
      bytes.reverse! if is_big_endian
    end    
    bytes
  end
  
  # Checks the range of a number for fixed-length encoding.
  def self.check_number_range(number, length, is_signed)
    range = 1 << (8 * length)
    if is_signed      
      min_value, max_value = -(range >> 1), (range >> 1) - 1
    else
      min_value, max_value = 0, range - 1
    end
    
    exception_string = "Number #{number} exceeds #{min_value}-#{max_value}"
    raise exception_string if number < min_value or number > max_value
  end
  
  # Reads a variable-length string serialized to an array.
  #
  # The source is indicated by the array and offset parameters. The number's
  # length is given in bytes.
  def self.string_from_array(array, offset, length)
    array[offset, length].pack('C*')
  end
  
  # Writes a fixed or variable-length string to an array.
  #
  # The source is indicated by the array and offset parameters. The number's
  # length is given in bytes.
  def self.string_to_array(array_or_string, length)
    if array_or_string.respond_to? :to_str
      # array_or_string is String-like
      string = array_or_string.to_str
      array = string.unpack('C*')
    else
      # array_or_string is Array-like
      array = array_or_string
    end
    
    if length and array.length > length
      raise "Cannot fit #{array_or_string.inspect} into a #{length}-byte string"       
    end
    # Pad the array with zeros up to the fixed length.
    length ||= 0
    array << 0 while array.length < length
    array
  end  
end

end  # namespace Tem::Builders
