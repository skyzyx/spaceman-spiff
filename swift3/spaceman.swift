#! /usr/bin/env swift

import Foundation

// Extend the String object with helpers
extension String {

    // String.trim()
    func trim() -> String
    {
        return self.trimmingCharacters(in: CharacterSet.whitespaces)
    }

    // String.delete()
    func delete(char: String) -> String
    {
        return self.components(separatedBy: char).joined(separator: "")
    }

    // String.replace(); similar to JavaScript's String.replace() and Ruby's String.gsub()
    func replace(pattern: String, replacement: String) -> String
    {
        let regex = try! RegularExpression(
            pattern: pattern,
            options: [.caseInsensitive]
        )

        return regex.stringByReplacingMatches(
            in: self,
            options: [.withTransparentBounds],
            range: NSMakeRange(0, self.characters.count),
            withTemplate: replacement
        )
    }

    // String.scan(); similar to Ruby's String.scan()
    func scan(pattern: String) throws -> [String]
    {
        let regex = try! RegularExpression(
            pattern: pattern,
            options: [.caseInsensitive]
        )

        let nsString = self as NSString

        let results = regex.matches(
            in: nsString as String,
            options: [.reportCompletion],
            range: NSMakeRange(0, nsString.length)
        ) as [TextCheckingResult]

        return results.map {
            nsString.substring(with: $0.range)
        }
    }

    // String.substring(); similar to JavaScript's String.subString()
    func substring(from: Int, to: Int) -> String
    {
        let range = Range(from..<to)

        return self.substring(with: range)
    }

    func indexOf(target: String) -> Int?
    {
        let range = self.range(of: target)

        if let range = range {
            return distance(from: self.startIndex, to: range.lowerBound)
        }

        return nil
    }

    func indexOf(target: String, startIndex: Int) -> Int?
    {
        var startRange = advance(self.startIndex, startIndex)
        var range = self.range(
            of: target,
            options: NSString.CompareOptions.LiteralSearch,
            range: Range<String.Index>(
                start: startRange,
                end: self.endIndex
            )
        )

        if let range = range {
            return distance(self.startIndex, range.startIndex)
        }

        return nil
    }

    // String.lastIndexOf(); similar to JavaScript's String.lastIndexOf() and Ruby's String.rindex()
    func lastIndexOf(target: String) -> Int?
    {
        var index = -1
        var stepIndex = self.indexOf(target: target)

        while stepIndex > -1 {
            index = stepIndex!

            if stepIndex! + target.len() < self.len() {
                stepIndex = indexOf(target: target, startIndex: stepIndex! + target.len())
            }

            stepIndex = nil
        }

        return index
    }

    // String.len(); similar to JavaScript's String.length property
    func len() -> Int
    {
        return self.characters.count
    }

    // String.split(); similar to JavaScript's String.split() or PHP's explode()
    func split(separator: String) -> [String]
    {
        return self.components(separatedBy: separator)
    }
}

// Run shell scripts
func shell(input: String) -> (output: String, exitCode: Int32)
{
    let arguments = input.components(separatedBy: " ")

    let task = Task()
    task.launchPath = "/usr/bin/env"
    task.arguments = arguments
    task.environment = [
        "LC_ALL" : "en_US.UTF-8",
        "HOME" : NSHomeDirectory()
    ]

    let pipe = Pipe()
    task.standardOutput = pipe
    task.launch()
    task.waitUntilExit()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output: String = NSString(data: data, encoding: String.Encoding.utf8.rawValue) as! String

    return (output, task.terminationStatus)
}

// Read from STDIN or file; similar to Ruby's argF
func argf() -> String
{
    var keyboard: FileHandle;

    if Process.arguments.count == 1 {
        keyboard = FileHandle.withStandardInput
    } else {
        keyboard = FileHandle(forReadingAtPath: Process.arguments[1])!
    }

    let inputData = keyboard.availableData
    return NSString(data: inputData, encoding: String.Encoding.utf8.rawValue) as! String
}

// Recursively collect all of the IP addresses?
func scanSpf(input: String, ips: inout [String])
{
    ips += try! input.scan(pattern: "(ip4:([^\\s]*))")
    ips += try! input.scan(pattern: "(ip6:([^\\s]*))")

    let includes = try! input.scan(pattern: "include:([^\\s]*)").map {
        $0.delete(char: "include:")
    }

    for incl in includes {
        let inclu = incl.delete(char: "\"")
        let record = shell(input: "dig TXT \(inclu) +short")

        print("-------------------")
        print("dig TXT \(inclu) +short")
        print(record.output)

        scanSpf(input: record.output, ips: &ips)
    }
}

// Initialize
var input = argf().delete(char: "\"").trim()
var idx = 0
var ips: [String] = []
var dns: [String] = []
var baseLength = 220 // Max length of a string before we start prepending/appending

// Where do we start?
print("SPF-formatted input record")
print(input)

scanSpf(input: input, ips: &ips)
ips.sortInPlace {
    $0.compare($1, options: NSString.CompareOptions.LiteralSearch) == ComparisonResult.OrderedAscending
}

// Take the original input and strip away what we've already resolved
let prefix = input
    .replace(pattern: "include:([^\\s]*)", replacement: "")
    .replace(pattern: "ip(4|6):([^\\s]*)", replacement: "")
    .replace(pattern: "(~|-)all", replacement: "")
    .replace(pattern: "\\s+", replacement: " ")

print("")
print("***********************")
print("DNS RECORDS TO CREATE:")
print("***********************")
print("")

// Things to apply to every record
let spf = "v=spf1"
let swc = "include:spf0.wepay.com -all"

// Flatten array into a space-delimited string
var ipString = prefix + ips.joined(separator: " ")

// Marker for the end of the string, within the confines of our boundaries
var s = ipString.substring(from: 0, to: baseLength).lastIndexOf(target: " ")

// Produce the first record
dns.append([
    ipString.substring(from: 0, to: s!),
    swc.replace(pattern: "spf0.", replacement: "spf\(idx + 1).")
].joined(separator: " "))

// Trim to only what's left to process
ipString = ipString.substring(from: s!, to: ipString.len()).trim()

// Break the list into chunks
while ipString.len() > 0 {

    // Increment
    idx = idx + 1

    if ipString.len() >= baseLength {
        s = ipString.substring(from: 0, to: baseLength).lastIndexOf(target: " ")
        dns.append([
            spf,
            ipString.substring(from: 0, to: s!),
            swc
                .replace(pattern: "spf0.", replacement: "spf\(idx + 1).")
                .replace(pattern: "\\s+", replacement: " ")
        ].joined(separator: " "))
        ipString = ipString.substring(from: s!, to: ipString.len()).trim()
    } else {
        dns.append([
            spf,
            ipString,
            "-all"
        ].joined(separator: " "))
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
