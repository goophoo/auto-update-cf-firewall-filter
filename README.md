# auto-update-cf-firewall-filter

This shell script can be used to auto update your public ip to CF firewall filter;
The public ip is curled from 4 sets of public api, if all failed, the failure notification can be pushed to bark server if configured;

HOW TO USE
---
If you blocked all the china's ip including youself the way like I do, so it is needed to auto update the public ip into the allow list in CF firewall filter.
![image](https://user-images.githubusercontent.com/112747189/196971965-f5e7d55c-311c-420a-9755-e97f0364abb3.png)

1. Replace CF account info with yours;

2. Configure job in your crontab.

20221110
---
TRY 10 TIMES IF CURLING CLOUDFLARE FAILED.
![Screenshot 2022-11-11 165123](https://user-images.githubusercontent.com/112747189/201303103-aa1712d6-f72e-44fa-8c57-5530399147f2.png)

20221109
---
1. TIMEOUT ADDED IN CURL IF FAILED ON CURLING TO CLOUDFLARE;
2. FIXED ISSUES ON IPv6.
