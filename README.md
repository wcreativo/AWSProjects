# AWS Projects - Full Stack DevOps Solution

A professional DevOps solution featuring two full-stack applications deployed on AWS with Docker, Django Ninja, React, and Nginx.

## 🏗️ Architecture Overview

This project consists of two independent applications, each with its own backend (Django Ninja) and frontend (React), orchestrated with Docker Compose and deployed on AWS using CloudFormation.

### Projects:
- **HelloProject** - Domain: `maialejandra.com`
- **WorldProyect** - Domain: `embyter.com`

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
│   ├── cloudformation-template.yaml
│   └── deploy.sh
├── HelloProject/
│   ├── backend/
│   │   ├── core/
│   │   ├── api/
│   │   ├── requirements.txt
│   │   └── Dockerfile
│   ├── frontend/
│   │   ├── src/
│   │   ├── public/
│   │   ├── package.json
│   │   └── Dockerfile
│   ├── nginx/
│   │   ├── nginx.conf
│   │   └── conf.d/
│   └── docker-compose.yml
├── WorldProyect/
│   ├── backend/
│   ├── frontend/
│   ├── nginx/
│   └── docker-compose.yml
├── nginx/
│   ├── nginx.conf
│   └── conf.d/
├── scripts/
│   ├── dev.sh
│   └── prod.sh
├── docker-compose.yml
└── README.md
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

2. **Run development environment**
   ```bash
   chmod +x scripts/dev.sh
   ./scripts/dev.sh
   ```

3. **Access applications**
   - HelloProject: http://localhost
   - WorldProyect: http://localhost:8001

### Individual Project Development

#### HelloProject
```bash
cd HelloProject
docker-compose up --build
```

#### WorldProyect
```bash
cd WorldProyect
docker-compose up --build
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

## 🔧 Configuration

### EC2 Spot Instance Request

This project uses **EC2 Spot Instance Request** to reduce costs by up to 90% compared to On-Demand instances:

- **Instance Type:** t3.medium (configurable)
- **Spot Price:** $0.0416/hour maximum bid (adjustable)
- **Request Type:** one-time (single instance)
- **Termination Policy:** Instance terminates when Spot price exceeds bid
- **Auto-Recovery:** Lambda function automatically reassociates EIP when new instance starts

#### Spot Instance Benefits:
- ✅ **Cost Savings:** Up to 90% cheaper than On-Demand
- ✅ **High Availability:** Automatic failover with Lambda
- ✅ **Flexibility:** Easy to modify bid prices
- ✅ **Monitoring:** CloudWatch integration for tracking

#### Spot Instance Considerations:
- ⚠️ **Interruption Risk:** Instances can be terminated with 2-minute notice
- ⚠️ **Price Fluctuations:** Bid prices may need adjustment
- ⚠️ **Availability:** May not be available in all AZs

### Environment Variables

#### Backend (Django)
- `DEBUG` - Set to `False` in production
- `SECRET_KEY` - Change in production

#### Frontend (React)
- API proxy configuration in `package.json`
- Environment-specific builds

### Nginx Configuration

#### Main Nginx (Port 80)
- Routes traffic based on domain names
- SSL termination (when configured)
- Load balancing

#### Project-specific Nginx
- Handles internal routing
- API proxying
- Static file serving

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

## 📝 API Documentation

### HelloProject API
- Base URL: `http://maialejandra.com/api/`
- Endpoints:
  - `GET /` - Hello World message
  - `GET /health` - Health check

### WorldProyect API
- Base URL: `http://embyter.com/api/`
- Endpoints:
  - `GET /` - Hello World message
  - `GET /health` - Health check

## 🐛 Troubleshooting

### Common Issues

1. **Port conflicts**
   ```bash
   # Check what's using port 80
   sudo netstat -tulpn | grep :80
   ```

2. **Docker build failures**
   ```bash
   # Clean Docker cache
   docker system prune -a
   ```

3. **Nginx configuration errors**
   ```bash
   # Test nginx configuration
   docker exec main-nginx nginx -t
   ```

4. **Database connection issues**
   ```bash
   # Check Django migrations
   docker exec helloproject-backend python manage.py migrate
   ```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:
- Create an issue in the repository
- Check the troubleshooting section
- Review the logs for error messages

---

**Happy Coding! 🚀**
