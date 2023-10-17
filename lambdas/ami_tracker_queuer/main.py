import json
import boto3
import os

from aws_lambda_powertools import Logger

logger = Logger()

region = os.getenv('REGION', 'us-east-1')
table_name = os.getenv('DYNAMODB_TABLE_NAME', 'AmiTracker')
queue_url = os.environ['QUEUE_URL']

def get_ami_trackerdata():
    ami_tracker_list = []
    try:
        # ddb table
        dynamodb = boto3.resource('dynamodb', region_name=region)

        table = dynamodb.Table(table_name)
        # scan items in ddb table
        response = table.scan()
        items = response['Items']
        # extension of items in dynamodb table per page
        while 'LastEvaluatedKey' in response:
            response = table.scan(
                ExclusiveStartKey=response['LastEvaluatedKey'])
            items.extend(response['Items'])
        # for every item append to ami_tracker_list
        # return ami_tracker_list
        for i in range(len(items)):
            ami_tracker_list.append(items[i])
        return ami_tracker_list
    except Exception as e:
        logger.error(
            f'An error occured while trying to retrieve data from the DynamoDB table: {e}')
        raise e


def send_sqs_ami_trackerdata(data):
    try:
        # sqs queue
        sqs = boto3.client('sqs')
        # send each item in ami_tracker_list to sqs queue
        # return message id of data sent
        response = sqs.send_message(
            QueueUrl=queue_url,
            MessageBody=json.dumps(data)
        )
        message_id = response['MessageId']
        logger.info(f'Message id:{message_id} in the queue')
    except Exception as e:
        logger.error(
            f'An error occured while trying to send data to the SQS queue: {e}')
        raise e


def handler(event, context):
    try:
        # ami tracker data
        ami_tracker = get_ami_trackerdata()
        # every item in ami_tracker list send data to sqs
        for i in ami_tracker:
            send_sqs_ami_trackerdata(i)

        return 'Data retrieval and sending to the SQS queue completed successfully.'
    except Exception as e:
        logger.error(f'Error: {e}')
        raise e
