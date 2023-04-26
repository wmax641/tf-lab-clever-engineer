#!/usr/bin/env python3
# Lambda function to operate on server
# get status or delete the lab instance corresponding to the provided [id] param

import boto3
from datetime import datetime
from datetime import timedelta
import json
import os

_SECONDS_BETWEEN_INSTANCE_TERMINATION = 900

# Check the stored ssm param to see if it's been sufficient delay since last deletion
# Returns (bool, int) if okay or not, and if not okay, the number of seconds to wait
# Returns (None, None) on unhandled exception
def is_ok_to_del_datetime_to_delete(uniq_id:str) -> [bool, int]:

    ssm = boto3.client('ssm')
    dt_param_path = "{}-{}/terminated-datetime".format(os.environ['base_param_path'], uniq_id)
    try:
        #last_dt_unix = ssm.get_parameter(Name=param_path)["Parameter"]["Value"]
        #dt_last = datetime.fromtimestamp(int(last_dt_unix))
        dt_last_unixtime = int(ssm.get_parameter(Name=dt_param_path)["Parameter"]["Value"])
    except (KeyError, ssm.exceptions.ParameterNotFound) as e:
        print("KeyError exception at is_ok_to_del_datetime_to_delete() - {}".format(str(e)))
        return((None,None))
    except Exception as e:
        print("Unhandled exception at is_ok_to_del_datetime_to_delete() - {}".format(str(e)))
        return((None,None))

    now_unixtime = int(datetime.now().timestamp())
    delta_seconds = now_unixtime - dt_last_unixtime

    if delta_seconds > _SECONDS_BETWEEN_INSTANCE_TERMINATION:
        return((True, 0))
    else:
        return((False, _SECONDS_BETWEEN_INSTANCE_TERMINATION - delta_seconds))

# Get list of instance_ids that correspond to a uniq_id
# Returns None if unhandled exception, 
# Returns [] if no instance found with the provided uniq_id tag
# otherwise returns tuple of (instance_id, "state")
# Possible states: 0:pending, 16:running, 32:shutting-down, 48:terminating, 
#                  64:stopping, 80:stopped
def get_instance_ids_for_uniq_id(uniq_id:str) -> list[tuple[str, str]]:
    ec2 = boto3.client('ec2')
    ret = []

    try:
        r = ec2.describe_instances(Filters=[{"Name":"tag:uniq_id", "Values":[uniq_id]}])

        # if no instances found with tag
        if len(r["Reservations"]) == 0:
            return([])

        for rezo in r["Reservations"]:
            for instance in rezo["Instances"]:
                ret.append((instance["InstanceId"], instance["State"]["Name"]))
    except Exception as e:
        print("Unhandled exception at get_instance_ids_for_uniq_id() - {}".format(str(e)))
        return(None)

    return(ret)


def delete_instances(matching_ids_list : list[tuple[str, bool]]) -> None:
    ec2 = boto3.client('ec2')
    for instance_id, status in matching_ids_list:
        # Possible states: 0:pending, 16:running, 32:shutting-down, 
        # 48:terminating, 64:stopping, 80:stopped
        if status not in {"running", "stopping", "stopped", "shutting-down"}:
            continue
        try:
            print("trying to delete {} (status: {})...".format(instance_id, status))
            ec2.terminate_instances( InstanceIds=[instance_id])
        except Exception as e:
            print("Unhandled exception at delete_instances() deleting {} - {}".format(instance_id, str(e)))
            continue

def update_datetime_param(uniq_id : str) -> None:
    ssm = boto3.client('ssm')
    param_path = "{}-{}/terminated-datetime".format(os.environ['base_param_path'], uniq_id)
    now_unixtime = int(datetime.now().timestamp())
    print("Setting param {} to{}".format(param_path, now_unixtime))
    try:
        ssm.put_parameter(Name=param_path, Value=str(now_unixtime), Overwrite=True)
    except Exception as e:
        print("Unhandled exception at update_datetime_param() - {}".format(str(e)))
    
