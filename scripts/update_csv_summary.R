library(tidyverse)
library(DBI)
library(RSQLite)

# 1. Load the dataset
db_path <- "investments.db"
con <- dbConnect(SQLite(), db_path)
df <- dbReadTable(con, "investments") |> as_tibble()
dbDisconnect(con)

# 2. Create a comprehensive summary by country
country_summary <- df |>
  group_by(country) |>
  summarise(
    total_activities = n(),
    investment_count = sum(type == "Investment", na.rm = TRUE),
    construction_count = sum(type == "Construction", na.rm = TRUE),
    unique_investors = n_distinct(investor),
    unique_targets = n_distinct(target),
    .groups = "drop"
  ) |>
  arrange(desc(construction_count))

# 3. Save to CSV
write.csv(country_summary, "country_comprehensive_summary.csv", row.names = FALSE)

print("Comprehensive summary with construction counts saved to country_comprehensive_summary.csv")

# 4. Display the top 10 by construction for verification
print("--- Top 10 Countries by Construction (Verification) ---")
country_summary |>
  select(country, construction_count) |>
  head(10) |>
  print()
