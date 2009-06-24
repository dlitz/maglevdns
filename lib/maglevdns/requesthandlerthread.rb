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
require 'maglevdns/stoppablethread'

module MaglevDNS
  class RequestHandlerThread < StoppableThread

    def initialize(request, request_handler)
      @request = request
      @request_handler = request_handler
      super()
    end

    private
    def thread_main
      begin
        @request_handler.handle_request(@request)
      rescue BaseController::ReturnResponse => e
        unless e.response.nil?
          @request.respond(e.response.to_s)
        end
      end
    end

  end
end
