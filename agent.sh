#!/bin/bash
function agentInstall() {
    mkdir /usr/Hosting/
    cd /usr/Hosting
    wget -O agent https://github.com/AKASHRP98/agent/blob/master/agent?raw=true
    chmod +x agent
    wget -O config.json https://raw.githubusercontent.com/AKASHRP98/agent/master/config.json

    cat >>/etc/systemd/system/agent.service <<EOL
[Unit]
Description=Hosting agent

[Service]
Type=simple
ExecStart=/usr/Hosting/agent
KillMode=process
User=root
Group=root
Restart=on-failure
SuccessExitStatus=2

[Install]
WantedBy=multi-user.target

EOL

    systemctl daemon-reload

    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    mv wp-cli.phar wp-cli

}

agentInstall
service agent start
