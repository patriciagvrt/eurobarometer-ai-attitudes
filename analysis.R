# ==============================================================================
# Socioeconomic Predictors of AI Attitudes in the Workplace
# Secondary analysis of Special Eurobarometer 554 / Eurobarometer 101.4
#
# Author: Patricia Givort Cruz Cabral
# MSc Computational Social Science, Linköping University
#
# Data: GESIS ZA8844, DOI 10.4232/1.14471
#       26,404 respondents, EU27, fieldwork 25 April - 22 May 2024
#       Not included in this repository. See data/README.md.
#
# All variable names and value codes below were verified directly against
# the .sav file metadata. Codes are documented in docs/codebook_notes.md.
# ==============================================================================


# ------------------------------------------------------------------------------
# 1. SETUP
# ------------------------------------------------------------------------------

# install.packages(c("haven", "labelled", "tidyverse", "survey", "srvyr", "scales"))

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

cat("Rows:", nrow(raw), "| Columns:", ncol(raw), "\n")
# Expected: 26404 rows, 349 columns

# The AI module is QB. To list its variables:
# names(raw)[grepl("^qb", names(raw))]

# To inspect any variable's value labels:
# val_labels(raw$qb5)


# ------------------------------------------------------------------------------
# 3. SELECT AND CLEAN
# ------------------------------------------------------------------------------

# Verified value codes:
#
#   qb5   1 Very positively / 2 Fairly positively / 3 Fairly negatively /
#         4 Very negatively / 5 Don't know
#   qb6_* 1 Totally agree / 2 Tend to agree / 3 Tend to disagree /
#         4 Totally disagree / 5 Don't know
#   qb2_* 1 Totally agree ... 4 Totally disagree / 5 Not applicable / 6 DK
#   qb7_* 1 Yes all the time / 2 Yes often / 3 No rarely / 4 No never /
#         5 Not applicable / 6 DK / 9 Inapplicable
#   d8    0 Refusal / 2-90 age / 97 No full-time education /
#         98 Still studying / 99 DK
#   d10   1 Man / 2 Woman / 3 Non-binary or prefer not to say
#   d25   1 Rural / 2 Small-medium town / 3 Large town / 8 DK
#   d60   1 Most of the time / 2 From time to time / 3 Almost never / 7 Refusal
#   d63   1 Working / 2 Lower middle / 3 Middle / 4 Upper middle /
#         5 Higher / 6 Other / 7 None / 8 Refusal / 9 DK

df <- raw %>%
  select(
    country = isocntry,
    w1, w22,
    qb5,
    starts_with("qb6_"),
    starts_with("qb7_"),
    starts_with("qb2_"),
    qb4,
    edu_age    = d8,
    gender     = d10,
    age        = d11,
    occupation = d15a,
    community  = d25,
    bills      = d60,
    soc_class  = d63
  ) %>%
  mutate(across(-country, ~ as.numeric(zap_labels(.))))

# --- Recode missing values ---------------------------------------------------
# Eurobarometer codes DK and refusals as substantive numbers. They must be
# set to NA or they enter the models as real responses.

df <- df %>%
  mutate(
    qb5   = na_if(qb5, 5),
    across(starts_with("qb6_"), ~ na_if(., 5)),
    across(starts_with("qb2_"), ~ if_else(. %in% c(5, 6), NA_real_, .)),
    across(starts_with("qb7_"), ~ if_else(. %in% c(5, 6, 9), NA_real_, .)),
    qb4       = if_else(qb4 %in% c(5, 6, 9), NA_real_, qb4),
    community = na_if(community, 8),
    bills     = na_if(bills, 7),
    gender    = na_if(gender, 3),
    soc_class = if_else(soc_class %in% c(6, 7, 8, 9), NA_real_, soc_class)
  )

# --- Derived variables -------------------------------------------------------

df <- df %>%
  mutate(
    edu_group = case_when(
      edu_age == 97                 ~ "No full-time education",
      edu_age == 98                 ~ "Still studying",
      edu_age >= 2  & edu_age <= 15 ~ "Low (up to 15)",
      edu_age >= 16 & edu_age <= 19 ~ "Medium (16-19)",
      edu_age >= 20 & edu_age <= 90 ~ "High (20+)",
      TRUE                          ~ NA_character_
    ),
    edu_group = factor(edu_group,
      levels = c("Low (up to 15)", "Medium (16-19)", "High (20+)",
                 "Still studying", "No full-time education")),

    precarity = factor(case_when(
      bills == 1 ~ "Most of the time",
      bills == 2 ~ "From time to time",
      bills == 3 ~ "Almost never / never",
      TRUE       ~ NA_character_
    ), levels = c("Almost never / never", "From time to time",
                  "Most of the time")),

    community_f = factor(case_when(
      community == 1 ~ "Rural",
      community == 2 ~ "Small/medium town",
      community == 3 ~ "Large town",
      TRUE           ~ NA_character_
    ), levels = c("Rural", "Small/medium town", "Large town")),

    gender_f = factor(if_else(gender == 1, "Man", "Woman")),

    # Outcome: qb5 runs 1 = very positively to 4 = very negatively,
    # so values 1 and 2 indicate a positive perception.
    ai_positive = if_else(qb5 <= 2, 1, 0),

    # Self-rated digital skill in daily life, reversed so higher = more skilled
    digital_skill = 5 - qb2_1,

    # Any workplace exposure to AI: "yes all the time" or "yes often"
    # on any of the six qb7 items
    ai_exposure = if_else(
      rowSums(across(starts_with("qb7_"), ~ . %in% c(1, 2)), na.rm = TRUE) > 0,
      1, 0
    )
  )

