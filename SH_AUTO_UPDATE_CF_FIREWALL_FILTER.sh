#!/bin/bash

generate_post_data()
{
  cat <<EOF
{
   "title": "$1",
   "body": "ROUTER: $(cat /proc/sys/kernel/hostname)\\nTIME: $(date +"%Y %b %d %A %T")",
   "device_key": "your_device_key",
   "badge": 1,
   "sound": "chime.caf",
}
EOF
}

curl_bark()
{
curl --connect-timeout 10 -X "POST" "https://your_bark_server/push" \
   -H 'Content-Type: application/json; charset=utf-8' \
   -d "$(generate_post_data $1)" &>/dev/null
}

for x in $(seq 4); do

  IP_1="api.ipify.org"
  IP_2="icanhazip.com"
  IP_3="ifconfig.me"
  IP_4="ipecho.net/plain"

  eval a=\${IP_${x}}

  TMP_PUBLIC_IP_NOW="$(curl --connect-timeout 5 -s $a | tail -1)"
#  TMP_PUBLIC_IP_NOW=""
#  TMP_PUBLIC_IP_NOW="error"
#  TMP_PUBLIC_IP_NOW="5.5.5.5"
#  TMP_PUBLIC_IP_NOW="2408:8352:c801:5625:8ac3:97ff:0:64"

  if [ -n "$TMP_PUBLIC_IP_NOW" ]
    then
#      echo "x IS: " $x
#      echo "FROM: " $a
#      echo "OK, NOT EMPTY IP"
      if [[ $TMP_PUBLIC_IP_NOW =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ || $TMP_PUBLIC_IP_NOW =~ ^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$ ]]
        then
#          echo "x IS: " $x
#          echo "FROM: " $a
#          echo "IP VALID, BREAK... $TMP_PUBLIC_IP_NOW"
#          echo ""
          break
#        else
#          echo "x IS: " $x
#          echo "FROM: " $a
#          echo "INVALID, GOING ON... $TMP_PUBLIC_IP_NOW"
#          echo ""
      fi
#    else
#      echo "x IS: " $x
#      echo "FROM: " $a
#      echo "EMPTY IP, GOING ON..."
#      echo ""
  fi
done

if [ -z "$TMP_PUBLIC_IP_NOW" ]
  then
    date >> /root/LOG_CURL_CF_RULE.log
    echo "ALL 4 TRIES CURLING FOR CURRENT PUBLIC IP RETURNED EMPTY, SO CURLING BARK SERVER..." >> /root/LOG_CURL_CF_RULE.log
    curl_bark "CURLING_FOR_CURRENT_PUBLIC_IP_RETURNED_EMPTY"
    echo "" >> /root/LOG_CURL_CF_RULE.log
    exit
  elif [[ ! $TMP_PUBLIC_IP_NOW =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && { [[ ! $TMP_PUBLIC_IP_NOW =~ ^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$ ]] ;}
    then
      date >> /root/LOG_CURL_CF_RULE.log
      echo "ALL 4 TRIES CURLING FOR CURRENT PUBLIC IP RETURNED INVALID VALUE, SO CURLING BARK SERVER..." >> /root/LOG_CURL_CF_RULE.log
      curl_bark "CURLING_FOR_CURRENT_PUBLIC_IP_RETURNED_INVALID_VALUE"
      echo "" >> /root/LOG_CURL_CF_RULE.log
      exit
fi

global_key="your_global_key"
Email="tiananmen@198964.com"
ZoneID="your_zone_id"
RuleID="your_rule_id"
FilterID="your_filter_id"

date >> /root/LOG_CURL_CF_RULE.log

i=1
while true
do
curl --connect-timeout 3 -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZoneID/firewall/rules/$RuleID?id=$RuleID" -H "Content-Type: application/json" -H "X-Auth-Email: $Email" -H  "X-Auth-Key: $global_key" >> /root/LOG_CURL_CF_RULE.log
if [[ $? -ne 0 ]]
  then
    if [[ $i -gt 10 ]]
      then
        echo "ALL $i TRIES FAILED RETRIEVING CF, GAVE UP, LAST VALID RECORED WILL BE USED." >> /root/LOG_CURL_CF_RULE.log
        break
      else
#        echo "$i TRIES FAILED RETRIEVING CF, TRYING AGAIN 10S LATER."
        i=$((i+1))
        sleep 10s
    fi
  else
    echo "$i TRIES SUCCESSFULLY RETRIEVED CF." >> /root/LOG_CURL_CF_RULE.log
    break
fi
done

LAST_SUCCESS=$(grep '"success":' /root/LOG_CURL_CF_RULE.log | tail -1 | awk -F'[ ,]' 'END{print $4}')
LAST_EXP=$(grep '"expression":' /root/LOG_CURL_CF_RULE.log | tail -1 | awk -F"[{}]" '{gsub(" ","|"); print $2}')

if [[ $LAST_SUCCESS == true  ]]
  then
    if [[ $TMP_PUBLIC_IP_NOW =~ $LAST_EXP ]]
      then
        echo "IT'S IN THE LIST, EXIT. $TMP_PUBLIC_IP_NOW" >> /root/LOG_CURL_CF_RULE.log
        echo "" >> /root/LOG_CURL_CF_RULE.log
        exit
      else
        echo "NOT IN THE LIST, UPDATING CF RULE... $TMP_PUBLIC_IP_NOW" >> /root/LOG_CURL_CF_RULE.log
        a=$(grep '"expression":' /root/LOG_CURL_CF_RULE.log | tail -1 | awk -F'[{}]' '{print $2}')
        b=$a" "$TMP_PUBLIC_IP_NOW

generate_post_data1()
{
  cat <<EOF
{
  "id":"$FilterID",
  "expression":"(ip.src in {$b})"
}
EOF
}

        i=1
        while true
        do
        curl --connect-timeout 3 -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZoneID/filters/$FilterID" -H "Content-Type: application/json" -H "X-Auth-Email: $Email" -H  "X-Auth-Key: $global_key" --data "$(generate_post_data1)"  &>/dev/null
        if [[ $? -eq 0 ]]
          then
            echo "$i TRIES SUCCESSFULLY UPDATED CF FIREWALL RULE." >> /root/LOG_CURL_CF_RULE.log
            echo "" >> /root/LOG_CURL_CF_RULE.log
            break
          else
            if [[ $i -gt 10 ]]
              then
                echo "ALL $i TRIES FAILED UPDATING CF FIREWALL RULE, GAVE UP." >> /root/LOG_CURL_CF_RULE.log
                echo "" >> /root/LOG_CURL_CF_RULE.log
                exit
              else
#                echo "$i TRIES FAILED UPDATING CF FIREWALL RULE, TRY AGAIN 10S LATER."
                i=$((i+1))
                sleep 10s
            fi
        fi
        done
        
#        echo "CURLING BARK OF NEW PUBLIC IP..."
        curl_bark "NEW_PUBLIC_IP_ADDED_ON_CF_$TMP_PUBLIC_IP_NOW"
#        echo "CURLING BARK OF NEW PUBLIC IP...FINISHED."

    fi
  else
    echo "LAST CHECK FAILED, EXIT." >> /root/LOG_CURL_CF_RULE.log
    exit
fi
