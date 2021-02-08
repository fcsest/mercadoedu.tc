# Import specific function in another file
from functions import cat
from dotenv import load_dotenv

load_dotenv()

database = 'course_names'
cutted = True

stop_words = ['curso',
              'superior',
              'tecnologia',
              'abi',
              'ead']
tfidf_min_df = 2
tfidf_range = (1,3)

model_test_size = 0.3
model_random_state = 1
model_loss = 'squared_hinge'
model_penalty = 'l2'
model_dual = False
model_max_iter = 3000000

cpu_threads = -1

CV = 4
              
bucket_name = 'ia-censo-tc'
boxplot_cv_file = 'cv_models.png'
confusion_matrix_file = 'confusion_matrix.png'
url = 'https://' + bucket_name + '.s3.us-east-2.amazonaws.com/'

#==================================================================================================#
# Processamento de dados ####
#==========================================================#
#--------------------------------------------------------------------------------------------------#
cat('Preprocess', 'green').print()
#----------------------------------------------------------#
from os import environ
from pandas import read_sql_table, notnull, concat
from sqlalchemy import create_engine
#----------------------------------------------------------#
engine_string = 'postgresql://{user}:{password}@{host}:{port}/{database}'.format(
    host = environ['AWS_HOST_RDS'],
    port = environ['AWS_PORT_RDS'],
    database = environ['AWS_DB_MODEL'],
    user = environ['AWS_USER'],
    password = environ['AWS_PASSWORD']
)

eng = create_engine(engine_string)

df = read_sql_table(database, eng).sort_values(['name', 'name_detail'])

if cutted:
  df = df.loc[4012:20871]

little = df[df['name'].groupby(df['name']).transform('size') < 10]

appended = concat([little.drop_duplicates()] * 10,
                  ignore_index = False).sort_values(['name', 'name_detail'])

df = df.append(appended, ignore_index = False)

del appended, little

col = ['name', 'name_detail']
df = df[col]
df = df[notnull(df['name_detail'])]
df.columns = ['name', 'name_detail']
df['category_id'] = df['name'].factorize()[0]

category_id_df = df[['name', 'category_id']].drop_duplicates().sort_values('category_id')

category_to_id = dict(category_id_df.values)

id_to_category = dict(category_id_df[['category_id', 'name']].values)
#--------------------------------------------------------------------------------------------------#

#--------------------------------------------------------------------------------------------------#
cat('TF-IDF').print()
#----------------------------------------------------------#
from nltk.corpus import stopwords
from sklearn.feature_extraction.text import TfidfVectorizer
#----------------------------------------------------------#
all_stopwords = stopwords.words('portuguese')

all_stopwords.extend(stop_words)

tfidf = TfidfVectorizer(stop_words = all_stopwords,
                        min_df = tfidf_min_df,  ngram_range = tfidf_range)

features = tfidf.fit_transform(df.name_detail).toarray()

labels = df.category_id

print(
  f'\nTemos {features.shape[0]} nomes detalhados para treinar as {len(category_id_df)} categorias',
  'de nomes agregados...\nAs features são os unigramas, bigramas e trigramas mais correlacionados',
  f'para cada categoria...\nDesta forma temos {features.shape[1]} features para a predição do nome',
  f'agregado de cada curso, ou seja...\nTemos {features.shape[1]} unigramas, bigramas e trigramas',
  'que representam os nomes agregados de curso.'
  )
#--------------------------------------------------------------------------------------------------#
#==================================================================================================#

#==================================================================================================#
# Cross Validation + Model Evaluation ####
#==========================================================#
#--------------------------------------------------------------------------------------------------#
cat('Cross Validation', 'green').print()
#----------------------------------------------------------#
from sklearn.model_selection import cross_val_score
from sklearn.linear_model import LogisticRegression
from sklearn.svm import LinearSVC
from pandas import DataFrame
from sklearn.model_selection import train_test_split
#----------------------------------------------------------#

X = df['name_detail'] # Collection of documents
y = df['name'] # Target or the labels we want to predict (i.e., the 13 different complaints of products)

X_train, X_test, y_train, y_test = train_test_split(X, y,
                                                    test_size = model_test_size,
                                                    random_state = model_random_state)

models = [
    LogisticRegression(random_state = model_random_state,
                       max_iter = model_max_iter),
    LinearSVC(random_state = model_random_state,
              max_iter = model_max_iter),
    LinearSVC(dual = False,
              penalty = 'l2', loss = 'squared_hinge',
              random_state = model_random_state, max_iter = model_max_iter),
    LinearSVC(dual = False,
              penalty = 'l1', loss = 'squared_hinge',
              random_state = model_random_state, max_iter = model_max_iter),
    LinearSVC(dual = True,
              penalty = 'l2', loss = 'squared_hinge',
              random_state = model_random_state, max_iter = model_max_iter),
    LinearSVC(dual = True,
              penalty = 'l2', loss = 'hinge',
              random_state = model_random_state, max_iter = model_max_iter)
]

