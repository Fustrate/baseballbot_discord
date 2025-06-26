# frozen_string_literal: true

module BaseballDiscord
  module Commands
    module Username
      PROFANITY = /
        faggot|nigga|cunt|nigger|retard|bootlick|trump|chink|republican|democrat|maga|snowflake|libtard|qanon|antifa|
        incel
      /ix

      def self.register(bot)
        bot.application_command(:username) { UsernameCommand.new(it).run }
      end

      # Allows the administrator to invite this bot to a server
      class UsernameCommand < SlashCommand
        def run
          username = options['username'].gsub(/[^a-zA-Z0-9_-]/, '').strip

          raise UserError, 'Username contains invalid characters or is blank.' if username.empty?

          tag = user.nick.match(/(?<tag>\[.*\])$/)

          change_username!([username, tag ? tag[:tag] : nil].compact.join(' '))
        rescue UserError => e
          error_message e.message
        end

        protected

        def change_username!(username)
          raise UserError, 'Username is too long.' if username.length > 32

          raise UserError, 'Username is invalid.' if username.match?(PROFANITY)

          user.nick = username

          respond_with content: "Your username has been changed to **#{username}**.", ephemeral: true
        rescue Discordrb::Errors::NoPermission
          raise UserError, "The bot doesn't have permission to change your username to #{username}."
        end
      end
    end
  end
end
