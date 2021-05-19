#!/usr/bin/env bash

#### DEV1 ####
bootNodeIP=164.90.155.170
bootNodeHost=testnet-node-1.dev1.cere.network
genesisValidatorIP=104.236.193.202
genesisValidatorHost=testnet-node-2.dev1.cere.network
validatorsIPs=(167.99.188.91\
               167.99.131.218\
               165.227.224.150)
validatorsHosts=(testnet-node-3.dev1.cere.network\
                 testnet-node-4.dev1.cere.network\
                 testnet-node-5.dev1.cere.network)
fullNodeIP=138.197.202.96
fullNodeHost=testnet-node-6.dev1.cere.network
archiveNodeIP=134.209.192.121
archiveNodeHost=testnet-node-7.dev1.cere.network
user="andrei"
path="../../root/"

#### DEV2 ####
#ips=(157.230.113.121\
#     139.59.164.220\
#     165.227.57.154\
#     104.236.108.211)
#hosts=(tokenomic-node-1.dev.cere.network\
#		    tokenomic-node-2.dev.cere.network\
#       tokenomic-node-3.dev.cere.network\
#       tokenomic-node-4.dev.cere.network)
#user="andrei"
#path="../../root/"

repo=https://github.com/Cerebellum-Network/nodes-installation-scripts.git
repoBranch="feature/launch"
dirName="cere-network"

generate_chain_spec () {
  docker-compose down -t 0
  rm -rf chain-data accounts spec-data scripts/keys

  docker-compose up create_chain_spec
  docker-compose up --build generate_accounts
  docker-compose up --build generate_emulations_chain_spec
  docker-compose up create_raw_chain_spec
}

start_boot () {
  ssh ${user}@${bootNodeIP} 'bash -s'  << EOT
    sudo su -c "cd ${path}; git clone ${repo} ${dirName}; cd ${dirName}; git checkout ${repoBranch}; chmod -R 777 chain-data"
    sudo su -c "cd ${path}${dirName}; sed -i \"s|NODE_NAME=NODE_NAME|NODE_NAME=CereMainnetAlpha01|\" ./configs/.env.mainnet";
    sudo su -c "cd ${path}${dirName}; docker-compose --env-file ./configs/.env.mainnet up -d boot_node"
    sudo su -c "cd ${path}${dirName}; sed -i \"s|testnet-node-1.cere.network:9945.*|${hosts[0]}:9945 {|\" Caddyfile";
    sudo su -c "cd ${path}${dirName}; sed -i \"s|testnet-node-1.cere.network:9934.*|${hosts[0]}:9934 {|\" Caddyfile";
    sudo su -c "cd ${path}${dirName}; docker-compose up -d caddy";
EOT
}

start_genesis_validators () {
  bootNodeID=$(curl -H 'Content-Type: application/json' --data '{ "jsonrpc":"2.0", "method":"system_localPeerId", "id":1 }' ${bootNodeIP}:9933 -s | jq '.result')
  while [ -z $bootNodeID ]; do
      echo "*** bootNodeID is empty "
      bootNodeID=$(curl -H 'Content-Type: application/json' --data '{ "jsonrpc":"2.0", "method":"system_localPeerId", "id":1 }' ${bootNodeIP}:9933 -s | jq '.result')
      sleep 5
  done
  ssh ${user}@${ips[1]} 'bash -s'  << EOT
    sudo su -c "cd ${path}; git clone ${repo} ${dirName}; cd ${dirName}; git checkout ${repoBranch}; chmod -R 777 chain-data"
    sudo su -c "cd ${path}${dirName}; sed -i \"s|BOOT_NODE_IP_ADDRESS=.*|BOOT_NODE_IP_ADDRESS=${bootNodeIP}|\" ./configs/.env.mainnet";
    sudo su -c "cd ${path}${dirName}; sed -i \"s|NETWORK_IDENTIFIER=.*|NETWORK_IDENTIFIER=${bootNodeID}|\" ./configs/.env.mainnet";
    sudo su -c "cd ${path}${dirName}; sed -i \"s|NODE_NAME=NODE_NAME|NODE_NAME=CereMainnetAlpha02|\" ./configs/.env.mainnet";
    sudo su -c "cd ${path}${dirName}; docker-compose --env-file ./configs/.env.mainnet up -d add_validation_node_custom"
    sudo su -c "cd ${path}${dirName}; sed -i \"s|testnet-node-1.cere.network:9945.*|${hosts[1]}:9945 {|\" Caddyfile";
    sudo su -c "cd ${path}${dirName}; sed -i \"s|boot_node:9944|add_validation_node_custom:9944|\" Caddyfile";
    sudo su -c "cd ${path}${dirName}; sed -i \"s|testnet-node-1.cere.network:9934.*|${hosts[1]}:9934 {|\" Caddyfile";
    sudo su -c "cd ${path}${dirName}; sed -i \"s|boot_node:9933|add_validation_node_custom:9933|\" Caddyfile";
    sudo su -c "cd ${path}${dirName}; docker-compose up -d caddy";
EOT
}

start_validators () {
  for i in ${!validatorsIPs[@]}; do
    let nodeIndex=$i+3
    if (( ${nodeIndex} < 10 )); then
      nodeIndex=0${nodeIndex}
    fi
    echo Starting Validator ${nodeIndex}
    start_node ${validatorsIPs[i]} CereMainnetAlpha${nodeIndex} add_validation_node_custom add_validation_node_custom ${validatorsHosts[i]}
  done
}

