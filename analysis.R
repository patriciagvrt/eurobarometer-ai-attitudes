# ==============================================================================
# Who Accepts AI at Work?
# Socioeconomic predictors of workplace AI attitudes in the European Union
#
# Author: Patricia Cruz
# MSc Computational Social Science, Linköping University
#
# Data: Special Eurobarometer 554 / Eurobarometer 101.4
# GESIS ZA8844
# ==============================================================================
#
# Main research question:
#
# Which socioeconomic and experiential factors are associated with
# positive perceptions of artificial intelligence in the workplace
# across the European Union?
#
# This is an observational, cross-sectional analysis.
# Results are interpreted as associations, not causal effects.
# ==============================================================================


# ------------------------------------------------------------------------------
# 1. SETUP
# ------------------------------------------------------------------------------

# Install once if necessary:
#
# install.packages(c(
#   "haven",
#   "labelled",
#   "tidyverse",
#   "survey",
#   "srvyr",
#   "scales"
# ))

library(haven)
library(labelled)
library(tidyverse)
library(survey)
library(srvyr)

theme_set(theme_minimal(base_size = 11))

dir.create("output/figures", recursive = TRUE, showWarnings = FALSE)
dir.create("output/tables", recursive = TRUE, showWarnings = FALSE)


# ------------------------------------------------------------------------------
# 2. LOAD DATA
# ------------------------------------------------------------------------------

raw <- read_sav("data/ZA8844_v1-0-0.sav")

cat(
  "Rows:", nrow(raw),
  "| Columns:", ncol(raw),
  "\n"
)


# ------------------------------------------------------------------------------
# 3. SELECT VARIABLES
# ------------------------------------------------------------------------------

df <- raw %>%
  select(
    # Geography and weights
    country = isocntry,
    w1,
    w1de,
    w22,
    
    # Main AI attitude outcome
    qb5,
    
    # AI attitudes / experience
    starts_with("qb6_"),
    starts_with("qb7_"),
    starts_with("qb2_"),
    qb4,
    
    # Socioeconomic variables
    edu_age = d8,
    gender = d10,
    age = d11,
    community = d25,
    bills = d60,
    soc_class = d63
  ) %>%
  mutate(
    across(
      -country,
      ~ as.numeric(zap_labels(.))
    )
  )


# ------------------------------------------------------------------------------
# 4. MISSING VALUES
# ------------------------------------------------------------------------------

# Verified coding from the Eurobarometer dataset:
#
# qb5:
# 1 Very positively
# 2 Fairly positively
# 3 Fairly negatively
# 4 Very negatively
# 5 Don't know
#
# qb2:
# 1 Totally agree
# 2 Tend to agree
# 3 Tend to disagree
# 4 Totally disagree
# 5 Not applicable
# 6 Don't know
#
# qb7:
# 1 Yes, all the time
# 2 Yes, often
# 3 No, rarely
# 4 No, never
# 5 Not applicable
# 6 Don't know
# 9 Inapplicable

df <- df %>%
  mutate(
    qb5 = na_if(qb5, 5),
    
    across(
      starts_with("qb6_"),
      ~ na_if(., 5)
    ),
    
    across(
      starts_with("qb2_"),
      ~ if_else(. %in% c(5, 6), NA_real_, .)
    ),
    
    across(
      starts_with("qb7_"),
      ~ if_else(. %in% c(5, 6, 9), NA_real_, .)
    ),
    
    qb4 = if_else(
      qb4 %in% c(5, 6, 9),
      NA_real_,
      qb4
    ),
    
    community = na_if(community, 8),
    
    bills = na_if(bills, 7),
    
    # GESIS collapsed categories 3 and 4 for gender.
    # For the present binary comparison, retain only codes 1 and 2.
    gender = if_else(
      gender %in% c(1, 2),
      gender,
      NA_real_
    ),
    
    soc_class = if_else(
      soc_class %in% c(6, 7, 8, 9),
      NA_real_,
      soc_class
    )
  )


# ------------------------------------------------------------------------------
# 5. DERIVED VARIABLES
# ------------------------------------------------------------------------------

