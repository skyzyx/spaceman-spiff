#! /usr/bin/env swift

import Foundation
import SwiftShell

// Extend the String object with helpers
extension String {

    func trim() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // String.delete()
    func delete(char: String) -> String {
        return self
            .components(separatedBy: char)
            .joined(separator: "")
    }

    // String.scan(); similar to Ruby's String.scan()
    func scan(regex: String) throws -> [String] {
        let regex = try! NSRegularExpression(
            pattern: regex,
            options: [.caseInsensitive]
        )
        
        let nsString = self as NSString
        
        let results = regex.matches(
            in: nsString as String,
            options: [.reportCompletion],
            range: NSMakeRange(0, nsString.length)
            ) as [NSTextCheckingResult]
        
        return results.map {
            nsString.substring(with: $0.range)
        }
    }
}

// Recursively collect all of the IP addresses
func scanSpf(input: String, ips: inout [String]) {
    ips += try! input.scan(regex: "(ip4:([^\\s]*))")
    ips += try! input.scan(regex: "(ip6:([^\\s]*))")
    
    let includes = try? input.scan(regex: "include:([^\\s]*)").map {
        $0.delete(char: "include:")
    }

    print(includes!.joined(separator: " | "))
    
//    for incl in includes! {
//        let inclu = incl.delete(char: "\"")
//        let record = shell("dig TXT \(inclu) +short")
//
//        print("-------------------")
//        print("dig TXT \(inclu) +short")
//        print(record.output)
//
//        scanSpf(record.output, ips: &ips)
//    }
}

// https://kareman.github.io/FileSmith/Classes/ReadableFile.html#/s:FC9FileSmith12ReadableFile4readFT_SS
var inputStream = try main.arguments.first.map {try open($0)} ?? main.stdin

// Initialize
var input = inputStream.read().delete(char: "\"").trim()
var idx = 0
var ips: [String] = []
var dns: [String] = []
var baseLength = 220 // Max length of a string before we start prepending/appending

// Where do we start?
print("SPF-formatted input record")
print(input)

scanSpf(input: input, ips: &ips)
ips.sort()
