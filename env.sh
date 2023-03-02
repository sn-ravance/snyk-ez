

#help function
usage () 
{ 
echo "Usage:\n"
echo "Example: ./env.sh -d"

		echo "OPTIONS:"
		echo "-d	debug mode"
        echo "-ij   don't create json"
		echo "-h	Displays this help text"
		echo "\n"
		echo "Running without options runs the script normally" 
			
}

setvars()
{

SLOG=`pwd`"/snyk-log"
SJSON="snyk-orgs.json"

}

checkbin()
{
if [ "$1" == "-d" ]; then
    echo "***prereqs:***"
fi   

if [ ! command -v jq &> /dev/null ]; then
    if [ "$OSTYPE" == "darwin"* ]; then
        echo "Installing JQ"
        brew install jq
    fi
    if [ "$1" == "-d" ]; then
        if [ ! command -v jq &> /dev/null ]; then
            echo "JQ is not installed"
        else
            echo "JQ is installed"
        fi
    fi  
else
    if [ "$1" == "-d" ]; then 
        echo "JQ is installed"
    fi
fi

if [ ! command -v npm &> /dev/null ]; then
    if [ "$OSTYPE" == "darwin"* ]; then
        echo "Installing npm"
        brew install node
    fi
    if [ "$1" == "-d" ]; then
        if [ ! command -v npm &> /dev/null ]; then
            echo "NPM is not installed"
        else
            echo "NPM is installed"
        fi
    fi
else
    if [ "$1" == "-d" ]; then 
        echo "NPM is installed"
    fi
fi

if [ ! command -v snyk-api-import &> /dev/null ]; then
    if [ ! command -v npm &> /dev/null ]; then
        echo "*** ERROR *** NPM is not installed!"
        exit
    else
        echo "## Set up\nInstalling snyk-api-import"
        npm install snyk-api-import@latest -g
    fi
else
    if [ "$1" == "-d" ]; then 
        echo "snyk-api-import is installed"
    fi
fi

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

setfolders()
{
echo "\n*** Set files and folders ***"

if [ ! -d "$SLOG" ]; then
    echo "*** Create $SLOG folder ***"
mkdir -p $SLOG
sudo chmod -R 766 $SLOG
fi

}

createjson()
{

echo "## Step 3."
#cat <<< $(jq '.orgData[].name='$GITHUB_ORG_NAME $SJSON) > $SJSON
cat <<< $(jq --arg newkey ${GITHUB_ORG_NAME} '(.orgData[].name)=$newkey' $SJSON ) > $SJSON

echo "## Step 6.\n"
#cat <<< $(jq '.orgData[].orgId='$SNYK_ORG_ID $SJSON) > $SJSON 
cat <<< $(jq --arg newkey ${SNYK_ORG_ID} '(.orgData[].orgId)=$newkey' $SJSON ) > $SJSON

echo "## Step 7.\n"
#cat <<< $(jq '.orgData[].integrations.github='$SNYK_ORG_INT_ID $SJSON) > $SJSON 
cat <<< $(jq --arg newkey ${SNYK_ORG_INT_ID} '(.orgData[].integrations.github)=$newkey' $SJSON ) > $SJSON
cat <<< $(jq 'del(.orgData[].integrations ["github-enterprise"])' $SJSON) > $SJSON 

}

importdata ()
{
if [ "$1" == "-d" ]; then

echo "## Import data"
DEBUG=snyk* snyk-api-import import:data --source=github --integrationType=github --orgsData=$SJSON

else

echo "## Import data"
snyk-api-import import:data --source=github --integrationType=github --orgsData=$SJSON

fi
}

reviewdata()
{

echo "## Step 2"
jq . $SLOG/github-import-targets.json

echo "## Step 3"
cat $SLOG/github-import-targets.json | jq '.targets | length'

echo "## 5."
snyk-api-import import --file=$SLOG/github-import-targets.json

echo "1. Check how many projects successfully imported:"
jq -s length $SLOG/$SNYK_ORG_ID.imported-projects.log

echo "2. Check if any projects failed to import and why:"
jq . $SLOG/$SNYK_ORG_ID.failed-projects.log
   
echo "4. Review the snyk-logs folder for other log files:"
ls -la snyk-log

}

call_each()
{

    while getopts "h:d:" option; do
        case "${option}" in
            d) debug_info=${OPTARG}"d";;
            h) usage; exit;;
            *) usage; exit;;
        esac
    done

    checkbin "$@"
    setvars "$@"
    exportvars "$@"
    setfolders "$@"
    if [ "$1" == "-x" ]; then
        createjson "$@"
    fi
    importdata "$@"
    reviewdata "$@"
}

call_each "$@"