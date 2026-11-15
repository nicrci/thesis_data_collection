# ============================================================
#  Sector Yearly Trends — Journal Quality
# ============================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(DBI)
  library(RSQLite)
  library(scales)
})

db_path <- "investments.db"
output_dir <- "static/r_plots"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# ── Connect & load ─────────────────────────────────────────
con <- dbConnect(SQLite(), db_path)
df  <- dbReadTable(con, "investments") |> as_tibble()
dbDisconnect(con)

# Clean and filter
df_clean <- df |>
  mutate(
    amount = as.numeric(amount),
    year   = as.integer(year)
  ) |>
  filter(!is.na(amount), !is.na(sector), year >= 2005, year <= 2024)

# Identify top 15 sectors by total investment
top_15_sectors <- df_clean |>
  group_by(sector) |>
  summarise(total_all_time = sum(amount, na.rm = TRUE), .groups = "drop") |>
  slice_max(total_all_time, n = 15) |>
  pull(sector)

# Aggregate yearly by sector
sector_trends <- df_clean |>
  filter(sector %in% top_15_sectors) |>
  group_by(sector, year) |>
  summarise(yearly_total = sum(amount, na.rm = TRUE), .groups = "drop") |>
  # Ensure all years are present for each sector to avoid gaps in lines
  complete(sector, year = 2005:2024, fill = list(yearly_total = 0))

# ── Journal Theme ──────────────────────────────────────────
theme_journal <- theme_minimal(base_size = 12, base_family = "sans") +
  theme(
    panel.background = element_blank(),
    plot.background  = element_blank(),
    panel.grid.major = element_line(color = "#e5e7eb", linewidth = 0.2),
    panel.grid.minor = element_blank(),
    axis.line        = element_line(color = "#374151", linewidth = 0.4),
    axis.ticks       = element_line(color = "#374151", linewidth = 0.4),
    text             = element_text(color = "#111827"),
    axis.text        = element_text(size = 6, color = "#374151"),
    axis.title       = element_text(size = 8, face = "plain", color = "#111827"),
    plot.title       = element_text(size = 10, face = "bold", hjust = 0, margin = margin(b = 10)),
    strip.background = element_rect(fill = "#f3f4f6", color = NA),
    strip.text       = element_text(size = 7, face = "bold"),
    legend.position  = "none"
  )

double_col <- 7.48

# ── 1. Faceted Sector Trends ───────────────────────────────
p1 <- ggplot(sector_trends, aes(x = year, y = yearly_total)) +
  geom_area(fill = "#3b82f6", alpha = 0.1) +
  geom_line(color = "#1d4ed8", linewidth = 0.5) +
  facet_wrap(~ sector, scales = "free_y", ncol = 3) +
  scale_y_continuous(
    labels = function(x) paste0("$", comma(x / 1000), "B"),
    expand = expansion(mult = c(0, 0.1))
  ) +
  scale_x_continuous(breaks = c(2005, 2015, 2024)) +
  labs(
    title    = "Annual Chinese investment trends by top 15 sectors (2005-2024)",
    x = "Year",
    y = "Total investment (USD million)"
  ) +
  theme_journal

ggsave(file.path(output_dir, "sector_yearly_trends.png"), p1,
       width = double_col, height = 9, dpi = 300, bg = "white")

message("Sector trends analysis complete. Plot saved to: ", output_dir)
