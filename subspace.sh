#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

cd $HOME

if [[ "$1" == "uninstall" ]]; then
        printf "${GREEN}Удаление ноды${NC}\n"

        if [[ "$2" == "--all" ]]; then
                cat .bash_profile | grep -v SUBSPACE_WALLET_ADDRESS | grep -v SUBSPACE_NODE_NAME | grep -v SUBSPACE_PLOT_SIZE | grep -v subspace_logs > .bash_profile
                unset SUBSPACE_WALLET_ADDRESS
                unset SUBSPACE_NODE_NAME
                unset SUBSPACE_PLOT_SIZE
        fi

        if [ ! -d "subspace" ]; then
                printf "${RED}Установка Subspace не найдена${NC}\n"
                exit
        fi
        cd subspace
        docker-compose down -v
        cd $HOME
        rm -rf subspace
        exit
fi

printf "${GREEN}Обновление системы${NC}\n"
apt -qq update -y
apt -qq upgrade -y

if [[ "$1" != "update" ]]; then
        printf "${GREEN}Устанавка зависимостей${NC}\n"
        apt -qq install curl wget jq -y

        printf "${GREEN}Установка Docker${NC}\n"
        apt -qq purge docker docker-engine docker.io containerd docker-compose -y
        rm /usr/bin/docker-compose /usr/local/bin/docker-compose > /dev/null 2>&1
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        systemctl restart docker
        curl -SL https://github.com/docker/compose/releases/download/v2.5.0/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
fi

printf "${GREEN}Конфигурация${NC}\n"
mkdir subspace
cd subspace

$SUBSPACE_RELEASE=$(curl -s https://api.github.com/repos/subspace/subspace/releases | jq '[.[] | select(.prerelease==false) | select(.tag_name | startswith("runtime") | not) | select(.tag_name | startswith("chain-spec") | not)][0].tag_name')
$SUBSPACE_CHAIN="gemini-2a"

source $HOME/.bash_profile
if [[ -z "${SUBSPACE_WALLET_ADDRESS}" ]]; then
        read -p "Введите адрес кошелька: " SUBSPACE_WALLET_ADDRESS
        echo 'export SUBSPACE_WALLET_ADDRESS='$SUBSPACE_WALLET_ADDRESS >> $HOME/.bash_profile
fi
if [[ -z "${SUBSPACE_NODE_NAME}" ]]; then
        read -p "Введите имя ноды: " SUBSPACE_NODE_NAME
        echo 'export SUBSPACE_NODE_NAME="'${SUBSPACE_NODE_NAME}'"' >> $HOME/.bash_profile
fi
if [[ -z "${SUBSPACE_PLOT_SIZE}" ]]; then
        read -p "Введите размер плота (10Gb, 100Gb, 1Tb, etc.): " SUBSPACE_PLOT_SIZE
        echo 'export SUBSPACE_PLOT_SIZE='$SUBSPACE_PLOT_SIZE >> $HOME/.bash_profile
fi

wget -qO - https://github.com/bombermine3/subspace-docker/raw/main/docker-compose-auto.yml | envsubst > docker-compose.yml

printf "${GREEN}Запуск ноды${NC}\n"
docker-compose up -d


if [[ `alias | grep subspace_logs | wc -l` == 0 ]]; then
        echo 'cd $HOME/subspace && docker-compose logs --tail=1000 -f' > $HOME/.bash_profile
fi

source $HOME/.bash_profile

printf "Проверка логов: subspace_logs\n"