# frozen_string_literal: true

require_relative 'series_channels_bot'

bot = SeriesChannelsBot.new token: ENV['DISCORD_GAMETHREAD_TOKEN']

bot.move_channels
