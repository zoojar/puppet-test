
# Test

Task for acceptance integration testing servers (roles)

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with test](#setup)
    * [What test affects](#what-test-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with test](#beginning-with-test)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Limitations - OS compatibility, etc.](#limitations)
5. [Development - Guide for contributing to the module](#development)

## Description

Puppet module including a task for acceptance & integration testing servers
using various optional test tools such as inspec, serverspec and more.

## Setup

### What test affects

When run against targeted nodes:
1. (Optionally) Installs the specified test tooling (gems) in *gem_dir* (default: /<tmp>/puppet_test/gems) on the target node.
2. Executes a specified test with the specified test tooling (minitest/inspec/serverspec) on the target node.


### Setup Requirements

Your tests should live with your code...

This task assumes that you are using [Roles & Profiles](https://puppet.com/docs/pe/2019.0/the_roles_and_profiles_method.html) in your control-repo.
The task instructs the test tool to pick up a test file for a given role from files in your role(s) module.

For example: `<control-repo>/site/roles/files/tests/<test_tool>/<role>.rb`

To add an inspec test for your "web_server" role, add a test file in your control-repo (or role module if external):
>`<control-repo>/site/roles/files/tests/inspec/web_server.rb`
```ruby
describe port(80) do
  it { should be_listening }
end
```

See `spec/fixtures/site/role/files/tests` in this module for more examples.



### Beginning with Test

#### Role or Roles ?

Some use "role", and others use "roles" when using [Roles & Profiles](https://puppet.com/docs/pe/2019.0/the_roles_and_profiles_method.html).
Task metadata (role.json & roles.json) allows for either naming conventions. When executing this task, use either `test::role` or `test::roles` depending on your role module location.

#### Test tools

The task currently supports the following test tools:

- [Serverspec](https://serverspec.org/) - RSpec tests for your servers configured by Puppet, Chef or anything else
- [InSpec](https://www.inspec.io) - a free and open-source framework for testing and auditing your applications and infrastructure.
- [MiniTest](https://github.com/seattlerb/minitest) - a complete suite of testing facilities supporting TDD, BDD, mocking, and benchmarking.


## Usage

### Task: Execute Inspec, against a web_server role

[InSpec](https://www.inspec.io) is a free and open-source framework for testing and auditing your applications and infrastructure.

```bash
bolt task run test::roles -n webserver-01.local --modulepath . --run-as root test_tool=inspec
```

This does the following things:
1. Installs the InSpec gems on webserver-01.local in gem_dir (/tmp/puppet_test/gems)
2. Auto-detects the node's role ("web_server") using Facter.
3. Executes InSpec runner with the "web_server.rb" test file:
> *control-repo*/site/**roles**/files/tests/***inspec***/web_server.rb
4. Returns the test report from InSpec 


### Task: InSpec, specifying a test_file & reporter

The test_file parameter can be used to execute a specific test file...

```bash
bolt task run test::roles -n webserver-01.local --modulepath . --run-as root \
--params '{ "test_tool":"inspec", "test_file":"another_test.rb", "reporter":"json" }'
```

This does the following things:
1. Installs the InSpec gems on webserver-01.local in gem_dir (/tmp/puppet_test/gems)
2. Copies the files from 
3. Executes InSpec runner with the test file: 
> *control-repo*/site/**roles**/files/tests/***inspec***/***another_test.rb*** 
4. Returns the test report from InSpec in json format; [InSpec Reporters](https://www.inspec.io/docs/reference/reporters/)


### Plan

The module also contains a plan, allowing gems to be "cached" locally on the plan runner then copied across to the target node.
This method is mainly useful in two ways; 1. Authentication is handled by the Puppet server (PCP), and 2. Target nodes don't need to download and install gems,

Example usage:

```bash
bolt plan run test::role --modulepath . --run-as root --params '{"target":"webserver.local","test_params":{"test_tool":"serverspec","test_file":"webserver.rb"},"ctrl_params":{"tmp_dir":"/Users/Shared/tmp"}}'
```


## Limitations

### InSpec: gcc gcc-c++

Running InSpec on target nodes requires the following packages ot also be installed on the target node: install: gcc gcc-c++. InSpec gem installation will fail without these present.



## Development

Contributions welcome.

## Release Notes/Contributors/Etc. **Optional**

TBD
