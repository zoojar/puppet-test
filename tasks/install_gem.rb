#!/opt/puppetlabs/puppet/bin/ruby
require 'json'
require 'puppet'
require 'facter'

def install_gem(gem_bin, gem, version, install_dir, platform)
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
  cmd << '--platform' << platform unless platform.empty?
  cmd = cmd.shelljoin
  begin
    FileUtils.mkdir_p install_dir unless File.directory?(install_dir)
    stdout, stderr, exitcode = Open3.capture3(cmd)
    raise "Failed to install gem #{gem} using cmd: #{cmd} : #{stderr}" unless exitcode.to_i.zero? && stderr.to_s.empty?
    puts "gem #{gem} installed at #{install_dir}: #{stdout} #{stderr}"
  rescue => e
    puts({ status: 'failure', error: e.message }.to_json)
  end
end

begin
  stdin = STDIN.read
  unless stdin.to_s.empty?
    params = JSON.parse(stdin)
    case Facter.value(:kernel)
    when 'Linux'
      os_tmp = '/tmp'
      gem_bin = params['gem_bin'] ||= File.join('/', 'opt', 'puppetlabs', 'puppet', 'bin', 'gem')
    when 'Darwin'
      os_tmp = '/Users/Shared/tmp'
      gem_bin = params['gem_bin'] ||= File.join('/', 'opt', 'puppetlabs', 'puppet', 'bin', 'gem')
    when 'Windows'
      os_tmp = 'c:/tmp'
      gem_bin = params['gem_bin'] ||=  File.join('C:', 'Program Files', 'Puppet Labs', 'Puppet', 'sys', 'ruby', 'bin', 'gem.bat')
    end
    install_dir = params['install_dir'] ||= File.join(os_tmp, 'puppet_test')
    gem         = params['gem']
    version     = params['version'] ||= '> 0' # latest
    platform    = params['platform']
    install_gem(gem_bin, gem, version, install_dir, platform)
  end
rescue => e
  puts({ status: 'failure', error: e.message }.to_json)
  exit 1
end
