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

# Create connection driver and open connection
jdbcDriver <-
  JDBC(driverClass = "oracle.jdbc.OracleDriver",
       classPath = "C:\\Users\\PoorJ\\Desktop\\ojdbc7.jar")

jdbcConnection <-
  dbConnect(
    jdbcDriver,
    url = ablak$server,
    user = ablak$uid,
    password = ablak$pwd
  )

# Read in SQL script from file
portf <-
  readQuery(here::here("SQL", "kpi_portf.sql"))

# Query on the Oracle instance name
t_al_curr <- dbGetQuery(jdbcConnection, portf)

# Close connection
dbDisconnect(jdbcConnection)



# Add to log on local storage then load log
t_al_log <- write_to_log(t_al_curr, here::here("Data", "al_kpi_log.csv"))

# Transform and save to dashboard intput
if (!is.null(t_al_log)) {
  t_al_log$DATUM <- ymd_hms(t_al_log$DATUM)
  t_al_log$DATUM <- as.character((t_al_log$DATUM))
  t_al_log <- t_al_log[t_al_log$ERK_SZERZ < 100, ] #outlier kezel�s
  
  
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
  
  
  traject <- t_al_curr[t_al_curr$KOTVENYESITES == "Manualis", ]
  traject <- traject[traject$ERK_SZERZ < 100, ]
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
  
  #Trajectory manu�lis term�keknk�nt
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
  


  #Kontakt adatok#########################################################################x  
  # Set JAVA_HOME, set max. memory, and load rJava library
  Sys.setenv(JAVA_HOME = "C:\\Program Files\\Java\\jre1.8.0_60")
  options(java.parameters = "-Xmx2g")
  library(rJava)
  
  # Output Java version
  .jinit()
  print(.jcall("java/lang/System", "S", "getProperty", "java.version"))
  
  # Load RJDBC library
  library(RJDBC)
  
  # Create connection driver and open connection
  jdbcDriver <- JDBC(driverClass = "oracle.jdbc.OracleDriver", classPath = "C:\\Users\\PoorJ\\Desktop\\ojdbc7.jar")
  jdbcConnection <- dbConnect(jdbcDriver, "jdbc:oracle:thin:@//mmbdb:6678/ikon", "POORJ", "Aegon2021")
  
  bsc_kontakt_data_napi <- dbGetQuery(jdbcConnection, 
                                      "
                                      select   distinct
                                      trunc (sysdate - 1, 'ddd') as datum,
                                      f_ivk,
                                      f_kpi_kat,
                                      case
                                      when irat_tipus in
                                      ('_AFC_L_Aj�nlatkezel�s',
                                      '_AFC_L_Visszaes� t�tel',
                                      '_AFC_L_D�jkezel�s',
                                      '_AFC_L_Szerz�d�skezel�s')
                                      then
                                      irat_tipus
                                      else
                                      'Egy�b'
                                      end
                                      as irat_tipus,
                                      f_szarm_szerv,
                                      case when afcerk_lezarva_mn > 15 then 1 else 0 end as nap15,
                                      afcerk_lezarva_mn as erk_lezar
                                      from
                                      t_bsc_irat t1
                                      where   
                                      lezarva between trunc (sysdate - 1, 'mm') and trunc (sysdate, 'ddd')
                                      and lezaro_szervezet = 'AFC'
                                      and f_alirattipusid not in ('1940', '1941', '1942', '1943') --ig�nyfelm�r�
                                      and  NOT EXISTS (SELECT 1 FROM kontakt.t_irat_wflog t2 WHERE t2.f_ivk = t1.f_ivk AND t2.f_wfid = 1195)
                                      and f_irat_tipusid not in (418, 423, 430, 453)
                                      and afcerk_lezarva_mn <= 100
                                      ")

  # Close connection
  dbDisconnect(jdbcConnection)

  if (nrow(bsc_kontakt_data_napi)!=0) 
  {
    #id�szakosan napi adat�llom�ny ki�r�sa
    write.csv(bsc_kontakt_data_napi, sprintf("Napi_konakt_bsc_%s.csv", Sys.Date()-1), row.names = FALSE)
    
    #Log
    flist2 <- list.files("C:/Users/PoorJ/Desktop/Mischung/R/BSC monitor", ".csv")
    hits2 <- unlist(sapply(flist2, function(x)grepl(sprintf("History_kontakt_bsc_%s.csv", paste0(year(Sys.Date()-1), month(Sys.Date()-1))), x)))
    
    if (sum(hits2)==0) {
      write.csv(bsc_kontakt_data_napi, sprintf("History_kontakt_bsc_%s.csv", paste0(year(Sys.Date()), month(Sys.Date()))), row.names = FALSE)
      history_kontakt <- bsc_kontakt_data_napi
    }else{
      history_kontakt <- read.csv(sprintf("History_kontakt_bsc_%s.csv", paste0(year(Sys.Date()-1), month(Sys.Date()-1))))
      history_kontakt <- rbind(history_kontakt, bsc_kontakt_data_napi)
      write.csv(history_kontakt, sprintf("History_kontakt_bsc_%s.csv", paste0(year(Sys.Date()-1), month(Sys.Date()-1))), row.names = FALSE)
    }
    
    #Transform
    history_kontakt$DATUM <- ymd_hms(history_kontakt$DATUM)
    history_kontakt$DATUM <- as.character((history_kontakt$DATUM))
    history_kontakt <- history_kontakt[history_kontakt$ERK_LEZAR < 100, ] #outlier kezel�s
    
    #Generators
    generate_table_kontakt <- function(tabla, ...) {
      tbl_df(tabla) %>%
        group_by_(...) %>%
        summarize(DARAB = length(F_IVK),
                  ERK_LEZAR_ATLAG = round(mean(ERK_LEZAR), 2),
                  ERK_LEZAR_MEDIAN = round(median(ERK_LEZAR), 2),
                  ERK_LEZAR_SD = round(sd(ERK_LEZAR), 2),
                  ERK_LEZAR_MAD = round(mad(ERK_LEZAR), 2)) %>%
        ungroup() %>% #weight within monthly volume
        group_by_("DATUM") %>% #weight within monthly volume
        mutate(DB_SULY = round(DARAB/sum(DARAB), 4)) %>% #weight within monthly volume
        ungroup() %>% # bring stacked bar text to middle position
        group_by_(...) %>% # bring stacked bar text to middle position
        mutate(POS=cumsum(ERK_LEZAR_ATLAG)-(0.5*ERK_LEZAR_ATLAG)) # bring stacked bar text to middle position
    }
    
    
    generate_table_15_kontakt <- function(tabla, ...) {
      tbl_df(tabla) %>%
        group_by_(...) %>%
        summarize(DARAB = length(F_IVK),
                  NAGYOBB_15_NAP = sum(NAP15)/length(F_IVK)) %>%
        ungroup() %>% #weight within monthly volume
        group_by_("DATUM") %>% #weight within monthly volume
        mutate(DB_SULY = round(DARAB/sum(DARAB), 4)) %>% #weight within monthly volume
        ungroup() %>% # bring stacked bar text to middle position
        group_by_(...) %>% # bring stacked bar text to middle position
        mutate(POS=cumsum(NAGYOBB_15_NAP)-(0.5*NAGYOBB_15_NAP)) # bring stacked bar text to middle position
    }
    
    #BSC irat erk_lezar
    #FULL
    erk_lezar <- generate_table_kontakt(history_kontakt, "DATUM")
    write.csv(erk_lezar, "kontakt_erk_lezar_full.csv", row.names = FALSE)
    
    ggplot(erk_lezar, aes(x=DATUM, y=ERK_LEZAR_ATLAG)) +
      geom_bar(stat = "identity", fill = "#0072B2") +
      ylim(0,8) +
      geom_hline(aes(yintercept=2.5), colour="#990000", linetype = "dashed") +
      geom_text(aes(0,2.5,label = "Kiv�l� (2,5)", vjust = 0, hjust = 0), size = 4.5) +
      geom_hline(aes(yintercept=3.5), colour="#990000", linetype = "dashed") +
      geom_text(aes(0,3.5,label = "J� (3,5)", vjust = 0, hjust = 0), size = 4.5) +
      geom_hline(aes(yintercept=4.5), colour="#990000", linetype = "dashed") +
      geom_text(aes(0,4.5,label = "�tlagos (4,5)", vjust = 0, hjust = 0), size = 4.5) +
      geom_text(aes(label=ERK_LEZAR_ATLAG, y = POS), size = 4, color = "black", fontface = "bold") +
      theme(axis.text.x = element_text(angle = 90)) +
      ggtitle("Iratkezel�s benchmark: �rkez�st�l lez�r�sig munkanap �tlag")
    ggsave("Iratkezeles_FULL.png", width=10, height=7.5, dpi=300) 
    
    #IRATTIPUS
    erk_lezar_irattip <- generate_table_kontakt(history_kontakt, "DATUM", "IRAT_TIPUS")
    erk_lezar_irattip <- erk_lezar_irattip[erk_lezar_irattip$DARAB > 30, ]
    write.csv(erk_lezar_irattip, "kontakt_erk_lezar_irattip.csv", row.names = FALSE)
    
    #SZARM_SZERV + IRATTIPUS
    erk_lezar_szerv_irattip <- generate_table_kontakt(history_kontakt, "DATUM", "F_SZARM_SZERV", "IRAT_TIPUS")
    erk_lezar_szerv_irattip <- erk_lezar_szerv_irattip[erk_lezar_szerv_irattip$DARAB > 30, ]
    
    ggplot(erk_lezar_szerv_irattip, aes(x=DATUM, y=ERK_LEZAR_ATLAG)) +
      geom_bar(stat = "identity", fill = "#0072B2") +
      ylim(0,8) +
      geom_hline(aes(yintercept=2.5), colour="#990000", linetype = "dashed") +
      geom_text(aes(0,2.5,label = "Kiv�l� (2,5)", vjust = 0, hjust = 0), size = 2.5) +
      geom_hline(aes(yintercept=3.5), colour="#990000", linetype = "dashed") +
      geom_text(aes(0,3.5,label = "J� (3,5)", vjust = 0, hjust = 0), size = 2.5) +
      geom_hline(aes(yintercept=4.5), colour="#990000", linetype = "dashed") +
      geom_text(aes(0,4.5,label = "�tlagos (4,5)", vjust = 0, hjust = 0), size = 2.5) +
      geom_text(aes(label=ERK_LEZAR_ATLAG, y = POS+0.8), size = 2.5, color = "black", fontface = "bold") +
      geom_text(aes(label=sprintf("%1.0f%%", 100*DB_SULY), y = POS), size = 2.5, color = "black", fontface = "bold") +
      theme(axis.text.x = element_text(angle = 90)) +
      ggtitle("Iratkezel�s benchmark: �rkez�st�l lez�r�sig munkanap �tlag\n(A sz�zal�kos �rt�k a kateg�ria napi �llom�nyon bel�li s�ly�t mutatja)") +
      facet_grid(F_SZARM_SZERV ~ IRAT_TIPUS)
    ggsave("Iratkezeles_szerv_irattip.png", width=12, height=8, dpi=500) 
    
    #15 napon t�li ar�ny
    #FULL
    irat15 <- generate_table_15_kontakt(history_kontakt, "DATUM")
    write.csv(irat15, "irat15.csv", row.names = FALSE)
    
    ggplot(irat15, aes(x=DATUM, y=NAGYOBB_15_NAP)) +
      geom_bar(stat = "identity", fill = "#0072B2") +
      scale_y_continuous(labels=percent, limits=(c(0, 0.1))) +
      geom_hline(aes(yintercept=0.01), colour="#990000", linetype = "dashed") +
      geom_text(aes(0,0.01,label = "Kiv�l� (1%)", vjust = 0, hjust = 0), size = 4.5) +
      geom_hline(aes(yintercept=0.02), colour="#990000", linetype = "dashed") +
      geom_text(aes(0,0.02,label = "J� (2%)", vjust = 0, hjust = 0), size = 4.5) +
      geom_hline(aes(yintercept=0.03), colour="#990000", linetype = "dashed") +
      geom_text(aes(0,0.03,label = "�tlagos (3%)", vjust = 0, hjust = 0), size = 4.5) +
      geom_text(aes(label=sprintf("%1.2f%%", 100*NAGYOBB_15_NAP), y = POS), size = 4, color = "black", fontface = "bold") +
      theme(axis.text.x = element_text(angle = 90)) +
      ggtitle("Irat 15 napon t�l k�tv�nyes�tett benchmark: ar�ny")
    ggsave("Irat_15_nap.png", width=10, height=7.5, dpi=300)
    
    #IRATTIP
    irat15_irattip <- generate_table_15_kontakt(history_kontakt, "DATUM", "IRAT_TIPUS")
    irat15_irattip <- irat15_irattip[irat15_irattip$DARAB > 30, ]
    write.csv(irat15_irattip, "irat15_irattip.csv", row.names = FALSE)
    
    #SZARM_SZERV + IRATTIPUS
    irat15_szerv_irattip <- generate_table_15_kontakt(history_kontakt, "DATUM", "F_SZARM_SZERV", "IRAT_TIPUS")
    irat15_szerv_irattip <- irat15_szerv_irattip[irat15_szerv_irattip$DARAB > 30, ]
    
    ggplot(irat15_szerv_irattip, aes(x=DATUM, y=NAGYOBB_15_NAP)) +
      geom_bar(stat = "identity", fill = "#0072B2") +
      scale_y_continuous(labels=percent) +
      geom_hline(aes(yintercept=0.01), colour="#990000", linetype = "dashed") +
      geom_text(aes(0,0.01,label = "Kiv�l� (1%)", vjust = 0, hjust = 0), size = 2.5) +
      geom_hline(aes(yintercept=0.02), colour="#990000", linetype = "dashed") +
      geom_text(aes(0,0.02,label = "J� (2%)", vjust = 0, hjust = 0), size = 2.5) +
      geom_hline(aes(yintercept=0.03), colour="#990000", linetype = "dashed") +
      geom_text(aes(0,0.03,label = "�tlagos (3%)", vjust = 0, hjust = 0), size = 2.5) +
      geom_text(aes(label=sprintf("%1.2f%%", 100*NAGYOBB_15_NAP), y = POS+0.01), size = 2.5, color = "black", fontface = "bold") +
      geom_text(aes(label=sprintf("%1.0f%%", 100*DB_SULY), y = POS), size = 2.5, color = "black", fontface = "bold") +
      theme(axis.text.x = element_text(angle = 90)) +
      ggtitle("Irat 15 napon t�l k�tv�nyes�tett benchmark: ar�ny\n(A m�sodik sz�zal�kos �rt�k a kateg�ria napi �llom�nyon bel�li s�ly�t mutatja)") +
      facet_grid(F_SZARM_SZERV ~ IRAT_TIPUS)
    ggsave("Irat_15_nap_szerv_irattip.png", width=14, height=7.5, dpi=300) 
  }
  
  ##P�nz�gy adatok###################################################################x
  # Set JAVA_HOME, set max. memory, and load rJava library
  Sys.setenv(JAVA_HOME="C:\\Program Files\\Java\\jre1.8.0_60")
  options(java.parameters="-Xmx2g")
  library(rJava)
  
  # Output Java version
  .jinit()
  print(.jcall("java/lang/System", "S", "getProperty", "java.version"))
  
  # Load RJDBC library
  library(RJDBC)
  
  # Create connection driver and open connection
  jdbcDriver <- JDBC(driverClass="oracle.jdbc.OracleDriver", classPath="C:\\Users\\PoorJ\\Desktop\\ojdbc7.jar")
  jdbcConnection <- dbConnect(jdbcDriver, "jdbc:oracle:thin:@//dijtart:9929/peep", "POORJ", "Poor01234.")
  
  
  # Query on the Oracle instance name.
  pu_data_napi <- dbGetQuery(jdbcConnection, 
                              "
                              select trunc(sysdate, 'ddd') - 1 as datum,
                              a.* from t_bsc_pu a
                              ")
  
  # Close connection
  dbDisconnect(jdbcConnection)
  
  
  if (nrow(pu_data_napi)!=0) 
  {
    #id�szakosan napi adat�llom�ny ki�r�sa
    write.csv(pu_data_napi, sprintf("Napi_pu_bsc_%s.csv", Sys.Date()-1), row.names = FALSE)
    
    #Log
    flist <- list.files("C:/Users/PoorJ/Desktop/Mischung/R/BSC monitor", ".csv")
    hits <- unlist(sapply(flist, function(x)grepl(sprintf("History_pu_bsc_%s.csv", paste0(year(Sys.Date()-1), month(Sys.Date()-1))), x)))
    
    if (sum(hits)==0) {
      write.csv(pu_data_napi, sprintf("History_pu_bsc_%s.csv", paste0(year(Sys.Date()), month(Sys.Date()))), row.names = FALSE)
      history_pu <- pu_data_napi
    }else{
      history_pu <- read.csv(sprintf("History_pu_bsc_%s.csv", paste0(year(Sys.Date()-1), month(Sys.Date()-1))))
      history_pu <- rbind(history_pu, pu_data_napi)
      write.csv(history_pu, sprintf("History_pu_bsc_%s.csv", paste0(year(Sys.Date()-1), month(Sys.Date()-1))), row.names = FALSE)
    }
    
    #Transform
    history_pu$DATUM <- ymd_hms(history_pu$DATUM)
    history_pu$DATUM <- as.character((history_pu$DATUM))
    history_pu$ERK_KONYV <- history_pu$ATFUT
    history_pu <- history_pu[history_pu$ERK_KONYV < 100, ] #outlier kezel�s
    
    #2017.05.11. FUFI d�jak korrekci�ja
    history_pu <- history_pu[!(as.character(ymd_hms(history_pu$KONYVDAT)) == '2017-05-11 00:00:00' & history_pu$TIPUS %in% c('FUFI PSM', 'FUFI f�gg�', 'FUFI foglal�')) , ]
    
    #Generators
    generate_table_pu <- function(tabla, ...)
    {
      tbl_df(tabla) %>%
        group_by_(...) %>%
        summarize(DARAB = length(SORSZAM),
                  ERK_KONYV_ATLAG = round(mean(ERK_KONYV), 2),
                  ERK_KONYV_MEDIAN = round(median(ERK_KONYV), 2),
                  ERK_KONYV_SD = round(sd(ERK_KONYV), 2),
                  ERK_KONYV_MAD = round(mad(ERK_KONYV), 2)) %>%
        ungroup() %>% #weight within monthly volume
        group_by_("DATUM") %>% #weight within monthly volume
        mutate(DB_SULY = round(DARAB/sum(DARAB), 4)) %>% #weight within monthly volume
        ungroup() %>% # bring stacked bar text to middle position
        group_by_(...) %>% # bring stacked bar text to middle position
        mutate(POS=cumsum(ERK_KONYV_ATLAG)-(0.5*ERK_KONYV_ATLAG)) # bring stacked bar text to middle position
    }
    
   
    #Manualis konyveles
    #FULL
    pu_erk_konyv <- generate_table_pu(history_pu, "DATUM")
    write.csv(pu_erk_konyv, "pu_erk_konyv_full.csv", row.names = FALSE)
    
    ggplot(pu_erk_konyv, aes(x=DATUM, y=ERK_KONYV_ATLAG)) +
      geom_bar(stat = "identity", fill = "#0072B2") +
      #ylim(0,7) +
      geom_hline(aes(yintercept=3.5), colour="#990000", linetype = "dashed") +
      geom_text(aes(0,3.5,label = "Kiv�l� (3,5)", vjust = 0, hjust = 0), size = 4.5) +
      geom_hline(aes(yintercept=4.5), colour="#990000", linetype = "dashed") +
      geom_text(aes(0,4.5,label = "J� (4,5)", vjust = 0, hjust = 0), size = 4.5) +
      geom_hline(aes(yintercept=5.5), colour="#990000", linetype = "dashed") +
      geom_text(aes(0,5.5,label = "�tlagos (5,5)", vjust = 0, hjust = 0), size = 4.5) +
      geom_text(aes(label=ERK_KONYV_ATLAG, y = POS), size = 4, color = "black", fontface = "bold") +
      theme(axis.text.x = element_text(angle = 90)) +
      ggtitle("AFC manu�lis k�nyvel�s benchmark: �rkez�st�l k�nyvel�sig munkanap �tlag")
    ggsave("Konyveles.png", width=10, height=7.5, dpi=300)  

    #        
    #K�T�SI M�D + TERMCSOP
    pu_erk_konyv_tipus <- generate_table_pu(history_pu, "DATUM", "TIPUS")
    write.csv(pu_erk_konyv_tipus, "pu_erk_konyv_tipus.csv", row.names = FALSE)
    
    ggplot(pu_erk_konyv_tipus, aes(x=DATUM, y=ERK_KONYV_ATLAG)) +
      geom_bar(stat = "identity", fill = "#0072B2") +
      geom_hline(aes(yintercept=3.5), colour="#990000", linetype = "dashed") +
      geom_text(aes(0,3.5,label = "Kiv�l� (3,5)", vjust = 0, hjust = 0), size = 2.5) +
      geom_hline(aes(yintercept=4.5), colour="#990000", linetype = "dashed") +
      geom_text(aes(0,4.5,label = "J� (4,5)", vjust = 0, hjust = 0), size = 2.5) +
      geom_hline(aes(yintercept=5.5), colour="#990000", linetype = "dashed") +
      geom_text(aes(0,5.5,label = "�tlagos (5,5)", vjust = 0, hjust = 0), size = 2.5) +
      geom_text(aes(label=ERK_KONYV_ATLAG, y = POS+0.8), size = 2.5, color = "black", fontface = "bold") +
      geom_text(aes(label=sprintf("%1.0f%%", 100*DB_SULY), y = POS-0.5), size = 2.5, color = "black", fontface = "bold") +
      theme(axis.text.x = element_text(angle = 90)) +
      ggtitle("AFC manu�lis k�nyvel�s benchmark: �rkez�st�l meneszt�sig munkanap �tlag\n(A sz�zal�kos �rt�k a kateg�ria napi �llom�nyon bel�li s�ly�t mutatja)") +
      facet_grid(TIPUS ~.)
    ggsave("Konyveles_tipus.png", width=12, height=8, dpi=500) 
  }
  
  # Knit flexdahsboard
  library(rmarkdown)
  render("BSC_dashboard.Rmd")
  
  # Copy to public folder
  file.copy("C:/Users/PoorJ/Desktop/Mischung/R/BSC monitor/BSC_dashboard.html", "C:/Users/PoorJ/Desktop/Mischung/R/AFC_publish", overwrite = T)
  
  
  # Redirect stdout back to console
sink(type = "message")
close(scriptLog)