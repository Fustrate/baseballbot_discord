# frozen_string_literal: true

module BaseballDiscord
  module Events
    module MemberJoin
      extend Discordrb::EventContainer

      member_join do |event|
        # Same as when they type !verify
        # BaseballDiscord::Commands::Verify::RedditAuthCommand.new(event).run

        nil
      end
    end
  end
end
