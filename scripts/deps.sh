sudo su
apt install software-properties-common
add-apt-repository ppa:deadsnakes/ppa

apt update
apt upgrade -y

apt install python3.8 python3-pip virtualenv

update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.6 1
update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 2

virtualenv -p python3.8 ~/.virtualenvs/text_class

source ~/.virtualenvs/text_class/bin/activate

python3.8 -m pip install -r ./requirements.txt

python3.8 -c "import nltk
nltk.download('stopwords')
quit()"
