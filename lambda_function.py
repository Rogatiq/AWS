import json
import os
import boto3

dynamo = boto3.client('dynamodb')
table_name = os.environ['DYNAMO_TABLE']

def lambda_handler(event, context):
    for record in event['Records']:
        filename = record['s3']['object']['key']
        dynamo.put_item(
            TableName=table_name,
            Item={
                'filename': {'S': filename}
            }
        )
    return {'statusCode': 200, 'body': json.dumps('OK')}