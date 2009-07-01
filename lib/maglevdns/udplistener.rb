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
require 'ipaddr'

module MaglevDNS
  class UDPListenerThread < StoppableThread

    def initialize(request_queue, host, port)
      # By default, Ruby blocks when calling UDPSocket#recvfrom_nonblock (and
      # probably Socket#accept_nonblock) in order to look up the client
      # hosts's canonical name in the DNS.  Make sure this brain-damaged
      # behaviour is disabled.
      unless Socket.do_not_reverse_lookup
        raise RuntimeError.new("Socket.do_not_reverse_lookup must be true")
      end

      @request_queue = request_queue
      @af = IPAddr.new(host).family   # Socket::AF_INET or Socket::AF_INET6
      @host = host
      @port = port
      super()
    end

    private
    def thread_main
      UDPSocket.open(@af) do |sock|
        sock.bind(@host, @port)
        loop do
          rr = IO::select([@stop_pipe_r, sock], nil, nil)[0]
          check_stop
          raise "BUG: socket not returned by select()" unless rr.include?(sock)
          begin
            msg, addr = sock.recvfrom_nonblock(65535)
          rescue SystemCallError
            next
          end
          host, port = addr[3], addr[1]
          @request_queue << Request.new(
            :raw_message => msg,
            :tcp => false,
            :client_host => host,
            :client_port => port,
            :respond_lambda => lambda { |raw_response| sock.send(raw_response, 0, host, port) }
          )
        end
      end
    end

  end
end
