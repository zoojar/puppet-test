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
  stdout, stderr, exitcode = Open3.capture3(cmd)
  if exitcode != 0 then 
    raise "Failed to install gem #{gem} using cmd: #{cmd} : #{stderr}"
  end
end

begin
  params = JSON.parse(STDIN.read) 
  os_tmp = case Facter.value(:kernel)
           when 'Darwin'  ; '/Users/Shared/tmp' 
           when 'Linux'   ; '/tmp' 
           when 'Windows' ; 'c:/tmp'
           end
  install_dir = params['install_dir'] || File.join(os_tmp, 'puppet_test')
  gem_bin     = params['gem_bin']     || File.join('/opt','puppetlabs','puppet','bin','gem')
  gem         = params['gem']
  version     = params['version']     || '> 0' # latest

  result = install_gem(gem_bin, gem, version, install_dir)
  puts install_dir

rescue Puppet::Error => e
  # handle failure and exit
  puts({ status: 'failure', error: e.message }.to_json)
  exit 1
end
