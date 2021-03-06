require 'csv'
require 'open-uri'

namespace :catagolue do
  desc 'Update patterns'
  namespace :update do
    task asymmetric: :environment do
      url = "http://catagolue.appspot.com/textcensus/b3s23/C1/since/#{Publication.timestamp('C1').to_date.iso8601}"

      CSV.new(open(url).read(), headers: true, header_converters: :symbol).each do |data|
        next if data[:apgcode].include?('Total objects')

        p = Pattern.find_or_initialize_by(apgcode: data[:apgcode], symmetry: 'C1')
        p.update(data.to_hash)
      end
    end

    task symmetric: :environment do
      Pattern::SYMMETRIES.each do |symmetry|
        next if symmetry == 'C1'

        url = "http://catagolue.appspot.com/textcensus/b3s23/#{symmetry}/since/#{Publication.timestamp(symmetry).to_date.iso8601}"

        CSV.new(open(url).read(), headers: true, header_converters: :symbol).each do |data|
          next if data[:apgcode].include?('Total objects')

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

    def write_timestamp(symmetry)
      Publication.find_or_initialize_by(symmetry: symmetry).touch
    end

    desc 'Report interesting patterns in asymmetric soups'
    task asymmetric: :environment do
      Pattern.asymmetric.created_recently.select(&:interesting?).each do |p|
        contributor = p.contributor
        update p, "New natural #{p.description}#{contributor ? " found by #{contributor}" : ""} #{p.url}"
      end

      # Pattern.asymmetric.rare.updated_recently.select(&:interesting?).each do |p|
      #   update p, "New soup producing a rare #{p.description} #{p.url}"
      # end

      write_timestamp('C1')
    end

    desc 'Report interesting patterns in symmetric soups'
    task symmetric: :environment do
      counts = Pattern.symmetric.where('apgcode NOT LIKE ?', 'xs%').created_recently.group(:apgcode).count
      totals = Pattern.where(apgcode: counts.keys).group(:apgcode).count

      counts.each do |apgcode, count|
        next if count < totals[apgcode]

        p = Pattern.new(apgcode: apgcode, symmetry: 'D8_4') # any symmetric
        next unless p.interesting?

        update p, "New #{p.description} found in a symmetric soup #{p.url}"
      end

      Pattern.symmetric.undetermined.created_recently.each do |p|
        next unless p.interesting?
        update p, "New symmetric soup producing #{p.description.with_indefinite_article} #{p.url}"
      end

      Pattern::SYMMETRIES.each(&method(:write_timestamp))
    end
  end
end
