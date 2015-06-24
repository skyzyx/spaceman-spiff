The Ruby source code is shorter, but the compiled Go binary runs measurably 
faster. Go appears to be the lovechild of Python and C. If that's something 
you're into, you're gonna love Go.

## Installation (Go version)

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
