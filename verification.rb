# frozen_string_literal: true

require 'redd'
require 'securerandom'

class BaseballDiscordBot
  module Verification
    def self.add_to(discord_bot, baseballbot)
      discord_bot.command(:auth) do |event|
        if event.user.roles.map(&:name).include?('Verified')
          event.user.pm 'You have already been verified.'
        else
          baseballbot.send_reddit_auth_url(event)
        end
      end

      discord_bot.member_join do |event|
        if event.server.id == BaseballDiscordBot::SERVER_ID
          $stdout << event.server.inspect
          $stdout << event.user.inspect
        end

        nil
      end

      discord_bot.command(:debug, help_available: false) do |event|
        if event.server.id == BaseballDiscordBot::SERVER_ID
          $stdout << event.server.inspect
        end

        nil
      end
    end

    def send_reddit_auth_url(event)
      event.user.pm 'Click the following link to verify your reddit account:'
      event.user.pm Redd.url(
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
