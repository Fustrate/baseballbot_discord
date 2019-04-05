# frozen_string_literal: true

module GameChatBot
  module GameFeed
    def lineups
      away_abbrev = @feed.game_data.dig('teams', 'away', 'abbreviation')
      home_abbrev = @feed.game_data.dig('teams', 'home', 'abbreviation')

      away_lineup = lineup_data('away').map { |pos, name| "#{name} *#{pos}*" }
      home_lineup = lineup_data('home').map { |pos, name| "#{name} *#{pos}*" }

      <<~MESSAGE
        **#{away_abbrev}:** #{away_lineup.join(' | ')}
        **#{home_abbrev}:** #{home_lineup.join(' | ')}
      MESSAGE
    end

    def team_lineup(input)
      case BaseballDiscord::Utilities.find_team_by_name(input)
      when @feed.game_data.dig('teams', 'away', 'id')
        lineup_data('away').map { |pos, name| "#{name} *#{pos}*" }.join(' | ')
      when @feed.game_data.dig('teams', 'home', 'id')
        lineup_data('home').map { |pos, name| "#{name} *#{pos}*" }.join(' | ')
      else
        false
      end
    end

    def fields_for_umpires
      @feed.boxscore['officials'].map do |umpire|
        {
          name: umpire['officialType'],
          value: umpire.dig('official', 'fullName'),
          inline: true
        }
      end
    end

    def game_ended?
      @feed.game_data.dig('status', 'abstractGameState') == 'Final'
    end

    def output_lineups
      # Once the game has started, don't bother
      return true if Time.now >= @starts_at

      output_team_lineup_table('home')
      output_team_lineup_table('away')
    end

    protected

    def output_team_lineup_table(flag)
      return if bot.redis.get("#{redis_key}_#{flag}_lineup_posted")

      rows = lineup_data(flag)

      return unless rows&.any?

      rows.insert(6, :separator)
      rows.insert(3, :separator)

      send_message text: lineup_table(flag, rows), force: true

      bot.redis.set "#{redis_key}_#{flag}_lineup_posted", 1
    end

    def lineup_table(flag, rows)
      table = Terminal::Table.new rows: rows, title: "#{team_name(flag)} Lineup"

      format_table table
    end

    def lineup_data(flag)
      ids = @feed.boxscore.dig('teams', flag, 'battingOrder')
        .map { |id| "ID#{id}" }

      lineup_positions(flag, ids).zip(lineup_names(ids))
    end

    def lineup_names(ids)
      @feed.game_data['players'].values_at(*ids)
        .map { |player| player['lastName'] }
    end

    def lineup_positions(flag, ids)
      @feed.boxscore.dig('teams', flag, 'players')
        .values_at(*ids)
        .map { |player| player.dig('position', 'abbreviation') }
    end
  end
end
