# ============================================================
#  China Global Investment Tracker — R Analysis (tidyverse)
#  Reads from investments.db and writes PNG plots to static/
# ============================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(DBI)
  library(RSQLite)
  library(scales)
})

# ── Helpers ────────────────────────────────────────────────
db_path <- commandArgs(trailingOnly = TRUE)
if (length(db_path) == 0) db_path <- "investments.db"

output_dir <- "static/r_plots"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# ── Connect & load ─────────────────────────────────────────
con <- dbConnect(SQLite(), db_path)
df  <- dbReadTable(con, "investments") |> as_tibble()
dbDisconnect(con)

if (nrow(df) == 0) {
  message("No data found in database. Exiting.")
  quit(status = 0)
}

# Clean up
df <- df |>
  mutate(
    amount = as.numeric(amount),
    year   = as.integer(year)
  ) |>
  filter(!is.na(amount), !is.na(sector), !is.na(country))

# ── Theme ──────────────────────────────────────────────────
theme_journal <- theme_minimal(base_size = 12, base_family = "sans") +
  theme(
    panel.background = element_blank(),
    plot.background  = element_blank(),
    panel.grid.major = element_line(color = "#e5e7eb", linewidth = 0.2),
    panel.grid.minor = element_blank(),
    axis.line        = element_line(color = "#374151", linewidth = 0.4),
    axis.ticks       = element_line(color = "#374151", linewidth = 0.4),
    text             = element_text(color = "#111827"),
    axis.text        = element_text(size = 7, color = "#374151"),
    axis.title       = element_text(size = 8, face = "plain", color = "#111827"),
    plot.title       = element_text(size = 10, face = "bold", hjust = 0, margin = margin(b = 10)),
    plot.subtitle    = element_text(size = 7, color = "#4b5563", margin = margin(b = 10)),
    legend.position  = "bottom",
    legend.text      = element_text(size = 7),
    legend.title     = element_text(size = 7),
    strip.background = element_rect(fill = "#f3f4f6", color = NA),
    strip.text       = element_text(size = 8, face = "bold")
  )

# Elsevier standard widths (expanded slightly for digital clarity)
single_col <- 4.5
double_col <- 8.5

# ── 1. Investment by Sector ─────────────────────────────────
sector_summary <- df |>
  filter(!is.na(type)) |>
  group_by(sector, type) |>
  summarise(total = sum(amount, na.rm = TRUE), .groups = "drop") |>
  group_by(sector) |>
  mutate(grand_total = sum(total)) |>
  ungroup() |>
  arrange(desc(grand_total)) |>
  slice_max(grand_total, n = 30) |> 
  mutate(sector = fct_reorder(sector, grand_total))

p1 <- ggplot(sector_summary, aes(x = total, y = sector, fill = type)) +
  geom_col(width = 0.75, color = "white", linewidth = 0.1) +
  scale_x_continuous(
    labels = function(x) paste0("$", comma(x / 1000), "B"),
    expand = expansion(mult = c(0, 0.15))
  ) +
  scale_fill_manual(values = c("Investment" = "#3b82f6", "Construction" = "#10b981")) +
  labs(
    title    = "Chinese investment and construction by sector",
    x = "Total value (USD million)",
    y = NULL,
    fill = "Activity Type"
  ) +
  theme_journal +
  theme(plot.margin = margin(10, 20, 10, 10))

ggsave(file.path(output_dir, "sector_investment.png"), p1,
       width = single_col, height = 6, dpi = 300, bg = "white")

# ── 2. Investment by Region ──────────────────────────────────
region_summary <- df |>
  filter(!is.na(region), region != "", !is.na(type)) |>
  group_by(region, type) |>
  summarise(total = sum(amount, na.rm = TRUE), .groups = "drop") |>
  group_by(region) |>
  mutate(grand_total = sum(total)) |>
  ungroup() |>
  mutate(region = fct_reorder(region, grand_total))

p2 <- ggplot(region_summary, aes(x = total, y = region, fill = type)) +
  geom_col(width = 0.75, color = "white", linewidth = 0.1) +
  scale_x_continuous(
    labels = function(x) paste0("$", comma(x / 1000), "B"),
    expand = expansion(mult = c(0, 0.15))
  ) +
  scale_fill_manual(values = c("Investment" = "#3b82f6", "Construction" = "#10b981")) +
  labs(
    title    = "Activity by geographic region",
    x = "Total value (USD million)",
    y = NULL,
    fill = "Activity Type"
  ) +
  theme_journal +
  theme(plot.margin = margin(10, 20, 10, 10))

ggsave(file.path(output_dir, "region_investment.png"), p2,
       width = single_col, height = 5, dpi = 300, bg = "white")

# ── 3. Top 15 Destination Countries ────────────────────────
country_summary <- df |>
  filter(!is.na(type)) |>
  group_by(country, type) |>
  summarise(total = sum(amount, na.rm = TRUE), .groups = "drop") |>
  group_by(country) |>
  mutate(grand_total = sum(total)) |>
  ungroup() |>
  slice_max(grand_total, n = 30) |> # Top 15 * 2
  mutate(country = fct_reorder(country, grand_total))

