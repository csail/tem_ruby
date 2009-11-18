require 'yaml'

class Tem::SecPack
  @@serialized_ivars = [:body, :labels, :ep, :sp, :extra_bytes, :signed_bytes,
                        :secret_bytes, :bound, :lines]    
 
  def self.new_from_array(array)
    arg_hash = { }
    @@serialized_ivars.each_with_index { |name, i| arg_hash[name] = array[i] }
    self.new arg_hash
  end
  
  def self.new_from_yaml_str(yaml_str)
    array = YAML.load yaml_str
    new_from_array array
  end
  
  # Creates a deep copy of the SECpack.
  def copy
    Tem::SecPack.new_from_array self.to_array
  end

  def to_array
    @@serialized_ivars.map { |m| self.instance_variable_get :"@#{m}" }
  end
  
  def to_yaml_str
    self.to_array.to_yaml.to_s
  end
  
  # The size of the secret data in the SECpack.
  attr_reader :secret_bytes
  # The SECpack's body.
  attr_reader :body
  # The size of the encrypted data, if the SECpack is bound. False otherwise.
  attr_reader :bound
  # Debugging information.
  attr_reader :lines
  
  def trim_extra_bytes
    @extra_bytes = 0
    while @extra_bytes < @body.length
      break if @body[-@extra_bytes - 1] != 0
      @extra_bytes += 1
    end
    @body.slice! @body.length - @extra_bytes, @extra_bytes    
  end
  
  def expand_extra_bytes
    @body += [0] * @extra_bytes
    @extra_bytes = 0
  end
  
  def initialize(args)
    @@serialized_ivars.map { |m| self.instance_variable_set :"@#{m}", args[m] }
    @bound ||= false
    
    @extra_bytes ||= 0
    # trim_extra_bytes if @extra_bytes == 0
  end
  
  def label_address(label_name)
    @labels[label_name.to_sym]
  end
  
  def bind(public_key, secret_from = :secret, plain_from = :plain)
    raise "SECpack is already bound" if @bound
    
    expand_extra_bytes
    unless secret_from.kind_of? Numeric
      secret_from_label = secret_from
      secret_from = @labels[secret_from.to_sym]
      raise "Undefined label #{secret_from_label}" unless secret_from
    end
    unless plain_from.kind_of? Numeric
      plain_from_label = plain_from
      plain_from = @labels[plain_from.to_sym]
      raise "Undefined label #{plain_from_label}" unless plain_from      
    end
    
    @signed_bytes = secret_from
    @secret_bytes = plain_from - secret_from

    secpack_sig = Tem::Abi.tem_hash tem_header + @body[0, plain_from]
    crypt = public_key.encrypt @body[secret_from, @secret_bytes] + secpack_sig
    @body = [@body[0, secret_from], crypt, @body[plain_from..-1]].flatten
      
    label_delta = crypt.length - @secret_bytes
    relocate_labels secret_from, plain_from, label_delta
    
    #trim_extra_bytes
    @bound = crypt.length
  end

  def fake_bind(secret_from = :secret, plain_from = :plain)
    raise "SECpack is already bound" if @bound
    
    expand_extra_bytes
    unless secret_from.kind_of? Numeric
      secret_from_label = secret_from
      secret_from = @labels[secret_from.to_sym]
      raise "Undefined label #{secret_from_label}" unless secret_from
    end
    unless plain_from.kind_of? Numeric
      plain_from_label = plain_from
      plain_from = @labels[plain_from.to_sym]
      raise "Undefined label #{plain_from_label}" unless plain_from      
    end
    
    @signed_bytes = secret_from
    @secret_bytes = plain_from - secret_from
    
    #trim_extra_bytes
    @bound = @secret_bytes    
  end
  
  # Relocates the labels to reflect a change in the size of encrypted bytes.
  #
  # Args:
  #   same_until:: the end of the signed area (no relocations done there)
  #   delete_until:: the end of the old encrypted area (labels are removed)
  #   delta:: the size difference between the new and the old encrypted areas
  def relocate_labels(same_until, delete_until, delta)
    @labels = Hash[*(@labels.map { |k, v|
      if v <= same_until
        [k, v] 
      elsif v < delete_until
        []
      else
        [k, v + delta]
      end
    }.flatten)]    
  end
    
  # The encrypted data in a SECpack.
  #
  # This is useful for SECpack migration -- the encrypted bytes are the only
  # part that has to be migrated.
  def encrypted_data
    @body[@signed_bytes, @bound]
  end
  
  # Replaces the encrypted bytes in a SECpack.
  #
  # This is used in SECpack migration -- the encryption bytes are the only part
  # that changes during migration.
  def encrypted_data=(new_encrypted_bytes)
    raise "SECpack is not bound. See #bind and #fake_bind." unless @bound
    
    @body[@signed_bytes, @bound] = new_encrypted_bytes
    relocate_labels @signed_bytes, @signed_bytes + @bound, 
                    new_encrypted_bytes.length - @bound 
    @bound = new_encrypted_bytes.length
  end
  
  def tem_header
    # TODO: use 0x0100 (no tracing) depending on options
    hh = [0x0101, @signed_bytes || 0, @secret_bytes || 0, @extra_bytes, @sp,
          @ep].map { |n| Tem::Abi.to_tem_ushort n }.flatten
    hh += Array.new((Tem::Abi.tem_hash [0]).length - hh.length, 0)
    return hh
  end
  private :tem_header
  
  def tem_formatted_body
    # HACK: Ideally, we would allocate a bigger buffer, and then only fill part
    #       of it. Realistically, we'll just send in extra_bytes 0s.
    [tem_header, @body, [0] * @extra_bytes].flatten
  end
  
  def line_info_for_addr(addr)
    return nil unless @lines

    @lines.reverse_each do |info|
      # If something breaks, it's likely to happen after the opcode of the 
      # offending instruction has been read, so assume offending_ip < ip.
      return info if addr >= info[0]
    end
    return @lines.first
  end
  
  def label_info_for_addr(addr)
    @labels.to_a.reverse_each do |info|
      return info.reverse if addr >= info[1]
    end
    return [0, :__start]
  end
  
  # Methods for interacting with the plaintext content of a SECpack.
 
  def get_bytes(label, byte_count)
    expand_extra_bytes
    raise "Unknown label #{label}" unless addr = @labels[label]
    bytes = @body[addr, byte_count]
    #trim_extra_bytes
    bytes
  end
  
  def set_bytes(label, bytes)
    expand_extra_bytes
    raise "Unknown label #{label}" unless addr = @labels[label]
    @body[addr, bytes.length] = bytes
    #trim_extra_bytes
  end
  
  def set_value(label, abi_type, value)
    set_bytes label, Tem::Abi.send(:"to_#{abi_type}", value)
  end
  
  def get_value(label, abi_type)
    expand_extra_bytes
    raise "Unknown label #{label}" unless addr = @labels[label]
    value = Tem::Abi.send :"read_#{abi_type}", @body, addr
    #trim_extra_bytes
    value
  end
end
