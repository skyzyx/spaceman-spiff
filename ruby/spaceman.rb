#! /usr/bin/env ruby

# Initial cleanup and setup
input = ARGF.read
input.delete! '"'
$ips = []
$dns = []
$base_length = 220 # Max length of a string before we start prepending/appending

# Where do we start?
puts "SPF-formatted input record"
puts input

# Recursively collect all of the IP addresses?
def scan_spf(input)
  $ips.push(input.scan /(ip4:([^\s]*))/)
  $ips.push(input.scan /(ip6:([^\s]*))/)

  includes = input.scan /include:([^\s]*)/
  includes.each do | incl |
    incl = incl[0].delete '"'
    record = `dig TXT #{incl} +short`

    puts '-------------------'
    puts "dig TXT #{incl} +short"
    puts record

    scan_spf(record)
  end
end

scan_spf(input)
$ips = $ips.flatten.select{| ip | ip[/^ip/] }.sort!

# Take the original input and strip away what we've already resolved
prefix = input
  .gsub(/include:([^\s]*)/, '')
  .gsub(/ip(4|6):([^\s]*)/, '')
  .gsub(/-all/, '')
  .gsub(/\s+/, ' ')

puts ''
puts '***********************'
puts 'DNS RECORDS TO CREATE:'
puts '***********************'
puts ''

# Things to apply to every record
spf = "v=spf1"
swc = "include:spf0.wepay.com -all"

# We need to start cutting-up the string
$ips = prefix + $ips.join(' ')
idx = 0
s = $ips[0..$base_length].rindex(' ')
$dns[idx] = $ips[0..s] + swc.gsub(/spf0./, "spf#{idx + 1}.")
$ips = $ips.slice(s, $ips.length).strip

# Break the list into chunks
while $ips.length > 0 do
  idx = idx + 1

  if $ips.length >= $base_length
    s = $ips[0..$base_length].rindex(' ')
    $dns[idx] = sprintf("%s %s %s", spf, $ips[0..s], swc.gsub(/spf0\./, "spf#{idx + 1}.")).gsub(/\s+/, ' ')
    $ips = $ips.slice(s, $ips.length).to_s.strip
  else
    $dns[idx] = sprintf("%s %s -all", spf, $ips[0..s])
    $ips = $ips.slice(s, $ips.length).to_s.strip
  end
end

# Display the list
idx = 0
$dns.each do | value |
  if idx == 0
    puts "# TXT wepay.com (#{value.length} chars)"
  else
    puts "# TXT spf#{idx}.wepay.com (#{value.length} chars)"
  end

  puts value
  puts ""
  idx = idx + 1
end
