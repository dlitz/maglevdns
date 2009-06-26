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

    # Initialize a new server using the specified options.
    #
    # The following options are supported::
    # [:script_filename]
    #   Filename of the script to execute to process incoming queries.
    # [:listeners]
    #   An array of descriptors (hashes) describing what listeners to start.
    #   Each descriptor hash contains the following keys:
    #     [:host]  host address to listen on (String)
    #     [:port]  port to listen on (Integer)
    def initialize(opts={})
      # Handle option :script_filename
      File.read(opts[:script_filename])   # Test reading the file; raises exception on failure
      @script_filename = opts[:script_filename]

      # Handle option :listeners
      raise ArgumentError.new("No listeners") if opts[:listeners].nil? or opts[:listeners].empty?
      @listener_descriptors = opts[:listeners]

      Thread.current[:thread_stopper] = ThreadStopper.new unless Thread.current[:thread_stopper]
      @thread_stopper = Thread.current[:thread_stopper]
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
      for desc in @listener_descriptors
        UDPListenerThread.new(@request_queue, desc[:host], desc[:port])
        TCPListenerThread.new(@request_queue, desc[:host], desc[:port])
      end

      # Start dispatcher
      DispatcherThread.new(@request_queue, @script_filename)

      return nil
    end

    # Request that the server stop
    def request_stop
      @thread_stopper.request_stop
    end

    # Wait for the server to stop (typically done after invoking request_stop)
    def join
      @thread_stopper.join
    end

  end

end
