#!/usr/bin/env ruby
require 'rubygems'
require 'open-uri'
require 'json'
require 'trollop'
require 'pp'
require 'colorize' # if verbose

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

data_path = dir + "/data"
js_path = data_path + "/js"
csv_path = data_path + "/csv"

def read_required_twitter_js_file(file_path)
    raise "#{file_path} must exist" unless  File.exists?(file_path)
    read_twitter_js_file(file_path)
end

def read_twitter_js_file(file_path)
    file_contents = open(file_path).read.split("\n").join(" ")
    json_file_contents = file_contents.gsub(/^((var)?\s*(.+?)\s+=\s+)/m, '')
    json = JSON.parse(json_file_contents)
end

def display_tweet(tweet)
    if tweet['entities'] && tweet['entities']['urls']
        tweet['entities']['urls'].each { |url_entity|
            tweet['text'] = tweet['text'].gsub("#{url_entity['url']}", "#{url_entity['expanded_url']}")
        }
    end
    tweet = "@#{tweet['user']['screen_name']}".blue + ": \"#{tweet['text']}\"\n"
end

# find user_id in data/js/user_details.js
user_details = read_required_twitter_js_file(js_path + "/user_details.js")
user_id = user_details["id"]
screen_name = user_details["screen_name"]
puts "Twitter Archive for " + "@#{screen_name}".light_blue + " (##{user_id}) found"

# find archive details
archive_details = read_required_twitter_js_file(js_path + "/payload_details.js")
puts "Found archive payload containing #{archive_details['tweets']} tweets, created at #{archive_details['created_at']}"

# find latest month file (should be last when sorted alphanumerically)
twitter_js_files = Dir.glob("#{js_path}/tweets/*.js")
latest_month = read_required_twitter_js_file(twitter_js_files.sort.last)

# find last_tweet_id in latest_month (should be first, because Twitter)
last_tweet = latest_month.first
last_tweet_id = last_tweet["id_str"]
last_tweet_date = Date.parse(last_tweet["created_at"])

puts "Last tweet in archive is\n\t" + display_tweet(last_tweet)

# get response from API
twitter_url = "http://api.twitter.com/1/statuses/user_timeline.json?count=#{count}&user_id=#{user_id}&since_id=#{last_tweet_id}&include_rts=true"
puts "Making request to #{twitter_url}"
tweets = JSON.parse(open(twitter_url).read)

puts "There have been #{tweets.length} tweets since the archive" + (archive_details.has_key?('updated_at') ? " was last updated on #{archive_details['updated_at']}" : " was created")

# collect tweets by year_month
collected_months = Hash.new
tweets.each do |tweet|
    tweet_date = Date.parse(tweet["created_at"])
    hash_index = tweet_date.strftime('%Y_%m')
    if collected_months[hash_index].respond_to? :<<
        collected_months[hash_index] << tweet
    else
        collected_months[hash_index] = [tweet]
    end
end

pp collected_months

# add tweets to json data file and csv data file
    # if tweets returned contain new month, create new month files, add file location to tweet_index.js 
# add count to tweet_index.js, payload_details.js

