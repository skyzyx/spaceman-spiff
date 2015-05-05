# Spaceman Spiff

Takes an SPF-specific DNS record and recursively resolves all `include:` markers
down to a flat list of IPs. This can be used to manually update the list of IPs,
or when we need to add an additional SPF record and want to keep the DNS lookup
count low.

## Installation

Dependencies are installed using [Bundler].

```bash
bundle install
```

## Examples
### Pipe a raw SPF record into `spaceman`

```bash
echo "v=spf1 a mx ptr mx:aspmx.l.google.com include:_spf.google.com include:sendgrid.net include:mail.zendesk.com ~all" | spaceman
```

### Read a file containing the SPF record
```bash
spaceman spf.txt
```

### Output for `wepay.com`
```
SPF-formatted input record
v=spf1 a mx ptr mx:aspmx.l.google.com include:_spf.google.com include:sendgrid.net include:mail.zendesk.com ~all
-------------------
dig TXT _spf.google.com +short
"v=spf1 include:_netblocks.google.com include:_netblocks2.google.com include:_netblocks3.google.com ~all"
-------------------
dig TXT _netblocks.google.com +short
"v=spf1 ip4:64.18.0.0/20 ip4:64.233.160.0/19 ip4:66.102.0.0/20 ip4:66.249.80.0/20 ip4:72.14.192.0/18 ip4:74.125.0.0/16 ip4:173.194.0.0/16 ip4:207.126.144.0/20 ip4:209.85.128.0/17 ip4:216.58.192.0/19 ip4:216.239.32.0/19 ~all"
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
"v=spf1 ip4:192.161.144.0/20 ip4:185.12.80.0/22 ip4:96.46.150.192/27 ip4:198.61.149.152/29 ip4:173.203.47.128/27 ip4:184.106.12.184/29 ip4:174.137.46.0/24 ip4:173.203.47.160/27 ip4:184.106.40.64/28 ip4:50.57.199.0/27 include:_spf1.mail.zendesk.com"
-------------------
dig TXT _spf1.mail.zendesk.com +short
"v=spf1 ip4:50.57.4.208/29 ~all"

***********************
DNS RECORDS TO CREATE:
***********************

# TXT wepay.com (228 chars)
v=spf1 a mx ptr mx:aspmx.l.google.com ip4:167.89.0.0/17 ip4:173.193.132.0/23 ip4:173.194.0.0/16 ip4:173.203.47.128/27 ip4:173.203.47.160/27 ip4:174.137.46.0/24 ip4:174.36.80.208/28 ip4:174.36.92.96/27 include:spf1.wepay.com ~all

# TXT spf1.wepay.com (240 chars)
v=spf1 ip4:184.106.12.184/29 ip4:184.106.40.64/28 ip4:185.12.80.0/22 ip4:192.161.144.0/20 ip4:192.254.112.0/20 ip4:198.21.0.0/21 ip4:198.37.144.0/20 ip4:198.61.149.152/29 ip4:207.126.144.0/20 ip4:208.115.214.0/24 include:spf2.wepay.com ~all

# TXT spf2.wepay.com (249 chars)
v=spf1 ip4:208.115.235.0/24 ip4:208.115.239.0/24 ip4:208.117.48.0/20 ip4:209.85.128.0/17 ip4:216.239.32.0/19 ip4:216.58.192.0/19 ip4:50.31.32.0/19 ip4:50.57.199.0/27 ip4:50.57.4.208/29 ip4:64.18.0.0/20 ip4:64.233.160.0/19 include:spf3.wepay.com ~all

# TXT spf3.wepay.com (242 chars)
v=spf1 ip4:66.102.0.0/20 ip4:66.249.80.0/20 ip4:67.228.50.32/27 ip4:69.162.98.0/24 ip4:72.14.192.0/18 ip4:74.125.0.0/16 ip4:74.63.194.0/24 ip4:74.63.202.0/24 ip4:74.63.231.0/24 ip4:74.63.234.0/24 ip4:74.63.235.0/24 include:spf4.wepay.com ~all

# TXT spf4.wepay.com (254 chars)
v=spf1 ip4:74.63.236.0/24 ip4:74.63.247.0/24 ip4:75.126.200.128/27 ip4:75.126.253.0/24 ip4:96.46.150.192/27 ip6:2001:4860:4000::/36 ip6:2404:6800:4000::/36 ip6:2607:f8b0:4000::/36 ip6:2800:3f0:4000::/36 ip6:2a00:1450:4000::/36 include:spf5.wepay.com ~all

# TXT spf5.wepay.com (35 chars)
v=spf1 ip6:2c0f:fb50:4000::/36 ~all
```

  [Bundler]: http://bundler.io
