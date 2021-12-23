
# TNLooker - Telephone Number Lookup

- [TNLooker - Telephone Number Lookup](#tnlooker---telephone-number-lookup)
  - [Introduction](#introduction)
    - [Description](#description)
    - [How It Works](#how-it-works)
    - [Purpose](#purpose)
    - [Demo](#demo)
  - [Installation](#installation)
    - [Pre-Requisites](#pre-requisites)
    - [Quick Installation](#quick-installation)
    - [Custom Installation](#custom-installation)
  - [Usage](#usage)
  - [LICENSE](#license)

---
## Introduction 

### Description 
This tool will lookup various information, given one or more telephone numbers.

### How It Works
This shell script will perform the lookups by making requests to the NumVerify API and store the information in a MySQL database. The database is run in a Docker container and setup is automated through docker-compose. The script selects the requested information from the database and displays it. 

### Purpose
This project is purely for educational purposes and will be expanded upon as time permits. 

### Demo
[![asciicast](https://asciinema.org/a/diNog3rF3Rh1uoN5TYRhcNU55.svg)](https://asciinema.org/a/diNog3rF3Rh1uoN5TYRhcNU55)

---
## Installation
### Pre-Requisites
1. Requires Docker and Docker-Compose. 
2. Requires mysql-client[4]
3. Requires [jq][2] for parsing JSON data. 

### Quick Installation
1. Clone the repository.
2. Run `docker-compose up -d` to start the database.
3. Create a free NumVerify account [here][1].
4. Run `./tnlooker.sh -A [access_key]` where access_key is your API key from NumVerify.
5. Start performing telephone number lookups! 

### Custom Installation
* Configuration files are included in the `./config` directory for modifying the API and Database connections. 
* The included **Dockerfile** and **build_db.sql** in `./build` can be modified to customize the MySQL container.
* **NOTE** If you intend to use a different API with this script you will need to modify some of the core functions. 

[1]: https://numverify.com/product
[2]: https://linuxcommandlibrary.com/man/jq
[3]: https://github.com/Insecure88/tnlooker/blob/master/LICENSE
[4]: https://packages.ubuntu.com/focal/mysql-client-core-8.0

---

## Usage
```
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
        -p - country_prefix Display the country prefix number
        -o - country_code   Display the 2 letter country code
        -a - country_name   Display the entire country name
        -u - location       Display the town/city/state of the number.
        -c - carrier        Display the carrier name.
        -t - line_type      Display the line type (mobile, landline, or VOIP)
        -h - help           Display this help message
```

---
## LICENSE
This software is licensed under the MIT license. [See Here][3]
