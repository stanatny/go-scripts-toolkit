# go-scripts
A Go-based script library for setting up test environments, generating test data, and providing various utility tools. The project is designed to facilitate automated testing and development tasks with Go, while also supporting auxiliary Python and Shell scripts for additional automation needs.

## File Structure
```perl
go-scripts-toolkit/           # Root directory
├── cmd/                      # Go main program entry points
│   └── es-data-loader/       # ES test data construction tool entry
│       └── main.go           # Main entry point for ES data loader
├── pkg/                      # Go packages and reusable libraries
│   └── esloader/             # ES data loading library
│       ├── loader.go         # Data import implementation
│       └── mapping.go        # ES mapping operations
├── data/                     # Data directory
│   └── es_data_loader/       # Data for the ES data loader
│       └── test-index/       # Sample index
│           ├── mapping.json  # Mapping file for the sample index
│           ├── doc_1.json    # Sample data file 1
│           └── doc_2.json    # Sample data file 2
├── internal/                 # Internal modules for the project
├── scripts/                  # Auxiliary scripts
│   ├── python/               # Python helper scripts
│   └── shell/                # Shell helper scripts
├── docs/                     # Documentation
├── go.mod                    # Go module dependency file
├── go.sum                    # Go module version lock file
├── Makefile                  # Build and automation tasks
└── .gitignore                # Git ignore rules
```

## Scripts
### ES Data Loader
The `es-data-loader` script, located in `cmd/es-data-loader/`, is a tool for setting up Elasticsearch (ES) test data. It automates the process of creating ES indices, configuring mappings, and importing test data. The script supports multiple data directories under `data/es_data_loader/`, where each subdirectory corresponds to an index name. Each subdirectory should include a `mapping.json` file to define the mapping for the index and `doc_{id}.json` files for the data documents.

#### How It Works
1. **Index Setup**: The script traverses the `data/es_data_loader/` directory, identifying subdirectories as potential indices.
2. **Mapping Configuration**: For each subdirectory, the script checks for a `mapping.json` file and uses it to set up the index mapping.
3. **Data Import**: The script loads any `doc_{id}.json` files found in the subdirectory as documents in the corresponding index, where `{id}` is used as the document ID.
4. **Re-initialization Support**: Before setting up the mapping and loading data, the script drops any existing index with the same name to ensure a clean state.

#### Example Usage
1. Make sure the Elasticsearch server is running at the default address (`http://localhost:9200`).
2. Run the script with:
``` bash
make script-gen-es-data
```

#### Adding New Data Sets
To add a new data set:
1. Create a new subdirectory under `data/es_data_loader/` named after the desired index.
2. Add a `mapping.json` file in the new subdirectory to define the index mapping.
3. Add one or more `doc_{id}.json` files for the documents you want to import.

## Environment Setup
To help set up common services required for testing, such as Elasticsearch, Kibana, MySQL, MongoDB, and Redis, the project provides several Docker commands via the Makefile.

### Start Elasticsearch and Kibana
You can use the following commands to start Elasticsearch and Kibana using Docker:
```bash
# Start Elasticsearch
make run-docker-es

# Start Kibana (make sure Elasticsearch is already running)
make run-docker-kibana
```

For ARM64 architecture, use the following commands:
```bash
# Start Elasticsearch for ARM64
make run-docker-es-arm64

# Start Kibana for ARM64 (make sure Elasticsearch is already running)
make run-docker-kibana-arm64
```

### Start Other Services
The project also provides Docker commands to start other common services:
```bash
# Start MySQL
make run-docker-mysql

# Start MongoDB
make run-docker-mongo

# Start Redis
make run-docker-redis
```

For ARM64 architecture, use:
```bash
# Start MySQL for ARM64
make run-docker-mysql-arm64

# Start MongoDB for ARM64
make run-docker-mongo-arm64

# Start Redis for ARM64
make run-docker-redis-arm64
```

## Development
### Building the Project
To build the Go scripts, run:
```bash
make build
```

### Running Tests
To run the tests, use:
```bash
make test
```

### Cleaning Up
To clean up the build artifacts, execute:
```bash
make clean
```

### Code Formatting
To format the Go code, run:
```bash
make fmt
```

## Contributing
1. Fork the repository.
2. Create a new branch (`git checkout -b feature/new-feature`).
3. Commit your changes (`git commit -am 'Add new feature'`).
4. Push the branch (`git push origin feature/new-feature`).
5. Open a pull request.

## License
This project is licensed under the MIT License. See the `LICENSE` file for details.

