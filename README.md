# [Spaceman Spiff](https://www.google.com/search?q=Spaceman%20Spiff)

Once upon a time, when I used to work for [WePay](https://wepay.com), we faced an issue: We were trying to send emails via so many third-party services (Google Apps, Sendmail, Amazon SES, Marketo, various other tools), that we exceeded the [SPF-mandated DNS lookup limit](https://sendgrid.com/docs/Classroom/Deliver/Sender_Authentication/spf_dont_exceed_ten_dns_lookups.html) by several, causing many of our emails to be flagged as spam.

So I wrote this (fairly naïve) tool to recursively resolve all `include:` markers down to a flat list of IPs. This can be used to manually update the list of IPs, or when we need to add an additional SPF record and want to keep the DNS lookup count low.

* It doesn't resolve smaller CIDRs into larger/overlapping ones, but it should someday.
* There are better ways of bundling multiple records into a single DNS lookup that I never got around to implementing.

After working on this, I realized that this particular problem touched on many of the core fundamentals of programming (e.g., string parsing, arrays, sets, queue vs. recursion, performance vs. scalability, regular expressions). So I began using this as a starting point for learning new languages. As such, this application has multiple ports. None are particularly good, but it has allowed me to become a better polyglot.

> **NOTE:** This software was written on my own time and with my own equipment. It is the property of myself, and not WePay. This product is not affiliated with WePay, but I used the SPF records from wepay.com as a starting point.

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
