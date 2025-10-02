# MEAN Stack Application

A full-stack web application built with MongoDB, Express.js, Angular, and Node.js (MEAN Stack) as part of the StegHub DevOps Cloud Bootcamp.

##  Project Overview

This project demonstrates the implementation of a complete MEAN stack application, showcasing modern web development practices and cloud deployment strategies. The application provides a robust foundation for building scalable web applications using JavaScript technologies throughout the entire stack.

## 🛠️ Technology Stack

- **MongoDB** - NoSQL database for data persistence
- **Express.js** - Web application framework for Node.js
- **Angular** - Frontend framework for building dynamic user interfaces
- **Node.js** - JavaScript runtime environment for server-side development

## 📋 Prerequisites

Before running this application, ensure you have the following installed:

- Node.js (v14.x or higher)
- npm (v6.x or higher)
- MongoDB (v4.x or higher)
- Angular CLI (v12.x or higher)

## 🔧 Installation & Setup

### 1. Clone the Repository
```bash
git clone <repository-url>
cd MEAN-Stack
```

### 2. Install Dependencies
```bash
# Install backend dependencies
npm install

# Install frontend dependencies (if separate Angular app)
cd client
npm install
cd ..
```

### 3. Environment Configuration
Create a `.env` file in the root directory:
```env
PORT=3000
MONGODB_URI=mongodb://localhost:27017/meanstack
NODE_ENV=development
```

### 4. Start MongoDB Service
```bash
# On Ubuntu/Linux
sudo systemctl start mongod

# On macOS with Homebrew
brew services start mongodb-community
```

### 5. Run the Application
```bash
# Start the backend server
npm start

# Start the Angular development server (in a new terminal)
cd client
ng serve
```

## 📸 Application Screenshots

### Initial Setup and Configuration
![Project Setup](Screenshot%20from%202025-09-08%2022-25-05.png)
*Initial project configuration and environment setup*

### Database Connection
![Database Setup](Screenshot%20from%202025-09-08%2022-44-08.png)
*MongoDB database connection and configuration*

### Backend API Development
![API Development](Screenshot%20from%202025-09-08%2022-46-19.png)
*Express.js API endpoints and middleware configuration*

### Frontend Development
![Frontend Interface](Screenshot%20from%202025-09-08%2022-47-44.png)
*Angular frontend component development*

### Application Testing
![Testing Phase](Screenshot%20from%202025-09-08%2022-53-33.png)
*Application testing and debugging process*

### Feature Implementation
![Feature Development](Screenshot%20from%202025-09-08%2023-10-18.png)
*Implementation of core application features*

### User Interface
![UI Components](Screenshot%20from%202025-09-08%2023-10-24.png)
*User interface components and styling*

### Data Management
![Data Operations](Screenshot%20from%202025-09-08%2023-14-16.png)
*CRUD operations and data management functionality*

### Application Deployment
![Deployment Process](Screenshot%20from%202025-09-08%2023-21-26.png)
*Application deployment and production setup*

### Performance Optimization
![Performance Tuning](Screenshot%20from%202025-09-08%2023-32-11.png)
*Performance optimization and monitoring*

### Final Application
![Final Result](Screenshot%20from%202025-09-08%2023-37-45.png)
*Completed MEAN stack application running successfully*

## 🏗️ Project Structure

```
MEAN-Stack/
├── server/
│   ├── models/          # MongoDB data models
│   ├── routes/          # Express.js API routes
│   ├── middleware/      # Custom middleware functions
│   ├── config/          # Configuration files
│   └── app.js           # Main server file
├── client/
│   ├── src/
│   │   ├── app/         # Angular components
│   │   ├── services/    # Angular services
│   │   ├── models/      # TypeScript interfaces
│   │   └── assets/      # Static assets
│   └── angular.json     # Angular configuration
├── package.json         # Node.js dependencies
└── README.md           # Project documentation
```

## 🔌 API Endpoints

### User Management
- `GET /api/users` - Get all users
- `POST /api/users` - Create new user
- `GET /api/users/:id` - Get user by ID
- `PUT /api/users/:id` - Update user
- `DELETE /api/users/:id` - Delete user

### Authentication
- `POST /api/auth/login` - User login
- `POST /api/auth/register` - User registration
- `POST /api/auth/logout` - User logout

## 🧪 Testing

Run the test suite:
```bash
# Backend tests
npm test

# Frontend tests
cd client
ng test
```

## 🚀 Deployment

### Local Development
```bash
npm run dev
```

### Production Build
```bash
# Build Angular app
cd client
ng build --prod

# Start production server
npm run start:prod
```

### Cloud Deployment
This application can be deployed on various cloud platforms:
- AWS EC2 with MongoDB Atlas
- Heroku with MongoDB Atlas
- DigitalOcean Droplets
- Google Cloud Platform

## 🔒 Security Features

- Input validation and sanitization
- JWT-based authentication
- CORS configuration
- Environment variable protection
- MongoDB injection prevention

## 📊 Performance Considerations

- Database indexing for optimized queries
- Angular lazy loading for improved load times
- Express.js compression middleware
- Static asset optimization
- Caching strategies implementation

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Nelson Ngumo**
- GitHub: [@nelson-ngumo](https://github.com/nelson-ngumo)
- LinkedIn: [Nelson Ngumo](https://linkedin.com/in/nelson-ngumo)

## 🙏 Acknowledgments

- StegHub DevOps Cloud Bootcamp for the comprehensive training
- MEAN stack community for excellent documentation
- MongoDB, Express.js, Angular, and Node.js teams for amazing technologies

## 📞 Support

If you have any questions or need help with setup, please:
1. Check the [Issues](../../issues) page
2. Create a new issue with detailed description
3. Contact the maintainer directly

---

**Built with ❤️ as part of StegHub DevOps Cloud Bootcamp**