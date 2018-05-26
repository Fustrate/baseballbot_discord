# frozen_string_literal: true

module BaseballDiscord
  module Commands
    # Basic debug commands that should log to the output file
    module Debug
      extend Discordrb::Commands::CommandContainer

      command(:debug, help_available: false) do |event|
        # event.server&.id == BaseballDiscord::Bot::SERVER_ID

        event.message.react '✅'

        event.bot.logger.debug 'Debug Info:'
        event.bot.logger.debug "\tServer: #{event.server.inspect}"
        event.bot.logger.debug "\tUser: #{event.user.distinct}"

        nil
      end
    end
  end
end
