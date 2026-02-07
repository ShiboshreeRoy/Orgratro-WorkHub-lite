require "test_helper"

class InternDashboardControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get intern_dashboard_index_url
    assert_response :success
  end
end