models_specs = [
  'LogisticRegression',
  'LinearSVC Default',
  'LinearSVC w/ D:F, P:l2, L=hinge2',
  'LinearSVC w/ D:F, P:l1, L=hinge2',
  'LinearSVC w/ D:T, P:l2, L=hinge2',
  'LinearSVC w/ D:T, P:l2, L=hinge'
]

models_names = [
  'LogisticReg',
  'SVC_Default',
  'SVC_F22',
  'SVC_F12',
  'SVC_T22',
  'SVC_T21'
]

cv_df = DataFrame(index=range(CV * len(models)))

entries = []

for i, model in enumerate(models):
  model_name = models_names[i]
  model_spec = models_specs[i]
  accuracies = cross_val_score(model,
                               features,
                               labels,
                               scoring='accuracy',
                               cv=CV,
                               n_jobs = cpu_threads)
  for fold_idx, accuracy in enumerate(accuracies):
    entries.append((model_name, model_spec, fold_idx+1, accuracy))

cv_df = DataFrame(entries, columns=['model_name', 'model_spec', 'iteration', 'accuracy'])
print(cv_df)
#--------------------------------------------------------------------------------------------------#

#--------------------------------------------------------------------------------------------------#
cat('CV Stats').print()
#----------------------------------------------------------#
from pandas import concat
#----------------------------------------------------------#
mean_accuracy = cv_df.groupby('model_name').accuracy.mean()
std_accuracy = cv_df.groupby('model_name').accuracy.std()

acc = concat([mean_accuracy, std_accuracy], axis= 1,
          ignore_index=True)
acc.columns = ['Acurácia média', 'Desvio padrão']
print(acc)
#--------------------------------------------------------------------------------------------------#

#--------------------------------------------------------------------------------------------------#
cat('CV Boxplots').print()
#----------------------------------------------------------#
from os import stat
from boto3 import resource
from matplotlib.pyplot import savefig
from seaborn import boxplot, stripplot
#----------------------------------------------------------#
boxplot(x = 'model_name', y = 'accuracy', data = cv_df)

stripplot(x = 'model_name', y = 'accuracy', data = cv_df,
              size = 8, jitter = True, edgecolor = 'gray', linewidth = 2)

# save the plot to a static folder
savefig(boxplot_cv_file)

s3 = resource('s3')

# upload image to aws s3
img_data = open(boxplot_cv_file, 'rb')
s3.Bucket(bucket_name).put_object(Key = boxplot_cv_file, Body = img_data,
                                 ContentType = 'image/png', ACL = 'public-read')

if stat(boxplot_cv_file).st_size > 0:
  print('A imagem está disponível na url: ', url + boxplot_cv_file)
#--------------------------------------------------------------------------------------------------#


#--------------------------------------------------------------------------------------------------#
cat('Model Evaluation').print()
#----------------------------------------------------------#
from sklearn.metrics import classification_report
from sklearn.svm import LinearSVC
from sklearn.model_selection import train_test_split
#----------------------------------------------------------#
X_train, X_test, y_train, y_test, indices_train, indices_test = train_test_split(
  features,
  labels,
  df.index,
  test_size = model_test_size,
  random_state = model_random_state
)

model = LinearSVC(dual = model_dual,
                  penalty = model_penalty,
                  loss = model_loss,
                  max_iter = model_max_iter)

model.fit(X_train, y_train)

y_pred = model.predict(X_test)

print('\t\t\t\tMétricas da classificação\n',
      classification_report(y_test, y_pred, target_names = df['name'].unique()))
#--------------------------------------------------------------------------------------------------#

#--------------------------------------------------------------------------------------------------#
cat('Confusion Matrix').print()
#----------------------------------------------------------#
from boto3 import resource
from seaborn import heatmap
from sklearn.metrics import confusion_matrix
from matplotlib.pyplot import savefig, ylabel, xlabel, subplots
#----------------------------------------------------------#
conf_mat = confusion_matrix(y_test, y_pred, labels = category_id_df.category_id)

conf_mat.shape

fig, ax = subplots(figsize=(60, 60))

heatmap(conf_mat,
        annot = True,
        fmt = 'd',
        square = True,
        xticklabels = category_id_df.name.values,
        yticklabels = category_id_df.name.values)

ylabel('Actual')

xlabel('Predicted')

savefig(confusion_matrix_file)

s3 = resource('s3')

img_data = open(confusion_matrix_file, 'rb')
s3.Bucket(bucket_name).put_object(Key = confusion_matrix_file, Body = img_data,
                                 ContentType = 'image/png', ACL = 'public-read')

if stat(confusion_matrix_file).st_size > 0:
  print('A imagem está disponível na url: ', url + confusion_matrix_file)
#--------------------------------------------------------------------------------------------------#

