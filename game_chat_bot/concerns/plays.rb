# frozen_string_literal: true

module GameChatBot
  module Plays
    def output_plays
      event = @bot.redis.get("#{redis_key}_next_event")

      plays_starting_with(event).each do |embed|
        embed_hash = embed.to_h

        @bot.send_to_home_runs_channel(embed_hash) if embed.is_a?(Embeds::HomeRun)

        send_message embed: embed_hash, at: embed.post_at
      end

      update_next_event(event)
    end

    protected

    def plays_starting_with(next_event)
      return next_play_embeds(next_event) if next_event

      embeds_for_plays @feed.plays['allPlays']
    end

    def update_next_event(next_event)
      value = last_play_key

      @bot.redis.set("#{redis_key}_next_event", value) if value && value != next_event
    end

    def last_play_key
      return unless @last_play

      return "#{@last_play['atBatIndex'] + 1},0" if @last_play.dig('about', 'isComplete')

      "#{@last_play['atBatIndex']},#{@last_play['playEvents'].length}"
    end

    def next_play_embeds(next_event)
      play_id, event_id = next_event.split(',').map(&:to_i)

      [
        embeds_for_play(@feed.plays['allPlays'][play_id], after: event_id),
        embeds_for_plays(@feed.plays['allPlays'][(play_id + 1)..])
      ].flatten.compact
    end

    def embeds_for_play(play, after: -1)
      return [] unless play

      @last_play = play

      [
        interesting_events(play, play['playEvents'][(after + 1)..]),
        (embed_for(play) if play.dig('about', 'isComplete'))
      ].flatten.compact
    end

    def embeds_for_plays(plays)
      return [] unless plays

      # If we missed some things, oh well
      plays
        .select { it['playEvents'].any? }
        .last(3)
        .flat_map { embeds_for_play(it) }
    end

    def interesting_events(play, events)
      return unless events&.any?

      actions = events.filter_map { it.dig('details', 'description') if it['type'] == 'action' }

      Embeds::Interesting.new(play, self, actions.join("\n")) if actions.any?
    end

    def embed_for(play)
      @bot.logger.info "[#{redis_key}] Play ##{play['atBatIndex']}, #{play.dig('result', 'description')}"

      case play.dig('result', 'eventType')
      when 'walk', 'strikeout'
        Embeds::StrikeoutOrWalk.new(play, self)
      when 'home_run'
        Embeds::HomeRun.new(play, self)
      else
        Embeds::Play.new(play, self)
      end
    end
  end
end
