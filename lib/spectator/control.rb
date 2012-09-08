module Spectator
  module Control
    def exit
      @exiting = true
      puts '--- Exiting...'.white
      Kernel.exit
    end

    def abort!
      puts '--- Forcing abort...'.white
      Kernel.abort("\n")
    end

    def trap_int!
      # Ctrl-C
      @interrupted ||= false
      Signal.trap('INT') { ask_what_to_do! }
    end


    private

    def ask_what_to_do!
      puts ' (Interrupted with CTRL+C)'.red
      if @interrupted
        @exiting ? abort! : exit
      else
        @interrupted = true
        case ask('--- What to do now? (q=quit, a=all-specs): ')
        when 'q' then @interrupted = false; exit
        when 'a' then @interrupted = false; rspec_all
        else
          @interrupted = false
          puts '--- Bad input, ignored.'.yellow
        end
        puts '--- Waiting for changes...'.cyan
      end
    end

    def ask question
      print question.yellow
      $stdout.flush
      STDIN.gets.chomp.strip.downcase
    end

  end
end
