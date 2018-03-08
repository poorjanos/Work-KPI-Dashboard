# Redirect stdout to logfile
scriptLog <- file("scriptLog", open="wt")
sink(scriptLog, type="message")

# Quit if sysdate == weekend
stopifnot(!(strftime(Sys.Date(),'%u') == 1 | strftime(Sys.Date(),'%u') == 7))

# Load required libs
library(config)
library(here)
library(ggplot2)
library(scales)
library(dplyr)
library(lubridate)
library(xlsx)  

# Import helper functions
source(here::here("R", "data_manipulation.R"))

# Define constants
# Cons: Kontakt credentials
kontakt <-
  config::get("kontakt",
              file = "C:\\Users\\PoorJ\\Projects\\config.yml")

# Cons: IFI credentials
ablak <-
  config::get("ablak",
              file = "C:\\Users\\PoorJ\\Projects\\config.yml")

# Create dirs (dir.create() does not crash when dir already exists)
dir.create(here::here("Data"), showWarnings = FALSE)
dir.create(here::here("Reports"), showWarnings = FALSE)


#########################################################################################
# Data Extraction #######################################################################
#########################################################################################
  
# Set JAVA_HOME, set max. memory, and load rJava library
Sys.setenv(JAVA_HOME="C:\\Program Files\\Java\\jre1.8.0_60")
options(java.parameters="-Xmx2g")
library(rJava)

# Output Java version
.jinit()
print(.jcall("java/lang/System", "S", "getProperty", "java.version"))

# Load RJDBC library
library(RJDBC)

# Create connection driver 
jdbcDriver <-
  JDBC(driverClass = "oracle.jdbc.OracleDriver",
       classPath = "C:\\Users\\PoorJ\\Desktop\\ojdbc7.jar")


# Open connection: ablak
jdbcConnection <-
  dbConnect(
    jdbcDriver,
    url = ablak$server,
    user = ablak$uid,
    password = ablak$pwd
  )

# Read in SQL script from file
kpi_al <-
  readQuery(here::here("SQL", "kpi_al.sql"))
kpi_pu <-
  readQuery(here::here("SQL", "kpi_pu.sql"))

# Query on the Oracle instance name
t_al_curr <- dbGetQuery(jdbcConnection, kpi_al)
t_pu_curr <- dbGetQuery(jdbcConnection, kpi_pu)

# Close connection: ablak
dbDisconnect(jdbcConnection)


# Open connection: kontakt
jdbcConnection <-
  dbConnect(
    jdbcDriver,
    url = kontakt$server,
    user = kontakt$uid,
    password = kontakt$pwd
  )

# Read in SQL script from file
kpi_il <-
  readQuery(here::here("SQL", "kpi_il.sql"))

# Query on the Oracle instance name
t_il_curr <- dbGetQuery(jdbcConnection, kpi_il)

# Close connection: kontakt
dbDisconnect(jdbcConnection)



#########################################################################################
# Data Wrangling ########################################################################
#########################################################################################

# Init or append to log on local storage then load log
t_al_log <- write_to_log(t_al_curr, here::here("Data", "al_kpi_log.csv"), "SZERZDAT")
t_il_log <- write_to_log(t_il_curr, here::here("Data", "il_kpi_log.csv"), "LEZARVA")
t_pu_log <- write_to_log(t_pu_curr, here::here("Data", "pu_kpi_log.csv"), "KONYVDAT")

