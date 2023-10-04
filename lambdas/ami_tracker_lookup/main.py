import json
import boto3
import os
from aws_lambda_powertools import Logger
from aws_lambda_powertools.utilities.typing import LambdaContext

logger = Logger()
region = os.getenv('REGION', 'us-east-1')
table_name = os.getenv('DYNAMODB_TABLE_NAME', 'AmiTracker')
topic_arn = os.environ['SNS_TOPIC_ARN']

# return current version of ami image id with filter type
def lookup_filter(source):
    try:
        # get current version filter type ami
        ec2 = boto3.client('ec2')
        response = ec2.describe_images(
            Filters=source
        )

        # sort images by creationdate release in descending order
        response['Images'].sort(
            key=lambda x: x['CreationDate'],
            reverse=True
        )

        # return current version ami image id
        return response['Images'][0]['ImageId']

    except Exception as e:
        logger.error(
            f'An error occurred while trying to get latest AMI ID: {e}')
        raise e

# return current version of ami image id with ssm type
def lookup_ssm(source):
    try:
        # get current version ssm type ami
        ssm = boto3.client('ssm')
        response = ssm.get_parameter(
            Name=source
        )

        # return current version ami image id
        return response['Parameter']['Value']
    except Exception as e:
        logger.error(
            f'An error occurred while trying to get latest AMI ID: {e}')
        raise e


def ddb_ami_version_update(ami_name, marketplace_ami_current_version):
    try:
        # write dynamo table/update item
        dynamodb = boto3.resource('dynamodb', region_name=region)
        table = dynamodb.Table(table_name)

        # update the ami name with newest ami image id
        response = table.update_item(
            Key={
                'AmiName': ami_name
            },
            UpdateExpression='SET CurrentVersion = :newCurrentVersion',
            ExpressionAttributeValues={
                ':newCurrentVersion': marketplace_ami_current_version
            },
            ReturnValues='UPDATED_NEW'
        )
        return response
    except Exception as e:
        logger.error(
            f'An error occurred while trying to update the AMI version in DynamoDB: {e}')
        raise e


def sns_new_version_message(ami_name, marketplace_ami_current_version):
    if os.environ.get('RESTORE_DB', False):
        logger.info('Skipping SNS message for database restoration')

    # data object to send to sns topic
    data = {
        "v1": {
            "Message": f"A new version of the {ami_name} has been released. You are now able to launch new EC2 instances from these AMIs.",
            "image":  {
                "image_name": f"{ami_name}",
                "image_id": f"{marketplace_ami_current_version}"
            },
            "region": f"{region}"
        }
    }

    try:
        # publish message to sns topic
        sns = boto3.client('sns')
        response = sns.publish(
            TopicArn=topic_arn,
            Message=json.dumps(data)
        )
        message_id = response['MessageId']
        logger.info(
            f'Sns Topic message published successfully. Message id: {message_id}')
    except Exception as e:
        logger.error(f'Failed to publish message to the SNS topic: {e}')
    raise e


@logger.inject_lambda_context
def handler(event, context):
    try:
        body = json.loads(event['Records'][0]['body'])

        # ami name from ddb
        ami_name = body['AmiName']

        ami_filter = body['Filters'] if 'Filters' in body else ''
        ssm_parameter = body['ParameterPath'] if 'ParameterPath' in body else ''

        # ami current_version from ddb
        ddb_ami_current_version = body['CurrentVersion']
        logger.info(
            f'AMI ID in dynamodb for AMI Name: {ami_name} is {ddb_ami_current_version}')

        current_version = ''
        if len(ami_filter) > 0:
            # current version update from AWS Marketplace Filter Type
            current_version = lookup_filter(ami_filter)
        else:
            # current version update from AWS Marketplace SSM Type
            current_version = lookup_ssm(ssm_parameter)

        logger.info(
            f'Latest version of AMI Name: {ami_name} is {current_version}')

        # compare the ami image_id version within ddb and newest version from AWS Marketplace
        # if not the same version write newest ami image_id version from AWS Marketplace to ddb table and send sns message
        if ddb_ami_current_version != current_version:
            ddb_ami_version_update(ami_name, current_version)
            sns_new_version_message(ami_name, current_version)
        else:
            # no version change for ami image_id
            logger.info(
                f'AMI Name: {ami_name} image_id is the same value no new version available')
            return None

    except Exception as e:
        logger.error(f'Error: {e}')
        raise e