cat("\n--- Education groups ---\n"); print(table(df$edu_group, useNA = "ifany"))
cat("\n--- Precarity ---\n");        print(table(df$precarity, useNA = "ifany"))
cat("\n--- Outcome ---\n");          print(table(df$ai_positive, useNA = "ifany"))


# ------------------------------------------------------------------------------
# 4. SURVEY DESIGN
# ------------------------------------------------------------------------------

# w1  = national post-stratification weight, for country-level analysis
# w22 = EU27 weight, for pooled EU-level estimates
# No PSU or strata identifiers are released, so this is a weights-only design.

design_country <- df %>% filter(!is.na(w1))  %>% as_survey_design(weights = w1)
design_eu      <- df %>% filter(!is.na(w22)) %>% as_survey_design(weights = w22)


# ------------------------------------------------------------------------------
# 5. DESCRIPTIVE ANALYSIS
# ------------------------------------------------------------------------------

desc_overall <- design_eu %>%
  filter(!is.na(qb5)) %>%
  group_by(qb5) %>%
  summarise(prop = survey_mean(vartype = "ci"))

print(desc_overall)
write_csv(desc_overall, "output/tables/perception_overall.csv")

desc_edu <- design_eu %>%
  filter(!is.na(edu_group), !is.na(ai_positive)) %>%
  group_by(edu_group) %>%
  summarise(
    prop_positive = survey_mean(ai_positive, vartype = "ci"),
    n = unweighted(n())
  )

print(desc_edu)
write_csv(desc_edu, "output/tables/perception_by_education.csv")

desc_precarity <- design_eu %>%
  filter(!is.na(precarity), !is.na(ai_positive)) %>%
  group_by(precarity) %>%
  summarise(
    prop_positive = survey_mean(ai_positive, vartype = "ci"),
    n = unweighted(n())
  )

print(desc_precarity)
write_csv(desc_precarity, "output/tables/perception_by_precarity.csv")

desc_country <- design_country %>%
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

p1 <- desc_edu %>%
  filter(edu_group %in% c("Low (up to 15)", "Medium (16-19)", "High (20+)")) %>%
  ggplot(aes(x = edu_group, y = prop_positive)) +
  geom_col(fill = "grey35", width = 0.6) +
  geom_errorbar(aes(ymin = prop_positive_low, ymax = prop_positive_upp),
                width = 0.12, colour = "grey15") +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  labs(
    title = "Positive perception of AI in the workplace, by education",
    subtitle = "Special Eurobarometer 554 (2024), EU27, survey-weighted",
    x = NULL, y = "Share with positive perception",
    caption = "Education measured by age when full-time education ended.\nError bars show 95% confidence intervals."
  ) +
  theme(plot.title.position = "plot")

ggsave("output/figures/perception_by_education.png", p1,
       width = 7, height = 5, dpi = 300)

p2 <- desc_country %>%
  ggplot(aes(x = reorder(country, prop_positive), y = prop_positive)) +
  geom_point(size = 2, colour = "grey20") +
  geom_errorbar(aes(ymin = prop_positive_low, ymax = prop_positive_upp),
                width = 0, colour = "grey55") +
  coord_flip() +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  labs(
    title = "Positive perception of AI in the workplace, by country",
    subtitle = "Special Eurobarometer 554 (2024), survey-weighted",
    x = NULL, y = "Share with positive perception"
  ) +
  theme(plot.title.position = "plot")

ggsave("output/figures/perception_by_country.png", p2,
       width = 7, height = 8, dpi = 300)

p3 <- desc_precarity %>%
  ggplot(aes(x = precarity, y = prop_positive)) +
  geom_col(fill = "grey35", width = 0.6) +
  geom_errorbar(aes(ymin = prop_positive_low, ymax = prop_positive_upp),
                width = 0.12, colour = "grey15") +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  labs(
    title = "Positive perception of AI, by financial precarity",
    subtitle = "Difficulty paying bills in the last year. EU27, survey-weighted",
    x = NULL, y = "Share with positive perception"
  ) +
  theme(plot.title.position = "plot")

ggsave("output/figures/perception_by_precarity.png", p3,
       width = 7, height = 5, dpi = 300)


# ------------------------------------------------------------------------------
# 7. REGRESSION
# ------------------------------------------------------------------------------

# Weighted logistic regression. quasibinomial is used because survey weights
# produce non-integer counts, which binomial() rejects.

model1 <- svyglm(
  ai_positive ~ edu_group + age + gender_f + precarity + community_f,
  design = design_eu,
  family = quasibinomial()
)

summary(model1)

model2 <- svyglm(
  ai_positive ~ edu_group + age + gender_f + precarity + community_f +
                digital_skill + ai_exposure,
  design = design_eu,
  family = quasibinomial()
)

summary(model2)

or_table <- tibble(
  term       = names(coef(model2)),
  odds_ratio = exp(coef(model2)),
  ci_low     = exp(confint(model2)[, 1]),
  ci_high    = exp(confint(model2)[, 2]),
  p_value    = summary(model2)$coefficients[, 4]
)

print(or_table, n = 30)
write_csv(or_table, "output/tables/regression_odds_ratios.csv")


# ------------------------------------------------------------------------------
# 8. SESSION INFO
# ------------------------------------------------------------------------------

writeLines(capture.output(sessionInfo()), "output/session_info.txt")

# ==============================================================================
# End of script
# ==============================================================================
