# ============================================================
#  Southeast Asia Regional Analysis — Journal Quality
# ============================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(DBI)
  library(RSQLite)
  library(scales)
})

db_path <- "investments.db"
output_dir <- "static/se_asia"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# ── Connect & load ─────────────────────────────────────────
con <- dbConnect(SQLite(), db_path)
df  <- dbReadTable(con, "investments") |> as_tibble()
dbDisconnect(con)

# Filter for Southeast Asia
df_sea <- df |>
  filter(region == "Southeast Asia") |>
  mutate(
    amount = as.numeric(amount),
    year   = as.integer(year)
  ) |>
  filter(!is.na(amount), !is.na(sector), !is.na(country), !is.na(type))

if (nrow(df_sea) == 0) {
  message("No Southeast Asia data found in database. Exiting.")
  quit(status = 0)
}

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
    axis.text        = element_text(size = 7, color = "#374151"),
    axis.title       = element_text(size = 8, face = "plain", color = "#111827"),
    plot.title       = element_text(size = 10, face = "bold", hjust = 0, margin = margin(b = 10)),
    legend.position  = "bottom",
    legend.text      = element_text(size = 7),
    legend.title     = element_text(size = 7)
  )

single_col <- 4.5
double_col <- 8.5

# ── 1. Investment by Country (within SE Asia) ──────────────
country_sea <- df_sea |>
  group_by(country, type) |>
  summarise(total = sum(amount, na.rm = TRUE), .groups = "drop") |>
  group_by(country) |>
  mutate(grand_total = sum(total)) |>
  ungroup() |>
  mutate(country = fct_reorder(country, grand_total))

p1 <- ggplot(country_sea, aes(x = total, y = country, fill = type)) +
  geom_col(width = 0.75, color = "white", linewidth = 0.1) +
  scale_x_continuous(
    labels = function(x) paste0("$", comma(x / 1000), "B"),
    expand = expansion(mult = c(0, 0.15))
  ) +
  scale_fill_manual(values = c("Investment" = "#3b82f6", "Construction" = "#10b981")) +
  labs(
    title    = "Chinese activity in Southeast Asian countries",
    x = "Total value (USD million)",
    y = NULL,
    fill = "Activity Type"
  ) +
  theme_journal +
  theme(plot.margin = margin(10, 20, 10, 10))

ggsave(file.path(output_dir, "sea_country_investment.png"), p1,
       width = single_col, height = 5, dpi = 300, bg = "white")

# ── 2. Investment by Sector (within SE Asia) ───────────────
sector_sea <- df_sea |>
  group_by(sector, type) |>
  summarise(total = sum(amount, na.rm = TRUE), .groups = "drop") |>
  group_by(sector) |>
  mutate(grand_total = sum(total)) |>
  ungroup() |>
  mutate(sector = fct_reorder(sector, grand_total))

p2 <- ggplot(sector_sea, aes(x = total, y = sector, fill = type)) +
  geom_col(width = 0.75, color = "white", linewidth = 0.1) +
  scale_x_continuous(
    labels = function(x) paste0("$", comma(x / 1000), "B"),
    expand = expansion(mult = c(0, 0.15))
  ) +
  scale_fill_manual(values = c("Investment" = "#3b82f6", "Construction" = "#10b981")) +
  labs(
    title    = "Chinese activity in Southeast Asia by sector",
    x = "Total value (USD million)",
    y = NULL,
    fill = "Activity Type"
  ) +
  theme_journal +
  theme(plot.margin = margin(10, 20, 10, 10))

ggsave(file.path(output_dir, "sea_sector_investment.png"), p2,
       width = single_col, height = 5, dpi = 300, bg = "white")

# ── 3. Investment Trend (SE Asia) ──────────────────────────
trend_sea <- df_sea |>
  filter(year >= 2005, year <= 2024) |>
  group_by(year) |>
  summarise(total = sum(amount, na.rm = TRUE), .groups = "drop")

p3 <- ggplot(trend_sea, aes(x = year, y = total)) +
  geom_line(color = "#0891b2", linewidth = 0.8) +
  geom_point(color = "#0891b2", size = 1.2) +
  scale_y_continuous(
    labels = function(x) paste0("$", comma(x / 1000), "B"),
    expand = expansion(mult = c(0, 0.1))
  ) +
  scale_x_continuous(breaks = seq(2005, 2024, 2), expand = c(0, 0)) +
  labs(
    title    = "Annual Chinese investment trend in Southeast Asia",
    x = "Year",
    y = "Total investment (USD million)"
  ) +
  theme_journal

ggsave(file.path(output_dir, "sea_yearly_trend.png"), p3,
       width = double_col, height = 3.5, dpi = 300, bg = "white")

message("Southeast Asia analysis complete. Plots saved to: ", output_dir)
