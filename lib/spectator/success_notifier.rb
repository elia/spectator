# coding: utf-8
require 'notify'

module Spectator
  class SuccessNotifier

    def initialize(config)
      @config ||= config
      if osx?
        begin
          require 'terminal-notifier'
        rescue LoadError => e
          $stderr.puts e.message
          $stderr.puts 'On OSX you should use notification center: gem install terminal-notifier'.red
        end
      end
    end

    def notify(success)
      message = success ? success_message : failed_message
      Thread.new { Notify.notify 'RSpec Result:', message }
    end

    def success_message
      @success_message ||= osx? ? '🎉 SUCCESS'.freeze :
                                  '♥♥ SUCCESS :) ♥♥'.freeze
    end

    def failed_message
      @failed_message ||= osx? ? '💔 FAILED'.freeze :
                                 '♠♠ FAILED >:( ♠♠'.freeze
    end

    def osx?
      @osx ||= RUBY_PLATFORM.include? 'darwin'
    end
  end
end
