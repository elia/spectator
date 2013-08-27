require 'thread'

module Spectator
  module Control
    def exit
      @exiting = true
      puts '--- Exiting...'.white
      Kernel.exit
    end

    def abort!
      puts '--- Forcing abort...'.white
      Kernel.abort("\n")
    end

    def trap_int!
      # Ctrl-C
      @interrupted ||= false
      @signal_queue = []
      @signals_handler = Thread.new do
        loop do
          sleep(0.3)
          if signal_queue.any?
            listener.pause
            ask_what_to_do!
            listener.unpause
            Thread.pass
            signal_queue.shift
          end
        end
      end

      Signal.trap('INT') do
        abort!     if exiting?
        start_exit if interrupted?
        signal_queue << :int
        puts ' (Interrupted with CTRL+C)'.red
      end
    end

    attr_reader :signal_queue


    private

    def interrupted?
      signal_queue.any?
    end

    def ask_what_to_do!
      if @exiting
        abort!
      else
        answer = ask('--- What to do now? (q=quit, a=all-specs): ')
        case answer
        when 'q' then start_exit
        when 'a' then rspec_all
        else puts '--- Bad input, ignored.'.yellow
        end
        puts '--- Waiting for changes...'.cyan
      end
    end

    def start_exit
      return if exiting?
      @exiting = true
      exit
    end

    def exiting?
      @exiting
    end

    def ask question
      print question.yellow
      $stdout.flush
      STDIN.gets.chomp.strip.downcase
    end

  end
end
