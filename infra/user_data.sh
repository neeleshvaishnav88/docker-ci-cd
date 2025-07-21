#!/bin/bash

# User data script for EC2 instance
# This script runs when the instance first boots

set -e

# Update system packages
yum update -y

# Install essential packages
yum install -y \
    aws-cli \
    jq \
    htop \
    unzip \
    wget \
    curl \
    git

# Configure CloudWatch agent for logging
yum install -y amazon-cloudwatch-agent

# Create CloudWatch agent configuration
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "/aws/ec2/${project_name}/system",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/secure",
            "log_group_name": "/aws/ec2/${project_name}/security",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          }
        ]
      }
    }
  }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -s \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# Enable CloudWatch agent to start on boot
systemctl enable amazon-cloudwatch-agent

# Security hardening
# Disable root login
passwd -l root

# Configure SSH security
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# Restart SSH service
systemctl restart sshd

# Configure firewall (if using firewalld)
if command -v firewall-cmd &> /dev/null; then
    systemctl enable firewalld
    systemctl start firewalld
    firewall-cmd --permanent --add-service=ssh
    firewall-cmd --permanent --add-service=http
    firewall-cmd --permanent --add-service=https
    firewall-cmd --reload
fi

# Create application user
useradd -m -s /bin/bash appuser
usermod -aG wheel appuser

# Set up basic monitoring
# Create a simple health check script
cat > /home/appuser/health_check.sh << 'EOF'
#!/bin/bash
echo "Instance is healthy"
echo "Timestamp: $(date)"
echo "Uptime: $(uptime)"
echo "Memory usage: $(free -h)"
echo "Disk usage: $(df -h /)"
EOF

chmod +x /home/appuser/health_check.sh
chown appuser:appuser /home/appuser/health_check.sh

# Create a simple web server for health checks
cat > /home/appuser/simple_server.py << 'EOF'
#!/usr/bin/env python3
import http.server
import socketserver
import os
import subprocess
import json
from datetime import datetime

PORT = 8080

class HealthCheckHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            
            # Get system information
            uptime = subprocess.check_output(['uptime']).decode().strip()
            memory = subprocess.check_output(['free', '-h']).decode().strip()
            disk = subprocess.check_output(['df', '-h', '/']).decode().strip()
            
            health_data = {
                'status': 'healthy',
                'timestamp': datetime.now().isoformat(),
                'uptime': uptime,
                'memory': memory,
                'disk': disk
            }
            
            self.wfile.write(json.dumps(health_data, indent=2).encode())
        else:
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            
            html = f"""
            <html>
            <head><title>Sample EC2 Instance</title></head>
            <body>
                <h1>Sample EC2 Instance</h1>
                <p>Environment: {os.environ.get('ENVIRONMENT', 'dev')}</p>
                <p>Project: {os.environ.get('PROJECT_NAME', 'sample-ec2')}</p>
                <p>Instance is running successfully!</p>
                <p><a href="/health">Health Check</a></p>
            </body>
            </html>
            """
            self.wfile.write(html.encode())

if __name__ == '__main__':
    with socketserver.TCPServer(("", PORT), HealthCheckHandler) as httpd:
        print(f"Server running on port {PORT}")
        httpd.serve_forever()
EOF

chmod +x /home/appuser/simple_server.py
chown appuser:appuser /home/appuser/simple_server.py

# Create systemd service for the web server
cat > /etc/systemd/system/sample-app.service << EOF
[Unit]
Description=Sample EC2 Application
After=network.target

[Service]
Type=simple
User=appuser
WorkingDirectory=/home/appuser
Environment=ENVIRONMENT=${environment}
Environment=PROJECT_NAME=${project_name}
ExecStart=/usr/bin/python3 /home/appuser/simple_server.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl enable sample-app
systemctl start sample-app

# Set environment variables
echo "export ENVIRONMENT=${environment}" >> /home/appuser/.bashrc
echo "export PROJECT_NAME=${project_name}" >> /home/appuser/.bashrc

# Create a welcome message
cat > /home/appuser/welcome.txt << EOF
Welcome to the Sample EC2 Instance!

Environment: ${environment}
Project: ${project_name}
Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)

This instance has been configured with:
- Security hardening (SSH key-only access, root disabled)
- CloudWatch logging
- Basic monitoring
- Simple web server on port 8080
- Health check endpoint at http://localhost:8080/health

To check the application status:
  sudo systemctl status sample-app

To view logs:
  sudo journalctl -u sample-app -f

To access the web interface:
  curl http://localhost:8080

To check health:
  curl http://localhost:8080/health
EOF

chown appuser:appuser /home/appuser/welcome.txt

echo "User data script completed successfully!" 