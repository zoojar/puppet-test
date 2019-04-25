# wrapper
def run(_test_tool, test_file, _report_format)
  require 'minitest/autorun'
  RSpec::Core::Runner.run([test_file, '-c', '-f', report_format])
end
