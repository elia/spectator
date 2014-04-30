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
        matchable_paths = self.matchable_paths(path)
        print "--- Searching specs for #{path.inspect} (as: #{matchable_paths.join(", ")})...".yellow
        specs = match_specs(matchable_paths)
        puts specs.empty? ? ' nothing found.'.red : " #{specs.size} matched.".green
        specs
      end
    end

    def matchable_paths(file)
      matchers.map do |matcher|
        file.scan(matcher).flatten.first.to_s.gsub(/\.rb$/,'')
      end.flatten.reject(&:empty?)
    end

    def match_specs matchable_paths
      matchable_paths.uniq.map do |path|
        # Dir['**/**'].grep(%r{^#{config.spec_dir_regexp}}).grep(/\b#{path}((_spec)?\.rb)?$/)
        Dir['**/**'].grep(%r{^#{config.spec_dir_regexp}}).grep(/\b#{path}_spec\.rb$/)
      end.flatten
    end

    attr_reader :config, :files
  end
end
