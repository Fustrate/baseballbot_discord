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
        def run
          if user.roles.map(&:name).include?('Verified')
            user.pm 'You have already been verified.'
          else
            user.pm 'Click the following link to verify your reddit account:'
            user.pm reddit_auth_url
            user.pm <<~PM.tr("\n", ' ').strip
              This link is active for 7 days, after which you can
              message me with `!verify` to receive a new link.
            PM
          end
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
            id: user.id,
            username: user.username,
            distinct: user.distinct
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
