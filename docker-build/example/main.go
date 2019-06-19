package main

import (
	"flag"
	"fmt"
	"html/template"
	log "github.com/sirupsen/logrus"
	"net/http"
	"os"
	"runtime"
)

var (
	httpAddr   *string
	serverName *string
)

func init() {
	hostname, _ := os.Hostname()
	httpAddr = flag.String("http", ":8080", "Listen address")
	serverName = flag.String("server", hostname, "Server Name")
}

func main() {
	flag.Parse()
	http.HandleFunc("/", root)
	fmt.Print("Ready to receive requests on port 8080\n")
	log.Fatal(http.ListenAndServe(*httpAddr, nil))
}

func root(w http.ResponseWriter, r *http.Request) {
	path := "unknown"
	if (len(r.URL.Path) > 1) {
		path = r.URL.Path[1:]
	}
   
	data := struct {
		ServerName, Path, OS, Arch string
	}{
		*serverName, path, runtime.GOOS, runtime.GOARCH,
	}
	w.Header().Set("Server", "Hello Server")
	w.WriteHeader(200)
	err := tmpl.Execute(w, data)
	if (err != nil) {
		log.Print(err)
	}
}

var tmpl = template.Must(template.New("tmpl").Parse(`
<!DOCTYPE html><html><body><center>
	<h2 style="color:blue">Hello {{.Path}} from {{.ServerName}}</h2>
	<h3>Running on OS: {{.OS}}, Arch: {{.Arch}}</h3>
</center></body></html>
`))

