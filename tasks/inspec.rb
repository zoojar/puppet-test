# wrapper
def run(test_tool, test_file, report_format)
  require test_tool
  runner = Inspec::Runner.new('reporter' => [report_format])
  runner.add_target(test_file)
  runner.run().to_i
end
