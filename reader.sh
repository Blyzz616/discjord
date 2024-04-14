#! /bin/bash

# This should only run once, when the SCRIPT is started (before the server comes online)
date +%s > /opt/discjord/times/srvr.up

#CURRENTUSER=$(whoami)

SCRIPTSTART=$(date +%s)

HOOK="<!WEBHOOK-REPLACE ME!>"
STEAMID=""
CHARNAME=""
STEAMNAME=""
WORKINGDIR=/opt/discjord
PLAYERDBDIR="$WORKINGDIR"/playerdb
JOINLOG="$PLAYERDBDIR"/join.log
USERLOG="$PLAYERDBDIR"/users.log
HTMLDIR="$PLAYERDBDIR"/html
MASTERLIST="$PLAYERDBDIR"/masterlist.db
TIMES="$WORKINGDIR"/times
DEATH=""
VER=""
# Get World Name
WORLD=$(grep world /tmp/valheim_log.txt | tail -n1 | awk '{print $NF}' | sed -e 's/(//' | sed -e 's/)//')

# File containing all the colours we use in discord
source /opt/discjord/colours.dec

VALUP(){
    TITLE="Server $WORLD Online"
    WORLDUP=$(date +%s)
    RISETIME=$(( "$WORLDUP" - "$SCRIPTSTART" ))
    $WORLDUP > "$TIMES"/"$WORLD".up
    MESSAGE="$WORLD took $RISETIME to come online."
    curl -H "Content-Type: application/json" -X POST -d "{\"embeds\": [{ \"color\": \"$GREEN\", \"title\": \"$TITLE\", \"description\": \"$MESSAGE\" }] }" "$HOOK"
}

VALDOWN(){
    DOWNTIME=$(date +%s)
    UPTIME=$(cat "$TIMES"/"$WORLD".up)
    ONLINETIME=$(( "$DOWNTIME" - "$UPTIME" ))
    TITLE="Server $WORLD offline"
    if [[ "$ONLINETIME" -ge 604800 ]]; then
        LIFE=$(printf '%dw %dd %dh %dm %ds' $((TOTAL/604800)) $((TOTAL/86400)) $((TOTAL%86400/3600)) $((TOTAL%3600/60)) $((TOTAL%60)))
    elif [[ "$ONLINETIME" -ge 86400 ]]; then
        LIFE=$(printf '%dd %dh %dm %ds' $((TOTAL/86400)) $((TOTAL%86400/3600)) $((TOTAL%3600/60)) $((TOTAL%60)))
    elif [[ "$ONLINETIME" -ge 3600  ]]; then
        LIFE=$(printf '%dh %dm %ds' $((TOTAL/3600)) $((TOTAL%3600/60)) $((TOTAL%60)))
    elif [[ "$ONLINETIME" -ge 60 ]]; then
        LIFE=$(printf '%dm %ds' $((TOTAL/60)) $((TOTAL%60)))
    else
        LIFE=$(printf '%ds' $((GAMETIME)))
    fi
    MESSAGE="$WORLD was online for $LIFE"
    curl -H "Content-Type: application/json" -X POST -d "{\"embeds\": [{ \"color\": \"$RED\", \"title\": \"$TITLE\", \"description\": \"$MESSAGE\" }] }" "$HOOK"
}

GETSTEAMNAME(){
    STEAMLINK="https://steamcommunity.com/profiles/$STEAMID"
    echo "$DATE - Steam Link set to $STEAMLINK" >> "$JOINLOG"
    [[ ! -d "$HTMLDIR"/ ]] && mkdir -p "$HTMLDIR"/
    wget -qO "$HTMLDIR"/"$STEAMID".html "$STEAMLINK"
    # get Steam Username
    STEAMNAME=$(grep -E '<title>' "$HTMLDIR"/"$STEAMID".html | awk -F":" '{print $3}' | xargs | awk -F"<" '{print $1}')
    echo "$DATE - Steam Name set to $STEAMNAME" > "$JOINLOG"
    return "$STEAMNAME"
}

