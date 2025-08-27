# AWS Projects - Multi-Tenant Full Stack DevOps Solution

A professional multi-tenant DevOps solution featuring independent full-stack applications deployed on AWS with Docker, Django Ninja, React, and advanced Nginx reverse proxy architecture.

## 🏗️ Architecture Overview

This project implements a **multi-tenant architecture** where multiple independent applications share the same infrastructure while maintaining complete isolation. Each project has its own backend (Django Ninja), frontend (React), and internal nginx configuration, all orchestrated through a main nginx reverse proxy.

### Live Projects:
- **HelloProject** - Production: `https://maialejandra.com`
- **Future Projects** - Easily add new projects with independent domains

### Key Features:
- ✅ **Multi-tenant architecture** with complete project isolation
- ✅ **SSL/HTTPS support** with automatic certificate management
- ✅ **Environment-specific configurations** (development/production)
- ✅ **Docker network isolation** between projects
- ✅ **Nginx reverse proxy** with intelligent routing
- ✅ **Django Ninja API** with CORS and security configurations
- ✅ **React SPA** with proxy configuration for development
- ✅ **AWS deployment** with CloudFormation Infrastructure as Code

## 🚀 Tech Stack

### Backend
- **Django Ninja** - Fast API framework for Django
- **Gunicorn** - WSGI HTTP Server
- **SQLite** - Database (can be easily changed to PostgreSQL)

### Frontend
- **React 18** - Modern React with hooks
- **Axios** - HTTP client for API calls
- **Modern CSS** - Responsive design with gradients

### Infrastructure
- **Docker & Docker Compose** - Containerization
- **Nginx** - Reverse proxy and load balancer
- **AWS CloudFormation** - Infrastructure as Code
- **EC2** - Compute instances
- **VPC & Security Groups** - Networking

## 📁 Project Structure

```
AWSProjects/
├── infrastructure/
│   ├── cloudformation-template.yaml    # AWS Infrastructure as Code
│   └── deploy.sh                      # Deployment automation script
├── HelloProject/                      # Complete isolated project
│   ├── backend/                       # Django Ninja API
│   │   ├── core/
│   │   │   ├── settings/
│   │   │   │   ├── base.py           # Base Django settings
│   │   │   │   ├── development.py    # Development configuration
│   │   │   │   └── production.py     # Production configuration
│   │   │   ├── urls.py               # Main URL routing
│   │   │   └── wsgi.py               # WSGI application
│   │   ├── api/
│   │   │   ├── views.py              # Django Ninja API endpoints
│   │   │   └── models.py             # Database models
│   │   ├── requirements.txt          # Python dependencies
│   │   ├── Dockerfile                # Backend container config
│   │   ├── init.sh                   # Initialization script
│   │   └── .env                      # Environment variables
│   ├── frontend/                     # React SPA
│   │   ├── src/
│   │   │   ├── App.js                # Main React component
│   │   │   ├── App.css               # Styling
│   │   │   └── index.js              # React entry point
│   │   ├── public/
│   │   ├── package.json              # Node.js dependencies & proxy config
│   │   └── Dockerfile                # Frontend container config
│   └── nginx/                        # Project-specific nginx
│       ├── nginx.conf                # Internal nginx configuration
│       └── conf.d/
│           └── default.conf          # Internal routing rules
├── nginx/                            # Main reverse proxy
│   ├── nginx.conf                    # Main nginx configuration
│   └── conf.d/
│       ├── default.conf              # Main routing & SSL config
│       ├── default-ssl.template      # SSL configuration template
│       └── default-certbot.template  # Certbot configuration template
├── scripts/
│   ├── switch-nginx-config.sh        # SSL/Certbot configuration switcher
│   ├── dev.sh                        # Development environment
│   └── prod.sh                       # Production environment
├── certbot/                          # SSL certificate management
│   └── www/                          # Certbot challenge directory
├── docker-compose.yml                # Main orchestration
└── README.md                         # This documentation
```

## 🛠️ Local Development

### Prerequisites
- Docker & Docker Compose
- Node.js 18+ (for local development)
- Python 3.11+ (for local development)

