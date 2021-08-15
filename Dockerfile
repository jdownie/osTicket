FROM ubuntu:20.04
MAINTAINER James Downie <jdownie@gmail.com>

ARG OSTICKET_VERSION

ENV TZ="Australia/Brisbane"
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt update && apt install -y git php php-cli apache2 php-mysql php-imap php-xml php-mbstring php-intl php-apcu php-gd sendmail

WORKDIR /
COPY setup setup
RUN chmod +x setup
RUN ./setup

COPY osticket.conf /etc/apache2/sites-available/osticket.conf
RUN /usr/sbin/a2enmod rewrite
RUN /usr/sbin/a2enmod md
RUN /usr/sbin/a2enmod ssl
RUN /usr/sbin/a2dissite 000-default
RUN /usr/sbin/a2ensite osticket

COPY entrypoint /entrypoint
RUN chmod +x /entrypoint
WORKDIR /osTicket
CMD [ "/entrypoint" ]
