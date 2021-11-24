#!/bin/bash

# This script will accept one or more TN's and pull information about it.

function help()
{
    echo -e "
    TNLooker - Telephone Number Lookup Tool 

    Desc: This tool will lookup various information, given one or more telephone numbers. 
    Usage: tnlooker [OPTION...] ARGUEMENT...

    Examples:
        tnlooker 14158586270 
        tnlooker 14158586270 14158586271 +1415-858-6271
        tnlooker -n 14158586270 14158586271 +1415-858-6271
        tnlooker -vnli 14158586270 14158586271 +1415-858-6271
        tnlooker -F TN_FILE.txt

    Options: 
        ENV
        -A - access_key     Specifies the access_key to be used when making API calls. 
        -E - endpoint       Specifies the endpoint the API Calls are made to. 
        -D - DF_FILE        Specifies the mysql client configuration file. 
    
        INPUT
        -F - TN_FILE        Input a file containing telephone numbers seperated by whitespace. 
    
        OUTPUT
        -v - valid          Display whether the number is a valid telephone number. 
        -n - number         Display the number in 11 digit format. 
        -l - local_format   Display the number in local format (without the country prefix)
        -i - int_format     Display the number in 
        -p - country_prefix Disiplay the country prefix number 
        -o - country_code   Display the 2 letter country code 
        -a - country_name   Disiplay the entire country name
        -u - location       Display the town/city/state of the number. 
        -c - carrier        Display the carrier name. 
        -t - line_type      Display the line type (mobile, landline, or VOIP)
        -h - help           Display this help message 
    "
}

##################################################################################
#                      GET ENV VARIABLES
##################################################################################
CFG_FILE=./config/tnlooker.cfg

function makeConfig()
    # Create the default config file if it does not exist. 
{
    if [[ ! -f $CFG_FILE ]];
    then
        echo "baseURL='http://apilayer.net'" > $CFG_FILE
        echo "endpoint='/api/validate'" >> $CFG_FILE
        echo "access_key=''" >> $CFG_FILE
        echo "DB_FILE='config/mysql_connect.cfg'" >> $CFG_FILE
    fi
}
makeConfig


function updateConfig()
    # Update the config file. Accepts 2 arguments: [Parameter] [value]. 
{
    param=$1
    value=$2
    sed -i "s/$param='.*'/$param='$value'/g" $CFG_FILE
    if [[ $? -ne 0 ]];
    then
        echo "There was an issue updating the config file. Check your params/values and CFG_File."
    else
        . $CFG_FILE
    fi
}

# Source the current config. 
. $CFG_FILE

##################################################################################
#                      GET -OPTIONS
##################################################################################
# Create an array to store the output options. 
declare -a options=()

while getopts "hvnlipoauctA:E:D:F:" option
do
	case "${option}" in
        v) options=(${options[@]} 'valid');;
        n) options=(${options[@]} 'number');;
        l) options=(${options[@]} 'local_format');;
        i) options=(${options[@]} 'int_format');;
        p) options=(${options[@]} 'country_prefix');;
        o) options=(${options[@]} 'country_code');;
        a) options=(${options[@]} 'country_name');;
        u) options=(${options[@]} 'location');;
        c) options=(${options[@]} 'carrier');;
        t) options=(${options[@]} 'line_type');;
        A) access_key=${OPTARG}; updateConfig access_key $access_key;;
        E) endpoint=${OPTARG}; updateConfig endpoint $endpoint;;
        D) DB_FILE=${OPTARG}; updateConfig DB_FILE $DB_FILE;;
        F) TN_FILE=${OPTARG};;
        h) help; exit;;
        \?) help; exit;;
	esac
done

columns=$(echo -e "${options[@]}" | sed 's/ /,/g')

shift $(($OPTIND -1))

# Set columns to all by default. 
if [[ -z "$columns"  ]];
then
	columns=*
fi

# Make sure we have an access key. 
if [[ -z "$access_key" ]];
then
    echo -e "No Access Key Set. Run ./tnlooker.sh -A [access key]"
    exit 101
fi
##################################################################################

# Create an array to store the TNs. 
if [[ -n "$TN_FILE" ]];
then
    declare -a tns=($(cat $TN_FILE))
else
    declare -a tns=($@)
fi

# Define acceptable input formats. 
numberFormat="^[1-9][0-9]{10,14}$"
localFormat="^[0-9]{10}$"


function checkDB()
    # Checks the DB for records matching the current TN and stores the id. Returns 1 if no match is found. 
{
    local QUERY="SELECT id FROM tnlooker_db.numbers WHERE $column = ${num} $@"
    id=$(echo $QUERY | mysql --defaults-extra-file=$DB_FILE -s)
    if [[ $? -ne 0 ]];
    then 
        echo -e "\nFatal MySQL Error Received. Exiting."
        exit 500
    fi

    if [[ -z $id ]]; 
    then
        return 1
    else
        return 0
    fi
}

function checkRecord_age()
    # Checks whether the current TN's record needs to be updated (Max: 7 days). Returns 1 if an update is needed. 
{
    local QUERY="SELECT 
            CASE 
                WHEN TIMESTAMPDIFF(DAY,updated_on,now()) > 7 THEN 1 
                ELSE 0 
            END record_age 
        FROM numbers WHERE id = $id;"

    local record_age=$(echo $QUERY | mysql --defaults-extra-file=$DB_FILE -s)
    if [[ $record_age -ne 0 ]]; 
    then
        return 1
    else
        return 0
    fi
}

