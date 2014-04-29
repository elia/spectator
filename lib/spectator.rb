require 'spectator/version'
# require 'spectator/runner'
require 'ostruct'
require 'thread'
require 'term/ansicolor'
String.send :include, Term::ANSIColor

module Kernel
  alias real_p p
  def p(*args)
    real_p(*args) if $spectator_debug
  end
  def p_print(*args)
    print(*args) if $spectator_debug
  end
end

module Spectator
  extend self

  def config
    @config ||= begin
      config = OpenStruct.new
      config.rspec_command   = ENV['RSPEC_COMMAND']   || (File.exist?('.rspec') ? 'rspec' : 'spec')
      config.spec_dir_regexp = ENV['SPEC_DIR_REGEXP'] || 'spec'
      config.base_dir_regexp = ENV['BASE_DIR_REGEXP'] || 'app|lib|script'
      config.debug = ARGV.include?('debug')
      config
    end
  end

  def path_watcher
    @path_watcher ||= PathWatcher.new(config)
  end

  def ui
    @ui ||= UI.new(config)
  end

  def spec_runner
    @spec_runner ||= SpecRunner.new(config)
  end

  def success_notifier
    @success_notifier ||= SuccessNotifier.new(config)
  end

  def run
    $spectator_debug = config.debug

    path_watcher.on_change { ui << :run_specs }
    path_watcher.watch_paths!

    ui.on(:run_specs) do
      next unless ui.can_run_specs?

      ui.status = :running_specs
      files = path_watcher.pop_files
      specs = SpecsMatcher.new(config).specs_for(files)
      result = ui.run spec_runner.command(specs)
      success_notifier.notify(result)
      ui.status = nil if ui.status == :running_specs
    end

    ui.on(:interrupt) do
      puts ' (Interrupted with CTRL+C)'.red
      case ui.status
      when :wait_for_input then ui.exit
      when :running_specs  then ui.noop
      when :exiting        then Kernel.abort
      else Thread.new { ui.ask_what_to_do }
      end
    end

    trap('INT') { ui << :interrupt }

    ui.on(:run_all) do

      next unless ui.can_run_specs?
      ui.status = :running_specs
      result = ui.run(spec_runner.command)
      success_notifier.notify(result)
      ui.status = nil if ui.status == :running_specs
    end

    ui.start
  end






  # CLASSES

  class PathWatcher
    require 'listen'
    require 'thread'

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

  class UI
    def initialize(config)
      @mutex = Mutex.new
      @status_mutex = Mutex.new
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
      loop do
        if @queue.empty?
          p_print '.'
          sleep $spectator_debug ? 0.3 : 0.05
        else
          event = @queue.pop
          p [:queue, event]
          @mutex.synchronize { @callbacks[event].call }
        end
      end
    end

    attr_reader :status

    def status= status
      @status_mutex.synchronize do
        @status = status
        (@status_callbacks[status] || noop).call
      end
    end

    def noop
      @noop ||= OpenStruct.new(call: nil)
    end

    def on_status status, &block
      @status_callbacks[status] = block
    end

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
      self << :run_all
      self.status = nil
    end

    def wait_for_changes
      self.status = nil
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

    def terminal_columns
      cols = `stty -a 2>&1`.scan(/ (\d+) columns/).flatten.first
      $?.success? ? cols.to_i : 80
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
      status.nil?
    end
  end

  class SuccessNotifier
    require 'notify'

    def initialize(config)
      @config ||= config
      if osx?
        begin
          require 'terminal-notifier'
        rescue LoadError => e
          $stderr.puts e.message
          $stderr.puts 'On OSX you should use notification center: gem install terminal-notifier'.red
        end
      end
    end

    def notify(success)
      message = success ? success_message : failed_message
      Thread.new { Notify.notify 'RSpec Result:', message }
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
  end

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
