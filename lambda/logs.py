#!/usr/bin/env python3
# Lambda funciton to generate random logs given the appropriate [id] param
#

import boto3
from datetime import datetime
from datetime import timedelta
import random
import base64
import string
import json
import os

_LOG_LINES = 1337

def gen_random_ipaddr() -> str:
    return(".".join([str(random.randint(0, 255)) for x in range(4)]))

def gen_random_str(l0, l1) -> str:
    valid_chars = string.ascii_uppercase + string.ascii_lowercase + string.digits
    return(''.join(random.choice(valid_chars) for _ in range(random.randint(l0, l1))))

def gen_httpd_log_message() -> str:
    ipaddr = gen_random_ipaddr()
    http_status = random.choice(["200","301", "403", "418", "500"])
    http_action = random.choice(["GET", "POST", "PUT", "DELETE"])
    url = gen_random_str(6,16) + ".html"
    return('"{} {} /{} HTTP/1.0" {} 1337'.format(ipaddr, http_action, url, http_status))

def gen_ssh_log_message() -> str:
    action = random.choice([
        "Connected to {} with fingerprint {}".format(gen_random_ipaddr(),gen_random_str(10,20)), 
        "Connected to sec@{} fingerprint {}".format(gen_random_ipaddr(),gen_random_str(11,22)), 
        "Attempt connect to {} port 22".format(gen_random_ipaddr()), 
        "Authenticating to {} port 22".format(gen_random_ipaddr()), 
        "Authenticated to {} port 22 with key".format(gen_random_ipaddr()), 
        "Host {}.com Local version string SSH-2.0-OpenSSH_6.1".format(gen_random_str(4,10)),
        "root@{}: Permission denied".format(gen_random_ipaddr()),
        "root@{}: authentication failed".format(gen_random_ipaddr()),
        "Server host key: ssh-rsa SHA256:{}".format(gen_random_str(14,20)),
        "Remote public key: ed25519 {}".format(gen_random_str(26, 34)),
        "{} is {}'s host signature".format(gen_random_str(28, 36),gen_random_ipaddr()),
        "{} is {}'s public key".format(gen_random_str(23, 40), gen_random_ipaddr()),
        "{} has key {}".format(gen_random_ipaddr(), gen_random_str(20,34)),
    ])
    return(action)

def gen_sshd_log_message() -> str:
    ipaddr = gen_random_ipaddr()
    action = random.choice([
        "Accepted ed25519 public key for root from {}", 
        "Accepted rsa public key for admin from {}", 
        "Rejected rsa public key for user {}",
        "Rejected ed25519 public key for root from {}",
        "Host {} is starting up server",
        "{} : 22 is now listening",
        "Connection closed from {}",
        "Connection opened by {}",
        "{} is connecting",
    ])
    return(action.format(ipaddr))

def gen_postfix_log_message() -> str:
    ipaddr = gen_random_ipaddr()
    action = random.choice(["connect", "disconnect", "authentication", "EHLO", "HELO"])
    hostname = gen_random_str(7, 16)
    return("{} from {}.com [{}]".format(action, hostname, ipaddr))

_GENERATE_LOG_FOR = {
    "httpd"     : gen_httpd_log_message,
    "sshd"      : gen_sshd_log_message,
    "ssh"       : gen_ssh_log_message,
    "postfix"   : gen_postfix_log_message,
}

def gen_logs(host:str, username:str, password:str, port:str) -> list[str]:
    ret = []
    dt0 = datetime.now() - timedelta(days=1)
    line_number_with_leak = random.randint(_LOG_LINES>>~-4, -10+~-~-_LOG_LINES>>3<<3-1)

    for i in range(_LOG_LINES):

        dt_str = dt0.strftime("%Y-%m-%d %H:%M:%S")
        proc_id = random.randint(1, 65535)

        # This is the password leak. It only occurs once
        if i == line_number_with_leak:
            proc = "ssh"
            salt = gen_random_str(2,3)
            cred_leak_msg = random.choice([
             "Connected to {}@{}:{} with password {}".format(username,host,port,password),
             "Authenticated to {}@{}:{} with password {}".format(username,host,port,password),
             "Connected with password {} to {}@{}:{}".format(password,username,host,port),
             "Authenticated to {}@{} password {} port {}".format(username,host,password,port),
            ])
            msg = "{} {}".format(salt, cred_leak_msg)

        # Generic log message
        else:
            proc = random.choice(list(_GENERATE_LOG_FOR.keys()))
            msg = _GENERATE_LOG_FOR[proc]()
        
        header_msg = "[{}] {}[{}]:".format(dt_str, proc, proc_id)
        b64_msg = base64.b64encode(msg.encode("ascii")).decode("ascii")
        ret.append("{:37}{}".format(header_msg, b64_msg))

        dt0 += timedelta(seconds=random.randint(1, 120))

    return(ret)

