#!/bin/bash

#determinate ip addresses for configuration
ips=$(ip a | grep -Po '(inet6 \K[0-9a-f:]+)|(inet \K[\d.]+)' | tr '\n' ' ')
if [ -z "$INET_INTERFACE" ]
then 
   INET_INTERFACE=$ips
fi


###Dovecot installieren und konfigurieren
#Anzupassende Stellen - /etc/dovecot/dovecot.conf
#- ssl_cert
#/etc/ssl-cert/fullchain.pem
#- ssl_key
#/etc/ssl-cert/privkey.pem
#- postmaster_address
sed -i "s/%postmasterplaceholder%/$POSTMASTER_ADDRESS/g" /etc/dovecot/dovecot.conf

#Anzupassende Stellen - /etc/dovecot/dovecot-sql.conf
#- Datenbankpasswort vmaildbpass
sed -i "s/%passwordplaceholder%/$MYSQL_PASSWORD/g" /etc/dovecot/dovecot-sql.conf
#- Mailserver Hostname
sed -i "s/%hostnameplaceholder%/$MYSQL_HOSTNAME/g" /etc/dovecot/dovecot-sql.conf
chmod 440 /etc/dovecot/dovecot-sql.conf

if [ ! -f /etc/dovecot/dh/dh4096.pem ]; then
    openssl dhparam -out /etc/dovecot/dh/dh4096.pem 4096
fi


###Postfix installieren und konfigurieren
#Anzupassende Stellen - /etc/postfix/main.cf
#- inet_interfaces
#sed -i "s/%inetintplaceholder%/$INET_INTERFACE/g" /etc/postfix/main.cf
sed -i "s/^\(inet_interfaces = \).*/\1$INET_INTERFACE/" /etc/postfix/main.cf
#- myhostname
sed -i "s/%hostnameplaceholder%/$FQN_HOSTNAME/g" /etc/postfix/main.cf
#- smtpd_tls_cert_file
#/etc/ssl-cert/fullchain.pem
#- smtpd_tls_key_file
#/etc/ssl-cert/privkey.pem

if [ ! -f /etc/postfix/dh/dh2048.pem ]; then
    openssl dhparam -out /etc/postfix/dh/dh2048.pem 2048
fi

#Postfix SQL-Konfiguration
sed -i "s/%vmaildbpassplaceholder%/$MYSQL_PASSWORD/g" /etc/postfix/sql/*.cf
sed -i "s/%hostnameplaceholder%/$MYSQL_HOSTNAME/g" /etc/postfix/sql/*.cf
chown -R root:postfix /etc/postfix/sql
chmod g+x /etc/postfix/sql

postmap /etc/postfix/without_ptr
newaliases
#/usr/sbin/postfix set-permissions

#Rspamd installieren und konfigurieren
sed -i "s/%rspampassplaceholder%/$(rspamadm pw -p $RSPAMD_PASSWORD)/g" /etc/rspamd/local.d/worker-controller.inc

if [ ! -f /var/lib/rspamd/dkim/2020.txt ]; then
    rspamadm dkim_keygen -b 2048 -s 2020 -k /var/lib/rspamd/dkim/2020.key > /var/lib/rspamd/dkim/2020.txt
    chown -R _rspamd:_rspamd /var/lib/rspamd/dkim
    chmod 440 /var/lib/rspamd/dkim/*
fi

#Set permissions for vmail
chown -R vmail:vmail /var/vmail


#while /bin/true; do
# sleep 60
#done

#start services
/usr/sbin/dovecot -c /etc/dovecot/dovecot.conf -F &
/usr/bin/rspamd -i -f &
#/usr/sbin/postfix start-fg
/usr/sbin/rsyslogd
/etc/init.d/postfix start
touch /var/log/mail.log
tail -f /var/log/mail.log


