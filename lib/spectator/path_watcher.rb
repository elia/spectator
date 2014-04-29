require 'listen'
require 'thread'
require 'spectator/debug'

module Spectator
  class PathWatcher

    def initialize(config)
      @config = config
      @queue = Queue.new
    end

    def has_changed_files?
      queue.size > 0
    end

    def on_change &block
      @on_change = block if block_given?
      @on_change
    end

    def pop_files
      files = []
      queue.size.times { files << queue.pop }
      files
    end

    def watch_paths!
      listener.start
    end

    attr_reader :queue, :config
    private :queue, :config

    def listener
      @listener ||= begin
        listener = Listen.to(Dir.pwd, :relative_paths => true)
        p [:watching, config.base_dir_regexp]
        listener = listener.filter %r{^(#{config.base_dir_regexp}|#{config.spec_dir_regexp})/}
        listener = listener.change do  |modified, added, removed|
          p ['modified, added, removed', modified, added, removed]
          files = [modified, added].flatten
          files.each { |relative| queue.push relative }
          p on_change
          on_change.call(files) if on_change && files.any?
        end
      end
    end
  end
end
