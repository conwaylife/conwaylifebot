require 'csv'
require 'open-uri'

namespace :catagolue do
  desc 'Update patterns'
  namespace :update do
    task asymmetric: :environment do
      url = "http://catagolue.appspot.com/textcensus/b3s23/C1"

      CSV.new(open(url).read(), headers: true, header_converters: :symbol).each do |data|
        p = Pattern.find_or_initialize_by(apgcode: data[:apgcode], symmetry: 'C1')
        p.update(data.to_hash)
      end
    end

    task symmetric: :environment do
      Pattern::SYMMETRIES.each do |symmetry|
        next if symmetry == 'C1'

        url = "http://catagolue.appspot.com/textcensus/b3s23/#{symmetry}"

        CSV.new(open(url).read(), headers: true, header_converters: :symbol).each do |data|
          p = Pattern.find_or_initialize_by(apgcode: data[:apgcode], symmetry: symmetry)
          p.update(data.to_hash)
        end
      end
    end
  end

  namespace :report do
    def bot
      @bot ||= Chatterbot::Bot.new
    end

    def update(pattern, text)
      if pattern.still_life? || pattern.oscillator? || pattern.spaceship?
        bot.client.update_with_media(text, pattern.image)
      else
        bot.tweet text
      end
    end

    desc 'Report interesting patterns in asymmetric soups'
    task asymmetric: :environment do
      Pattern.asymmetric.created_recently.select(&:interesting?).each do |p|
        update p, "New natural #{p.description} found by #{p.contributor} #{p.url}"
      end

      # Pattern.asymmetric.rare.updated_recently.select(&:interesting?).each do |p|
      #   update p, "New soup producing a rare #{p.description} #{p.url}"
      # end
    end

    desc 'Report interesting patterns in symmetric soups'
    task symmetric: :environment do
      Pattern.group(:apgcode).having('COUNT(delta) = ?', 0).each do |p|
        next unless p.symmetric? && p.interesting?
        update p, "New #{p.description} found in a symmetric soup #{p.url}"
      end

      Pattern.symmetric.undetermined.updated_recently.each do |p|
        next unless p.symmetric? && p.interesting?
        update p, "New symmetric soup producing #{p.description.with_indefinite_article} #{p.url}"
      end
    end
  end
end
