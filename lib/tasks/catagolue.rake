require 'csv'
require 'open-uri'

namespace :catagolue do
  desc 'Update patterns'
  task update: :environment do
    Pattern::SYMMETRIES.each do |symmetry|
      url = "http://catagolue.appspot.com/textcensus/b3s23/#{symmetry}"

      CSV.new(open(url).read(), headers: true, header_converters: :symbol).each do |data|
        p = Pattern.find_or_initialize_by(apgcode: data[:apgcode], symmetry: symmetry)
        p.update(data.to_hash)
      end
    end
  end

  desc 'Report interesting patterns'
  task report: :environment do
    bot = Chatterbot::Bot.new

    Pattern.asymmetric.created_recently.select(&:interesting?).each do |p|
      bot.tweet "New natural #{p.description} #{p.url}"
    end

    Pattern.asymmetric.rare.updated_recently.select(&:interesting?).each do |p|
      bot.tweet "New soup producing a rare #{p.description} #{p.url}"
    end

    Pattern.group(:apgcode).having('COUNT(delta) = ?', 0).each do |p|
      next unless p.symmetric? && p.interesting?
      bot.tweet "New #{p.description} found in a symmetric soup #{p.url}"
    end
  end
end
