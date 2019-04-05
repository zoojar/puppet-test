
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
1. Installs the specified test tooling (gems) in *gem_dir* (default: /tmp/puppet_test/gems) on the target node.
2. Executes a specified test with the specified test tooling (eg. inspec) on the target node.


### Setup Requirements

Your tests should live with your code...

This task assumes that you are using [Roles & Profiles](https://puppet.com/docs/pe/2019.0/the_roles_and_profiles_method.html) in your control-repo.
The task instructs the test tool to pick up a test file for a given role from files in your role(s) module.

For example: `<control-repo>/site/roles/files/tests/<test_tool>/<role>.rb`

To add an inspec test for your "web_server" role, add a test file:
>`<control-repo>/site/roles/files/tests/inspec/web_server.rb`
```ruby
describe port(80) do
  it { should be_listening }
end
```





### Beginning with Test

#### Role or Roles ?

Some use "role", and others use "roles" when using the Roles & Profiles pattern.
Task metadata (role.json & roles.json) allows for both naming conventions; "role" and "roles". When executing this task, for the task name use either `test::role` or `test::roles` depending on your role module location.


## Usage

### Example: Execute Inspec, against a web_server role

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


### Example: InSpec, specifying a test_file & reporter

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



### Example: InSpec, specifying a test_file from this module

This example uses an example test file within this module.

```bash
bolt task run test::test -n webserver-01.local --modulepath . --run-as root \ test_tool=inspec test_file=example.rb
```

This does the following things:
1. Installs the InSpec gems on webserver-01.local in gem_dir (/tmp/puppet_test/gems)
2. Copies the files from 
3. Executes InSpec runner with the test file: 
> *control-repo*/site/**roles**/files/tests/***inspec***/***another_test.rb*** 
4. Returns the test report from InSpec in json format.





## Limitations

### InSpec: gcc gcc-c++

Running InSpec on target nodes requires the following packages ot also be installed on the target node: install: gcc gcc-c++. InSpec gem installation will fail without these present. For a workaround, use serverspec.



## Development

In the Development section, tell other users the ground rules for contributing to your project and how they should submit their work.

## Release Notes/Contributors/Etc. **Optional**

If you aren't using changelog, put your release notes here (though you should consider using changelog). You can also add any additional sections you feel are necessary or important to include here. Please use the `## ` header.