### Quick Start

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd AWSProjects
   ```

2. **Run complete multi-tenant environment**
   ```bash
   docker-compose up --build
   ```

3. **Access applications**
   - HelloProject: http://localhost (main domain)
   - Direct access via IP: http://localhost (default server)

### Development Workflow

#### Full Stack Development
```bash
# Start all services
docker-compose up --build

# View logs
docker-compose logs -f

# Restart specific service
docker-compose restart helloproject-backend

# Stop all services
docker-compose down
```

#### Individual Project Development
```bash
# HelloProject only
cd HelloProject
docker-compose up --build

# Access at http://localhost:3000 (frontend) and http://localhost:8000 (backend)
```

### Environment Configuration

#### Backend Configuration
The backend uses Django's settings modules:
- **Development**: `core.settings.development` (SQLite, DEBUG=True)
- **Production**: `core.settings.production` (PostgreSQL, DEBUG=False)

Set via environment variable:
```bash
DJANGO_SETTINGS_MODULE=core.settings.development  # or production
```

#### Frontend Configuration
React development server with proxy configuration in `package.json`:
```json
{
  "proxy": "http://helloproject-backend:8000"
}
```

## ☁️ AWS Deployment

### Prerequisites
- AWS CLI configured
- EC2 Key Pair created
- Domain names pointing to your AWS instance

### Deployment Steps

1. **Update deployment script**
   ```bash
   # Edit infrastructure/deploy.sh
   # Change KEY_PAIR_NAME to your actual key pair name
   ```

2. **Deploy infrastructure**
   ```bash
   cd infrastructure
   chmod +x deploy.sh
   ./deploy.sh
   ```

3. **Configure DNS**
   - Point `maialejandra.com` to your EC2 public IP
   - Point `embyter.com` to your EC2 public IP

### CloudFormation Stack

The CloudFormation template creates:
- VPC with public subnet
- EC2 Spot Instance Request (t3.medium by default) - **Up to 90% cost savings**
- Security groups for HTTP, HTTPS, SSH
- IAM roles with necessary permissions
- Elastic IP for consistent addressing
- Lambda function for automatic EIP association
- CloudWatch monitoring and logging

## 🔧 Advanced Configuration

### Multi-Tenant Nginx Architecture

#### Main Nginx Reverse Proxy
The main nginx acts as a reverse proxy and SSL terminator:

```nginx
# Routes traffic to project-specific nginx containers
upstream helloproject {
    server helloproject-nginx:80;
}

server {
    listen 443 ssl http2;
    server_name maialejandra.com www.maialejandra.com;
    
    location / {
        proxy_pass http://helloproject;
        proxy_set_header X-Forwarded-Proto https;
    }
}
```

#### Project-Specific Nginx
Each project has its own nginx for internal routing:

```nginx
server {
    listen 80;
    
    # Frontend (React SPA)
    location / {
        proxy_pass http://helloproject-frontend:3000;
    }
    
    # Backend API
    location /api/ {
        proxy_pass http://helloproject-backend:8000;
    }
}
```

### SSL/HTTPS Configuration

#### Automatic SSL Configuration Switching
Use the provided script to switch between SSL and Certbot configurations:

```bash
# Switch to SSL configuration (production)
./scripts/switch-nginx-config.sh ssl

# Switch to Certbot configuration (certificate generation)
./scripts/switch-nginx-config.sh certbot
```

#### SSL Certificate Generation
```bash
# Generate certificates using Certbot
docker-compose run --rm certbot certonly --webroot \
  --webroot-path=/var/www/certbot \
  -d maialejandra.com -d www.maialejandra.com

# Switch to SSL configuration
./scripts/switch-nginx-config.sh ssl
```

### Django Configuration Architecture

#### Settings Structure
```python
# base.py - Common settings
INSTALLED_APPS = [...]
MIDDLEWARE = [...]

# development.py - Development overrides
DEBUG = True
ALLOWED_HOSTS = ['*']
DATABASES = {'default': {'ENGINE': 'django.db.backends.sqlite3'}}

# production.py - Production overrides
DEBUG = False
ALLOWED_HOSTS = ['maialejandra.com', 'helloproject-backend', 'localhost']
SECURE_SSL_REDIRECT = False  # Let nginx handle SSL termination
```

#### CORS Configuration
```python
# Allow frontend communication
CORS_ALLOWED_ORIGINS = [
    "https://maialejandra.com",
    "http://helloproject-frontend:3000",
    "http://localhost:3000",
]
```

### Docker Network Architecture

#### Network Isolation
```yaml
networks:
  helloproject-network:    # Internal project communication
    driver: bridge
  main-network:           # External communication
    driver: bridge

