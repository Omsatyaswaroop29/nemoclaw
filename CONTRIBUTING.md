# Contributing to NemoClaw

Thank you for your interest in contributing to NemoClaw! This document provides guidelines and information for contributors.

## How Can I Contribute?

### Reporting Bugs

If you find a bug, please open an issue on GitHub with the following information:

- A clear, descriptive title
- Steps to reproduce the issue
- Expected behavior vs. actual behavior
- Your environment details (OS, instance type, versions)
- Relevant log output

### Suggesting Enhancements

Enhancement suggestions are welcome! Open an issue describing the problem you're trying to solve, your proposed solution, and whether you're willing to implement it yourself.

### Areas Where Help Is Needed

These areas would benefit from community contributions:

**Docker Containerization:** Create a Docker image that packages NemoClaw for easier deployment without needing to compile llama.cpp.

**Infrastructure as Code:** Terraform or CloudFormation templates that automate the entire AWS infrastructure setup.

**Multi-Cloud Support:** Deployment guides and scripts for Google Cloud Platform and Microsoft Azure.

**Monitoring and Observability:** Grafana dashboards, CloudWatch configurations, or Prometheus metrics for monitoring NemoClaw health and performance.

**Documentation:** Improvements to existing documentation, translations, or new guides for specific use cases.

## Development Setup

To contribute code, you'll need an AWS account for testing deployments, Git for version control, and a code editor of your choice.

Fork the repository and clone it locally:

```bash
git clone https://github.com/YOUR_USERNAME/nemoclaw.git
cd nemoclaw
```

Create a branch for your changes:

```bash
git checkout -b feature/your-feature-name
```

## Submitting Changes

Before submitting changes to the installation script or documentation, launch a fresh EC2 g5.xlarge instance, run your modified installation script, verify NemoClaw starts correctly, test the API endpoint, and document any issues or changes in behavior.

Use clear, descriptive commit messages. Include in your PR description what problem this solves, how you tested it, and whether there are any breaking changes.

## Style Guidelines

For bash scripts, use shellcheck to validate scripts, include comments for complex logic, use meaningful variable names, always quote variables to prevent word splitting, and use `set -e` to exit on errors.

For documentation, use clear and concise language, include code examples where helpful, structure with headers for easy navigation, and test all commands before documenting them.

## Thank You!

Every contribution helps make NemoClaw better for everyone. Whether it's fixing a typo, improving documentation, or adding major features, your help is appreciated!
