#!/bin/bash
if [ -f ./agentstrings.config ]; then
	. ./agentstrings.config
else
	echo "agentstrings.config file missing"
	exit 1
fi

#default options
COUNT=100
MAX=300
MIN=120
QUIET=0

# Gets the command name without path
cmd(){ echo `basename $0`; }

# Help command output
usage(){
echo "Uses curl, tor and proxychains to \"ping\" a website with a random user agent string"
echo "\
`cmd` [OPTION...]
-c, --count; Number of times to repeat (default: 10)
-M, --max; max random time in seconds (default: 300)
-m, --min; min time in seconds to wait before running (default: 120)
-u, --url; url to use
-h, --help; displays this
-q, --quiet; No curl output
" | column -t -s ";"
}

if [ "$#" == "0" ]; then
    usage
    exit 1
fi

# Error message
error(){
    echo "`cmd`: invalid option -- '$1'";
    echo "Try '`cmd` -h' for more information.";
    exit 1;
}

# getopt string
opts="cMmuq:"

# There's two passes here. The first pass handles the long options and
# any short option that is already in canonical form. The second pass
# uses `getopt` to canonicalize any remaining short options and handle
# them
for pass in 1 2; do
    while [ -n "$1" ]; do
        case $1 in
            --) shift; break;;
            -*) case $1 in
                -c|--count)    COUNT=$2; shift;;
                -M|--max)      MAX=$2; shift;;
                -m|--min)      MIN=$2; shift;;
                -u|--url)      URL=$2; shift;;
		-q|--quiet)    QUIET=1;;
                -h|--help)     usage;; 
                --*)           error $1;;
                -*)            if [ $pass -eq 1 ]; then ARGS="$ARGS $1";
                               else error $1; fi;;
                esac;;
            *)  if [ $pass -eq 1 ]; then ARGS="$ARGS $1";
                else error $1; fi;;
        esac
        shift
    done
    if [ $pass -eq 1 ]; then ARGS=`getopt $opts $ARGS`
        if [ $? != 0 ]; then usage; exit 2; fi; set -- $ARGS
    fi
done

# Handle positional arguments
if [ -n "$*" ]; then
    echo "`cmd`: Extra arguments -- $*"
    echo "Try '`cmd` -h' for more information."
    exit 1
fi

if [ -z "$URL" ]; then
    echo "URL is empty"
    exit 1;
fi

isnum() {
	if [ "$1" -eq "$1" ] 2>/dev/null; then
		return 0	
	else
  		echo "$2 is not number"
		exit 1
	fi
}

isnum $COUNT "count"
isnum $MAX "max"
isnum $MIN "min"

COUNTER=0;
while [ $COUNTER -lt $COUNT ]; do
	if [ $QUIET -eq 0 ]; then
		proxychains curl -A "${ARRAY[$RANNUM]}" "$URL"
	else
		proxychains curl -A "${ARRAY[$RANNUM]}" "$URL" >/dev/null
	fi
	RANNUM=$[ 0 + $[ RANDOM % 249 ]]
        sleep $[ ( $RANDOM % $MAX )  + $MIN ]s
        let "COUNTER=$COUNTER + 1"
done
