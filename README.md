# GrailbirdUpdater

For the most of the people who know me online, I've been dying to get a copy of
my Twitter archive from Twitter for forever. I was finally given one and
decided to write a quick script to keep my own archive up-to-date.

Turns out the contents in the archive are partial/trimmed API responses from
the Twitter API, so it is actually possible to drop a whole API response in
there, do some sorting and update the archive.


## Installation

Install it yourself as:

    $ gem install grailbird_updater

Or add this line to your application's Gemfile:

    gem 'grailbird_updater'

And then execute:

    $ bundle

## Usage

```
grailbird_updater /path/to/twitter/archive
```

To run as a cronjob, with the gem installed using rvm (at `/home/username/grailbird` in this example)

```
@daily /bin/bash -l -c 'cd /home/username/grailbird && grailbird_updater /path/to/twitter/archive'
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## FAQ

* _I have a protected Twitter account, can I still use this updater with my Twitter archive?_

    Actually, yes! Like with any account, as of v0.5.0, you will need to create your own "application" on
    Twitter and then use your own consumer key/secret pair to let the application
    use the oauth tokens for a user and then follow the authorization steps for
    a given user.

    Once you have auth'd the application for a user, you do not have to do
    it again, the consumer key/secret and oauth token/secret are stored in a YAML file
    at the root of your tweet archive (or a user specified locationo, if the --key_path flag is used).

    __IMPORTANT__ Do NOT commit or post your own consumer key/secret or your oauth
    token/secret anywhere.

    Note: you will only need to create a single application on Twitter even if you
    are using this to update multiple accounts. You can reuse the consumer
    key/secret and just authorize each account individually.

    Please see [this wiki article](https://github.com/DeMarko/grailbird_updater/wiki/Authorizing-grailbird_updater) for step-by-step instructions.

* _How do I know if I have a Twitter archive?_

    Hopefully, you downloaded it from Twitter once the feature was made available
    to you and have their web application which can consume it.

    This gem only modifies what's in the `data` directory for a given archive,
    the rest of the files are provided by Twitter.

    To check if you can download a copy of your Twitter archive, go to your
    [Account Settings](https://twitter.com/settings/account) and scroll all
    the way to the bottom. If the feature is enabled for you, you should see
    a section labeled "Your Twitter Archive".

    The file structure looks somewhat like this (as of 09.04.13):


```
tweets
├── README.txt
├── css
│   └─ application.min.css
├── data
│   └── js
│       ├── payload_details.js
│       ├── tweet_index.js
│       ├── tweets
│       │   ├── 2007_03.js
│       │   ├── 2007_04.js
│       │   ├── 2007_05.js
│       │   ├─ ... // you get the idea, I've been on Twitter a while
│       │   ├── 2013_02.js
│       │   ├── 2013_03.js
│       │   └── 2013_04.js
│       └── user_details.js
├── img
│   └─ ... // provided by Twitter
├── index.html
├── js
│   └─ ... // provided by Twitter
├── lib
│   └─ ... // provided by Twitter
├── README.txt
└── tweets.csv
```