#--------------------------------------------------------------------------------------------------#
cat('Wrong Matches').print()
#----------------------------------------------------------#
from IPython.display import display
#----------------------------------------------------------#
for predicted in category_id_df.category_id:
  for actual in category_id_df.category_id:
    if predicted != actual and conf_mat[actual, predicted] >= 2:
      print('"{}" foi predito como "{}" : {} exemplos.'.format(id_to_category[actual],
                                                               id_to_category[predicted],
                                                               conf_mat[actual, predicted]))
      display(df.loc[indices_test[(y_test == actual) & (y_pred == predicted)]][['name', 'name_detail']])
      print('\n')
#--------------------------------------------------------------------------------------------------#

#--------------------------------------------------------------------------------------------------#
cat('Fit and Check').print()
#----------------------------------------------------------#
from numpy import argsort, array
#----------------------------------------------------------#
model.fit(features, labels)

N = 2
for name, category_id in sorted(category_to_id.items()):
  indices = argsort(model.coef_[category_id])
  feature_names = array(tfidf.get_feature_names())[indices]
  unigrams = [v for v in reversed(feature_names) if len(v.split(' ')) == 1][:N]
  bigrams = [v for v in reversed(feature_names) if len(v.split(' ')) == 2][:N]
  threegrams = [v for v in reversed(feature_names) if len(v.split(' ')) == 3][:N]
  print('\n==> n-gramas mais correlacionados com o curso "{}":'.format(name))
  print('  * Unigrams: "%s"' %('", "'.join(unigrams)))
  print('  * Bigrams: "%s"' %('", "'.join(bigrams)))
  print('  * Threegrams: "%s"' %('", "'.join(threegrams)))

#--------------------------------------------------------------------------------------------------#
#==================================================================================================#


#==================================================================================================#
# Prediction ####
#==========================================================#
#--------------------------------------------------------------------------------------------------#
cat('Calibrate', 'green').print()
#----------------------------------------------------------#
from sklearn.calibration import CalibratedClassifierCV
#----------------------------------------------------------#
X = df['name_detail']
y = df['name']

X_train, X_test, y_train, y_test = train_test_split(X, y,
                                                    test_size = model_test_size,
                                                    random_state = model_random_state)

tfidf = TfidfVectorizer(stop_words = all_stopwords,
                        min_df = tfidf_min_df,  ngram_range = tfidf_range)

fitted_vectorizer = tfidf.fit(X_train)
tfidf_vectorizer_vectors = fitted_vectorizer.transform(X_train)

SVC = LinearSVC(dual = model_dual,
                penalty = model_penalty,
                loss = model_loss,
                random_state = model_random_state,
                max_iter = model_max_iter)

calibrated_clf = CalibratedClassifierCV(SVC, cv = CV, n_jobs = cpu_threads)

calibrated_clf.fit(tfidf_vectorizer_vectors, y_train)

#--------------------------------------------------------------------------------------------------#

#--------------------------------------------------------------------------------------------------#
cat('Test').print()
#----------------------------------------------------------#
from pandas import DataFrame
from functions import df_trans
#----------------------------------------------------------#
course_to_predict = 'ecologia sustentavel'

df_probs = DataFrame(calibrated_clf.predict_proba(fitted_vectorizer.transform([course_to_predict]))*100,
                      columns=category_id_df.name.values)

result_df = df_trans(df_probs)

print(result_df)
#--------------------------------------------------------------------------------------------------#

#--------------------------------------------------------------------------------------------------#
cat('Pergunta', 'cyan').print()
#----------------------------------------------------------#
from functions import ask_user
#----------------------------------------------------------#
if not(ask_user('Deseja salvar o modelo?')):
  print('Você decidiu não salvar o modelo no bucket' + bucket_name + ' do AWS...')
  quit()
#--------------------------------------------------------------------------------------------------#

#--------------------------------------------------------------------------------------------------#
cat('Save Model').print()
#----------------------------------------------------------#
from boto3 import resource
from pickle import dumps
#----------------------------------------------------------#
text_vec_filename = 'text_vec.pkl'
text_vec_dump = dumps(fitted_vectorizer)

text_clf_filename = 'text_clf.pkl'
text_clf_dump = dumps(calibrated_clf)

ids_filename = 'ids.pkl'
ids_dump = dumps(category_id_df.name)

s3 = resource('s3')

s3.Object(bucket_name, text_vec_filename).put(Body = text_vec_dump)
s3.Object(bucket_name, text_clf_filename).put(Body = text_clf_dump)
s3.Object(bucket_name, ids_filename).put(Body = ids_dump)
#--------------------------------------------------------------------------------------------------#

#--------------------------------------------------------------------------------------------------#
cat('Save log').print()
#----------------------------------------------------------#
from boto3 import resource
#----------------------------------------------------------#
log_file = 'log.txt'

s3 = resource('s3')

log_data = open(log_file, 'rb')
s3.Bucket(bucket_name).put_object(Key = log_file, Body = log_data,
                                 ContentType = 'text/txt', ACL = 'public-read')
#--------------------------------------------------------------------------------------------------#
#==================================================================================================#
