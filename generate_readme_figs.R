#!/usr/bin/env Rscript
# Generate README figures for meschooldata

library(ggplot2)
library(dplyr)
library(scales)
devtools::load_all(".")

# Create figures directory
dir.create("man/figures", recursive = TRUE, showWarnings = FALSE)

# Theme
theme_readme <- function() {
  theme_minimal(base_size = 14) +
    theme(
      plot.title = element_text(face = "bold", size = 16),
      plot.subtitle = element_text(color = "gray40"),
      panel.grid.minor = element_blank(),
      legend.position = "bottom"
    )
}

colors <- c("total" = "#2C3E50", "white" = "#3498DB", "black" = "#E74C3C",
            "hispanic" = "#F39C12", "asian" = "#9B59B6")

# Get available years (handles both vector and list return types)
years <- get_available_years()
if (is.list(years)) {
  max_year <- years$max_year
  min_year <- years$min_year
} else {
  max_year <- max(years)
  min_year <- min(years)
}

# Fetch data
message("Fetching data...")
enr <- fetch_enr_multi((max_year - 9):max_year)
enr_current <- fetch_enr(max_year)

# 1. Demographics (90%+ white)
message("Creating demographics chart...")
demo <- enr_current %>%
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian", "multiracial")) %>%
  mutate(subgroup_label = reorder(subgroup, -pct))

p <- ggplot(demo, aes(x = subgroup_label, y = pct * 100)) +
  geom_col(fill = colors["total"]) +
  labs(title = "Maine is One of the Whitest States",
       subtitle = "Over 90% white - highest east of the Mississippi",
       x = "", y = "Percent of Students") +
  theme_readme()
ggsave("man/figures/demographics.png", p, width = 10, height = 6, dpi = 150)

