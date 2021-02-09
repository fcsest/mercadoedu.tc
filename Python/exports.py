from functions import cat

#==================================================================================================#
# Exports ####
cat('Exports', 'green').print()
#--------------------------------------------------------------------------------------------------#
from os import environ
from boto3 import resource
from dotenv import load_dotenv
#--------------------------------------------------------------------------------------------------#

load_dotenv()

bucket_name = 'ia-censo-tc'

log_file = 'log.txt'
boxplot_cv_file = 'cv_models.png'
confusion_matrix_file = 'confusion_matrix.png'

url = 'https://' + bucket_name + '.s3.us-east-2.amazonaws.com/'

s3 = resource('s3',
              aws_access_key_id = environ['AWS_ACCESS_KEY_ID'],
              aws_secret_access_key = environ['AWS_SECRET_ACCESS_KEY'])

#==========================================================#
cat('Boxplots').print()
#----------------------------------------------------------#
img_data = open(boxplot_cv_file, 'rb')
s3.Bucket(bucket_name).put_object(Key = boxplot_cv_file,
                                  Body = img_data,
                                  ContentType = 'image/png',
                                  ACL = 'public-read')

print('A imagem está disponível na url: ',
      url + boxplot_cv_file)
#==========================================================#

#==========================================================#
cat('Confusion Matrix').print()
#----------------------------------------------------------#
img_data = open(confusion_matrix_file, 'rb')
s3.Bucket(bucket_name).put_object(Key = confusion_matrix_file,
                                  Body = img_data,
                                  ContentType = 'image/png',
                                  ACL = 'public-read')

print('A imagem está disponível na url: ', 
      url + confusion_matrix_file)
#==========================================================#

#==========================================================#
cat('Log file').print()
#----------------------------------------------------------#
log_data = open(log_file, 'rb')
s3.Bucket(bucket_name).put_object(Key = log_file, 
                                  Body = log_data,
                                  ContentType = 'text/txt',
                                  ACL = 'public-read')
                                  
print('O log está disponível na url: ', 
      url + log_file)
#==========================================================#
#==================================================================================================#
