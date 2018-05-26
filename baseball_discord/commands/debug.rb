# frozen_string_literal: true

module BaseballDiscord
  module Commands
    # Basic debug commands that should log to the output file
    module Debug
      extend Discordrb::Commands::CommandContainer

      command(:debug, help_available: false) do |event|
        # event.server&.id == BaseballDiscord::Bot::SERVER_ID

        event.message.react '✅'

        prefix = "[#{event.message.id}] [#{event.user.distinct}]"

        event.bot.logger.debug "#{prefix} Debug Info:"
        event.bot.logger.debug "#{prefix} Server: #{event.server.inspect}"
        event.bot.logger.debug "#{prefix} User: #{event.user.distinct}"

        nil
      end
    end
  end
end
