#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
function RandomString {
    head /dev/urandom | tr -dc _A-Za-z0-9 | head -c55
}

function packages() {
    apt-get update -y
    apt-get upgrade -y
    apt-get install -y wget tar make curl incron openssl
}
function nusterInstall() {

    NAME="hosting"
    cd
    echo "
██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗     ██╗███╗   ██╗ ██████╗     ███╗   ██╗██╗   ██╗███████╗████████╗███████╗██████╗ 
██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║     ██║████╗  ██║██╔════╝     ████╗  ██║██║   ██║██╔════╝╚══██╔══╝██╔════╝██╔══██╗
██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║     ██║██╔██╗ ██║██║  ███╗    ██╔██╗ ██║██║   ██║███████╗   ██║   █████╗  ██████╔╝
██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║     ██║██║╚██╗██║██║   ██║    ██║╚██╗██║██║   ██║╚════██║   ██║   ██╔══╝  ██╔══██╗
██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗██║██║ ╚████║╚██████╔╝    ██║ ╚████║╚██████╔╝███████║   ██║   ███████╗██║  ██║
╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝╚═╝  ╚═══╝ ╚═════╝     ╚═╝  ╚═══╝ ╚═════╝ ╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝
"

    wget https://github.com/jiangwenyuan/nuster/releases/download/v5.2.5.22/nuster-5.2.5.22.tar.gz
    tar -xf nuster-5.2.5.22.tar.gz
    cd nuster-5.2.5.22
    apt-get install -y libz-dev libssl-dev libpcre3-dev build-essential make
    make TARGET=linux-glibc USE_OPENSSL=1 USE_PCRE=1 USE_ZLIB=1
    make install PREFIX=/usr/local/$NAME
    cd
    rm -rf nuster-5.2.5.22
    rm -rf nuster-5.2.5.22.tar.gz
    cd /usr/local/$NAME/sbin/
    mv nuster $NAME
    mkdir /opt/Hosting
    openssl dhparam -out /opt/Hosting/dhparam.pem 2048
    cat >>/etc/systemd/system/hosting.service <<EOL

[Unit]
Description=Hosting cache server
After=syslog.target network.target

[Service]
ExecStart=/usr/local/hosting/sbin/hosting -f /opt/Hosting/hosting.cfg -D -q
ExecReload=/usr/local/hosting/sbin/hosting -f /opt/Hosting/hosting.cfg -D -q
ExecReload=/bin/kill -USR2 $MAINPID
KillMode=mixed
Restart=always
SuccessExitStatus=143
Type=forking

[Install]
WantedBy=multi-user.target

EOL
}

function mariadbInstall() {
    apt-get install -y software-properties-common
    apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc'
    add-apt-repository 'deb [arch=amd64,arm64,ppc64el] http://sfo1.mirrors.digitalocean.com/mariadb/repo/10.4/ubuntu focal main'
    add-apt-repository 'deb [arch=amd64,arm64,ppc64el] http://nyc2.mirrors.digitalocean.com/mariadb/repo/10.4/ubuntu focal main'
    apt-get update -y
    apt-get install -y mariadb-server
    systemctl start mysql
    apt-get install -y expect

    ROOTPASS=$(RandomString)

    SECURE_MYSQL=$(expect -c "
set timeout 5
spawn mysql_secure_installation

expect \"Enter current password for root (enter for none):\"
send \"\r\"

expect \"Switch to unix_socket authentication\"
send \"y\r\"

expect \"Change the root password?\"
send \"y\r\"

expect \"New password:\"
send \"$ROOTPASS\r\"

expect \"Re-enter new password:\"
send \"$ROOTPASS\r\"

expect \"Remove anonymous users?\"
send \"y\r\"

expect \"Disallow root login remotely?\"
send \"y\r\"

expect \"Remove test database and access to it?\"
send \"y\r\"

expect \"Reload privilege tables now?\"
send \"y\r\"

expect eof
")
    echo "$SECURE_MYSQL"

    cat >>/etc/mysql/mariadb.conf.d/root <<EOL
user: root
password: $ROOTPASS
EOL

}

function litespeedInstall() {
    sudo wget -O - http://rpms.litespeedtech.com/debian/enable_lst_debian_repo.sh | bash
    apt-get install -y openlitespeed
    lsphp="lsphp72 lsphp72-apcu lsphp72-common lsphp72-curl lsphp72-igbinary lsphp72-imagick lsphp72-imap lsphp72-intl lsphp72-ioncube lsphp72-json lsphp72-ldap lsphp72-memcached lsphp72-msgpack lsphp72-mysql lsphp72-opcache lsphp72-pgsql lsphp72-pspell lsphp72-recode lsphp72-redis lsphp72-sqlite3 lsphp72-sybase lsphp72-tidy"

    lsphp+=" lsphp73 lsphp73-apcu lsphp73-common lsphp73-curl lsphp73-igbinary lsphp73-imagick lsphp73-imap lsphp73-intl lsphp73-ioncube lsphp73-json lsphp73-ldap lsphp73-memcached lsphp73-msgpack lsphp73-mysql lsphp73-opcache lsphp73-pgsql lsphp73-pspell lsphp73-recode lsphp73-redis lsphp73-sqlite3 lsphp73-sybase lsphp73-tidy"
    lsphp+=" lsphp74 lsphp74-apcu lsphp74-common lsphp74-curl lsphp74-igbinary lsphp74-imagick lsphp74-imap lsphp74-intl lsphp74-ioncube lsphp74-json lsphp74-ldap lsphp74-memcached lsphp74-msgpack lsphp74-mysql lsphp74-opcache lsphp74-pgsql lsphp74-pspell lsphp74-redis lsphp74-sqlite3 lsphp74-sybase lsphp74-tidy"
    lsphp+=" lsphp80 lsphp80-apcu lsphp80-common lsphp80-curl lsphp80-igbinary lsphp80-imagick lsphp80-imap lsphp80-intl lsphp80-ldap lsphp80-memcached lsphp80-msgpack lsphp80-mysql lsphp80-opcache lsphp80-pgsql lsphp80-pspell lsphp80-redis lsphp80-sqlite3 lsphp80-sybase lsphp80-tidy"
    apt-get install -y $lsphp
    ln -sf /usr/local/lsws/lsphp72/bin/lsphp /usr/local/lsws/fcgi-bin/lsphp72
    ln -sf /usr/local/lsws/lsphp73/bin/lsphp /usr/local/lsws/fcgi-bin/lsphp73
    ln -sf /usr/local/lsws/lsphp74/bin/lsphp /usr/local/lsws/fcgi-bin/lsphp74
    ln -sf /usr/local/lsws/lsphp80/bin/lsphp /usr/local/lsws/fcgi-bin/lsphp80
    ln -s /usr/local/lsws/lsphp74/bin/php /usr/bin/php
    wget -O /usr/local/lsws/conf/httpd_config.conf https://raw.githubusercontent.com/AKASHRP98/lsws/master/httpd_config.conf
}

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

    mkdir /usr/Hosting/errors
    wget -O /usr/Hosting/errors/404.http https://raw.githubusercontent.com/AKASHRP98/agent/master/404.http
}

function misc() {
    echo "root" >/etc/incron.allow
    touch /etc/incron.d/sites.txt
    apt-get dist-upgrade -y
}

packages
nusterInstall
mariadbInstall
litespeedInstall
agentInstall
cd
rm hosting.sh
misc
service agent start
service hosting start
service mariadb start
service lsws restart
