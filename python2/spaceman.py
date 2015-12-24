#! /usr/bin/env python2.7

import re
import subprocess
import sys

# Initial cleanup and setup
params = len(sys.argv)
if params == 1:
    inpt = sys.stdin.read()
else:
    inpt = open(sys.argv[1], 'r').read()
#endif

inpt = inpt.replace('"', '')
ips = []
dns = []
base_length = 220 # Max length of a string before we start prepending/appending

# Where do we start?
print("SPF-formatted input record")
print(inpt)

# Recursively collect all of the IP addresses?
def scan_spf(inpt):
    re_ip4 = re.compile('(ip4:([^\s]*))')
    re_ip6 = re.compile('(ip6:([^\s]*))')
    re_include = re.compile('include:([^\s]*)')

    for match in re.finditer(re_ip4, inpt):
        ips.append(match.group(0))
    for match in re.finditer(re_ip6, inpt):
        ips.append(match.group(0))
    includes = re.findall(re_include, inpt)

    for incl in includes:
        record = subprocess.check_output("dig TXT {} +short".format(incl), shell=True)

        print('-------------------')
        print("dig TXT {} +short".format(incl))
        print(record)

        scan_spf(record)
# enddef

scan_spf(inpt)
ips.sort()

# Take the original input and strip away what we've already resolved
prefix = inpt
prefix = re.sub('include:([^\s]*)', '', prefix)
prefix = re.sub('ip(4|6):([^\s]*)', '', prefix)
prefix = re.sub('(~|-)all', '', prefix)
prefix = re.sub('\s+', ' ', prefix)

print('')
print('***********************')
print('DNS RECORDS TO CREATE:')
print('***********************')
print('')

# Things to apply to every record
spf = "v=spf1"
swc = "include:spf0.wepay.com -all"

# We need to start cutting-up the string
ips = prefix + ' '.join(ips)
idx = 0
s = ips[0:base_length].rindex(' ')
dns.append(" ".join([
    ips[0:s],
    re.sub('spf0.', "spf{}.".format(idx + 1), swc)
]))
ips = ips[s:].strip()

# Break the list into chunks
while len(ips) > 0:
    idx = idx + 1

    if len(ips) >= base_length:
        s = ips[0:base_length].rindex(' ')
        dns.append(
            re.sub('\s+', ' ', "{} {} {}".format(
                spf,
                ips[0:s],
                re.sub('spf0\.', "spf{}.".format(idx + 1), swc)
            ))
        )
        ips = ips[s:].strip()
    else:
        dns.append(
            "{} {} -all".format(
                spf,
                ips[0:s]
            )
        )
        ips = ips[s:].strip()
# endwhile

# Display the list
idx = 0
for value in dns:
    if idx == 0:
        print("# TXT wepay.com ({} chars)".format(len(value)))
    else:
        print("# TXT spf{}.wepay.com ({} chars)".format(idx, len(value)))

    print(value)
    print("")
    idx = idx + 1
# endfor
