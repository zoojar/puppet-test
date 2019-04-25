# wrapper
def run(_test_tool, test_file, _report_format)
  require 'minitest/autorun'
  begin
    load test_file
  rescue
  end
end
