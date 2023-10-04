import ast
import boto3
import logging
import os
import yaml
import argparse

p = argparse.ArgumentParser()
p.add_argument('-r', '--region', dest='region', action='store', default='us-east-1',
               help='Region where your Dynamodb table resides', required=True)
p.add_argument('-t', '--table_name', dest='table_name', action='store', default='AmiTracker',
               help='Name of the DynamoDB table to store lookup config', required=True)
p.add_argument('-d', '--images_dir', dest='images_dir', action='store', default='./tracked_images',
               help='Directory where tracked images definitions are stored', required=True)


logger = logging.getLogger()
logger.setLevel(logging.INFO)


def load_yaml_config():
    tracked_images_yaml = []
    with os.scandir(args.images_dir) as images_config:
        for entry in images_config:
            if entry.name.endswith('.yml') and entry.is_file():
                with open(f'{entry.path}') as f:
                    yaml_config = yaml.safe_load(f)
                    tracked_images_yaml += yaml_config['images']

    for img in tracked_images_yaml:
        if 'Filters' in img:
            filters = img['Filters']
            # HACK: We want to store this data as an array of maps
            #      to easily pass to the Filters parameter of the ec2 describe_images call
            #      add a trailing comma for the ast.literal_eval call to ensure dynamo stores this properly
            if img['Filters'].count('{') == 1:
                filters = filters + ','

            img['Filters'] = [a for a in ast.literal_eval(filters)]

    return tracked_images_yaml


def load_db_config(table):
    response = None
    lastKey = None
    tracked_images_db = []
    while True:
        if lastKey is not None:
            response = table.scan(ExclusiveStartKey=lastKey)
        else:
            response = table.scan()
        if 'Items' in response:
            for item in response['Items']:
                tracked_images_db.append(item)

        if 'LastEvaluatedKey' in response:
            lastKey = response['LastEvaluatedKey']
        else:
            break

    return tracked_images_db


def compare_lists(tracked_images_yaml, tracked_images_db):
    removed = []
    changed = []
    new = [new_img for new_img in tracked_images_yaml if new_img['Name']
           not in [img['AmiName'] for img in tracked_images_db]]

    for db_image in tracked_images_db:
        yaml = [yml_img for yml_img in tracked_images_yaml if yml_img['Name']
                == db_image['AmiName']]

        if len(yaml) == 0:
            removed.append(db_image)
        else:
            image = yaml[0]
            if 'Filters' in image and image['Filters'] != db_image['Filters']:
                changed.append(image)
            if 'ParameterPath' in image and image['ParameterPath'] != db_image['ParameterPath']:
                changed.append(image)

    return new, changed, removed


def insert_config(table, new_images):
    for img in new_images:
        if 'Filters' in img:
            item = {
                'AmiName': img['Name'],
                'Filters': img['Filters'],
                'CurrentVersion': ''
            }
        else:
            item = {
                'AmiName': img['Name'],
                'ParameterPath': img['ParameterPath'],
                'CurrentVersion': ''
            }

        response = table.put_item(
            Item=item
        )


def update_config(table, updated_images):
    for img in updated_images:

        if 'Filters' in img:
            update_expression = 'SET Filters = :newValue'
            value = img['Filters']
        else:
            update_expression = 'SET ParameterPath = :newValue'
            value = img['ParameterPath']

        try:
            response = table.update_item(
                Key={
                    'AmiName': img['Name']
                },
                UpdateExpression=update_expression,
                ExpressionAttributeValues={
                    ':newValue': value
                },
                ReturnValues='UPDATED_NEW'
            )
            return response
        except Exception as e:
            logger.error(
                f'An error occurred while trying to update the AMI version in DynamoDB: {e}')
            raise e


def delete_config(table, deleted_images):
    for img in deleted_images:
        try:
            print(img)
            table.delete_item(Key={'AmiName': img['AmiName']})
        except Exception as e:
            logger.error(
                f'An error occurred while trying to update the AMI version in DynamoDB: {e}')
            raise e


def main(**kwargs):
    print(args.images_dir)
    print(os.path.abspath(args.images_dir))

    ddb_resource = boto3.resource('dynamodb', region_name=args.region)

    table = ddb_resource.Table(args.table_name)

    tracked_images_yaml = load_yaml_config()
    tracked_images_db = load_db_config(table)

    new, changed, removed = compare_lists(
        tracked_images_yaml, tracked_images_db)

    insert_config(table, new)
    update_config(table, changed)
    delete_config(table, removed)


if __name__ == '__main__':
    args = p.parse_args()
    main(**vars(args))
