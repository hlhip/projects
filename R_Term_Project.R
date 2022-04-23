rm(list=ls())
library(datasets)
library(tidyverse)
library(skimr)
library(GGally)

wb_countries <- LifeCycleSavings %>%
  bind_rows(LifeCycleSavings)

# Question 1
skim(wb_countries)

# Question 3
wb_countries <- wb_countries %>%
  mutate(sav_ratio = sr / dpi)
skim(wb_countries$sav_ratio)

# Question 4
ggpairs(wb_countries)

# Question 5A
ggplot(wb_countries, aes(y = sav_ratio, x = 1)) + geom_boxplot() + theme_minimal()

# Question 5C (not necessary)
highsav <- boxplot.stats(wb_countries$sav_ratio)$out
country <- which(wb_countries$sav_ratio %in% c(highsav))
length(country)

# Question 6
sav_ratio_mean <- mean(wb_countries$sav_ratio)
wb_countries <- wb_countries %>%
  mutate(strategy = ifelse(sav_ratio > sav_ratio_mean, "EXPAND", "HOLD"))
rm(sav_ratio_mean)

# Question 7
# not normal
shapiro.test(wb_countries$sav_ratio)
shapiro.test(wb_countries$sav_ratio[wb_countries$strategy == "EXPAND"])
shapiro.test(wb_countries$sav_ratio[wb_countries$strategy == "HOLD"])
# variances aren't equal
ansari.test(sav_ratio ~ strategy, wb_countries)
t.test(sav_ratio ~ strategy, data = wb_countries, var.equal = FALSE)

# Question 8
numeric_to_percentage <- function(x) {
  paste0(x * 100, "%")
}
ggplot(wb_countries, aes(x = sav_ratio, y = strategy)) + 
  geom_violin(fill = "blue") +
  labs(title = "Savings ratio distribution by country strategy", x = "Savings ratio", y = NULL) +
  scale_x_continuous(labels = numeric_to_percentage) +
  theme_minimal()
