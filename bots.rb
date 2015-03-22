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
  doc = Nokogiri::HTML(open(meerkat))

  stream_url = doc.xpath("//meta[@name='twitter:app:url:iphone']/@content")
                  .to_s
                  .split('/')
                  .last

  api_base_url = 'http://resources.meerkatapp.co/'

  response        = HTTParty.get(api_base_url + 'broadcasts/' + stream_url + '/summary')
  broadcast_info  = JSON.parse(response.body)
  broadcast_info['result']['status'] == 'ended'
end

class MyBot < Ebooks::Bot
  def configure
    self.consumer_key = CONSUMER_KEY
    self.consumer_secret = CONSUMER_SECRET

    self.blacklist = ['appmeerkat']
    self.delay_range = 1..6
  end

  def on_startup
    # Run every hour
    scheduler.cron '0 * * * *' do
      # See https://github.com/jmettraux/rufus-scheduler
      # tweet("hi")
      # pictweet("hi", "cuteselfie.jpg")
    end
  end
end

# Make a MyBot and attach it to an account
MyBot.new("roadkillbot") do |bot|
  bot.access_token = OAUTH_TOKEN
  bot.access_token_secret = OAUTH_TOKEN_SECRET
end
