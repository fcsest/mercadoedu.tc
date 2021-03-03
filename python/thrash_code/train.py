from python.functions import cat

#==================================================================================================#
# Preprocess ####
cat("Preprocess", "green").print()
#--------------------------------------------------------------------------------------------------#
from dotenv import load_dotenv
from os import environ
from pandas import read_sql_table, notnull, concat
from sqlalchemy import create_engine
from nltk.corpus import stopwords
from sklearn.feature_extraction.text import TfidfVectorizer
#--------------------------------------------------------------------------------------------------#

load_dotenv()

database = "course_names"

stop_words = ["curso",
              "superior",
              "tecnologia",
              "abi",
              "ead",
              "cst"]
tfidf_min_df = 1
tfidf_range = (1,3)

#==========================================================#
cat("Import/Format").print()
#----------------------------------------------------------#
engine_string = "postgresql://{user}:{password}@{host}:{port}/{database}".format(
    host = environ["AWS_HOST_RDS"],
    port = environ["AWS_PORT_RDS"],
    database = environ["AWS_DB_MODEL"],
    user = environ["AWS_USER"],
    password = environ["AWS_PASSWORD"]
)

eng = create_engine(engine_string)

df = read_sql_table(database, eng).sort_values(["name", "name_detail"])

col = ["name", "name_detail"]
df = df[col]
df = df[notnull(df["name_detail"])]
df.columns = ["name", "name_detail"]
df["category_id"] = df["name"].factorize()[0]

category_id_df = df[["name", "category_id"]].drop_duplicates().sort_values("category_id")

category_to_id = dict(category_id_df.values)

id_to_category = dict(category_id_df[["category_id", "name"]].values)
#==========================================================#

#==========================================================#
cat("TF-IDF").print()
#----------------------------------------------------------#
all_stopwords = stopwords.words("portuguese")

all_stopwords.extend(stop_words)

tfidf = TfidfVectorizer(stop_words = all_stopwords,
                        min_df = 1,  ngram_range = (1,3))

features = tfidf.fit_transform(df.name_detail)

features2 = features.toarray()

labels = df.category_id

print(
  f"\nTemos {features.shape[0]} nomes detalhados para treinar as {len(category_id_df)} categorias",
  "de nomes agregados...\nAs features são os unigramas, bigramas e trigramas mais correlacionados",
  f"para cada categoria...\nDesta forma temos {features.shape[1]} features para a predição do nome",
  f"agregado de cada curso, ou seja...\nTemos {features.shape[1]} unigramas, bigramas e trigramas",
  "que representam os nomes agregados de curso."
  )
  
features
features2
#==========================================================#
#==================================================================================================#


#==================================================================================================#
# Model Selection ####
cat("Model Selection", "green").print()
#--------------------------------------------------------------------------------------------------#
from numpy import argsort, array
from sklearn.svm import LinearSVC
from IPython.display import display
from pandas import DataFrame, concat
from seaborn import boxplot, stripplot, heatmap
from sklearn.linear_model import LogisticRegression
from matplotlib.pyplot import savefig, ylabel, xlabel, subplots
from sklearn.metrics import classification_report, confusion_matrix
from sklearn.model_selection import cross_val_score, train_test_split
#--------------------------------------------------------------------------------------------------#

model_test_size = 0.3
model_random_state = 1
model_penalty = "l1"
model_loss = "squared_hinge"
model_dual = False
model_max_iter = 3000000

cpu_threads = -1

CV = 4

boxplot_cv_file = "cv_models.png"
confusion_matrix_file = "confusion_matrix.png"

#==========================================================#
cat("Cross Validation").print()
#----------------------------------------------------------#
X = df["name_detail"]
y = df["name"]

X_train, X_test, y_train, y_test = train_test_split(X, y,
                                                    test_size = model_test_size,
                                                    random_state = model_random_state)

models = [
    LogisticRegression(random_state = model_random_state,
                       max_iter = model_max_iter),
    LinearSVC(random_state = model_random_state,
              max_iter = model_max_iter),
    LinearSVC(dual = False,
              penalty = "l2", loss = "squared_hinge",
              random_state = model_random_state, max_iter = model_max_iter),
    LinearSVC(dual = False,
              penalty = "l1", loss = "squared_hinge",
              random_state = model_random_state, max_iter = model_max_iter),
    LinearSVC(dual = True,
              penalty = "l2", loss = "squared_hinge",
              random_state = model_random_state, max_iter = model_max_iter),
    LinearSVC(dual = True,
              penalty = "l2", loss = "hinge",
              random_state = model_random_state, max_iter = model_max_iter)
]

models_specs = [
  "LogisticRegression",
  "LinearSVC Default",
  "LinearSVC w/ D:F, P:l2, L=hinge2",
  "LinearSVC w/ D:F, P:l1, L=hinge2",
  "LinearSVC w/ D:T, P:l2, L=hinge2",
  "LinearSVC w/ D:T, P:l2, L=hinge"
]

models_names = [
  "LogisticReg",
  "SVC_Default",
  "SVC_F22",
  "SVC_F12",
  "SVC_T22",
  "SVC_T21"
]

cv_df = DataFrame(index=range(CV * len(models)))

entries = []

