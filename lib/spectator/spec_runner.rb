module Spectator
  class SpecRunner
    def initialize(config)
      @config = config
    end
    attr_reader :config

    def command files = default_files
      "#{config.rspec_command} #{files.join(' ')}"
    end

    def default_files
      Dir['**/**'].grep(%r{^(?:#{config.spec_dir_regexp}\b)/?$})
    end
  end
end
