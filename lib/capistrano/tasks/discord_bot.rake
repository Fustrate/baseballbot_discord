# frozen_string_literal: true

namespace :discord_bot do
  %i[start stop restart].each do |action|
    desc "#{action} the discord bot"
    task action do
      on roles(:web) do
        within release_path do
          execute :bundle, :exec, :ruby, 'baseballbot/control.rb', action
        end
      end
    end
  end
end
