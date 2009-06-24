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

module MaglevDNS

  # Thread for handling incoming TCP connections
  class TCPConnectionThread < StoppableThread

    def initialize(client_addr_family, client_host, client_port, sock, request_queue)
      @client_addr_family = client_addr_family
      @client_host = client_host
      @client_port = client_port
      @sock = sock
      @request_queue = request_queue
      super()
    end

    private
    def thread_main
      puts "TCP connection received" # TODO XXX FIXME
    ensure
      # Make sure we always close the socket
      @sock.close
    end

  end

end
