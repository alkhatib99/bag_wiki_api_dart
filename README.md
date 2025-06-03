# BAG Wiki API (Dart Backend)

A Dart-based backend API for BAG Wiki and BAG Wiki Admin applications, providing section management functionality with PostgreSQL database integration.

## Features

- **RESTful API**: Provides endpoints for managing content sections
- **PostgreSQL Integration**: Connects to PostgreSQL database for data persistence
- **CORS Support**: Configured for secure cross-origin requests from frontend applications
- **Docker Support**: Ready for containerized deployment
- **Environment Configuration**: Flexible configuration via environment variables

## API Endpoints

| Method | Endpoint           | Description                  | Request Body                                      | Response                      |
|--------|-------------------|------------------------------|--------------------------------------------------|-------------------------------|
| GET    | /api/sections     | Fetch all sections           | -                                                | Array of section objects      |
| GET    | /api/sections/:id | Fetch a specific section     | -                                                | Section object                |
| POST   | /api/sections     | Create a new section         | `{ "title": "", "content": "", "imageUrl": "" }` | Created section object        |
| PUT    | /api/sections/:id | Update an existing section   | `{ "title": "", "content": "", "imageUrl": "" }` | Updated section object        |
| DELETE | /api/sections/:id | Delete a section             | -                                                | 204 No Content                |

## Project Structure

```
bag_wiki_api_dart/
├── bin/
│   └── server.dart           # Main entry point
├── lib/
│   ├── config/
│   │   └── database_config.dart  # Database configuration
│   ├── controllers/
│   │   └── section_controller.dart  # Section API controller
│   ├── middleware/
│   │   └── cors_middleware.dart  # CORS handling
│   ├── models/
│   │   └── section_model.dart  # Section data model
│   └── routes/
│       └── api_router.dart  # API route configuration
├── Dockerfile                # Docker configuration
├── pubspec.yaml              # Dart dependencies
├── render.yaml               # Render deployment configuration
└── .env.example              # Example environment variables
```

## Prerequisites

- Dart SDK 3.0.0 or higher
- PostgreSQL database
- Docker (for containerized deployment)

## Environment Variables

Create a `.env` file in the root directory with the following variables:

```
# Database Configuration
DB_HOST=your_postgres_host
DB_PORT=5432
DB_NAME=your_database_name
DB_USER=your_database_user
DB_PASSWORD=your_database_password
DB_SSL=true

# Server Configuration
PORT=8080
ENVIRONMENT=production

# CORS Configuration
ALLOWED_ORIGINS=https://bag-wiki.vercel.app,https://bag-wiki-admin.vercel.app
```

## Local Development

1. Clone the repository:
   ```bash
   git clone https://github.com/alkhatib99/bag_wiki_api_dart.git
   cd bag_wiki_api_dart
   ```

2. Install dependencies:
   ```bash
   dart pub get
   ```

3. Create a `.env` file based on `.env.example`

4. Run the server:
   ```bash
   dart run bin/server.dart
   ```

The server will start on port 8080 (or the port specified in your `.env` file).

## Deployment to Render

### Option 1: Using render.yaml (Recommended)

1. Fork this repository to your GitHub account
2. Connect your GitHub account to Render
3. Create a new Web Service on Render, selecting the repository
4. Render will automatically detect the `render.yaml` file and configure the service
5. Set up the required environment variables in the Render dashboard
6. Deploy the service

### Option 2: Manual Deployment

1. Create a new Web Service on Render
2. Select "Docker" as the environment
3. Connect your GitHub repository
4. Set the following configuration:
   - Build Command: (leave empty, Docker will handle this)
   - Start Command: (leave empty, Docker will handle this)
5. Add the required environment variables
6. Deploy the service

## Docker Deployment

1. Build the Docker image:
   ```bash
   docker build -t bag-wiki-api .
   ```

2. Run the container:
   ```bash
   docker run -p 8080:8080 --env-file .env bag-wiki-api
   ```

## Database Setup

The application will automatically create the necessary tables in your PostgreSQL database on startup. Make sure your database user has the appropriate permissions to create tables.

## Frontend Integration

This API is designed to work with:
- BAG Wiki: https://bag-wiki.vercel.app
- BAG Wiki Admin: https://bag-wiki-admin.vercel.app

Both frontend applications are configured to connect to this API at `https://bag-wiki-api.onrender.com`.

## License

This project is proprietary and owned by BAG Guild.

---

© 2025 BAG Guild. All Rights Reserved.
