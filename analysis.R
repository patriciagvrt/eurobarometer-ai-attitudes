# ==============================================================================
# Socioeconomic Predictors of AI Attitudes in the EU
# Secondary analysis of Special Eurobarometer 554 (ZA8844)
#
# Author: Patricia Givort Cruz Cabral
# MSc Computational Social Science, Linköping University
#
# Data: GESIS ZA8844, DOI 10.4232/1.14471
# Not included in this repository. See data/README.md for download instructions.
# ==============================================================================


# ------------------------------------------------------------------------------
# 1. SETUP
# ------------------------------------------------------------------------------

# Install once if needed:
# install.packages(c("haven", "labelled", "tidyverse", "survey", "srvyr", "ggplot2"))

library(haven)      # reads SPSS .sav files, preserves labels
library(labelled)   # inspects and manipulates labelled variables
library(tidyverse)  # data manipulation and plotting
library(survey)     # survey-weighted estimation
library(srvyr)      # tidyverse-friendly wrapper for survey
library(ggplot2)

# Set a consistent theme for all plots
theme_set(theme_minimal(base_size = 11))

# Create output directories if they do not exist
dir.create("output/figures", recursive = TRUE, showWarnings = FALSE)
dir.create("output/tables", recursive = TRUE, showWarnings = FALSE)


# ------------------------------------------------------------------------------
# 2. LOAD DATA
# ------------------------------------------------------------------------------

# Update the filename to match your downloaded file
raw <- read_sav("data/ZA8844_v1-0-0.sav")

# Basic structure check
cat("Rows:", nrow(raw), "\n")
cat("Columns:", ncol(raw), "\n")

# Search for AI-related variables by their labels.
# The QB module is the AI content in this wave.
look_for(raw, "artificial")
look_for(raw, "robot")

# List all variables starting with qb (the AI module)
names(raw)[grepl("^qb", names(raw), ignore.case = TRUE)]

# Inspect one variable to see its value labels and coding
attributes(raw$qb5)


# ------------------------------------------------------------------------------
# 3. SELECT AND CLEAN VARIABLES
# ------------------------------------------------------------------------------

# IMPORTANT: verify the exact variable names and missing codes in the GESIS
# variable report before running this section. Codes differ by question.
# Notes on coding decisions are kept in docs/codebook_notes.md

df <- raw %>%
  select(
    # Identifiers and weights
    country   = isocntry,
    w1,                       # national weight, for country-level analysis

    # Dependent variables (AI attitudes)
    qb5,                      # overall perception of AI/robots at work
    starts_with("qb6_"),      # nine-item agreement battery
    starts_with("qb7_"),      # prior exposure to AI at work
    starts_with("qb8_"),      # perception of specific AI applications

    # Independent variables (demographics and socioeconomic position)
    edu_age   = d8,           # age when stopped full-time education
    age       = d11,
    gender    = d10,
    occupation = d15a,
    community = d25,          # urban / rural
    bills     = d60           # difficulty paying bills
  )

# --- Handle missing values ---------------------------------------------------
# Eurobarometer codes "don't know" and refusals as numeric values, not as NA.
# These must be recoded explicitly or they enter models as real data.
# Check each variable's codes in the variable report.

df <- df %>%
  mutate(
    # d8: 98 = refusal, 99 = don't know
    edu_age = if_else(edu_age %in% c(98, 99), NA_real_, as.numeric(edu_age)),

    # d60: 4 = refusal / don't know
    bills = if_else(bills == 4, NA_real_, as.numeric(bills)),

    # d25: 4 = don't know
    community = if_else(community == 4, NA_real_, as.numeric(community)),

    # qb5: verify the DK code in the variable report before setting this
    qb5 = as.numeric(qb5)
  )

# --- Derived variables -------------------------------------------------------

df <- df %>%
  mutate(
    # Education categories based on age leaving full-time education.
    # 0 = still studying is treated separately.
    edu_group = case_when(
      edu_age == 0            ~ "Still studying",
      edu_age > 0 & edu_age <= 15 ~ "Low (up to 15)",
      edu_age >= 16 & edu_age <= 19 ~ "Medium (16-19)",
      edu_age >= 20           ~ "High (20+)",
      TRUE                    ~ NA_character_
    ),
    edu_group = factor(edu_group,
                       levels = c("Low (up to 15)", "Medium (16-19)",
                                  "High (20+)", "Still studying")),

    # Financial precarity: struggling versus not
    precarity = case_when(
      bills == 1 ~ "Most of the time",
      bills == 2 ~ "From time to time",
      bills == 3 ~ "Almost never / never",
      TRUE       ~ NA_character_
    ),
    precarity = factor(precarity,
                       levels = c("Almost never / never",
                                  "From time to time",
                                  "Most of the time")),

    # Binary outcome: positive perception of AI at work
    # Verify the direction of the qb5 scale before using this
    ai_positive = if_else(qb5 <= 2, 1, 0)
  )

# Quick check of what survived cleaning
summary(df$edu_age)
table(df$edu_group, useNA = "ifany")
table(df$precarity, useNA = "ifany")


