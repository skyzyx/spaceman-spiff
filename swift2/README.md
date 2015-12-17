Swift 2.0 feels comfortable if you come from a Ruby, JavaScript, C#, Scala 
or **Modern** PHP (and/or Hack) background because it borrows concepts from 
across the board.

## Installation (Swift version)

Written in **Swift 2.1**, which requires **Xcode 7.2** or newer to compile.

(This version does not (yet) support `spaceman spf.txt` syntax. It only supports 
piping from `STDIN`.)


1. [Install Xcode 7.2](https://developer.apple.com/xcode/downloads/)

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
swift ./spaceman.swift
```
