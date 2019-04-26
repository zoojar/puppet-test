# frozen_string_literal: true

require 'serverspec'
require 'puppet_litmus'
include PuppetLitmus
include BoltSpec::Run

if ENV['TARGET_HOST'].nil? || ENV['TARGET_HOST'] == 'localhost'
  puts 'Running tests against this machine !'
  if Gem.win_platform?
    set :backend, :cmd
  else
    set :backend, :exec
  end
else
  # load inventory
  inventory_hash = inventory_hash_from_inventory_file
  node_config = config_from_node(inventory_hash, ENV['TARGET_HOST'])

  if target_in_group(inventory_hash, ENV['TARGET_HOST'], 'ssh_nodes')
    set :backend, :ssh
    options = Net::SSH::Config.for(host)
    options[:user] = node_config.dig('ssh', 'user') unless node_config.dig('ssh', 'user').nil?
    options[:port] = node_config.dig('ssh', 'port') unless node_config.dig('ssh', 'port').nil?
    options[:password] = node_config.dig('ssh', 'password') unless node_config.dig('ssh', 'password').nil?
    options[:verify_host_key] = Net::SSH::Verifiers::Null.new unless node_config.dig('ssh', 'host-key-check').nil?
    host = if ENV['TARGET_HOST'].include?(':')
             ENV['TARGET_HOST'].split(':').first
           else
             ENV['TARGET_HOST']
           end
    set :host,        options[:host_name] || host
    set :ssh_options, options
    set :request_pty, true
  elsif target_in_group(inventory_hash, ENV['TARGET_HOST'], 'winrm_nodes')
    require 'winrm'

    set :backend, :winrm
    set :os, family: 'windows'
    user = node_config.dig('winrm', 'user') unless node_config.dig('winrm', 'user').nil?
    pass = node_config.dig('winrm', 'password') unless node_config.dig('winrm', 'password').nil?
    endpoint = "http://#{ENV['TARGET_HOST']}:5985/wsman"

    opts = {
      user: user,
      password: pass,
      endpoint: endpoint,
      operation_timeout: 300,
    }

    winrm = WinRM::Connection.new opts
    Specinfra.configuration.winrm = winrm
  end
end

def test_run_task(task_name, params)
  config_data = { 'modulepath' => File.join(Dir.pwd, 'spec', 'fixtures', 'modules') }
  inventory_hash = inventory_hash_from_inventory_file
  target_node_name = ENV['TARGET_HOST'] if target_node_name.nil?
  run_task(task_name, target_node_name, params, config: config_data, inventory: inventory_hash)
end

def test_run_plan(plan_name, params)
  config_data = { 'modulepath' => File.join(Dir.pwd, 'spec', 'fixtures', 'modules') }
  inventory_hash = inventory_hash_from_inventory_file
  target_node_name = ENV['TARGET_HOST'] if target_node_name.nil?
  run_plan(plan_name, params.merge!('target' => target_node_name), config: config_data, inventory: inventory_hash)
end