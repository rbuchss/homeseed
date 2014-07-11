# Homeseed

CLI for config/dot-profile deployments
also is a bash login session command flattener for remote ssh exec

## Installation

Add this line to your application's Gemfile:

    gem 'homeseed'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install homeseed

## Usage

homeseed commands
```
➜ homeseed help
Commands:
  homeseed exec [-e <command> or -f <files>] [-u <user>] -s, --servers=SERVERS  # executes bash login session(s) on remote servers to run inline bash commands or bash commands from yml file
  homeseed help [COMMAND]                                                       # Describe available commands or one specific command
  homeseed plant [-u <user>] -s, --servers=SERVERS                              # installs homeshick and then dot profile based on localhost $HOME/.homeseed.yml
  homeseed update [-u <user>] -s, --servers=SERVERS                             # updates dot profile based on localhost $HOME/.homeup.yml
```

to install dot profile on csv server list run; uses $HOME/.homeseed.yml
```
homeseed plant -s blackberry,blueberry,raspberry
```

ex $HOME/.homeseed.yml
```
homeshick:
  clone:
    - https://github.com/rbuchss/terminator.git --batch
    - https://github.com/rbuchss/vim-4-eva.git --batch
  link:
    - terminator --force
    - vim-4-eva --force
```

to update run; uses $HOME/.homeup.yml
```
homeseed update -s soho
```

ex $HOME/.homeup.yml
```
homeshick:
  pull:
    - --force --batch
  link:
    - terminator --force
    - vim-4-eva --force
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
