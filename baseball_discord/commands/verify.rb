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
          Click the following link to verify your reddit account:
          %<auth_url>s
          This link is active for 7 days, after which you can message me with `!verify %<guild>s` to receive a new link.
        PM

        MISSING_SERVER_NAME = <<~PM
          Please enter a server name, e.g. `!verify baseball` for the baseball server.
        PM

        INVALID_SERVER_NAME = 'I couldn\'t find a server with that name.'

        VERIFIED_MESSAGE = <<~PM
          Thanks for verifying your account! You should now have access to the server.
        PM

        ALREADY_VERIFIED = 'You have already been verified on this server.'

        def run
          server_name = args.join(' ').strip.downcase.gsub(/[^a-z]/, '')

          guild = find_server_by_name(server_name)

          return unless guild

          member = guild.member(user.id)

          return user.pm ALREADY_VERIFIED if member_verified_on_server?(member)

          send_pm format(
            WELCOME_MESSAGE,
            auth_url: auth_url(guild),
            guild: server_name
          )
        end

        def send_welcome_pm
          server_name = bot.class::SERVERS.key(server.id)

          user.pm format(
            WELCOME_MESSAGE,
            auth_url: auth_url,
            guild: server_name
          )
        end

        protected

        def find_server_by_name(name)
          return send_pm MISSING_SERVER_NAME if name.empty?
          return send_pm INVALID_SERVER_NAME unless bot.class::SERVERS[name]

          bot.server bot.class::SERVERS[name]
        end

        def member_verified_on_server?(member)
          member.roles.map(&:id).include?(
            bot.class::VERIFIED_ROLES[member.server.id]
          )
        end

        def auth_url(guild = nil)
          Redd.url(
            client_id: ENV['DISCORD_REDDIT_CLIENT_ID'],
            redirect_uri: 'https://baseballbot.io/discord/reddit-callback',
            response_type: 'code',
            state: generate_state_data(guild || server),
            scope: ['identity'],
            duration: 'temporary'
          )
        end

        def generate_state_data(guild)
          state_token = SecureRandom.urlsafe_base64

          data = {
            user_id: user.id,
            server_id: guild.id,
            role_id: bot.class::VERIFIED_ROLES[guild.id]
          }

          bot.redis.set "discord.verification.#{state_token}", data.to_json

          bot.redis.expire "discord.verification.#{state_token}", 604_800

          state_token
        end
      end
    end
  end
end