for i, model in enumerate(models):
  model_name = models_names[i]
  model_spec = models_specs[i]
  accuracies = cross_val_score(model,
                               features,
                               labels,
                               scoring = "accuracy",
                               cv = CV,
                               n_jobs = cpu_threads)
  for fold_idx, accuracy in enumerate(accuracies):
    entries.append((model_name, model_spec, fold_idx+1, accuracy))

cv_df = DataFrame(entries, columns=["model_name", "model_spec", "iteration", "accuracy"])

print(cv_df)
#==========================================================#

#==========================================================#
cat("CV Stats").print()
#----------------------------------------------------------#
mean_accuracy = cv_df.groupby("model_name").accuracy.mean()
std_accuracy = cv_df.groupby("model_name").accuracy.std()

acc = concat([mean_accuracy, std_accuracy], axis= 1,
          ignore_index=True).sort_values(1, ascending = True).sort_values(0, ascending = False)
          
acc.columns = ["Acurácia média", "Desvio padrão"]

print(acc)
#==========================================================#

#==========================================================#
cat("CV Boxplots").print()
#----------------------------------------------------------#
boxplot(x = "model_name", y = "accuracy", data = cv_df)

stripplot(x = "model_name", y = "accuracy", data = cv_df,
              size = 8, jitter = True, edgecolor = "gray", linewidth = 2)

savefig(boxplot_cv_file)
#==========================================================#

#==========================================================#
cat("Model Evaluation").print()
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

print("\t\t\t\tMétricas da classificação\n",
      classification_report(y_test, y_pred))
#==========================================================#

#==========================================================#
cat("Confusion Matrix").print()
#----------------------------------------------------------#
conf_mat = confusion_matrix(y_test, 
                            y_pred, 
                            labels = category_id_df.category_id)

conf_mat.shape

fig, ax = subplots(figsize=(90, 90))

heatmap(conf_mat,
        annot = True,
        fmt = "d",
        square = True,
        xticklabels = category_id_df.name.values,
        yticklabels = category_id_df.name.values)

ylabel("Actual")

xlabel("Predicted")

savefig(confusion_matrix_file)
#==========================================================#

#==========================================================#
cat("Wrong Matches").print()
#----------------------------------------------------------#
for predicted in category_id_df.category_id:
  for actual in category_id_df.category_id:
    if predicted != actual and conf_mat[actual, predicted] >= 1:
      print("'{}' foi predito como '{}' : {} exemplos.".format(id_to_category[actual],
                                                               id_to_category[predicted],
                                                               conf_mat[actual, predicted]))
      display(df.loc[indices_test[(y_test == actual) & (y_pred == predicted)]][["name", "name_detail"]])
      print("\n")

#==========================================================#

#==========================================================#
cat("Fit and Check").print()
#----------------------------------------------------------#
model.fit(features, labels)

N = 2
for name, category_id in sorted(category_to_id.items()):
  indices = argsort(model.coef_[category_id])
  feature_names = array(tfidf.get_feature_names())[indices]
  unigrams = [v for v in reversed(feature_names) if len(v.split(" ")) == 1][:N]
  bigrams = [v for v in reversed(feature_names) if len(v.split(" ")) == 2][:N]
  threegrams = [v for v in reversed(feature_names) if len(v.split(" ")) == 3][:N]
  print("\n==> n-gramas mais correlacionados com o curso '{}':".format(name))
  print("  * Unigrams: '%s'" %("', '".join(unigrams)))
  print("  * Bigrams: '%s'" %("', '".join(bigrams)))
  print("  * Threegrams: '%s'" %("', '".join(threegrams)))

#==========================================================#
#==================================================================================================#


#==================================================================================================#
# Deploy ####
cat("Deploy", "green").print()
#--------------------------------------------------------------------------------------------------#
from pickle import dumps
from boto3 import resource
from functions import df_trans
from sklearn.calibration import CalibratedClassifierCV
#--------------------------------------------------------------------------------------------------#

X = df["name_detail"]
y = df["name"]

#==========================================================#
cat("Calibration").print()
#----------------------------------------------------------#
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

calibrated_clf = CalibratedClassifierCV(SVC, n_jobs = cpu_threads)

calibrated_clf.fit(tfidf_vectorizer_vectors, y_train)
#==========================================================#

#==========================================================#
cat("Predictions").print()
#----------------------------------------------------------#
course_to_predict = "ecologia sustentavel"

df_probs = DataFrame(calibrated_clf.predict_proba(fitted_vectorizer.transform([course_to_predict]))*100,
                      columns=category_id_df.name.values)

result_df = df_trans(df_probs)

print(result_df)
#==========================================================#

#==========================================================#
cat("Export Models").print()
#----------------------------------------------------------#

bucket_name = "ia-censo-tc"

text_vec_filename = "text_vec.pkl"
text_clf_filename = "text_clf.pkl"
ids_filename = "ids.pkl"

text_vec_dump = dumps(fitted_vectorizer)
text_clf_dump = dumps(calibrated_clf)
ids_dump = dumps(category_id_df.name)

s3 = resource("s3",
              aws_access_key_id = environ["AWS_ACCESS_KEY_ID"],
              aws_secret_access_key = environ["AWS_SECRET_ACCESS_KEY"])

s3.Object(bucket_name, text_vec_filename).put(Body = text_vec_dump)
s3.Object(bucket_name, text_clf_filename).put(Body = text_clf_dump)
s3.Object(bucket_name, ids_filename).put(Body = ids_dump)
#==========================================================#
#==================================================================================================#
