module Piggly
  module Util

    #
    # Executes blocks in parallel subprocesses
    #
    class ProcessQueue

      def self.concurrent=(count)
        @concurrent = count
      end

      def self.concurrent
        @concurrent || 1
      end

      def initialize(concurrent = self.class.concurrent)
        @concurrent, @items = concurrent, []
      end

      def concurrent=(value)
        @concurrent = value
      end

      def size
        @items.size
      end

      def queue(&block)
        @items << block
      end

      alias add queue

      def execute
        # Test if fork is supported
        forkable =
          begin
            Process.wait(Process.fork { exit! 60 })
            raise unless $?.exitstatus.to_i == 60
            true
          rescue Exception
            false
          end

        if forkable
          concurrently
        else
          serially
        end
      end

    protected

      def serially
        $stderr.puts "ProcessQueue running serially"

        while block = @items.shift
          block.call
        end
      end

      def concurrently
        $stderr.puts "ProcessQueue running concurrently"
        active = 0

        # enable enterprise ruby feature
        GC.copy_on_write_friendly = true if GC.respond_to?(:copy_on_write_friendly=)

        while block = @items.shift
          if active >= @concurrent
            pid = Process.wait
            active -= 1
          end

          # use exit! to avoid auto-running any test suites
          Process.fork do
            begin
              block.call
              exit! 0
            rescue Exception
              $stderr.puts $!
              $stderr.puts "\t" + $!.backtrace.join("\n\t")
              exit! 1
            end
          end

          active += 1
        end

        Process.waitall
      end

    end
  end
end
