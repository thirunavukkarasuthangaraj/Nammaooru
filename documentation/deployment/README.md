# Deployment Documentation

Guides for deploying NammaOoru to production and CI/CD configuration.

## 📄 Documents in this folder

### [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
Complete deployment procedures for production environment
- Server setup and configuration
- Database deployment
- Application deployment
- Environment variables
- SSL/HTTPS setup
- Domain configuration

### [TROUBLESHOOTING_GUIDE.md](TROUBLESHOOTING_GUIDE.md)
Common deployment issues and solutions
- Database connection issues
- Application startup problems
- Performance issues
- Network and firewall configuration
- Logging and monitoring

## 🚀 Quick Deployment Steps

1. **Prepare Server**
   - Ubuntu 20.04+ LTS
   - PostgreSQL 15+
   - Java 17+
   - Node.js 18+

2. **Database Setup**
   - Create PostgreSQL database
   - Run migrations
   - Configure connection

3. **Deploy Backend**
   - Build JAR file
   - Configure application.yml
   - Start Spring Boot app

4. **Deploy Frontend**
   - Build Angular app
   - Configure Nginx
   - Setup reverse proxy

5. **Deploy Mobile Apps**
   - Build release APKs
   - Upload to Play Store
   - Configure Firebase

## 🔧 CI/CD Pipeline

The project uses GitHub Actions for automatic deployment:
- Push to `main` branch triggers deployment
- Backend and frontend deployed separately
- Automated tests run before deployment

## 📞 Support

For deployment issues, check the [Troubleshooting Guide](TROUBLESHOOTING_GUIDE.md).
