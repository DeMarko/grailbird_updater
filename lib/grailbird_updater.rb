require "grailbird_updater/version"

class GrailbirdUpdater

  KEEP_FIELDS = {'user' => ['name', 'screen_name', 'protected', 'id_str', 'profile_image_url_https', 'id', 'verified']}
  MAX_REQUEST_SIZE = 200
  PLATFORM_IS_OSX = (Object::RUBY_PLATFORM =~ /darwin/i) ? true : false

  class JsFile
    # Read UTF-8 file and return hash of contents (files being read contain JS arrays)
    #
    # @param file_path [String] path to file being read
    def self.read(file_path)
      file_contents = open(file_path).read.force_encoding("UTF-8").split("\n").join(" ")
      json_file_contents = file_contents.gsub(/^((var)?\s*(.+?)\s+=\s+)/m, '')
      return JSON.parse(json_file_contents)
    end

    # Checks if file being read exists, stops everything if it doesn't
    #
    # @param file_path [String] path to file being read
    # @raise [IOError] if the required file isn't found
    def self.read_required(file_path)
      raise IOError, "#{file_path} must exist" unless File.exists?(file_path)
      read(file_path)
    end

    # Write files Twitter's Archive app likes with specific headings
    #
    # @param contents [Object] object whose contents are to be written to the file
    # @param file_path [String] path to file being written
    # @param heading [String] heading for file, usually "var Something"
    def self.write_with_heading(contents, file_path, heading)
      json_pretty_contents = JSON.pretty_generate(contents)
      File.open(file_path, 'w') {|f| f.write("#{heading} = #{json_pretty_contents}")}
    end
  end

  class CsvFile
    # Write Twitter's archive CSV files
    # @param tweets [Array] all of the tweets you want to write to the file
    # @param file_path [String] path to file being written
    def self.write_tweets_csv (tweets, csv_path)
      CSV.open(csv_path, "w") do |csv|
        csv << ["tweet_id", "in_reply_to_status_id", "in_reply_to_user_id", "retweeted_status_id", "retweeted_status_user_id", "timestamp", "source", "text", "expanded_urls"]
        tweets.each do |tweet|
          csv << parse_tweet_into_csv_array(tweet)
        end
      end
    end

    # Auxiliary function that turns a Tweet hash array (a single tweet from the API,
    # encoded as a Hash) into the Array to write out to Twitter's CSV
    #
    # @param tweet [Hash] single tweet, encoded as a Hash
    # @return [Array] the tweet as an array
    def self.parse_tweet_into_csv_array (tweet)
      csv_tweet_array = [tweet["id"],
                        tweet["in_reply_to_status_id"],
                        tweet["in_reply_to_user_id"],
                        tweet.has_key?("retweeted_status") ? tweet["retweeted_status"]["id"] : '',
                        tweet.has_key?("retweeted_status") ? tweet["retweeted_status"]["user"]["id"] : '',
                        tweet["created_at"],
                        tweet["source"],
                        tweet["text"]];
      if tweet.has_key?("entities") && tweet["entities"].has_key?("urls")
          tweet["entities"]["urls"].each do |url|
              csv_tweet_array << url["expanded_url"]
          end
      end
      return csv_tweet_array
    end
  end

  def initialize(dir, verbose, prune, key_dir, write_csv)
    @base_dir = dir
    data_path = dir + "/data"
    @js_path = data_path + "/js"
    @csv_path = data_path + "/csv"
    @key_path = key_dir

    @write_csv = write_csv
    @verbose = verbose
    @prune = prune
    @access_token = nil
  end

  def update_tweets
    # find user_id in data/js/user_details.js
    user_details = GrailbirdUpdater::JsFile.read_required("#{@js_path}/user_details.js")
    user_id = user_details["id"]
    screen_name = user_details["screen_name"]
    vputs "Twitter Archive for " + "@#{screen_name}".light_blue + " (##{user_id}) found"

    # find archive details
    archive_details = GrailbirdUpdater::JsFile.read_required("#{@js_path}/payload_details.js")
    vputs "Found archive payload containing #{archive_details['tweets']} tweets, created at #{archive_details['created_at']}"

    # find latest month file (should be last when sorted alphanumerically)
    twitter_js_files = Dir.glob("#{@js_path}/tweets/*.js")
    latest_month = GrailbirdUpdater::JsFile.read_required(twitter_js_files.sort.last)

    # find last_tweet_id in latest_month (should be first, because Twitter)
    last_tweet = latest_month.first
    last_tweet_id = last_tweet["id_str"]

    vputs "Last tweet in archive is\n\t" + display_tweet(last_tweet)

    tweets = get_twitter_user_timeline_response(screen_name, user_id, last_tweet_id)

    vputs "There have been #{tweets.length} tweets since the archive" + (archive_details.has_key?('updated_at') ? " was last updated on #{archive_details['updated_at']}" : " was created")

    # collect tweets by year_month
    collected_months = Hash.new
    tweets.each do |tweet|
      tweet = prune_tweet(tweet) if @prune
      vputs "\t" + display_tweet(tweet)
      tweet_date = Date.parse(tweet["created_at"])
      hash_index = tweet_date.strftime('%Y_%m')
      collected_months[hash_index] = Array(collected_months[hash_index])
      collected_months[hash_index] << tweet
    end

    # add tweets to json data file
    tweet_index = GrailbirdUpdater::JsFile.read_required("#{@js_path}/tweet_index.js")
    collected_months.each do |year_month, month_tweets|
      month_path = "#{@js_path}/tweets/#{year_month}.js"

      existing_month_tweets = (File.exists?(month_path)) ? GrailbirdUpdater::JsFile.read(month_path) : []
      all_month_tweets = month_tweets | existing_month_tweets
      # sort new collection of tweets for this month by reverse date
      all_month_tweets.sort_by {|t| -Date.parse(t['created_at']).strftime("%s").to_i }

      # overwrite existing file (or create new if doesn't exist)
      GrailbirdUpdater::JsFile.write_with_heading(all_month_tweets, "#{@js_path}/tweets/#{year_month}.js", "Grailbird.data.tweets_#{year_month}")
      GrailbirdUpdater::CsvFile.write_tweets_csv(all_month_tweets, "#{@csv_path}/#{year_month}.csv") if @write_csv
      tweet_index = update_tweet_index(tweet_index, year_month, month_tweets.length)
    end

    # write new tweet_index.js once
    GrailbirdUpdater::JsFile.write_with_heading(tweet_index, "#{@js_path}/tweet_index.js", "var tweet_index")

    # add count to payload_details.js
    archive_details['tweets'] += tweets.length
    archive_details['updated_at'] = Time.now.getgm.strftime("%a %b %d %T %z %Y")
    GrailbirdUpdater::JsFile.write_with_heading(archive_details, "#{@js_path}/payload_details.js", "var payload_details")
  end

  def get_twitter_user_timeline_response(screen_name, user_id, last_tweet_id)
    twitter_url = "https://api.twitter.com/1.1/statuses/user_timeline.json"
    twitter_uri = URI(twitter_url)

    params = {
      :count => MAX_REQUEST_SIZE,
      :user_id => user_id,
      :since_id => last_tweet_id,
      :include_rts => true,
      :include_entities => true}
    twitter_uri.query = URI.encode_www_form(params)

    response = make_twitter_request(twitter_uri, screen_name)

    response_tweets = JSON.parse(response.body)

    total_tweets = Array.new

    while response_tweets.length > 0
      total_tweets += response_tweets
      last_tweet_returned = response_tweets.last
      params[:max_id] = last_tweet_returned['id'] - 1 # this way the response doesn't include the last tweet from the previous one
      twitter_uri.query = URI.encode_www_form(params)

      response = make_twitter_request(twitter_uri, screen_name)
      response_tweets = JSON.parse(response.body)
    end

    return total_tweets
  end

  def make_twitter_request(twitter_uri, screen_name)
    vputs "\nMaking request to #{twitter_uri}\n"

    if !@access_token.nil?
      response = @access_token.request(:get, twitter_uri.to_s)
    else
      @access_token = do_oauth_dance(screen_name)
      response = @access_token.request(:get, twitter_uri.to_s)
    end

    if response.is_a?(Net::HTTPUnauthorized)
      puts "\nSomething went wrong trying to authorize grailbird_updater with the account: " + "@#{screen_name}".blue
      puts "Please delete #{@key_path}/#{screen_name}_keys.yaml and follow the authorize steps again."
      exit
    end

    return response
  end

  def do_oauth_dance(screen_name)
    key_file_path = "#{@key_path}/#{screen_name}_keys.yaml"

    if File.exists?(key_file_path)
        keys = YAML.load_file(key_file_path)
        consumer_key = keys['consumer_key']
        consumer_secret = keys['consumer_secret']
        token = keys['token']
        token_secret = keys['secret']
    else
      puts <<-EOS
