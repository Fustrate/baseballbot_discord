# frozen_string_literal: true

module BaseballDiscord
  module Commands
    # Basic debug commands that should log to the output file
    module Debug
      extend Discordrb::Commands::CommandContainer

      command(:debug, help_available: false) do |event|
        DebugCommand.new(event).run
      end

      # Prints some basic info to the log file
      class DebugCommand < Command
        def run
          # return unless server&.id == BaseballDiscord::Bot::SERVER_ID

          log "Server: #{server.inspect}", :debug
          log "Message: #{message.inspect}", :debug

          react_to_message '✅'
        end
      end
    end
  end
end
