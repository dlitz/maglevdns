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

    def initialize(options={})
      @listen_address = {
        :family => options[:address_family],
        :bind_args => [Socket::pack_sockaddr_in(options[:port], options[:host])],
      }
      @request_queue = options[:request_queue]
      super()
    end

    private
    def thread_main
      Socket.open(@listen_address[:family], Socket::Constants::SOCK_STREAM, 0) do |sock|
        sock.bind(*@listen_address[:bind_args])
        sock.listen(10) # XXX - hard-coded backlog
        loop do
          rr = IO::select([@stop_pipe_r, sock], [], [])[0]
          check_stop
          raise "BUG: socket not returned by select()" unless rr.include?(sock)
          client_sock, client_addr = sock.accept()
          port, host = Socket::unpack_sockaddr_in(client_addr)
          ipaddr = IPAddr.new(host)
          # TODO FIXME: add thread to ThreadContainer
          TCPConnectionThread.new(ipaddr.family, ipaddr.to_s, port, client_sock, @request_queue)
#          @request_queue << {
#            :listener => self,
#            :raw_message => msg,
#            :tcp => true,
#            :address => client_addr,
#            :sock => client_sock,
#            :respond_lambda => lambda {|*args| respond(*args) },
#          }
        end
      end
    end

  end
end
