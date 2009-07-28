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

  class Request

    def initialize(opts={})
      @tcp = opts[:tcp] ? true : false
      @client_host = opts[:client_host] or raise ArgumentError.new("option :client_host missing")
      @client_port = opts[:client_port] or raise ArgumentError.new("option :client_port missing")
      @respond_lambda = opts[:respond_lambda] or raise ArgumentError.new("option :respond_lambda missing")
      @raw_message = opts[:raw_message] or raise ArgumentError.new("option :raw_message missing")
      @query = nil
    end

    # Return true if the query was received over TCP.
    def tcp?
      return @tcp
    end

    def axfr?
      return query.qtype == DNS::Types::AXFR
    end

    def query
      return @query unless @query.nil?
      @query = MaglevDNS::DNS::Message.new(@raw_message)
      return @query
    end

    def respond(response)
      @respond_lambda.call(response)
    end

    # Return the host part of the network address of the client
    def client_host
      return @client_host
    end

    # Return the client port number
    def client_port
      return @client_port
    end

  end

end
