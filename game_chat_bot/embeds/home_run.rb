# frozen_string_literal: true

module GameChatBot
  module Embeds
    class HomeRun < Play
      MINIMUM_DISTANCE = 420
      MINIMUM_SPEED = 110
      BORING_LAUNCH_ANGLE = 18..42

      def to_h
        {
          title: "#{team_emoji} #{@play.dig('result', 'event')} (#{count})",
          description: description,
          fields: hit_data_fields.append({ name: 'Pitch', value: pitch_type, inline: true }),
          color: color.to_i(16),
          footer: resulting_context
        }
      end

      protected

      def event() = (@event ||= @play['playEvents'].last)

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

      def pitch_type() = "#{event.dig('pitchData', 'startSpeed')} mph #{event.dig('details', 'type', 'description')}"
    end
  end
end
