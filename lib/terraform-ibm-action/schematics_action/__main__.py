from ibm_cloud_sdk_core.authenticators import IAMAuthenticator
from ibm_schematics.schematics_v1 import SchematicsV1
import json
import time
import os
import random
import string
import hashlib

schematics_service = None

def getActionById(action_id):
    response = schematics_service.get_action(
        action_id=action_id
    )
    action_response = response.get_result()
    return action_response

def getJobById(job_id):
    response = schematics_service.get_job(
        job_id=job_id
    )
    job_response = response.get_result()
    return job_response

def waitForActionStatus(action_id):
    actionStatus = "pending"

    while actionStatus == "pending":
        actionStatus = getActionById(action_id)['state']['status_code']
        time.sleep(2)
    
    return actionStatus

def waitForJobCompletion(job_id):
    jobStatus = "job_pending"

    while jobStatus == "job_pending" or jobStatus == "job_in_progress"  :
        jobStatus = getJobById(job_id)['status']['action_job_status']['status_code']
        time.sleep(2)

    return jobStatus

def find_instance_group_action(action_name):
    detResponse = schematics_service.list_actions()
    response = detResponse.get_result()
    if 'actions' in response:
        for action in response['actions']:
            if action['name'] == action_name:
                return action
    return None

def genHash(repo_url, env_name, ip_list):
    m = hashlib.md5()
    m.update(repo_url.encode('utf-8'))
    m.update(env_name.encode('utf-8'))
    for i in ip_list:
        m.update(i.encode('utf-8'))
    return m.hexdigest()

def main(params):

    authenticator = IAMAuthenticator(
        apikey = os.environ.get("__OW_IAM_NAMESPACE_API_KEY"),
        client_id='bx',
        client_secret='bx'
    )

    refresh_token = authenticator.token_manager.request_token()['refresh_token']
    
    global schematics_service
    
    schematics_service = SchematicsV1(authenticator = authenticator)
    schematics_service.set_service_url('https://schematics.cloud.ibm.com')

    actions = params['actions']
    inventories = params['inventories']

    fqaction = params['action'].split('.')
    actionkey = fqaction[0]
    action = fqaction[1]

    repo_url = actions[actionkey]['action_repo_url']
    env_name = params['env_name']

    instance_group_hash = genHash(repo_url, env_name, inventories[env_name]['instance_ip_list'])
    command_parameter = actions[actionkey]['action_yml_map'][action]
    
    action_name = actionkey +  str(instance_group_hash)
    instance_group_action = find_instance_group_action(action_name)

    status = {
        'action_status' : '',
        'job_status' : ''
    }

    if not instance_group_action:
        response = schematics_service.create_action(
            name = action_name,
            description = "This Action can be used to Start/Stop the VSI",
            location = "us-east",
            resource_group = "default",
            source = {
                'source_type' : 'git',
                'git' : {
                    'git_repo_url' : repo_url
                },
            },
            command_parameter = command_parameter,
            user_state = {
                'state' : 'live'
            },
            source_readme_url = "",
            source_type = "GitHub",
            inputs = [{
                'name' : 'instance_ip_list',
                'value' : ",".join(inventories[env_name]['instance_ip_list'])
            }]
        )

        if response.get_status_code() == 201:
            action_id = response.get_result()['id']
            actionStatus = waitForActionStatus(action_id)
            status['action_status'] = actionStatus
            if actionStatus != "normal" :
                return status
        else:
            status['action_status'] = "action creation failed"
            return status
    else:
        action_id = instance_group_action['id']
        status['action_status'] = instance_group_action['state']['status_code']


    response = schematics_service.create_job(
        refresh_token = refresh_token,
        command_object = "action",
        command_object_id = action_id,
        command_name = "ansible_playbook_run",
        command_parameter = command_parameter,
        location = "us-east"
    )

    jobStatus = waitForJobCompletion(response.get_result()['id'])

    status['job_status'] = jobStatus

    return status

