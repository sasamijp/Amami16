# -*- encoding:utf-8 -*-

require 'tweetstream'
require 'twitter'
require './responder.rb'








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
        :responder => Responder.new('../db/main2.db'),
        :icon => open('../icons/haruka.png', "r")
    },
    '千早' => {
        :responder => Responder.new('../db/main_c.db'),
        :icon => open('../icons/chihaya.png', 'r')
    }
}

responder = roids['春香'][:responder]
rest.update_profile_image(roids['春香'][:icon])

client.userstream do |status|
  p status.text
  next if status.text.start_with?('RT')
  if status.text.include?('@sa2mi ch ')
    responder = roids[status.text.sub('@sa2mi ch ', '').gsub('!!', '')][:responder]
    Thread.new {
      rest.update_profile_image(roids[status.text.sub('@sa2mi ch ','').gsub('!!', '')][:icon])
      text = "@#{status.user.screen_name} changed#{'!'*rand(100)}"
      option = {:in_reply_to_status_id => status.id.to_s}
      rest.update text, option
    }
  elsif status.text.include?('@sa2mi')
    res = responder.respond(status.text.gsub(/@sa2mi/i, ''), status.user.screen_name)
    Thread.new {
      text = "@#{status.user.screen_name} #{res}"
      option = {:in_reply_to_status_id => status.id.to_s}
      rest.update text, option
    }
  end
end
