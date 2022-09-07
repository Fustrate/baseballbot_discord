# frozen_string_literal: true

module BaseballDiscord
  module Commands
    # Basic debug commands that should log to the output file
    module Debug
      def self.register(bot)
        bot.application_command(:debug) do |event|
          if event.options['type'] == 'emoji'
            emojis = YAML.safe_load_file(File.expand_path("#{__dir__}/../config/emoji.yml")).values.map { "<#{_1}>" }

            event.respond content: emojis.join(' ')
          else
            event.respond content: 'Unknown type', ephemeral: true
          end
        end
      end
    end
  end
end
