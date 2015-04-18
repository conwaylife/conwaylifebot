module Chatterbot
  module Config
    def config_file
      Rails.root.join('config/chatterbot.yml')
    end
  end
end
