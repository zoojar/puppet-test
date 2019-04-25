# wrapper
def run(_test_tool, test_file, _report_format)
  require 'minitest/autorun'
  load test_file
end
