from Python.functions import cat

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
tfidf_min_df = 3
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


#==========================================================#
df2 = df[df.groupby("name").name_detail.transform("nunique") <= 10].reset_index(drop = True)

cat("<= 5").print()
print("Temos",
      df2["name"].drop_duplicates().count(), 
      "nomes agregados de cursos tem menos de 5 nomes detalhados diferentes:")
print(df2["name"].drop_duplicates().to_string())


df = df[df.groupby("name").name_detail.transform("nunique") > 10].reset_index(drop = True)

cat("> 5").print()
print("Temos",
      df["name"].drop_duplicates().count(), 
      "nomes agregados de cursos tem mais de 5 nomes detalhados diferentes:")
print(df["name"].drop_duplicates().to_string())
#==========================================================#


col = ["name", "name_detail"]
df = df[col]
df = df[notnull(df["name_detail"])]
df.columns = ["name", "name_detail"]
df["category_id"] = df["name"].factorize()[0]

category_id_df = df[["name", "category_id"]].drop_duplicates().sort_values("category_id")

category_to_id = dict(category_id_df.values)

id_to_category = dict(category_id_df[["category_id", "name"]].values)
#==========================================================#

del df2

#==========================================================#
cat("TF-IDF").print()
#----------------------------------------------------------#
all_stopwords = stopwords.words("portuguese")

all_stopwords.extend(stop_words)

tfidf = TfidfVectorizer(stop_words = all_stopwords,
                        min_df = tfidf_min_df,  ngram_range = tfidf_range)

features = tfidf.fit_transform(df.name_detail).toarray()

labels = df.category_id

print(
  f"\nTemos {features.shape[0]} nomes detalhados para treinar as {len(category_id_df)} categorias",
  "de nomes agregados...\nAs features são os unigramas, bigramas e trigramas mais correlacionados",
  f"para cada categoria...\nDesta forma temos {features.shape[1]} features para a predição do nome",
  f"agregado de cada curso, ou seja...\nTemos {features.shape[1]} unigramas, bigramas e trigramas",
  "que representam os nomes agregados de curso."
  )
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
