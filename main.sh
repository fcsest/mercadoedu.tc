# Function to decide what do next...
function ask_user() {

# Message with choices informations
echo -e "\n\n
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
| O que deseja fazer?                          |
|					       |
| 1) Instalar dependencias                     |
| 2) Treinar modelo                            |
| 3) Exportar imagens e log para o S3          |
| 4) Limpar arquivos temporários               |
|                                              |
| 9) Fechar terminal                           |
| 0) Continuar no terminal                     |
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
|					       |
| Digite um numero para escolher uma opcao...  |
|					       |
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#\n"

# Display a message if select undefined choices
if [ "$AGAIN" == "1" ]; then
	echo -e "Escolha uma das opcoes acima 1, 2, or 3...\n"
fi

# Input of user choice
read -e -p " — Eu escolho a opcao: " choice

# Conditional to open R Studio
if [ "$choice" == "1" ]; then
	./deps.sh && sleep 2 && ask_user

# Conditional to open R in Terminal
elif [ "$choice" == "2" ]; then
	sudo python3 'train.py' | tee log.txt && sleep 2 && ask_user

# Conditional to open R Studio
elif [ "$choice" == "3" ]; then
	sudo python3 'exports.py' && sleep 2 && ask_user

# Conditional to open R in Terminal
elif [ "$choice" == "4" ]; then
	sudo python3 'clear.py' && sleep 2 && ask_user

# Conditional to exit
elif [ "$choice" == "0" ]; then
  exit;

# Conditional to exit
elif [ "$choice" == "9" ]; then
	clear; exit 0

# Conditional to ask again
else
	AGAIN=1
	clear && ask_user
fi
}

ask_user
