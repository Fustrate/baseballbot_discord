# frozen_string_literal: true

require_relative 'bot'

# Only uncomment a command when it needs to be updated. Re-comment after the update is deployed and this script is run.

@bot = ModmailBot::Bot.new

@bot.register_application_command(:archive, 'Archive modmail') do |cmd|
  cmd.string 'reason', 'the reason this message is being archived', required: false
end

@bot.register_application_command(:unarchive, 'Unarchive modmail') do |cmd|
  cmd.string 'reason', 'the reason this message is being unarchived', required: false
end
