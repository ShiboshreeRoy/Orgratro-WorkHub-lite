require "test_helper"

class Admin::InternTasksControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get admin_intern_tasks_index_url
    assert_response :success
  end

  test "should get new" do
    get admin_intern_tasks_new_url
    assert_response :success
  end

  test "should get create" do
    get admin_intern_tasks_create_url
    assert_response :success
  end

  test "should get edit" do
    get admin_intern_tasks_edit_url
    assert_response :success
  end

  test "should get update" do
    get admin_intern_tasks_update_url
    assert_response :success
  end

  test "should get show" do
    get admin_intern_tasks_show_url
    assert_response :success
  end

  test "should get destroy" do
    get admin_intern_tasks_destroy_url
    assert_response :success
  end
end