# AL segment ----------------------------------------------------------------------------
# Transform and save to dashboard intput
if (!is.null(t_al_log)) {
  t_al_log$DATUM <- ymd_hms(t_al_log$DATUM)
  t_al_log$DATUM <- as.character((t_al_log$DATUM))
  t_al_log <- t_al_log[t_al_log$ERK_SZERZ < 100, ] #outliers
  
  write.csv(
    generate_table(t_al_log, "DATUM"),
    here::here("Data", "erk_szerz_full.csv"),
    row.names = FALSE
  )
  
  write.csv(
    generate_table(t_al_log, "DATUM", "TERMCSOP"),
    here::here("Data", "erk_szerz_term_full.csv"),
    row.names = FALSE
  )
  
  write.csv(
    generate_table(t_al_log[t_al_log$KOTVENYESITES == "Manualis",], "DATUM"),
    here::here("Data", "afc_erk_szerz_full.csv"),
    row.names = FALSE
  )
  
  write.csv(
    generate_table(t_al_log[t_al_log$KOTVENYESITES == "Manualis",], "DATUM", "TERMCSOP"),
    here::here("Data", "afc_erk_szerz_term.csv"),
    row.names = FALSE
  )
  
  write.csv(
    generate_table(t_al_log[t_al_log$KOTVENYESITES == "Manualis",], "DATUM", "TERMCSOP"),
    here::here("Data", "afc_erk_szerz_term.csv"),
    row.names = FALSE
  )
  
  write.csv(
    generate_table_15(t_al_log[t_al_log$KOTVENYESITES == "Manualis",], "DATUM"),
    here::here("Data", "afc15.csv"),
    row.names = FALSE
  )
  
  write.csv(
    generate_table_15(t_al_log[t_al_log$KOTVENYESITES == "Manualis",], "DATUM", "TERMCSOP"),
    here::here("Data", "afc15_term.csv"),
    row.names = FALSE
  )
  
  traject <- t_al_curr[t_al_curr$KOTVENYESITES == "Manualis",]
  traject <- traject[traject$ERK_SZERZ < 100,]
  traject$SZERZDAT <- ymd_hms(traject$SZERZDAT)
  traject$SZERZDAT <-
    format(as.POSIXct(traject$SZERZDAT), "%Y-%m-%d")
  traject$SZERZDAT <- as.character((traject$SZERZDAT))
  
  idosor <- group_by(traject, SZERZDAT) %>%
    summarize(ERK_SZERZ = mean(ERK_SZERZ),
              DARAB = length(VONALKOD)) %>%
    mutate(cs_prod = cumsum(ERK_SZERZ * DARAB),
           cs = cumsum(DARAB)) %>%
    mutate(ERK_SZERZ_ROLL = cs_prod / cs)
  
  write.csv(idosor, here::here("Data", "trajectory.csv"), row.names = FALSE)
  
  idosor_term <- group_by(traject, SZERZDAT, TERMCSOP) %>%
    summarize(ERK_SZERZ = mean(ERK_SZERZ),
              DARAB = length(VONALKOD)) %>%
    ungroup() %>%
    group_by(TERMCSOP) %>%
    mutate(cs_prod = cumsum(ERK_SZERZ * DARAB),
           cs = cumsum(DARAB)) %>%
    mutate(ERK_SZERZ_ROLL = cs_prod / cs)
  
  write.csv(idosor_term,
            here::here("Data", "trajectory_term.csv"),
            row.names = FALSE)
}
  

# IL segment ----------------------------------------------------------------------------
# Transform and save to dashboard intput
if (!is.null(t_il_log)) {
  t_il_log$DATUM <- ymd_hms(t_il_log$DATUM)
  t_il_log$DATUM <- as.character((t_il_log$DATUM))
  t_il_log <- t_il_log[t_il_log$ERK_LEZAR < 100,] #outliers
  
  write.csv(
    generate_table_kontakt(t_il_log, "DATUM"),
    here::here("Data", "kontakt_erk_lezar_full.csv"),
    row.names = FALSE
  )
  
  erk_lezar_irattip <-
    generate_table_kontakt(t_il_log, "DATUM", "IRAT_TIPUS")
  erk_lezar_irattip <-
    erk_lezar_irattip[erk_lezar_irattip$DARAB > 30, ]
  
  write.csv(
    erk_lezar_irattip,
    here::here("Data", "kontakt_erk_lezar_irattip.csv"),
    row.names = FALSE
  )
  
  write.csv(
    generate_table_15_kontakt(t_il_log, "DATUM"),
    here::here("Data", "irat15.csv"),
    row.names = FALSE
  )
  
  irat15_irattip <-
    generate_table_15_kontakt(t_il_log, "DATUM", "IRAT_TIPUS")
  irat15_irattip <- irat15_irattip[irat15_irattip$DARAB > 30, ]
  
  write.csv(irat15_irattip,
            here::here("Data", "irat15_irattip.csv"),
            row.names = FALSE)
}


# PU segment ----------------------------------------------------------------------------
# Transform and save to dashboard intput
if (!is.null(t_pu_log)) {
  t_pu_log$DATUM <- ymd_hms(t_pu_log$DATUM)
  t_pu_log$DATUM <- as.character((t_pu_log$DATUM))
  t_pu_log$ERK_KONYV <- t_pu_log$ATFUT
  t_pu_log <- t_pu_log[t_pu_log$ERK_KONYV < 100, ] #outliers
  
  write.csv(
    generate_table_pu(t_pu_log, "DATUM"),
            here::here("Data", "pu_erk_konyv_full.csv"),
            row.names = FALSE)
  
  write.csv(
    generate_table_pu(t_pu_log, "DATUM", "TIPUS"),
    here::here("Data", "pu_erk_konyv_tipus.csv"),
    row.names = FALSE
  )
  
}

  
# Knit flexdahsboard
library(rmarkdown)
render(here::here("Reports", "KPI_dashboard.Rmd"))


# Redirect stdout back to console
sink(type = "message")
close(scriptLog)