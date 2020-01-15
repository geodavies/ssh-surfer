#!/bin/bash
input="/Users/$USER/.ssh/servers.csv"

# Setup global vars
headerPrinted=false

# Make sure the script exits cleanly in failure
set -e

# Prints out how to use the tool
function usage {
	echo 'Usage: [command] [name]'
	echo '    1: The command to perform on the server (eg. ls/connect/deploy)'
	echo '    2: The name of the server (eg. server-name)'
	exit 0
}

# Parse options for help (-h)
while getopts ':h' opt; do
	case ${opt} in
		h)
			usage
			;;
		\?)
			echo "Invalid Option: -$OPTARG" 1>&2
			exit 1
			;;
  esac
done

# Check the subcommand is valid
subcommand=$1
case "$subcommand" in
	ls)
		command='list'
		;;
	connect)
		command='connect'
		;;
	deploy)
		command='deploy'
		;;
	*)
		echo "Command not found: $subcommand"
		usage
		exit 1
esac

# Prints the SSH Surfer banner
function printBanner {
	printf "           -.--.\n           )  \" '-,\n           ',' 2  \_\n            \q \ .  \ \n         _.--'  '----.__\n        /  ._      _.__ \__      __________ __  __   _____            ____\n     _.'_.'  \_ .-._\_ '-, }    / ___/ ___// / / /  / ___/__  _______/ __/__  _____\n    (,/ _.---;-(  . \ \   ~     \__ \\\\\__ \/ /_/ /   \__ \/ / / / ___/ /_/ _ \/ ___/\n  ____ (  .___\_\  \/_/        ___/ /__/ / __  /   ___/ / /_/ / /  / __/  __/ /\n (      '-._ \   \ |          /____/____/_/ /_/   /____/\__,_/_/  /_/  \___/_/\n  '._       ),> _) >\n     '-._ c='  Cooo  -._\n         '-._           '.\n             '-._         \`\\ \n                 '-._       '.\n                     '-._     \\ \n                         \`~---'\n"
}

# Prints the table header
function printHeader {
	headerPrinted=true
	echo -e ""
	printf "%-40s \e[95m|\e[39m %-25s \e[95m|\e[39m %-15s \e[95m|\e[39m %-20s \e[95m" 'Tags' 'Server Name' 'Server IP' 'Username'
	printf "\n\e[95m-----------------------------------------+---------------------------+-----------------+----------------------\e[39m\n"
}

# Pretty prints a row in the table
function prettyPrint {
	# Print table header if it's not there
	if [ "$headerPrinted" = 'false' ]; then
		printHeader
	fi

	printf "%-40s \e[95m|\e[39m %-25s \e[95m|\e[39m %-15s \e[95m|\e[39m %-20s \n" "$1" "$2" "$3" "$4"
}

# Searches and extracts matching servers from spreadsheet
function findServersFromSpreadsheet {
	# Check if the user has specified all
	if [ "$1" = '' ]; then
		# If all then result is every record except the spreadsheet header
		tail -n+2 $input
	else
		# Otherwise look for records that have matching tags
		local serverCount=0
		local awkString=''
		for tag in "$@"
		do
			if [ "$serverCount" = 0 ]; then
				awkString="/(${tag} | ${tag}|,${tag},|^${tag},)/"
			else
				awkString="${awkString} && /(${tag} | ${tag}|,${tag},|^${tag},)/"
			fi
			((serverCount++))
		done
		cat $input | awk "${awkString}"
	fi
}

printBanner

servers=$(findServersFromSpreadsheet ${@:2})

# If no server was found then let the user know
if [ ${#servers} = 0 ]; then
	echo "No server found matching: ${@:2}"
else
	# Check there's only one server matching for single commands
	serverCount=$(echo "$servers" | wc -l | awk '{$1=$1;print}')
	if [ "$serverCount" -gt "1" ]; then
		if [ $command = "connect" ]; then
			echo 'Found more than one server matching that tag, I can only connect to one server at a time, please be more precise.'
		elif [ $command = "deploy" ]; then
			echo 'Found more than one server matching that tag, I can only deploy keys to one server at a time, please be more precise.'
		fi
		command='list'
	fi

	# Loop over each row in spreadsheet
	echo -e "$servers" | while IFS=',' read -r f1 f2 f3 f4
	do
		if [ $command = "list" ]; then
			prettyPrint "$f1" "$f2" "$f3" "$f4"
		elif [ $command = "connect" ]; then
			printf "Connecting to $f2 at $f3 as user $f4...\n\n"
			ssh -t -l $f4 $f3 < /dev/tty
		elif [ $command = "deploy" ]; then
			printf "Deploying SSH keys for passwordless login to $f2 at $f3 as user $f4...\nType in your password for the server when prompted.\n\n"
			connectionString="$f4@$f3"
			ssh-copy-id $connectionString
		fi
	done
fi

exit 0
