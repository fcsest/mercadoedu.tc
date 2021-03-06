% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/update_databases.R
\name{update_stopwords}
\alias{update_stopwords}
\title{Update stopwords table}
\usage{
update_stopwords(
  con,
  stopwords,
  db_tbl_name = "model_stopwords",
  ptbr_stopwords = TRUE,
  append = FALSE
)
}
\arguments{
\item{con}{A database connection;}

\item{stopwords}{A list/vector of strings;}

\item{db_tbl_name}{A string of table name in database;\strong{\preformatted{Default: "model_stopwords"
}

}}

\item{ptbr_stopwords}{A logical that defines when to add PT-BR stopwords;\strong{\preformatted{Default: TRUE
}

}}

\item{append}{A logical that defines when to append or overwrite;\strong{\preformatted{Default: FALSE
}

}}
}
\value{
A logical that warnings if stopwords database was updated or not.
}
\description{
Update a stopwords table from database with new stopwords.
}
\details{
This function adds the same stopwords inputted but without accent.
}
\examples{
\dontrun{
  if(interactive()){
    ### Updating a stopwords table of Amazon RDS Model Database####
    odbc::odbc() |>
      DBI::dbConnect("Amazon RDS Model",
                     timeout = 0) |>
      mercadoedu.tc::update_stopwords(stopwords = c("abi",
                                                    "lins",
                                                    "distância",
                                                    "presencial",
                                                    "semipresencial",
                                                    "cidade universitária",
                                                    "centro universitário",
                                                    "modalidade",
                                                    "modalidade ensino"))
  }
}

}
\seealso{
\code{\link[=get_stopwords]{get_stopwords()}}
\code{\link[purrr]{map2}}
\code{\link[stopwords]{stopwords}}
\code{\link[stringr]{str_subset}}, \code{\link[stringr]{str_trim}}
\code{\link[abjutils]{rm_accent}}
\code{\link[dplyr]{filter-joins}}
}
