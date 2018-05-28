# frozen_string_literal: true

module BaseballDiscord
  module Commands
    # Basic debug commands that should log to the output file
    module Invite
      extend Discordrb::Commands::CommandContainer

      command(
        :invite,
        help_available: false,
        min_args: 1,
        max_args: 1
      ) do |event, *args|
        InviteCommand.new(event, *args).accept_invite
      end

      # Prints some basic info to the log file
      class InviteCommand < Command
        def accept_invite
          unless user.id == BaseballDiscord::Bot::ADMIN_ID
            return react_to_message '🔒'
          end

          bot.join args.join('')

          react_to_message '✅'
        end
      end
    end
  end
end
