FROM ubuntu:xenial

USER root

RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y curl cron bzip2 perl-modules lsof libc6-i386 lib32gcc1 sudo tzdata && \
    echo steam steam/question select "I AGREE" | debconf-set-selections && \
    echo steam steam/license note '' | debconf-set-selections && \
    apt-get install -y ca-certificates steamcmd language-pack-en

RUN ln -s /usr/games/steamcmd /usr/local/bin && \
    adduser --gecos "" --disabled-password steam

RUN curl -sL https://git.io/arkmanager | bash -s steam && \
    ln -s /usr/local/bin/arkmanager /usr/bin/arkmanager

RUN mkdir /ark && \
    mkdir /arkserver
    
COPY arkmanager/arkmanager.cfg /etc/arkmanager/arkmanager.cfg
COPY arkmanager/instance.cfg /etc/arkmanager/instances/main.cfg
COPY arkserver.sh /arkserver/arkserver.sh
COPY log.sh /arkserver/log.sh

RUN chown -R steam:steam /home/steam /ark /arkserver && chmod -R 777 /root /arkserver

RUN echo "%sudo   ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers && \
    usermod -a -G sudo steam && \
    touch /home/steam/.sudo_as_admin_successful

WORKDIR /home/steam
USER steam

RUN steamcmd +quit

ENV am_ark_SessionName="Ark Server" \
    am_serverMap="TheIsland" \
    am_ark_ServerAdminPassword="k3yb04rdc4t" \
    am_ark_MaxPlayers=70 \
    am_ark_QueryPort=27015 \
    am_ark_Port=7778 \
    am_ark_RCONPort=32330 \
    am_ark_AltSaveDirectoryName=SavedArks \
    am_arkwarnminutes=15 \
    am_arkAutoUpdateOnStart=false \
    VALIDATE_SAVE_EXISTS=false \
    BACKUP_ONSTART=false \
    LOG_RCONCHAT=0 \
    ARKCLUSTER=false
    UID=1000 \
    GID=1000

# only mount the steamapps directory
VOLUME /home/steam/.steam/steamapps
VOLUME /ark
# optionally shared volumes between servers in a cluster
VOLUME /arkserver
# mount /arkserver/ShooterGame/Saved seperate for each server
# mount /arkserver/ShooterGame/Saved/clusters shared for all servers

CMD [ "/arkserver/arkserver.sh" ]
