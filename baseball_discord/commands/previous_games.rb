# frozen_string_literal: true

module BaseballDiscord
  module Commands
    module PreviousGames
      extend Discordrb::Commands::CommandContainer

      COMMAND = :last
      DESCRIPTION = 'Display the last N games for a team'
      USAGE = 'last [N=10] [team]'

      command(COMMAND, description: DESCRIPTION, usage: USAGE) do |event, *args|
        PreviousGamesCommand.new(event, *args).run
      end

      class PreviousGamesCommand < Command
        def run
          'Umm yeah I haven\'t finished this one yet...'
        end
      end
    end
  end
end
