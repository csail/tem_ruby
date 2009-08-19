# Benchmarks the TEM hardware's overhead for an APDU round-trip.
#
# This overhead applies to any TEM operation, because each operation involves
# one or more APDU exchanges. 
#
# Author:: Victor Costan
# Copyright:: Copyright (C) 2008 Massachusetts Institute of Technology
# License:: MIT


# :nodoc:
class Tem::Benchmarks
  def time_simple_apdu
    do_timing { @tem.get_tag_length }
  end
end
