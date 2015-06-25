#! /usr/bin/env swift

import Foundation

// Extend the String object with helpers
extension String {

    // String.trim()
    func trim() -> String {
        return self.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
    }

    // String.delete()
    func delete(char: String) -> String {
        return "".join(self.componentsSeparatedByString(char))
    }

    // String.replace(); similar to JavaScript's String.replace() and Ruby's String.gsub()
    func replace(pattern: String, replacement: String) -> String {
        let regex = try! NSRegularExpression(
            pattern: pattern,
            options: [.CaseInsensitive]
        )

        return regex.stringByReplacingMatchesInString(
            self,
            options: [.WithTransparentBounds],
            range: NSMakeRange(0, self.characters.count),
            withTemplate: replacement
        )
    }

    // String.scan(); similar to Ruby's String.scan()
    func scan(regex: String) throws -> [String] {
        let regex = try! NSRegularExpression(
            pattern: regex,
            options: [.CaseInsensitive]
        )

        let nsString = self as NSString

        let results = regex.matchesInString(
            nsString as String,
            options: [.ReportCompletion],
            range: NSMakeRange(0, nsString.length)
        ) as [NSTextCheckingResult]

        return results.map {
            nsString.substringWithRange($0.range)
        }
    }
}

// Run shell scripts
func shell(input: String) -> (output: String, exitCode: Int32) {
    let arguments = input.componentsSeparatedByString(" ")

    let task = NSTask()
    task.launchPath = "/usr/bin/env"
    task.arguments = arguments
    task.environment = [
        "LC_ALL" : "en_US.UTF-8",
        "HOME" : NSHomeDirectory()
    ]

    let pipe = NSPipe()
    task.standardOutput = pipe
    task.launch()
    task.waitUntilExit()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output: String = NSString(data: data, encoding: NSUTF8StringEncoding) as! String

    return (output, task.terminationStatus)
}

// Read from STDIN
func readStdIn() -> String {
    let keyboard = NSFileHandle.fileHandleWithStandardInput()
    let inputData = keyboard.availableData
    return NSString(data: inputData, encoding:NSUTF8StringEncoding) as! String
}

// Recursively collect all of the IP addresses?
func scanSpf(input: String, inout ips: [String]) {
    ips += try! input.scan("(ip4:([^\\s]*))")
    ips += try! input.scan("(ip6:([^\\s]*))")

    let includes = try! input.scan("include:([^\\s]*)").map {
        $0.delete("include:")
    }

    for incl in includes {
        let inclu = incl.delete("\"")
        let record = shell("dig TXT \(inclu) +short")

        print("-------------------")
        print("dig TXT \(inclu) +short")
        print(record.output)

        scanSpf(record.output, ips: &ips)
    }
}

var input = readStdIn().delete("\"").trim()
var ips: [String] = []
var dns: [String] = []
var baseLength = 220 // Max length of a string before we start prepending/appending

// Where do we start?
print("SPF-formatted input record")
print(input)

scanSpf(input, ips: &ips)
ips.sortInPlace {
    $0.compare($1, options: NSStringCompareOptions.NumericSearch) == NSComparisonResult.OrderedAscending
}

print(ips)

// Take the original input and strip away what we've already resolved
let prefix = input
    .replace("include:([^\\s]*)", replacement: "")
    .replace("ip(4|6):([^\\s]*)", replacement: "")
    .replace("(~|-)all", replacement: "")
    .replace("\\s+", replacement: " ")

print("")
print("***********************")
print("DNS RECORDS TO CREATE:")
print("***********************")
print("")

// Things to apply to every record
let spf = "v=spf1"
let swc = "include:spf0.wepay.com ~all"

// # # We need to start cutting-up the string
// # $ips = prefix + $ips.join(' ')
// # idx = 0
// # s = $ips[0..$base_length].rindex(' ')
// # $dns[idx] = $ips[0..s] + swc.gsub(/spf0./, "spf#{idx + 1}.")
// # $ips = $ips.slice(s, $ips.length).strip

// # # Break the list into chunks
// # while $ips.length > 0 do
// #   idx = idx + 1

// #   if $ips.length >= $base_length
// #     s = $ips[0..$base_length].rindex(' ')
// #     $dns[idx] = sprintf("%s %s %s", spf, $ips[0..s], swc.gsub(/spf0\./, "spf#{idx + 1}.")).gsub(/\s+/, ' ')
// #     $ips = $ips.slice(s, $ips.length).to_s.strip
// #   else
// #     $dns[idx] = sprintf("%s %s ~all", spf, $ips[0..s])
// #     $ips = $ips.slice(s, $ips.length).to_s.strip
// #   end
// # end

// # # Display the list
// # idx = 0
// # $dns.each do | value |
// #   if idx == 0
// #     puts "# TXT wepay.com (#{value.length} chars)"
// #   else
// #     puts "# TXT spf#{idx}.wepay.com (#{value.length} chars)"
// #   end

// #   puts value
// #   puts ""
// #   idx = idx + 1
// # end
