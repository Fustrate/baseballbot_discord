# frozen_string_literal: true

class BaseballDiscord
  module Events
    module MemberJoin
      extend Discordrb::EventContainer

      member_join do |event|
        if event.server.id == BaseballDiscord::Bot::SERVER_ID
          $stdout << event.server.inspect
          $stdout << event.user.inspect
        end

        nil
      end
    end
  end
end
