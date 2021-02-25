# Import my functions of ./python folder
from python.functions import cat

#==================================================================================================#
# Preprocess ####
cat("Daily Train", "green").print()
#--------------------------------------------------------------------------------------------------#
from os import environ
from pickle import dumps
from boto3 import resource
from dotenv import load_dotenv
from nltk.corpus import stopwords
from sklearn.svm import LinearSVC
from sqlalchemy import create_engine
from python.functions import df_trans
from pandas import read_sql_table, notnull, concat
from sklearn.model_selection import train_test_split
from sklearn.calibration import CalibratedClassifierCV
from sklearn.feature_extraction.text import TfidfVectorizer
#--------------------------------------------------------------------------------------------------#

print("\nLoading environment variables...\n")
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
n_distinct = 10 

model_test_size = 0.3
model_random_state = 42
model_loss = "squared_hinge"
model_penalty = "l1"
model_dual = False
model_max_iter = 3000000

#==========================================================#
cat("Preprocess").print()
#----------------------------------------------------------#
engine_string = "postgresql://{user}:{password}@{host}:{port}/{database}".format(
    host = environ["AWS_HOST_RDS"],
    port = environ["AWS_PORT_RDS"],
    database = environ["AWS_DB_MODEL"],
    user = environ["AWS_USER"],
    password = environ["AWS_PASSWORD"]
)

eng = create_engine(engine_string)

print("\nLoading database...\n")
df = read_sql_table(database,
                    eng).sort_values(["name",
                                      "name_detail"])
                                      
#==========================================================#
df2 = df[df.groupby("name").name_detail.transform("nunique") <= n_distinct].reset_index(drop = True)

cat("<= {}".format(n_distinct)).print()
print("Temos",
      df2["name"].drop_duplicates().count(), 
      "nomes agregados de cursos tem menos de",
      n_distinct,
      "nomes detalhados diferentes:")
print(df2["name"].drop_duplicates().to_string())

del df2

print("\nSelecting only categories with more than 10 different detailed names...")
df = df[df.groupby("name").name_detail.transform("nunique") > n_distinct].reset_index(drop = True)

cat("> {}".format(n_distinct)).print()
print("Temos",
      df["name"].drop_duplicates().count(), 
      "nomes agregados de cursos tem mais de",
      n_distinct,
      "nomes detalhados diferentes:")
print(df["name"].drop_duplicates().to_string())
#==========================================================#

print("\nFormat dataframe and prepare auxiliar vectors..")
col = ["name", 
       "name_detail"]
df = df[col]
df = df[notnull(df["name_detail"])]
df.columns = ["name",
              "name_detail"]
df["category_id"] = df["name"].factorize()[0]

category_id_df = df[["name",
                     "category_id"]].drop_duplicates().sort_values("category_id")

category_to_id = dict(category_id_df.values)

id_to_category = dict(category_id_df[["category_id",
                                      "name"]].values)
                                      
all_stopwords = stopwords.words("portuguese")

all_stopwords.extend(stop_words)

labels = df.category_id
#==========================================================#

#==========================================================#
cat('TS').print()
#----------------------------------------------------------#
print("\nSplitting training data from test data...")
X_train, X_test, y_train, y_test = train_test_split(df["name_detail"],
                                                    df["name"],
                                                    test_size = model_test_size,
                                                    random_state = model_random_state)
#==========================================================#

#==========================================================#
cat('FS').print()
#----------------------------------------------------------#
print("Using tf-idf to feature extraction...")
print("\nWith parameters:",
      "\nN-Gram Range =", tfidf_range,
      "\nCut-off Value Min =", tfidf_min_df,
      "\nStopwords =", stop_words,
      "\n")
      
tfidf = TfidfVectorizer(stop_words = all_stopwords,
                        min_df = tfidf_min_df,
                        ngram_range = tfidf_range)

fitted_vectorizer = tfidf.fit(X_train)
#==========================================================#


#==========================================================#
cat("Calibration").print()
#----------------------------------------------------------#
SVC = LinearSVC(dual = model_dual,
                penalty = model_penalty,
                loss = model_loss,
                random_state = model_random_state,
                max_iter = model_max_iter)

calibrated_clf = CalibratedClassifierCV(SVC, cv = 10, n_jobs = -1)

features = tfidf.fit_transform(df.name_detail).toarray()
calibrated_clf.fit(features, labels)
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
