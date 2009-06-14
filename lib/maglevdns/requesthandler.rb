require 'thread'

module MaglevDNS
  class RequestHandlerThread < Thread

    def initialize(request)
      @request = request
      @mutex = Mutex.new
      @stop_requested = false
      super { thread_main }
    end

    # Ask the thread to exit
    def request_stop
      @mutex.synchronize {
        @stop_requested = true
      }
    end

    # Throw :STOP_THREAD if request_stop has been called.
    def check_stop
      @mutex.synchronize { throw :STOP_THREAD if @stop_requested }
    end

    private
    def thread_main
      catch :STOP_THREAD do
        controller = ApplicationController.new(@request, self)
        begin
          controller.handle_query
        rescue BaseController::ReturnResponse => e
          unless e.response.nil?
            @request[:respond_proc].call(@request, e.response.to_s)
          end
        end
      end
    end

  end
end