services:
  helloproject-backend:
    networks:
      - helloproject-network  # Internal APIs
      - main-network         # Database access
  
  helloproject-frontend:
    networks:
      - helloproject-network  # Internal only
```

### Environment Variables

#### Production Environment (.env)
```bash
# Django Configuration
DJANGO_SETTINGS_MODULE=core.settings.production
SECRET_KEY=your-secret-key-here
DEBUG=False

# Database Configuration (if using PostgreSQL)
DB_NAME=your_db_name
DB_USER=your_db_user
DB_PASSWORD=your_db_password
DB_HOST=your_db_host
DB_PORT=5432
```

#### Development Environment
```bash
DJANGO_SETTINGS_MODULE=core.settings.development
DEBUG=True
```

## 📊 Monitoring & Health Checks

### CloudWatch Monitoring

The infrastructure includes comprehensive CloudWatch monitoring:

- **System Metrics:** CPU, Memory, Disk usage
- **Application Logs:** Nginx access and error logs
- **Custom Metrics:** Application health checks
- **Alarms:** Automatic notifications for issues

### Health Check Endpoints
- HelloProject: `http://your-domain/api/health`
- WorldProyect: `http://your-domain:8001/api/health`

### CloudWatch Dashboard

Access your CloudWatch dashboard to monitor:
- Instance performance metrics
- Application logs in real-time
- Cost optimization insights
- Spot instance interruption history

### Spot Instance Monitoring

Use the monitoring script to track your Spot instance:

```bash
./scripts/monitor-spot.sh
```

This script provides:
- Real-time Spot Instance Request status
- Active instance information
- Spot price history
- CloudWatch metrics
- Cost estimation

### Logs
```bash
# View all logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f helloproject-backend
docker-compose logs -f worldproyect-frontend
```

## 🔒 Security

### Production Checklist
- [ ] Change Django secret keys
- [ ] Configure HTTPS with SSL certificates
- [ ] Set up proper firewall rules
- [ ] Use environment variables for sensitive data
- [ ] Regular security updates
- [ ] Database backups

### SSL Configuration
```bash
# Install certbot on EC2 instance
sudo yum install -y certbot python3-certbot-nginx

# Get SSL certificates
sudo certbot --nginx -d maialejandra.com -d www.maialejandra.com
sudo certbot --nginx -d embyter.com -d www.embyter.com
```

## 🚀 Scaling

### Horizontal Scaling
- Add more EC2 instances behind a load balancer
- Use AWS Auto Scaling Groups
- Implement database clustering

### Vertical Scaling
- Increase EC2 instance size
- Add more CPU/memory resources
- Optimize application performance

## 🏛️ Architecture Deep Dive

### Request Flow Architecture

```
Internet → AWS Load Balancer → EC2 Instance → Main Nginx → Project Nginx → Backend/Frontend
```

#### Detailed Flow:
1. **Client Request**: `https://maialejandra.com/api/`
2. **Main Nginx**: Receives request, terminates SSL, routes to `helloproject-nginx:80`
3. **Project Nginx**: Routes `/api/` to `helloproject-backend:8000`
4. **Django Backend**: Processes API request, returns JSON response
5. **Response Path**: Backend → Project Nginx → Main Nginx → Client

### Multi-Tenant Benefits

#### Project Isolation
- **Network Isolation**: Each project has its own Docker network
- **Configuration Isolation**: Independent nginx and environment configs
- **Resource Isolation**: Separate containers for each service
- **Deployment Isolation**: Projects can be deployed independently

#### Scalability
- **Horizontal Scaling**: Add more project containers behind load balancer
- **Vertical Scaling**: Increase resources per container
- **Independent Scaling**: Scale projects based on individual demand

#### Maintenance
- **Zero Downtime**: Update projects without affecting others
- **Independent Releases**: Deploy new features per project
- **Rollback Capability**: Rollback individual projects if needed

### Security Architecture

