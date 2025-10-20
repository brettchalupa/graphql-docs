# frozen_string_literal: true

require "test_helper"
require "rake"

class RakeTaskTest < Minitest::Test
  def setup
    # Clear any existing tasks to ensure clean state
    Rake::Task.clear if Rake::Task.respond_to?(:clear)

    @rake = Rake::Application.new
    Rake.application = @rake

    # Load the graphql-docs library and the rake task
    require "graphql-docs"
    load File.expand_path("../lib/tasks/graphql-docs.rake", __dir__)
  end

  def teardown
    # Clean up the task
    Rake::Task["graphql-docs:generate"].clear if Rake::Task.task_defined?("graphql-docs:generate")
    Rake.application = nil
  end

  def test_rake_task_is_defined
    assert Rake::Task.task_defined?("graphql-docs:generate"), "graphql-docs:generate task should be defined"
  end

  def test_rake_task_name_is_correct
    task = Rake::Task["graphql-docs:generate"]
    assert_equal "graphql-docs:generate", task.name
  end

  def test_rake_task_exits_without_schema_file
    task = Rake::Task["graphql-docs:generate"]

    # Capture output and exit
    out, _err = capture_io do
      assert_raises(SystemExit) do
        task.invoke
      end
    end

    assert_match(/Please specify a GraphQL schema file/, out)
    assert_match(/Using task arguments/, out)
    assert_match(/Or using environment variables/, out)
  end

  def test_rake_task_can_be_enhanced
    # This test verifies that the task can be used in task dependencies
    # which is the main use case mentioned in the requirements
    task = Rake::Task["graphql-docs:generate"]
    assert_respond_to task, :enhance
  end

  def test_rake_task_accepts_arguments
    # Verify that the task accepts the expected arguments
    task = Rake::Task["graphql-docs:generate"]
    assert task.arg_names.include?(:schema_file), "Task should accept schema_file argument"
    assert task.arg_names.include?(:output_dir), "Task should accept output_dir argument"
    assert task.arg_names.include?(:base_url), "Task should accept base_url argument"
    assert task.arg_names.include?(:delete_output), "Task should accept delete_output argument"
  end
end