df <- df %>%
  mutate(
    
    # --------------------------------------------------------------------------
    # Education
    # --------------------------------------------------------------------------
    
    edu_group = case_when(
      edu_age == 97 ~ "No full-time education",
      edu_age == 98 ~ "Still studying",
      edu_age >= 2 & edu_age <= 15 ~ "Low (up to 15)",
      edu_age >= 16 & edu_age <= 19 ~ "Medium (16-19)",
      edu_age >= 20 & edu_age <= 90 ~ "High (20+)",
      TRUE ~ NA_character_
    ),
    
    edu_group = factor(
      edu_group,
      levels = c(
        "Low (up to 15)",
        "Medium (16-19)",
        "High (20+)",
        "Still studying",
        "No full-time education"
      )
    ),
    
    # --------------------------------------------------------------------------
    # Financial precarity
    # --------------------------------------------------------------------------
    
    precarity = factor(
      case_when(
        bills == 1 ~ "Most of the time",
        bills == 2 ~ "From time to time",
        bills == 3 ~ "Almost never / never",
        TRUE ~ NA_character_
      ),
      levels = c(
        "Almost never / never",
        "From time to time",
        "Most of the time"
      )
    ),
    
    # --------------------------------------------------------------------------
    # Community
    # --------------------------------------------------------------------------
    
    community_f = factor(
      case_when(
        community == 1 ~ "Rural",
        community == 2 ~ "Small/medium town",
        community == 3 ~ "Large town",
        TRUE ~ NA_character_
      ),
      levels = c(
        "Rural",
        "Small/medium town",
        "Large town"
      )
    ),
    
    # --------------------------------------------------------------------------
    # Gender
    # --------------------------------------------------------------------------
    
    gender_f = factor(
      case_when(
        gender == 1 ~ "Man",
        gender == 2 ~ "Woman",
        TRUE ~ NA_character_
      ),
      levels = c("Man", "Woman")
    ),
    
    # --------------------------------------------------------------------------
    # Main outcome
    #
    # QB5:
    # 1 Very positively
    # 2 Fairly positively
    # 3 Fairly negatively
    # 4 Very negatively
    # --------------------------------------------------------------------------
    
    ai_positive = case_when(
      qb5 %in% c(1, 2) ~ 1,
      qb5 %in% c(3, 4) ~ 0,
      TRUE ~ NA_real_
    ),
    
    # --------------------------------------------------------------------------
    # Digital competence
    #
    # QB2_1 runs from:
    # 1 Totally agree
    # to
    # 4 Totally disagree
    #
    # Reverse so that larger values indicate greater perceived competence.
    # --------------------------------------------------------------------------
    
    digital_skill = 5 - qb2_1,
    
    # --------------------------------------------------------------------------
    # Country
    #
    # Merge East and West Germany for country-level comparison.
    # --------------------------------------------------------------------------
    
    country27 = if_else(
      country %in% c("DE-E", "DE-W"),
      "DE",
      country
    )
  )


# ------------------------------------------------------------------------------
# 6. AI EXPOSURE
# ------------------------------------------------------------------------------

# IMPORTANT:
#
# The old version classified respondents with all QB7 items missing as
# "not exposed".
#
# Here we distinguish:
#
# 0 = valid answers, no frequent AI exposure
# 1 = frequent exposure on at least one QB7 item
# NA = no valid QB7 information

qb7_vars <- names(df)[str_detect(names(df), "^qb7_")]

df <- df %>%
  mutate(
    
    qb7_nonmissing = rowSums(
      across(
        all_of(qb7_vars),
        ~ !is.na(.)
      )
    ),
    
    qb7_frequent_count = rowSums(
      across(
        all_of(qb7_vars),
        ~ . %in% c(1, 2)
      ),
      na.rm = TRUE
    ),
    
    ai_exposure = case_when(
      qb7_nonmissing == 0 ~ NA_real_,
      qb7_frequent_count > 0 ~ 1,
      qb7_frequent_count == 0 ~ 0,
      TRUE ~ NA_real_
    )
  )


# ------------------------------------------------------------------------------
# 7. COUNTRY WEIGHT
# ------------------------------------------------------------------------------

