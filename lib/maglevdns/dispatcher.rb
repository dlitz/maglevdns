require 'thread'

module MaglevDNS
  class DispatcherThread < Thread
    def initialize(request_queue, thread_container)
      @request_queue = request_queue
      @thread_container = thread_container
      @mutex = Mutex.new
      @stop_requested = false
      super { thread_main }
    end

    def request_stop
      @mutex.synchronize {
        @stop_requested = true
        @request_queue << :NOOP
      }
    end

    private
    def thread_main
      catch :STOP_THREAD do
        loop do
          request = @request_queue.shift
          check_stop
          next if request == :NOOP
          @thread_container << RequestHandlerThread.new(request)
          @thread_container.prune!
        end
      end
    end

    # Throw :STOP_THREAD if request_stop has been called.
    def check_stop
      @mutex.synchronize { throw :STOP_THREAD if @stop_requested }
    end
  end
end