insert_keys () {
  NODE_0_URL=http://${hosts[0]}:9933
  NODE_1_URL=http://${hosts[1]}:9933

  curl ${NODE_0_URL} -H "Content-Type:application/json;charset=utf-8" -d "@scripts/keys/node_0_stash_gran.json"
  curl ${NODE_0_URL} -H "Content-Type:application/json;charset=utf-8" -d "@scripts/keys/node_0_gran.json"
  curl ${NODE_0_URL} -H "Content-Type:application/json;charset=utf-8" -d "@scripts/keys/node_0_babe.json"
  curl ${NODE_0_URL} -H "Content-Type:application/json;charset=utf-8" -d "@scripts/keys/node_0_imol.json"
  curl ${NODE_0_URL} -H "Content-Type:application/json;charset=utf-8" -d "@scripts/keys/node_0_audi.json"

  curl ${NODE_1_URL} -H "Content-Type:application/json;charset=utf-8" -d "@scripts/keys/node_1_stash_gran.json"
  curl ${NODE_1_URL} -H "Content-Type:application/json;charset=utf-8" -d "@scripts/keys/node_1_gran.json"
  curl ${NODE_1_URL} -H "Content-Type:application/json;charset=utf-8" -d "@scripts/keys/node_1_babe.json"
  curl ${NODE_1_URL} -H "Content-Type:application/json;charset=utf-8" -d "@scripts/keys/node_1_imol.json"
  curl ${NODE_1_URL} -H "Content-Type:application/json;charset=utf-8" -d "@scripts/keys/node_1_audi.json"
}

restart_genesis () {
  ssh ${user}@${ips[0]} 'bash -s'  << EOT
    sudo su -c "cd ${path}${dirName}; docker-compose restart boot_node"
EOT
  ssh ${user}@${ips[1]} 'bash -s'  << EOT
    sudo su -c "cd ${path}${dirName}; docker-compose restart add_validation_node_custom"
EOT
}

start_full () {
  start_node ${fullNodeIP} CereMainnetAlphaFull01 full_node cere_full_node ${fullNodeHost}
}

start_archive () {
  start_node ${archiveNodeIP} CereMainnetAlphaArchive01 archive_node cere_archive_node ${archiveNodeHost}
}

start_node () {
  ip=${1}
  host=${5}
  nodeName=${2}
  serviceName=${3}
  containerName=${4}
  bootNodeID=$(curl -H 'Content-Type: application/json' --data '{ "jsonrpc":"2.0", "method":"system_localPeerId", "id":1 }' ${bootNodeIP}:9933 -s | jq '.result')
  while [ -z $bootNodeID ]; do
      echo "*** bootNodeID is empty "
      bootNodeID=$(curl -H 'Content-Type: application/json' --data '{ "jsonrpc":"2.0", "method":"system_localPeerId", "id":1 }' ${bootNodeIP}:9933 -s | jq '.result')
      sleep 5
  done
  ssh ${user}@${ip} 'bash -s'  << EOT
    sudo su -c "cd ${path}; git clone ${repo} ${dirName}; cd ${dirName}; git checkout ${repoBranch}; chmod -R 777 chain-data"
    sudo su -c "cd ${path}${dirName}; sed -i \"s|BOOT_NODE_IP_ADDRESS=.*|BOOT_NODE_IP_ADDRESS=${bootNodeIP}|\" ./configs/.env.mainnet";
    sudo su -c "cd ${path}${dirName}; sed -i \"s|NETWORK_IDENTIFIER=.*|NETWORK_IDENTIFIER=${bootNodeID}|\" ./configs/.env.mainnet";
    sudo su -c "cd ${path}${dirName}; sed -i \"s|NODE_NAME=NODE_NAME|NODE_NAME=${nodeName}|\" ./configs/.env.mainnet";
    sudo su -c "cd ${path}${dirName}; docker-compose --env-file ./configs/.env.mainnet up -d ${serviceName}"
    sudo su -c "cd ${path}${dirName}; sed -i \"s|testnet-node-1.cere.network:9945.*|${host}:9945 {|\" Caddyfile";
    sudo su -c "cd ${path}${dirName}; sed -i \"s|boot_node:9944|${containerName}:9944|\" Caddyfile";
    sudo su -c "cd ${path}${dirName}; sed -i \"s|testnet-node-1.cere.network:9934.*|${host}:9934 {|\" Caddyfile";
    sudo su -c "cd ${path}${dirName}; sed -i \"s|boot_node:9933|${containerName}:9933|\" Caddyfile";
    sudo su -c "cd ${path}${dirName}; docker-compose up -d caddy";
EOT
}

stop_network () {
  stop_node ${bootNodeIP}
  stop_node ${genesisValidatorIP}
  for i in ${validatorsIPs[@]}
  do
    stop_node ${i}
  done
  stop_node ${fullNodeIP}
  stop_node ${archiveNodeIP}
}

stop_node () {
  ip=${1}
  echo "Stopping ${ip}"
  ssh ${user}@${ip} 'bash -s' << EOT
    sudo su -c "cd ${path}${dirName}; docker-compose down;"
    sudo su -c "cd ${path}; rm -rf cere-network;"
EOT
}

case $1 in
  generate_chain_spec) "$@"; exit;;
  start_boot) "$@"; exit;;
  start_genesis_validators) "$@"; exit;;
  start_validators) "$@"; exit;;
  insert_keys) "$@"; exit;;
  restart_genesis) "$@"; exit;;
  start_full) "$@"; exit;;
  start_archive) "$@"; exit;;
  stop_network) "$@"; exit;;
esac