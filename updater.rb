#!/usr/bin/env ruby
require 'rubygems'
require 'open-uri'
require 'json'
require 'trollop'

opts = Trollop::options do
    version "updater 0.1"
    banner <<-EOS
Update your Twitter archive (best if used with a cron)

Usage: updater [options] [path to archive]

EOS
    opt :verbose, "Verbose mode"
    opt :limit, "How many tweets to look back at (max: 3200)", :default => 1000
    opt :directory, "Twitter archive directory", :type => :string
end

dir = nil
dir ||= opts[:directory]
dir ||= ARGV.first
raise ArgumentError, "Must specify a directory" unless File.directory?(dir)
raise ArgumentError, "Cannot look back further than 3200 tweets" if opts[:limit] > 3200

count = opts[:limit]

# find user_id in data/js/user_details.js

# find latest_month_file (should be last when sorted alphanumerically)
# find :last_tweet_id in latest_month_file
# get response from API
# add tweets to json data file and csv data file
    # if tweets returned contain new month, create new month files, add file location to tweet_index.js 
# add count to tweet_index.js, payload_details.js

twitter_url = 'http://api.twitter.com/1/statuses/user_timeline.json?count=1000&user_id=809399&since_id=279926892881145857'

tweets = JSON.parse(open(url).read)
