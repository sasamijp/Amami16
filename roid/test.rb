# -*- encoding:utf-8 -*-

require 'tweetstream'
require 'twitter'
require './responder.rb'

class Const
  CONSUMER_KEY       = 'sjgQvrc62MkU9gg0yCjsQ'
  CONSUMER_SECRET    = 'OR18Oyg4cqT9oz1OFosvrLVxbkcoD08rcanijA7Ng'
  ACCESS_TOKEN        = '978275298-nMUXlNVztlJZY36fSppAH1zVDk0W3GmUripNyDvP'
  ACCESS_TOKEN_SECRET = 'JHDIdh3rvcuqqHF5JxMhvaG1gGsyLLct2dAACkyDPQ' #sa2mi
end

rest = Twitter::REST::Client.new do |config|
  config.consumer_key        = Const::CONSUMER_KEY
  config.consumer_secret     = Const::CONSUMER_SECRET
  config.access_token        = Const::ACCESS_TOKEN
  config.access_token_secret = Const::ACCESS_TOKEN_SECRET
end
TweetStream.configure do |config|
  config.consumer_key        = Const::CONSUMER_KEY
  config.consumer_secret     = Const::CONSUMER_SECRET
  config.oauth_token         = Const::ACCESS_TOKEN
  config.oauth_token_secret  = Const::ACCESS_TOKEN_SECRET
  config.auth_method         = :oauth
end

client = TweetStream::Client.new
roids = {
    '春香' => {
        :responder => Responder.new('../db/main.db'),
        :icon => open('../icons/haruka.png', "r")
    },
    '千早' => {
        :responder => Responder.new('../db/main_c.db'),
        :icon => open('../icons/chihaya.png', 'r')
    }
}

responder = roids['春香'][:responder]
#rest.update_profile_image(roids['春香'][:icon])

pp roids["春香"][:responder].respond("おはよう")
pp roids["千早"][:responder].respond("おはよう")
pp roids["春香"][:responder].respond("おはよう")

loop do
  text = gets.chomp
  next if text.start_with?('RT')
  if text.include?('@sa2mi ch ')
    p roids[text.sub('@sa2mi ch ', '').gsub('!!', '')]
    responder = roids[text.sub('@sa2mi ch ', '').gsub('!!', '')][:responder]
    p responder
    Thread.new {
      #rest.update_profile_image(roids[status.text.sub('@sa2mi ch ', '').gsub('!!', '')][:icon])
      text = "changed#{'!'*rand(100)}"
      puts text
      #option = {:in_reply_to_status_id => status.id.to_s}
      #rest.update text, option
    }
  elsif text.include?('@sa2mi')
    pp responder
    res = responder.respond(text.gsub(/@sa2mi/i, ''))
    Thread.new {
      text = res
      #option = {:in_reply_to_status_id => status.id.to_s}
      #rest.update text, option
      puts text
    }
  end
end
