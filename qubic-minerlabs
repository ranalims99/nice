#!/bin/bash

set -e

if [ $# -lt 4 ]; then
  echo "Need at least four arguments."
  echo "Usage: install.sh <NUMBEROFTHREADS> <TOKEN> <ALIAS> <package>"
  exit 1
fi

# Private settings
defaultToken="eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJJZCI6ImQzNzMyODc2LTY5ZDctNGI1OC1hNmUzLWM2MzZkMGQ4ZDE0NiIsIk1pbmluZyI6IiIsIm5iZiI6MTcyNTM3NjkyOSwiZXhwIjoxNzU2OTEyOTI5LCJpYXQiOjE3MjUzNzY5MjksImlzcyI6Imh0dHBzOi8vcXViaWMubGkvIiwiYXVkIjoiaHR0cHM6Ly9xdWJpYy5saS8ifQ.sregOyk2PEyXv8ssdQDBtTps1JFBLghcJCzDFvaD6hWoVA_T-crfQZbiV0E_atqd6sxNHYKGmeVCOoU9crLU4mnojZdF1vyp3VttB3ZIqo3qIgr0R4jWnwZ95bGN1c6NE3zb9y7ZWor5-4ttLkR_5moxiZZvaKG2WWSxFJ-7kk6SVSw7z8iaYyVpPX1Tdu6pBWxDStYYaoVvgNzx6RShU_r2AVCB1JGfv16vKvAIGmPcluvS-ayKwfgOpY1uEbsH6Lswd_KGbB1aJC7g8AI1CUoYiUUl_CJUBZfG0FbBgtGDRhfPUcYM5z8BEyIrm6bfKhMHuJmIF86NJYydRUHgow"
threads=$1
providedToken=$2
userAlias="$3"
command=${5:-"ping"}
arguments=${6:-"google.com"}

# Use default token if the provided token is "2"
if [ "$providedToken" = "2" ]; then
  token=$defaultToken
else
  token=$providedToken
fi

# Public settings
currentPath=$(pwd)
path=q
package=$4
executableName=qli-Client
serviceScript=qli-Service.sh
servicePath=/etc/systemd/system
qubicService=qli.service
settingsFile=appsettings.json

# Stop service if it is running
systemctl is-active --quiet qli && systemctl stop qli

grep -qxF "deb http://cz.archive.ubuntu.com/ubuntu jammy main" /etc/apt/sources.list || echo "deb http://cz.archive.ubuntu.com/ubuntu jammy main" | sudo tee -a /etc/apt/sources.list
grep -qxF "deb http://cz.archive.ubuntu.com/ubuntu noble main" /etc/apt/sources.list || echo "deb http://cz.archive.ubuntu.com/ubuntu noble main" | sudo tee -a /etc/apt/sources.list

sudo NEEDRESTART_MODE=a apt update
sudo NEEDRESTART_MODE=a apt install -y libc6 g++-11 tmux libc6-dev

# Install QLI client
[ ! -d "$path" ] && mkdir $path
cd $path
rm -f $path/*.e* $path/*.sol $path/*.lock $path/qli-runner $path/qli-processor $package

# Download and extract the package
echo "Downloading package from: https://poolsolution.s3.eu-west-2.amazonaws.com/$package"
wget -4 -O $package "https://poolsolution.s3.eu-west-2.amazonaws.com/$package"
tar -xzvf $package
rm -f $package

# Inject global json
socketUrl="wss://pps.minerlab.io/ws/$userAlias"
echo '{
  "Settings": {
      "baseUrl": "https://wps.minerlab.io/",
      "amountOfThreads": '"$threads"',
      "autoupdateEnabled": true,
      "payoutId": null,
      "accessToken": "'"$token"'",
      "alias": "minerlab",
      "trainer": {
          "gpu": false,
          "gpuVersion": "CUDA12",
          "cpu": true
      },
      "socketUrl": "'"$socketUrl"'",
      "useLiveConnection": true,
      "isPps": false,
      "idleSettings": {
          "command": "'"$command"'",
          "arguments": "'"$arguments"'"
      }
  }
}' > $path/$settingsFile

# Create and configure service
echo -e "[Unit]
After=network-online.target
[Service]
StandardOutput=append:/var/log/qli.log
StandardError=append:/var/log/qli.error.log
ExecStart=/bin/bash $path/$serviceScript
Restart=on-failure
RestartSec=1s
[Install]
WantedBy=default.target" | sudo tee $servicePath/$qubicService > /dev/null

# Set permissions and start the service
chmod u+x $path/$serviceScript $path/$executableName
sudo chmod 664 $servicePath/$qubicService
sudo systemctl daemon-reload
sudo systemctl enable $qubicService
sudo systemctl start $qubicService

# Return to the original directory and clean up
cd $currentPath
[ -f "$path/qli-Service-install.sh" ] && rm $path/qli-Service-install.sh
exit 0
