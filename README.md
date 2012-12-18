# GrailbirdUpdater

For the most of the people who know me online, I've been dying to get a copy of
my Twitter archive from Twitter for forever. I was finally given one and
decided to write a quick script to keep my own archive up-to-date.

Turns out the contents in the archive are partial/trimmed API responses from
the Twitter API, so it is actually possible to drop a whole API response in
there, do some sorting and update the archive.

## Installation

Add this line to your application's Gemfile:

    gem 'grailbird_updater'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install grailbird_updater

## Usage

```
grailbird_updater /path/to/twitter/archive
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
