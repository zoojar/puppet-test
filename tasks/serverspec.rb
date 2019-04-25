# wrapper
def run(test_tool, test_file, report_format)
  require test_tool
  status = RSpec::Core::Runner.run([test_file, '-c', '-f', report_format]).to_i
  return status
end