p3 <- ggplot(country_summary, aes(x = total, y = country, fill = type)) +
  geom_col(width = 0.75, color = "white", linewidth = 0.1) +
  scale_x_continuous(
    labels = function(x) paste0("$", comma(x / 1000), "B"),
    expand = expansion(mult = c(0, 0.15))
  ) +
  scale_fill_manual(values = c("Investment" = "#3b82f6", "Construction" = "#10b981")) +
  labs(
    title    = "Top 15 destination countries (Combined)",
    subtitle = "Distinguishing between ownership investments and construction contracts",
    x = "Total value (USD million)",
    y = NULL,
    fill = "Activity Type"
  ) +
  theme_journal +
  theme(plot.margin = margin(10, 20, 10, 10))

ggsave(file.path(output_dir, "country_investment.png"), p3,
       width = single_col, height = 6, dpi = 300, bg = "white")

# ── 4. Investment Trend Over Time ──────────────────────────
yearly <- df |>
  filter(!is.na(year), year >= 2005, year <= 2024) |>
  group_by(year) |>
  summarise(total = sum(amount, na.rm = TRUE), deals = n(), .groups = "drop")

p4 <- ggplot(yearly, aes(x = year)) +
  geom_line(aes(y = total), color = "#1d4ed8", linewidth = 0.8) +
  geom_point(aes(y = total), color = "#1d4ed8", size = 1.2) +
  scale_y_continuous(
    labels = function(x) paste0("$", comma(x / 1000), "B"),
    expand = expansion(mult = c(0, 0.1))
  ) +
  scale_x_continuous(breaks = seq(2005, 2024, 2), expand = c(0, 0)) +
  labs(
    title    = "Trend of annual Chinese outbound investment",
    x = "Year",
    y = "Total investment (USD million)"
  ) +
  theme_journal

ggsave(file.path(output_dir, "yearly_trend.png"), p4,
       width = double_col, height = 3.5, dpi = 300, bg = "white")

# ── 5. Yearly Trend by Activity Type (Amount) ──────────────
yearly_type_amount <- df |>
  filter(!is.na(year), year >= 2005, year <= 2024, !is.na(type)) |>
  group_by(year, type) |>
  summarise(total = sum(amount, na.rm = TRUE), .groups = "drop")

p5 <- ggplot(yearly_type_amount, aes(x = year, y = total, color = type, group = type)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.2) +
  scale_y_continuous(
    labels = function(x) paste0("$", comma(x / 1000), "B"),
    expand = expansion(mult = c(0, 0.1))
  ) +
  scale_x_continuous(breaks = seq(2005, 2024, 2), expand = c(0, 0)) +
  scale_color_manual(values = c("Investment" = "#3b82f6", "Construction" = "#10b981")) +
  labs(
    title    = "Yearly trend of investment and construction amount",
    subtitle = "Comparing total value by activity type (2005-2024)",
    x = "Year",
    y = "Total value (USD million)",
    color = "Activity Type"
  ) +
  theme_journal

ggsave(file.path(output_dir, "yearly_trend_amount_by_type.png"), p5,
       width = double_col, height = 4, dpi = 300, bg = "white")

# ── 6. Yearly Trend by Activity Type (Count) ───────────────
yearly_type_count <- df |>
  filter(!is.na(year), year >= 2005, year <= 2024, !is.na(type)) |>
  group_by(year, type) |>
  summarise(count = n(), .groups = "drop")

p6 <- ggplot(yearly_type_count, aes(x = year, y = count, color = type, group = type)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.2) +
  scale_y_continuous(
    labels = comma,
    expand = expansion(mult = c(0, 0.1))
  ) +
  scale_x_continuous(breaks = seq(2005, 2024, 2), expand = c(0, 0)) +
  scale_color_manual(values = c("Investment" = "#3b82f6", "Construction" = "#10b981")) +
  labs(
    title    = "Yearly trend of investment and construction projects",
    subtitle = "Comparing number of deals/projects by activity type (2005-2024)",
    x = "Year",
    y = "Number of projects",
    color = "Activity Type"
  ) +
  theme_journal

ggsave(file.path(output_dir, "yearly_trend_count_by_type.png"), p6,
       width = double_col, height = 4, dpi = 300, bg = "white")

# ── 7. Sector × Region Heatmap ─────────────────────────────
if ("region" %in% names(df) && !all(is.na(df$region))) {
  heat_data <- df |>
    filter(!is.na(region), region != "") |>
    group_by(sector, region) |>
    summarise(total = sum(amount, na.rm = TRUE), .groups = "drop") |>
    group_by(sector) |>
    filter(sum(total) > 0) |>
    ungroup()

  top_sectors <- heat_data |>
    group_by(sector) |>
    summarise(s = sum(total)) |>
    slice_max(s, n = 10) |>
    pull(sector)

  heat_data <- heat_data |> filter(sector %in% top_sectors)

  p7 <- ggplot(heat_data, aes(x = region, y = sector, fill = total)) +
    geom_tile(color = "white", linewidth = 0.2) +
    scale_fill_viridis_c(
      option = "inferno",
      labels = function(x) paste0("$", comma(x / 1000), "B"),
      name = "USD million"
    ) +
    scale_x_discrete(guide = guide_axis(angle = 45)) +
    labs(
      title    = "Distribution of investment by sector and region",
      x = "Region",
      y = "Sector"
    ) +
    theme_journal +
    theme(panel.grid = element_blank())

  ggsave(file.path(output_dir, "sector_region_heatmap.png"), p7,
         width = double_col, height = 4.5, dpi = 300, bg = "white")
}

message("R analysis complete. Plots saved to: ", output_dir)
