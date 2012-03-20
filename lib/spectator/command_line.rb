module Spectator
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
end
