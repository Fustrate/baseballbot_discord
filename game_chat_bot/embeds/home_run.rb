# frozen_string_literal: true

module GameChatBot
  module Embeds
    class HomeRun < Play
      MINIMUM_DISTANCE = 420
      MINIMUM_SPEED = 110
      BORING_LAUNCH_ANGLE = 18..42

      COPYPASTA = <<~COPYPASTA.gsub(/\s/, ' ')
        I get physically angry watching Max Muncy hit. This man just doesn't chase. You can almost hear him sneering
        "that's 0.16cm outside" as he takes a ball 1. Two-strike counts don't faze him. Then he'll whip out a
        hellacious dong on the 9th pitch. He's suffocating. He's Max Muncy.
      COPYPASTA

      def to_h
        {
          title: "#{team_emoji} #{@play.dig('result', 'event')} (#{count})",
          description:,
          fields: [*hit_data_fields, { name: 'Pitch', value: pitch_type, inline: true }, copypasta].compact,
          color: color.to_i(16),
          footer: resulting_context
        }
      end

      protected

      def event = (@event ||= @play['playEvents'].last)

      def hit_data_fields
        # Rarely, a home run has no hit data
        return [] unless event['hitData']

        angle, speed, distance = event['hitData'].values_at('launchAngle', 'launchSpeed', 'totalDistance')

        [
          { name: 'Launch Angle', value: angle_for(angle), inline: true },
          { name: 'Launch Speed', value: speed_for(speed), inline: true },
          { name: 'Distance', value: distance_for(distance), inline: true }
        ]
      end

      def distance_for(distance)
        return '???' unless distance

        distance < MINIMUM_DISTANCE ? "#{distance} feet" : ":star2: **#{distance} feet** :star2:"
      end

      def speed_for(speed)
        return '???' unless speed

        speed < MINIMUM_SPEED ? "#{speed} mph" : ":star2: **#{speed} mph** :star2:"
      end

      def angle_for(angle)
        return '???' unless angle

        BORING_LAUNCH_ANGLE.cover?(angle) ? "#{angle} deg" : ":star2: **#{angle} deg** :star2:"
      end

      def pitch_type = "#{event.dig('pitchData', 'startSpeed')} mph #{event.dig('details', 'type', 'description')}"

      def copypasta
        return unless @play.dig('matchup', 'batter', 'id') == 571970

        { name: 'Max Muncy', value: COPYPASTA }
      end
    end
  end
end
