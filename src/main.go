package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
)

// getEnvPropertiesPath returns the path from ENV_PROPERTIES_PATH or defaults to "./.env"
func getEnvPropertiesPath() string {
	if path := os.Getenv("ENV_PROPERTIES_PATH"); path != "" {
		return path
	}
	// Default to current working directory with .env
	return "./.env"
}

// readEnvProperties reads the .env file and returns key/value pairs.
func readEnvProperties() map[string]string {
	envMap := make(map[string]string)
	path := getEnvPropertiesPath()
	data, err := os.ReadFile(path)

	if err != nil {
		log.Printf("Error reading env properties from %s: %v", path, err)
		return envMap
	}

	lines := strings.Split(string(data), "\n")

	for _, line := range lines {
		if trimmed := strings.TrimSpace(line); trimmed != "" && !strings.HasPrefix(trimmed, "#") {
			parts := strings.SplitN(trimmed, "=", 2)
			if len(parts) == 2 {
				envMap[strings.TrimSpace(parts[0])] = strings.TrimSpace(parts[1])
			}
		}
	}

	return envMap
}

func handler(w http.ResponseWriter, r *http.Request) {
	// Read properties from the .env file.
	env := readEnvProperties()

	appVersion := env["APP_VERSION"]
	if appVersion == "" {
		appVersion = "Unknown"
	}

	cloudProvider := env["CLOUD_PROVIDER"]
	if cloudProvider == "" {
		cloudProvider = "Unknown"
	}

	region := env["REGION"]
	if region == "" {
		region = "Unknown"
	}

	az := env["AZ"]
	if az == "" {
		az = "Unknown"
	}

	k8sProvider := env["K8S_PROVIDER"]
	if k8sProvider == "" {
		k8sProvider = "Unknown"
	}

	response := fmt.Sprintf(`
		<html>
			<head><title>Info Web App</title></head>
			<body>
				<h1>Info Web App</h1>
				<p>Application Version: %s</p>
				<p>Cloud Provider: %s</p>
				<p>Region: %s</p>
				<p>Availability Zone: %s</p>
				<p>Kubernetes Provider: %s</p>
			</body>
		</html>`, appVersion, cloudProvider, region, az, k8sProvider)

	w.Header().Set("Content-Type", "text/html")
	w.Write([]byte(response))
}

func main() {
	http.HandleFunc("/", handler)
	log.Println("Starting server on port 80")
	if err := http.ListenAndServe(":80", nil); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}
