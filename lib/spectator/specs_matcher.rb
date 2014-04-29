require 'spectator/debug'
require 'spectator/color'

module Spectator
  class SpecsMatcher
    def initialize(config)
      @config = config
      @matchers = [
        %r{^#{config.spec_dir_regexp}/(.*)_spec\.rb$},
        %r{^(?:#{config.base_dir_regexp})/(.*)(?:\.rb|\.\w+|)$},
      ]
    end
    attr_reader :matchers

    def specs_for(files)
      files.flat_map do |path|
        print "--- Searching specs for #{path.inspect}...".yellow
        specs = match_specs path
        puts specs.empty? ? ' nothing found.'.red : " #{specs.size} matched.".green
        specs
      end
    end

    def match_specs file
      matched = matchers.map do |matcher|
        file.scan(matcher).flatten.first.to_s.gsub(/\.rb$/,'')
      end.flatten.reject(&:empty?)

      matched.uniq.map do |path|
        Dir['**/**'].grep(%r{^#{config.spec_dir_regexp}}).grep(/\b#{path}((_spec)?\.rb)?$/)
      end.flatten
    end

    attr_reader :config, :files
  end
end
