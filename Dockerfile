FROM alpine:latest as builder
#FROM alpine:3.15.5 as builder
# additional files
##################

RUN apk add bash util-linux tmux curl python3 py3-pip moreutils grep supervisor openvpn drill dumb-init tini jq coreutils git openrc iptables shadow su-exec nginx ca-certificates php php-fpm php-json nodejs npm ffmpeg sox unzip mktorrent xmlrpc-c libtorrent rtorrent

ADD build/supervisor.conf /etc/

# grabbed from his github repo:
# curl --connect-timeout 5 --max-time 600 --retry 5 --retry-delay 0 --retry-max-time 60 -o /tmp/scripts-master.zip -L https://github.com/binhex/scripts/archive/master.zip
ADD build/docker/*.sh /usr/local/bin/


# add install bash script
ADD build/root/*.sh /root/

# add bash script to run openvpn
ADD run/root/*.sh /root/

# add bash script to run privoxy
ADD run/nobody/*.sh /home/nobody/

# docker settings
#################

# expose port for privoxy
EXPOSE 8118


FROM builder

RUN apk add openssl py3-chardet py3-dbus py3-distro py3-idna py3-mako py3-pillow py3-openssl py3-rencode py3-service_identity py3-setproctitle py3-six py3-future py3-requests py3-twisted py3-xdg py3-zope-interface xdg-utils libappindicator libseccomp
RUN pip3 install python-geoip-python3



# add supervisor conf file for app
ADD build/*.conf /etc/supervisor/conf.d/

# add bash scripts to install app
ADD build/root/*.sh /root/

# get release tag name from build arg
## not using right now to reduce complexity.
#ARG release_tag_name

# add bash script to run rtorrent
ADD run/nobody/*.sh /home/nobody/

# add pre-configured config files for rtorrent
ADD config/nobody/ /home/nobody/

# install app
#############

RUN npm install --global flood

# docker settings
#################


# expose port for scgi
EXPOSE 5000

# expose port for Flood
EXPOSE 9080

# expose port for Flood https
EXPOSE 9443

# expose port for privoxy
EXPOSE 8118

# expose port for incoming connections (used only if vpn disabled)
EXPOSE 49160

# expose port for dht udp (used only if vpn disabled)
EXPOSE 49170



ENTRYPOINT ["/usr/bin/dumb-init", "--"]


# make executable and run bash scripts to install app
RUN chmod +x /root/*.sh /home/nobody/*.sh && \
	/bin/bash /root/install.sh "0.1"

# run script to set uid, gid and permissions
CMD ["/bin/bash", "/usr/local/bin/init.sh"]