ADDPLAYER(){
    # This is only called when the STEAMID does not exist in the masterlist
    # Adding Row for STEAMID:
    #Check that we've got a masterlist
    [[ ! -d "$PLAYERDBDIR" ]] && mkdir -p "$PLAYERDBDIR"
    [[ ! -f "$MASTERLIST" ]] && touch "$MASTERLIST"; echo -e "PLAYERID\tSTEAMID\tFIRSTSEEN\tSTEAMNAME\tPLAYERNAME" > $MASTERLIST
    # Check if there's a player in the Masterlist, if not, set value to 0 else set value to last PLAYERID
    [[ $(wc -l "$MASTERLIST") -lt 2 ]] && INCREMENTME=0 || INCREMENTME=$(tail -n1 "$MASTERLIST" | awk '{print $1}')
    # Increment the PLAYERID to get a new PLAYERID
    PLAYERID=$(( INCREMENTME + 1 ))
    # OK. We've only got a STEAMID now - no Username - so we're going to have to add that to the MASTERLIST
    # PLAYERID    STEAMID    FIRSTSEEN    STEAMNAME    "####"
    GETSTEAMNAME
    #Add entry in Masterlist without charname
    echo -e "$PLAYERID\t$STEAMID\t$(date +%Y-%m-%d_%H:%M:%S)\t$STEAMNAME\t#####" >> $MASTERLIST
    # Then We're going to have to add the username later
}

ADDNAME(){
    # Ok, this should only happen when a new player has joined and we do not have their name in the Masterlist, BUT we do have it now
    sed -en "/#####/$CHARNAME/"
    # Now we run JOIN() as it was skipped when we did the ADDPLAYER()
    JOIN
##    # Also - lets add a nice little welcome message to the server
}

