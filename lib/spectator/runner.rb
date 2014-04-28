# coding: utf-8

require 'term/ansicolor'
require 'thread'
require 'listen'
require 'set'

require 'spectator/command_line'
require 'spectator/specs'
require 'spectator/control'

module Spectator
  class Runner
    String.send :include, Term::ANSIColor

    include CommandLine
    include Specs
    include Control

    def matchers
      @matchers ||= []
    end

    def queue
      @queue ||= Queue.new
    end



    def wait_for_changes
      puts '--- Waiting for changes...'.cyan

      loop do
        sleep 0.1 while queue.empty? or interrupted?

        files = []
        queue.size.times do
          files << queue.pop
        end

        files.compact!
        redo if files.empty?

        rspec_files(*specs_for(files))
      end
    end


    def puts *args
      print args.join("\n")+"\n"
    end

    def run_specs specs
      rules.each do |(regexp, action)|
        regexp = Regexp.new(regexp)
        if file =~ regexp
          m = regexp.match(file)
          action.call(m)
        end
      end
    end

    def wait_for_changes
      puts '--- Waiting for changes...'.cyan

      loop do
        sleep 0.1 while queue.empty? or interrupted?

        files = []
        queue.size.times do
          files << queue.pop
        end

        files.compact!
        redo if files.empty?

        rspec_files(*specs_for(files))
      end
    end

    def specs_for files
      specs = Set.new
      files = [files] unless files.respond_to? :each
      files.each do |file|
        matched = matchers.map do |matcher|
          file.scan(matcher).flatten.first.to_s.gsub(/\.rb$/,'')
        end.flatten.reject(&:empty?)
        specs += matched.uniq.map { |m| specs_for_file(m) }.flatten
      end
      specs.to_a
    end

    class EventQueue < Queue
    end

    attr_reader :events, :states

    def initialize config = {}, &block
      @config = config
      yield self if block_given?

      matchers << %r{^#{config.spec_dir_regexp}/(.*)_spec\.rb$}
      matchers << %r{^(?:#{config.base_dir_regexp})/(.*)(?:\.rb|\.\w+|)$}

      @events = EventQueue.new
      @states = StateMachine.new
      while (event = events.pop)
        states.send(event)
      end



      trap_int!
      Thread.abort_on_exception = true
      @runner   = Thread.new { wait_for_changes }
      @listener = Thread.new { watch_paths! }
      sleep
    end

    attr_reader :config
  end
end
