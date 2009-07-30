## opennic-example.rb for MaglevDNS
## This configuration file is placed into the public domain.
##
## Forwards queries to a randomly-chosen public OpenNIC server if the query is
## for one of the OpenNIC zones (.oss, .geek, .ing, .free, .bbs, .gopher).
## Forwards everything else to your ISP's nameserver.
##
## Note that you will need to enter the IP address of your ISP's nameserver
## below.

# Fill in the IP address of your ISP's nameserver here.
default_resolver = "1.2.3.4"

# List of OpenNIC TLDs and public DNS servers
# See http://www.opennicproject.org/ for an updated list, but be sure to test
# them first, since some servers listed there do not work or resolve
# incorrectly!
opennic_zones = %w{ bbs dyn free fur geek opennic.glue indy ing null oss parody eco }
opennic_servers = %w{ 58.6.115.42 58.6.115.43 119.31.230.42 200.252.98.162
                      217.79.186.148 82.229.244.191 66.244.95.20 }
# Uncomment if you have IPv6 connectivity
#opennic_servers += %w{ 2001:470:1f07:38b::1 2001:470:1f10:c6::2 }

# Forward to randomly-chosen public OpenNIC server if the query is for an
# OpenNIC zone.
forward_to opennic_servers.choice if match_zone?(opennic_zones)

# Otherwise...
forward_to default_resolver
