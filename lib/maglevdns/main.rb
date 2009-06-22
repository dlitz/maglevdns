#--
# MaglevDNS
# Copyright (c) 2009 Dwayne C. Litzenberger <dlitz@dlitz.net>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++
require 'socket'
require 'thread'

require 'maglevdns'

module MaglevDNS
  def self.main(request_handler_class)

    Thread.abort_on_exception = true

    request_queue = Queue.new

    thread_container = ThreadContainer.new
    thread_container << UDPListenerThread.new(
      :address_family => Socket::AF_INET6,
      :bind_address => ["::", 5354],
      :request_queue => request_queue
    )
    thread_container << DispatcherThread.new(request_queue, thread_container, request_handler_class)

    puts "Press enter to stop:"
    $stdin.gets

    thread_container.request_stop
    thread_container.join
  end
end
