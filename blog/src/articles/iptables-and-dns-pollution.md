&nbsp; &nbsp; &nbsp; &nbsp;ip桌子！由于众所周知的原因，向国外递归服务器发起的请求常常会得到**损坏**的数据包，故而dnscrypt，DoH等技术常被使用以应对这一现状。但cdn们却会带些脏东西（geodns是什么垃圾....)，故而得到的解析结果往往会造成不理想的访问速度。虽然edns0 client subnet或许会改变这一状况，但该标准仍不普及，因此dns分流实为必要。传统的dns分流手段往往是依靠域名列表，虽然效果绝佳，但列表的维护与匹配时带来的overhead却是不可忽略。

&nbsp; &nbsp; &nbsp; &nbsp;既然要不依赖列表，实时监测便是我给出的答案，udp劫持、tcp阻断、连接超时，依靠这三大主要指征我构建了[Project Calorina](https://gitlab.com/NickCao/calorina)，并得到了较为不错的结果....然后....干！内存漏了.... 排查了许久，发现问题似乎出在第三方库内，who cares？ 恰好在推特上看到了某位不愿透露姓名的大佬的推文：两个损坏的数据包之一的IP Identification为0，而另一则设置了Don't fragment，而Google public dns则不会有这两个特征，可以用iptables过滤..... 这一结论很有理论价值，但现实价值却不高，毕竟有DoH存在，此等极度依赖网路环境的方案不会被作为首选。但这两个特征，又让我想到了**损坏**的数据包的另一个特征：在answser section中只有一个RR。这一特征则可用于对国内的递归服务器的查询，避免上游投毒造成的影响（虽然会有误杀，但实为少数）
```
sudo iptables -I INPUT -s 8.8.8.8 -p udp --sport 53 -m u32 --u32 "2&0xFFFF=0x0" -j DROP
sudo iptables -I INPUT -s 8.8.8.8 -p udp --sport 53 -m u32 --u32 "4&0xFFFF=0x4000" -j DROP
sudo iptables -I INPUT -s 223.5.5.5 -p udp --sport 53 -m u32 --u32 "32&0xFFFF=0x0001" -j DROP
```
&nbsp; &nbsp; &nbsp; &nbsp;这便是我最终得出的解答。但经过短暂测试，便发现了这一规则的漏洞：CNAME。对于域名其他记录的查询会导致响应中CNAME字段的出现，使得RR数不为一，而与之相伴的**损坏**的A/AAAA记录也会进而污染本地缓存。对此的应对措施我则采用了unbound，这也依赖于unbound的一个安全特性：

> CNAMEs are chased by unbound itself, asking the remote server for every name in the indirection chain, to  protect  the local  cache  from  illegal  indirect referenced items.

配置文件如下
```
server:
	interface: 127.0.0.1
	interface: ::1
	port: 53
	do-daemonize: no
	prefetch: yes

forward-zone:
	name: "."
	forward-addr: 223.5.5.5
	forward-addr: 8.8.8.8
```
&nbsp; &nbsp; &nbsp; &nbsp;三行iptables规则，三行forward zone配置，于我而言确是一个比近千行的code base更优美的方案。ONE TABLE TO RULE THEM ALL