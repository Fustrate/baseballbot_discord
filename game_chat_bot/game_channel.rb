# frozen_string_literal: true

module GameChatBot
  class GameChannel
    attr_reader :bot, :channel, :feed, :game_pk, :line_score, :game_over

    def initialize(bot, game_pk, channel, feed)
      @bot = bot

      @game_pk = game_pk
      @channel = channel
      @feed = feed

      @starts_at = Time.parse @feed.game_data.dig('datetime', 'dateTime')
      @last_update = Time.now - 3600 # So we can at least do one update
      @game_over = false
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
      return false if @game_over

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

      lineup_positions(flag, ids)
        .zip(lineup_names(ids))
        .map { |pos, name| "#{name} *#{pos}*" }.join(' | ')
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

    def redis_key
      @redis_key ||= "#{@channel.id}_#{@game_pk}"
    end

    def output_plays
      @next_event = @bot.redis.get "#{redis_key}_next_event"

      return process_next_plays if @next_event

      process_plays @feed.plays['allPlays']

      update_next_event
    end

    def process_next_plays
      play_id, event_id = @next_event.split(',').map(&:to_i)

      process_play @feed.plays['allPlays'][play_id], events_after: event_id

      process_plays @feed.plays['allPlays'][(play_id + 1)..-1]
    end

    def last_eventful_plays(plays, count)
      plays&.select { |play| play['playEvents'].any? }&.last(count) || []
    end

    def process_plays(plays)
      # If we missed some things, oh well
      last_eventful_plays(plays, 3).each { |play| process_play(play) }
    end

    def process_play(play, events_after: -1)
      return unless play

      post_interesting_actions play['playEvents'][(events_after + 1)..-1]

      @last_play = play

      return unless play.dig('about', 'isComplete')

      embed = Play.new(play, self).embed

      @bot.home_run_alert(embed) if play.dig('result', 'event') == 'Home Run'

      @channel.send_embed '', embed
    end

    def post_interesting_actions(events)
      return unless events&.any?

      actions = events.select { |event| event['type'] == 'action' }
        .map { |action| action.dig('details', 'description') }

      return if actions.none?

      @channel.send_embed(
        '',
        description: actions.join("\n"),
        color: '999999'.to_i(16)
      )
    end

    def update_next_event
      return unless @last_play

      value = if @last_play.dig('about', 'isComplete')
                [@last_play['atBatIndex'] + 1, 0]
              else
                [@last_play['atBatIndex'], @last_play['playEvents'].length]
              end

      return if value.join(',') == @next_event

      @bot.redis.set "#{redis_key}_next_event", value.join(',')
    end

    # @!group Alerts

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

      return unless alert['category'] == 'game_over'

      # Stop trying to update
      @game_over = true
    end

    # @!endgroup Alerts
  end
end
