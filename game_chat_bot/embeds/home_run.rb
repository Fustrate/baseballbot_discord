# frozen_string_literal: true

module GameChatBot
  module Embeds
    class HomeRun < Play
      def embed
        {
          title: "#{team_emoji} #{type} (#{count})",
          description: description,
          fields: home_run_fields,
          color: color,
          footer: resulting_context
        }
      end

      protected

      def home_run_fields
        fields = hit_data_fields

        fields << { name: 'Pitch', value: pitch_type, inline: true }

        fields
      end

      def event
        @event ||= @play['playEvents'].last
      end

      def hit_data_fields
        # Rarely, a home run has no hit data
        return [] unless event['hitData']

        angle, speed, distance = event['hitData']
          .values_at 'launchAngle', 'launchSpeed', 'totalDistance'

        [
          { name: 'Launch Angle', value: "#{angle} deg", inline: true },
          { name: 'Launch Speed', value: "#{speed} mph", inline: true },
          { name: 'Distance', value: "#{distance} feet", inline: true }
        ]
      end

      def pitch_type
        speed = event.dig('pitchData', 'startSpeed')

        "#{speed} mph #{event.dig('details', 'type', 'description')}"
      end
    end
  end
end
