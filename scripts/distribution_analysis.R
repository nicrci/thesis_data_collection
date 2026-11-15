library(tidyverse)
library(DBI)
library(RSQLite)

# 1. Load the dataset
db_path <- "investments.db"
con <- dbConnect(SQLite(), db_path)
df <- dbReadTable(con, "investments") |> as_tibble()
dbDisconnect(con)

# Basic cleaning (similar to analysis.R)
df <- df |>
  mutate(
    amount = as.numeric(amount),
    year = as.integer(year)
  )

# 2. List the distribution
print("--- Dataset Structure ---")
glimpse(df)

print("--- Distribution of Investment Amounts (Summary) ---")
print(summary(df$amount))

print("--- Distribution of Investments by Year ---")
df |> 
  count(year) |> 
  arrange(year) |> 
  print(n = Inf)

print("--- Distribution of Investments by Sector ---")
df |> 
  count(sector, sort = TRUE) |> 
  print()

# 3. Frequency tables of investments by country
print("--- Frequency Table: Top 20 Countries by Number of Investments ---")
country_freq <- df |> 
  count(country, sort = TRUE)
print(head(country_freq, 20))

# 4. Number of entities involved
# We can define "entities" as unique investors and unique targets.
print("--- Number of Entities Involved by Country ---")
entity_summary <- df |>
  group_by(country) |>
  summarise(
    num_investments = n(),
    unique_investors = n_distinct(investor),
    unique_targets = n_distinct(target),
    .groups = "drop"
  ) |>
  arrange(desc(num_investments))

print(head(entity_summary, 20))

# Save the entity summary to a CSV for the user
write.csv(entity_summary, "country_entity_summary.csv", row.names = FALSE)
print("Detailed summary saved to country_entity_summary.csv")
