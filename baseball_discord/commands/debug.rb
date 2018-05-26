# frozen_string_literal: true

module BaseballDiscord
  module Commands
    # Basic debug commands that should log to the output file
    module Debug
      extend Discordrb::Commands::CommandContainer

      command(:auth) do |event|
        if event.user.roles.map(&:name).include?('Verified')
          event.user.pm 'You have already been verified.'
        else
          baseballbot.send_reddit_auth_url(event)
        end
      end

      command(:debug, help_available: false) do |event|
        if event.server.id == BaseballDiscord::Bot::SERVER_ID
          $stdout << event.server.inspect
        end

        nil
      end
    end
  end
end
