library(tidyverse)
library(DBI)
library(RSQLite)
library(gridExtra)
library(grid)

# ── Setup ──────────────────────────────────────────────────
db_path <- "investments.db"
output_dir <- "static/r_plots"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# ── Connect & Load ─────────────────────────────────────────
con <- dbConnect(SQLite(), db_path)
df  <- dbReadTable(con, "investments") |> as_tibble()
dbDisconnect(con)

# ── Table 1: Top 10 Countries ──────────────────────────────
table_country <- df |>
  count(country, sort = TRUE) |>
  head(10) |>
  rename(Country = country, `Project Count` = n)

# ── Table 2: Activity by Region ────────────────────────────
table_region <- df |>
  count(region, sort = TRUE) |>
  rename(Region = region, `Project Count` = n)

# ── Table 3: Regional Composition ──────────────────────────
table_composition <- df |>
  group_by(region) |>
  summarise(
    Projects = n(),
    Countries = n_distinct(country),
    `Top Contributor` = country[which.max(table(country))],
    .groups = "drop"
  ) |>
  arrange(desc(Projects)) |>
  rename(Region = region)

# ── Helper: Save Table to PNG ─────────────────────────────
save_table_png <- function(tbl, filename, title) {
  # Set theme
  tt <- ttheme_minimal(
    base_size = 10,
    core = list(fg_params = list(hjust = 0, x = 0.1),
                bg_params = list(fill = c("#f9fafb", "#ffffff"), col = "white")),
    colhead = list(fg_params = list(col = "white", fontface = "bold"),
                   bg_params = list(fill = "#374151"))
  )
  
  # Create table grob
  tg <- tableGrob(tbl, theme = tt, rows = NULL)
  
  # Add title
  title_grob <- textGrob(title, gp = gpar(fontsize = 12, fontface = "bold"))
  
  # Combine
  padding <- unit(5, "mm")
  full_grob <- gtable::gtable_add_rows(tg, heights = grobHeight(title_grob) + padding, pos = 0)
  full_grob <- gtable::gtable_add_grob(full_grob, title_grob, t = 1, l = 1, r = ncol(full_grob))
  
  # Save
  # Estimate dimensions
  w <- convertWidth(sum(tg$widths), "in", valueOnly = TRUE) + 0.5
  h <- convertHeight(sum(tg$heights) + grobHeight(title_grob) + padding, "in", valueOnly = TRUE) + 0.5
  
  png(file.path(output_dir, filename), width = w, height = h, units = "in", res = 300, bg = "white")
  grid.draw(full_grob)
  dev.off()
  
  message("Saved: ", filename)
}

# ── Generate ───────────────────────────────────────────────
save_table_png(table_country, "table_top_10_countries.png", "Top 10 Destination Countries (Frequency)")
save_table_png(table_region, "table_activity_by_region.png", "Project Activity by Region (Frequency)")
save_table_png(table_composition, "table_regional_composition.png", "Regional Composition and Diversification")

message("Table PNG generation complete.")
