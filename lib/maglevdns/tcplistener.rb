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
require 'maglevdns/stoppablethread'

module MaglevDNS
  class TCPListenerThread < StoppableThread

    def initialize(request_queue, host, port)
      @request_queue = request_queue
      @af = IPAddr.new(host).family   # Socket::AF_INET or Socket::AF_INET6
      @host = host
      @port = port
      super()
    end

    private
    def thread_main
      Socket.open(@af, Socket::Constants::SOCK_STREAM, 0) do |sock|
        sock.bind(Socket::pack_sockaddr_in(@port, @host))
        sock.listen(10) # XXX - hard-coded backlog
        loop do
          rr = IO::select([@stop_pipe_r, sock], nil, nil)[0]
          check_stop
          raise "BUG: socket not returned by select()" unless rr.include?(sock)
          begin
            s, raw_client_addr = sock.accept_nonblock()
          rescue SystemCallError  # XXX: possible source of infinite loops?
            next
          end
          port, host = Socket::unpack_sockaddr_in(raw_client_addr)
          TCPConnectionThread.new(s, [host, port], @request_queue)
        end
      end
    end

  end
end
