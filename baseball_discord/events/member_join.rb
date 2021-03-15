# frozen_string_literal: true

module BaseballDiscord
  module Events
    module MemberJoin
      extend Discordrb::EventContainer

      member_join do |event|
        BaseballDiscord::Commands::Verify::RedditAuthCommand.new(event).send_welcome_pm

        nil
      end
    end
  end
end
