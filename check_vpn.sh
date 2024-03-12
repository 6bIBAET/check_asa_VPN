#!/bin/bash

function usage {
        echo "  "
        echo "usage: [--help] [--usage]"
        echo "[-A] Path to RSA file"
        echo "[-H] Hostname or IP Address"
        echo "[-C] Command to execute"
                echo "[-P] Cisco Enable Password"
        echo "  "
        echo "Command List:"
        echo "  'vpnamount' show vpn connection statistic"
        echo "  'vpnusers' show connected users table"
        echo "  "
        echo "Syntax: check_vpn.sh -H ip/hostname -A /path/to/id_rsa -U ASA_Username -P ASA_Enable_pass -C Check_command"
        echo "  "
        exit 0
}

while [ -n "$1" ]
do
case "$1" in
-H) Host="$2";;

-A) RSAFile="$2";;

-C) Command="$2";;

-P) Enpass="$2";;

-U) User="$2";;

--help) usage;;

--usage) usage;;

esac
shift
shift
done

if [ -z "${Host}" ] || [ -z "${RSAFile}" ] || [ -z "${Command}" ];
then
        echo "Wrong Syntax - use '--help' for help ( Host address is "$Host" ; RSA file is "$RSAfile" ; Command is $Command ; enable password is "$Enpass" )    "
exit 2
fi

#VPN Amount
if [[ $Command == "vpnamount" ]];
then
        tmpfile=$(mktemp /tmp/vpnsession.XXXXXX)
        sshpass ssh -T -i $RSAFile -o StrictHostKeyChecking=no  $User@$Host $'enable\n'$"$Enpass"$'\nterminal pager 0\nsh vpn-sessiondb summary\nexit\n' </dev/zero  &> $tmpfile
        activeinactive=`grep 'Total Active and Inactive' $tmpfile | awk '{print $6}' | sed $'s/\r//'`
        anyconnectactive=`grep 'AnyConnect Client' $tmpfile | awk '{print $4}' | sed $'s/\r//'`
        anyconnectpeak=`grep 'AnyConnect Client' $tmpfile | awk '{print $8}' | sed $'s/\r//'`
        anyconnectinactive=`grep 'AnyConnect Client' $tmpfile | awk '{print $10}' | sed $'s/\r//'`
        clientlessactive=`grep 'Clientless VPN' $tmpfile | awk '{print $4}' | sed $'s/\r//'`
        clientlesspeak=`grep 'Clientless VPN' $tmpfile | awk '{print $8}' | sed $'s/\r//'`
        echo "Total sessions: $activeinactive | Total=$activeinactive"
        echo "Active sessionsAnyConnect: $anyconnectactive | Active_AnyConnect=$anyconnectactive"
        echo "Inactive sessionsAnyConnect: $anyconnectinactive | Inactive_AnyConnect=$anyconnectinactive"
        echo "Peak number of sessions AnyConnect: $anyconnectpeak | Peak_AnyConnect=$anyconnectpeak"
        echo "Active sessions without a client: $clientlessactive | Active_Clientless=$clientlessactive"
        echo "Peak number of sessions without a client: $clientlesspeak | Peak_Clientless=$clientlesspeak"
        rm -f $tmpfile
        exit 0

elif [[ $Command == "vpnusers" ]];
then
        tmpfileuserhtml=$(mktemp /tmp/vpnusershtml.XXXXXX)
        temptablefile=$(mktemp /tmp/tmptable.XXXXXX)
        sshpass ssh -T -i $RSAFile -o StrictHostKeyChecking=no  $User@$Host $'enable\n'$"$Enpass"$'\nterminal pager 0\nsh vpn-sessiondb svc\nexit\n' </dev/zero  &> $tmpfileuserhtml
        usernameshtml=`grep 'Username' $tmpfileuserhtml | awk '{print $3}' | sed $'s/\r//'`
        assigniphtml=`grep 'Assigned IP' $tmpfileuserhtml | awk '{print $4}' | sed $'s/\r//'`
        publickiphtml=`grep 'Public IP' $tmpfileuserhtml | awk '{print $8}' | sed $'s/\r//'`
        durationhtml=`grep 'Duration' $tmpfileuserhtml | awk '{print $3 $4}' | sed $'s/\r//'`
        grouppolicyhtml=`grep 'Group Policy' $tmpfileuserhtml | awk '{print $4}' | sed $'s/\r//'`
        inactivityhtml=`grep 'Inactivity' $tmpfileuserhtml | awk '{print $3}' | sed $'s/\r//'`
        txhtml=`grep 'Bytes Tx' $tmpfileuserhtml | awk '{print $4}' | sed $'s/\r//'`
        rxhtml=`grep 'Bytes Rx' $tmpfileuserhtml | awk '{print $8}' | sed $'s/\r//'`

        paste -d "," <(echo "$usernameshtml") <(echo "$grouppolicyhtml") <(echo "$assigniphtml") <(echo "$publickiphtml") <(echo "$durationhtml") <(echo "$inactivityhtml") <(echo "$txhtml") <(echo "$rxhtml") &> $temptablefile

        echo -n "<table border="1"><tr><th>Login</th><th>Group</th><th>Assigned IP</th><th>Public IP</th><th>Duration</th><th>Downtime</th><th>tx</th><th>rx</th></tr>" ; while read INPUT ; do echo -n "<tr><td>${INPUT//,/</td><td>}</td></tr>" ; done < $temptablefile ; e$

        rm -f $tmpfileuserhtml
        rm -f $temptablefile
        exit 0
else
        echo " Wrong Syntax - use '--help' for help ( Host address is "$Host" ; RSA file is "$RSAFile" ; Command is "$Command" ; enable password is "$Enpass" )    "
exit 2
fi
