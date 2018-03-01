# Function to read in SQL scripts from file
readQuery <-
  function(file)
    paste(readLines(file, warn = FALSE), collapse = "\n")


# Function to write daily query results to log on local storage
write_to_log <- function(df_curr, path_to_log) {
  # Initialize curr as hist if folder empty
  if (!file.exists(path_to_log) & nrow(df_curr) > 100) {
    df_hist <- df_curr
    write.csv(df_hist, path_to_log, row.names = FALSE)
    return(df_hist)
    # Check further if folder not empty
  } else {
    df_hist <-
      read.csv(path_to_log, stringsAsFactors = FALSE)
    max_hist_date <-
      max(floor_date(ymd_hms(df_hist$SZERZDAT), "day"))
    max_curr_date <-
      max(floor_date(ymd_hms(df_curr$SZERZDAT), "day"))
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
