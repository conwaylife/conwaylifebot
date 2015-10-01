require 'open-uri'

module Concerns
  module Contributed
    @@contributors = YAML.load_file(Rails.root.join(*%w[ config contributors.yml ]))

    def contributor
      name = open(contributors_url).read.match(%r{is owned by (.+)})[1]
      @@contributors.fetch(name) do |name|
        if name.match(%r{\A@\w+\z})
          name
        else
          "'#{name.sub(%r{@.*}, '')}'"
        end
      end
    end

    private

    def contributors_url
      ENV['contributors_url'] % apgcode
    end
  end
end
