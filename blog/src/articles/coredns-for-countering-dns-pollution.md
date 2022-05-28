&nbsp; &nbsp; &nbsp; &nbsp;DNS污染一直是个大问题，而[ChinaDNS](https://github.com/shadowsocks/ChinaDNS) ，[neatdns](https://github.com/ustclug/neatdns) 与[Pcap_DNSProxy](https://github.com/chengr28/Pcap_DNSProxy) 都是优秀的解决方案。但前两者需要列表支撑，后者也只是依靠不可靠的时间差。DNS over HTTPS或者over TLS虽然能解决问题，但通常会丢失CDN优化，导致用户体验变差。通过一段时间的研究与尝试，最终发现DNS over TCP在查询被污染域名时会被RST的特征（或者叫一种行为？），由此自动筛选被污染域名，转用DNS over TLS查询。这一操作可以简便地由Coredns自动化，最终得出了如下Corefile：
```
.:53 {
    forward . dns://8.8.8.8 dns://8.8.4.4 {
        force_tcp
	expire 20s
	max_fails 1
	policy sequential
	health_check 1s
    }
    fallback SERVFAIL . 127.0.0.1:1053 {
        fail_timeout 2s
        max_fails 1
        protocol dns
    }  
    log
    cache
}

.:1053 {
    forward . tls://1.1.1.1 tls://1.0.0.1 {
        expire 20s
        max_fails 1
        tls
        tls_servername cloudflare-dns.com
        policy sequential
	health_check 1s
    }
}
```