function getData()
    # Parses the json data and stores values in variables. 
{
    number=$(echo $json | jq -r .number)
    local_format=$(echo $json | jq -r .local_format)
    int_format=$(echo $json | jq -r .international_format)
    country_prefix=$(echo $json | jq -r .country_prefix)
    country_code=$(echo $json | jq -r .country_code)
    country_name=$(echo $json | jq -r .country_name)
    location=$(echo $json | jq -r .location)
    carrier=$(echo $json | jq -r .carrier)
    line_type=$(echo $json | jq -r .line_type)
    valid=$(echo $json | jq -r .valid)
}

function insertData()
    # Inserts data from the APICall into the DB. 
{
    QUERY="INSERT INTO numbers 
        (
            number,
            local_format,
            int_format,
            country_prefix,
            country_code,
            country_name,
            location,
            carrier,
            line_type,
            valid
        )
        VALUES
        (
            '$number',
            '$local_format',
            '$int_format',
            '$country_prefix',
            '$country_code',
            '$country_name',
            '$location',
            '$carrier',
            '$line_type',
            $valid
        );"

    echo $QUERY | mysql --defaults-extra-file=$DB_FILE -s
}

function updateData()
    # Updates an existing record in the DB with data from the API Call. 
{
    QUERY="UPDATE numbers 
        SET 
            number = '$number',
            local_format = '$local_format',
            int_format = '$int_format',
            country_prefix = '$country_prefix',
            country_code = '$country_code',
            country_name = '$country_name',
            location = '$location',
            carrier = '$carrier',
            line_type = '$line_type',
            valid = $valid,
            updated_on = NOW()
        WHERE id = $id;"
    
    echo $QUERY | mysql --defaults-extra-file=$DB_FILE -s
}

function selectData()
    # Selects the TN's information from the DB.
{
    QUERY="SELECT $columns FROM numbers WHERE id = $id;"
    output=$(echo -e "${QUERY}" | mysql --defaults-extra-file=$DB_FILE -s --table)
    # if [[ $record_age -ne 0 ]]; 
    # then
    #     return 1
    # else
    #     return 0
    # fi
}

for ((i=0; i < ${#tns[@]}; i++))
do
    num=$(echo ${tns[$i]} | tr -dc '[:digit:]|\n')

    if [[ ${num} =~ $numberFormat ]]; 
    then
        echo "Checking DB for TN $num"
        column='number'; checkDB
        
        if [[ $? -ne 0 ]];
        then
            # echo "Record does not exist! Doing 11 digit curl!"
            # json=$(cat wip/${num}.json); getData
            json=$(curl -s "${baseURL}${endpoint}?access_key=${access_key}&number=${num}"); sleep 2
            getData; insertData # && echo "DB Updated!"
            checkDB; selectData; echo -e "$output \n"
        else
            # echo "Checking Record Age"
            checkRecord_age
            
            if [[ $? -ne 0 ]]; 
            then
                # echo "Record too old! Doing 11 digit curl!"
                # json=$(cat wip/${num}.json); getData
                json=$(curl -s "${baseURL}${endpoint}?access_key=${access_key}&number=${num}"); sleep 2
                getData; updateData # && echo "DB Updated!"
                checkDB; selectData; echo -e "$output \n"
            else
                # echo "Record exists and is not too old. Selecting info"
                selectData; echo -e "$output \n"
            fi
            
        fi

    elif [[ ${num} =~ $localFormat ]]; 
    then
        read -p "TN $num is only 10 digits. Enter 2 letter Country Code: " country_code
        if [[ "$country_code" =~ ^[a-zA-Z]{2}$ ]]; 
        then
            echo "Checking DB for TN $num"
            column='local_format'; checkDB "AND country_code = '$country_code'"
            
            if [[ $? -ne 0 ]];
            then
                # echo "Record does not exist! Doing 10 digit curl!"
                # json=$(cat wip/${num}.json); getData
                json=$(curl -s "${baseURL}${endpoint}?access_key=${access_key}&number=${num}&country_code=${country_code}"); sleep 2
                getData; insertData # && echo "DB Updated!"
                checkDB "AND country_code = '$country_code'"; selectData; echo -e "$output \n"
            else
                # echo "Checking Record Age"
                checkRecord_age
                
                if [[ $? -ne 0 ]]; 
                then
                    # echo "Record too old! Doing 10 digit curl!"
                    # json=$(cat wip/${num}.json); getData
                    json=$(curl -s "${baseURL}${endpoint}?access_key=${access_key}&number=${num}&country_code=${country_code}"); sleep 2
                    getData; updateData # && echo "DB Updated!"
                    checkDB "AND country_code = '$country_code'"; selectData; echo -e "$output \n"
                else
                    # echo "Record exists and is not too old. Selecting info"
                    selectData; echo -e "$output \n"
                fi
                
            fi
        else
            echo "Error: Invalid Country Code Format"
            continue  
        fi
    else
        echo "Error: TN ${num} is in an invalid format."
        continue
    fi
done
