# frozen_string_literal: true

module BaseballDiscord
  module Commands
    # Basic debug commands that should log to the output file
    module Debug
      def self.register(bot)
        bot.application_command(:debug) { DebugCommand.new(_1).run }
      end

      class DebugCommand < SlashCommand
        TYPES = %w[channel emoji message pm react server user].freeze

        def run
          if TYPES.include?(event.options['type'])
            public_send "debug_#{event.options['type']}"
          else
            event.respond content: 'Unknown type', ephemeral: true
          end
        end

        def debug_channel = event.respond(content: event.channel.inspect, ephemeral: true)

        def debug_emoji
          emojis = YAML.safe_load_file(File.expand_path("#{__dir__}/../../config/emoji.yml")).values.map { "<#{_1}>" }

          event.respond content: emojis.join(' '), ephemeral: true
        end

        def debug_message = event.respond(content: event.message.inspect, ephemeral: true)

        def debug_pm = send_pm('Hello!')

        def debug_react = react_to_message('✅')

        def debug_server = event.respond(content: event.server.inspect, ephemeral: true)

        def debug_user = event.respond(content: event.user.inspect, ephemeral: true)
      end
    end
  end
end
