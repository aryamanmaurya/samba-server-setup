# Samba Server Setup Script

This script helps set up a Samba server on CentOS or RHEL-based systems, allowing directory sharing between Linux and Windows systems. It includes prompts for directory selection, user creation, and network configuration.

## Features
- Check if the directory to share exists, and prompt for a correct one if not.
- Install Samba if it is not already installed.
- Create a Samba user and set a password.
- Configure the Samba share with access restricted to a specific user.
- Adjust firewall settings to allow Samba traffic.
- Provide detailed instructions for mounting the share on Linux and Windows clients.

## Prerequisites
- CentOS or RHEL-based system
- sudo privileges
- Active network connection

## Usage
1. Clone this repository and navigate to the directory.
   ```bash
   git clone <repository-url>
   cd <repository-directory>

2. Run the script
    ```bash
    sudo bash samba_setup.sh

3. Follow the prompts:
    Enter the directory path to share.
 - Enter the username for the Samba user.
 - Set and confirm the Samba user password.
 - Enter the IP range allowed to access the share.

## Mounting instructions
### linux 
1. Install samba clients
 - For CentOS/RHEL
   ```
   sudo yum install cifs-utils -y
 - For Ubuntu/Debian
    ```
    sudo yum install cifs-utils -y
2. Create directory for mount the share
    ```
    mkdir /mnt/shared

3.  Mount the share
      ```
    sudo mount -t cifs //<server-ip>/<share-name> /mnt/shared username=<samba-user>
  Example:
 
   ```
   sudo mount -t cifs //192.168.56.111/data /mnt/shared -o username=demo
   ```
### Windows

  1. window + R
     ```
        \\<server-ip>
     ```

  2. Enter the username and password when prompted.

## Troubleshooting
### 1. Selinux:

 If you have SELinux enabled and experience permission issues, disable S ELinux temporarily to check if it's the source of the problem:
   ```
     sudo setenforce 0
   ```
 If disabling SELinux resolves the issue, you can create an SELinux policy to allow Samba to access the directory:
  ``` 
     sudo chcon -t samba_share_t <directory-path>
  ```
### 2. Permissions:

 Do not share files inside the /root home directory, as permissions will block the sharing. Choose another directory like /srv or /home.

### 3. firewall:
 Ensure the firewall is correctly configured to allow Samba traffic. Use:

 ```
     sudo firewall-cmd --permanent --add-service=samba
     sudo firewall-cmd --reload
 ```





