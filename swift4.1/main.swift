#! /usr/bin/env swift

import Foundation

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
}

// Read from STDIN or file; similar to Ruby's argf()
func argf() -> String {
    var keyboard: FileHandle;
    
    if CommandLine.arguments.count == 1 {
        keyboard = FileHandle.standardInput
    } else {
        keyboard = FileHandle(forReadingAtPath: CommandLine.arguments[1])!
    }
    
    let inputData = keyboard
        .readDataToEndOfFile()
    
    return String(decoding: inputData, as: UTF8.self)
}

var input = argf().delete(char: "\"").trim()

// Where do we start?
print("SPF-formatted input record")
print(input)
