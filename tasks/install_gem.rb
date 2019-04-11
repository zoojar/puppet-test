#!/opt/puppetlabs/puppet/bin/ruby
require 'json'
require 'puppet'
require 'facter'

def install_gem(gem_bin, gem, version, install_dir)
  require 'shellwords'
  require 'open3'
  # If HOME is not already set, set it.
  if ENV['HOME'].nil?
    require 'etc'
    ENV['HOME'] = Etc.getpwuid.dir
  end
  cmd = [
    gem_bin, 'install', gem,
    '-i', install_dir,
    '--no-ri', '--no-rdoc',
    '-v', version
  ].shelljoin
  begin
    stdout, stderr, exitcode = Open3.capture3(cmd)
    raise "Failed to install gem #{gem} using cmd: #{cmd} : #{result}" unless exitcode.to_i.zero? && stderr.to_s.empty?
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
             when 'Darwin' then '/Users/Shared/tmp'
             when 'Linux' then '/tmp'
             when 'Windows' then 'c:/tmp'
             end
    install_dir = params['install_dir'] ||= File.join(os_tmp, 'puppet_test')
    gem_bin     = params['gem_bin'] ||= File.join('/opt', 'puppetlabs', 'puppet', 'bin', 'gem')
    gem         = params['gem']
    version     = params['version'] ||= '> 0' # latest
    install_gem(gem_bin, gem, version, install_dir)
  end
rescue => e
  puts({ status: 'failure', error: e.message }.to_json)
  exit 1
end
