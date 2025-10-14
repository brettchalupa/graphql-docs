# frozen_string_literal: true

require 'test_helper'

class CliTest < Minitest::Test
  def setup
    @schema = File.join(fixtures_dir, 'sw-schema.graphql')
  end

  def test_cli_works
    FileUtils.rm_rf("output")
    assert cmd("#{@schema}")
    assert File.exist?(File.join("output", 'index.html'))
  end

  def test_cli_works_with_output_dir
    clean_up_output # NOTE: this is the fixture output dir
    schema = File.join(fixtures_dir, 'sw-schema.graphql')
    assert cmd("#{@schema} -o #{output_dir}")
    assert File.exist?(File.join(output_dir, 'index.html'))
  end

  def test_cli_requires_schema
    _out, err = capture_subprocess_io do
      refute cmd("", exception: false)
    end
    assert_match /schema must be specified/, err
  end

  def test_cli_help
    out, err = capture_subprocess_io do
      assert cmd("--help")
    end
    assert_match /Usage/, out
    assert err.empty?, "errors not empty: #{err}"
  end

  def test_cli_verbose
    out, err = capture_subprocess_io do
      assert cmd("#{@schema} --verbose")
    end
    assert_match /Generating site/, out
    assert_match /Site successfully generated/, out
    assert err.empty?, "errors not empty: #{err}"
  end

  def test_cli_base_url
    out, err = capture_subprocess_io do
      assert cmd("#{@schema} -b https://example.com")
    end
    assert err.empty?, "errors not empty: #{err}"
    assert File.read(File.join("output", 'index.html')).include?("<link rel=\"stylesheet\" href=\"https://example.com/assets/style.css\">")
  end

  def test_cli_version
    out, err = capture_subprocess_io do
      assert cmd("--version")
    end
    assert_match /#{GraphQLDocs::VERSION}/, out
    assert err.empty?, "errors not empty: #{err}"
  end

  private

  def cmd(args, exception: true)
    system("ruby -Ilib ./exe/graphql-docs #{args}", exception: exception)
  end
end
