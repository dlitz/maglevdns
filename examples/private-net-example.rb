## private-net-example.rb for MaglevDNS
## This configuration file is placed into the public domain.
##
## Forwards queries for local domains (forward and reverse) to a local server.
## Forwards everything else to your ISP's nameserver.
##

# Fill in the IP address of your ISP's nameserver here.
default_resolver = "1.2.3.4"

# Avoid leaking private names outside the local network.
forward_to default_resolver unless match_ip? "192.168.63.0/24"

# Forward internal queries to a private DNS server
if match_zone? ["example.com", "63.168.192.in-addr.arpa"]
  forward_to "192.168.63.63"
end

# Otherwise...
forward_to default_resolver
