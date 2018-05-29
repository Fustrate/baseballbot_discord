# frozen_string_literal: true

module BaseballDiscord
  module Commands
    # Basic debug commands that should log to the output file
    module Debug
      extend Discordrb::Commands::CommandContainer

      command(:debug, help_available: false) do |event, *args|
        DebugCommand.new(event, *args).debug
      end

      command(:debug_verify, help_available: false) do |event, *args|
        DebugCommand.new(event, *args).debug_verify
      end

      command(:debug_welcome, help_available: false) do |event, *_args|
        # Must be run on an actual server
        return unless event.server

        BaseballDiscord::Commands::Verify::RedditAuthCommand.new(event)
          .send_welcome_pm
      end

      # Prints some basic info to the log file
      class DebugCommand < Command
        def debug
          # return unless server&.id == BaseballDiscord::Bot::SERVER_ID

          log "Server: #{server.inspect}", level: :debug
          log "Message: #{message.inspect}", level: :debug

          react_to_message '✅'
        end

        def debug_verify
          member = bot.server(server.id).member(user.id)

          verified_role = bot.class::VERIFIED_ROLES[server.id]

          member.add_role verified_role # , 'User verified their reddit account'
          member.nickname = "#{user.name} bloop" # , 'Syncing reddit username'

          react_to_message '✅'
        end
      end
    end
  end
end
