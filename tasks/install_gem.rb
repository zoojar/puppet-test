#!/opt/puppetlabs/puppet/bin/ruby

def install_gem(gem_bin, gem, version, install_dir)
  require 'shellwords'
  require 'open3'
  require 'fileutils'
  # If HOME is not already set, set it.
  if ENV['HOME'].nil?
    require 'etc'
    ENV['HOME'] = Etc.getpwuid.dir
  end

  cmd = [
    gem_bin, 'install', gem,
    '-i', install_dir,
    '--no-ri', '--no-rdoc'
  ]
  cmd << '-v' << version unless version.empty?
  cmd = cmd.shelljoin
  FileUtils.mkdir_p install_dir unless File.directory?(install_dir)
  stdout, stderr, exitcode = Open3.capture3(cmd)
  raise "Gem install failed: #{stdout} #{stderr}" unless exitcode.success?
end
