# Homeseed

Bash command flattener for remote ssh exec

## Installation

Add this line to your application's Gemfile:

    gem 'homeseed'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install homeseed

## Usage

Examples

to install dot profile on server list run
```
homeseed plant -s blackberry,blueberry,raspberry -f config/shick-seed.yml
```

to update run
```
homeseed plant -s soho -f config/shick-update.yml
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
