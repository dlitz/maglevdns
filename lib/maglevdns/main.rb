require 'socket'
require 'thread'

require 'maglevdns'

module MaglevDNS
  def self.main
    require './app/app_controller'

    Thread.abort_on_exception = true

    request_queue = Queue.new

    thread_container = ThreadContainer.new
    thread_container << UDPListenerThread.new(
      :address_family => Socket::AF_INET6,
      :bind_address => ["::", 5354],
      :request_queue => request_queue
    )
    thread_container << DispatcherThread.new(request_queue, thread_container)

    puts "Press enter to stop:"
    gets

    thread_container.request_stop
    thread_container.join
  end
end
