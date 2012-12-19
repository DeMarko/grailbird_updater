# GrailbirdUpdater

For the most of the people who know me online, I've been dying to get a copy of
my Twitter archive from Twitter for forever. I was finally given one and
decided to write a quick script to keep my own archive up-to-date.

Turns out the contents in the archive are partial/trimmed API responses from
the Twitter API, so it is actually possible to drop a whole API response in
there, do some sorting and update the archive.

## How do I know if I have a Twitter archive?

Hopefully, you downloaded it from Twitter once the feature was made available
to you and have their web application which can consume it. The file structure
looks somewhat like this (as of 19.12.12):

```
tweets
├── README.txt
├── css
│   └─ ... // provided by Twitter
├── data
│   ├── csv
│   │   ├── 2007_03.csv
│   │   ├── 2007_04.csv
│   │   ├── 2007_05.csv
│   │   ├─ ...
│   │   ├── 2012_10.csv
│   │   ├── 2012_11.csv
│   │   └── 2012_12.csv
│   └── js
│       ├── payload_details.js
│       ├── tweet_index.js
│       ├── tweets
│       │   ├── 2007_03.js
│       │   ├── 2007_04.js
│       │   ├── 2007_05.js
│       │   ├─ ... // you get the idea, I've been on Twitter a while
│       │   ├── 2012_10.js
│       │   ├── 2012_11.js
│       │   └── 2012_12.js
│       └── user_details.js
├── img
│   └─ ... // provided by Twitter
├── index.html
├── js
│   └─ ... // provided by Twitter
└── lib
    └─ ... // provided by Twitter
```

This gem only modifies what's in the data directory for a given archive, 
the rest of the files are provided by Twitter

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
