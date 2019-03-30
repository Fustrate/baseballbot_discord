# frozen_string_literal: true

module GameChatBot
  module Plays
    def output_plays
      @next_event = @bot.redis.get "#{redis_key}_next_event"

      plays_starting_with(@next_event).each do |play|
        embed = play.embed

        @bot.home_run_alert(embed) if play.type == 'Home Run'

        send_message embed, at: play.post_at
      end

      update_next_event
    end

    protected

    def plays_starting_with(next_event)
      return next_play_embeds(next_event) if next_event

      embeds_for_plays @feed.plays['allPlays']
    end

    def update_next_event
      value = last_play_key

      return if !value || value == @next_event

      @bot.redis.set "#{redis_key}_next_event", value
    end

    def last_play_key
      return unless @last_play

      if @last_play.dig('about', 'isComplete')
        [@last_play['atBatIndex'] + 1, 0].join(',')
      else
        [@last_play['atBatIndex'], @last_play['playEvents'].length].join(',')
      end
    end

    def next_play_embeds(next_event)
      play_id, event_id = next_event.split(',').map(&:to_i)

      [
        embeds_for_play(@feed.plays['allPlays'][play_id], after: event_id),
        embeds_for_plays(@feed.plays['allPlays'][(play_id + 1)..-1])
      ].flatten.compact
    end

    def embeds_for_play(play, after: -1)
      return [] unless play

      @last_play = play

      [
        interesting_events(play, play['playEvents'][(after + 1)..-1]),
        (embed_for(play) if play.dig('about', 'isComplete'))
      ].flatten.compact
    end

    def embeds_for_plays(plays)
      return [] unless plays

      # If we missed some things, oh well
      plays
        .select { |play| play['playEvents'].any? }
        .last(3)
        .map { |play| embeds_for_play(play) }
    end

    def interesting_events(play, events)
      return unless events&.any?

      actions = events.select { |event| event['type'] == 'action' }
        .map { |action| action.dig('details', 'description') }

      return if actions.none?

      Embeds::Interesting.new(play, self, actions.join("\n"))
    end

    def embed_for(play)
      case play.dig('result', 'event')
      when 'Walk', 'Strikeout'
        Embeds::StrikeoutOrWalk.new(play, self)
      when 'Home Run'
        Embeds::HomeRun.new(play, self)
      else
        Embeds::Play.new(play, self)
      end
    end
  end
end