#### Network Security
```yaml
# Network isolation prevents cross-project communication
networks:
  helloproject-network:  # Isolated project network
  main-network:         # Shared infrastructure network
```

#### SSL/TLS Security
- **SSL Termination**: Main nginx handles all SSL/TLS
- **Internal HTTP**: Project communication uses HTTP internally
- **Certificate Management**: Automated with Certbot
- **Security Headers**: Configured in main nginx

#### Django Security
```python
# Production security settings
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = 'DENY'
SECURE_HSTS_SECONDS = 31536000
```

## 📝 API Documentation

### HelloProject API
- **Base URL**: `https://maialejandra.com/api/`
- **Authentication**: None (public endpoints)
- **Content-Type**: `application/json`

#### Endpoints:

##### GET `/api/`
Returns a hello world message from the backend.

**Response**:
```json
{
  "message": "Hello World! It Works!",
  "project": "HelloProject"
}
```

##### GET `/api/health`
Health check endpoint for monitoring.

**Response**:
```json
{
  "status": "healthy",
  "service": "HelloProject API"
}
```

### Adding New Projects

#### 1. Create Project Structure
```bash
mkdir NewProject
cd NewProject
mkdir -p backend frontend nginx/conf.d
```

#### 2. Copy Templates
```bash
# Copy from HelloProject as template
cp -r ../HelloProject/backend ./
cp -r ../HelloProject/frontend ./
cp -r ../HelloProject/nginx ./
```

#### 3. Update Configuration
- Update `docker-compose.yml` with new service names
- Configure domain routing in main nginx
- Update environment variables
- Modify API endpoints and frontend branding

#### 4. Add to Main Orchestration
```yaml
# Add to main docker-compose.yml
services:
  newproject-backend:
    build: ./NewProject/backend
    networks:
      - newproject-network
      - main-network
```

## 🐛 Troubleshooting

### Common Issues & Solutions

#### 1. API Connection Errors ("Error connecting to API")

**Symptoms**: Frontend shows "Error connecting to API"

**Diagnosis**:
```bash
# Check if backend is responding
docker exec helloproject-backend curl -I http://127.0.0.1:8000/api/

# Check nginx to backend communication
docker exec helloproject-nginx curl -I http://helloproject-backend:8000/api/

# Check main nginx to project nginx
docker exec main-nginx curl -I http://helloproject-nginx:80/api/
```

**Solutions**:
- Verify `ALLOWED_HOSTS` in Django production settings includes container names
- Ensure `SECURE_SSL_REDIRECT = False` for internal communication
- Check CORS configuration allows frontend domain

#### 2. SSL/HTTPS Issues

**Symptoms**: SSL certificate errors, mixed content warnings

**Solutions**:
```bash
# Switch to certbot configuration
./scripts/switch-nginx-config.sh certbot

# Generate certificates
docker-compose run --rm certbot certonly --webroot \
  --webroot-path=/var/www/certbot -d your-domain.com

# Switch to SSL configuration
./scripts/switch-nginx-config.sh ssl
```

#### 3. Docker Network Issues

**Symptoms**: Containers can't communicate with each other

**Diagnosis**:
```bash
# Check container networks
docker network ls
docker inspect helloproject-network

# Test container connectivity
docker exec helloproject-frontend ping helloproject-backend
```

**Solutions**:
- Ensure containers are in the correct networks
- Restart docker-compose to recreate networks
- Check firewall rules on host system

#### 4. Port Conflicts

**Symptoms**: "Port already in use" errors

**Solutions**:
```bash
# Check what's using ports
sudo netstat -tulpn | grep :80
sudo netstat -tulpn | grep :443

# Stop conflicting services
sudo systemctl stop apache2  # if Apache is running
sudo systemctl stop nginx    # if system nginx is running
```

#### 5. Django Configuration Issues

**Symptoms**: 400 Bad Request, CORS errors

**Solutions**:
```bash
# Check Django logs
docker logs helloproject-backend --tail 50

# Verify settings module
docker exec helloproject-backend python -c "
import os
print('Settings:', os.getenv('DJANGO_SETTINGS_MODULE'))
from django.conf import settings
print('Debug:', settings.DEBUG)
print('Allowed Hosts:', settings.ALLOWED_HOSTS)
"

# Run migrations
docker exec helloproject-backend python manage.py migrate
```

