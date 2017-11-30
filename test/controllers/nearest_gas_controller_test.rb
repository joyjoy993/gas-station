require 'test_helper'

class NearestGasControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get nearest_gas_index_url
    assert_response :success
  end

end
