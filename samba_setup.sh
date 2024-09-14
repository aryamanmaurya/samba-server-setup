#!/bin/bash

# Function to check and prompt for a valid directory
get_directory() {
  while true; do
    read -p "Enter the full path of the directory you want to share: " shared_dir
    if [ -d "$shared_dir" ]; then
      echo "Directory exists: $shared_dir"
      break
    else
      echo "Directory does not exist. Please enter a valid directory."
    fi
  done
}

# Function to create a Samba user and set password
create_samba_user() {
  read -p "Enter the username for the Samba share: " smb_user
  while true; do
    read -s -p "Enter password for Samba user $smb_user: " smb_pass1
    echo
    read -s -p "Confirm password: " smb_pass2
    echo
    if [ "$smb_pass1" == "$smb_pass2" ]; then
      echo "Passwords match."
      break
    else
      echo "Passwords do not match. Try again."
    fi
  done

  # Create the user and set the Samba password
  sudo useradd -s /sbin/nologin $smb_user
  echo -e "$smb_pass1\n$smb_pass1" | sudo smbpasswd -a $smb_user
  sudo smbpasswd -e $smb_user
  sudo usermod -aG smbgroup $smb_user
}

# Install Samba if not installed
install_samba() {
  echo "Checking if Samba is installed..."
  if ! rpm -qa | grep samba > /dev/null; then
    echo "Samba not found. Installing Samba..."
    sudo yum install samba samba-client samba-common smb-utils -y
  else
    echo "Samba is already installed."
  fi
}

# Configure Samba
configure_samba() {
  smb_conf="/etc/samba/smb.conf"
  
  echo "Configuring Samba..."
  
  # Create a backup of the Samba configuration file
  sudo cp $smb_conf ${smb_conf}.bak

  # Prompt for allowed hosts IP range
  read -p "Enter the network IP range to allow (e.g., 192.168.56. for 192.168.56.111/24): " allowed_hosts

  # Create Samba group
  sudo groupadd smbgroup

  # Add network configuration to [global] section of smb.conf
  sudo sed -i '/\[global\]/a hosts allow = '"$allowed_hosts"'' $smb_conf

  # Create share configurations
  sudo bash -c "cat >> $smb_conf <<EOF

[$(basename $shared_dir)]
   path = $shared_dir
   valid users = @$smb_user
   browsable = yes
   writable = yes
   guest ok = no
   read only = no
   create mask = 0775
   directory mask = 0775

EOF"

  # Set ownership and permissions on the shared directory
  sudo chown -R :smbgroup $shared_dir
  sudo chmod -R 0775 $shared_dir
}

# Configure Firewall
configure_firewall() {
  echo "Configuring firewall rules for Samba..."
  sudo firewall-cmd --permanent --add-service=samba
  sudo firewall-cmd --reload
}

# Start Samba Services
start_samba_services() {
  echo "Starting Samba services..."
  sudo systemctl start smb
  sudo systemctl start nmb
  sudo systemctl enable smb
  sudo systemctl enable nmb
}

# Provide instructions to the user on how to mount the Samba share
provide_mount_instructions() {
  echo "==== Mounting Instructions ===="
  
  echo "=== Linux ==="
  echo "1. Install Samba client: sudo yum install cifs-utils -y (for CentOS/RHEL) or sudo apt install cifs-utils -y (for Ubuntu/Debian)"
  echo "2. Create a directory to mount the share: mkdir /mnt/shared"
  echo "3. Mount the share: sudo mount -t cifs //<server-ip>/$(basename $shared_dir) /mnt/shared -o username=$smb_user"
  echo "   Example: sudo mount -t cifs //192.168.56.111/$(basename $shared_dir) /mnt/shared -o username=$smb_user"
  echo

  echo "=== Windows ==="
  echo "1. Open File Explorer."
  echo "2. In the address bar, type: \\\\<server-ip>\\$(basename $shared_dir)"
  echo "   Example: \\\\192.168.56.111\\$(basename $shared_dir)"
  echo "3. Enter the username and password when prompted."
  echo
  echo "Troubleshooting-- make sure selinux is disabled or create a selinux policy for the shared directory."
  echo "Examle: sudo chcon -t samba_share_t <directory-path>"
  echo "If you are sharing the directory under the /root you may have assign some additional permissions."

}

# Main Script Execution
echo "==== Samba Server Setup ===="

# Get the directory to share
get_directory

# Install Samba if necessary
install_samba

# Configure Samba
create_samba_user
configure_samba

# Configure Firewall for Samba
configure_firewall

# Start Samba Services
start_samba_services

# Provide mounting instructions
provide_mount_instructions

echo "Samba server setup is complete!"

