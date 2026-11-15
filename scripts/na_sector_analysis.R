library(tidyverse)
library(DBI)
library(RSQLite)

# Connect to the database
con <- dbConnect(SQLite(), "investments.db")
df <- dbReadTable(con, "investments") |> as_tibble()
dbDisconnect(con)

# Filter for North America
na_df <- df |> 
  filter(region == "North America") |>
  mutate(amount = as.numeric(amount))

# Create cross table of country by sector (Total Amount)
na_cross_table <- na_df |>
  group_by(country, sector) |>
  summarise(total_amount = sum(amount, na.rm = TRUE), .groups = "drop") |>
  pivot_wider(names_from = sector, values_from = total_amount, values_fill = 0)

# Identify top sectors in the USA
usa_top_sectors <- na_df |>
  filter(country == "USA") |>
  group_by(sector) |>
  summarise(total_amount = sum(amount, na.rm = TRUE)) |>
  arrange(desc(total_amount))

# Print Results
cat("\n--- North America Country by Sector Cross Table (Total Amount) ---\n")
print(na_cross_table, n = Inf, width = Inf)

cat("\n--- Top Sectors in the USA ---\n")
print(usa_top_sectors)

# Save to CSV
write_csv(na_cross_table, "na_country_sector_cross_table_r.csv")
cat("\nCross table saved to 'na_country_sector_cross_table_r.csv'\n")
