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

      Signal.trap('INT') do
        puts  ' (Interrupted with CTRL+C)'.red
        if @interrupted
          @exiting ? abort! : exit
        else
          @interrupted = true
          print '--- What to do now? (q=quit, a=all-specs): '.yellow
          case STDIN.gets.chomp.strip.downcase
          when 'q'; @interrupted = false; exit
          when 'a'; @interrupted = false; rspec_all
          else
            @interrupted = false
            puts '--- Bad input, ignored.'.yellow
          end
          puts '--- Waiting for changes...'.cyan
        end
      end
    end
    
  end
end
