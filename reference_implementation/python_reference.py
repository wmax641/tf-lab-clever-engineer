#!/usr/bin/python3
#   by wmax641
#
# This is a reference implementation for 'tf-lab-clueless-engineer' in python3
#
# By all means read through this if you're having trouble with the programming component of 
# the lab, but any code you write for the lab must be all your own code.

import requests
import argparse
import re
import sys
import base64

_URL_REGEX_PATTERN = "^[a-z0-9]+\.execute-api\.[a-z0-9-]+\.amazonaws.com$"

# Clean up the input url to get a URL in form:
#   XXXXXXXXX.execute-api-ap-southeast-2.amazonaws.com
def get_base_url(url:str) -> str:

    # get the URL into the correct format
    if url.endswith("/"):
        url = url[:-1]

    # Get rid of leading http/https
    if "http://" in url.lower() or "https://" in url.lower():
        url = url.split("//")[1]

    if re.match(_URL_REGEX_PATTERN, url) is None:
        print(f"Error: [--url, -u] argument did not match pattern: {_URL_REGEX_PATTERN}")
        print("Exiting...")
        sys.exit(1)

    return(url)


if __name__ == "__main__":

    parser = argparse.ArgumentParser()
    parser.add_argument('-u', '--url', required=True, help="base URL of the API endpoint;\n \
                        eg. https://XXXXXXXXX.execute-api-ap-southeast-2.amazonaws.com")
    parser.add_argument('-i', '--id', required=True, help="Unique ID for the lab")
    args = parser.parse_args()

    # Prepare URL to request
    uniq_ud = args.id
    base_url = get_base_url(args.url)
    url = f"https://{base_url}/v1/logs?id={args.id}"

    # Make HTTP request
    print(f"HTTP GET: {url}")
    r = requests.get(url)

    # Exit if error
    if not r.ok:
        print(f"Error - HTTP {r.status_code};\n{r.text}")
        print("Exiting...")
        sys.exit(1)

    # return should be JSON in this form - so iterate through the logs
    #   {
    #       "error" : false,
    #       "id"    : <id>,
    #       "logs"  : [
    #           "[YYYY-MM-DD HH:MM:SS] XXXX[XXXX]:    <BASE64_STR>",
    #           "[YYYY-MM-DD HH:MM:SS] XXXX[XXXX]:    <BASE64_STR>",
    #           "...",
    #       ]
    #   }
    for row in r.json()["logs"]:
        try:
            eNcRyPtED_str = row.split(":")[-1].split(" ")[-1]
            DeCRypTeD_str = base64.b64decode(eNcRyPtED_str).decode("utf-8")
        except Exception as e:
            print(f"Error - Exception {type(e)} - str(e) while processing row;")
            print(f"{row}")
            print("Skipping...")
            continue

        if "password" in DeCRypTeD_str.lower():
            print("! ! ! Possible password found ! ! !")
            print(f"eNcRyPtED string: {eNcRyPtED_str}")
            print(f"DeCRypTeD_string: {DeCRypTeD_str}")
