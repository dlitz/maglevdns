require 'thread'
require 'socket'

class UDPListenerThread < Thread

  def initialize(options={})
    @listen_address = {:family => options[:address_family], :host => options[:bind_host], :port => options[:bind_port]}
    @request_queue = options[:request_queue]
    @mutex = ::Mutex.new
    @stop_requested = false
    @stop_pipe_r, @stop_pipe_w = IO::pipe   # pipe used for stopping the thread during select()
    super { thread_main }
  end

  # Ask the thread to exit
  def request_stop
    @mutex.synchronize {
      raise "Not running" if @thread.nil?
      @stop_requested = true
      @stop_pipe_w.close unless @stop_pipe_w.closed?  # send a 'signal' to the thread
    }
  end

  private
  def thread_main
    catch (:STOP_THREAD) do
      ::UDPSocket.open(@listen_address[:family]) do |sock|
        sock.bind(@listen_address[:host], @listen_address[:port])
        loop do
          rr = ::IO::select([@stop_pipe_r, sock], [], [])[0]
          check_stop
          raise "BUG: socket not returned by select()" unless rr.include?(sock)
          msg, addr = sock.recvfrom(65535)
          @request_queue << {:listener => self, :message => msg, :address => addr}
        end
      end
    end
  ensure
    @stop_pipe_r.close
    @stop_pipe_r = nil
  end

  # Throw :STOP_THREAD if request_stop has been called.
  def check_stop
    @mutex.synchronize { throw :STOP_THREAD if @stop_requested }
  end
end

#u = UDPListenerThread.new(::Socket::AF_INET6, "::", 5354)
