import os
import re
import json
import urllib
import datetime as dt
from logging import getLogger, DEBUG, INFO, WARNING, ERROR, StreamHandler
import boto3
from requests_aws4auth import AWS4Auth
from opensearchpy import OpenSearch, RequestsHttpConnection

logger = getLogger(__name__)
handler = StreamHandler()
handler.setLevel(INFO)
logger.setLevel(INFO)
logger.addHandler(handler)
logger.propagate = False

S3_CLIENT = boto3.client('s3')
OS_ENDPOINT = os.getenv('OS_ENDPOINT')


def get_object_list(event):
    object_list = []

    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        key = urllib.parse.unquote_plus(
            record['s3']['object']['key'], encoding='utf-8')
        object_list.append((bucket, key))

    return object_list


def get_object(bucket, key):
    try:
        response = S3_CLIENT.get_object(Bucket=bucket, Key=key)
        logger.info('Get S3 Object: ' + bucket + '/' + key)
        return response['Body'].read().decode('UTF-8')
    except Exception as e:
        logger.error(e)
        logger.error(
            f'Error getting object {key} from bucket {bucket}. Make sure they exist and your bucket is in the same region as this function.')
        raise e


def parse_cowrie_log(logdata):
    out_log = []
    for line in logdata.split('\n'):
        if line == '':
            continue
        out_log.append(json.loads(line))
        out_log[-1]['log'] = json.loads(out_log[-1]['log'])

    return out_log


def parse_mysql_honeypotd_log(logdata):
    out_log = []
    log_format = r''

    for line in logdata.split('\n'):
        if line == '':
            continue
        out_log.append(json.loads(line))
        pot_log = json.loads(line)['log']
        logger.debug(pot_log)

    return out_log


def create_os_client():
    os_region = 'ap-northeast-1'
    service = 'aoss'
    credentials = boto3.Session().get_credentials()
    awsauth = AWS4Auth(credentials.access_key, credentials.secret_key,
                       os_region, service, session_token=credentials.token)

    os_client = OpenSearch(
        hosts=[{'host': OS_ENDPOINT, 'port': 443}], http_auth=awsauth,
        use_ssl=True, http_compress=True, verify_certs=True,
        retry_on_timeout=True, connection_class=RequestsHttpConnection,
        timeout=60)
    return os_client


def put_logs_to_opensearch(os_client, logdata):
    load_data = ''
    for log in logdata:
        index_name = log['container_name'].replace('-service', '')
        req = {'index': {'_index': index_name}}
        load_data += json.dumps(req) + '\n' + json.dumps(log) + '\n'

    response = os_client.bulk(load_data)
    logger.info(response)


def lambda_handler(event, _):
    logger.info(event)

    if OS_ENDPOINT:
        object_list = get_object_list(event)
        parsed_data = []
        for obj in object_list:
            bucket = obj[0]
            obj_key = obj[1]
            object_body = get_object(bucket, obj_key)
            if 'cowrie/' in obj_key:
                parsed_data.extend(parse_cowrie_log(object_body))

            elif 'mysql-honeypotd/' in obj_key:
                parsed_data.extend(parse_mysql_honeypotd_log(object_body))
            else:
                raise Exception

        os_client = create_os_client()
        put_logs_to_opensearch(os_client, parsed_data)
    else:
        logger.warning('OS_ENDPOINT is not set.')


if __name__ == "__main__":
    lambda_handler('', '')
