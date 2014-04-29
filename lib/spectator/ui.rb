require 'thread'
require 'spectator/debug'
require 'spectator/color'

module Spectator
  class UI
    def initialize(config)
      @mutex = Mutex.new
      @status_mutex = Mutex.new
      @status = nil
      @status_callbacks = {}
      @callbacks = {}
      @queue = Queue.new
    end

    def << event
      @queue << event
      p event
    end

    def start
      wait_for_changes
      loop do
        if @queue.empty?
          p_print '.'
          sleep $spectator_debug ? 0.3 : 0.05
        else
          event = @queue.pop
          p [:queue, event]
          @mutex.synchronize { @callbacks[event].call }
        end
      end
    end

    attr_reader :status

    def status= status
      @status_mutex.synchronize do
        @status = status
        (@status_callbacks[status] || noop).call
      end
    end

    def noop
      @noop ||= OpenStruct.new(call: nil)
    end

    def on_status status, &block
      @status_callbacks[status] = block
    end

    def on event, &block
      @callbacks[event] = block
    end

    def ask_what_to_do
      self.status = :wait_for_input
      answer = ask('--- What to do now? (q=quit, a=all-specs): ')
      case answer
      when 'q' then exit
      when 'a' then run_all
      else
        puts '--- Bad input, ignored.'.yellow
        wait_for_changes
      end
    end

    def run_all
      self << :run_all
      self.status = nil
    end

    def wait_for_changes
      self.status = nil
      puts '--- Waiting for changes...'.cyan
    end

    def ask question
      print question.yellow
      $stdout.flush
      STDIN.gets.chomp.strip.downcase
    end

    def exit
      self.status = :exiting
      puts '--- Exiting...'.white
      super
    end

    def terminal_columns
      cols = `stty -a 2>&1`.scan(/ (\d+) columns/).flatten.first
      $?.success? ? cols.to_i : 80
    end

    def run cmd
      $running = true
      start = Time.now
      puts "=== running: #{cmd} ".ljust(terminal_columns, '=').cyan
      success = system cmd
      puts "=== time: #{(Time.now - start).to_i} seconds ".ljust(terminal_columns, '=').cyan
      success
    ensure
      $running = false
    end

    def can_run_specs?
      status.nil?
    end
  end
end