# W1 is appropriate for individual national samples.
#
# Germany is sampled separately as East and West Germany.
# W1DE adjusts these two samples to their population proportions
# when Germany is treated as one country.

df <- df %>%
  mutate(
    country_weight = case_when(
      country %in% c("DE-E", "DE-W") ~ w1de,
      TRUE ~ w1
    )
  )


# ------------------------------------------------------------------------------
# 8. BASIC CHECKS
# ------------------------------------------------------------------------------

cat("\n--- Education groups ---\n")
print(table(df$edu_group, useNA = "ifany"))

cat("\n--- Precarity ---\n")
print(table(df$precarity, useNA = "ifany"))

cat("\n--- Outcome ---\n")
print(table(df$ai_positive, useNA = "ifany"))

cat("\n--- AI exposure ---\n")
print(table(df$ai_exposure, useNA = "ifany"))

cat("\n--- Countries ---\n")
print(table(df$country27))


# ------------------------------------------------------------------------------
# 9. SURVEY DESIGNS
# ------------------------------------------------------------------------------

# EU27 pooled analysis

design_eu <- df %>%
  filter(!is.na(w22)) %>%
  as_survey_design(
    weights = w22
  )


# Country-level descriptive analysis

design_country <- df %>%
  filter(!is.na(country_weight)) %>%
  as_survey_design(
    weights = country_weight
  )


# ------------------------------------------------------------------------------
# 10. DESCRIPTIVE ANALYSIS
# ------------------------------------------------------------------------------

# Overall AI perception

desc_overall <- design_eu %>%
  filter(!is.na(qb5)) %>%
  group_by(qb5) %>%
  summarise(
    prop = survey_mean(
      vartype = "ci"
    )
  )

print(desc_overall)

write_csv(
  desc_overall,
  "output/tables/perception_overall.csv"
)


# AI perception by education

desc_edu <- design_eu %>%
  filter(
    !is.na(edu_group),
    !is.na(ai_positive)
  ) %>%
  group_by(edu_group) %>%
  summarise(
    prop_positive = survey_mean(
      ai_positive,
      vartype = "ci"
    ),
    n = unweighted(n())
  )

print(desc_edu)

write_csv(
  desc_edu,
  "output/tables/perception_by_education.csv"
)


# AI perception by financial precarity

desc_precarity <- design_eu %>%
  filter(
    !is.na(precarity),
    !is.na(ai_positive)
  ) %>%
  group_by(precarity) %>%
  summarise(
    prop_positive = survey_mean(
      ai_positive,
      vartype = "ci"
    ),
    n = unweighted(n())
  )

print(desc_precarity)

write_csv(
  desc_precarity,
  "output/tables/perception_by_precarity.csv"
)


# AI perception by country

desc_country <- design_country %>%
  filter(
    !is.na(ai_positive)
  ) %>%
  group_by(country27) %>%
  summarise(
    prop_positive = survey_mean(
      ai_positive,
      vartype = "ci"
    ),
    n = unweighted(n())
  ) %>%
  arrange(
    desc(prop_positive)
  )

print(desc_country, n = 30)

write_csv(
  desc_country,
  "output/tables/perception_by_country.csv"
)


# ------------------------------------------------------------------------------
# 11. VISUALISATIONS
# ------------------------------------------------------------------------------

# Education

p1 <- desc_edu %>%
  filter(
    edu_group %in% c(
      "Low (up to 15)",
      "Medium (16-19)",
      "High (20+)"
    )
  ) %>%
  ggplot(
    aes(
      x = edu_group,
      y = prop_positive
    )
  ) +
  geom_col(
    fill = "grey35",
    width = 0.6
  ) +
  geom_errorbar(
    aes(
      ymin = prop_positive_low,
      ymax = prop_positive_upp
    ),
    width = 0.12,
    colour = "grey15"
  ) +
  scale_y_continuous(
    labels = scales::percent_format(
      accuracy = 1
    ),
    limits = c(0, 0.85)
  ) +
  labs(
    title = "Positive perception of AI in the workplace, by education",
    subtitle = "Special Eurobarometer 554 (2024), EU27, survey-weighted",
    x = NULL,
    y = "Share with positive perception",
    caption = paste(
      "Education measured by age when full-time education ended.",
      "Error bars show 95% confidence intervals.",
      sep = "\n"
    )
  ) +
  theme(
    plot.title.position = "plot"
  )

