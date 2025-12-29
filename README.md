# TaskMate

## Getting Started

### Prerequisites
- Docker
- Docker Compose

### Running the Backend

1. Navigate to the `infra` directory:
   ```bash
   cd infra
   ```

2. Start the services:
   ```bash
   docker-compose up -d
   ```

3. The API will be available at `http://localhost:8000`.
   Check the health endpoint: `http://localhost:8000/health`.
