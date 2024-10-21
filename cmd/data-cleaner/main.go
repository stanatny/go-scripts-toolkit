package main

import (
	"fmt"
	"log"
	"os"

	"github.com/stanatny/go-scripts-toolkit/pkg/cleaner"
)

func main() {
	// Default ES URL
	esURL := "http://localhost:9200"

	// Check if a custom ES URL is provided through environment variables
	if customURL := os.Getenv("ES_URL"); customURL != "" {
		esURL = customURL
	}

	fmt.Println("Cleaning all test data...")

	// Clean all indices in Elasticsearch
	err := cleaner.CleanElasticsearchData(esURL)
	if err != nil {
		log.Fatalf("Failed to clean Elasticsearch data: %v", err)
	}

	fmt.Println("All test data cleaned successfully")
}
