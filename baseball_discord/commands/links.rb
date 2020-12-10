# frozen_string_literal: true

module BaseballDiscord
  module Commands
    # Basic debug commands that should log to the output file
    module Links
      extend Discordrb::Commands::CommandContainer

      command(:bbref, help_available: false) do |event, *args|
        LinksCommand.new(event, *args).bbref
      end

      command(:fangraphs, help_available: false) do |event, *args|
        LinksCommand.new(event, *args).fangraphs
      end

      # Prints some basic info to the log file
      class LinksCommand < Command
        def bbref
          "https://www.baseball-reference.com/search/search.fcgi?search=#{CGI.escape raw_args}"
        end

        def fangraphs
          "https://www.fangraphs.com/players.aspx?new=y&lastname=#{CGI.escape raw_args}"
        end
      end
    end
  end
end
