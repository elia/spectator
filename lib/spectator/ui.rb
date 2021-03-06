require 'thread'
require 'spectator/debug'
require 'spectator/color'

module Spectator
  class UI
    def initialize(config)
      @mutex = Mutex.new
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
      thread = Thread.new { event_loop }
      p thread
      Thread.pass
      sleep
    end

    attr_accessor :status

    def noop
      @noop ||= lambda {}
    end

    def interrupt!
      self.interrupted_status = status
      self << :interrupt
    end

    attr_accessor :interrupted_status

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
      self.status = :waiting_for_changes
      self << :run_all
    end

    def wait_for_changes
      return if status == :waiting_for_changes
      self.status = :waiting_for_changes
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
      p [:can_run_specs?, status]
      status == :waiting_for_changes
    end


    private

    def terminal_columns
      cols = `tput cols 2> /dev/tty`.strip.to_i
      ($?.success? && cols.nonzero?) ? cols : 80
    end

    def event_loop
      loop do
        event = @queue.pop
        p [:queue, event]
        @mutex.synchronize { @callbacks[event].call }
      end
    end

  end
end
