# MERN Stack Todo Application Deployment on AWS EC2

This project demonstrates the complete deployment of a MERN (MongoDB, Express.js, React.js, Node.js) stack Todo application on AWS EC2 instance with API testing using Postman.

## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Architecture](#architecture)
- [Step-by-Step Deployment Guide](#step-by-step-deployment-guide)
- [API Testing with Postman](#api-testing-with-postman)
- [Troubleshooting](#troubleshooting)
- [Conclusion](#conclusion)

## Overview

This MERN stack Todo application includes:
- **MongoDB**: Database for storing todo items
- **Express.js**: Backend API server with routes
- **React.js**: Frontend client application
- **Node.js**: Runtime environment (v18.20.8)

**Project Structure:**
```
~/
├── index.js              # Main server file
├── package.json          # Backend dependencies
├── routes/
│   └── api.js            # API routes
└── Todo/
    ├── client/           # React frontend
    ├── models/           # MongoDB schemas
    └── .env             # Environment variables
```

## Prerequisites

- AWS Account with EC2 access
- Basic knowledge of Linux commands
- Understanding of JavaScript and MERN stack
- SSH client and Postman for API testing

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Postman/      │    │   AWS EC2       │    │   MongoDB       │
│   React Client  │◄──►│   Ubuntu 24.04  │◄──►│   Database      │
│                 │    │   Port 5000     │    │   Port 27017    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌─────────────────┐
                       │   Todo API      │
                       │   Express.js    │
                       │   Mongoose      │
                       └─────────────────┘
```

## Step-by-Step Deployment Guide

### Step 1: AWS EC2 Instance Launch
![EC2 Launch](Screenshot%20from%202025-09-01%2022-11-12.png)

**Launch Ubuntu 24.04 LTS EC2 Instance:**
- Instance Type: t2.micro (free tier)
- AMI: Ubuntu 24.04.3 LTS (Noble Numbat)
- Key Pair: steghub.pem

### Step 2: Security Group Configuration
![Security Groups](Screenshot%20from%202025-09-01%2022-13-00.png)

**Configure Inbound Rules:**
```bash
Port 22   - SSH (Your IP)
Port 80   - HTTP (0.0.0.0/0)
Port 443  - HTTPS (0.0.0.0/0)
Port 3000 - React Dev Server (0.0.0.0/0)
Port 5000 - Express API (0.0.0.0/0)
```

### Step 3: SSH Connection to EC2
![SSH Connection](Screenshot%20from%202025-09-01%2022-18-42.png)

**Connect to EC2 Instance:**
```bash
# Set correct permissions for key
chmod 400 steghub.pem

# Connect to EC2
ssh -i steghub.pem ubuntu@44.211.186.181

# Update system packages
sudo apt update && sudo apt upgrade -y
```

### Step 4: Install Node.js and npm
![Node.js Installation](Screenshot%20from%202025-09-01%2022-33-05.png)

**Install Node.js v18.20.8:**
```bash
# Install Node.js from NodeSource
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify installation
node --version  # v18.20.8
npm --version   # 10.8.2
```

### Step 5: Install and Configure MongoDB
![MongoDB Installation](Screenshot%20from%202025-09-01%2022-38-10.png)

**MongoDB Setup:**
```bash
# Import MongoDB GPG key
wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add -

# Add MongoDB repository
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list

# Install MongoDB
sudo apt-get update
sudo apt-get install -y mongodb-org

# Start and enable MongoDB
sudo systemctl start mongod
sudo systemctl enable mongod
```

### Step 6: Initialize Backend Application
![Backend Setup](Screenshot%20from%202025-09-01%2022-42-07.png)

**Create Backend Structure:**
```bash
# Initialize npm project
npm init -y

# Install dependencies
npm install express mongoose dotenv
npm install -D nodemon concurrently

# Create directories
mkdir routes Todo
```

### Step 7: Configure Express Server
![Express Configuration](Screenshot%20from%202025-09-01%2022-53-43.png)

**Main Server File (index.js):**
```javascript
require('dotenv').config({ path: __dirname + '/Todo/.env' });

const express = require('express');
const bodyParser = require('body-parser');
const mongoose = require('mongoose');
const routes = require('./routes/api');

const app = express();
const port = process.env.PORT || 5000;

// Database connection
mongoose.connect(process.env.DB, {})
  .then(() => console.log('✅ Database connected successfully'))
  .catch(err => console.error('❌ DB Connection Error:', err));

mongoose.Promise = global.Promise;

// Middleware
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept');
  next();
});

app.use(bodyParser.json());
app.use('/api', routes);

app.get('/', (req, res) => {
  res.send('Welcome to my Todo API! Use /api/todos to interact with tasks.');
});

app.use((err, req, res, next) => {
  console.error(err.message);
  res.status(422).send({ error: err.message });
});

app.listen(port, () => {
  console.log(`🌍 Server running on port ${port}`);
});
```

### Step 8: Create React Frontend
![React Setup](Screenshot%20from%202025-09-01%2023-30-59.png)

**Frontend Setup:**
```bash
# Navigate to Todo directory
cd Todo

# Create React app
npx create-react-app client
cd client

# Install additional dependencies
npm install axios

# Project structure created:
# Todo/client/src/components/
# Todo/client/src/App.js
# Todo/client/package.json
```

### Step 9: Database Models and API Routes
![Database Models](Screenshot%20from%202025-09-01%2023-49-01.png)

**Create MongoDB Models:**
```bash
# In Todo/models/ directory
# Define Todo schema for MongoDB collections
```

**API Routes (routes/api.js):**
```javascript
// RESTful API endpoints for Todo operations
// GET /api/todos - Fetch all todos
// POST /api/todos - Create new todo
// DELETE /api/todos/:id - Delete todo
```

### Step 10: Environment Configuration
![Environment Setup](Screenshot%20from%202025-09-01%2023-49-37.png)

**Environment Variables (Todo/.env):**
```bash
# Database connection string
DB=mongodb://localhost:27017/todo
PORT=5000
```

### Step 11: Application Testing
![Application Testing](Screenshot%20from%202025-09-02%2000-00-09.png)

**Start Development Servers:**
```bash
# Start backend server
node index.js

# In another terminal, start React client
cd Todo/client
npm start
```

### Step 12: API Testing with Postman
![Postman Testing](Screenshot%20from%202025-09-02%2020-49-16.png)

**Test API Endpoints:**
```bash
# Test server connection
GET http://44.211.186.181:5000/

# Test Todo API endpoints
GET http://44.211.186.181:5000/api/todos
POST http://44.211.186.181:5000/api/todos
DELETE http://44.211.186.181:5000/api/todos/:id
```

### Step 13: Frontend-Backend Integration
![Frontend Integration](Screenshot%20from%202025-09-02%2020-59-07.png)

**React Components:**
- Todo list display
- Add new todo functionality
- Delete todo operations
- API integration with Axios

### Step 14: Production Deployment
![Production Setup](Screenshot%20from%202025-09-02%2021-04-55.png)

**Production Configuration:**
```bash
# Build React app
cd Todo/client
npm run build

# Install PM2 for process management
sudo npm install -g pm2

# Start backend with PM2
pm2 start index.js --name "todo-api"
pm2 startup
pm2 save
```

### Step 15: Additional Screenshots Documentation
![Additional Setup 1](Screenshot%20from%202025-09-02%2021-06-25.png)
![Additional Setup 2](Screenshot%20from%202025-09-02%2021-21-24.png)
![Additional Setup 3](Screenshot%20from%202025-09-02%2021-44-35.png)
![Additional Setup 4](Screenshot%20from%202025-09-02%2021-45-02.png)
![Additional Setup 5](Screenshot%20from%202025-09-02%2022-14-57.png)
![Additional Setup 6](Screenshot%20from%202025-09-02%2022-15-11.png)
![Additional Setup 7](Screenshot%20from%202025-09-02%2022-15-30.png)
![Additional Setup 8](Screenshot%20from%202025-09-02%2022-24-35.png)
![Additional Setup 9](Screenshot%20from%202025-09-02%2022-51-36.png)
![Final Verification](Screenshot%20from%202025-09-02%2023-00-23.png)

## API Testing with Postman

### Available Endpoints

**Base URL:** `http://44.211.186.181:5000`

1. **GET /** - Welcome message
2. **GET /api/todos** - Fetch all todos
3. **POST /api/todos** - Create new todo
4. **DELETE /api/todos/:id** - Delete specific todo

### Sample API Requests

**Create Todo:**
```json
POST /api/todos
Content-Type: application/json

{
  "action": "Learn MERN Stack",
  "completed": false
}
```

**Get All Todos:**
```json
GET /api/todos
Response: [
  {
    "_id": "...",
    "action": "Learn MERN Stack",
    "completed": false
  }
]
```

## Actual Implementation Details

**System Information:**
- OS: Ubuntu 24.04.3 LTS (Noble Numbat)
- Node.js: v18.20.8
- npm: 10.8.2
- Architecture: x86_64

**Dependencies:**
```json
{
  "dependencies": {
    "dotenv": "^17.2.1",
    "express": "^5.1.0",
    "mongoose": "^8.18.0"
  },
  "devDependencies": {
    "concurrently": "^9.2.1",
    "nodemon": "^3.1.10"
  }
}
```

## Troubleshooting

### Common Issues

1. **MongoDB Connection Issues:**
```bash
# Check MongoDB status
sudo systemctl status mongod
sudo systemctl restart mongod
```

2. **Port Access Issues:**
```bash
# Check if port is in use
sudo netstat -tlnp | grep :5000
```

3. **Environment Variables:**
```bash
# Verify .env file location and content
cat Todo/.env
```

4. **CORS Issues:**
```javascript
// Ensure CORS headers are properly set
res.header('Access-Control-Allow-Origin', '*');
```

## Security Considerations

1. **Environment Variables:** Store sensitive data in .env files
2. **CORS Configuration:** Properly configure allowed origins
3. **Input Validation:** Validate all API inputs
4. **MongoDB Security:** Restrict database access to localhost

## Performance Optimization

1. **Database Indexing:** Create indexes for frequently queried fields
2. **Connection Pooling:** Use mongoose connection pooling
3. **Error Handling:** Implement comprehensive error handling
4. **Logging:** Add proper logging for debugging

## Conclusion

This project successfully demonstrates:

✅ **Complete MERN Stack Deployment** on AWS EC2  
✅ **Ubuntu 24.04 LTS** server configuration  
✅ **Node.js v18.20.8** and npm setup  
✅ **MongoDB** database integration  
✅ **Express.js API** with RESTful endpoints  
✅ **React.js** frontend application  
✅ **API Testing** with Postman  
✅ **Environment Configuration** with .env files  
✅ **Production Deployment** with PM2  

The Todo application is fully functional with:
- Backend API server running on port 5000
- Frontend React client
- MongoDB database integration
- Complete CRUD operations
- API testing capabilities

**Next Steps:**
1. Implement user authentication
2. Add data validation
3. Set up automated testing
4. Configure CI/CD pipeline
5. Add monitoring and logging


**Author:** Nelson Ngumo  
**Project:** StegHub DevOps Cloud Bootcamp  
**Date:** September 2025  
**EC2 Instance:** 44.211.186.181  
**Repository:** AWS-Projects/StegHub-DevOps-Cloud-Bootcamp/Mern-Stack