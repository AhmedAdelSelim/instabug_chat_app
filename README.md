# instabug_chat_app

## Overview

This project provides a chat system API built using Ruby on Rails with RabbitMQ for message queuing and Elasticsearch for message search. The system allows creating applications, chats within those applications, and messages within those chats. It includes a message worker to keep track of chat and message counts.

## Prerequisites

Before you start, ensure you have the following installed:

- Ruby (2.7 or later)
- Rails (5.x)
- MySQL
- RabbitMQ
- Docker and Docker Compose (optional, for containerization)
- Elasticsearch (optional, for message search)

## Setup and Configuration

### Environment Variables

Create a `.env` file in the root directory with the following environment variables:

DATABASE_URL=mysql2://username
@localhost:3306/chat_system_db RABBITMQ_URL=amqp://guest
@localhost:5672/ ELASTICSEARCH_URL=http://localhost:9200

Replace `username`, `password`, and `localhost` with your actual database credentials and RabbitMQ URL.

### Database Setup

1. **Create and Migrate the Database**

   Run the following commands to set up the database:

   ```bash
   rails db:create
   rails db:migrate
   ```

If you have seed data, run:
rails db:seed

Build and Run the Docker Containers

bash

```
 docker-compose up --build
```
