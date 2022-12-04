import os
import re
import json
import urllib
import datetime as dt
from logging import getLogger, DEBUG, INFO, WARNING, ERROR, StreamHandler
import boto3
from requests_aws4auth import AWS4Auth
from opensearchpy import OpenSearch, RequestsHttpConnection, AWSV4SignerAuth

logger = getLogger(__name__)
handler = StreamHandler()
handler.setLevel(DEBUG)
logger.setLevel(DEBUG)
logger.addHandler(handler)
logger.propagate = False

S3_CLIENT = boto3.client('s3')
OS_ENDPOIT = os.getenv('OS_ENDPOINT')


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
        print(e)
        print('Error getting object {} from bucket {}. Make sure they exist and your bucket is in the same region as this function.'.format(key, bucket))
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
    log_format = r''

    for line in logdata.split('\n'):
        pot_log = json.loads(line)['log']
        print(pot_log)

    return logdata


# def put_logdata_as_parquet(bucket, key, logdata):
#     # S3_CLIENT.put_object(Bucket=bucket, Key=key, Body=logdata.encode('UTF-8'))
#     df = pandas.DataFrame(logdata)
#     df.to_parquet('/tmp/tmp.parquet')
#     S3_CLIENT.upload_file('/tmp/tmp.parquet', bucket, key)


def create_os_client():
    os_region = 'ap-northeast-1'
    service = 'aoss'
    credentials = boto3.Session().get_credentials()
    # awsauth = AWSV4SignerAuth(credentials, os_region)
    awsauth = AWS4Auth(credentials.access_key, credentials.secret_key,
                       os_region, service, session_token=credentials.token)

    os_client = OpenSearch(
        hosts=[{'host': OS_ENDPOIT, 'port': 443}], http_auth=awsauth,
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

    os_client.bulk(load_data)


def lambda_handler(event, _):
    logger.info(event)

    object_list = get_object_list(event)
    parsed_data = []
    for obj in object_list:
        bucket = obj[0]
        obj_key = obj[1]
        object_body = get_object(bucket, obj_key)
        if 'cowrie/' in obj_key:
            parsed_data.extend(parse_cowrie_log(object_body))
            # parsed_log_key = obj_key.replace('RawLogs/', 'ParsedLogs/')
            # parsed_log_key += '.parquet'
            # put_logdata_as_parquet(bucket, parsed_log_key, parsed_data)

        elif 'mysql-honeypotd/' in obj_key:
            # parsed_data = parse_mysql_honeypotd_log(object_body)
            pass
        else:
            raise Exception

    os_client = create_os_client()
    put_logs_to_opensearch(os_client, parsed_data)


if __name__ == "__main__":
    lambda_handler('', '')