def lambda_handler(event, context):

    print(event)

    # Set some default values
    logs = []
    statusCode = 500
    content_type = "application/json"
    uniq_id = ""
    ipaddr = ""
    username = ""
    passwd = ""
    ret = {
        "error":True,
        "id":""
    }

    # ensure id parameter exists, otherwise quick exit
    try:
        uniq_id = event["queryStringParameters"]["id"]
        print('PARAMETER["id"] = {}'.format(uniq_id[:50]))
        if len(uniq_id) < 5 or len(uniq_id) > 30:
            raise(KeyError)
        ret["id"] = uniq_id

    except (KeyError, TypeError) as e:
        print("KeyError exception while reading 'id' param - {}".format(str(e)))
        ret["error_msg"] = "No or invalid 'id' parameter provided"
        return {
            'statusCode': 400,
            'headers':{"Content-Type": "application/json"},
            'body': json.dumps(ret, indent=3)
        }
    except Exception as e:
        print("Unhandled exception while reading 'id' param - {}".format(str(e)))
        ret["error_msg"] = "Unhandled server side error: {}".format(str(e))
        return {
            'statusCode': 500,
            'headers':{"Content-Type": "application/json"},
            'body': json.dumps(ret, indent=3)
        }

    
    try:
        # Pull values out of SSM param store
        ssm = boto3.client('ssm')

        base_param = "{}-{}".format(os.environ['base_param_path'], uniq_id)

        ipaddr = ssm.get_parameter(Name="{}/ip".format(base_param))["Parameter"]["Value"]
        username = ssm.get_parameter(Name="{}/username".format(base_param))["Parameter"]["Value"]
        passwd = ssm.get_parameter(Name="{}/cred".format(base_param))["Parameter"]["Value"]

        # Really secure debugging!!!1
        print("{}, {}, {}, {}".format(uniq_id, ipaddr, username, passwd))

        # Finally generate the logs
        logs = gen_logs(host=ipaddr, username=username, password=passwd, port="22")
        ret["error"] = False

    except (KeyError, ssm.exceptions.ParameterNotFound) as e:
        print("Key Error exception while generating logs - {}".format(str(e)))
        ret["error_msg"] = "Invalid id parameter provided"
        return {
            'statusCode': 400,
            'headers':{"Content-Type": "application/json"},
            'body': json.dumps(ret, indent=3)
        }
    except Exception as e:
        print("Unhandled exception while generating logs - {}".format(str(e)))
        ret["error_msg"] = "Unhandled server side error: {}".format(str(e))
        return {
            'statusCode': 500,
            'headers':{"Content-Type": "application/json"},
            'body': json.dumps(ret, indent=3)
        }

    # change to txt output if requested. This only works if the statusCode is already 200
    if ("txt" in event["queryStringParameters"] and 
        event["queryStringParameters"]["txt"].lower() == "true"):

        content_type = "text/plain"
        body = "\n".join(logs) 

    # otherwise, default json
    else:
        ret["logs"] = logs
        body = json.dumps(ret, indent=3) 

    return {
        'statusCode': 200,
        'headers':{"Content-Type": content_type},
        'body': body
    }

if __name__ == "__main__":
    passwd = "".join(random.choice(string.ascii_letters) for i in range(16))
    logs = gen_logs(host="1.3.3.7", username="seceng", password=passwd, port="22")
    for line in logs:
        print(line)
