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

    IDLE_TIMEOUT = 300  # close idle TCP connections after 5 minutes

    class IdleTimeout < StandardError; end

    def initialize(sock, client_addr, request_queue)
      # Ruby stupidly does a DNS lookup when you do a Socket#recvfrom.
      # This breaks DNS services, obviously.
      unless Socket.do_not_reverse_lookup
        raise RuntimeError.new("Socket.do_not_reverse_lookup must be true")
      end

      @sock = sock
      @client_host = client_addr[0]
      @client_port = client_addr[1]
      @request_queue = request_queue
      super()
    end

    private
    def thread_main
      response_queue = Queue.new
      puts "TCP connection received" # TODO XXX FIXME
      loop do
        len = sock_read(2).unpack("n")[0]
        break if len.nil?  # connection closed
        msg = sock_read(len)
        @request_queue << Request.new(
          :raw_message => msg,
          :tcp => true,
          :client_host => @client_host,
          :client_port => @client_port,
          :respond_lambda => lambda { |response| response_queue << response }
        )
        response = response_queue.shift # FIXME: timeout
        if response.is_a? Array   # AXFR
          for r in response
            raw_response = r.to_s
            sock_write([raw_response.length].pack("n") + raw_response)
          end
        else
          raw_response = response.to_s
          sock_write([raw_response.length].pack("n") + raw_response)
        end
      end
      puts "TCP connection closed" # DEBUG FIXME
    rescue IdleTimeout
      # Do nothing if the connection times out
      # XXX - should log here
    ensure
      # Make sure we always close the socket
      @sock.close
    end

    # Read the specified number of bytes from the socket, while still
    # stopping the thread if request_stop is invoked.  Note that if the
    # connection is terminated, this function might return fewer than the
    # specified number of bytes.
    def sock_read(bytes)
      buffer = []
      count = 0
      while count < bytes
        result = IO::select([@stop_pipe_r, @sock], nil, nil, IDLE_TIMEOUT)
        raise IdleTimeout if result.nil?    # timeout
        rr = result[0]
        check_stop
        raise "BUG: socket not returned by select()" unless rr.include?(@sock)
        begin
          data = @sock.recv_nonblock(bytes - count)
        rescue SystemCallError  # XXX: possible source of infinite loops?
          next
        end
        break if data.empty?  # Socket closed
        buffer << data
        count += data.length
      end
      return buffer.join("")
    end

    # Write the specified number of bytes to the socket, while still
    # stopping the thread if request_stop is invoked.  Note that if the
    # connection is terminated, this function might return fewer than the
    # specified number of bytes.
    #
    # Returns the number of bytes actually written.
    def sock_write(data)
      pos = 0
      while pos < data.length
        result = IO::select([@stop_pipe_r], [@sock], nil, IDLE_TIMEOUT)
        raise IdleTimeout if result.nil?    # timeout
        rr, ww = result[0,2]
        check_stop
        raise "BUG: socket not returned by select()" unless ww.include?(@sock)
        begin
          sent = @sock.write_nonblock(data[pos..-1])
        rescue Errno::EAGAIN, Errno::EWOULDBLOCK
          next
        rescue Errno::ECONNRESET
          break
        end
        pos += sent
      end
      return pos
    end

  end

end
