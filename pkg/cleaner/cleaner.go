package cleaner

import (
	"fmt"
	"io/ioutil"
	"net/http"
)

// CleanElasticsearchData deletes all indices from the specified Elasticsearch instance
func CleanElasticsearchData(esURL string) error {
	// Delete all indices
	url := fmt.Sprintf("%s/*", esURL)
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

	if resp.StatusCode != http.StatusOK {
		body, _ := ioutil.ReadAll(resp.Body)
		return fmt.Errorf("failed to delete all indices: %s", string(body))
	}

	return nil
}
