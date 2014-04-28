require 'spectator/version'
# require 'spectator/runner'
require 'ostruct'
require 'thread'
require 'term/ansicolor'
String.send :include, Term::ANSIColor

$spectator_debug = ARGV.include?('--debug')
module Kernel
  alias real_p p
  def p *args
    real_p *args if $spectator_debug
  end
  def p_print *args
    print *args if $spectator_debug
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

  def run
    path_watcher.on_change { ui << :run_specs }
    path_watcher.watch_paths!

    ui.on(:run_specs) do
      ui.status = :running_specs
      files = path_watcher.pop_files
      specs = SpecsMatcher.new(config, files).specs
      spec_runner.run specs
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

    ui.on(:run_all) { spec_runner.run_all }
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
      # sleep
    end

    private

    attr_reader :queue, :config

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
    def initialize(config, files)
      @config = config
      @files = files
    end

    def specs
      # TODO
      files.grep(/_spec.rb/)
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
          sleep 0.3
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
      when 'a' then self << :run_all
      else puts '--- Bad input, ignored.'.yellow
      end
      wait_for_changes
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
  end

  class SpecRunner
    def initialize(config)
      @config = config
    end
    attr_reader :config

    def run files
      success = cmd("#{config.rspec_command} #{files.join(' ')}")
      notify(success)
    end

    def cmd *command
      p command
      system *command
    end

    def notify(success)
      p [:success, success]
      #TODO
      # success ? success_message : failed_message
    end
  end

end
