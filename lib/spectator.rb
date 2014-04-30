require 'ostruct'
require 'thread'
require 'spectator/version'
require 'spectator/debug'
require 'spectator/color'
require 'spectator/path_watcher'
require 'spectator/specs_matcher'
require 'spectator/success_notifier'
require 'spectator/spec_runner'
require 'spectator/ui'

module Spectator
  extend self

  def config(overrides_hash = {})
    Config.new(default_config_hash.merge(env_config_hash).merge(overrides_hash))
  end

  def env_config_hash
    config = {}
    config[:rspec_command]   = ENV['RSPEC_COMMAND']   if ENV['RSPEC_COMMAND']
    config[:spec_dir_regexp] = ENV['SPEC_DIR_REGEXP'] if ENV['SPEC_DIR_REGEXP']
    config[:base_dir_regexp] = ENV['BASE_DIR_REGEXP'] if ENV['BASE_DIR_REGEXP']
    config[:debug]           = ENV['SPECTATOR_DEBUG'] if ENV['SPECTATOR_DEBUG']
    config
  end

  def default_config_hash
    {
      rspec_command:   (File.exist?('.rspec') ? 'rspec' : 'spec'),
      spec_dir_regexp: 'spec',
      base_dir_regexp: 'app|lib|script',
      debug:           false,
    }
  end

  Config = Class.new(OpenStruct)

  class Runner
    def initialize(config)
      @config            = config
      @path_watcher      = PathWatcher.new(config)
      @ui                = UI.new(config)
      @spec_runner       = SpecRunner.new(config)
      @success_notifier  = SuccessNotifier.new(config)
      @specs_matcher     = SpecsMatcher.new(config)
    end

    attr_reader :config, :path_watcher, :ui, :spec_runner, :success_notifier, :specs_matcher

    def run
      $spectator_debug = config.debug

      path_watcher.on_change { ui << :run_specs }
      path_watcher.watch_paths!

      ui.on(:run_specs) do
        next unless ui.can_run_specs?
        ui.status = :running_specs
        files = path_watcher.pop_files
        specs = specs_matcher.specs_for(files)
        if specs.any?
          result = ui.run spec_runner.command(specs)
          success_notifier.notify(result)
        end
        ui.wait_for_changes
      end

      ui.on(:interrupt) do
        puts ' (Interrupted with CTRL+C)'.red
        p [ui.status, ui.interrupted_status]
        case ui.interrupted_status
        when :wait_for_input then ui.exit
        when :running_specs  then ui.wait_for_changes
        when :exiting        then Kernel.abort
        else Thread.new { ui.ask_what_to_do }
        end
      end

      trap('INT') { ui.interrupt! }

      ui.on(:run_all) do
        next unless ui.can_run_specs?

        ui.status = :running_specs
        result = ui.run(spec_runner.command)
        success_notifier.notify(result)
        ui.status = nil if ui.status == :running_specs
      end

      ui.start
    end
  end

  def run(*args, &block)
    Runner.new(*args, &block).run
  end
end
