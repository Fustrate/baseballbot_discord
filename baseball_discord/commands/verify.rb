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
        VERIFY_MESSAGE = <<~PM
          Click the following link to verify your reddit account:
          %<auth_url>s
          This link is active for 7 days, after which you can message me with `!verify` to receive a new link.
        PM

        def run
          if user.roles.map(&:name).include?('Verified')
            user.pm 'You have already been verified.'

            return
          end

          user.pm format(VERIFY_MESSAGE, auth_url: reddit_auth_url)
        end

        def reddit_auth_url
          Redd.url(
            client_id: ENV['DISCORD_REDDIT_CLIENT_ID'],
            redirect_uri: 'https://baseballbot.io/discord/reddit-callback',
            response_type: 'code',
            state: generate_state_data,
            scope: ['identity'],
            duration: 'temporary'
          )
        end

        def generate_state_data
          state_token = SecureRandom.urlsafe_base64

          state_data = {
            server_id: server.id,
            user_id: user.id
          }

          # Store the data for one week. After that, they'll have to get a new
          # link.
          bot.redis.mapped_hmset state_token, state_data
          bot.redis.expire state_token, 604_800

          state_token
        end
      end
    end
  end
end
