# coding: utf-8

module Spectator
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

    def full_rspec_command
      @full_rspec_command ||= ENV['RSPEC_COMMAND'] || "bundle exec #{rspec_command}"
    end

    def rspec options
      unless options.empty?
        success = run("#{full_rspec_command} #{options}")
        notify( success ? success_message : failed_message )
      end
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

    def rspec_all
      rspec ENV['SPEC_DIR_GLOB'] || 'spec'
    end

    def rspec_files *files
      rspec files.join(' ')
    end

    def specs_for_file(path)
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
end
