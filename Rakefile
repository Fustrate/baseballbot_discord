# frozen_string_literal: true

%i[start stop restart status].each do |command|
  desc "Discord Bot Control: #{command}"
  task(command) do
    ruby "discord_bot_control.rb #{command}"
  end
end