# ------------------------------------------------------------------------------
# 4. SURVEY DESIGN
# ------------------------------------------------------------------------------

# Eurobarometer requires weights. w1 is the national post-stratification weight.
# For pooled EU-level estimates, substitute the EU27 total weight.
# No PSU or strata identifiers are released, so this is a weights-only design.

design <- df %>%
  filter(!is.na(w1)) %>%
  as_survey_design(weights = w1)


# ------------------------------------------------------------------------------
# 5. DESCRIPTIVE ANALYSIS
# ------------------------------------------------------------------------------

# --- Overall distribution of AI perception -----------------------------------

desc_overall <- design %>%
  filter(!is.na(qb5)) %>%
  group_by(qb5) %>%
  summarise(prop = survey_mean(vartype = "ci"))

print(desc_overall)
write_csv(desc_overall, "output/tables/perception_overall.csv")

# --- AI perception by education group ----------------------------------------

desc_edu <- design %>%
  filter(!is.na(edu_group), !is.na(ai_positive)) %>%
  group_by(edu_group) %>%
  summarise(
    prop_positive = survey_mean(ai_positive, vartype = "ci"),
    n = unweighted(n())
  )

print(desc_edu)
write_csv(desc_edu, "output/tables/perception_by_education.csv")

# --- AI perception by financial precarity ------------------------------------

desc_precarity <- design %>%
  filter(!is.na(precarity), !is.na(ai_positive)) %>%
  group_by(precarity) %>%
  summarise(
    prop_positive = survey_mean(ai_positive, vartype = "ci"),
    n = unweighted(n())
  )

print(desc_precarity)
write_csv(desc_precarity, "output/tables/perception_by_precarity.csv")

# --- AI perception by country ------------------------------------------------

desc_country <- design %>%
  filter(!is.na(ai_positive)) %>%
  group_by(country) %>%
  summarise(
    prop_positive = survey_mean(ai_positive, vartype = "ci"),
    n = unweighted(n())
  ) %>%
  arrange(desc(prop_positive))

print(desc_country, n = 30)
write_csv(desc_country, "output/tables/perception_by_country.csv")


# ------------------------------------------------------------------------------
# 6. VISUALISATION
# ------------------------------------------------------------------------------

# --- Positive perception by education ----------------------------------------

p1 <- desc_edu %>%
  filter(!is.na(edu_group)) %>%
  ggplot(aes(x = edu_group, y = prop_positive)) +
  geom_col(fill = "grey30", width = 0.6) +
  geom_errorbar(aes(ymin = prop_positive_low, ymax = prop_positive_upp),
                width = 0.15, colour = "grey10") +
  scale_y_continuous(labels = scales::percent_format()) +
  labs(
    title = "Positive perception of AI in the workplace, by education",
    subtitle = "Special Eurobarometer 554 (2024), EU27, survey-weighted",
    x = NULL,
    y = "Share with positive perception",
    caption = "Error bars show 95% confidence intervals"
  ) +
  theme(plot.title.position = "plot")

print(p1)
ggsave("output/figures/perception_by_education.png", p1,
       width = 7, height = 5, dpi = 300)

# --- Positive perception by country ------------------------------------------

p2 <- desc_country %>%
  ggplot(aes(x = reorder(country, prop_positive), y = prop_positive)) +
  geom_point(size = 2, colour = "grey20") +
  geom_errorbar(aes(ymin = prop_positive_low, ymax = prop_positive_upp),
                width = 0, colour = "grey50") +
  coord_flip() +
  scale_y_continuous(labels = scales::percent_format()) +
  labs(
    title = "Positive perception of AI in the workplace, by country",
    subtitle = "Special Eurobarometer 554 (2024), survey-weighted",
    x = NULL,
    y = "Share with positive perception"
  ) +
  theme(plot.title.position = "plot")

print(p2)
ggsave("output/figures/perception_by_country.png", p2,
       width = 7, height = 8, dpi = 300)


# ------------------------------------------------------------------------------
# 7. REGRESSION
# ------------------------------------------------------------------------------

# Weighted logistic regression predicting positive perception of workplace AI.
# quasibinomial is used because survey weights produce non-integer counts.

model1 <- svyglm(
  ai_positive ~ edu_group + age + factor(gender) + precarity + factor(community),
  design = design,
  family = quasibinomial()
)

summary(model1)

# Odds ratios with confidence intervals
or_table <- tibble(
  term = names(coef(model1)),
  odds_ratio = exp(coef(model1)),
  ci_low  = exp(confint(model1)[, 1]),
  ci_high = exp(confint(model1)[, 2]),
  p_value = summary(model1)$coefficients[, 4]
)

print(or_table)
write_csv(or_table, "output/tables/regression_odds_ratios.csv")


# ------------------------------------------------------------------------------
# 8. SESSION INFO
# ------------------------------------------------------------------------------

# Recorded for reproducibility
writeLines(capture.output(sessionInfo()), "output/session_info.txt")

# ==============================================================================
# End of script
# ==============================================================================
