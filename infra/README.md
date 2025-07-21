# Sample EC2 Infrastructure with Terraform

This repository contains a secure, production-ready Terraform configuration for deploying EC2 instances on AWS with security best practices, least-privilege IAM policies, and automated security scanning.

## 🚀 Features

- **Secure EC2 Instance**: Amazon Linux 2 with security hardening
- **Least-Privilege IAM**: Minimal required permissions for EC2 instances
- **Security Scanning**: Automated tfsec and Checkov scans
- **VPC & Networking**: Isolated network with proper security groups
- **Monitoring**: CloudWatch logging and basic health checks
- **Encryption**: Encrypted EBS volumes and IMDSv2
- **Automation**: Makefile for common operations

## 📋 Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate credentials
- SSH key pair for EC2 access
- tfsec and Checkov (optional, will be installed automatically)

## 🛠️ Quick Start

### 1. Clone and Setup

```bash
# Clone the repository
git clone <repository-url>
cd infra

# Generate SSH key pair (if you don't have one)
make generate-keys
```

### 2. Configure Variables

```bash
# Copy the example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit the configuration with your values
nano terraform.tfvars
```

**Important Security Notes:**
- Update `allowed_ssh_ips` to your specific IP ranges
- Replace `ssh_public_key` with your actual public key
- Consider changing the default region and instance type

### 3. Deploy Infrastructure

```bash
# Initialize Terraform
make init

# Run security scans and plan
make plan

# Apply the configuration
make apply
```

### 4. Access Your Instance

```bash
# Get the instance details
make outputs

# SSH to the instance (replace with your private key path)
ssh -i id_rsa ec2-user@<instance-public-ip>

# Check the web application
curl http://<instance-public-ip>:8080
curl http://<instance-public-ip>:8080/health
```

## 🔒 Security Features

### IAM Least-Privilege Policies
- EC2 instances can only access specific CloudWatch log groups
- Limited S3 access to configuration bucket only
- No administrative permissions

### Network Security
- VPC with isolated subnets
- Security groups with minimal required ports
- SSH access restricted to specific IP ranges
- IMDSv2 required (metadata service security)

### Instance Security
- Root login disabled
- SSH key-only authentication
- Encrypted EBS volumes
- Security updates applied automatically
- Firewall configured

### Security Scanning
- **tfsec**: Static analysis for security misconfigurations
- **Checkov**: Policy-as-code security scanning
- Automated scanning in CI/CD pipeline

## 📁 Project Structure

```
.
├── main.tf                 # Main Terraform configuration
├── variables.tf            # Input variables
├── versions.tf             # Provider versions
├── user_data.sh           # EC2 instance initialization script
├── terraform.tfvars.example # Example configuration
├── .tfsec.yml             # tfsec configuration
├── checkov.yml            # Checkov configuration
├── Makefile               # Automation scripts
└── README.md              # This file
```

## 🛡️ Security Scanning

### Manual Scanning

```bash
# Run all security scans
make security-scan

# Run individual scans
make tfsec
make checkov

# Comprehensive security audit
make security-audit
```

### CI/CD Integration

Add to your CI/CD pipeline:

```yaml
# Example GitHub Actions step
- name: Security Scan
  run: |
    make security-scan
    # Fail if high/critical issues found
    if [ -s tfsec-results.json ] || [ -s checkov-results.json ]; then
      echo "Security issues found!"
      exit 1
    fi
```

## 🔧 Available Commands

```bash
make help              # Show all available commands
make init              # Initialize Terraform
make validate          # Validate configuration
make format            # Format Terraform files
make plan              # Plan changes with security scan
make apply             # Apply changes
make destroy           # Destroy infrastructure
make security-scan     # Run security scans
make security-audit    # Comprehensive security audit
make clean             # Clean temporary files
make outputs           # Show Terraform outputs
make resources         # List managed resources
```

## 📊 Monitoring

### CloudWatch Logs
- System logs: `/aws/ec2/sample-ec2/system`
- Security logs: `/aws/ec2/sample-ec2/security`

### Health Checks
- Web endpoint: `http://<instance-ip>:8080/health`
- Returns JSON with system status

### Application Logs
```bash
# View application logs
sudo journalctl -u sample-app -f

# Check application status
sudo systemctl status sample-app
```

## 🔄 Updates and Maintenance

### Updating the Infrastructure

```bash
# Make changes to Terraform files
# Then run:
make plan
make apply
```

### Security Updates

```bash
# Run security scans
make security-scan

# Review and fix any issues
# Re-apply if needed
make plan
make apply
```

## 🚨 Security Best Practices

1. **Never commit secrets**: Use environment variables or AWS Secrets Manager
2. **Restrict SSH access**: Update `allowed_ssh_ips` to your specific ranges
3. **Regular updates**: Keep Terraform and providers updated
4. **Monitor logs**: Check CloudWatch logs regularly
5. **Security scans**: Run scans before every deployment
6. **Backup state**: Store Terraform state securely
7. **Use tags**: All resources are properly tagged for cost tracking

## 🆘 Troubleshooting

### Common Issues

1. **SSH Connection Failed**
   - Verify security group allows your IP
   - Check SSH key configuration
   - Ensure instance is running

2. **Security Scan Failures**
   - Review scan results in JSON files
   - Fix issues or add exclusions in config files
   - Update Terraform configuration

3. **Terraform Errors**
   - Run `terraform validate`
   - Check AWS credentials
   - Verify region and resource limits

### Getting Help

- Check CloudWatch logs for application issues
- Review Terraform state: `terraform state list`
- Run security audit: `make security-audit`

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run security scans: `make security-scan`
5. Submit a pull request

## ⚠️ Disclaimer

This is a sample configuration for educational purposes. Always review and customize security settings for your specific requirements before using in production. 