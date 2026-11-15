library(tidyverse)
library(DBI)
library(RSQLite)

# 1. Load data
con <- dbConnect(SQLite(), "investments.db")
df <- dbReadTable(con, "investments") |> as_tibble()
dbDisconnect(con)

# 2. Check for exact duplicates (all columns except 'id')
# We exclude 'id' because it's an autoincrementing primary key in the DB.
df_no_id <- df |> select(-id)
total_rows <- nrow(df_no_id)
unique_rows <- nrow(distinct(df_no_id))
duplicates_count <- total_rows - unique_rows

print(paste("Total rows:", total_rows))
print(paste("Duplicate rows found:", duplicates_count))

if (duplicates_count > 0) {
  print("Sample of duplicated rows:")
  df_no_id |> 
    group_by_all() |> 
    filter(n() > 1) |> 
    ungroup() |> 
    head(10) |> 
    print()
}

# 3. Specifically investigate USA entries
usa_df <- df |> filter(country == "USA")

print(paste("Total USA records before cleaning:", nrow(usa_df)))

# Check for "near-duplicates" (same year, investor, target, amount, but maybe different month/share)
near_duplicates <- usa_df |>
  group_by(year, investor, target, amount) |>
  filter(n() > 1) |>
  arrange(year, investor)

print("Sample of 'near-duplicates' in USA (same Year, Investor, Target, Amount):")
print(head(near_duplicates, 10))

# 4. Clean the full dataset (removing exact duplicates)
df_cleaned <- df |> 
  select(-id) |> 
  distinct()

# 5. Re-run top 10 combined frequency
cleaned_top_10 <- df_cleaned |>
  count(country, sort = TRUE) |>
  head(10)

print("--- Top 10 Countries (After removing exact duplicates) ---")
print(cleaned_top_10)

# Check USA count after cleaning
print(paste("USA count after cleaning:", nrow(df_cleaned |> filter(country == "USA"))))