JOIN(){
    DATE=$(date +%Y-%m-%d_%H:%M:%S)
    echo "$DATE - Join Funciton called" >> "$JOINLOG"

    # If there is no Userlog - create it
    [[ $(wc -l < "$USERLOG") -eq 0 ]] && echo -e 'PLAYERID\tSTEAMID\tIP_ADDR\tSTEAMNAME\tFISRTSEEN\tLOGINCOUNT\tPLAYERNAME\tCOUNT' > "$USERLOG"
    # Write log to access log
    echo "$DATE - Steam user $STEAMNAME ($STEAMLINK) attempted connection" >> "$PLAYERDBDIR"/access.log

    # checking if character log exists and creating it
    if [[ ! -f "$TIMES"/"$CHARNAME.log" ]]; then
        touch "$TIMES"/"$CHARNAME.log"
    fi

    # To keep track of life times:
    #Set Time of birth if itr does not exist
    [[ ! -f "$TIMES"/"$CHARNAME".tob ]] && date +%s > "$TIMES"/"$CHARNAME".tob
    
    # Write date to CHAR.online file 
    date +%s > "$TIMES"/"$CHARNAME".online
        
    GETSTEAMNAME
    # get image extension
    # some profiles have backgrounds, if they do, then we need to modify the code to ignore them
    if grep -q 'has_profile_background' "$HTMLDIR"/"$STEAMID".html; then
        echo "$DATE - Steam Profile has a background" > "$JOINLOG"
        #IMGEXT=$(grep -E -A4 'playerAvatarAutoSizeInner' "$HTMLDIR"/"$STEAMID".html | tail -n1 | awk -F'"' '{print $2}' | awk -F. '{print $NF}')
        # get image link
        IMGNAME=$(grep -A4 'playerAvatarAutoSizeInner' "$HTMLDIR"/"$STEAMID".html | tail -n1 | awk -F'"' '{print $2}')
    else
        echo "$DATE - Steam Profile does not have a background" > "$JOINLOG"
        #IMGEXT=$(grep -A1 'playerAvatarAutoSizeInner' "$HTMLDIR"/"$STEAMID".html | tail -n1 | awk -F'"' '{print $2}' | awk -F. '{print $NF}')
        # get image link
        IMGNAME=$(grep -A1 'playerAvatarAutoSizeInner' "$HTMLDIR"/"$STEAMID".html | tail -n1 | awk -F'"' '{print $2}')
    fi

   # get hours played
    echo "$DATE - Getting hours of Valheim played" > "$JOINLOG"
    HRS=$(grep -B2 -E 'Valheim' "$HTMLDIR"/"$STEAMID".html | grep -E 'on record' | grep -o -E '[0-9,]*')

    # Lets get other games from steam (NAME is game name LAST is last played, HRS is hours in that game)
    OGAMENAME1=$(grep -E -A4 "\"game_capsule\"" "$HTMLDIR"/"$STEAMID".html | grep -v 896660 | grep -E "whiteLink" | head -n1 | xargs | sed 's/.*app\/[0-9]*>//'    | rev | cut -c12- | rev)
    OGAMENAME2=$(grep -E -A4 "\"game_capsule\"" "$HTMLDIR"/"$STEAMID".html | grep -v 896660 | grep -E "whiteLink" | tail -n1 | xargs | sed 's/.*app\/[0-9]*>//'    | rev | cut -c12- | rev)
    if [[ $(grep -E -A4 "\"game_capsule\"" "$HTMLDIR"/"$STEAMID".html | grep -v 896660 | sed 's/^\s*//' | tail -n10 | grep -o -E 'last.*'| head -n1 | rev | cut -c9- | rev | sed 's/ on/:/' | s
ed 's/.*/\u&/' | xargs | awk '{print $3 " " $4}') = $(date +%d" "%b) ]]; then
        OGAMELAST1="Last played: Today"
    elif [[ $(grep -E -A4 "\"game_capsule\"" "$HTMLDIR"/"$STEAMID".html | grep -v 896660 | sed 's/^\s*//' | tail -n10 | grep -o -E 'last.*'| head -n1 | rev | cut -c9- | rev | sed 's/ on/:/' |
 sed 's/.*/\u&/' | xargs | awk '{print $3 " " $4}') = $(date -d "yesterday" +%d" "%b) ]]; then
        OGAMELAST1="Last played: Yesterday"
    else
        OGAMELAST1=$(grep -E -A4 "\"game_capsule\"" "$HTMLDIR"/"$STEAMID".html | grep -v 896660 | sed 's/^\s*//' | tail -n10 | grep -o -E 'last.*'| head -n1 | rev | cut -c9- | rev | sed 's/ on/
:/' | sed 's/.*/\u&/' | xargs)
    fi
    if [[ $(grep -E -A4 "\"game_capsule\"" "$HTMLDIR"/"$STEAMID".html | grep -v 896660 | sed 's/^\s*//' | tail -n10 | grep -o -E 'last.*'| tail -n1 | rev | cut -c9- | rev | sed 's/ on/:/' | s
ed 's/.*/\u&/' | xargs) = $(date +%d" "%b) ]]; then
        OGAMELAST2="Last played: Today"
    elif [[ $(grep -E -A4 "\"game_capsule\"" "$HTMLDIR"/"$STEAMID".html | grep -v 896660 | sed 's/^\s*//' | tail -n10 | grep -o -E 'last.*'| tail -n1 | rev | cut -c9- | rev | sed 's/ on/:/' |
 sed 's/.*/\u&/' | xargs) = $(date -d "yesterday" +%d" "%b) ]]; then
        OGAMELAST2="Last played: Yesterday"
    else
        OGAMELAST2=$(grep -E -A4 "\"game_capsule\"" "$HTMLDIR"/"$STEAMID".html | grep -v 896660 | sed 's/^\s*//' | tail -n10 | grep -o -E 'last.*'| tail -n1 | rev | cut -c9- | rev | sed 's/ on/
:/' | sed 's/.*/\u&/' | xargs)
    fi
    OGAMEHRS1=$(grep -E -A4 "\"game_capsule\"" "$HTMLDIR"/"$STEAMID".html | grep -v 896660 | sed 's/^\s*//' | tail -n10 | grep -o -E '.*ord' | head -n1)
    OGAMEHRS2=$(grep -E -A4 "\"game_capsule\"" "$HTMLDIR"/"$STEAMID".html | grep -v 896660 | sed 's/^\s*//' | tail -n10 | grep -o -E '.*ord' | tail -n1)

    # lets keep a record of who joins the server
    # users.log
    # access.log
    # denied.log
    touch "$USERLOG" "$PLAYERDBDIR"/access.log "$PLAYERDBDIR"/denied.log

    if [[ -z "$OGAMENAME2" ]]; then
            if [[ -z "$OGAMENAME1" ]]; then
                if [[ -z $HRS ]]; then
                    if [[ -z $PING ]]; then
                        curl -H "Content-Type: application/json" -X POST -d "{\"embeds\": [{ \"color\": \"$PURPLE\", \
                        \"title\": \"New connection:\", \
                        \"description\": \"Steam Profile: [$STEAMNAME]($STEAMLINK)\\nLogging in as **$PLAYERNAME**\\nFrom: $GEOIP\", \
                        \"thumbnail\": { \"url\": \"$IMGNAME\"}}]}" "$HOOK"
                    else
                        curl -H "Content-Type: application/json" -X POST -d "{\"embeds\": [{ \"color\": \"$PURPLE\", \
                        \"title\": \"New connection:\", \
                        \"description\": \"Steam Profile: [$STEAMNAME]($STEAMLINK)\\nLogging in as **$PLAYERNAME**\\nFrom: $GEOIP\\nPing: $PING\", \
                        \"thumbnail\": { \"url\": \"$IMGNAME\"}}]}" "$HOOK"
                    fi
                else
                    if [[ -z $PING ]]; then
                        curl -H "Content-Type: application/json" -X POST -d "{\"embeds\": [{ \"color\": \"$PURPLE\", \
                        \"title\": \"New connection:\", \
                        \"description\": \"Steam Profile: [$STEAMNAME]($STEAMLINK)\\nLogging in as **$PLAYERNAME**\\nFrom: $GEOIP\", \
                        \"fields\": [{\"name\": \"Hours on Record:\", \
                        \"value\": \"$HRS\", \
                        \"inline\": false}], \
                        \"thumbnail\": { \"url\": \"$IMGNAME\"}}]}" "$HOOK"
                    else
                        curl -H "Content-Type: application/json" -X POST -d "{\"embeds\": [{ \"color\": \"$PURPLE\", \
                        \"title\": \"New connection:\", \
                        \"description\": \"Steam Profile: [$STEAMNAME]($STEAMLINK)\\nLogging in as **$PLAYERNAME**\\nFrom: $GEOIP\\nPing: $PING\", \
                        \"fields\": [{\"name\": \"Hours on Record:\", \
                        \"value\": \"$HRS\", \
                        \"inline\": false}], \
                        \"thumbnail\": { \"url\": \"$IMGNAME\"}}]}" "$HOOK"
                    fi
                fi
            else
                if [[ -z $PING ]]; then
                    curl -H "Content-Type: application/json" -X POST -d "{\"embeds\": [{ \"color\": \"$PURPLE\", \
                    \"title\": \"New connection:\", \
                    \"description\": \"Steam Profile: [$STEAMNAME]($STEAMLINK)\\nLogging in as **$PLAYERNAME**\\nFrom: $GEOIP\", \
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
                    \"thumbnail\": { \"url\": \"$IMGNAME\"}}]}" "$HOOK"
                else
                    curl -H "Content-Type: application/json" -X POST -d "{\"embeds\": [{ \"color\": \"$PURPLE\", \
                    \"title\": \"New connection:\", \
                    \"description\": \"Steam Profile: [$STEAMNAME]($STEAMLINK)\\nLogging in as **$PLAYERNAME**\\nFrom: $GEOIP\\nPing: $PING\", \
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
                    \"thumbnail\": { \"url\": \"$IMGNAME\"}}]}" "$HOOK"
                fi
            fi
    else
        if [[ -z $PING ]]; then
            curl -H "Content-Type: application/json" -X POST -d "{\"embeds\": [{ \"color\": \"$PURPLE\", \
            \"title\": \"New connection:\", \
            \"description\": \"Steam Profile: [$STEAMNAME]($STEAMLINK)\\nLogging in as **$PLAYERNAME**\\nFrom: $GEOIP\", \
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
            \"thumbnail\": { \"url\": \"$IMGNAME\"}}]}" "$HOOK"
        else
            curl -H "Content-Type: application/json" -X POST -d "{\"embeds\": [{ \"color\": \"$PURPLE\", \
            \"title\": \"New connection:\", \
            \"description\": \"Steam Profile: [$STEAMNAME]($STEAMLINK)\\nLogging in as **$PLAYERNAME**\\nFrom: $GEOIP\\nPing: $PING\", \
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
            \"thumbnail\": { \"url\": \"$IMGNAME\"}}]}" "$HOOK"
        fi
    fi

    # # check to see if we have a record of the user, if not, add to users.log and save image.
    # if [[ $(grep -c -E "$STEAMID" "$USERLOG") -eq 0 ]]; then
    #     # Get last count of PLAYERID and the increment by 1 for next row
    #             #PLAYERID\tSTEAMID\tIP_ADDR\tSTEAMNAME\tFISRTSEEN\tLOGINCOUNT\tPLAYERNAME\tCOUNT
    #     echo -e "$PLAYERID\t$DATE\t$STEAMID\t$STEAMNAME\t$CONNIP\t$PLAYERNAME\t$STEAMNAME.$IMGEXT\t$IMGNAME" >> "$USERLOG"
    #     # format is:
    #     # FIRST SEEN              STEAMID                       STEAM NAME            IP ADDRESS          login     IMAGE NAME            IMAGE LINK
    #     # e.g.
    #     # 2023-08-21 16:25:21     76561198058880519             Blyzz.com             192.168.0.33        blyzz     Blyzz.com.gif
    #     # If they're not in the users log, they're not in the alias log - add that too
    #     echo -e "$STEAMID\t$PLAYERNAME" >> "$PLAYERDBDIR"/alias.log
    # else
    #     if [[ $(grep -c -E "$PLAYERNAME" "$PLAYERDBDIR"/alias.log) -eq 0 ]]; then
    #         # Ok, so we've got a record of the user in users.log, but no alternate aliases in alias.log so lets save the new username
    #         # format is:
    #         # STEAMID                                 FIRST                     OTHERS
    #         # e.g.
    #         # 76561198058880519             Blyzz                     blyzz-test                blyzz-2
    #         sed -i -E "/^$STEAMID/ s/$/\t$PLAYERNAME/" "$PLAYERDBDIR"/alias.log
    #     fi
    #fi
    STEAMID=""  
}

QUIT(){
    STEAMID="$CHARQUIT"
    STEAMNAME=$(grep "$STEAMID" "$MASTERLIST" | awk '{print $4}')
    CHARNAME=$(grep "$STEAMID" "$MASTERLIST" | awk '{print $5}')
    JOINTIME=$(cat "$TIMES"/"$CHARNAME".online)
    rm "$TIMES"/"$CHARNAME".online
    QUITTIME=$(date +%s)
    # This is the session time
    SESSTIME=$(( QUITTIME - JOINTIME ))
    echo $SESSTIME >> "$TIMES"/"$CHARNAME".log
    STEAMLINK="https://steamcommunity.com/profiles/$STEAMID"

    # Keep track of CHARACHTER survival
    #timeofexit
    TOE=$(date +%s)
    # If .tob exists, they died in this session. else set tob to .online
    [[ -f "$TIMES"/"$CHARNAME".tob ]] && TOB=$(cat "$TIMES"/"$CHARNAME".tob);rm "$TIMES"/"$CHARNAME".tob || TOB=$(cat "$TIMES"/"$CHARNAME".online)
    THISSESS=$(( TOE - TOB ))
    
    # Store that somewhere
    echo $THISSESS > "$TIMES"/"$CHARNAME".sess
    
    # # This adds the current session session to the old session and re-writes it to the session time file
    # if [[ ! -f "$TIMES"/"$CHARNAME".sess ]]; then
    #     echo "$SESSTIME" > "$TIMES"/"$CHARNAME".sess
    # else
    #      PREVSESS=$(cat "$TIMES"/"$CHARNAME".sess)
    #      TOTSESS=$(( PREVSESS + SESSTIME ))
    #      echo $TOTSESS > "$TIMES"/"$CHARNAME".sess
    # fi
    TOTSESS=0
    while read -r SUM; do
        (( TOTSESS += SUM ))
    done < "$TIMES"/"$CHARNAME".log

    # # This gets the total session time
    # NEWSESS=$(cat "$TIMES"/"$CHARNAME".sess)

    # Makes it human-readable and keeps it as "$LIFE"
    if [[ $TOTSESS -ge 604800 ]]; then
        LIFE=$(printf '%dw %dd %dh %dm %ds' $((NEWSESS/604800)) $((NEWSESS/86400)) $((NEWSESS%86400/3600)) $((NEWSESS%3600/60)) $((NEWSESS%60)))
    elif [[ $TOTSESS -ge 86400 ]]; then
        LIFE=$(printf '%dd %dh %dm %ds' $((NEWSESS/86400)) $((NEWSESS%86400/3600)) $((NEWSESS%3600/60)) $((NEWSESS%60)))
    elif [[ $TOTSESS -ge 3600  ]]; then
        LIFE=$(printf '%dh %dm %ds' $((NEWSESS/3600)) $((NEWSESS%3600/60)) $((NEWSESS%60)))
    elif [[ $TOTSESS -ge 60 ]]; then
        LIFE=$(printf '%dm %ds' $((NEWSESS/60)) $((NEWSESS%60)))
    else
        LIFE=$(printf '%ds' $((NEWSESS)))
    fi

    IMGNAME=$(grep -E "$STEAMID" "$USERLOG" | awk '{print $NF}')
    TITLE="\"$CHARNAME has disconnected:\""
    MESSAGE="\"$STEAMNAME was online for $SESSTIME\nAt time of disconnecting, $CHARNAME had been alive for $LIFE.\nTotal time on server:\n$LIFE\""
    IMGNAME=$(grep -A1 'playerAvatarAutoSizeInner' "$HTMLDIR"/"$STEAMID".html | tail -n1 | awk -F'"' '{print $2}')
    curl -H "Content-Type: application/json" -X POST -d "{\"embeds\": [{ \
    \"color\": \"$RED\", \
    \"title\": \"$TITLE\", \
    \"description\": \"$MESSAGE\",\
    \"thumbnail\": { \"url\": \"$IMGNAME\"} }] }" "$HOOK"

}

OBIT(){
    CHARNAME=$DEATH
    # Set Time of death
    TOD=$(date +%s)
    # Calculate survival time
    # If the file *.tob exists, use that as a session start time (the char died recently)
    # Else use *.online (they've not died since they were online)
    [[ -e "$TIMES"/"$CHARNAME".tob ]] && SESSSTART=$(cat "$TIMES"/"$CHARNAME".tob) || SESSSTART=$("$TIMES"/"$CHARNAME".online)
    # Then calculate that time until now
    THISSESS=$(( TOD - SESSSTART ))
    # If there are previous sessions, add the number to variuable or use 0
    [[ -f "$TIMES"/"$CHARNAME".sess ]] && PREVSESS=$(cat "$TIMES"/"$CHARNAME".sess) || PREVSESS=0
    # Add previous sessions to this session
    SURVIVED=$(( THISSESS + PREVSESS ))
    # Make Time Survives human readable
    if [[ $SURVIVED -ge 604800 ]]; then
        SESS=$(printf '%dw %dd %dh %dm %ds' $((NEWSESS/604800)) $((NEWSESS/86400)) $((NEWSESS%86400/3600)) $((NEWSESS%3600/60)) $((NEWSESS%60)))
    elif [[ $SURVIVED -ge 86400 ]]; then
        SESS=$(printf '%dd %dh %dm %ds' $((NEWSESS/86400)) $((NEWSESS%86400/3600)) $((NEWSESS%3600/60)) $((NEWSESS%60)))
    elif [[ $SURVIVED -ge 3600  ]]; then
        SESS=$(printf '%dh %dm %ds' $((NEWSESS/3600)) $((NEWSESS%3600/60)) $((NEWSESS%60)))
    elif [[ $SURVIVED -ge 60 ]]; then
        SESS=$(printf '%dm %ds' $((NEWSESS/60)) $((NEWSESS%60)))
    else
        SESS=$(printf '%ds' $((NEWSESS)))
    fi
    # Create new time of birth
    echo "$TOD" > "$TIMES"/"$CHARNAME".tob
    TITLE="$CHARNAME just died"
## Creat a bunch of funny death messages and a randomiser
    MESSAGE="**$CHARNAME** Lived a brilliant life for $SESS,\nbut has now met with an untimely demise."
    # Get STEAMID
    STEAMID=$(grep "$CHARNAME" "$MASTERLIST" | awk '{print $2}')
    IMGNAME=$(grep -A1 'playerAvatarAutoSizeInner' "$HTMLDIR"/"$STEAMID".html | tail -n1 | awk -F'"' '{print $2}')
    curl -H "Content-Type: application/json" -X POST -d "{\"embeds\": [{ \
    \"color\": \"$RED\", \
    \"title\": \"$TITLE\", \
    \"description\": \"$MESSAGE\",\
    \"thumbnail\": { \"url\": \"$IMGNAME\"} }] }" "$HOOK"
}

UPDATE(){
#Network version check, their:23, mine:20
#VER="their:23, mine:20"
    THEIR=(echo "$VER" | awk -F, '{print $1}' | cut -d':' -f 2)
    MINE=(echo "$VER" | awk -F, '{print $2}' | cut -d':' -f 2)
    if [[ "$THEIR" -gt "$MINE" ]]; then
        # I need to reboot
## Add code to reboot server
    elif [[ "$MINE" -gt "$THEIR" ]]; then
        # I'm good - Let them know they need to update
## Add code to send notification to user
    else
        :
        #we're good
    fi
}

READER(){
    tail -Fn0 /tmp/valheim_log.txt 2> /dev/null | \
    while read -r LINE ; do
        SRVRUP=$(echo "$LINE" | grep -oE 'Game server connected')
        STEAMID=$(echo "$LINE" | grep -oE 'handshake\sfrom\sclient\s[0-9]+$' | awk '{print $NF}')
        CHARNAME=$(echo "$LINE" | grep -oE 'orange>\S+' /tmp/valheim_log.txt | cut -d'>' -f2 | cut -d'<' -f1)
        CHARQUIT=$(echo "$LINE" | grep -oE 'Closing\ssocket\s[0-9]+$' | awk '{print $NF}')
        DEATH=$(echo "$LINE" | grep -oE 'ZDOID\sfrom\s[a-zA-Z0-9]+\s:\s0:0' | awk '{print $3}')
        VER=$(echo $"LINE" | grep -oE 'their:[0-9]+,\smine:[0-9]+$')
        #Got character ZDOID from Astrid : 0:0
        [[ -n $SRVRUP ]] && VALUP
        # If we have the Steam ID, and it is NOT in the masterlist, add it
        # If we have the steam ID, and it IS in the masterlist, run JOIN()
        if [[ -n $STEAMID ]]; then
            if [[ $(grep -c "$STEAMID" "$MASTERLIST") -eq 0 ]]; then
                echo "$DATE - Player STEAMID not in Masterlist" >> "$JOINLOG"
                ADDPLAYER
            fi
        fi
        # IF we're getting the character name, then the player is already in game
        # We need to check if the player name is in the Masterlist
        # If it is not - we add it and then the JOIN() Function is run from ADDNAME()
        # If it is in the master list, we just go ahead and run the JOIN() funciton.
        if [[ -n $CHARNAME ]]; then
            if [[ $(grep -cE "####$" "$MASTERLIST") -eq 1 ]]; then
                ADDNAME
            else
                JOIN
            fi
        fi
        [[ -n "$CHARQUIT" ]] && QUIT
        [[ -n "$DEATH" ]] && OBIT
        [[ -n "$VER" ]] && UPDATE
    done    
}

READER

# There might be a problem with this becuase of the time difference
# We need to figure out how to deal with multiple players logging in at the same time
    # Player 1 logs on to server (hasn't entered password yet)
    # Player 2 logs on to server
    # Player 2 enters password
    # Player 1 enters password

    # In this instance, player 2 will log in correctly
    # player 1 will report as being player 2

    # How I'm going to deal with this is create a master table
    # this will work on first log-in - We'll create a file in /discjord/playerdb/masterlist.db
    # Layout of this db should be
    # PLAYERID    STEAMID            IP_ADDR            STEAMNAME    FISRTSEEN              LOGINCOUNT    PLAYERNAME    COUNT
    # 1           76561198058880519  222.222.222.222    Blyzz.com    2024-04-11 10:40:15    8             Astrid        6        

    # PLAYERID    STEAMID            STEAMNAME     PRIMARY_PLAYERNAME#LOGIN_COUNT OTHERNAMES#LOGIN_COUNT
    #             76561198058880519  Blyzz.com     Astrid#6                       Blyzz#2

    # We now need to check that the other counts are not bigger than the Primary - then if it IS bigger than the primary...
    # ...make it the primary by editing that ROW In place

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


