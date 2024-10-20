package esloader

import (
	"bytes"
	"fmt"
	"io/ioutil"
	"net/http"
)

// DropIndex deletes the specified index if it exists
func DropIndex(esURL, indexName string) error {
	url := fmt.Sprintf("%s/%s", esURL, indexName)
	req, err := http.NewRequest("DELETE", url, nil)
	if err != nil {
		return fmt.Errorf("failed to create HTTP request: %w", err)
	}

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("failed to send HTTP request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusNotFound {
		body, _ := ioutil.ReadAll(resp.Body)
		return fmt.Errorf("failed to delete index: %s", string(body))
	}

	return nil
}

// SetupMapping creates a new index with the specified mapping
func SetupMapping(esURL, indexName, mappingPath string) error {
	mapping, err := ioutil.ReadFile(mappingPath)
	if err != nil {
		return fmt.Errorf("failed to read mapping file: %w", err)
	}

	url := fmt.Sprintf("%s/%s", esURL, indexName)
	req, err := http.NewRequest("PUT", url, bytes.NewBuffer(mapping))
	if err != nil {
		return fmt.Errorf("failed to create HTTP request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("failed to send HTTP request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := ioutil.ReadAll(resp.Body)
		return fmt.Errorf("failed to set mapping: %s", string(body))
	}

	return nil
}
