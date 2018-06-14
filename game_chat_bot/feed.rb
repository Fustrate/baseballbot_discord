# frozen_string_literal: true

module GameChatBot
  class Feed
    attr_reader :bot, :channel, :feed, :game_pk, :line_score

    def initialize(bot, game_pk, channel, feed)
      @bot = bot

      @game_pk = game_pk
      @channel = channel
      @feed = feed

      @last_play = -1
      @last_event = -1
    end

    def update_game_chat
      return unless @feed.update!

      @line_score = LineScore.new(self)

      output_last_play

      output_alerts

      @channel.topic = @line_score.line_score_state
    rescue Net::OpenTimeout, SocketError
      nil
    end

    def send_line_score
      @channel.send_message <<~LINESCORE
        #{@line_score.line_score_state}

        ```#{@line_score.line_score}```
      LINESCORE
    end

    def send_lineups
      away_abbrev = @feed.game_data.dig('teams', 'away', 'abbreviation')
      home_abbrev = @feed.game_data.dig('teams', 'home', 'abbreviation')

      @channel.send_message <<~MESSAGE
        **#{away_abbrev}:** #{team_lineup('away')}
        **#{home_abbrev}:** #{team_lineup('home')}
      MESSAGE
    end

    def send_lineup(event, input)
      team_id = BaseballDiscord::Utilities.find_team_by_name(input)

      if @feed.game_data.dig('teams', 'away', 'id') == team_id
        @channel.send_message team_lineup('away')
      elsif @feed.game_data.dig('teams', 'home', 'id') == team_id
        @channel.send_message team_lineup('home')
      else
        return event.message.react '❓'
      end
    end

    def send_umpires
      umpires = @feed.live_data.dig('boxscore', 'officials').map do |umpire|
        "**#{umpire['officialType']}**: #{umpire.dig('official', 'fullName')}"
      end

      @channel.send_message umpires.join("\n")
    end

    protected

    def team_lineup(flag)
      ids = @feed.boxscore.dig('teams', flag, 'battingOrder')
        .map { |id| "ID#{id}" }

      names = @feed.game_data['players'].values_at(*ids)
        .map { |player| player['lastName'] }

      positions = @feed.boxscore.dig('teams', flag, 'players').values_at(*ids)
        .map { |player| player.dig('position', 'abbreviation') }

      positions.zip(names).map { |pos, name| "#{name} *#{pos}*" }.join(' | ')
    end

    def plays_to_output
      plays = @feed.plays['allPlays']

      # No plays yet; game probably hasn't started.
      return [] unless plays&.any?

      if @last_play
        # Check to see if the last play we looked at has any more info
        # Output any more plays after this one
      else
        # Output all plays, I guess
      end
    end

    def output_last_play
      last_play = @feed.plays['allPlays']
        .select { |play| play['about']['isComplete'] }
        .last

      return unless last_play

      index = last_play.dig('about', 'atBatIndex')

      return if index <= @last_play

      @last_play = index

      @channel.send_embed '', Play.new(last_play, self).embed
    end

    def output_alerts
      return unless @feed.game_data

      key = "#{@channel.id}_#{@game_pk}_alerts"

      @feed.game_data['alerts'].each do |alert|
        next if @bot.redis.sismember key, alert['alertId']

        @bot.redis.sadd key, alert['alertId']

        puts alert

        @channel.send_embed '', Alert.new(alert, self).embed
      end
    end
  end
end
