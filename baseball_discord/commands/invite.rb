# frozen_string_literal: true

module BaseballDiscord
  module Commands
    module Invite
      extend Discordrb::Commands::CommandContainer

      command(:invite_url, help_available: false) do |event, *args|
        InviteCommand.new(event, *args).send_invite_url
      end

      # Allows the administrator to invite this bot to a server
      class InviteCommand < Command
        def send_invite_url
          unless user.id == BaseballDiscord::Bot::ADMIN_ID
            return react_to_message '🔒'
          end

          bot.invite_url
        end
      end
    end
  end
end
