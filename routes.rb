return "udp4://10.159.17.100:53" if recursion_desired? and match_ip? ["10.159.0.0/16", "127.0.0.1", "::1"] and match_zone? "dlitz.net"
