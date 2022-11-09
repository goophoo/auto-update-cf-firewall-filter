#!/bin/bash

for x in $(seq 4); do

  IP_1="api.ipify.org"
  IP_2="icanhazip.com"
  IP_3="ifconfig.me"
  IP_4="ipecho.net/plain"

  eval a=\${IP_${x}}

  TMP_PUBLIC_IP_NOW="$(curl --connect-timeout 3 -s $a | tail -1)"

  if [ -n "$TMP_PUBLIC_IP_NOW" ]
    then
#      echo "x IS: " $x
#      echo "IP IS: " $a
#      echo "OK, NOT EMPTY IP"
      if [[ $TMP_PUBLIC_IP_NOW =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ || $TMP_PUBLIC_IP_NOW =~ ^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$ ]]
        then
#          echo "x IS: " $x
#          echo "IP IS: " $a
#          echo "IP VALID, BREAK: " $TMP_PUBLIC_IP_NOW
#          echo ""
          break
#        else
#          echo "x IS: " $x
#          echo "IP IS: " $a
#          echo "INVALID, GOING ON: " $TMP_PUBLIC_IP_NOW
#          echo ""
      fi
#    else
#      echo "x IS: " $x
#      echo "IP IS: " $a
#      echo "EMPTY IP, GOING ON..."
#      echo ""
  fi
done



##PUSH FAILURES ON ALL CURLING TO BARK;
if [ -z "$TMP_PUBLIC_IP_NOW" ]
then
##echo "EMPTY AND CURL"
#generate_post_data()
#{
#  cat <<EOF
#{
#   "title": "ALL CURLs RESULT EMPTY.",
#   "body": "ROUTER: $(cat /proc/sys/kernel/hostname)\\nTIME: $(date +"%Y %b %d %A %T")",
#   "device_key": "your_device_key",
#   "badge": 1,
#   "sound": "chime.caf",
#   "icon": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSFdfqP9psOFmRSdxu5LoGG-g8ggRJCBnB6UQ&usqp=CAU"
#}
#EOF
#}
#
#curl --connect-timeout 10 -X "POST" "https://your_bark_server/push" \
#   -H 'Content-Type: application/json; charset=utf-8' \
#   -d "$(generate_post_data)" &>/dev/null
#
exit
#
elif [[ ! $TMP_PUBLIC_IP_NOW =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && { [[ ! $TMP_PUBLIC_IP_NOW =~ ^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$ ]] ;}
then
##echo "ALL CURLING FAILED AND CURLING BARK..."
#generate_post_data()
#{
#  cat <<EOF
#{
#   "title": "ALL CURLs FAILED.",
#   "body": "ROUTER: $(cat /proc/sys/kernel/hostname)\\nTIME: $(date +"%Y %b %d %A %T")",
#   "device_key": "your_device_key",
#   "badge": 1,
#   "sound": "chime.caf",
#   "icon": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSFdfqP9psOFmRSdxu5LoGG-g8ggRJCBnB6UQ&usqp=CAU"
#}
#EOF
#}
#
#curl --connect-timeout 10 -X "POST" "https://your_bark_server/push" \
#   -H 'Content-Type: application/json; charset=utf-8' \
#   -d "$(generate_post_data)" &>/dev/null
#
exit
#
fi



global_key="your_global_key"
Email="tiananmen@198964.com"
ZoneID="your_zone_id"
RuleID="your_rule_id"
FilterID="your_filter_id"

date >> /root/LOG_CURL_CF_RULE.log
#echo "STARTED RETRIEVING CF..."
curl --connect-timeout 5 -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZoneID/firewall/rules/$RuleID?id=$RuleID" -H "Content-Type: application/json" -H "X-Auth-Email: $Email" -H  "X-Auth-Key: $global_key" >> /root/LOG_CURL_CF_RULE.log
if [[ $? -ne 0 ]]
  then
    echo "CURL CF FAILED" >> /root/LOG_CURL_CF_RULE.log
    echo "" >> /root/LOG_CURL_CF_RULE.log
#    echo "FAILED RETRIEVING CF, LAST RECORD WILL BE USED..."
#else
#  echo "FINISHED RETRIEVING CF..."
fi

LAST_SUCCESS=$(grep '"success":' /root/LOG_CURL_CF_RULE.log | tail -1 | awk -F'[ ,]' 'END{print $4}')
LAST_EXP=$(grep '"expression":' /root/LOG_CURL_CF_RULE.log | tail -1 | awk -F"[{}]" '{gsub(" ","\|"); print $2}')

if [[ $LAST_SUCCESS == true  ]]
  then
    if [[ $TMP_PUBLIC_IP_NOW =~ $LAST_EXP ]]
      then
#        echo "IT'S IN THE LIST: " $TMP_PUBLIC_IP_NOW
#        echo ""
        exit
      else
#        echo "NOT IN THE LIST: " $TMP_PUBLIC_IP_NOW
#        echo "UPDATING CF RULE..."
#        echo ""
        a=$(grep '"expression":' /root/LOG_CURL_CF_RULE.log | tail -1 | awk -F'[{}]' '{print $2}')
        b=$a" "$TMP_PUBLIC_IP_NOW

generate_post_data()
{
  cat <<EOF
{
  "id":"$FilterID",
  "expression":"(ip.src in {$b})"
}
EOF
}
#echo "CURLING TO ADD NEW PUBLIC IP ON CF..."
curl --connect-timeout 10 -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZoneID/filters/$FilterID" -H "Content-Type: application/json" -H "X-Auth-Email: $Email" -H  "X-Auth-Key: $global_key" --data "$(generate_post_data)"  &>/dev/null
if [[ $? -eq 0 ]]
#  then
#    echo "SUCCESSFULLY ADDED NEW PUBLIC IP TO CF FIREWALL RULE."
#
#echo "CURLING BARK OF NEW PUBLIC IP..."
generate_post_data()
{
  cat <<EOF
{
   "title": "NEW PUBLIC IP ADDED ON CF",
   "body": "ROUTER: $(cat /proc/sys/kernel/hostname)\\nTIME: $(date +"%Y %b %d %A %T")\\n$TMP_PUBLIC_IP_NOW",
   "device_key": "your_device_key",
   "badge": 1,
   "sound": "chime.caf",
   "icon": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSFdfqP9psOFmRSdxu5LoGG-g8ggRJCBnB6UQ&usqp=CAU"
}
EOF
}

curl --connect-timeout 10 -X "POST" "https://your_bark_server/push" \
   -H 'Content-Type: application/json; charset=utf-8' \
   -d "$(generate_post_data)" &>/dev/null
#echo "FINISHED CURLING BARK OF NEW PUBLIC IP..."
#else
#echo "FAILED ON ADDING NEW PUBLIC IP TO CF FIREWALL RULE."
fi
fi
#  else
#    echo "LAST CHECK FAILED"
fi
