# Node.js REST API Application

This project demonstrates a simple Node.js REST API application for managing items.

## Directory Structure

```
.
├── nodejs-app/
│   ├── app.js                    # Node.js application code
│   ├── data.json                 # Sample data
│   ├── Dockerfile                # Dockerfile for Node.js app
│   └── package.json              # Node.js dependencies
├── docker-compose.yml            # Docker Compose configuration
└── README.md                     # This file
```

## Getting Started

1. Build and start the services:
   ```
   docker-compose up -d
   ```

2. Access the service:
   - Node.js API: http://localhost:3000/items

## API Endpoints

- `GET /items`: Get all items
- `POST /items/filter`: Filter items by category
- `GET /health`: Health check endpoint
