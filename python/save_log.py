from boto3 import resource

log_file = 'log.txt'
bucket_name = 'ia-censo-tc'

s3 = resource('s3')

log_data = open(log_file, 'rb')
s3.Bucket(bucket_name).put_object(Key = log_file, Body = log_data,
                                 ContentType = 'text/txt', ACL = 'public-read')
