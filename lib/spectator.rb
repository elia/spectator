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
end
