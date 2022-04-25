# frozen_string_literal: true

require_relative 'series_channels_bot'

bot = SeriesChannelsBot.new token: ENV.fetch('DISCORD_GAMETHREAD_TOKEN')

bot.update_channels
