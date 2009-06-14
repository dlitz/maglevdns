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
require 'thread'

module MaglevDNS
  class DispatcherThread < Thread
    def initialize(request_queue, thread_container)
      @request_queue = request_queue
      @thread_container = thread_container
      @mutex = Mutex.new
      @stop_requested = false
      super { thread_main }
    end

    def request_stop
      @mutex.synchronize {
        @stop_requested = true
        @request_queue << :NOOP
      }
    end

    private
    def thread_main
      catch :STOP_THREAD do
        loop do
          request = @request_queue.shift
          check_stop
          next if request == :NOOP
          @thread_container << RequestHandlerThread.new(request)
          @thread_container.prune!
        end
      end
    end

    # Throw :STOP_THREAD if request_stop has been called.
    def check_stop
      @mutex.synchronize { throw :STOP_THREAD if @stop_requested }
    end
  end
end
