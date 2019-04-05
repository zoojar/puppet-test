#!/opt/puppetlabs/puppet/bin/ruby
require 'facter'
require 'json'
params = JSON.parse(STDIN.read)
print Facter.value(params['fact'].to_sym)