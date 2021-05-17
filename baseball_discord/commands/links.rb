# frozen_string_literal: true

module BaseballDiscord
  module Commands
    # Basic debug commands that should log to the output file
    module Links
      extend Discordrb::Commands::CommandContainer

      command(:bbref, help_available: false) { |event, *args| LinksCommand.new(event, *args).bbref }

      command(:fangraphs, help_available: false) { |event, *args| LinksCommand.new(event, *args).fangraphs }

      # Prints some basic info to the log file
      class LinksCommand < Command
        def bbref() = "https://www.baseball-reference.com/search/search.fcgi?search=#{CGI.escape raw_args}"

        def fangraphs() = "https://www.fangraphs.com/players.aspx?new=y&lastname=#{CGI.escape raw_args}"
      end
    end
  end
end
