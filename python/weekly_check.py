# Append python folder to import functions.py 
from sys.path import append
sys.path.append('./python/')
from functions import cat

#==================================================================================================#
# Weekly Check ####
cat("Weekly Check", "green").print()
#--------------------------------------------------------------------------------------------------#
from os import environ
from dotenv import load_dotenv
from python.functions import df_trans
from sqlalchemy import create_engine
from pandas import read_sql_table, notnull, concat
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

col = ["name", "name_detail"]
df = df[col]
df = df[notnull(df["name_detail"])]
df.columns = ["name", "name_detail"]
df["category_id"] = df["name"].factorize()[0]

category_id_df = df[["name", "category_id"]].drop_duplicates().sort_values("category_id")

category_to_id = dict(category_id_df.values)

id_to_category = dict(category_id_df[["category_id", "name"]].values)
#==========================================================#
cat("Weekly Check", "cyan").print()
