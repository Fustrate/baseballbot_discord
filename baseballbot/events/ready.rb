# frozen_string_literal: true

module BaseballDiscord
  module Events
    module Ready
      extend Discordrb::EventContainer

      # Send a message to the /r/baseball modlogs channel to show that a restart has occurred.
      ready do |event|
        event.bot.channel(476402294171107359).send_message '', false, {
          title: 'Restarted',
          description: 'The bot has been restarted.',
          color: 'ffffff'.to_i(16)
        }

        nil
      end
    end
  end
end
