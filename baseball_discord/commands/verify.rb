# frozen_string_literal: true

module BaseballDiscord
  module Commands
    # Basic debug commands that should log to the output file
    module Verify
      extend Discordrb::Commands::CommandContainer

      command(:verify) do |event, *args|
        RedditAuthCommand.new(event, *args).run
      end

      class RedditAuthCommand < Command
        WELCOME_MESSAGE = <<~PM
          Welcome to the %<server_name>s Discord server!

          In order to join, please click the following link to verify your reddit account:

          %<auth_url>s

          This link is active for 7 days, after which you can message me with `!verify %<guild>s` to receive a new link.

          We look forward to getting to know you!
        PM

        VERIFY_MESSAGE = <<~PM
          Please click the following link to verify your reddit account:

          %<auth_url>s

          This link is active for 7 days, after which you can message me with `!verify %<guild>s` to receive a new link.
        PM

        MISSING_SERVER_NAME = <<~PM
          Please enter a server name, e.g. `!verify baseball` for the baseball server.
        PM

        INVALID_SERVER_NAME = 'I couldn\'t find a server with that name.'

        ALREADY_VERIFIED = 'You have already been verified on this server.'

        NOT_A_MEMBER = 'It doesn\'t look like you\'re a member of this server.'

        VERIFICATION_NOT_ENABLED = 'This server does not require verification.'

        def run
          start_verification_for_server find_server_by_name(raw_args)
        rescue UserError => e
          send_pm e.message
        end

        def send_welcome_pm
          return unless bot.config.verification_enabled?(server.id)

          start_verification_for_server server, welcome: true
        end

        protected

        def start_verification_for_server(guild, welcome: false)
          return unless guild

          raise UserError, VERIFICATION_NOT_ENABLED unless bot.config.verification_enabled?(guild.id)

          member = guild.member(user.id)

          raise UserError, NOT_A_MEMBER unless member
          raise UserError, ALREADY_VERIFIED if member_verified?(member)

          send_verification_pm(guild, welcome)
        rescue UserError => e
          send_pm e.message
        end

        def send_verification_pm(guild, welcome)
          send_pm format(
            (welcome ? WELCOME_MESSAGE : VERIFY_MESSAGE),
            server_name: guild.name,
            auth_url: auth_url(guild),
            guild: bot.config.server(guild.id)['short_name']
          )
        end

        def find_server_by_name(name)
          normal = name.strip.downcase.gsub(/[^a-z]/, '')

          raise UserError, MISSING_SERVER_NAME if normal.empty?

          server_id = bot.config.short_name_to_server_id(normal)

          raise UserError, INVALID_SERVER_NAME unless server_id

          bot.server server_id
        end

        def member_verified?(member)
          return true unless bot.config.verification_enabled?(member.server.id)

          member.roles.map(&:id).include? bot.config.verified_role_id(member.server.id)
        end

        def auth_url(guild = nil)
          Redd.url(
            client_id: ENV.fetch('DISCORD_REDDIT_CLIENT_ID'),
            redirect_uri: 'https://baseballbot.io/discord/reddit-callback',
            response_type: 'code',
            state: generate_state_data(guild || server),
            scope: ['identity'],
            duration: 'temporary'
          )
        end

        def generate_state_data(guild)
          state_token = SecureRandom.urlsafe_base64

          bot.redis.set "discord.verification.#{state_token}", state_data(guild)

          bot.redis.expire "discord.verification.#{state_token}", 604_800

          state_token
        end

        def state_data(guild)
          {
            user: user.id,
            server: guild.id,
            role: bot.config.verified_role_id(guild.id)
          }.to_json
        end
      end
    end
  end
end