ggsave(
  "output/figures/perception_by_education.png",
  p1,
  width = 7,
  height = 5,
  dpi = 300
)


# Financial precarity

p2 <- desc_precarity %>%
  ggplot(
    aes(
      x = precarity,
      y = prop_positive
    )
  ) +
  geom_col(
    fill = "grey35",
    width = 0.6
  ) +
  geom_errorbar(
    aes(
      ymin = prop_positive_low,
      ymax = prop_positive_upp
    ),
    width = 0.12,
    colour = "grey15"
  ) +
  scale_y_continuous(
    labels = scales::percent_format(
      accuracy = 1
    ),
    limits = c(0, 0.80)
  ) +
  labs(
    title = "Positive perception of AI, by financial precarity",
    subtitle = "Difficulty paying bills in the last year, EU27, survey-weighted",
    x = NULL,
    y = "Share with positive perception"
  ) +
  theme(
    plot.title.position = "plot"
  )

ggsave(
  "output/figures/perception_by_precarity.png",
  p2,
  width = 7,
  height = 5,
  dpi = 300
)


# Country

p3 <- desc_country %>%
  ggplot(
    aes(
      x = reorder(country27, prop_positive),
      y = prop_positive
    )
  ) +
  geom_point(
    size = 2,
    colour = "grey20"
  ) +
  geom_errorbar(
    aes(
      ymin = prop_positive_low,
      ymax = prop_positive_upp
    ),
    width = 0,
    colour = "grey55"
  ) +
  coord_flip() +
  scale_y_continuous(
    labels = scales::percent_format(
      accuracy = 1
    )
  ) +
  labs(
    title = "Positive perception of AI in the workplace, by country",
    subtitle = "Special Eurobarometer 554 (2024), EU27, survey-weighted",
    x = NULL,
    y = "Share with positive perception",
    caption = "Germany combines the East and West German samples using W1DE."
  ) +
  theme(
    plot.title.position = "plot"
  )

ggsave(
  "output/figures/perception_by_country.png",
  p3,
  width = 7,
  height = 8,
  dpi = 300
)


# ------------------------------------------------------------------------------
# 12. REGRESSION MODELS
# ------------------------------------------------------------------------------

# Model 1:
# demographic and socioeconomic predictors

model1 <- svyglm(
  ai_positive ~
    edu_group +
    age +
    gender_f +
    precarity +
    community_f,
  design = design_eu,
  family = quasibinomial()
)


# Model 2:
# add self-rated digital competence and workplace AI exposure

model2 <- svyglm(
  ai_positive ~
    edu_group +
    age +
    gender_f +
    precarity +
    community_f +
    digital_skill +
    ai_exposure,
  design = design_eu,
  family = quasibinomial()
)


# Model 3:
# main specification
#
# Adds country fixed effects so that individual-level associations
# are estimated after accounting for stable differences between countries.

model3 <- svyglm(
  ai_positive ~
    edu_group +
    age +
    gender_f +
    precarity +
    community_f +
    digital_skill +
    ai_exposure +
    factor(country27),
  design = design_eu,
  family = quasibinomial()
)


cat("\n--- MODEL 1 ---\n")
print(summary(model1))

cat("\n--- MODEL 2 ---\n")
print(summary(model2))

cat("\n--- MODEL 3 ---\n")
print(summary(model3))


# ------------------------------------------------------------------------------
# 13. ODDS-RATIO TABLES
# ------------------------------------------------------------------------------

make_or_table <- function(model, model_name) {
  
  beta <- coef(model)
  
  se <- sqrt(
    diag(vcov(model))
  )
  
  z <- qnorm(0.975)
  
  p_values <- coef(summary(model))[, 4]
  
  tibble(
    model = model_name,
    term = names(beta),
    estimate = beta,
    std_error = se,
    odds_ratio = exp(beta),
    ci_low = exp(beta - z * se),
    ci_high = exp(beta + z * se),
    p_value = p_values
  )
}


