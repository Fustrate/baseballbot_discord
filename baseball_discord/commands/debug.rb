# frozen_string_literal: true

module BaseballDiscord
  module Commands
    # Basic debug commands that should log to the output file
    module Debug
      extend Discordrb::Commands::CommandContainer

      command(:debug, help_available: false) do |event, *args|
        DebugCommand.new(event, *args).debug
      end

      # Prints some basic info to the log file
      class DebugCommand < Command
        def debug
          return react_to_message('🔒') unless user.id == BaseballDiscord::Bot::ADMIN_ID

          log "Server: #{server.inspect}", level: :debug
          log "Message: #{message.inspect}", level: :debug

          react_to_message '✅'
        end
      end
    end
  end
end
