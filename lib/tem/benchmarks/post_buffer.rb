class Tem::Benchmarks
  def time_post_buffer
    data = (0...490).map { |i| (39 * i * i + 91 * i + 17) % 256 }
    p @tem.stat_buffers
    do_timing do
      buffer_id = @tem.post_buffer(data)
      @tem.release_buffer buffer_id
    end
  end
end