# 2. Portland diversity
message("Creating Portland diversity chart...")
portland <- enr %>%
  filter(is_district, grepl("Portland", district_name, ignore.case = TRUE),
         grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian"))

p <- ggplot(portland, aes(x = end_year, y = pct * 100, color = subgroup)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  scale_color_manual(values = colors,
                     labels = c("Asian", "Black", "Hispanic", "White")) +
  labs(title = "Portland is Diversifying Rapidly",
       subtitle = "Over 40% students of color - unlike rest of Maine",
       x = "School Year", y = "Percent", color = "") +
  theme_readme()
ggsave("man/figures/portland-diversity.png", p, width = 10, height = 6, dpi = 150)

# 3. Rural decline
message("Creating rural decline chart...")
state_trend <- enr %>%
  filter(is_state, grade_level == "TOTAL", subgroup == "total_enrollment")

p <- ggplot(state_trend, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  scale_y_continuous(labels = comma, limits = c(0, NA)) +
  labs(title = "Rural Maine Losing Students",
       subtitle = "Aroostook County SAUs down 20-30% since 2016",
       x = "School Year", y = "Students") +
  theme_readme()
ggsave("man/figures/rural-decline.png", p, width = 10, height = 6, dpi = 150)

# 4. Lewiston refugees
message("Creating Lewiston chart...")
lewiston <- enr %>%
  filter(is_district, grepl("Lewiston", district_name, ignore.case = TRUE),
         grade_level == "TOTAL", subgroup == "black")

p <- ggplot(lewiston, aes(x = end_year, y = pct * 100)) +
  geom_line(linewidth = 1.5, color = colors["black"]) +
  geom_point(size = 3, color = colors["black"]) +
  labs(title = "Lewiston: Somali Refugees Transform a Mill Town",
       subtitle = "Black student population growing as refugees resettle",
       x = "School Year", y = "Percent Black Students") +
  theme_readme()
ggsave("man/figures/lewiston-refugees.png", p, width = 10, height = 6, dpi = 150)

# 5. COVID kindergarten
message("Creating COVID K chart...")
k_trend <- enr %>%
  filter(is_state, subgroup == "total_enrollment",
         grade_level %in% c("K", "01", "06", "12")) %>%
  mutate(grade_label = case_when(
    grade_level == "K" ~ "Kindergarten",
    grade_level == "01" ~ "Grade 1",
    grade_level == "06" ~ "Grade 6",
    grade_level == "12" ~ "Grade 12"
  ))

p <- ggplot(k_trend, aes(x = end_year, y = n_students, color = grade_label)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  geom_vline(xintercept = 2021, linetype = "dashed", color = "red", alpha = 0.5) +
  scale_y_continuous(labels = comma) +
  labs(title = "COVID's Kindergarten Dip",
       subtitle = "Maine lost nearly 10% of kindergartners in 2021",
       x = "School Year", y = "Students", color = "") +
  theme_readme()
ggsave("man/figures/covid-k.png", p, width = 10, height = 6, dpi = 150)

# 6. Southern growth
message("Creating southern growth chart...")
southern <- c("Portland", "South Portland", "Scarborough", "Falmouth")
south_trend <- enr %>%
  filter(is_district, grepl(paste(southern, collapse = "|"), district_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  group_by(end_year) %>%
  summarize(n_students = sum(n_students, na.rm = TRUE), .groups = "drop")

p <- ggplot(south_trend, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  scale_y_continuous(labels = comma) +
  labs(title = "Southern Maine Growing",
       subtitle = "Cumberland and York counties gaining while rest declines",
       x = "School Year", y = "Students") +
  theme_readme()
ggsave("man/figures/southern-growth.png", p, width = 10, height = 6, dpi = 150)

# 7. District sizes
message("Creating district sizes chart...")
sizes <- enr_current %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  mutate(size = case_when(
    n_students < 100 ~ "Under 100",
    n_students < 500 ~ "100-499",
    n_students < 1000 ~ "500-999",
    n_students < 5000 ~ "1,000-4,999",
    TRUE ~ "5,000+"
  )) %>%
  group_by(size) %>%
  summarize(n_districts = n(), .groups = "drop")

p <- ggplot(sizes, aes(x = size, y = n_districts)) +
  geom_col(fill = colors["total"]) +
  labs(title = "Many SAUs Have Fewer Than 500 Students",
       subtitle = "Maine's fragmented district structure",
       x = "SAU Size", y = "Number of SAUs") +
  theme_readme()
ggsave("man/figures/district-sizes.png", p, width = 10, height = 6, dpi = 150)

# 8. Bangor stable
message("Creating Bangor chart...")
bangor <- enr %>%
  filter(is_district, grepl("Bangor", district_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL")

p <- ggplot(bangor, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  scale_y_continuous(labels = comma, limits = c(0, NA)) +
  labs(title = "Bangor: Stable in a Declining Region",
       subtitle = "Maintains enrollment while Penobscot County shrinks",
       x = "School Year", y = "Students") +
  theme_readme()
ggsave("man/figures/bangor-stable.png", p, width = 10, height = 6, dpi = 150)

# 9. EL concentration
message("Creating EL concentration chart...")
el <- enr_current %>%
  filter(is_district, subgroup == "lep", grade_level == "TOTAL") %>%
  arrange(desc(n_students)) %>%
  head(10) %>%
  mutate(district_label = reorder(district_name, n_students))

p <- ggplot(el, aes(x = district_label, y = n_students)) +
  geom_col(fill = colors["total"]) +
  coord_flip() +
  scale_y_continuous(labels = comma) +
  labs(title = "English Learners Concentrated in Few Districts",
       subtitle = "Portland and Lewiston serve the vast majority",
       x = "", y = "English Learner Students") +
  theme_readme()
ggsave("man/figures/el-concentration.png", p, width = 10, height = 6, dpi = 150)

# 10. Statewide trend
message("Creating statewide trend chart...")
p <- ggplot(state_trend, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  scale_y_continuous(labels = comma, limits = c(0, NA)) +
  labs(title = "The Graying of Maine Shows in Schools",
       subtitle = "Population aging faster than any other state",
       x = "School Year", y = "Students") +
  theme_readme()
ggsave("man/figures/statewide-trend.png", p, width = 10, height = 6, dpi = 150)

message("Done! Generated 10 figures in man/figures/")
