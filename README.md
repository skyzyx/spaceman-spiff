# [Spaceman Spiff](https://www.google.com/search?q=Spaceman%20Spiff)

Takes an SPF-specific DNS record and recursively resolves all `include:` markers
down to a flat list of IPs. This can be used to manually update the list of IPs,
or when we need to add an additional SPF record and want to keep the DNS lookup
count low.

This app has two ports: Ruby and Go. The Ruby version was written first, and was
later ported to Go. They should be identical, making it a good opportunity to
learn Go if you already know some Ruby.

The Ruby source code is shorter, but the compiled Go binary runs measurably
faster. Go appears to be the lovechild of Python and C. If that's something
you're into, you're gonna love Go.

## Examples
### Pipe a raw SPF record into `spaceman`

```bash
dig TXT wepay.com +short | spaceman
```

### Read a file containing the SPF record

```bash
spaceman spf.txt
```

### Output for `wepay.com`
```
SPF-formatted input record
v=spf1 a mx include:_spf.google.com include:sendgrid.net include:mail.zendesk.com include:mktomail.com -all
-------------------
dig TXT _spf.google.com +short
"v=spf1 include:_netblocks.google.com include:_netblocks2.google.com include:_netblocks3.google.com ~all"
-------------------
dig TXT _netblocks.google.com +short
"v=spf1 ip4:64.18.0.0/20 ip4:64.233.160.0/19 ip4:66.102.0.0/20 ip4:66.249.80.0/20 ip4:72.14.192.0/18 ip4:74.125.0.0/16 ip4:108.177.8.0/21 ip4:173.194.0.0/16 ip4:207.126.144.0/20 ip4:209.85.128.0/17 ip4:216.58.192.0/19 ip4:216.239.32.0/19 ~all"
-------------------
dig TXT _netblocks2.google.com +short
"v=spf1 ip6:2001:4860:4000::/36 ip6:2404:6800:4000::/36 ip6:2607:f8b0:4000::/36 ip6:2800:3f0:4000::/36 ip6:2a00:1450:4000::/36 ip6:2c0f:fb50:4000::/36 ~all"
-------------------
dig TXT _netblocks3.google.com +short
"v=spf1 ~all"
-------------------
dig TXT sendgrid.net +short
"v=spf1 ip4:208.115.214.0/24 ip4:74.63.202.0/24 ip4:75.126.200.128/27 ip4:75.126.253.0/24 ip4:67.228.50.32/27 ip4:174.36.80.208/28 ip4:174.36.92.96/27 ip4:69.162.98.0/24 ip4:74.63.194.0/24 ip4:74.63.234.0/24 ip4:74.63.235.0/24 include:sendgrid.biz ~all"
-------------------
dig TXT sendgrid.biz +short
"v=spf1 ip4:167.89.0.0/17 ip4:208.115.235.0/24 ip4:74.63.231.0/24 ip4:74.63.247.0/24 ip4:74.63.236.0/24 ip4:208.115.239.0/24 ip4:173.193.132.0/23 ip4:208.117.48.0/20 ip4:50.31.32.0/19 ip4:198.37.144.0/20 ip4:198.21.0.0/21 ip4:192.254.112.0/20 ~all"
-------------------
dig TXT mail.zendesk.com +short
"v=spf1 ip4:192.161.144.0/20 ip4:185.12.80.0/22 ip4:96.46.150.192/27 ip4:174.137.46.0/24 ip4:188.172.128.0/20 ip4:216.198.0.0/18 ~all"
-------------------
dig TXT mktomail.com +short
"MS=ms86038015"
"v=spf1 ip4:199.15.212.0/22 ip4:72.3.185.0/24 ip4:72.32.154.0/24 ip4:72.32.217.0/24 ip4:72.32.243.0/24 ip4:94.236.119.0/26 ip4:37.188.97.188/32 ip4:185.28.196.0/22 ip4:192.28.128.0/18 ip4:103.237.104.0/22 ip6:2a04:35c0::/29  ~all"
"google-site-verification=hlFqCorHDm61oaA9tEbxS2EoxvmpThp60Z3A8osUq5I"

***********************
DNS RECORDS TO CREATE:
***********************

# TXT wepay.com (237 chars)
v=spf1 a mx ip4:103.237.104.0/22 ip4:108.177.8.0/21 ip4:167.89.0.0/17 ip4:173.193.132.0/23 ip4:173.194.0.0/16 ip4:174.137.46.0/24 ip4:174.36.80.208/28 ip4:174.36.92.96/27 ip4:185.12.80.0/22 ip4:185.28.196.0/22 include:spf1.wepay.com -all

# TXT spf1.wepay.com (238 chars)
v=spf1 ip4:188.172.128.0/20 ip4:192.161.144.0/20 ip4:192.254.112.0/20 ip4:192.28.128.0/18 ip4:198.21.0.0/21 ip4:198.37.144.0/20 ip4:199.15.212.0/22 ip4:207.126.144.0/20 ip4:208.115.214.0/24 ip4:208.115.235.0/24 include:spf2.wepay.com -all

# TXT spf2.wepay.com (248 chars)
v=spf1 ip4:208.115.239.0/24 ip4:208.117.48.0/20 ip4:209.85.128.0/17 ip4:216.198.0.0/18 ip4:216.239.32.0/19 ip4:216.58.192.0/19 ip4:37.188.97.188/32 ip4:50.31.32.0/19 ip4:64.18.0.0/20 ip4:64.233.160.0/19 ip4:66.102.0.0/20 include:spf3.wepay.com -all

# TXT spf3.wepay.com (242 chars)
v=spf1 ip4:66.249.80.0/20 ip4:67.228.50.32/27 ip4:69.162.98.0/24 ip4:72.14.192.0/18 ip4:72.3.185.0/24 ip4:72.32.154.0/24 ip4:72.32.217.0/24 ip4:72.32.243.0/24 ip4:74.125.0.0/16 ip4:74.63.194.0/24 ip4:74.63.202.0/24 include:spf4.wepay.com -all

# TXT spf4.wepay.com (236 chars)
v=spf1 ip4:74.63.231.0/24 ip4:74.63.234.0/24 ip4:74.63.235.0/24 ip4:74.63.236.0/24 ip4:74.63.247.0/24 ip4:75.126.200.128/27 ip4:75.126.253.0/24 ip4:94.236.119.0/26 ip4:96.46.150.192/27 ip6:2001:4860:4000::/36 include:spf5.wepay.com -all

# TXT spf5.wepay.com (149 chars)
v=spf1 ip6:2404:6800:4000::/36 ip6:2607:f8b0:4000::/36 ip6:2800:3f0:4000::/36 ip6:2a00:1450:4000::/36 ip6:2a04:35c0::/29 ip6:2c0f:fb50:4000::/36 -all
```
