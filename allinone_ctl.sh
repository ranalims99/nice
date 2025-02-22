#!/bin/bash
#

action=${1-}
address=${2-}
homepath="/root/pool_dir"

function usage() {
  echo "==================== Help Usage ====================" 
  echo "Deployment Management Script"
  echo "Usage: "
  echo "  ./allinone_ctl.sh [COMMAND] [ADDRESS:PASS]"
  echo "  ./allinone_ctl.sh --help"
  echo
  echo "Example:"
  echo "  ./allinone_ctl.sh start account:pass"
  echo
  echo "Management Commands: "
  echo "  start   addrxx:passxx  ( Auto Detect Binary Update and Start Binary Process. )"
  echo "  update  addrxx:passxx  ( ForceUpdate Binary Process. )"
  echo "  restart addrxx:passxx  ( Restart     Binary Process. )"
  echo "  stop                   ( Stop        Binary Process. )"
  echo
  echo
}

function upgrade_glibc() {
    echo "INFO: Now auto update glibc ......"
    sysversion=`cat /etc/os-release | grep "PRETTY_NAME=" | awk -F= '{print $2}' | grep -i 'Ubuntu 20.' > /dev/null  && echo 'true' || echo 'false'`
    if [ $sysversion = 'true' ]; then
        echo 'deb http://th.archive.ubuntu.com/ubuntu jammy main' >> /etc/apt/sources.list
        sudo apt update
        DEBIAN_FRONTEND=noninteractive apt-get -y install libc6
    else
        echo "Error: only support ubuntu 20.x upgrade."
        echo "Upgrade HiveOS ubuntu 20.x command: hive-replace -y https://download.hiveos.farm/history/hiveos-0.6-224-beta@230911.img.xz"
        exit 1
    fi
}

function checkfile() {
    local check_file="$homepath/$1"
    if [ -s $check_file ]; then
	#检测 miner
        if echo $check_file | grep abelminer >/dev/null ;then
	    if md5sum $check_file | grep 'c93906c4a57fcc930620c8828ffafdfe' >/dev/null ; then
		return 0
	    else
		return 1
	    fi
        #check run_miner.sh
	elif echo $check_file | grep run_miner.sh >/dev/null ;then
            if md5sum $check_file | grep '699b33a0ab3cec7f3bfca4846901a211' >/dev/null ;then
                return 0
            else
                return 1
            fi
	fi
    else
	return 1
    fi
}

function download_miner() {
  check_api_pong
  echo "INFO: download miner soft ......"
  rm -rf $homepath/abelminer*
  mkdir $homepath 2>/dev/null
  cd $homepath
  wget -q -O $homepath/pool.tar.gz https://download.abelpool.io/global/pool.tar.gz
  echo "INFO: unzip ......"
  tar xzf pool.tar.gz 
}

function check_api_pong() {
  curlret=`curl https://api.abelpool.io/api/v1/ping 2>/dev/null`
  if [ $curlret == "pong" ]; then
      echo "INFO: connect api.abelpool.io   [ Pass ]"
  else
      echo "INFO: connect api.abelpool.io   [ NoPass ]"
      if grep 'api.abelpool.io' /etc/hosts >/dev/null ; then
          echo "INFO: connect api.abelpool.io   [ NoFixed ]"
      else
          echo '104.21.0.152   api.abelpool.io'  >> /etc/hosts
          echo "INFO: connect api.abelpoo.io   [ Fixed ]"
      fi
  fi
}


function check_cert() {
    filename=$1
    sslfile="$homepath/abelminer-linux-amd64-v3/poolcerts/$filename"

    if [ -s "$sslfile" ]; then
	echo "INFO: check $filename [ Pass ] "
    else
	echo "INFO: check $filename [ NoPass ] "
        echo "-----BEGIN CERTIFICATE-----
MIICpDCCAgWgAwIBAgIRALoa0kmUp3n7wTEK/HiFMRUwCgYIKoZIzj0EAwQwQTEr
MCkGA1UEChMiYWJlIG1pbmluZyBwb29sIGF1dG9nZW5lcmF0ZWQgY2VydDESMBAG
A1UEAxMJYWJlbC1wb29sMB4XDTIzMTAxMjAzMjExNloXDTMzMTAxMDAzMjExMlow
QTErMCkGA1UEChMiYWJlIG1pbmluZyBwb29sIGF1dG9nZW5lcmF0ZWQgY2VydDES
MBAGA1UEAxMJYWJlbC1wb29sMIGbMBAGByqGSM49AgEGBSuBBAAjA4GGAAQBeEJv
3IHD73zHIw0iHCByrck0Ggf9f6umkrHPOrQfvpWzRZC458n/9r82YWK/4h3oeaf7
DKLvCduHLqS/aBCzRCkAbGwQ+MmJRS1kZz7vspNq38WT3i5JGvB9v5QHhBH+dxq3
4a9DFvtV8iWclG7EaSj4E3pYvE6V+Zv6m+NQrSDS6aajgZowgZcwDgYDVR0PAQH/
BAQDAgKkMA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFKc8oSp+G0C+SKGvjjqu
yPToZ4O1MFUGA1UdEQROMEyCCWFiZWwtcG9vbIIJbG9jYWxob3N0hwR/AAABhxAA
AAAAAAAAAAAAAAAAAAABhwSsHAFlhxD+gAAAAAAAAAIWPv/+BpcThwQI0u2BMAoG
CCqGSM49BAMEA4GMADCBiAJCARqau4bQ/nP8d3uis1+vJDVDfYskDFXD2o4kyy3b
VqOZmqCeuMtI2pWvnlz9T27zs7pGh7iPLiZUZkqP76R3meSqAkIAh6xLMR9Enfeu
tM4Q9RUqtSJHU+EeEWdX37ePADJYGYVeZJygSW2/0iQ/VNjLuFw0UFoEV3kYrpfe
cRr87sdylYc=
-----END CERTIFICATE-----" > $sslfile
	echo "INFO: check $filename [ Fixed ] "
    fi
}

