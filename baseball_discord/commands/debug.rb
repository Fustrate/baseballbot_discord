# frozen_string_literal: true

module BaseballDiscord
  module Commands
    # Basic debug commands that should log to the output file
    module Debug
      extend Discordrb::Commands::CommandContainer

      command(:debug, help_available: false) do |event|
        if event.server.id == BaseballDiscord::Bot::SERVER_ID
          @logger.debug event.server.inspect
        end

        nil
      end
    end
  end
end
