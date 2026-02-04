# AWS Setup Guide for NemoClaw

This guide provides comprehensive, step-by-step instructions for setting up the AWS infrastructure required to run NemoClaw. By the end of this guide, you'll have a fully configured EC2 instance ready for the NemoClaw installation.

---

## Prerequisites

Before you begin, make sure you have an active AWS account with billing enabled and payment method configured, administrative access to create EC2 instances, security groups, and key pairs, and terminal access on your local machine (macOS Terminal, Linux shell, or Windows PowerShell).

Estimated Setup Time: 15-20 minutes (plus potential wait time for GPU quota approval)

---

## Step 1: Request GPU Quota

AWS accounts have a default quota of 0 for GPU instances, which means you cannot launch them until you request an increase. This is a one-time process per region.

Open the AWS Console and sign in. In the search bar at the top, type "Service Quotas" and click on the Service Quotas service. On the Service Quotas dashboard, click on AWS services in the left sidebar, then search for and select Amazon Elastic Compute Cloud (Amazon EC2).

In the search box that appears, type "Running On-Demand G" to filter the quotas. Click on Running On-Demand G and VT instances. Click the Request increase at account-level button and enter the new quota value as 4 (the g5.xlarge instance requires 4 vCPUs of GPU quota). Optionally add a reason like "Running AI inference workloads with self-hosted language models for development purposes."

Click Request to submit. AWS typically approves GPU quota requests within 15-30 minutes for established accounts. New accounts may take up to 24 hours. You'll receive an email notification when the request is approved.

---

## Step 2: Create a Key Pair

A key pair allows you to securely SSH into your EC2 instance without a password.

