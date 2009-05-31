class Tem::Benchmarks
  def time_devchip_decrypt
    pubek = @tem.pubek
    data = (1...120).map { |i| (i * i * 217 + i * 661 + 393) % 256 }
    encrypted_data = pubek.encrypt data
    print "Encrypted blob has #{encrypted_data.length} bytes\n"
    do_timing { @tem.devchip_decrypt encrypted_data, 0 }
  end
end
