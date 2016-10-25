import json
import requests
import os
import subprocess
import sys
import argparse

'''
Usage:
python post-result.py \
--github_pr_url https://api.github.com/repos/RackHD/on-core/issues/${PullRequestId}/comments \
--jenkins_url http://rackhdci.lss.emc.com \
--build_url http://rackhdci.lss.emc.com/job/on-core/851/ \
--build_name '#851' \
--public_jenkins_url http://147.178.202.18/
'''

#with open('${HOME}/.ghtoken', 'r') as file:
with open('/home/onrack/.ghtoken', 'r') as file:
    TOKEN = file.read().strip('\n')

HEADERS = {'Authorization': 'token %s' % TOKEN}

GITHUB_PR_URL = ""
JENKINS_URL = ""
BUILD_URL = ""
BUILD_NAME = ""
PUBLIC_JENKINS_URL = ""
FAIL_REPORTS = []

def parse_args(args):
    parser = argparse.ArgumentParser()
    parser.add_argument('--github_pr_url',
                        required=True,
                        help="The url of the pull request in github",
                        action="store")
    parser.add_argument('--jenkins_url',
                        required=True,
                        help="The url of the internal jenkins",
                        action="store")
    parser.add_argument('--build_url',
                        required=True,
                        help="the url of the build in jenkins",
                        action="store")
    parser.add_argument('--build_name',
                        required=True,
                        help="the name of the build in jenkins",
                        action="store")
    parser.add_argument('--public_jenkins_url',
                        required=True,
                        help="the url of the public jenkins",
                        action="store")

    parsed_args = parser.parse_args(args)
    return parsed_args

def get_build_data(build_url):
    '''
    get the json data of a build
    :param build_url: the url of a build in jenkins
    :return: json data of the build if succeed to get the json data
             None if failed to get the json data
    '''
    r = requests.get(build_url + "/api/json?depth=2")
    if is_error_response(r):
        print "Failed to get api json of {0}".format(build_url)
        print r.text
        print r.status_code
        return None
    else:
        data = r.json()
        return data

def is_error_response(res):
    """
    check the status code of http response
    :param res: http response
    :return: True if the status code less than 200 or larger than 206;
             False if the status code is between 200 and 206
    """
    if res is None:
        return True
    if res.status_code < 200 or res.status_code > 299:
        return True
    return False

def post_comments_to_github(comments, github_pr_url, headers):
    '''
    post comments to github Pull Request
    :param comments: comments to be posted to Pull Request
    :param github_pr_url: the url of the PR
    :param headers: the request headers which usually contains the "Authorization" field
    :return: exit with error code 1 if get bad response for the request
             return null if get successful response
    '''
    body = { "body" : comments }
    r = requests.post(github_pr_url,headers=headers,data=json.dumps(body))
    if is_error_response(r):
        print "Failed to post comments to pull request {0}".format(github_pr_url)
        print r.text
        print r.status_code
        sys.exit(1)
    else:
        print "Succeed to post comments to pull request {0}".format(github_pr_url)
        return
                
def main():
    OUTPUT = ""
    job_name = BUILD_URL.split('/')[-3]
    build_number = BUILD_URL.split('/')[-2]

    public_build_url = BUILD_URL.replace(JENKINS_URL, PUBLIC_JENKINS_URL)
    try:
        build_data = get_build_data(BUILD_URL)
        if build_data:
            build_name = build_data['fullDisplayName']
            build_result = build_data['result']
            OUTPUT +=  "BUILD [" + build_name + "](" + public_build_url + ") : " + build_result + "\n"
    except Exception as e:
        print e
        sys.exit(1)
    finally:
        if OUTPUT == "":
            build_name = job_name + " #" + build_number
            OUTPUT += "BUILD [" + build_name + "](" + public_build_url + ") \n"
        post_comments_to_github(OUTPUT, GITHUB_PR_URL, HEADERS)

if __name__ == "__main__":
    # parse arguments
    parsed_args = parse_args(sys.argv[1:])
    GITHUB_PR_URL = parsed_args.github_pr_url
    JENKINS_URL = parsed_args.jenkins_url
    BUILD_URL = parsed_args.build_url
    BUILD_NAME = parsed_args.build_name
    PUBLIC_JENKINS_URL = parsed_args.public_jenkins_url
    main()
