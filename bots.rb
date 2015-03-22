require 'dotenv'
require 'httparty'
require 'nokogiri'
require 'open-uri'
require 'twitter_ebooks'

Dotenv.load(".env")

CONSUMER_KEY = ENV['EBOOKS_CONSUMER_KEY']
CONSUMER_SECRET = ENV['EBOOKS_CONSUMER_SECRET']
OAUTH_TOKEN = ENV['EBOOKS_OAUTH_TOKEN']
OAUTH_TOKEN_SECRET = ENV['EBOOKS_OAUTH_TOKEN_SECRET']

def roadkill?(meerkat)
  begin
    doc = Nokogiri::HTML(open(meerkat))

    stream_url = doc.xpath("//meta[@name='twitter:app:url:iphone']/@content")
                    .to_s
                    .split('/')
                    .last

    api_base_url = 'http://resources.meerkatapp.co/'

    response        = HTTParty.get(api_base_url + 'broadcasts/' + stream_url + '/summary')
    broadcast_info  = JSON.parse(response.body)
    broadcast_info['result']['status'] == 'ended'
  rescue
    false
  end
end

class MyBot < Ebooks::Bot
  def configure
    self.consumer_key = CONSUMER_KEY
    self.consumer_secret = CONSUMER_SECRET

    self.blacklist = ['appmeerkat']
    self.delay_range = 10..30
  end

  def dead_response
    "|STREAM OVER| Looks like we've got ourselves a dead meerkat. Mind cleaning up the mess?"
  end

  def reply_response
    "This is an automated service by @prestonrichey. Feel free to get in contact."
  end

  def on_startup
    # Run every 30 min
    scheduler.cron '0, 15, 30, 45 * * * *' do
      twitter.search("'|LIVE NOW|' meerkat", result_type: 'recent').each do |tweet|
        delay do
          url = tweet.text.split(' ').last
          if roadkill? url
            reply(tweet, dead_response)
          end
        end
      end
    end
  end

  def on_mention(tweet)
    reply(tweet, reply_response)
  end
end

# Make a MyBot and attach it to an account
MyBot.new("roadkillbot") do |bot|
  bot.access_token = OAUTH_TOKEN
  bot.access_token_secret = OAUTH_TOKEN_SECRET
end
