# Contributing to NemoClaw 🦞

First off, thank you for considering contributing to NemoClaw! It's people like you that make the open-source community such a wonderful place to learn, inspire, and create.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Pull Request Process](#pull-request-process)
- [Style Guidelines](#style-guidelines)
- [Community](#community)

---

## Code of Conduct

This project and everyone participating in it is governed by our commitment to making participation in our community a harassment-free experience for everyone. We pledge to act and interact in ways that contribute to an open, welcoming, diverse, inclusive, and healthy community.

---

## How Can I Contribute?

### 🐛 Reporting Bugs

Found a bug? We'd love to know about it! Before creating a bug report, please check the existing issues to see if someone has already reported it.

When filing a bug report, please include as much detail as possible. This helps us understand the problem and fix it quickly.

**Great bug reports tend to include:**
- A quick summary and background
- Steps to reproduce (be specific!)
- What you expected would happen
- What actually happens
- Your environment (OS, instance type, versions)
- Relevant log output from `sudo journalctl -u nemoclaw -n 50`
- GPU info from `nvidia-smi`

### 💡 Suggesting Features

Have an idea for a new feature? We're all ears! Open an issue with the tag "enhancement" and describe your feature request. Tell us what problem it solves and how you envision it working.

### 📖 Improving Documentation

Documentation is incredibly important, and improvements are always welcome. This includes fixing typos, clarifying confusing sections, adding examples, or writing tutorials.

### 🔧 Contributing Code

Ready to contribute code? Awesome! Here are some areas where we'd especially appreciate help:

**High Priority:**
- Docker containerization for simplified deployment
- Terraform or CloudFormation templates for infrastructure-as-code
- Automated testing scripts

**Medium Priority:**
- GCP and Azure deployment guides
- Model switching functionality (use different models without reinstalling)
- Performance monitoring and alerting

**Nice to Have:**
- Web dashboard for server management
- Multi-GPU support for larger models
- Automatic cost tracking and AWS budget alerts

---

## Development Setup

### Prerequisites

To work on NemoClaw, you'll need access to an AWS account with GPU quota approved (g5 instances), basic knowledge of bash scripting for installer modifications, an understanding of systemd services, and familiarity with the llama.cpp project if modifying inference settings.

### Testing Changes

1. **Fork and clone the repository:**
   ```bash
   git clone https://github.com/YOUR_USERNAME/nemoclaw.git
   cd nemoclaw
   ```

2. **Create a branch for your changes:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Test on a fresh EC2 instance:**
   - Launch a new g5.xlarge with the Deep Learning AMI
   - Copy your modified scripts to the instance
   - Run through the full installation
   - Verify everything works

4. **Document any changes:**
   - Update relevant documentation
   - Add comments explaining complex logic
   - Update the CHANGELOG if adding features

---

## Pull Request Process

1. **Before starting work,** open an issue discussing what you'd like to change. This helps avoid duplicate effort and ensures your contribution aligns with the project's direction.

2. **Make your changes** on a feature branch, not directly on `main`.

3. **Test thoroughly.** For script changes, run on a fresh EC2 instance. For documentation, verify all links work and instructions are accurate.

4. **Update documentation** to reflect any changes to functionality.

5. **Submit your PR** with a clear description of what it does and why. Reference any related issues.

6. **Respond to feedback.** We may ask questions or request changes. This is a collaborative process!

---

## Style Guidelines

### Bash Scripts

For bash scripts, please follow these conventions. Include comments for any non-obvious logic. Use meaningful variable names (MODEL_DIR instead of MD). Include error handling with clear error messages. Use the color-coded output functions (print_step, print_success, print_error) for user feedback. Test scripts with `shellcheck` when possible.

Example:
```bash
# Good
print_step "Installing CUDA Toolkit..."
if ! sudo dnf install -y cuda-toolkit-12-4; then
    print_error "CUDA installation failed!"
    exit 1
fi
print_success "CUDA Toolkit installed"

# Avoid
dnf install cuda-toolkit-12-4
```

### Documentation

For documentation, use clear, simple language. Include examples for complex concepts. Use proper Markdown formatting. Test all commands before documenting them. Include expected output where helpful.

### Commit Messages

Write clear, meaningful commit messages. Use present tense ("Add feature" not "Added feature"). Keep the first line under 50 characters. Add detail in the body if needed.

Example:
```
Add Docker containerization

- Create Dockerfile with multi-stage build
- Add docker-compose.yml for easy deployment
- Update README with Docker instructions
```

---

## Community

### Getting Help

If you need help with your contribution, you can open a draft PR and ask questions in the description, start a discussion in the GitHub Discussions tab, or join the OpenClaw Discord server where many NemoClaw users hang out.

### Recognition

All contributors will be recognized in our README! We appreciate every contribution, no matter how small.

---

## Thank You! 🎉

Every contribution helps make NemoClaw better for everyone. Whether you're fixing a typo, adding a feature, or helping someone troubleshoot, you're making a difference.

The fact that you're reading this means you're already awesome. Let's build something great together! 🦞
