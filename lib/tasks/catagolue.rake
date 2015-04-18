require 'csv'
require 'open-uri'

namespace :catagolue do
  desc 'Update patterns'
  task update: :environment do
    url = 'http://catagolue.appspot.com/textcensus/b3s23/C1'

    CSV.new(open(url).read(), headers: true, header_converters: :symbol).each do |data|
      p = Pattern.find_or_initialize_by(apgcode: data[:apgcode])
      p.update(data.to_hash)
    end
  end

  desc 'Report interesting patterns'
  task report: :environment do
    bot = Chatterbot::Bot.new

    bot.no_update = true
    bot.verbose = true

    Pattern.created_recently.each do |p|
      next if p.still_life? && p.cells < 30

      bot.tweet "New natural #{p.description} #{p.url}"
    end

    Pattern.rare.updated_recently.each do |p|
      next if p.still_life?

      bot.tweet "New soup producing a rare #{p.description} #{p.url}"
    end
  end
end
