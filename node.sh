#!/bin/bash

apt install lz4
# Remove any previous Go installation
sudo rm -rf /usr/local/go

# Download the latest version of Go (adjust the version number if necessary)
wget https://go.dev/dl/go1.21.10.linux-amd64.tar.gz

# Extract the archive to /usr/local
sudo tar -C /usr/local -xzf go1.21.10.linux-amd64.tar.gz

# Set up Go environment variables
echo "export PATH=\$PATH:/usr/local/go/bin" | sudo tee -a /etc/profile
echo "export GOROOT=/usr/local/go" | sudo tee -a /etc/profile
echo "export GOPATH=\$HOME/go" | sudo tee -a /etc/profile
echo "export PATH=\$PATH:\$GOPATH/bin" | sudo tee -a /etc/profile

# Apply the changes to the current session
source /etc/profile

# Verify the installation
go version

# Download scripts
wget https://raw.githubusercontent.com/JeTr1x/stafi/main/0g_forknew.sh
wget http://95.216.25.144:21212/0g_storage.sh
wget https://raw.githubusercontent.com/eeeZEGEN/scripts0g/main/0g_kv.sh

# Execute the first script
bash 0g_forknew.sh

# Create systemd service for OG Node
sudo tee /etc/systemd/system/ogd.service > /dev/null <<EOF
[Unit]
Description=OG Node
After=network.target

[Service]
User=root
Type=simple
ExecStart=/root/go/bin/0gchaind start --home /root/.0gchain
Restart=on-failure
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start OG Node service
systemctl daemon-reload
systemctl enable ogd
systemctl restart ogd
journalctl -u ogd -f -o cat


# Creating wallet
# 0gchaind keys add wallet --eth
# passphrase 6bmeVz8^`~z4