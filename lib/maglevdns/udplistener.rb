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
  class UDPListenerThread < StoppableThread

    def initialize(options={})
      @listen_address = {:family => options[:address_family], :bind_address => options[:bind_address]}
      @request_queue = options[:request_queue]
      super()
    end

    private
    def thread_main
      UDPSocket.open(@listen_address[:family]) do |sock|
        sock.bind(*@listen_address[:bind_address])
        loop do
          rr = IO::select([@stop_pipe_r, sock], [], [])[0]
          check_stop
          raise "BUG: socket not returned by select()" unless rr.include?(sock)
          msg, addr = sock.recvfrom(65535)
          @request_queue << {
            :listener => self,
            :raw_message => msg,
            :tcp => false,
            :address => addr,
            :sock => sock,
            :respond_proc => proc {|*args| respond(*args) },
          }
        end
      end
    end

    def respond(request, raw_response)
      request[:sock].send(raw_response, 0, request[:address][3], request[:address][1])
    end
  end
end
