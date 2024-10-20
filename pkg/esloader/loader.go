package esloader

import (
	"bytes"
	"fmt"
	"io/ioutil"
	"net/http"
	"path/filepath"
	"strings"
)

// LoadData imports all JSON documents in the specified directory to the given index
func LoadData(esURL, indexName, dataDir string) error {
	files, err := ioutil.ReadDir(dataDir)
	if err != nil {
		return fmt.Errorf("failed to read data directory: %w", err)
	}

	client := &http.Client{}
	for _, file := range files {
		if filepath.Ext(file.Name()) != ".json" || file.Name() == "mapping.json" {
			continue
		}

		filePath := filepath.Join(dataDir, file.Name())
		data, err := ioutil.ReadFile(filePath)
		if err != nil {
			return fmt.Errorf("failed to read data file %s: %w", filePath, err)
		}

		// Extract the document ID from the file name (e.g., "doc_1.json" -> "1")
		docID := strings.TrimPrefix(file.Name(), "doc_")
		docID = strings.TrimSuffix(docID, ".json")

		if docID == "" {
			return fmt.Errorf("failed to get doc id from file %s", filePath)
		}

		url := fmt.Sprintf("%s/%s/_doc/%s", esURL, indexName, docID)
		req, err := http.NewRequest("POST", url, bytes.NewBuffer(data))
		if err != nil {
			return fmt.Errorf("failed to create HTTP request: %w", err)
		}
		req.Header.Set("Content-Type", "application/json")

		resp, err := client.Do(req)
		if err != nil {
			return fmt.Errorf("failed to send HTTP request: %w", err)
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusCreated {
			body, _ := ioutil.ReadAll(resp.Body)
			return fmt.Errorf("failed to index document %s: %s", file.Name(), string(body))
		}

		fmt.Printf("Indexed document %s successfully\n", file.Name())
	}

	return nil
}
