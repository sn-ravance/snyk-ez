
#help function
usage () 
{ 
echo "Usage:\n"
echo "Example: ./env.sh -d"

		echo "OPTIONS:"
		echo "-d	debug mode"
		echo "-h	Displays this help text"
		echo "\n"
		echo "Running without options runs the script normally" 
			
}

exportvars()
{

echo "*** Set environment Variables ***"

input=`pwd`"/config.ini"
while IFS= read -r line
do
  echo "$line"
export "$line"
done < "$input"

if [ "$1" == "-d" ]; then
    echo "\n*** Environment Variables ***"
    printenv | grep -E 'SNYK*|GITHUB*|SANITIZE*' | sort
    echo "\n"
fi

}

call_each()
{

    while getopts "h:d" option; do
        case "${option}" in
            d) debug_info=${OPTARG}"d";;
            h) usage; exit;;
            *) usage; exit;;
        esac
    done

    exportvars "$@"
}

call_each "$@"
