# coding: utf-8

require 'term/ansicolor'
require 'thread'
require 'listen'
require 'set'

require 'spectator/version'
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

    def watch_paths!
      listener.start
      sleep
    end

    def listener
      @listener ||= begin
        listener = Listen.to(Dir.pwd, :relative_paths => true)
        listener = listener.filter %r{^(app|spec|lib|script)/}
        listener = listener.change do  |modified, added, removed|
          [modified, added].flatten.each { |relative| queue.push relative }
        end
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

    def initialize &block
      yield self if block_given?

      spec_dir_glob = ENV['SPEC_DIR_GLOB'] || 'spec'
      base_dir_glob = ENV['BASE_DIR_GLOB'] || 'app|lib|script'
      matchers << %r{^#{spec_dir_glob}/(.*)_spec\.rb$}
      matchers << %r{^(?:#{base_dir_glob})/(.*)(?:\.rb|\.\w+|)$}

      trap_int!
      Thread.abort_on_exception = true
      @runner  = Thread.new { wait_for_changes }
      watch_paths!
    end
  end



  def self.run
    Runner.new
  end
end
