#! /bin/bash

SCRIPTSTART=$(date +%s)

HOOK=WEBHOOK

# File containing all the colours we use in discord
source /opt/discjord/colours.dec

# Get World Name
WORLD=$(grep world /tmp/valheim_log.txt | tail -n1 | awk '{print $NF}' | sed -e 's/(//' | sed -e 's/)//')

# This should only run once, when the SCRIPT is started (before the server comes online)
date +%s > /opt/discjord/times/srvr.up

VALUP(){

}

VALDOWN(){

}

JOIN(){

}

QUIT(){

}

OBIT(){

}

READER(){
    tail -Fn0 /tmp/valheim_log.txt 2> /dev/null | \
    while read -r LINE ; do
      SRVRUP=$(echo "$LINE" | grep -Ec 'Game server connected')



      if [[ $SRVRUP -eq 1 ]]; then
        TITLE="Server $WORLD Online"
        RISETIME=$(( (date +%s) - "$SCRIPTSTART") ))
        MESSAGE="$WORLD took $RISETIME to come online."
        curl -H "Content-Type: application/json" -X POST -d "{\"embeds\": [{ \"color\": \"$LIME\", \"title\": \"$TITLE\", \"description\": \"$MESSAGE\" }] }" $URL
      fi
    done
}

READER


#Game Server Up:
#04/10/2024 16:20:54: Game server connected
#Pre-Password
#04/10/2024 16:12:12: Got connection SteamID 76561198058880519
#04/10/2024 16:12:12: Got handshake from client 76561198058880519
#incompatible verison
#04/10/2024 16:12:49: Network version check, their:23, mine:20
#04/10/2024 16:12:49: Peer 76561198058880519 has incompatible version, mine:0.217.38 (network version 20)   remote 0.217.46 (network version 23)
#04/10/2024 16:12:49: RPC_Disconnect
#04/10/2024 16:12:49: Disposing socket
#04/10/2024 16:12:49: Closing socket 76561198058880519
#04/10/2024 16:12:49:   send queue size:0
#04/10/2024 16:12:49: Disposing socket
#04/10/2024 16:12:49: Got status changed msg k_ESteamNetworkingConnectionState_ClosedByPeer
#04/10/2024 16:12:49: Socket closed by peer Steamworks.SteamNetConnectionStatusChangedCallback_t
#04/10/2024 16:12:49: Got status changed msg k_ESteamNetworkingConnectionState_None
#Password entered
#04/10/2024 16:21:52: Network version check, their:23, mine:23
#04/10/2024 16:21:52: Server: New peer connected,sending global keys
#Character laoded:
#04/10/2024 16:22:13: Got character ZDOID from Astrid : -136624608:6
#04/10/2024 16:22:13: Console: <color=orange>Astrid</color>: <color=#FFEB04FF>I HAVE ARRIVED!</color>
#Character died:
#04/10/2024 16:25:45: Got character ZDOID from Astrid : 0:0
#04/10/2024 16:25:53: Got character ZDOID from Astrid : -136624608:739
#Update od some sort:
#04/10/2024 16:50:49: Available space to current user: 18160762880. Saving is blocked if below: 23887002 bytes. Warnings are given if below: 47774004
#04/10/2024 16:50:49: Sending message to save player profiles
#04/10/2024 16:50:49: Sent to 76561198058880519
#04/10/2024 16:50:50: PrepareSave: clone done in 49ms
#04/10/2024 16:50:50: PrepareSave: ZDOExtraData.PrepareSave done in 58 ms
#04/10/2024 16:50:50: World save writing starting
#04/10/2024 16:50:50: World save writing started
#04/10/2024 16:50:50: Saved 214962 ZDOs
#04/10/2024 16:50:50: World save writing finishing
#04/10/2024 16:50:50: World save writing finished
#04/10/2024 16:50:51: World saved ( 925.4ms )
#04/10/2024 16:50:51: Considering autobackup. World time: 1796.48, short time: 7200, long time: 43200, backup count: 4
#04/10/2024 16:50:51: No autobackup needed yet...
#Am I Host? True
#04/10/2024 16:50:54:  Connections 1 ZDOS:214972  sent:0 recv:553
#Disconnect
#04/10/2024 17:00:14: RPC_Disconnect
#04/10/2024 17:00:14: Destroying abandoned non persistent zdo -136624608:739 owner -136624608
#04/10/2024 17:00:14: Destroying abandoned non persistent zdo -136624608:2108 owner -136624608
#04/10/2024 17:00:14: Destroying abandoned non persistent zdo -136624608:4795 owner -136624608
#04/10/2024 17:00:14: Destroying abandoned non persistent zdo -136624608:4735 owner -136624608
#04/10/2024 17:00:14: Destroying abandoned non persistent zdo -136624608:4036 owner -136624608
#04/10/2024 17:00:14: Destroying abandoned non persistent zdo -136624608:4438 owner -136624608
#04/10/2024 17:00:14: Destroying abandoned non persistent zdo -136624608:2107 owner -136624608
#04/10/2024 17:00:14: Destroying abandoned non persistent zdo -136624608:2110 owner -136624608
#04/10/2024 17:00:14: Destroying abandoned non persistent zdo -136624608:4035 owner -136624608
#04/10/2024 17:00:14: Destroying abandoned non persistent zdo -136624608:2130 owner -136624608
#04/10/2024 17:00:14: Destroying abandoned non persistent zdo -136624608:4794 owner -136624608
#04/10/2024 17:00:14: Destroying abandoned non persistent zdo -136624608:4796 owner -136624608
#04/10/2024 17:00:14: Destroying abandoned non persistent zdo -136624608:4793 owner -136624608
#04/10/2024 17:00:14: Destroying abandoned non persistent zdo -136624608:2109 owner -136624608
#04/10/2024 17:00:14: Destroying abandoned non persistent zdo -136624608:4788 owner -136624608
#04/10/2024 17:00:14: Disposing socket
#04/10/2024 17:00:14: Closing socket 76561198058880519
#04/10/2024 17:00:14:   send queue size:0
#04/10/2024 17:00:15: Disposing socket
#04/10/2024 17:00:15: Got status changed msg k_ESteamNetworkingConnectionState_ClosedByPeer
#04/10/2024 17:00:15: Socket closed by peer Steamworks.SteamNetConnectionStatusChangedCallback_t
#04/10/2024 17:00:15: Got status changed msg k_ESteamNetworkingConnectionState_None

