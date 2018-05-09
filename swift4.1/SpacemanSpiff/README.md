Swift feels comfortable if you come from a Ruby, JavaScript, C#, Scala  or **Modern** PHP (and/or Hack) background because it borrows concepts from  across the board.

## Installation (Swift version)

Written in **Swift 4.1**, which requires **Xcode 9.3** or newer to compile.

1. [Install Xcode 9.3](https://developer.apple.com/xcode/downloads/)

1. Set your default Xcode compiler, accept the license agreement, and install the CLI tools.

   ```bash
   sudo xcode-select -s /Applications/Xcode.app/
   sudo xcode-select --install
   sudo xcodebuild -license
   ```

1. Move into the `SpacemanSpiff` directory.

   ```bash
   cd SpacemanSpiff
   ```

1. Install the dependencies.

   ```bash
   swift build
   ```

1. Compile the Swift source code into a binary.

   ```bash
   swiftc -sdk `xcrun --show-sdk-path` -o spaceman ./Sources/main.swift
   #=> spaceman

   ./spaceman ../../spf.txt
   ```

If you are making changes to the app, you can run the app in interpreter mode instead.

```bash
swift ./Sources/main.swift ../../spf.txt
```
