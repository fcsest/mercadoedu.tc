<!-- README.md is generated from README.Rmd. Please edit that file -->
<a href="https://mercadoedu.com.br">
<img src="./inst/readme/images/slogan.png" align = "left" height = "59px"/>
</a>

<span style="display:inline-block; width: 450px;"></span>

<a href="https://tawk.to/fcs.est">
<img src="./inst/readme/images/perfil.png" align = "right" height = "100px"/>
</a>

# Text Classification

<!-- badges: start -->

![Development
Status](https://img.shields.io/badge/lifecycle-experimental-orange.svg)
<!-- badges: end -->

Repositório para treinar o modelo de classificação de texto dos nomes de
curso da mercadoedu, utilizando o algoritmo
[TF-IDF](https://scikit-learn.org/stable/modules/generated/sklearn.feature_extraction.text.TfidfVectorizer.html)
de 1 até 3 n-gramas e o classificador
[LinearSVC](https://scikit-learn.org/stable/modules/generated/sklearn.svm.LinearSVC.html)
ambos da biblioteca [scikit-learn](https://scikit-learn.org/).

## Table of Contents

-   [Preparação do ambiente](#prepação-do-ambiente)
    -   [Baixando código](#baixando-código)
    -   [Instalação das dependências](#instalação-das-dependências)
    -   [Variáveis de ambiente](#variáveis-de-ambiente)
-   [Análise com aprendizado de
    máquina](#análise-com-aprendizado-de-máquina)
    -   [Rotina principal](#rotina-principal)
    -   [Salvar modelo](#salvar-modelo)

## Clone do repositório

Para clonar o repositório e visualizar as rotinas utilize os comandos
abaixo conforme o gif:

``` bash
sudo git clone https://github.com/fcsestme/mercadoedu.tc.git]
```

``` bash
sudo cd mercadoedu.tc

ls
```

## Rotina principal

Temos a rotina principal chamada `./main.sh` que roda as demais rotinas
contidas nas pastas `./python` e `./scripts`.

Após entrarmos no diretório clonado, chamamos a rotina principal com o
comando abaixo:

``` bash
./main.sh
```

Desta forma irá aparecer uma série de alternativas que irão rodar as
demais rotinas necessárias e para escolher uma opção digite o respectivo
número da escolha e pressione `Enter`.

As três primeiras opções(`1`, `2` e `3`) só precisam ser rodadas na
máquina pela primeira vez.

As opções de `Treinar modelos` e `Avaliar modelos`(`4` e `5`) seriam
duas rotinas, uma diária e uma semanal respectivamente.

As últimas opções(`9` e `0`) são para sair do terminal e do menu
respectivamente.

### Depedências

A primeira opção(`1`) irá instalar as dependências necessárias para
rodar todas as demais rotinas.

Abaixo você pode conferir o passo a passo dessa rotina de instalação de
dependências. sudo apt install software-properties-common sudo
add-apt-repository ppa:deadsnakes/ppa -y

sudo apt update sudo apt upgrade -y

sudo apt install python3-pip -y

python3 -m pip install -r ./requirements.txt

python3 -c “import nltk; nltk.download(‘stopwords’)”

#### Atualizando Ubuntu

#### Atualizando Python

#### Instalando bibliotecas em Python

#### Baixando as stopwords em Português

### Variáveis de ambiente

A segunda opção(`2`) irá abrir um arquivo `./.env` para você definir as
variáveis de ambiente.

### Autenticação do AWS

A terceira opção(`3`) irá rodar a função de configuração do AWS, para
realizar a autenticação.

Desta forma após selecioná-la, será solicitado o AWS Access Key ID, AWS
Secret Access Key, o nome da região padrão(por padrão seria `us-east-2`)
e o formato de saída padrão(por padrão seria `json`).

### Treinamento dos modelos

#### Pré-processamento

#### Vetorização

#### Classificador

#### Deploy

### Avaliação dos modelos

#### Pré-processamento

#### Extração de features

#### Seleção de features

#### Seleção de modelos

#### Avaliação do modelo

#### Explicabilidade do modelo

#### Complexidade vs interpretabilidade

# Referências

Todo código contido neste projeto foi desenvolvido a partir das
referências abaixo:

-   <https://reslan-tinawi.github.io/2020/05/26/text-classification-using-sklearn-and-nltk.html>
