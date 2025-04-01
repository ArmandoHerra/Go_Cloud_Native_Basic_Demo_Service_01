package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
)

func main() {
	// Create in-cluster config
	config, err := rest.InClusterConfig()
	if err != nil {
		log.Fatalf("Error creating in-cluster config: %v", err)
	}

	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		log.Fatalf("Error creating Kubernetes client: %v", err)
	}

	// Get the node name from environment injected via downward API
	nodeName := os.Getenv("NODE_NAME")
	if nodeName == "" {
		log.Fatalf("NODE_NAME environment variable is not set")
	}

	// Fetch the node object
	node, err := clientset.CoreV1().Nodes().Get(context.Background(), nodeName, metav1.GetOptions{})
	if err != nil {
		log.Fatalf("Error retrieving node %q: %v", nodeName, err)
	}

	// Read labels for region and AZ
	region := node.Labels["topology.kubernetes.io/region"]
	zone := node.Labels["topology.kubernetes.io/zone"]

	// Fallback to legacy labels if needed
	if region == "" || zone == "" {
		region = node.Labels["failure-domain.beta.kubernetes.io/region"]
		zone = node.Labels["failure-domain.beta.kubernetes.io/zone"]
	}

	appVersion := os.Getenv("APP_VERSION")
	if appVersion == "" {
		appVersion = "Unknown"
	}

	fmt.Printf("App Version: %s\n", appVersion)
	fmt.Printf("Running on Node: %s\n", nodeName)
	fmt.Printf("Region: %s\n", region)
	fmt.Printf("Zone: %s\n", zone)

	// Serve HTTP requests (for example)
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		response := fmt.Sprintf(`
			<html>
				<head><title>Info Web App</title></head>
				<body>
					<h1>Info Web App</h1>
					<p>Application Version: %s</p>
					<p>Running on Node: %s</p>
					<p>Region: %s</p>
					<p>Availability Zone: %s</p>
				</body>
			</html>`, appVersion, nodeName, region, zone)
		w.Header().Set("Content-Type", "text/html")
		w.Write([]byte(response))
	})

	log.Println("Starting server on port 80")
	if err := http.ListenAndServe(":80", nil); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}