def lambda_handler(event, context):

    ret = {"error": True, "id":""}
    
    # ensure id parameter is provided, otherwise quick exit
    try:
        uniq_id = event["queryStringParameters"]["id"]

        if len(uniq_id) < 5 or len(uniq_id) > 30:
            raise(KeyError)
        ret["id"] = uniq_id

    except (KeyError, TypeError) as e:
        ret["error_msg"] = "No or invalid 'id' parameter provided"
        print("KeyError exception while reading 'id' param - {}".format(str(e)))
        return {
            'statusCode': 400,
            'headers':{"Content-Type": "application/json"},
            'body': json.dumps(ret, indent=3)
        }
    except Exception as e:
        ret["error_msg"] = "Unhandled server side error: {}".format(str(e))
        print("Unhandled exception while reading 'id' param - {}".format(str(e)))
        return {
            'statusCode': 500,
            'headers':{"Content-Type": "application/json"},
            'body': json.dumps(ret, indent=3)
        }

    # Print Debug logs
    try:
        print("DEBUG: Parameters: {}".format(event["queryStringParameters"]))
    except:
        pass
    try:
        ua = event["requestContext"]["identity"]["userAgent"]
        ip = event["requestContext"]["identity"]["sourceIp"]
        print("DEBUG: Requestor: 'src_ip': '{}', 'ua': '{}'".format(ip, ua))
    except:
        pass

    # Try to find instances for  matching_ids_list (instance_id, bool(running or not)
    matching_ids_list = get_instance_ids_for_uniq_id(uniq_id)

    if matching_ids_list is None:
        ret["error_msg"] = "Invalid id parameter provided"
        ret["error_msg"] = "Unhandled server side error"
        return {
            'statusCode': 500,
            'headers':{"Content-Type": "application/json"},
            'body': json.dumps(ret, indent=3)
        }
    elif len(matching_ids_list) == 0:
        ret["error_msg"] = "Invalid id parameter provided"
        return {
            'statusCode': 400,
            'headers':{"Content-Type": "application/json"},
            'body': json.dumps(ret, indent=3)
        }

    # Check the stored ssm param to see if it's been sufficient delay since last deletion
    is_ok_to_del, delay = is_ok_to_del_datetime_to_delete(uniq_id)
    if is_ok_to_del is None:
        ret["error_msg"] = "Unhandled server side error"
        return {
            'statusCode': 500,
            'headers':{"Content-Type": "application/json"},
            'body': json.dumps(ret, indent=3)
        }

    # Now we Delete or Query depending on HTTP method;

    # GET request
    # Put all the statuses of all instances in the set, and take the most relevant
        # Possible states: 0:pending, 16:running, 32:shutting-down, 
        # 48:terminating, 64:stopping, 80:stopped
    # Also return some info on termination delay
    if event["httpMethod"] == "GET":
        ret["error"] = False
        ret["delete_possible"] = is_ok_to_del
        ret["delete_delay"] = delay
        status_set = set()
        for instance_id, status in matching_ids_list:
            status_set.add(status)

        if "running" in status_set:
            ret["status"] = "running"
        elif "pending" in status_set:
            ret["status"] = "pending"
        elif "shutting-down" in status_set:
            ret["status"] = "shutting-down"
        elif "terminated" in status_set:
            ret["status"] = "terminated"
        elif "stopping" in status_set:
            ret["status"] = "stopping"
        elif "stopped" in status_set:
            ret["status"] = "stopped"
            

    # DELETE request 
    else: 
        if not is_ok_to_del: 
            ret["error"] = True
            ret["error_msg"] = "Can't delete yet. Please wait another {} seconds".format(delay)
            return {
                'statusCode': 400,
                'headers':{"Content-Type": "application/json"},
                'body': json.dumps(ret, indent=3)
            }
        # go through each active instance, and terminate. 
        #Then update datetime parameter for cooldown before next termination request
        delete_instances(matching_ids_list)
        update_datetime_param(uniq_id)

        ret["error"] = False
        ret["msg"] = "Termination of server initiated. After a few minutes, the sever will be re-deployed and reset to initial settings. However, its public IP address will be different"

    # Finally if we make it here, everything was okay
    return {
          'statusCode': 200,
          'headers':{"Content-Type": "application/json"},
          'body': json.dumps(ret, indent=3)
    }

# for testing
if __name__ == "__main__":
    # need to set environment variables "uniq_id" and "base_param_path"
    uniq_id = os.environ['uniq_id']

    matching_ids_list = get_instance_ids_for_uniq_id(uniq_id)
    for i in matching_ids_list:
        print(i)
    print(is_ok_to_del_datetime_to_delete(uniq_id))
    #delete_instances(matching_ids_list)
    #update_datetime_param(uniq_id)
    #print(is_ok_to_del_datetime_to_delete(uniq_id))

