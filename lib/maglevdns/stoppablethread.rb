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
  class StoppableThread < ::Thread

    def initialize
      @mutex = ::Mutex.new
      @stop_requested = false
      @stop_pipe_r, @stop_pipe_w = ::IO::pipe # pipe used for breaking out of select() calls
      super() do
        begin
          catch(:STOP_THREAD) { thread_main }
        ensure
          @stop_pipe_r.close
          @stop_pipe_r = nil
        end
      end
    end

    # Ask the thread to exit
    def request_stop
      @mutex.synchronize {
        @stop_requested = true
        @stop_pipe_w.close unless @stop_pipe_w.closed?  # send a 'signal' to the thread
        yield if block_given?
      }
    end

    # Throw :STOP_THREAD if request_stop has been called.
    def check_stop
      @mutex.synchronize { throw :STOP_THREAD if @stop_requested }
    end

    protected

    def thread_main
      raise "thread_main not implemented"
    end

  end
end
