# Function to decide what do next...
function ask_user() {

# Message with choices informations
echo -e "\n\n
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
| O que deseja fazer?                            |
|					         |
| 1) (first time) Instalar dependencias          |
| 2) (first time) Definir variáveis de ambiente  |
| 3) (first time) Definir autenticação do AWS    |
| 4) (daily) Treinar modelos                     |
| 5) (weekly) Avaliar modelos                    |
|                                                |
| 9) Fechar terminal                             |
| 0) Continuar no terminal                       |
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
|					         |
| Digite um numero para escolher uma opcao...    |
|					         |
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#\n"

# Display a message if select undefined choices
if [ "$AGAIN" == "1" ]; then
	echo -e "Escolha uma das opcoes acima 1, 2, or 3...\n"
fi

# Input of user choice
read -e -p " — Eu escolho a opcao: " choice

# Conditional to install depedencies
if [ "$choice" == "1" ]; then
	./scripts/deps.sh && sleep 1 && ask_user

# Conditional to define environment variables
elif [ "$choice" == "2" ]; then
	./scripts/env.sh && sleep 1 && ask_user

# Conditional to define autorization keys of AWS
elif [ "$choice" == "3" ]; then
	./scripts/auth.sh && sleep 1 && ask_user

# Conditional to run a daily train
elif [ "$choice" == "4" ]; then
	sudo python3.8 './python/daily_train.py' | tee log_daily_`date +%d-%m-%y`.txt && sleep 1 && ask_user

# Conditional to run a weekly check
elif [ "$choice" == "5" ]; then
	sudo python3.8 './python/weekly_check.py' | tee log_weekly_`date +%d-%m-%y`.txt && sleep 1 && ask_user

# Conditional to exit menu
elif [ "$choice" == "0" ]; then
  exit;

# Conditional to exit console
elif [ "$choice" == "9" ]; then
	clear; exit; exit 0;

# Conditional to ask again
else
	AGAIN=1
	clear && ask_user
fi
}

ask_user