\nTo be able to retrieve your protected tweets, you will need a consumer key/secret

Please follow these steps to authorize grailbird_updater to download tweets:
    1. Go to https://apps.twitter.com/apps/new
    2. Give it a name (I recommend #{screen_name}_grailbird), description and URL
    3. Create application
    4. Go to your application page, you should see a "Consumer key" and a "Consumer secret"
    5. Enter these here when prompted, go to the URL provided then enter the PIN you receive

#{"Note".underline}: you will only need to create this application once!

So you don't have to enter these again, we'll save a copy of your keys to:
    #{key_file_path}

You can always change the directory these are saved to by using the -k or --key-path option

#{"WARNING".red.underline} Do NOT store the folder of your tweets on a public server.
    If someone gets access to #{screen_name}_keys.yaml they can access your entire account!
    If you want to share your archived tweets, either control the read access to the key file
    OR use the --key-path option to store them somewhere else.
EOS

      print_flush "\nEnter your 'Consumer key': "
      consumer_key = STDIN.gets.chomp
      print_flush "Enter your 'Consumer secret': "
      consumer_secret = STDIN.gets.chomp
      consumer = OAuth::Consumer.new(
        consumer_key,
        consumer_secret,
        { :site => 'https://api.twitter.com/',
          :request_token_path => '/oauth/request_token',
          :access_token_path => '/oauth/access_token',
          :authorize_path => '/oauth/authorize' }
      )
      request_token = consumer.get_request_token
      authorize_url = request_token.authorize_url()
      puts "\nGo to this URL: #{authorize_url}"
      puts "Authorize the application and you will receive a PIN"
      # open default browser if on OS X
      if PLATFORM_IS_OSX
        sleep(2)
        `open "#{authorize_url}"`
      end

      print_flush "Enter the PIN here: "
      pin = STDIN.gets.chomp
      access_token = request_token.get_access_token(:oauth_verifier => pin)

      token = access_token.token
      token_secret = access_token.secret
      tokens = {
        'consumer_key' => consumer_key,
        'consumer_secret' => consumer_secret,
        'token' => token,
        'secret' => token_secret}
      File.open(key_file_path, 'w+') {|f| f.write(tokens.to_yaml) }
    end

    # Exchange our oauth_token and oauth_token secret for the AccessToken instance.
    access_token = prepare_access_token(consumer_key, consumer_secret, token, token_secret)
  end

  def prepare_access_token(consumer_key, consumer_secret, oauth_token, oauth_token_secret)
    consumer = OAuth::Consumer.new(consumer_key, consumer_secret,
      { :site => "https://api.twitter.com",
        :scheme => :header
      })
    # now create the access token object from passed values
    token_hash = {:oauth_token => oauth_token,
                  :oauth_token_secret => oauth_token_secret
                }
    access_token = OAuth::AccessToken.from_hash(consumer, token_hash )
    return access_token
  end

  def prune_tweet(tweet)
    KEEP_FIELDS.each do |parent_field, field_names|
      tweet[parent_field].delete_if { |key, value| !field_names.include?(key) }
    end
    return tweet
  end

  def display_tweet(tweet)
    tweet = tweet["retweeted_status"] if tweet.has_key?("retweeted_status")
    tweet_text = tweet['text']
    if tweet['entities'] && tweet['entities']['urls']
      tweet['entities']['urls'].each { |url_entity|
        tweet_text = tweet['text'].gsub("#{url_entity['url']}", "#{url_entity['expanded_url']}")
      }
    end
    tweet = "@#{tweet['user']['screen_name']}".blue + ": #{tweet_text}\n"
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
    return tweet_index.unshift(new_month).sort_by {|m| [-m['year'], -m['month']]}
  end

  private

  # only puts if we're verbose
  def vputs(str)
    puts str if @verbose
  end

  def print_flush(str)
    print str
    $stdout.flush
  end
end

