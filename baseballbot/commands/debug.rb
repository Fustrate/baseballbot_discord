# frozen_string_literal: true

module BaseballDiscord
  module Commands
    # Basic debug commands that should log to the output file
    module Debug
      def self.register(bot)
        bot.application_command(:debug) { DebugCommand.new(_1).run }
      end

      class DebugCommand < SlashCommand
        TYPES = %w[channel emoji pm server user].freeze

        def run
          if TYPES.include?(options['type'])
            public_send :"debug_#{options['type']}"
          else
            respond_with content: 'Unknown type', ephemeral: true
          end
        end

        def debug_channel
          log channel.inspect

          respond_with content: 'Check the logs!', ephemeral: true
        end

        def debug_emoji
          emojis = YAML.safe_load_file(File.expand_path("#{__dir__}/../../config/emoji.yml")).values.map { "<#{_1}>" }

          respond_with content: emojis.join(' '), ephemeral: true
        end

        def debug_pm = send_pm('Hello!')

        def debug_server
          log server.inspect

          respond_with content: 'Check the logs!', ephemeral: true
        end

        def debug_user
          log user.inspect

          respond_with content: 'Check the logs!', ephemeral: true
        end
      end
    end
  end
end
