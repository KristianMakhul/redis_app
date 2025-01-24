# Redis App

Welcome to Redis App! This Phoenix application integrates with Redis to add, delete, and manage data seamlessly. Follow the instructions below to set up and start the server.

## Demo Video

To see how the app works, check out this demo video:

https://github.com/user-attachments/assets/90285df2-803b-40d3-8ef6-a03c0b734946

## Prerequisites
Before starting, ensure you have the following installed on your system:

- Elixir/Erlang/NodeJS

- Docker and Docker Compose

## Getting Started

### Step 1: Clone the Repository

Clone the repository to your local machine:


```git clone https://github.com/KristianMakhul/redis_app.git```

### Step 2: Navigate to the Project Directory

Move into the project folder:

```cd redis_app/```

### Step 3: Install Dependencies

Fetch all required dependencies:

```mix deps.get```

### Step 4: Start Redis with Docker

Run the following command to start a Redis container using Docker Compose:

```docker-compose up -d```

### Step 5: Start the Phoenix Server

Run the Phoenix server:

```mix phx.server```

