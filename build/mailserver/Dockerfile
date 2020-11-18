FROM debian:buster

#Volume for SSL-Certs
VOLUME /etc/ssl-cert

#vmail-Benutzer und -Verzeichnis einrichten
RUN useradd --create-home --home-dir /var/vmail --user-group --shell /usr/sbin/nologin vmail && \
mkdir /var/vmail/mailboxes && \
mkdir -p /var/vmail/sieve/global && \
chown -R vmail /var/vmail && \
chgrp -R vmail /var/vmail && \
chmod -R 770 /var/vmail
VOLUME /var/vmail

#Dovecot installieren und konfigurieren
RUN apt-get update && \
apt install -y \
dovecot-core \
dovecot-imapd \
dovecot-lmtpd \
dovecot-mysql \
dovecot-sieve \
dovecot-managesieved && \
rm -rf /var/lib/apt/lists/*

RUN rm -r /etc/dovecot/*
COPY dovecot/*.conf /etc/dovecot/

#Spam Learning mit Rspamd
COPY sieve/*.sieve /var/vmail/sieve/global/

#Postfix installieren und konfigurieren
RUN apt-get update && \
apt install -y \
rsyslog \
postfix \
postfix-mysql && \
rm -rf /var/lib/apt/lists/*

RUN rm -r /etc/postfix/sasl && rm /etc/postfix/master.cf  /etc/postfix/main.cf.proto  /etc/postfix/master.cf.proto
COPY postfix/ /etc/postfix/


#Rspamd installieren und konfigurieren
RUN apt-get update && \
apt install -y \
lsb-release \
gnupg \
wget && \
rm -rf /var/lib/apt/lists/*

RUN wget -O- https://rspamd.com/apt-stable/gpg.key | apt-key add - && \
    echo "deb http://rspamd.com/apt-stable/ $(lsb_release -c -s) main" > /etc/apt/sources.list.d/rspamd.list && \
    echo "deb-src http://rspamd.com/apt-stable/ $(lsb_release -c -s) main" >> /etc/apt/sources.list.d/rspamd.list && \
    apt-get update && apt-get install -y \
    rspamd redis-server && \
rm -rf /var/lib/apt/lists/*

COPY rspamd/ /etc/rspamd/
VOLUME /var/lib/rspamd/dkim/



COPY start.sh /start.sh
RUN chmod +x start.sh
CMD /start.sh






