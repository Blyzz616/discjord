#! /bin/bash

SCRIPTSTART=$(date +%s)

HOOK=WEBHOOK
STEAMID=""
#CHARNAME=""
JOINLOG=/var/log/valheim/join.log

# File containing all the colours we use in discord
source /opt/discjord/colours.dec

# Get World Name
WORLD=$(grep world /tmp/valheim_log.txt | tail -n1 | awk '{print $NF}' | sed -e 's/(//' | sed -e 's/)//')

# This should only run once, when the SCRIPT is started (before the server comes online)
date +%s > /opt/discjord/times/srvr.up

VALUP(){
    TITLE="Server $WORLD Online"
    RISETIME=$(( (date +%s) - "$SCRIPTSTART") ))
    MESSAGE="$WORLD took $RISETIME to come online."
    curl -H "Content-Type: application/json" -X POST -d "{\"embeds\": [{ \"color\": \"$GREEN\", \"title\": \"$TITLE\", \"description\": \"$MESSAGE\" }] }" $URL
}

VALDOWN(){

}

JOIN(){
    LOGINNAME=""
    STEAMLINK="https://steamcommunity.com/profiles/$STEAMID"
    [[ ! -d /opt/discjord/playerdb/html/ ]] && mkdir -p /opt/discjord/playerdb/html/
    wget -qO /opt/discjord/playerdb/html/"STEAMID".html "$STEAMLINK"
    #get Steam Username
    STEAMNAME=$(grep -E '<title>' /opt/discjord/playerdb/html/"$STEAMID".html | awk -F":" '{print $3}' | xargs | awk -F"<" '{print $1}')
    # get image extension
    # some profiles have backgrounds, if they do, then we need to modify the code to ignore them
    if grep -q 'has_profile_background' /opt/discjord/playerdb/html/"$STEAMID".html; then
      IMGEXT=$(grep -E -A4 'playerAvatarAutoSizeInner' /opt/discjord/playerdb/html/"$STEAMID".html | tail -n1 | awk -F'"' '{print $2}' | awk -F. '{print $NF}')
      # get image link
      IMGNAME=$(grep -A4 'playerAvatarAutoSizeInner' /opt/discjord/playerdb/html/"$STEAMID".html | tail -n1 | awk -F'"' '{print $2}')
    else
      IMGEXT=$(grep -A1 'playerAvatarAutoSizeInner' /opt/discjord/playerdb/html/"$STEAMID".html | tail -n1 | awk -F'"' '{print $2}' | awk -F. '{print $NF}')
      # get image link
      IMGNAME=$(grep -A1 'playerAvatarAutoSizeInner' /opt/discjord/playerdb/html/"$STEAMID".html | tail -n1 | awk -F'"' '{print $2}')
    fi

   # get hours played
    HRS=$(grep -B2 -E 'Valheim' /opt/discjord/playerdb/html/"$STEAMID".html | grep -E 'on record' | grep -o -E '[0-9,]*')
    DATE=$(date +%Y-%m-%d\ %H:%M:%S)

    # Lets get other games from steam (NAME is game name LAST is last played, HRS is hours in that game)
    OGAMENAME1=$(grep -E -A4 "\"game_capsule\""    /opt/discjord/playerdb/html/"$STEAMID".html | grep -v 108600 | grep -E "whiteLink" | head -n1 | xargs | sed 's/.*app\/[0-9]*>//'    | rev | cut -c12- | rev)
    OGAMENAME2=$(grep -E -A4 "\"game_capsule\""    /opt/discjord/playerdb/html/"$STEAMID".html | grep -v 108600 | grep -E "whiteLink" | tail -n1 | xargs | sed 's/.*app\/[0-9]*>//'    | rev | cut -c12- | rev)
    if [[ $(grep -E -A4 "\"game_capsule\""    /opt/discjord/playerdb/html/"$STEAMID".html | grep -v 108600 | sed 's/^\s*//' | tail -n10 | grep -o -E 'last.*'| head -n1 | rev | cut -c9- | rev | sed 's/ on/:/' | s
ed 's/.*/\u&/' | xargs | awk '{print $3 " " $4}') = $(date +%d" "%b) ]]; then
        OGAMELAST1="Last played: Today"
    elif [[ $(grep -E -A4 "\"game_capsule\""    /opt/discjord/playerdb/html/"$STEAMID".html | grep -v 108600 | sed 's/^\s*//' | tail -n10 | grep -o -E 'last.*'| head -n1 | rev | cut -c9- | rev | sed 's/ on/:/' |
 sed 's/.*/\u&/' | xargs | awk '{print $3 " " $4}') = $(date -d "yesterday" +%d" "%b) ]]; then
        OGAMELAST1="Last played: Yesterday"
    else
        OGAMELAST1=$(grep -E -A4 "\"game_capsule\""    /opt/discjord/playerdb/html/"$STEAMID".html | grep -v 108600 | sed 's/^\s*//' | tail -n10 | grep -o -E 'last.*'| head -n1 | rev | cut -c9- | rev | sed 's/ on/
:/' | sed 's/.*/\u&/' | xargs)
    fi
    if [[ $(grep -E -A4 "\"game_capsule\""    /opt/discjord/playerdb/html/"$STEAMID".html | grep -v 108600 | sed 's/^\s*//' | tail -n10 | grep -o -E 'last.*'| tail -n1 | rev | cut -c9- | rev | sed 's/ on/:/' | s
ed 's/.*/\u&/' | xargs) = $(date +%d" "%b) ]]; then
        OGAMELAST2="Last played: Today"
    elif [[ $(grep -E -A4 "\"game_capsule\""    /opt/discjord/playerdb/html/"$STEAMID".html | grep -v 108600 | sed 's/^\s*//' | tail -n10 | grep -o -E 'last.*'| tail -n1 | rev | cut -c9- | rev | sed 's/ on/:/' |
 sed 's/.*/\u&/' | xargs) = $(date -d "yesterday" +%d" "%b) ]]; then
        OGAMELAST2="Last played: Yesterday"
    else
        OGAMELAST2=$(grep -E -A4 "\"game_capsule\""    /opt/discjord/playerdb/html/"$STEAMID".html | grep -v 108600 | sed 's/^\s*//' | tail -n10 | grep -o -E 'last.*'| tail -n1 | rev | cut -c9- | rev | sed 's/ on/
:/' | sed 's/.*/\u&/' | xargs)
    fi
    OGAMEHRS1=$(grep -E -A4 "\"game_capsule\""    /opt/discjord/playerdb/html/"$STEAMID".html | grep -v 108600 | sed 's/^\s*//' | tail -n10 | grep -o -E '.*ord' | head -n1)
    OGAMEHRS2=$(grep -E -A4 "\"game_capsule\""    /opt/discjord/playerdb/html/"$STEAMID".html | grep -v 108600 | sed 's/^\s*//' | tail -n10 | grep -o -E '.*ord' | tail -n1)

    # lets keep a record of who joins the server
    touch /opt/discjord/playerdb/users.log /opt/discjord/playerdb/access.log /opt/discjord/playerdb/denied.log

#    if [[ $(wc -l /opt/discjord/playerdb/users.log) -eq 0 ]]; then
     if [[ $(wc -l < /opt/discjord/playerdb/users.log) -eq 0 ]]; then
        echo -e 'FIRST SEEN\tSTEAMID\tSTEAM-NAME\tIP ADDRESS\tlogin\tIMAGE NAME\tIMAGE LINK' > /opt/discjord/playerdb/users.log
    fi

    echo "$(date +%Y-%m-%d\ %H:%M:%S) - Steam user $STEAMNAME ($STEAMLINK) attempted connection" >> /opt/discjord/playerdb/access.log



    if [[ -z "$OGAMENAME2" ]]; then
            if [[ -z "$OGAMENAME1" ]]; then
                if [[ -z $HRS ]]; then
                    if [[ -z $PING ]]; then
                        curl -H "Content-Type: application/json" -X POST -d "{\"embeds\": [{ \"color\": \"$PURPLE\", \
                        \"title\": \"New connection:\", \
                        \"description\": \"Steam Profile: [$STEAMNAME]($STEAMLINK)\\nLogging in as **$LOGINNAME**\\nFrom: $GEOIP\", \
                        \"thumbnail\": { \"url\": \"$IMGNAME\"}}]}" $URL
                    else
                            curl -H "Content-Type: application/json" -X POST -d "{\"embeds\": [{ \"color\": \"$PURPLE\", \
                            \"title\": \"New connection:\", \
                            \"description\": \"Steam Profile: [$STEAMNAME]($STEAMLINK)\\nLogging in as **$LOGINNAME**\\nFrom: $GEOIP\\nPing: $PING\", \
                            \"thumbnail\": { \"url\": \"$IMGNAME\"}}]}" $URL
                    fi
                else
                    if [[ -z $PING ]]; then
                        curl -H "Content-Type: application/json" -X POST -d "{\"embeds\": [{ \"color\": \"$PURPLE\", \
                        \"title\": \"New connection:\", \
                        \"description\": \"Steam Profile: [$STEAMNAME]($STEAMLINK)\\nLogging in as **$LOGINNAME**\\nFrom: $GEOIP\", \
                        \"fields\": [{\"name\": \"Hours on Record:\", \
                        \"value\": \"$HRS\", \
                        \"inline\": false}], \
                        \"thumbnail\": { \"url\": \"$IMGNAME\"}}]}" $URL
                    else
                        curl -H "Content-Type: application/json" -X POST -d "{\"embeds\": [{ \"color\": \"$PURPLE\", \
                        \"title\": \"New connection:\", \
                        \"description\": \"Steam Profile: [$STEAMNAME]($STEAMLINK)\\nLogging in as **$LOGINNAME**\\nFrom: $GEOIP\\nPing: $PING\", \
                        \"fields\": [{\"name\": \"Hours on Record:\", \
                        \"value\": \"$HRS\", \
                        \"inline\": false}], \
                        \"thumbnail\": { \"url\": \"$IMGNAME\"}}]}" $URL
                    fi
                fi
            else
                if [[ -z $PING ]]; then
                    curl -H "Content-Type: application/json" -X POST -d "{\"embeds\": [{ \"color\": \"$PURPLE\", \
                    \"title\": \"New connection:\", \
                    \"description\": \"Steam Profile: [$STEAMNAME]($STEAMLINK)\\nLogging in as **$LOGINNAME**\\nFrom: $GEOIP\", \
                    \"fields\": [{\"name\": \"Hours on Record:\", \
                    \"value\": \"$HRS\", \
                    \"inline\": false}, \
                    {\"name\": \"\u200b\", \
                    \"value\": \"\u200b\", \
                    \"inline\": false}, \
                    {\"name\": \"$STEAMNAME has also played:\", \
                    \"value\": \"\", \
                    \"inline\": false}, \
                    {\"name\": \"$OGAMENAME1\", \
                    \"value\": \"$OGAMEHRS1 \\n $OGAMELAST1\", \
                    \"inline\": true}], \
                    \"thumbnail\": { \"url\": \"$IMGNAME\"}}]}" $URL
                else
                    curl -H "Content-Type: application/json" -X POST -d "{\"embeds\": [{ \"color\": \"$PURPLE\", \
                    \"title\": \"New connection:\", \
                    \"description\": \"Steam Profile: [$STEAMNAME]($STEAMLINK)\\nLogging in as **$LOGINNAME**\\nFrom: $GEOIP\\nPing: $PING\", \
                    \"fields\": [{\"name\": \"Hours on Record:\", \
                    \"value\": \"$HRS\", \
                    \"inline\": false}, \
                    {\"name\": \"\u200b\", \
                    \"value\": \"\u200b\", \
                    \"inline\": false}, \
                    {\"name\": \"$STEAMNAME has also played:\", \
                    \"value\": \"\", \
                    \"inline\": false}, \
                    {\"name\": \"$OGAMENAME1\", \
                    \"value\": \"$OGAMEHRS1 \\n $OGAMELAST1\", \
                    \"inline\": true}], \
                    \"thumbnail\": { \"url\": \"$IMGNAME\"}}]}" $URL
                fi
            fi
    else
        if [[ -z $PING ]]; then
            curl -H "Content-Type: application/json" -X POST -d "{\"embeds\": [{ \"color\": \"$PURPLE\", \
            \"title\": \"New connection:\", \
            \"description\": \"Steam Profile: [$STEAMNAME]($STEAMLINK)\\nLogging in as **$LOGINNAME**\\nFrom: $GEOIP\", \
            \"fields\": [{\"name\": \"Hours on Record:\", \
            \"value\": \"$HRS\", \
            \"inline\": false}, \
            {\"name\": \"\u200b\", \
            \"value\": \"\u200b\", \
            \"inline\": false}, \
            {\"name\": \"$STEAMNAME has also played:\", \
            \"value\": \"\", \
            \"inline\": false}, \
            {\"name\": \"$OGAMENAME1\", \
            \"value\": \"$OGAMEHRS1 \\n $OGAMELAST1\", \
            \"inline\": true}, \
            {\"name\": \"\u200b\", \
            \"value\": \"\u200b\", \
            \"inline\": true}, \
            {\"name\": \"$OGAMENAME2\", \
            \"value\": \"$OGAMEHRS2 \\n $OGAMELAST2\", \
            \"inline\": true}], \
            \"thumbnail\": { \"url\": \"$IMGNAME\"}}]}" $URL
        else
            curl -H "Content-Type: application/json" -X POST -d "{\"embeds\": [{ \"color\": \"$PURPLE\", \
            \"title\": \"New connection:\", \
            \"description\": \"Steam Profile: [$STEAMNAME]($STEAMLINK)\\nLogging in as **$LOGINNAME**\\nFrom: $GEOIP\\nPing: $PING\", \
            \"fields\": [{\"name\": \"Hours on Record:\", \
            \"value\": \"$HRS\", \
            \"inline\": false}, \
            {\"name\": \"\u200b\", \
            \"value\": \"\u200b\", \
            \"inline\": false}, \
            {\"name\": \"$STEAMNAME has also played:\", \
            \"value\": \"\", \
            \"inline\": false}, \
            {\"name\": \"$OGAMENAME1\", \
            \"value\": \"$OGAMEHRS1 \\n $OGAMELAST1\", \
            \"inline\": true}, \
            {\"name\": \"\u200b\", \
            \"value\": \"\u200b\", \
            \"inline\": true}, \
            {\"name\": \"$OGAMENAME2\", \
            \"value\": \"$OGAMEHRS2 \\n $OGAMELAST2\", \
            \"inline\": true}], \
            \"thumbnail\": { \"url\": \"$IMGNAME\"}}]}" $URL
        fi
    fi

    # check to see if we have a record of the user, if not, add to users.log and save image.
    if [[ $(grep -c -E "$STEAMID" /opt/discjord/playerdb/users.log) -eq 0 ]]; then
        echo -e "$DATE\t$STEAMID\t$STEAMNAME\t$CONNIP\t$LOGINNAME\t$STEAMNAME.$IMGEXT\t$IMGNAME" >> /opt/discjord/playerdb/users.log
        # format is:
        # FIRST SEEN                        STEAMID                                 STEAM NAME            IP ADDRESS            login     IMAGE NAME            IMAGE LINK
        # e.g.
        # 2023-08-21 16:25:21     76561198058880519             Blyzz.com             192.168.0.33        blyzz     Blyzz.com.gif
        # If they're not in the users log, they're not in the alias log - add that too
        echo -e "$STEAMID\t$LOGINNAME" >> /opt/discjord/playerdb/alias.log
    else
        if [[ $(grep -c -E "$LOGINNAME" /opt/discjord/playerdb/alias.log) -eq 0 ]]; then
            # Ok, so we've got a record of the user in users.log, but no alternate aliases in alias.log so lets save the new username
            # format is:
            # STEAMID                                 FIRST                     OTHERS
            # e.g.
            # 76561198058880519             Blyzz                     blyzz-test                blyzz-2
            sed -i -E "/^$STEAMID/ s/$/\t$LOGINNAME/" /opt/discjord/playerdb/alias.log
        fi
    fi
    STEAMID=""  
}

QUIT(){

}

OBIT(){

}

UPDATE(){

}

READER(){
    tail -Fn0 /tmp/valheim_log.txt 2> /dev/null | \
    while read -r LINE ; do
        SRVRUP=$(echo "$LINE" | grep -oE 'Game server connected')
        STEAMID=$(echo "$LINE" | grep -oE 'SteamID\s[0-9]+$' | awk '{print $2}')
        CHARNAME=$(echo "$LINE" | grep -oE 'orange>\S+' /tmp/valheim_log.txt | cut -d'>' -f2 | cut -d'<' -f1)
        [[ $SRVRUP ]] && VALUP
        [[ $CHARNAME ]] && JOIN
    done
}

READER


# There might be a problem with this becuase of the time difference
#SteamID
#04/10/2024 16:21:23: Got connection SteamID 76561198058880519
#04/10/2024 16:21:23: Got handshake from client 76561198058880519
#that's a whole 19 seconds! fuck
#04/10/2024 16:21:52: Network version check, their:23, mine:23
#04/10/2024 16:21:52: Server: New peer connected,sending global keys
# THAT'S A WHOLE 50 SECONDS WTF
#Playername
#04/10/2024 16:22:13: Got character ZDOID from Astrid : -136624608:6



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


