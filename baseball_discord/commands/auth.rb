# frozen_string_literal: true

module BaseballDiscord
  module Commands
    # Basic debug commands that should log to the output file
    module Auth
      extend Discordrb::Commands::CommandContainer

      command(:auth) do |event|
        RedditAuthCommand.run event
      end

      class RedditAuthCommand < Command
        def run(event)
          if event.user.roles.map(&:name).include?('Verified')
            event.user.pm 'You have already been verified.'
          else
            event.user.pm 'Click the following link to verify your reddit account:'
            event.user.pm reddit_auth_url(event.user)
          end
        end

        def reddit_auth_url(event)
          event.user # We need to put this in the state, or shove stuff in Redis

          Redd.url(
            client_id: ENV['DISCORD_REDDIT_CLIENT_ID'],
            redirect_uri: 'https://baseballbot.io/discord/reddit-callback',
            response_type: 'code',
            state: SecureRandom.urlsafe_base64,
            scope: ['identity'],
            duration: 'temporary'
          )
        end
      end
    end
  end
end