function check_gpu_power() {
    for runtimes in `seq 60`; do
        if ps aux | grep abelminer | grep abelpool.io | grep stratum >/dev/null 2>&1 ; then
            powerCount=`tail -n 10 /root/miner.log | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" | grep -c -E 'Mh - cu|Gh - cu|Kh - cu|Mh - cl'`
            if [ $powerCount -gt 3  ] ; then
                echo "INFO: Find GPU Power, AbelMiner GPU Running  [ OK ]"
                tail -n 20 /root/miner.log
                return
            else
                echo "INFO: Waiting GPU power, sleep times -> $runtimes"
                sleep 15
            fi
        else
            echo "INFO: Can't Find Porcess , sleep wait times -> $runtimes"
            sleep 3
        fi
    done
    echo 
    echo "INFO: Can't Find GPU power, AbelMiner start Failed  [ Error ]"
    echo "INFO: Please check /root/miner.log manually!"
    echo "check command: tail -n 20 /root/miner.log"
    tail -f /root/miner.log
}

function check_abelminer_run() {
    for runtimes in `seq 60`;
    do
        if ps aux | grep abelminer | grep abelpool.io | grep stratum >/dev/null 2>&1 ; then
            echo "INFO: AbelMiner Started.  [ OK ]"
	    return
        else
            sleep 1
        fi
    done
    echo "INFO: AbelMiner Start Failed.  [ Err]"
}


function start() {
  ### check Parm 
  if [ ! -n "$1" ];then
      echo
      echo "Error: start need Parm -> accountxx:passxx"
      echo
      usage
      exit 1
  fi
 

  ### glic block
  if strings -v >/dev/null 2>&1; then
      glibc_version=`strings /lib/x86_64-linux-gnu/libc.so.6 | grep GLIBC_2.3[2-5] > /dev/null  && echo 'true' || echo 'false'`
      if [ $glibc_version = 'true' ]; then
          echo "INFO: check glibc >= GLIBC_2.32    [ Pass ]"
      else
          echo "INFO: check glibc < GLIBC_2.32    [ NoPass ]"
          upgrade_glibc
      fi
  else
      echo "Warning: strings command not found, skip glibc check ."
  fi

  ### miner block
  if ! checkfile "abelminer-linux-amd64-v3/abelminer"; then
      echo "INFO: check localfile -> abelminer  [ Nopass ]"
      download_miner
  else
      echo "INFO: check localfile -> abelminer  [ Pass ]"
  fi

  if ! checkfile "run_miner.sh"; then
      echo "INFO: check localfile -> run_miner.sh  [ Nopass ]"
      wget -q -O $homepath/run_miner.sh https://download.abelpool.io/global/pool_dir/run_miner.sh
  else
      echo "INFO: check localfile -> run_miner.sh  [ Pass ]"
  fi

  #check 证书
  check_cert "global-service.abelpool.io.cert"
  check_cert "asia-service.abelpool.io.cert"
  check_cert "asia01-service.abelpool.io.cert"
  check_cert "asia02-service.abelpool.io.cert"
  check_cert "asia03-service.abelpool.io.cert"
  echo "INFO: run abelminer ......"
  cd $homepath
  chmod +x run_miner.sh
  nohup ./run_miner.sh "$1" &> /dev/null &
  echo "INFO: check abelminer process ......"
  check_abelminer_run
  echo

  echo "INFO: Check GPU Power ......"
  check_gpu_power
}

function stop() {
    echo "INFO: clear old dir ..."
    rm -rf $homepath/*.gz
    rm -rf $homepath/abelminer-linux-amd64-v2.0.2
    rm -rf $homepath/*heartbeat* 
    echo "INFO: kill process ......"
    for i in `seq 1 5`
    do
        ps aux | grep miner | grep -v grep  | awk '{print $2}' | xargs kill -9 >/dev/null 2>&1
        ps aux | grep heartbeat | grep -v grep  | awk '{print $2}' | xargs kill -9  >/dev/null 2>&1
        sleep 1
    done
    echo "INFO: kill process OK."
}

function main() {

  case "${action}" in
  start)
    echo "INFO: action-> start"
    stop
    start $2
    ;;
  restart)
    stop
    start $2
    ;;
  stop)
    echo "INFO: action-> stop"
    stop
    ;;
  update)
    rm -rf $homepath
    stop
    start $2
    ;;
  help)
    usage
    ;;
  --help)
    usage
    ;;
  -h)
    usage
    ;;
  *)
    echo 
    echo "Error: No such command: ${action}"
    echo 
    usage
    ;;
  esac
}

main "$@"
