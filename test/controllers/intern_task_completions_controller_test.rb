require "test_helper"

class InternTaskCompletionsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get intern_task_completions_new_url
    assert_response :success
  end

  test "should get create" do
    get intern_task_completions_create_url
    assert_response :success
  end

  test "should get index" do
    get intern_task_completions_index_url
    assert_response :success
  end

  test "should get show" do
    get intern_task_completions_show_url
    assert_response :success
  end
end
