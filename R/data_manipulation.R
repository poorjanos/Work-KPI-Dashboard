# Function to read in SQL scripts from file
readQuery <-
  function(file)
    paste(readLines(file, warn = FALSE), collapse = "\n")


# Function to write daily query results to log on local storage
write_to_log <- function(df_curr, path_to_log, date_to_check) {
  # Initialize curr as hist if folder empty and enough data in curr
  if (!file.exists(path_to_log) & nrow(df_curr) > 100) {
    df_hist <- df_curr
    write.csv(df_hist, path_to_log, row.names = FALSE)
    return(df_hist)
    # Exit if folder empty but not enough data in curr
  } else if (!file.exists(path_to_log) & nrow(df_curr) < 100) {
    return()
    # Check max record dates if folder not empty
  } else {
    df_hist <-
      read.csv(path_to_log, stringsAsFactors = FALSE)
    max_hist_date <-
      max(floor_date(ymd_hms(df_hist[[date_to_check]]), "day"))
    max_curr_date <-
      max(floor_date(ymd_hms(df_curr[[date_to_check]]), "day"))
    # Re-init curr as hist if newmonth starts
    if (month(max_hist_date) < month(max_curr_date) &
        nrow(df_curr) > 100) {
      df_hist <- df_curr
      write.csv(df_hist, path_to_log, row.names = FALSE)
      return(df_hist)
      # Append curr to hist if within month
    } else if (max_curr_date > max_hist_date &
               nrow(df_curr) > 100) {
      df_hist <- rbind(df_hist, df_curr)
      write.csv(df_hist, path_to_log, row.names = FALSE)
      return(df_hist)
    }
  }
}


# Function to generate KPI aggregates: AL
generate_table <- function(tabla, ...) {
  tbl_df(tabla) %>%
    group_by_(...) %>%
    summarize(
      DARAB = length(VONALKOD),
      ERK_SZERZ_ATLAG = round(mean(ERK_SZERZ), 2),
      ERK_SZERZ_MEDIAN = round(median(ERK_SZERZ), 2),
      ERK_SZERZ_SD = round(sd(ERK_SZERZ), 2),
      ERK_SZERZ_MAD = round(mad(ERK_SZERZ), 2)
    ) %>%
    ungroup() %>% #weight within monthly volume
    group_by_("DATUM") %>% #weight within monthly volume
    mutate(DB_SULY = round(DARAB / sum(DARAB), 4)) %>% #weight within monthly volume
    ungroup() %>% # bring stacked bar text to middle position
    group_by_(...) %>% # bring stacked bar text to middle position
    mutate(POS = cumsum(ERK_SZERZ_ATLAG) - (0.5 * ERK_SZERZ_ATLAG)) # bring stacked bar text to middle position
}


# Function to generate KPI aggregates: AL
generate_table_15 <- function(tabla, ...) {
  tbl_df(tabla) %>%
    group_by_(...) %>%
    summarize(DARAB = length(VONALKOD),
              NAGYOBB_15_NAP = sum(ifelse(ERK_SZERZ > 15, 1, 0) / length(VONALKOD))) %>%
    ungroup() %>% #weight within monthly volume
    group_by_("DATUM") %>% #weight within monthly volume
    mutate(DB_SULY = round(DARAB / sum(DARAB), 4)) %>% #weight within monthly volume
    ungroup() %>% # bring stacked bar text to middle position
    group_by_(...) %>% # bring stacked bar text to middle position
    mutate(POS = cumsum(NAGYOBB_15_NAP) - (0.5 * NAGYOBB_15_NAP)) # bring stacked bar text to middle position
}


# Function to generate KPI aggregates: IL
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


# Function to generate KPI aggregates: IL
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


# Function to generate KPI aggregates: PU
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