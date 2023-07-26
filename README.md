# gitlab_push
Push android repo onto gitlab

Prerequisites
Following command line tools are needed:
1. git
2. repo
3. curl
4. jq
5. xmlstarlet

Usage:
Modify variables in configs to control the program.
Go to the top directory of the repo you'd like to push and execute
<dir where gitlab_push is placed>/gitlab_push.sh <dir where manifest file will be saved>

--------------
If the following error occurs when git push to server, follow steps below:
cd <the project directory>
git filter-branch -- --all
git push -u gitsrv-android iei-android-13.0.0_r6
