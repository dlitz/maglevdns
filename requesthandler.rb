require 'thread'
require 'routingcontext'

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

  protected

  def request
    @request
  end

  private
  def thread_main
    query = DNS::Message.new(@request[:raw_message])
    routing_context = RoutingContext.new(query, @request[:address])
    routing_result = eval(File.read("routes.rb"), routing_context.binding, "routes.rb", 1)
    puts "routing result: #{routing_result.inspect}"
  end

  # Throw :STOP_THREAD if request_stop has been called.
  def check_stop
    @mutex.synchronize { throw :STOP_THREAD if @stop_requested }
  end
end