#### 6. Frontend Build Issues

**Symptoms**: Frontend not loading, build failures

**Solutions**:
```bash
# Check frontend logs
docker logs helloproject-frontend --tail 50

# Rebuild frontend
docker-compose build --no-cache helloproject-frontend

# Check proxy configuration
docker exec helloproject-frontend cat package.json | grep proxy
```

### Debugging Commands

#### Container Status
```bash
# Check all containers
docker-compose ps

# Check specific container health
docker inspect helloproject-backend --format='{{.State.Health.Status}}'
```

#### Network Debugging
```bash
# List networks
docker network ls

# Inspect network
docker network inspect helloproject-network

# Test connectivity between containers
docker exec helloproject-frontend ping helloproject-backend
```

#### Log Analysis
```bash
# All logs
docker-compose logs -f

# Specific service logs
docker-compose logs -f helloproject-backend
docker-compose logs -f main-nginx

# Nginx access logs
docker exec main-nginx tail -f /var/log/nginx/access.log
```

#### Configuration Testing
```bash
# Test nginx configuration
docker exec main-nginx nginx -t
docker exec helloproject-nginx nginx -t

# Test Django configuration
docker exec helloproject-backend python manage.py check
```

## 🚀 Production Deployment Checklist

### Pre-Deployment
- [ ] Update Django `SECRET_KEY` in production
- [ ] Configure production database (PostgreSQL recommended)
- [ ] Set up domain DNS records
- [ ] Configure AWS credentials and key pairs
- [ ] Review security group settings

### SSL/HTTPS Setup
- [ ] Switch to certbot configuration: `./scripts/switch-nginx-config.sh certbot`
- [ ] Generate SSL certificates with Certbot
- [ ] Switch to SSL configuration: `./scripts/switch-nginx-config.sh ssl`
- [ ] Test HTTPS functionality
- [ ] Set up certificate auto-renewal

### Post-Deployment
- [ ] Verify all services are running: `docker-compose ps`
- [ ] Test API endpoints: `curl https://your-domain.com/api/`
- [ ] Check frontend functionality in browser
- [ ] Monitor logs for errors: `docker-compose logs -f`
- [ ] Set up monitoring and alerting

## 🎯 Key Achievements

This project successfully implements:

✅ **Multi-Tenant Architecture**: Complete project isolation with shared infrastructure  
✅ **Production-Ready Security**: SSL/HTTPS, CORS, Django security best practices  
✅ **Scalable Infrastructure**: Docker orchestration with nginx reverse proxy  
✅ **Environment Flexibility**: Easy switching between development and production  
✅ **AWS Integration**: CloudFormation Infrastructure as Code  
✅ **Modern Tech Stack**: Django Ninja + React + Docker + Nginx  
✅ **Automated SSL**: Certbot integration with configuration switching  
✅ **Network Isolation**: Docker networks for security and organization  
✅ **Monitoring Ready**: Health checks and logging infrastructure  
✅ **Developer Experience**: Easy local development and debugging tools  

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test thoroughly in both development and production modes
5. Update documentation if needed
6. Submit a pull request

### Development Guidelines
- Follow Django and React best practices
- Test nginx configuration changes with `nginx -t`
- Ensure Docker builds are optimized
- Document any new environment variables
- Test SSL configuration switching

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support & Community

### Getting Help
- **Documentation**: Start with this README and troubleshooting section
- **Issues**: Create detailed GitHub issues with logs and configuration
- **Discussions**: Use GitHub Discussions for questions and ideas

### Useful Resources
- [Django Ninja Documentation](https://django-ninja.rest-framework.com/)
- [React Documentation](https://reactjs.org/docs/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Nginx Configuration Guide](https://nginx.org/en/docs/)
- [AWS CloudFormation Documentation](https://docs.aws.amazon.com/cloudformation/)

---

## 🎉 Success!

**Congratulations!** You now have a production-ready, multi-tenant, full-stack application deployed on AWS with:

- **Secure HTTPS** communication
- **Scalable architecture** ready for multiple projects
- **Professional DevOps** practices
- **Modern development** workflow
- **Cost-effective** AWS deployment

**Happy Coding! 🚀**

---

*Built with ❤️ using Django Ninja, React, Docker, and AWS*
