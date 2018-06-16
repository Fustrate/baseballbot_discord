# frozen_string_literal: true

module GameChatBot
  class GameChannel
    attr_reader :bot, :channel, :feed, :game_pk, :line_score

    def initialize(bot, game_pk, channel, feed)
      @bot = bot

      @game_pk = game_pk
      @channel = channel
      @feed = feed

      @starts_at = Time.parse @feed.game_data.dig('datetime', 'dateTime')
      @last_update = Time.now - 3600 # So we can at least do one update
    end

    def update_game_chat
      return unless ready_to_update? && @feed.update!

      @line_score = LineScore.new(self)

      output_plays

      output_alerts

      @channel.topic = @line_score.line_score_state
    rescue Net::OpenTimeout, SocketError
      nil
    end

    def ready_to_update?
      return true if Time.now >= @starts_at

      # Only update every ~5 minutes when the game hasn't started yet
      return false unless @last_update + 300 <= Time.now

      @last_update = Time.now

      true
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
        {
          name: umpire['officialType'],
          value: umpire.dig('official', 'fullName'),
          inline: true
        }
      end

      @channel.send_embed '', fields: umpires
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

    def redis_key
      @redis_key ||= "#{@channel.id}_#{@game_pk}"
    end

    def output_plays
      @last_event = @bot.redis.get "#{redis_key}_last_event"

      return process_plays_since_last_event if @last_event

      process_plays @feed.plays['allPlays']
    end

    def process_plays_since_last_event
      play_id, event_id = @last_event.split(',').map(&:to_i)

      process_unfinished_event @feed.plays['allPlays'][play_id], event_id

      process_plays @feed.plays['allPlays'][(play_id + 1)..-1]
    end

    def process_unfinished_event(play, event_id)
      return unless play['playEvents'].length - 1 > event_id

      process_play play, events_after: event_id

      update_last_event play
    end

    def last_actual_plays(plays, count)
      plays.select { |play| play['playEvents'].any? }.last(count)
    end

    def process_plays(plays)
      return if plays&.none?

      # If we missed some things, oh well
      last_plays = last_actual_plays(plays, 3)

      return if last_plays.none?

      last_plays.each { |play| process_play(play) }

      update_last_event(last_plays.last)
    end

    def update_last_event(play)
      value = [
        play['atBatIndex'],
        play['playEvents'].length - 1
      ]

      # We have to rewind if this is complete-but-not-complete
      value[1] -= 1 if play['about']['isInPlay'] && !play['about']['isComplete']

      return if value.join(',') == @last_event

      @bot.redis.set "#{redis_key}_last_event", value.join(',')
    end

    def process_play(play, events_after: -1)
      post_interesting_actions play['playEvents'][(events_after + 1)..-1]

      return unless play.dig('about', 'isComplete')

      @channel.send_embed '', Play.new(play, self).embed
    end

    def post_interesting_actions(events)
      actions = events.select { |event| event['type'] == 'action' }
        .map { |action| action.dig('details', 'description') }

      return if actions.none?

      @channel.send_embed(
        '',
        description: actions.join("\n"),
        color: '999999'.to_i(16)
      )
    end

    def output_alerts
      return unless @feed.game_data

      @feed.game_data['alerts'].each do |alert|
        next if @bot.redis.sismember "#{redis_key}_alerts", alert['alertId']

        @bot.redis.sadd "#{redis_key}_alerts", alert['alertId']

        output_alert(alert)
      end
    end

    def output_alert(alert)
      embed = Alert.new(alert, self).embed

      @channel.send_embed '', embed if embed

      send_lineups if alert['description']['Lineups posted']

      @bot.end_feed_for_channel @channel if alert['category'] == 'game_over'
    end
  end
end