In the AWS Console, navigate to EC2 (search for it in the top bar). In the left sidebar, under Network & Security, click on Key Pairs. Click the Create key pair button at the top right and configure the following settings: Name as "nemoclaw-key", Key pair type as RSA, and Private key file format as .pem for macOS or Linux (or .ppk if you're on Windows using PuTTY).

Click Create key pair and your browser will automatically download the private key file.

This step is critical for security. The key file must have restricted permissions. On macOS or Linux, open Terminal and run these commands:

```bash
mv ~/Downloads/nemoclaw-key.pem ~/.ssh/
chmod 400 ~/.ssh/nemoclaw-key.pem
ls -la ~/.ssh/nemoclaw-key.pem
```

The output should show `-r--------` indicating the file is readable only by you. Never share your private key file. If it's compromised, anyone could access your EC2 instance.

---

## Step 3: Create a Security Group

A security group acts as a virtual firewall for your instance. We'll create one that allows only the necessary traffic.

In the EC2 dashboard, scroll down in the left sidebar to Network & Security and click on Security Groups. Click Create security group at the top right.

For the basic details, enter "nemoclaw-sg" as the Security group name, "Security group for NemoClaw inference server" as the Description, and select your default VPC.

Under Inbound rules, click Add rule twice to add two inbound rules. For the first rule (SSH Access), set Type to SSH, which will auto-fill Protocol as TCP and Port range as 22. Set Source to "My IP" and Description to "SSH access for management".

For the second rule (NemoClaw API), set Type to Custom TCP, Protocol to TCP, Port range to 8001, Source to "My IP", and Description to "NemoClaw API endpoint".

Leave the default outbound rule that allows all outbound traffic, as this is necessary for the instance to download software and the model. Click Create security group at the bottom of the page.

---

## Step 4: Launch the EC2 Instance

Now we'll launch the actual virtual machine that will run NemoClaw.

In the EC2 dashboard, click Instances in the left sidebar, then click the Launch instances button at the top right.

Under Name and tags, enter "nemoclaw-server".

Under Application and OS Images (Amazon Machine Image), click Browse more AMIs. In the search box, type "Deep Learning OSS Nvidia Driver AMI GPU PyTorch" and look for the AMI titled "Deep Learning OSS Nvidia Driver AMI GPU PyTorch 2.9 (Amazon Linux 2023)" or similar. The key elements to verify are that it's based on Amazon Linux 2023 and has NVIDIA drivers pre-installed. Click Select next to the appropriate AMI.

Under Instance type, search for and select "g5.xlarge". You'll see the specifications listed as 4 vCPUs and 16 GiB memory. The GPU (A10G with 24GB) isn't shown here but is included with all g5 instances. If g5.xlarge is grayed out with a message about quotas, your quota request from Step 1 hasn't been approved yet. Wait for the approval email and try again.

Under Key pair (login), select "nemoclaw-key" that you created earlier.

Click Edit next to Network settings. Set Auto-assign public IP to Enable. Under Firewall (security groups), select "Select existing security group" and choose "nemoclaw-sg" from the dropdown.

Under Configure storage, change the root volume to 100 GiB and Volume type to gp3. The 100GB provides ample space for the 21GB model file plus operating system, llama.cpp, logs, and any future needs.

Review your configuration in the Summary panel on the right side, then click Launch instance. Wait until the Instance state shows Running with a green circle (usually takes 1-2 minutes). Note the Public IPv4 address in the instance summary as you'll need it for SSH access.

---

## Step 5: Connect via SSH

Once the instance is running, note the Public IPv4 address from the EC2 console.

On macOS or Linux, run this command, replacing YOUR_PUBLIC_IP with the IP address you noted:

```bash
ssh -i ~/.ssh/nemoclaw-key.pem ec2-user@YOUR_PUBLIC_IP
```

On first connection, you'll see a message asking about host authenticity. Type "yes" and press Enter. You should see a welcome message that includes ASCII art and information about the Deep Learning AMI. Your prompt will change to something like `[ec2-user@ip-172-31-XX-XX ~]$`, indicating you're now connected to your EC2 instance.

---

## Step 6: Verify GPU Access

Before installing NemoClaw, verify the GPU is accessible by running:

```bash
nvidia-smi
```

You should see output showing your NVIDIA A10G GPU with 24GB of memory. If you see this output, the GPU is ready and you can now proceed to install NemoClaw by following the main README instructions.

---

## Cost Management

Understanding and managing costs is essential when running GPU instances. The g5.xlarge instance costs approximately $1.006 per hour on-demand in most US regions.

For different usage patterns: running 1 hour per day (30 hours per month) costs about $30, running 2 hours per day (60 hours per month) costs about $60, running 4 hours per day (120 hours per month) costs about $121, and running 24/7 (720 hours per month) costs about $725.

Your 100GB gp3 EBS volume costs approximately $8 per month. This charge continues even when the instance is stopped, because your data persists on the volume.

When you're not using NemoClaw, stop your instance to avoid EC2 charges. From the AWS Console, go to EC2, then Instances, select your nemoclaw-server instance, and click Instance state followed by Stop instance. Stopping an instance preserves your data and setup. Starting it again takes about 1 minute, then NemoClaw will automatically start.

---

## Elastic IP Setup (Optional)

When you stop and start an instance, its public IP address changes. An Elastic IP gives your instance a permanent public IP address that doesn't change.

Elastic IPs are free while attached to a running instance. However, AWS charges $0.005 per hour (about $3.65 per month) for an Elastic IP that's allocated but not attached to any instance, or attached to a stopped instance.

To set up an Elastic IP, navigate to EC2, then Elastic IPs in the left sidebar. Click Allocate Elastic IP address, leave the default settings, and click Allocate. Select the newly allocated Elastic IP, click Actions, then Associate Elastic IP address. Select your nemoclaw-server instance and click Associate. Now update your security group rules and OpenClaw config to use this permanent IP address.

---

## Next Steps

Once you've completed this guide and verified GPU access, you're ready to install NemoClaw. Return to the main README and follow the installation instructions starting from "Run the Automated Installer."
