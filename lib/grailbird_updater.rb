require "grailbird_updater/version"

class GrailbirdUpdater

  def initialize(data_path, js_path, csv_path)
    @data_path = data_path
    @js_path = js_path
    @csv_path = csv_path
  end

  def update_tweets
    # find user_id in data/js/user_details.js
    user_details = read_required_twitter_js_file("#{@js_path}/user_details.js")
    user_id = user_details["id"]
    screen_name = user_details["screen_name"]
    puts "Twitter Archive for " + "@#{screen_name}".light_blue + " (##{user_id}) found" if verbose

    # find archive details
    archive_details = read_required_twitter_js_file("#{@js_path}/payload_details.js")
    puts "Found archive payload containing #{archive_details['tweets']} tweets, created at #{archive_details['created_at']}" if verbose

    # find latest month file (should be last when sorted alphanumerically)
    twitter_js_files = Dir.glob("#{@js_path}/tweets/*.js")
    latest_month = read_required_twitter_js_file(twitter_js_files.sort.last)

    # find last_tweet_id in latest_month (should be first, because Twitter)
    last_tweet = latest_month.first
    last_tweet_id = last_tweet["id_str"]
    last_tweet_date = Date.parse(last_tweet["created_at"])

    puts "Last tweet in archive is\n\t" + display_tweet(last_tweet) if verbose

    # get response from API
    twitter_url = "http://api.twitter.com/1/statuses/user_timeline.json?count=#{count}&user_id=#{user_id}&since_id=#{last_tweet_id}&include_rts=true"
    puts "Making request to #{twitter_url}" if verbose
    tweets = JSON.parse(open(twitter_url).read)

    puts "There have been #{tweets.length} tweets since the archive" + (archive_details.has_key?('updated_at') ? " was last updated on #{archive_details['updated_at']}" : " was created") if verbose

    # collect tweets by year_month
    collected_months = Hash.new
    tweets.each do |tweet|
        puts "\t" + display_tweet(tweet) if verbose
        tweet_date = Date.parse(tweet["created_at"])
        hash_index = tweet_date.strftime('%Y_%m')
        collected_months[hash_index] = Array(collected_months[hash_index])
        collected_months[hash_index] << tweet
    end

    # add tweets to json data file and csv data file
    tweet_index = read_required_twitter_js_file("#{@js_path}/tweet_index.js")
    collected_months.each do |year_month, month_tweets|
        month_path = "#{@js_path}/tweets/#{year_month}.js"

        existing_month_tweets = (File.exists?(month_path)) ? read_twitter_js_file(month_path) : []
        all_month_tweets = month_tweets | existing_month_tweets
        # sort new collection of tweets for this month by reverse date
        all_month_tweets.sort_by {|t| -Date.parse(t['created_at']).strftime("%s").to_i }

        # overwrite existing file (or create new if doesn't exist)
        write_twitter_js_to_path_with_heading(all_month_tweets, "#{@js_path}/tweets/#{year_month}.js", "Grailbird.data.tweets_#{year_month}")
        tweet_index = update_tweet_index(tweet_index, year_month, month_tweets.length)
    end

    # write new tweet_index.js once
    write_twitter_js_to_path_with_heading(tweet_index, "#{@js_path}/tweet_index.js", "var tweet_index")

    # add count to payload_details.js
    archive_details['tweets'] += tweets.length
    archive_details['updated_at'] = Time.now.getgm.strftime("%a %b %d %T %z %Y")
    write_twitter_js_to_path_with_heading(archive_details, "#{@js_path}/payload_details.js", "var payload_details")
  end

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

  def update_tweet_index(tweet_index, year_month, count)
      year, month = year_month.split('_')
      year = year.to_i
      month = month.to_i
      tweet_index.each do |index_month|
          if index_month['year'] == year && index_month['month'] == month
              index_month['tweet_count'] += count
              return tweet_index
          end
      end

      new_month = {"file_name" => "data/js/tweets/#{year_month}.js",
                   "year" => year,
                   "var_name" => "tweets_#{year_month}",
                   "tweet_count" => count,
                   "month" => month
                  }
      new_index = tweet_index.unshift(new_month).sort_by {|m| [-m['year'], -m['month']]}

  end

  def write_twitter_js_to_path_with_heading(contents, path, heading)
      json_pretty_contents = JSON.pretty_generate(contents)
      File.open(path, 'w') {|f| f.write("#{heading} = #{json_pretty_contents}")}
  end
end

