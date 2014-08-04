# Homeseed

CLI for managing system configs and dot-profiles
can be used for initializations, deployments and updates on remotes or localhost

## Installation

Add this line to your application's Gemfile:

    gem 'homeseed'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install homeseed

## Usage

homeseed commands
```bash
$ homeseed
Commands:
  homeseed exec [-e <command> or -f <files>] [-u <user>] [-p <has_password>] -s, --servers=SERVERS              # executes bash login session(s) on remote servers to run inline bash commands or bash ...
  homeseed help [COMMAND]                                                                                       # Describe available commands or one specific command
  homeseed plant [-u <user>] [-p <has_password>] [-c <clean>] [--url <url>] -s, --servers=SERVERS               # installs homeshick and then dot profile based on localhost $HOME/.homeseed.yml or url...
  homeseed update [-u <user>] [-p <has_password>] [--url <url>] -s, --servers=SERVERS                           # updates dot profile based on localhost $HOME/.homeseed.yml or url with yml commands
  homeseed upload [-f <upload_files>] [-r <remote_path>] [-u <user>] [-p <has_password>] -s, --servers=SERVERS  # scp uploads file(s) to remote servers
```

to distribute and install your dot profile(s) on multiple of servers run
```bash
$ homeseed plant -s blackberry,blueberry,raspberry
```
this uses your user's local $HOME/.homeseed.yml by default; a url can be given instead to override this
(also supports post install bash hooks; see example user config below)
```bash
$ homeseed plant -s pom --url 'i_am_a_homeseed.yml_file'
```
localhost can be specified as the target for system initialization
```bash
$ homeseed exec -s localhost --url 'setup_bluez_mupen_and_such.yml'
```

to update run; uses $HOME/.homeseed.yml by default (same url based overrides apply here as well)
```bash
$ homeseed update -s soho
```
localhost can be specified here as well
```bash
$ homeseed update -s localhost
```

ex user config ($HOME/.homeseed.yml)
```ruby
:repos:
  terminator:
    :origin: https://github.com/rbuchss/terminator.git
  vim-4-eva:
    :origin: https://github.com/rbuchss/vim-4-eva.git
:post_install:
  ln: -s /opt/soho $HOME
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
