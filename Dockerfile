FROM resin/rpi-raspbian
MAINTAINER Gavin Adam <gavinadam80@gmail.com>

RUN apt-get update && apt-get install -y \
	build-essential libgd2-xpm-dev openssl \
	libssl-dev xinetd apache2-utils apache2 unzip php5 wget ca-certificates \
	--no-install-recommends && \
	apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN useradd nagios && \
	mkdir /home/nagios && \
	chown nagios:nagios /home/nagios && \
	groupadd nagcmd && \
	usermod -a -G nagcmd nagios

WORKDIR /opt/

RUN wget https://assets.nagios.com/downloads/nagioscore/releases/nagios-4.1.1.tar.gz && \
	tar xzvf nagios-4.1.1.tar.gz

WORKDIR /opt/nagios-4.1.1

RUN ./configure --with-nagios-group=nagios --with-command-group=nagcmd --with-httpd-conf=/etc/apache2/conf-available && \
	make all && \
	make install && \
	make install-commandmode && \
	make install-init && \
	make install-config && \
	/usr/bin/install -c -m 644 sample-config/httpd.conf /etc/apache2/sites-available/nagios.conf && \
	usermod -G nagcmd www-data && \
	ln -s /etc/init.d/nagios /etc/rcS.d/S99nagios

WORKDIR /opt/

RUN wget http://www.nagios-plugins.org/download/nagios-plugins-2.1.1.tar.gz && \
	tar xvf nagios-plugins-2.1.1.tar.gz

WORKDIR /opt/nagios-plugins-2.1.1

RUN ./configure --with-nagios-user=nagios --with-nagios-group=nagios && \
	make && \
	make install && \
	a2enmod rewrite && \
	a2enmod cgi && \
	htpasswd -c /usr/local/nagios/etc/htpasswd.users nagiosadmin && \
	a2ensite nagios && \
	/etc/init.d/apache2 restart

VOLUME /usr/local/nagios/var
VOLUME /usr/local/nagios/etc
VOLUME /usr/local/nagios/libexec
VOLUME /var/log/apache2

EXPOSE 80

CMD [ "/bin/bash" ]
