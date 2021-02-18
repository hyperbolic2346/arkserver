## Thanks for the patience
As of 2021-02-18 :latest is stable and will stay that way. Changes will begin in :dev.  Please communicate any issues. Thanks, jkread.

# arkserver
```
Docker image for a dedicated ARK Server with arkmanager.
```

## Overview

This is an image for running an ARK: Survival Evolved server in a Docker container. It uses [FezVrasta](https://github.com/FezVrasta)'s [arkmanager](https://github.com/FezVrasta/ark-server-tools) (ark-server-tools) to managed a single-instance ARK: Survival Evolved server inside a docker container.

For more information on `arkmanager`, see the repo here: https://github.com/FezVrasta/ark-server-tools

### Features
* Automated install (pull the image and run, no additional commands necessary)
* Configuration via Environment Variables
* Easy crontab manipulation for automated backups, updates, daily restarts, weekly dino wipes, etc
* Simple volume structure for server files, config, logs, backups, etc
* Inherently includes all features present in `arkmanager`

### Tags
| Tag | Description |
|--|--|
| latest | stable build |
| dev | working build (not-stable) |

## Usage

### Installing the image

Pull the latest (or any other desired version):
```bash
docker pull jkread/arkserver:latest
```

### Running the server

To run a generic server with no configuration modifications:
```bash
$ docker run -d \
    -v steam:/home/steam \  # mounted so that workshop (mod) downloads are persisted
    -v ark:/ark \  # mounted as the directory to contain the server/backup/log/config files
    -p 27015:27015 -p 27015:27015/udp \  # steam query port
    -p 7778:7778 -p 7778:7778/udp \  # gameserver port
    -p 7777:7777 -p 7777:7777/udp \ # gameserver port
    jkread/arkserver
```
Docker compose sample (change or remove environment variables as the suit you):
```yaml
version: '3'
volumes:
  ark:
  steam:
services:
  ark:
    image: jkread/arkserver:latest
    container_name: ark
    network_mode: bridge
    restart: always
    ports:
      - 7777:7777
      - 7777:7777/udp
      - 7778:7778
      - 7778:7778/udp
      - 27015:27015
      - 27015:27015/udp
    volumes:
      - ark:/ark
      - steam:/home/steam
    environment:
      - TZ=America/Chicago
      - am_ark_SessionName=Ark Docker Session
      - am_serverMap=TheIsland
      - am_ark_ServerPassword=letmein
      - am_ark_ServerAdminPassword=pleasechangeme
      - am_ark_MaxPlayers=70
      - am_ark_QueryPort=27015
      - am_ark_Port=7778
      - am_ark_RCONPort=32330
      - am_arkwarnminutes=15
      - am_arkAutoUpdateOnStart=true
      - am_arkBackupPreUpdate=true
      - am_arkMaxBackupSizeMB=500
      - am_arkflag_crossplay=false
      - am_arkflag_NoBattlEye=true
      - am_ark_GameModIds=111111111,566885854,731604991,761535755,821530042,889745138,1404697612
```

If the exposed ports are modified (in the case of multiple containers/servers on the same host) the `arkmanager` config will need to be modified to reflect the change as well. This is required so that `arkmanager` can properly check the server status and so that the ARK server itself can properly publish its IP address and query port to steam.

## Environment Variables

A set of required environment variables have default values provided as part of the image:

| Variable | Value | Description |
| - | - | - |
| TZ | N/A | Timezone |
| am_ark_SessionName | `Ark Server` | Server name as it will show on the steam server list |
| am_serverMap | `TheIsland` | Game map to load |
| am_ark_ServerPassword | N/A | Server password to connect |
| am_ark_ServerAdminPassword | `k3yb04rdc4t` | Admin password to be used via ingame console or RCON |
| am_ark_MaxPlayers | `70` | Max concurrent players in the game |
| am_ark_QueryPort | `27015` | Steam query port (allows the server to show up on the steam list) |
| am_ark_Port | `7778` | Game server port (allows clients to connect to the server) |
| am_ark_RCONPort | `32330` | RCON port |
| am_arkwarnminutes | `15` | Number of minutes to wait/warn players before updating/restarting |
| am_arkflag_crossplay | `false` | Allow crossyplay with Players on Epic |
| am_arkAutoUpdateOnStart=true | - | - |
| am_arkBackupPreUpdate=true | - | - |
| am_arkMaxBackupSizeMB=500 | - | - |
| am_arkflag_crossplay | `false` | Allow crossyplay with Players on Epic |
| am_arkflag_NoBattleEye | `false` | Disable BattleEye  |
| am_ark_GameModIds | N/A | List of game mod ids, comma delimited |

### Adding Additional Variables

Any configuration value that is available via `arkmanager` can be set using an environment variable. This works by taking any environment variable on the container that is prefixed with `am_` and mapping it to the corresponding environment variable in the `arkmanager.cfg` file. 

For a complete list of configuration values available, please see [FezVrasta](https://github.com/FezVrasta)'s great documentation here: [arkmanager Configuration Files](https://github.com/FezVrasta/ark-server-tools#configuration-files)

## Volumes

This image has two main volumes that should be mounted as named volumes or host directories for the persistence of the server install and all related configuration files. More information on Docker volumes here: [Docker: Use Volumes](https://docs.docker.com/storage/volumes/)

| Path | Description |
| - | - |
| /home/steam | Directory of steam cache and other steamcmd-related files. Should be mounted so that mod installs are persisted between container runs/restarts |
| /ark | Directory that will contain the server files, config files, logs and backups. More information below |

### Subdirectories of /ark

Inside the `/ark` volume there are several directories containing server related files:

| Path | Description |
| - | - |
| /ark/backup | Location of the zipped backups genereated from the `arkmaanger backup` command. Compressed using bz2. |
| /ark/config | Location of server config files. You can place customized config files here. AllowedCheaterSteamIDs.txt, Engine.ini, Game.ini, GameUserSettings.ini, crontab |
| /ark/log | Location of the arkmanager and arkserver log files. |
| /ark/server | Location of the server installation performed by `steamcmd`. This will contain the ShooterGame directory and the actual server binaries. |
| /ark/staging | Default directory for staging game and mod updates. Can be changed using in `arkmanager.cfg` |

### GameUserSettings.ini

Example [GameUserSettings.ini](https://pastebin.com/Td24Ku2E)

Your GameUserSettings.ini must contain the following or it will be overwritten:

```
[/Script/ShooterGame.ShooterGameUserSettings]
Version=5
```
