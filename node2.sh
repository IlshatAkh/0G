#!/bin/bash

# Execute the storage node script
bash 0g_storage.sh

# Create systemd service for zgstorage Node
tee /etc/systemd/system/zgstorage.service > /dev/null <<EOF
[Unit]
Description=zgstorage Node
After=network.target

[Service]
User=root
WorkingDirectory=/root/0g-storage-node/run
ExecStart=/root/0g-storage-node/target/release/zgs_node --config /root/0g-storage-node/run/config.toml
Restart=on-failure
RestartSec=10
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

sed -ie 's|https://0g-new-rpc.dongqn.com|http://159.69.72.247:22345|' /root/0g-storage-node/run/config.toml

# Reload systemd, enable and start zgstorage service
systemctl daemon-reload
systemctl enable zgstorage
systemctl start zgstorage

# Execute the KV node script
bash 0g_kv.sh

# Create systemd service for zgs_kv Node
tee /etc/systemd/system/zgs_kv.service > /dev/null <<EOF
[Unit]
Description=zgs_kv Node
After=network.target

[Service]
User=root
WorkingDirectory=/root/0g-storage-kv/run
ExecStart=/root/0g-storage-kv/target/release/zgs_kv --config /root/0g-storage-kv/run/config.toml
Restart=on-failure
RestartSec=10
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start zgs_kv service
systemctl daemon-reload
systemctl enable zgs_kv
systemctl start zgs_kv
journalctl -u zgs_kv -f -o cat

# Update KV script
wget -O 0g_kv_upd.sh http://95.216.25.144:21212/0g_kv.sh
bash 0g_kv_upd.sh

# Stop OG Node service
systemctl stop ogd

# Backup and remove OG Node data
cp /root/.0gchain/data/priv_validator_state.json /root/.0gchain/priv_validator_state.json.backup
rm -rf /root/.0gchain/data

# Download and extract the latest snapshot
curl https://snapshots-testnet.nodejumper.io/0g-testnet/0g-testnet_latest.tar.lz4 | lz4 -dc - | tar -xf - -C ./.0gchain
mv ./.0gchain/priv_validator_state.json.backup ./.0gchain/data/priv_validator_state.json
chmod +rwx ./.0gchain/data/priv_validator_state.json

# Update peers in the configuration
PEERS="35e76dcea85061feaef024ede1e1dd8661332238@62.171.132.194:12656,ed87b92b175a6e42f2688efb4f6070bb57a4914f@89.117.63.18:12656,49c663b278309472b81312adc0994ea99bc1b776@84.54.23.71:26656,057f64f293f0843c849aa3f1f1e20a1a0add29f8@45.159.222.237:26656,928f42a91548484f35a5c98aa9dcb25fb1790a70@65.109.155.238:26656,89e272c0e5007e391f420e4f45e1473f91995025@154.26.155.239:26656,96d615925aee68b90bfaf18d461e799fdcb22211@45.10.162.96:26656,b2ea93761696d4881e87f032a7f6158c6c25d92c@45.14.194.241:26646,cfd099ade96d82908b4ab185eddbf90379579bfc@84.247.149.9:26656,bc8898c416f7b22e56782eb16803150fd90863b6@81.0.221.180:26656,0aa16751b6c1884e755997d08dc17f8582aa9e38@45.10.163.80:26656,364c45b7cab8a095cb59443f3e91fd102ec9eb95@158.220.118.216:26656,7ecfe8d9404a4e1ea36cba5d546650da2b97bfd2@45.90.122.129:26656,c8807bba12fa67676319df8e049ae5fac690cf55@45.159.228.20:26656,d7ca6521ee30f8cf9eaf32e9edee1101e44c48e9@45.10.161.5:26656,369666051d45ed28379db34a80dfdf13e43d3681@5.104.80.63:26656,03619b6f90fab32cd5f0cadbe3021e6a3cda16e3@154.26.156.101:26656,6e3c5aaab9d3ac6c0de9fd90648cdced499086bf@65.109.58.118:12656,aa75383a75c4781667d69129e870c7bc397bb77d@185.222.241.250:12656,31d45a624434f8794cb19a5cc94789f783e337e7@104.251.215.226:16656"
sed -i 's|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' ./.0gchain/config/config.toml

# Update address book
curl -s https://snapshots-testnet.nodejumper.io/0g-testnet/addrbook.json > ./.0gchain/config/addrbook.json

# Restart OG Node service
systemctl restart ogd
journalctl -u ogd -fn 100 -o cat