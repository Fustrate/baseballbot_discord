# frozen_string_literal: true

module BaseballDiscord
  module Commands
    module Players
      extend Discordrb::Commands::CommandContainer

      command(:player, help_available: false) do |event, *args|
        PlayerCommand.new(event, *args).look_up_player
      end

      # Prints some basic info to the log file
      class PlayerCommand < Command
        def look_up_player
          return react_to_message('🔒') unless user.id == BaseballDiscord::Bot::ADMIN_ID

          BaseballDiscord::Utilities.look_up_player(raw_args).inspect
        end
      end
    end
  end
end
