
library(tidyverse)
library(DBI)
library(RSQLite)

db_path <- "investments.db"

# Connect to the database
con <- dbConnect(SQLite(), db_path)
df <- dbReadTable(con, "investments") |> as_tibble()
dbDisconnect(con)

# Clean data
df_clean <- df |>
  mutate(
    amount = as.numeric(amount),
    year   = as.integer(year)
  ) |>
  filter(!is.na(amount), !is.na(sector), !is.na(region))

# 1. Cross table of region by sector (Total Amount)
region_sector_table <- df_clean |>
  group_by(region, sector) |>
  summarise(total_amount = sum(amount, na.rm = TRUE), .groups = "drop") |>
  pivot_wider(names_from = sector, values_from = total_amount, values_fill = 0)

# 2. Trends table (Region, Sector, Year)
trends_table <- df_clean |>
  group_by(region, sector, year) |>
  summarise(yearly_amount = sum(amount, na.rm = TRUE), .groups = "drop") |>
  arrange(region, sector, year)

# 3. Year vs Region (Trend)
year_region_table <- df_clean |>
  group_by(year, region) |>
  summarise(total_amount = sum(amount, na.rm = TRUE), .groups = "drop") |>
  pivot_wider(names_from = region, values_from = total_amount, values_fill = 0) |>
  arrange(year)

# 4. Year vs Sector (Trend)
year_sector_table <- df_clean |>
  group_by(year, sector) |>
  summarise(total_amount = sum(amount, na.rm = TRUE), .groups = "drop") |>
  pivot_wider(names_from = sector, values_from = total_amount, values_fill = 0) |>
  arrange(year)

# Print first table
cat("\n--- Table 1: Total Investment by Region and Sector ---\n")
print(region_sector_table, n = Inf, width = Inf)

# Print Trend Tables
cat("\n--- Table 2: Investment Trends: Year vs Region ---\n")
print(year_region_table, n = Inf, width = Inf)

cat("\n--- Table 3: Investment Trends: Year vs Sector ---\n")
print(year_sector_table, n = Inf, width = Inf)

# Save to CSV
write_csv(region_sector_table, "region_sector_cross_table.csv")
write_csv(trends_table, "region_sector_year_long.csv")
write_csv(year_region_table, "year_region_trend_table.csv")
write_csv(year_sector_table, "year_sector_trend_table.csv")

# --- Visualizations ---
output_dir <- "static/r_plots"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

theme_journal <- theme_minimal(base_size = 10) +
  theme(
    panel.grid.major = element_line(color = "#e5e7eb", linewidth = 0.2),
    panel.grid.minor = element_blank(),
    axis.line        = element_line(color = "#374151", linewidth = 0.4),
    plot.title       = element_text(face = "bold", size = 12),
    legend.position  = "bottom"
  )

# 1. Heatmap: Region by Sector
heatmap_data <- df_clean |>
  group_by(region, sector) |>
  summarise(total_amount = sum(amount, na.rm = TRUE), .groups = "drop")

p_heatmap <- ggplot(heatmap_data, aes(x = sector, y = region, fill = total_amount)) +
  geom_tile(color = "white") +
  scale_fill_gradient(low = "#f0f9ff", high = "#0369a1", labels = scales::comma) +
  labs(title = "Total Investment by Region and Sector (USD Million)",
       x = "Sector", y = "Region", fill = "Total Amount") +
  theme_journal +
  theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1))

ggsave(file.path(output_dir, "region_sector_heatmap.png"), p_heatmap, width = 10, height = 7, dpi = 300, bg = "white")

# 2. Line Chart: Trends by Region
p_region_trend <- ggplot(year_region_table |> pivot_longer(-year, names_to = "region", values_to = "amount"), 
                         aes(x = year, y = amount, color = region)) +
  geom_line(linewidth = 1) +
  geom_point(size = 1.5) +
  scale_y_continuous(labels = scales::comma) +
  labs(title = "Investment Trends by Region (2005-2025)",
       x = "Year", y = "Total Investment (USD Million)", color = "Region") +
  theme_journal

ggsave(file.path(output_dir, "region_trends_line.png"), p_region_trend, width = 10, height = 6, dpi = 300, bg = "white")

# 3. Line Chart: Trends by Sector (Top 10)
top_sectors <- df_clean |> group_by(sector) |> summarise(total = sum(amount)) |> slice_max(total, n = 10) |> pull(sector)

p_sector_trend <- ggplot(df_clean |> filter(sector %in% top_sectors) |> group_by(year, sector) |> summarise(amount = sum(amount), .groups = "drop"), 
                         aes(x = year, y = amount, color = sector)) +
  geom_line(linewidth = 1) +
  geom_point(size = 1.5) +
  scale_y_continuous(labels = scales::comma) +
  labs(title = "Investment Trends: Top 10 Sectors (2005-2025)",
       x = "Year", y = "Total Investment (USD Million)", color = "Sector") +
  theme_journal

ggsave(file.path(output_dir, "sector_trends_line.png"), p_sector_trend, width = 10, height = 6, dpi = 300, bg = "white")

cat("\nVisualizations saved to 'static/r_plots/':\n")
cat("- region_sector_heatmap.png\n")
cat("- region_trends_line.png\n")
cat("- sector_trends_line.png\n")
