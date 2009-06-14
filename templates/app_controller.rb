class ApplicationController < ::MaglevDNS::BaseController
  def handle_query
    #if recursion_desired? and match_ip? ["10.159.0.0/16", "127.0.0.1", "::1"] and match_zone? "example.com"
    #  forward_to :host => "10.0.0.2"
    #end
    #forward_to "10.0.0.1", :port => 40053
  end
end
