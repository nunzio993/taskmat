# TaskMate

TaskMate is a comprehensive platform connecting users with local helpers for various tasks.

## Project Structure

- `apps/backend`: FastAPI backend service.
- `apps/mobile`: Flutter mobile application.
- `infra`: Docker Compose configuration for database and redis.
- `docs`: Documentation.

## Getting Started

Follow these steps to set up the project on a new machine.

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop)
- [Python 3.10+](https://www.python.org/downloads/)
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Git](https://git-scm.com/downloads)

### Installation

1.  **Clone the repository:**
    ```bash
    git clone <repository_url>
    cd taskmat
    ```

2.  **Start Infrastructure (Database & Redis):**
    ```bash
    cd infra
    docker-compose up -d
    cd ..
    ```

3.  **Setup Backend:**
    ```bash
    cd apps/backend
    
    # Create virtual environment
    python -m venv venv
    
    # Activate virtual environment
    # Windows:
    .\venv\Scripts\Activate
    # Mac/Linux:
    # source venv/bin/activate
    
    # Install dependencies
    pip install -r requirements.txt
    
    # Configure Environment
    cp .env.example .env
    # NOTE: Check .env and ensure DATABASE_URL points to localhost if running outside docker.
    # The default .env.example assumes local execution connecting to dockerized DB on localhost:5432.
    
    # Run Migrations (if applicable)
    # alembic upgrade head
    
    cd ../..
    ```

4.  **Setup Mobile App:**
    ```bash
    cd apps/mobile
    flutter pub get
    cd ../..
    ```

### Running the Application

**Run everything (Windows PowerShell):**
Use the provided script to start everything (clears port 3000, starts docker, backend, and flutter web):
```powershell
.\dev_start.ps1
```

**Run manually:**

1.  **Backend:**
    ```bash
    cd apps/backend
    uvicorn main:app --reload
    ```
    API docs available at: http://localhost:8000/docs

2.  **Mobile (Flutter):**
    ```bash
    cd apps/mobile
    flutter run
    ```

## Notes

- The backend runs on `http://localhost:8000`.
- Experience issues with SQLite? The project is configured for PostgreSQL. Ensure Docker is running.
