
<!-- README.md is generated from README.Rmd. Please edit that file -->

# mercadoedu.tc

<!-- badges: start -->
<!-- badges: end -->

Repositório para treinar o modelo de classificação de texto dos nomes de
curso da mercadoedu, utilizando o algoritmo
[TF-IDF](https://scikit-learn.org/stable/modules/generated/sklearn.feature_extraction.text.TfidfVectorizer.html)
de 1 até 3 n-gramas e o classificador
[LinearSVC](https://scikit-learn.org/stable/modules/generated/sklearn.svm.LinearSVC.html)
ambos da biblioteca [scikit-learn](https://scikit-learn.org/).

# TOC

-   [Preparação do ambiente](#prepação-do-ambiente)
    -   [Baixando código](#baixando-código)
    -   [Instalação das dependências](#instalação-das-dependências)
    -   [Variáveis de ambiente](#variáveis-de-ambiente)
-   [Análise com aprendizado de
    máquina](#análise-com-aprendizado-de-máquina)
    -   [Rotina principal](#rotina-principal)
    -   [Salvar modelo](#salvar-modelo)

## Preparação do ambiente

### Baixando código

Para clonar o repositório com as rotinas de treino e deploy do modelo
use:

``` bash
git clone https://github.com/fcsestme/mercadoedu.tc.git
```

### Instalação das dependências

Instale as dependências rodando o script `deps.sh` com:

``` bash
./deps.sh
```

### Variáveis de ambiente

Defina as variáveis de ambiente em .env e depois as chaves de acesso ao
AWS:

## Análise com aprendizado de máquina

### Rotina principal

Em seguida rodamos o script `train.py` com o função `tee` para exportar
o log junto:

``` bash
python3 train.py | tee log.txt
```

### Salvar modelo

Ao final do script você pode definir se deseja salvar o modelo treinado
no bucket do AWS S3.
