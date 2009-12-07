require 'tem_ruby'

require 'test/unit'


# Helper methods for TEM tests.
#
# This module implements setup and teardown methods that provide an initialized
# @tem instance variable holding a Tem::Session. Just the right thing for
# testing :) 
class TemTestCase < Test::Unit::TestCase
  def setup
    @tem = Tem.auto_tem
    
    @tem.kill
    @tem.activate
  end
  
  def teardown
    @tem.disconnect if defined?(@tem) && @tem
  end

  def default_test
    # NOTE: Without this, test/unit will complain that the class does not have
    #       test cases.
  end
end
