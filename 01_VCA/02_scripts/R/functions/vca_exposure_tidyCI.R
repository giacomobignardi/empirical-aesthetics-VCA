#Author: Giacomo Bignardi
#Date: 2023-05-02
#Adapted from Sutherland, Burton et al, 2020, PNAS;
#Function to tidy Variance Component with 95% CI output from the VCA function 
#input:bootVCA
VCA_exposure_tidyCI = function(bootVCA, MLM, variable = NA) {
VCAsummary =
  data.frame(
    Domain = rep(variable,18),
    Component = c( "Stimulus", "Individual", "Exposure", "Stimulus*Individual", "Exposure*Individual", "Stimulus*Exposure", "Residual",
                   "Stimulus_rep", "Individual_rep", "Exposure_rep", "Stimulus*Individual_rep", "Exposure*Individual_rep", "Stimulus*Exposure_rep",
                   "Repeatable", 
                   "Unique","Unique_rep",
                   "Shared", "Shared_rep"),
    Value = VCA_exposure(MLM),
    CI_low = c(
      as.numeric(quantile(bootVCA$t[,1], c(0.025, 0.975)))[1],
      as.numeric(quantile(bootVCA$t[,2], c(0.025, 0.975)))[1],
      as.numeric(quantile(bootVCA$t[,3], c(0.025, 0.975)))[1],
      as.numeric(quantile(bootVCA$t[,4], c(0.025, 0.975)))[1],
      as.numeric(quantile(bootVCA$t[,5], c(0.025, 0.975)))[1],
      as.numeric(quantile(bootVCA$t[,6], c(0.025, 0.975)))[1],
      as.numeric(quantile(bootVCA$t[,7], c(0.025, 0.975)))[1],
      as.numeric(quantile(bootVCA$t[,8], c(0.025, 0.975)))[1],
      as.numeric(quantile(bootVCA$t[,9], c(0.025, 0.975)))[1],
      as.numeric(quantile(bootVCA$t[,10], c(0.025, 0.975)))[1],
      as.numeric(quantile(bootVCA$t[,11], c(0.025, 0.975)))[1],
      as.numeric(quantile(bootVCA$t[,12], c(0.025, 0.975)))[1],
      as.numeric(quantile(bootVCA$t[,13], c(0.025, 0.975)))[1],
      as.numeric(quantile(bootVCA$t[,14], c(0.025, 0.975)))[1],
      as.numeric(quantile(bootVCA$t[,15], c(0.025, 0.975)))[1],
      as.numeric(quantile(bootVCA$t[,16], c(0.025, 0.975)))[1],
      as.numeric(quantile(bootVCA$t[,17], c(0.025, 0.975)))[1],
      as.numeric(quantile(bootVCA$t[,18], c(0.025, 0.975)))[1]
    ),
    CI_high = c(
      as.numeric(quantile(bootVCA$t[,1], c(0.025, 0.975)))[2],
      as.numeric(quantile(bootVCA$t[,2], c(0.025, 0.975)))[2],
      as.numeric(quantile(bootVCA$t[,3], c(0.025, 0.975)))[2],
      as.numeric(quantile(bootVCA$t[,4], c(0.025, 0.975)))[2],
      as.numeric(quantile(bootVCA$t[,5], c(0.025, 0.975)))[2],
      as.numeric(quantile(bootVCA$t[,6], c(0.025, 0.975)))[2],
      as.numeric(quantile(bootVCA$t[,7], c(0.025, 0.975)))[2],
      as.numeric(quantile(bootVCA$t[,8], c(0.025, 0.975)))[2],
      as.numeric(quantile(bootVCA$t[,9], c(0.025, 0.975)))[2],
      as.numeric(quantile(bootVCA$t[,10], c(0.025, 0.975)))[2],
      as.numeric(quantile(bootVCA$t[,11], c(0.025, 0.975)))[2],
      as.numeric(quantile(bootVCA$t[,12], c(0.025, 0.975)))[2],
      as.numeric(quantile(bootVCA$t[,13], c(0.025, 0.975)))[2],
      as.numeric(quantile(bootVCA$t[,14], c(0.025, 0.975)))[2],
      as.numeric(quantile(bootVCA$t[,15], c(0.025, 0.975)))[2],
      as.numeric(quantile(bootVCA$t[,16], c(0.025, 0.975)))[2],
      as.numeric(quantile(bootVCA$t[,17], c(0.025, 0.975)))[2],
      as.numeric(quantile(bootVCA$t[,18], c(0.025, 0.975)))[2]
    )
  )
}