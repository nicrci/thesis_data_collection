library(tidyverse)
library(DBI)
library(RSQLite)

# 1. Data Loading and Cleaning
db_path <- "investments.db"
con <- dbConnect(SQLite(), db_path)
df_indo <- dbReadTable(con, "investments") |> 
  filter(country == "Indonesia") |> 
  as_tibble()
dbDisconnect(con)

df_clean <- df_indo |>
  mutate(
    amount = as.numeric(amount),
    year   = as.integer(year)
  ) |>
  filter(!is.na(amount), !is.na(sector))

# Create output directory
output_dir <- "static/r_plots/indonesia"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# Theme definition
theme_journal <- theme_minimal(base_size = 12) +
  theme(
    panel.grid.major = element_line(color = "#e5e7eb", linewidth = 0.2),
    panel.grid.minor = element_blank(),
    axis.line        = element_line(color = "#374151", linewidth = 0.4),
    plot.title       = element_text(face = "bold", size = 14),
    legend.position  = "bottom"
  )

# 2. Yearly Trend by Transaction Type
yearly_type <- df_clean |>
  group_by(year, type) |>
  summarise(total_amount = sum(amount, na.rm = TRUE), .groups = "drop")

p_trend <- ggplot(yearly_type, aes(x = year, y = total_amount, color = type)) +
  geom_line(linewidth = 1) +
  geom_point(size = 1.5) +
  scale_y_continuous(labels = scales::comma) +
  scale_x_continuous(breaks = seq(min(df_clean$year), max(df_clean$year), by = 2), expand = c(0.05, 0)) +
  scale_color_brewer(palette = "Set1") +
  labs(title = "Yearly Investment & Construction Trend: Indonesia",
       subtitle = "Comparing absolute volume in USD Million",
       x = "Year", y = "Total Amount (USD Million)", color = "Type") +
  theme_journal

ggsave(file.path(output_dir, "yearly_trend_by_type.png"), p_trend, width = 10, height = 6, dpi = 300, bg = "white")

# 3. Year by Sector (Stacked Bar)
yearly_sector <- df_clean |>
  group_by(year, sector) |>
  summarise(total_amount = sum(amount, na.rm = TRUE), .groups = "drop")

p_sector_bar <- ggplot(yearly_sector, aes(x = year, y = total_amount, fill = sector)) +
  geom_col(width = 0.8, color = "white", linewidth = 0.1) +
  scale_y_continuous(labels = scales::comma) +
  scale_x_continuous(breaks = seq(min(df_clean$year), max(df_clean$year), by = 2)) +
  scale_fill_viridis_d(option = "plasma") +
  labs(title = "Indonesian Investment & Construction by Sector",
       x = "Year", y = "Total Amount (USD Million)", fill = "Sector") +
  theme_journal

ggsave(file.path(output_dir, "year_by_sector_stacked.png"), p_sector_bar, width = 10, height = 6, dpi = 300, bg = "white")

# 4. Top 10 Sectors (Overall)
top_sectors <- df_clean |>
  group_by(sector) |>
  summarise(total_amount = sum(amount, na.rm = TRUE)) |>
  slice_max(total_amount, n = 10)

p_top_sectors <- ggplot(top_sectors, aes(x = reorder(sector, total_amount), y = total_amount)) +
  geom_col(fill = "#0369a1") +
  coord_flip() +
  scale_y_continuous(labels = scales::comma) +
  labs(title = "Top 10 Investment & Construction Sectors in Indonesia",
       subtitle = "Total volume (2005-2025)",
       x = "Sector", y = "Total Amount (USD Million)") +
  theme_journal

ggsave(file.path(output_dir, "top_sectors_indonesia.png"), p_top_sectors, width = 8, height = 6, dpi = 300, bg = "white")

# 5. Top 10 Entities (Investors/Construction Companies) - with Sector Coloring
entity_sector <- df_clean |>
  group_by(investor, sector) |>
  summarise(sector_amount = sum(amount, na.rm = TRUE), .groups = "drop")

top_entities_list <- entity_sector |>
  group_by(investor) |>
  summarise(total_amount = sum(sector_amount), .groups = "drop") |>
  slice_max(total_amount, n = 10) |>
  pull(investor)

# For each top entity, find their primary sector (the one with the most investment)
top_entities_primary <- entity_sector |>
  filter(investor %in% top_entities_list) |>
  group_by(investor) |>
  slice_max(sector_amount, n = 1) |>
  ungroup() |>
  select(investor, primary_sector = sector)

top_entities_data <- df_clean |>
  filter(investor %in% top_entities_list) |>
  group_by(investor) |>
  summarise(total_amount = sum(amount, na.rm = TRUE), .groups = "drop") |>
  left_join(top_entities_primary, by = "investor")

p_top_entities <- ggplot(top_entities_data, aes(x = reorder(investor, total_amount), y = total_amount, fill = primary_sector)) +
  geom_col() +
  coord_flip() +
  scale_y_continuous(labels = scales::comma) +
  scale_fill_brewer(palette = "Paired") +
  labs(title = "Top 10 Chinese Entities in Indonesia",
       subtitle = "Colored by Primary Operating Sector (USD Million)",
       x = "Entity", y = "Total Amount (USD Million)", fill = "Primary Sector") +
  theme_journal

ggsave(file.path(output_dir, "top_entities_indonesia.png"), p_top_entities, width = 10, height = 6, dpi = 300, bg = "white")

# 6. Heatmap: Sector by Year
heatmap_data <- df_clean |>
  group_by(year, sector) |>
  summarise(total_amount = sum(amount, na.rm = TRUE), .groups = "drop")

p_heatmap <- ggplot(heatmap_data, aes(x = factor(year), y = sector, fill = total_amount)) +
  geom_tile(color = "white") +
  scale_fill_gradient(low = "#f0f9ff", high = "#0369a1", labels = scales::comma) +
  labs(title = "Heatmap: Investment & Construction by Sector (Indonesia)",
       subtitle = "Total volume per year (USD Million)",
       x = "Year", y = "Sector", fill = "Amount") +
  theme_journal +
  theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1))

ggsave(file.path(output_dir, "sector_year_heatmap_indonesia.png"), p_heatmap, width = 10, height = 7, dpi = 300, bg = "white")

cat("\nVisualizations for Indonesia saved to 'static/r_plots/indonesia/':\n")
cat("- yearly_trend_by_type.png\n")
cat("- year_by_sector_stacked.png\n")
cat("- top_sectors_indonesia.png\n")
cat("- top_entities_indonesia.png\n")
cat("- sector_year_heatmap_indonesia.png\n")
