# frozen_string_literal: true

module BaseballDiscord
  module Commands
    module Username
      def self.register(bot)
        bot.application_command(:username) { UsernameCommand.new(_1).run }
      end

      # Allows the administrator to invite this bot to a server
      class UsernameCommand < SlashCommand
        def run
          username = options['username'].gsub(/[^a-zA-Z]/, '').presence

          raise UserError, 'Username contains invalid characters or is blank.' unless username

          tag = member.nick.match(/(?<tag>\[.*\])$/)

          full_username = [username, tag ? tag[:tag] : nil].compact.join(' ')

          raise UserError, 'Username is too long.' if full_username.length > 32

          member.nick = full_username

          respond_with content: "Your username has been changed to **#{full_username}**.", ephemeral: true
        end
      end
    end
  end
end
