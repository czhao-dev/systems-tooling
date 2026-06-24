module example.com/foo

go 1.21

require (
	github.com/gorilla/mux v1.8.0
	golang.org/x/text v0.3.0 // indirect
)

require golang.org/x/sys v0.1.0

replace example.com/foo/bar => ../bar
