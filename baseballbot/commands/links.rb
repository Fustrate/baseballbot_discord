# frozen_string_literal: true

module BaseballDiscord
  module Commands
    # Basic debug commands that should log to the output file
    module Links
      BBREF = 'https://www.baseball-reference.com/search/search.fcgi?search=%<query>s'

      FANGRAPHS = 'https://www.fangraphs.com/players.aspx?new=y&lastname=%<query>s'

      def self.register(bot)
        bot.application_command(:bbref) { LinksCommand.new(_1).bbref }

        bot.application_command(:fangraphs) { LinksCommand.new(_1).fangraphs }
      end

      class LinksCommand < SlashCommand
        def bbref = respond_with(content: format(BBREF, query: CGI.escape(options['query'])))

        def fangraphs = respond_with(content: format(FANGRAPHS, query: CGI.escape(options['query'])))
      end
    end
  end
end
