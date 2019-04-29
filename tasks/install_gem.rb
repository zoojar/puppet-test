#!/opt/puppetlabs/puppet/bin/ruby
require 'json'
require 'puppet'
require 'facter'

def install_gem(gem, version, install_dir, platform, gem_bin = nil)
  require 'shellwords'
  require 'open3'
  require 'fileutils'
  # If HOME is not already set, set it.
  if ENV['HOME'].nil?
    require 'etc'
    ENV['HOME'] = Etc.getpwuid.dir
  end
  if gem_bin.nil?
    gem_bin = case Facter.value(:kernel)
              when 'Windows'
                File.join('c:', 'programdata', 'puppetlabs', 'puppet', 'bin', 'gem')
              else
                File.join('/', 'opt', 'puppetlabs', 'puppet', 'bin', 'gem')
              end
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
    os_tmp = case Facter.value(:kernel)
             when 'Darwin'
               '/Users/Shared/tmp'
             when 'Windows'
               'c:/tmp'
             else
               '/tmp'
             end
    install_dir = params['install_dir'] ||= File.join(os_tmp, 'puppet_test')
    gem         = params['gem']
    version     = params['version'] ||= '> 0' # latest
    platform    = params['platform']
    install_gem(gem, version, install_dir, platform)
  end
rescue => e
  puts({ status: 'failure', error: e.message }.to_json)
  exit 1
end
