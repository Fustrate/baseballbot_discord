# frozen_string_literal: true

module ModmailBot
  module Events
    module Reaction
      extend Discordrb::EventContainer

      reaction_add do |event|
        ReactionHandler.new(event)

        nil
      end

      class ReactionHandler
        attr_reader :event

        def initialize(event)
          @event = event
        end

        def process
          bot.logger.info "[#{channel.id}] Reaction: #{event.emoji.name} by #{user.nick}"
        end

        protected

        def bot = event.bot

        def channel = event.channel

        def user = event.user
      end
    end
  end
end
