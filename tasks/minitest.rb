# wrapper
def run(test_tool, test_file, report_format)
  require test_tool
  RSpec::Core::Runner.run([test_file, '-c', '-f', report_format])
end
