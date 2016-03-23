Swift feels comfortable if you come from a Ruby, JavaScript, C#, Scala 
or **Modern** PHP (and/or Hack) background because it borrows concepts from 
across the board.

## Installation (Swift version)

Written in **Swift 2.2**, which requires **Xcode 7.3** or newer to compile.

1. [Install Xcode 7.3](https://developer.apple.com/xcode/downloads/)

2. Set your default Xcode compiler, accept the license agreement, and install 
   the CLI tools.

   ```bash
   sudo xcode-select -s /Applications/Xcode.app/
   sudo xcode-select --install
   sudo xcodebuild -license
   ```

3. Compile the Swift source code into a binary.

   ```bash
   swiftc -sdk `xcrun --show-sdk-path` spaceman.swift
   #=> spaceman
   ```

If you are making changes to the app, you can run the app in interpreter mode 
instead.

```bash
swift swift2/spaceman.swift spf.txt
```
