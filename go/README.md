## Installation (Go version)

> **NOTE:** This version has a few small bugs. Use the Ruby version instead.

1. [Install Go](https://golang.org)

2. Install dependencies.

   ```bash
   go get github.com/yuya-takeyama/argf
   ```

3. Compile the Go source code into a binary.

   ```bash
   go build ./spaceman.go
   #=> spaceman
   ```

If you are making changes to the app, you can run the app in interpreter mode instead.

```bash
go run ./spaceman.go
```
