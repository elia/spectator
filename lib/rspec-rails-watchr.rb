# coding: utf-8

require 'rspec-rails-watchr/version'
require 'term/ansicolor'

class SpecWatchr
  String.send :include, Term::ANSIColor

  module CommandLine
    def terminal_columns
      cols = `stty -a`.scan(/ (\d+) columns/).flatten.first
      $?.success? ? cols.to_i : nil
    end

    def run cmd
      puts "=== running: #{cmd} ".ljust(terminal_columns, '=').cyan
      success = system cmd
      puts "===".ljust(terminal_columns, '=').cyan
      success
    end

    def clear!
      system 'clear'
    end
  end

  module Specs
    def notify message
      Thread.new do
        begin
          require 'notify'
          Notify.notify 'RSpec Result:', message
        rescue
          nil
        end
      end
    end

    def rspec_command
      @rspec_command ||= File.exist?('./.rspec') ? 'rspec' : 'spec'
    end

    def rspec options
      unless options.empty?
        success = run("bundle exec #{rspec_command} #{options}")
        notify( success ? '♥♥ SUCCESS :) ♥♥' : '♠♠ FAILED >:( ♠♠' )
      end
    end

    def rspec_all
      rspec 'spec'
    end

    def rspec_files *files
      rspec files.join(' ')
    end

    def specs_for(path)
      print "--- Searching specs for #{path.inspect}...".yellow
      specs = match_specs path, Dir['spec/**/*_spec.rb']
      puts specs.empty? ? ' nothing found.'.red : " #{specs.size} matched.".green
      specs
    end

    def default_rails_matcher path, specs
      specs.grep(/\b#{path}((_spec)?\.rb)?$/)
    end

    def match_specs path, specs
      matched_specs = @custom_matcher.call(path, specs) if @custom_matcher
      matched_specs = default_rails_matcher(path, specs) if matched_specs.nil?
    end
  end

  module Control
    def exit_watchr
      @exiting = true
      puts '--- Exiting...'.white
      exit
    end

    def abort_watchr!
      puts '--- Forcing abort...'.white
      abort("\n")
    end

    def reload!
      # puts ARGV.join(' ')
      exec('bundle exec watchr')
    end

    def reload_file_list
      require 'shellwords'
      system "touch #{__FILE__.shellescape}"
      # puts '--- Watch\'d file list reloaded.'.green
    end

    def trap_int!
      # Ctrl-C

      @interrupted ||= false

      Signal.trap('INT') { 
        puts  ' (Interrupted with CTRL+C)'.red
        if @interrupted
          @exiting ? abort_watchr : exit_watchr
        else
          @interrupted = true
          # reload_file_list
          print '--- What to do now? (q=quit, a=all-specs, r=reload): '.yellow
          case STDIN.gets.chomp.strip.downcase
          when 'q'; @interrupted = false; exit_watchr
          when 'a'; @interrupted = false; rspec_all
          when 'r'; @interrupted = false; reload!
          else
            @interrupted = false
            puts '--- Bad input, ignored.'.yellow
          end
          puts '--- Waiting for changes...'.cyan
        end
      }
    end
  end


  include CommandLine
  include Specs
  include Control

  def initialize watchr, &block
    @custom_matcher = block if block_given?
    @watchr = watchr

    watchr.watch('^spec/(.*)_spec\.rb$')                     {|m| rspec_files specs_for(m[1])}
    watchr.watch('^(?:app|lib|script)/(.*)(?:\.rb|\.\w+|)$') {|m| rspec_files specs_for(m[1].gsub(/\.rb$/,''))}

    trap_int!

    puts '--- Waiting for changes...'.cyan
  end
end


class Object
  module Rspec
    module Rails
      module Watchr
        def self.new *args, &block
          SpecWatchr.new *args, &block
        end
      end
    end
  end
end