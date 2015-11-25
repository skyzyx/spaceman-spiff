package main

import (
	"fmt"
	"github.com/yuya-takeyama/argf"
	"io/ioutil"
	"math"
	"os/exec"
	"regexp"
	"sort"
	"strings"
)

var includes []string
var ips []string
var dns []string
var base_length uint16

func main() {
	// Initial cleanup and setup
	reader, _ := argf.Argf() // Same as Ruby's ARGF
	i, _ := ioutil.ReadAll(reader)
	input := regexp.MustCompile(`\"`).ReplaceAllString(strings.Trim(string(i), "\r\n"), "")
	base_length := 220 // Max length of a string before we start prepending/appending

	// Where do we start?
	fmt.Println("SPF-formatted input record")
	fmt.Println(string(input))

	scan_spf(string(input))
	sort.Strings(ips)

	// Take the original input and strip away what we've already resolved
	var prefix string
	prefix = regexp.MustCompile(`include:([^\s]*)`).ReplaceAllString(input, "")
	prefix = regexp.MustCompile(`ip(4|6):([^\s]*)`).ReplaceAllString(prefix, "")
	prefix = regexp.MustCompile(`-all`).ReplaceAllString(prefix, "")
	prefix = regexp.MustCompile(`\s+`).ReplaceAllString(prefix, " ")

	// fmt.Printf("\nPREFIX: [%s]\n", prefix)

	fmt.Println("")
	fmt.Println("***********************")
	fmt.Println("DNS RECORDS TO CREATE:")
	fmt.Println("***********************")
	fmt.Println("")

	// Things to apply to every record
	spf := "v=spf1"
	swc := "include:spf0.wepay.com -all"

	// We need to start cutting-up the string
	ip_string := fmt.Sprint(prefix, strings.Join(ips, " "))
	idx := 0
	s := strings.LastIndex(ip_string[0:base_length], " ")

	// Determine how to format the first chunk of IPs
	spf_index := fmt.Sprint("spf", (idx + 1), ".")
	spf_subdomain := regexp.MustCompile(`spf0.`).ReplaceAllString(swc, spf_index)
	dns_string := fmt.Sprint(ip_string[0:s], " ", spf_subdomain)
	dns = append(dns, dns_string)
	ip_string = strings.Trim(ip_string[s:], "\r\n ")

	// Break the list into chunks
	for len(ip_string) > 0 {
		idx = idx + 1
		lower_bound := int(math.Min(float64(len(ip_string)), float64(base_length)))
		s = strings.LastIndex(ip_string[0:lower_bound], " ")

		if len(ip_string) >= base_length {
			spf_index := fmt.Sprint("spf", (idx + 1), ".")
			spf_subdomain := regexp.MustCompile(`spf0.`).ReplaceAllString(swc, spf_index)
			dns_string := fmt.Sprintf("%s %s %s", spf, ip_string[0:base_length], spf_subdomain)
			dns_string = strings.Trim(regexp.MustCompile(`\s+`).ReplaceAllString(dns_string, " "), "\r\n ")
			dns = append(dns, dns_string)
			ip_string = strings.Trim(ip_string[s:], "\r\n ")
		} else {
			dns = append(dns, fmt.Sprintf("%s %s -all", spf, ip_string[0:]))
			ip_string = ""
		}
	}

	// Display the list
	idx = 0
	for _, value := range dns {
		if idx == 0 {
			fmt.Println(fmt.Sprintf("# TXT wepay.com (%d chars)", len(value)))
		} else {
			fmt.Println(fmt.Sprintf("# TXT spf%d.wepay.com (%d chars)", idx, len(value)))
		}

		fmt.Println(value)
		fmt.Println()
		idx = idx + 1
	}

	return
}

// Recursively collect all of the IP addresses?
func scan_spf(input string) {

	// Collect the IP addresses and stash them in a global variable
	ip_matches := regexp.MustCompile(`(ip(4|6):([^\s]*))`).FindAllString(input, -1)
	ips = append(ips, ip_matches...)

	// Collect the `include:` statements
	includes_matches := regexp.MustCompile(`include:([^\s]*)`).FindAllStringSubmatch(input, -1)

	// Iterate over the include statements
	for _, incl := range includes_matches {
		clean_incl := regexp.MustCompile(`\"`).ReplaceAllString(string(incl[1]), "")
		cmd := exec.Command(`dig`, `TXT`, clean_incl, `+short`)
		record, _ := cmd.Output()

		fmt.Println("-------------------")
		fmt.Printf("dig TXT %s +short\n", clean_incl)
		fmt.Printf("%#v\n", string(record))

		scan_spf(string(record))
	}
}