or_model1 <- make_or_table(
  model1,
  "Model 1"
)

or_model2 <- make_or_table(
  model2,
  "Model 2"
)

or_model3 <- make_or_table(
  model3,
  "Model 3"
)


write_csv(
  or_model1,
  "output/tables/model1_odds_ratios.csv"
)

write_csv(
  or_model2,
  "output/tables/model2_odds_ratios.csv"
)

write_csv(
  or_model3,
  "output/tables/model3_odds_ratios.csv"
)


# Main predictors only, easier to use in report

main_terms <- c(
  "edu_groupMedium (16-19)",
  "edu_groupHigh (20+)",
  "edu_groupStill studying",
  "edu_groupNo full-time education",
  "age",
  "gender_fWoman",
  "precarityFrom time to time",
  "precarityMost of the time",
  "community_fSmall/medium town",
  "community_fLarge town",
  "digital_skill",
  "ai_exposure"
)

model_comparison <- bind_rows(
  or_model1,
  or_model2,
  or_model3
) %>%
  filter(
    term %in% main_terms
  )

write_csv(
  model_comparison,
  "output/tables/model_comparison.csv"
)

print(model_comparison)


# ------------------------------------------------------------------------------
# 14. ROBUSTNESS CHECK 1
# UNWEIGHTED LOGISTIC REGRESSION
# ------------------------------------------------------------------------------

complete_model_df <- df %>%
  filter(
    !is.na(ai_positive),
    !is.na(edu_group),
    !is.na(age),
    !is.na(gender_f),
    !is.na(precarity),
    !is.na(community_f),
    !is.na(digital_skill),
    !is.na(ai_exposure),
    !is.na(country27)
  )


robust_unweighted <- glm(
  ai_positive ~
    edu_group +
    age +
    gender_f +
    precarity +
    community_f +
    digital_skill +
    ai_exposure +
    factor(country27),
  data = complete_model_df,
  family = binomial()
)

robust_unweighted_or <- make_or_table(
  robust_unweighted,
  "Unweighted robustness"
)

write_csv(
  robust_unweighted_or,
  "output/tables/robustness_unweighted.csv"
)


# ------------------------------------------------------------------------------
# 15. ROBUSTNESS CHECK 2
# EXCLUDE STUDENTS AND NO-FULL-TIME-EDUCATION GROUP
# ------------------------------------------------------------------------------

design_edu_restricted <- design_eu %>%
  filter(
    edu_group %in% c(
      "Low (up to 15)",
      "Medium (16-19)",
      "High (20+)"
    )
  )


robust_education <- svyglm(
  ai_positive ~
    edu_group +
    age +
    gender_f +
    precarity +
    community_f +
    digital_skill +
    ai_exposure +
    factor(country27),
  design = design_edu_restricted,
  family = quasibinomial()
)


robust_education_or <- make_or_table(
  robust_education,
  "Restricted education sample"
)

write_csv(
  robust_education_or,
  "output/tables/robustness_education_sample.csv"
)


# ------------------------------------------------------------------------------
# 16. SAMPLE SIZES
# ------------------------------------------------------------------------------

sample_sizes <- tibble(
  analysis = c(
    "Full dataset",
    "Valid AI outcome",
    "Model 3 complete cases",
    "Restricted education robustness"
  ),
  n = c(
    nrow(df),
    sum(!is.na(df$ai_positive)),
    nrow(complete_model_df),
    nrow(
      complete_model_df %>%
        filter(
          edu_group %in% c(
            "Low (up to 15)",
            "Medium (16-19)",
            "High (20+)"
          )
        )
    )
  )
)

write_csv(
  sample_sizes,
  "output/tables/sample_sizes.csv"
)

print(sample_sizes)


# ------------------------------------------------------------------------------
# 17. SESSION INFORMATION
# ------------------------------------------------------------------------------

writeLines(
  capture.output(
    sessionInfo()
  ),
  "output/session_info.txt"
)


# ==============================================================================
# END
# ==============================================================================