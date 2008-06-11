class TemTimings
  def time_simple_apdu
    do_timing { @tem.get_tag_length }
  end
end
