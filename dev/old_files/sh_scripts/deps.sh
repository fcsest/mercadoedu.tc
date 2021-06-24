if [[ $(lsb_release -rs) == "20.04" ]]; then
  echo "Instalando dependências para o Ubuntu 20.04"
  sudo apt install software-properties-common
  sudo add-apt-repository ppa:deadsnakes/ppa -y

  sudo apt update
  sudo apt upgrade -y

  sudo apt install python3-pip libpq-dev awscli -y

  python3 -m pip install -r ./requirements.txt

  python3 -c "import nltk; nltk.download('stopwords')"

# Conditional to exit
elif [[ $(lsb_release -rs) == "18.04" ]]; then
	echo "O script de instalção das dependências ainda não é compatível com o Ubuntu 18.04,
	o sistema operacional deve ser Ubuntu 20.04"

else
       echo "O sistema operacional recomendado é o Ubuntu 20.04"
fi

