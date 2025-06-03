FROM dart:stable AS build

WORKDIR /app

# Copy pubspec files
COPY pubspec.* ./

# Get dependencies
RUN dart pub get

# Copy the rest of the application code
COPY . .

# Build the application
RUN dart compile exe bin/server.dart -o bin/server

# Create a smaller runtime image
FROM debian:bullseye-slim

# Install SSL certificates for HTTPS requests
RUN apt-get update && \
    apt-get install -y ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the compiled binary from the build stage
COPY --from=build /app/bin/server /app/bin/server

# Copy any other necessary files
COPY --from=build /app/.env.example /app/.env.example

# Expose the port the server listens on
EXPOSE 8080

# Start the server
CMD ["/app/bin/server"]
