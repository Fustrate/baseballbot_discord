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
          unless user.id == BaseballDiscord::Bot::ADMIN_ID
            return react_to_message '🔒'
          end

          BaseballDiscord::Utilities.look_up_player(args.join(' ')).inspect
        end
      end
    end
  end
end
