#! /usr/bin/env swift

import Foundation

// Extend the String object with helpers
extension String {

    // String.trim()
    func trim() -> String {
        let whitespace = NSCharacterSet.whitespaceCharacterSet()
        return self.stringByTrimmingCharactersInSet(whitespace)
    }

    // String.delete()
    func delete(char: String) -> String {
        return self.componentsSeparatedByString(char).joinWithSeparator("")
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

    // String.substring(); similar to JavaScript's String.subString()
    func substring(start: Int, end: Int) -> String {
        let range = Range(start: self.startIndex.advancedBy(start), end: self.startIndex.advancedBy(end))
        return self.substringWithRange(range)
    }

    // String.lastIndexOf(); similar to JavaScript's String.lastIndexOf() and Ruby's String.rindex()
    func lastIndexOf(target: String) -> Int? {
        if let range = self.rangeOfString(target, options: .BackwardsSearch) {
            return startIndex.distanceTo(range.startIndex)
        }
        return nil
    }

    // String.len(); similar to JavaScript's String.length property
    func len() -> Int {
        return self.characters.count
    }

    // String.split(); similar to JavaScript's String.split() or PHP's explode()
    func split(separator: String) -> Array<String> {
        return self.componentsSeparatedByString(separator)
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

// Read from STDIN or file; similar to Ruby's argF
func argf() -> String {
    var keyboard: NSFileHandle;

    if Process.arguments.count == 1 {
        keyboard = NSFileHandle.fileHandleWithStandardInput()
    } else {
        keyboard = NSFileHandle(forReadingAtPath: Process.arguments[1])!
    }

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

// Initialize
var input = argf().delete("\"").trim()
var idx = 0
var ips: [String] = []
var dns: [String] = []
var baseLength = 220 // Max length of a string before we start prepending/appending

// Where do we start?
print("SPF-formatted input record")
print(input)

scanSpf(input, ips: &ips)
ips.sortInPlace {
    $0.compare($1, options: NSStringCompareOptions.LiteralSearch) == NSComparisonResult.OrderedAscending
}

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
let swc = "include:spf0.wepay.com -all"

// Flatten array into a space-delimited string
var ipString = prefix + ips.joinWithSeparator(" ")

// Marker for the end of the string, within the confines of our boundaries
var s = ipString.substring(0, end: baseLength).lastIndexOf(" ")

// Produce the first record
dns.append([
    ipString.substring(0, end: s!),
    swc.replace("spf0.", replacement: "spf\(idx + 1).")
].joinWithSeparator(" "))

// Trim to only what's left to process
ipString = ipString.substring(s!, end: ipString.len()).trim()

// Break the list into chunks
while ipString.len() > 0 {

    // Increment
    idx = idx + 1

    if ipString.len() >= baseLength {
        s = ipString.substring(0, end: baseLength).lastIndexOf(" ")
        dns.append([
            spf,
            ipString.substring(0, end: s!),
            swc
                .replace("spf0.", replacement: "spf\(idx + 1).")
                .replace("\\s+", replacement: " ")
        ].joinWithSeparator(" "))
        ipString = ipString.substring(s!, end: ipString.len()).trim()
    } else {
        dns.append([
            spf,
            ipString,
            "-all"
        ].joinWithSeparator(" "))
        ipString = ""
    }
}

// Display the list
idx = 0
for value in dns {
    if idx == 0 {
        print("# TXT wepay.com (\(value.len()) chars)")
    } else {
        print("# TXT spf\(idx).wepay.com (\(value.len()) chars)")
    }

    print(value)
    print("")
    idx = idx + 1
}
