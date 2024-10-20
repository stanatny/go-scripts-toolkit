package main

import (
	"fmt"
	"log"
	"os"
	"path/filepath"

	"github.com/stanatny/go-scripts-toolkit/pkg/esloader"
)

func main() {
	// Default ES URL
	esURL := "http://localhost:9200"

	// Root data directory for es_data_loader
	rootDataDir := filepath.Join("data", "es_data_loader")

	// Traverse each subdirectory under rootDataDir
	err := filepath.Walk(rootDataDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		// Skip if not a directory or if it is the root directory itself
		if !info.IsDir() || path == rootDataDir {
			return nil
		}

		// The subdirectory name is used as the index name
		indexName := info.Name()
		dataDir := path

		// Load mapping file
		mappingPath := filepath.Join(dataDir, "mapping.json")
		if _, err := os.Stat(mappingPath); os.IsNotExist(err) {
			log.Printf("Skipping %s: mapping file %s not found\n", indexName, mappingPath)
			return nil // Skip this directory if no mapping file found
		}

		fmt.Printf("Processing index: %s\n", indexName)

		// Drop the index if it exists
		err = esloader.DropIndex(esURL, indexName)
		if err != nil {
			log.Printf("Failed to drop index %s: %v\n", indexName, err)
			return err
		}
		fmt.Printf("Index %s dropped successfully\n", indexName)

		// Set up the new mapping
		err = esloader.SetupMapping(esURL, indexName, mappingPath)
		if err != nil {
			log.Printf("Failed to setup mapping for index %s: %v\n", indexName, err)
			return err
		}
		fmt.Printf("ES mapping for index %s set up successfully\n", indexName)

		// Load the test data
		err = esloader.LoadData(esURL, indexName, dataDir)
		if err != nil {
			log.Printf("Failed to load data for index %s: %v\n", indexName, err)
			return err
		}
		fmt.Printf("Data for index %s imported successfully\n", indexName)

		return nil
	})

	if err != nil {
		log.Fatalf("Error while processing data directories: %v", err)
	}

	fmt.Println("All indices processed successfully")
}
