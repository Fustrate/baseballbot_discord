# frozen_string_literal: true

require 'rake/testtask'

%i[start stop restart status].each do |command|
  desc "Discord Bot Control: #{command}"
  task(command) do
    ruby "baseballbot/control.rb #{command}"
  end
end

Rake::TestTask.new do |t|
  t.pattern = 'test/*_spec.rb'
end

task default: :test
