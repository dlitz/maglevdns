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

  class Server
    def initialize(opts={})
      @request_handler = opts[:request_handler]
      @listener_factory_lambdas = opts[:listener_factory_lambdas]
      @threads = ThreadContainer.new
      @request_queue = Queue.new
      @started = false
      @finished = false
    end

    # Start the server
    def start
      # Check if the this method has already been called
      raise ArgumentError.new("already started") if @started
      @started = true

      # Start listeners
      for llambda in @listener_factory_lambdas
        @threads.add_thread! llambda.call(@request_queue)
      end

      # Start dispatcher
      @threads.add_thread! DispatcherThread.new(@request_queue, @request_handler, @threads)

      return nil
    end

    # Request that the server stop
    def request_stop
      @threads.request_stop
    end

    # Wait for the server to stop (typically done after invoking request_stop)
    def join
      @threads.join
    end

  end

end
