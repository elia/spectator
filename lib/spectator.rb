# coding: utf-8

require 'term/ansicolor'
require 'thread'
require 'fssm'
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
      FSSM.monitor(Dir.pwd, '{app,spec,lib,script}/**/*') do |monitor|
        monitor.update {|base, relative| puts relative; queue.push relative }
        monitor.create {|base, relative| puts relative; queue.push relative }
        monitor.delete {|base, relative| puts relative; '''do nothing'''            }
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
        sleep 0.1 while queue.empty?
        
        files = []
        queue.size.times do
          files << queue.pop
        end

        specs = Set.new
        files.each do |file|
          specs += matchers.map do |matcher|
            file_signature = $1.gsub(/\.rb$/,'') if matcher =~ file
            specs_for file
          end.flatten
        end
        
        rspec_files specs
      end
    end
    
    def initialize &block
      yield self if block_given?
      
      
      matchers << %r{^spec/(.*)_spec\.rb$}
      matchers << %r{^(?:app|lib|script)/(.*)(?:\.rb|\.\w+|)$}

      trap_int!
      @runner  = Thread.new { wait_for_changes }
      watch_paths!
    end
  end
  
  
  
  def self.run
    Runner.new
  end
end
