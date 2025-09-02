# NammaOoru Shop Management System - Documentation Index

## 📚 Complete Documentation Suite

This documentation covers everything you need to know about the NammaOoru Shop Management System, including the painful email issues we faced and how we solved them.

## 🔗 Quick Navigation

| Document | Description | When to Use |
|----------|-------------|-------------|
| [📧 Email Configuration](EMAIL_CONFIGURATION.md) | SMTP setup, OTP emails, Hostinger config | When email isn't working |
| [🚀 Deployment Guide](DEPLOYMENT_GUIDE.md) | Server setup, Docker, why we faced issues | When deploying or rebuilding |
| [📱 Mobile App Guide](MOBILE_APP_GUIDE.md) | Flutter app, API integration, build process | When working on mobile app |
| [🔧 Troubleshooting Guide](TROUBLESHOOTING_GUIDE.md) | Common issues, solutions, emergency fixes | When things break |

## 🎯 Why This Documentation Exists

### The Email Nightmare We Survived
We spent hours troubleshooting email issues because:
1. **Hardcoded Gmail defaults** in application.yml
2. **FROM address mismatch** with Hostinger SMTP
3. **Network/firewall** blocking SMTP ports  
4. **SSL handshake failures** between Java and Hostinger
5. **Missing documentation** of working configurations

**Result**: Lost time, frustrated debugging, production downtime

### What We Learned
- **Document everything** before it breaks
- **Test email in production** environment
- **Always match FROM address** with SMTP username
- **Keep working configurations** in version control
- **Have troubleshooting guides** ready

## 🏗️ System Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Mobile App    │    │  Web Frontend   │    │  Admin Panel    │
│   (Flutter)     │    │   (Angular)     │    │   (Angular)     │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          └──────────────────────┼──────────────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │     API Gateway         │
                    │  (nginx reverse proxy)  │
                    └────────────┬────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │   Backend API Server    │
                    │   (Spring Boot)         │
                    └────────────┬────────────┘
                                 │
          ┌──────────────────────┼──────────────────────┐
          │                      │                      │
┌─────────▼───────┐   ┌──────────▼──────────┐   ┌───────▼───────┐
│   PostgreSQL    │   │   File Storage      │   │  SMTP Server  │
│   Database      │   │   (Local/Cloud)     │   │ (Hostinger)   │
└─────────────────┘   └─────────────────────┘   └───────────────┘
```

## 🌐 Production Environment

### Server Details
- **Provider**: Hetzner Cloud
- **IP**: 65.21.4.236  
- **OS**: Ubuntu Server
- **Domain**: nammaoorudelivary.in
- **API**: api.nammaoorudelivary.in
- **SSL**: Let's Encrypt

### Key Services
- **Frontend**: Nginx serving Angular SPA
- **Backend**: Spring Boot in Docker container
- **Database**: PostgreSQL in Docker container
- **Email**: Hostinger SMTP (noreplay@nammaoorudelivary.in)
- **Mobile**: Flutter app connecting to production API

## 🚨 Emergency Quick Reference

### Email Not Working?
1. Check FROM address matches SMTP username: `noreplay@nammaoorudelivary.in`
2. Verify SMTP port (465 or 587) is open in firewall
3. Check backend logs: `docker-compose logs backend | grep -i mail`
4. Test OTP endpoint: `curl -X POST https://api.nammaoorudelivary.in/api/auth/send-otp`

### API Not Responding?
1. Check container status: `docker-compose ps`
2. Restart services: `docker-compose restart`
3. Check nginx: `systemctl status nginx`
4. View logs: `docker-compose logs -f backend`

### Mobile App Not Connecting?
1. Verify API URL: `https://api.nammaoorudelivary.in/api`
2. Check network connectivity from device
3. Enable debug logging in ApiClient
4. Test API in browser first

### Complete System Down?
```bash
# Nuclear option - rebuild everything
docker-compose down
docker system prune -a -f
git pull origin main
docker-compose up --build -d
```

## 📋 Pre-Flight Checklist

### Before Any Deployment
- [ ] Code tested locally
- [ ] Environment variables configured
- [ ] Email sending tested
- [ ] Database migrations applied
- [ ] SSL certificates valid
- [ ] Firewall rules updated
- [ ] Backup taken
- [ ] Documentation updated

### After Deployment
- [ ] API health check passes
- [ ] Email OTP working
- [ ] Mobile app can connect
- [ ] Frontend loads correctly
- [ ] Database queries working
- [ ] SSL certificate valid
- [ ] Monitoring alerts configured

## 🔐 Security Notes

### Critical Security Points
- **Never commit** SMTP passwords to git
- **JWT secrets** must be 256+ bits
- **HTTPS only** for all external communication
- **Firewall** properly configured
- **Database** not exposed externally
- **File uploads** size and type limited

### Current Credentials Location
- SMTP: Environment variables in docker-compose
- JWT: Environment variables 
- Database: Environment variables
- SSL: Let's Encrypt auto-renewal

## 📞 Support Information

### When Things Go Wrong
1. **Check this documentation first**
2. **Review troubleshooting guide**
3. **Check system logs**  
4. **Test individual components**
5. **Contact system admin** if needed

### External Support
- **Hostinger**: SMTP/email issues
- **Hetzner**: Server/infrastructure issues
- **Let's Encrypt**: SSL certificate issues

## 🔄 Regular Maintenance

### Daily
- Monitor error logs
- Check system resource usage
- Verify backup completion

### Weekly  
- Review security logs
- Update system packages
- Test backup restoration

### Monthly
- Review and update documentation
- Performance optimization
- Security audit

## 📈 Performance Monitoring

### Key Metrics to Watch
- **API Response Time**: < 500ms average
- **Database Query Time**: < 100ms average  
- **Email Delivery Rate**: > 95%
- **System Memory Usage**: < 80%
- **Disk Space**: < 85% full

### Monitoring Commands
```bash
# API performance
time curl https://api.nammaoorudelivary.in/api/actuator/health

# System resources  
htop
df -h
docker stats

# Application logs
docker-compose logs -f backend | grep -E "(ERROR|WARN)"
```

## 🎓 Learning Resources

### Technologies Used
- **Spring Boot**: Backend framework
- **Angular**: Frontend framework  
- **Flutter**: Mobile app framework
- **PostgreSQL**: Database
- **Docker**: Containerization
- **Nginx**: Web server/reverse proxy
- **Hostinger**: Email service provider

### Useful Commands Reference
```bash
# Git operations
git status
git log --oneline -5
git push origin main

# Docker operations  
docker-compose ps
docker-compose logs -f
docker-compose restart
docker-compose up --build -d

# Server operations
ssh root@65.21.4.236
systemctl status nginx
ufw status
```

---

## 💡 Final Words

This documentation exists because we learned the hard way that:

1. **Complex systems need documentation**
2. **Email issues are surprisingly complex**
3. **Production environments behave differently**
4. **Time spent documenting saves hours debugging**
5. **Future you will thank current you**

Keep this documentation updated. Your future self (and your team) will appreciate it when something breaks at 2 AM.

---

**Created**: January 2025  
**Last Updated**: After resolving email SMTP issues  
**Status**: ✅ All systems operational and documented  
**Next Review**: When new major features are added