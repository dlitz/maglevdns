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
require 'ipaddr'

module MaglevDNS

  class ScriptEvalContext

    UDP_QUERY_TIMEOUT = 30  # give up UDP queries after 30 seconds
    TCP_QUERY_TIMEOUT = 30  # give up TCP queries after 30 seconds

    def initialize(request)
      @request = request
    end

    def eval_from_file(filename)
      eval(File.read(filename), binding, filename, 1)
    end

    def check_stop
      Thread.current.check_stop
    end

    # Return the current query (a DNS::Message object)
    def query
      return @request.query
    end

    # Return true if the query was received over TCP.
    def tcp?
      return @request.tcp?
    end

    # Return true if this is an AXFR query.
    def axfr?
      return @request.axfr?
    end

    # Return true if the RD bit was set in the query.
    def recursion_desired?
      return query.rd
    end

    # Return true if the client address matches the specified list of IP
    # address.  The parameter may also be a single address.
    def match_ip?(addresses)
      client_address = IPAddr.new(@request.client_host)
      addresses = [addresses] if addresses.is_a?(String)
      for address in addresses
        match_address = IPAddr.new(address)
        return true if match_address.include?(client_address)
      end
      return false
    end

    # Return true if the query is for a name in the specified list of zones.
    # The parameter may also be a single address.
    def match_zone?(zones)
      if zones.is_a?(String)
        zone = zones
        q = query.qname.map { |label| label.downcase }
        z = DNS.parse_display_name(zone.downcase)
        return z == q[-z.length..-1]  # Return true if q ends with z
      else
        zones.each { |zone| return true if match_zone?(zone) }
        return false
      end
    end

    # Forward the current query to the specified host.
    #
    # Supported options::
    # [:port] The remote port to send the request to (default: 53).
    # [:tcp] If true, send the request over TCP.  If false, send the request
    #        over UDP.  The default is to use the same protocol used in the
    #        request, i.e. the return value of the tcp? method.
    def forward_to(host, options={})
      options = { :tcp => tcp?, :port => 53 }.merge(options)
      raise ArgumentError.new("host must not be a network address") if host.include?('/') # HACK: IPAddr doesn't export the prefix length
      host_addr = IPAddr.new(host)
      if options[:tcp]
        tcp_forward_to(host_addr, options)
      else  # UDP
        udp_forward_to(host_addr, options)
      end
    end

    private
    def udp_forward_to(host_addr, options)
      UDPSocket.open(host_addr.family) do |sock|
        # SECURITY TODO: Source-address port randomization
        sock.send(query.to_s, 0, host_addr.to_s, options[:port])
        t0 = Time.now
        while Time.now - t0 < UDP_QUERY_TIMEOUT
          check_stop
          result = IO::select([sock], [], [], UDP_QUERY_TIMEOUT)  # TODO: use a pipe to detect request_stop
          check_stop
          raise ReturnResponse.new(nil) if result.nil?  # timeout
          raise "BUG: sock not in select" unless result[0].include?(sock)
          msg, addr = sock.recvfrom(65535)
          begin
            response = DNS::Message.new(msg)
            raise ArgumentError if response.id != query.id
            raise ReturnResponse.new(response)
          rescue ArgumentError
            nil
          end
        end
      end
    end

    def tcp_forward_to(host_addr, options)
      TCPSocket.open(host_addr.to_s, options[:port]) do |sock|
        raw_query = query.to_s
        recv_lambda = lambda { |sock, t0, count|
          retval = ""
          while count > 0
            check_stop
            dt = Time.now - t0
            break if dt >= TCP_QUERY_TIMEOUT
            result = IO::select([sock], [], [], TCP_QUERY_TIMEOUT - dt) # TODO: use a pipe to detect request_stop
            check_stop
            break if result.nil?
            raise "BUG: sock not in select" unless result[0].include?(sock)
            data = sock.recv(count)
            return retval if data.empty?  # EOF; connection closed
            retval += data
            count -= data.length
          end
          retval = nil if retval.empty?
          return retval
        }

        sock.send([raw_query.length].pack("n") + raw_query, 0)

        if axfr?
          # HACK - special case for AXFR
          response_messages = []
          soa_records = 0

          loop {
            t0 = Time.now
            raw_length = ""
            raw_response = nil
            while Time.now - t0 < TCP_QUERY_TIMEOUT
              raw_len = recv_lambda.call(sock, t0, 2)
              raise ReturnResponse.new(nil) if raw_len.nil? or raw_len.length != 2  # timeout
              len = raw_len.unpack("n")[0]
              raw_response = recv_lambda.call(sock, t0, len)
              raise ReturnResponse.new(nil) if raw_response.nil? or raw_response.length != len  # timeout
              #raise ReturnResponse.new(raw_response)
              break
            end
            raise ReturnResponse.new(nil) if raw_response.nil? # timeout
            response_messages << raw_response

            # Stop after the final SOA record
            for rr in DNS::Message.new(raw_response).answer
              soa_records += 1 if rr.type == DNS::Types::SOA
            end
            raise ReturnResponse.new(response_messages) if soa_records >= 2
          }
        else
          # Normal query handling
          t0 = Time.now
          raw_length = ""
          while Time.now - t0 < TCP_QUERY_TIMEOUT
            raw_len = recv_lambda.call(sock, t0, 2)
            raise ReturnResponse.new(nil) if raw_len.nil? or raw_len.length != 2  # timeout
            len = raw_len.unpack("n")[0]
            raw_response = recv_lambda.call(sock, t0, len)
            raise ReturnResponse.new(nil) if raw_response.nil? or raw_response.length != len  # timeout
            raise ReturnResponse.new(raw_response)
          end
        end
      end
    end


  end

end
