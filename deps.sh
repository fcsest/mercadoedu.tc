sudo apt update

sudo apt upgrade

sudo apt install python3-pip

pip3 install scikit-learn seaborn matplotlib boto3 python-dotenv pandas sqlalchemy psycopg2 nltk numpy IPython pyfiglet ansicolors awscli

python3 -c "
import nltk

nltk.download('stopwords')

quit()
"

touch .env

nano .env

aws configure
