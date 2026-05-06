# ===============================================================
# Program name: Estimates for death-14 days grace period GH
# Primary programmer: Marzan Khan
# Last updated: May 6, 2026
# IPTW-weighted and unweighted rate ratios and rate differences
# with 1000 bootstrap replicates for death outcome with 14
# days grace period
# ===============================================================

library(WeightIt)
library(haven)
data<-read_sas("Your path")

# ---------------------------------------------------------
# USER INPUTS
# ---------------------------------------------------------

# Dataset name
# Assumes:
#   exposure = 0/1 treatment
#   outcome  = event count (often 0/1)
#   ptime    = person-time
#
# Replace with your actual dataset name
dat <- data

# Propensity score model for IPTW
ps_formula <- exposure ~ age + SEX_IDENT_CD + nh_time_total

# Number of bootstrap replicates
B <- 1000
set.seed(123)

# ---------------------------------------------------------
# FUNCTION: UNWEIGHTED RATES
# ---------------------------------------------------------

estimate_unweighted_rates <- function(d,
                                      exposure_var = "exposure",
                                      outcome_var = "death_14",
                                      ptime_var = "days_at_risk_14") {
  
  a <- d[[exposure_var]]
  y <- d[[outcome_var]]
  t <- d[[ptime_var]]
  
  if (any(is.na(a) | is.na(y) | is.na(t))) {
    stop("Missing values detected in exposure, outcome, or person-time.")
  }
  
  rate0 <- sum(y[a == 0], na.rm = TRUE) / sum(t[a == 0], na.rm = TRUE)
  rate1 <- sum(y[a == 1], na.rm = TRUE) / sum(t[a == 1], na.rm = TRUE)
  
  rr <- rate1 / rate0
  rd <- rate1 - rate0
  
  c(rate0 = rate0, rate1 = rate1, RR = rr, RD = rd)
}

# ---------------------------------------------------------
# FUNCTION: WEIGHTED RATES USING STABILIZED IPTW
# Re-estimates weights within each bootstrap sample
# ---------------------------------------------------------

estimate_weighted_rates <- function(d,
                                    ps_formula,
                                    exposure_var = "exposure",
                                    outcome_var = "death_14",
                                    ptime_var = "days_at_risk_14") {
  
  W <- weightit(
    formula   = ps_formula,
    data      = d,
    method    = "glm",
    estimand  = "ATE",
    stabilize = TRUE
  )
  
  w <- W$weights
  a <- d[[exposure_var]]
  y <- d[[outcome_var]]
  t <- d[[ptime_var]]
  
  rate0 <- sum(w[a == 0] * y[a == 0], na.rm = TRUE) /
    sum(w[a == 0] * t[a == 0], na.rm = TRUE)
  
  rate1 <- sum(w[a == 1] * y[a == 1], na.rm = TRUE) /
    sum(w[a == 1] * t[a == 1], na.rm = TRUE)
  
  rr <- rate1 / rate0
  rd <- rate1 - rate0
  
  c(rate0 = rate0, rate1 = rate1, RR = rr, RD = rd)
}

# ---------------------------------------------------------
# FUNCTION: BOOTSTRAP
# ---------------------------------------------------------

bootstrap_rates <- function(data, est_fun, B = 1000, seed = 123, ...) {
  set.seed(seed)
  
  n <- nrow(data)
  out <- matrix(NA_real_, nrow = B, ncol = 4)
  colnames(out) <- c("rate0", "rate1", "RR", "RD")
  
  for (b in 1:B) {
    idx <- sample(seq_len(n), size = n, replace = TRUE)
    d_b <- data[idx, , drop = FALSE]
    
    est <- tryCatch(
      est_fun(d_b, ...),
      error = function(e) {
        message("Bootstrap failure in replicate ", b, ": ", e$message)
        rep(NA_real_, 4)
      }
    )
    
    out[b, ] <- est
  }
  
  out <- as.data.frame(out)
  
  message("Number of failed bootstrap replicates: ", sum(!complete.cases(out)))
  
  ci <- rbind(
    rate0 = quantile(out$rate0, probs = c(0.025, 0.975), na.rm = TRUE),
    rate1 = quantile(out$rate1, probs = c(0.025, 0.975), na.rm = TRUE),
    RR    = quantile(out$RR,    probs = c(0.025, 0.975), na.rm = TRUE),
    RD    = quantile(out$RD,    probs = c(0.025, 0.975), na.rm = TRUE)
  )
  
  list(
    boot_estimates = out,
    ci = ci
  )
}

# ---------------------------------------------------------
# POINT ESTIMATES
# ---------------------------------------------------------

unweighted_est <- estimate_unweighted_rates(dat)
weighted_est   <- estimate_weighted_rates(dat, ps_formula = ps_formula)

# ---------------------------------------------------------
# BOOTSTRAP CONFIDENCE INTERVALS
# ---------------------------------------------------------

boot_unweighted <- bootstrap_rates(
  data = dat,
  est_fun = estimate_unweighted_rates,
  B = B,
  seed = 123
)

boot_weighted <- bootstrap_rates(
  data = dat,
  est_fun = estimate_weighted_rates,
  B = B,
  seed = 123,
  ps_formula = ps_formula
)

# ---------------------------------------------------------
# FINAL RESULTS TABLE
# Rates and RDs are in original person-time units
# ---------------------------------------------------------

results <- data.frame(
  Analysis = c("Unweighted", "Weighted IPTW"),
  rate0 = c(unweighted_est["rate0"], weighted_est["rate0"]),
  rate1 = c(unweighted_est["rate1"], weighted_est["rate1"]),
  RR = c(unweighted_est["RR"], weighted_est["RR"]),
  RR_LCL = c(boot_unweighted$ci["RR", 1], boot_weighted$ci["RR", 1]),
  RR_UCL = c(boot_unweighted$ci["RR", 2], boot_weighted$ci["RR", 2]),
  RD = c(unweighted_est["RD"], weighted_est["RD"]),
  RD_LCL = c(boot_unweighted$ci["RD", 1], boot_weighted$ci["RD", 1]),
  RD_UCL = c(boot_unweighted$ci["RD", 2], boot_weighted$ci["RD", 2])
)

print(results)

# ---------------------------------------------------------
# OPTIONAL: EXPRESS RATES AND RDs PER 1000 PERSON-DAYS
# ---------------------------------------------------------

results_per1000 <- results
results_per1000$rate0  <- round(results_per1000$rate0 * 1000, 2)
results_per1000$rate1  <- round(results_per1000$rate1 * 1000, 2)
results_per1000$RD     <- round(results_per1000$RD * 1000, 2)
results_per1000$RD_LCL <- round(results_per1000$RD_LCL * 1000, 2)
results_per1000$RD_UCL <- round(results_per1000$RD_UCL * 1000, 2)
results_per1000$RR     <- round(results_per1000$RR , 2)
results_per1000$RR_LCL <- round(results_per1000$RR_LCL, 2)
results_per1000$RR_UCL <- round(results_per1000$RR_UCL , 2)

#save the dataset
write.csv(results_per1000, "Your path", row.names=FALSE)


      