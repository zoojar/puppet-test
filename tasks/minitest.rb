# wrapper
def run(_test_tool, test_file, _report_format)
  require 'minitest/autorun'
  status = (load test_file).to_i
  return status
end
