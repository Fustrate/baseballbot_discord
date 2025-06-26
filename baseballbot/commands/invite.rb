# frozen_string_literal: true

module BaseballDiscord
  module Commands
    module Invite
      def self.register(bot)
        bot.application_command(:invite_url) { InviteCommand.new(it).run }
      end

      # Allows the administrator to invite this bot to a server
      class InviteCommand < SlashCommand
        def run
          return error_message('Restricted command') unless user.id == BaseballDiscord::Bot::ADMIN_ID

          respond_with content: bot.invite_url, ephemeral: true
        end
      end
    end
  end
end
