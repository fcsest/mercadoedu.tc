# Append python folder to import functions.py 
sys.path.append('./python/')
from functions import cat

from os import environ
from dotenv import load_dotenv
from python.functions import df_trans
from sqlalchemy import create_engine
from pandas import read_sql_table, notnull, concat
#--------------------------------------------------------------------------------------------------#
load_dotenv()

database = "course_names"

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

df.groupby(by="name")["name_detail"].agg(
        [
            ("count", lambda x: x.size)
        ]
    ).reset_index().sort_values(by="count", ascending=False)

from PyHighcharts import Chart, ChartTypes
import PyHighcharts
# A chart is the container that your data will be rendered in, it can (obviously) support multiple data series within it.
chart = Chart()

# Adding a series requires a minimum of two arguments, the series type and an array of data points
chart.add_data_series(ChartTypes.Spline, df["count"], "Example Series")

# This will open up a browser window and display the chart on the page
chart.show()
