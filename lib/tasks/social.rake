namespace :social do
  desc 'Retweet messages that mention the bot'
  task retweet: :environment do
    bot = Chatterbot::Bot.new

    friend_ids = bot.client.friends.collect(&:id)
    bot.replies do |tweet|
      if tweet.user.id.in?(friend_ids)
        bot.retweet(tweet.id)
      end
    end
  end

  desc 'Favorite tweets that mention Conway\'s Game of Life'
  task favorite: :environment do
    bot = Chatterbot::Bot.new
    bot.blacklist = %w{ alcheagle golautomat deetahanator }

    bot.search('conway game of life') do |tweet|
      bot.favorite(tweet)
    end
  end
end
