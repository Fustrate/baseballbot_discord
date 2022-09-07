# frozen_string_literal: true

module BaseballDiscord
  module Commands
    # Basic debug commands that should log to the output file
    module Links
      BBREF = 'https://www.baseball-reference.com/search/search.fcgi?search=%<query>s'

      FANGRAPHS = 'https://www.fangraphs.com/players.aspx?new=y&lastname=%<query>s'

      def self.register(bot)
        bot.application_command(:bbref) do |event|
          event.respond content: format(BBREF, query: CGI.escape(event.options['query']))
        end

        bot.application_command(:fangraphs) do |event|
          event.respond content: format(FANGRAPHS, query: CGI.escape(event.options['query']))
        end
      end
    end
  end
end
