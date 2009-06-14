class ApplicationController < BaseController
  def handle_query
    forward_to "10.159.17.205"
    #if recursion_desired? and match_ip? ["10.159.0.0/16", "127.0.0.1", "::1"] and match_zone? "dlitz.net"
    #  forward_to :host => "10.159.17.100"
    #end
  end
end
