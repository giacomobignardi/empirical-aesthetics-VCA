#Author: Giacomo Bignardi
#Adapted from: Vessel et al.(under review) https://psyarxiv.com/pnu3r/ 
#Date: 02-05-2023
#Description:
#Apply relative contribution to Variance Component Analysis (rcVCA) to get an approximate estimate of the amount of covariance between any given fixed effect IV an VPC
#Program: rcVCA ------------------------------------------------------------------------------------------------------------------------------
#load packages
library(tidyverse)
library(lme4)
library(tidylog)
library(readr)
library(patchwork) # this to make a easy grid

#clean working enviroment 
rm(list = ls())

#set Open Access working directories
wd = getwd()
wd_data = "01_data"
wd_Rfunction = "02_scripts/R/functions"
wd_output = "03_outputs"
wd_image = "04_images"

#load dataFrames:
AESR_data  = read_delim(sprintf("%s/%s/02_MLM_AE_SR_Vessel2023.csv", wd,wd_data))
#load functions:
source(sprintf("%s/%s/rcvca.R", wd,wd_Rfunction))

##MLM####
#define null model for "observational-variance"
mlm_AE_fit = lmer(AE ~  1+ ((1|Sub) + (1 |Obj) + (1|Sub:Obj)),data=AESR_data)
#Include fixed effects as predictors
mlm_AE_SR_fit = lmer(AE ~ SR  + ((1|Sub) + (1 |Obj) + (1|Sub:Obj)), data=AESR_data)

#estimate total variance from mlm
summary(mlm_AE_fit)$varcor %>% as.data.frame() %>% summarise(sum(vcov))
#observed variance
var(AESR_data$AE)
#overall variance of the random effects drop
summary(mlm_AE_SR_fit)$varcor %>% as.data.frame() %>% summarise(sum(vcov))

#rcVCA####
#Apply VCA functions to get rcVCP
#null model (aesthetic ratings)
vca_null = rcVCA(mlm_AE_fit) %>% mutate(model = "varparAE")
#model with additional fixed effect (self-relevance)
vca_sr = rcVCA(mlm_AE_SR_fit, null = F, nullmodel = mlm_AE_fit) %>% mutate(model = "varparAE_SR")

#rename for simplicity
colnames(vca_null)[2:4] = paste0(colnames(vca_null)[2:4], "_null")
colnames(vca_sr)[2:4] = paste0(colnames(vca_sr)[2:4], "_sr")
vca_comparison = list(vca_null,vca_sr) %>% reduce(inner_join, by='VPC')

#relative comparison
rcvca_comparison = 
  vca_comparison %>% mutate(null_m_SR = total_null-total_sr) %>%  # amount of random effects covarying with the fixed effect (SR)
  select(VPC, total_null,total_sr, null_m_SR) %>% 
  rename(null = total_null, SR = total_sr) %>% 
  pivot_longer(names_to = "model", values_to = "value", c(null:null_m_SR)) %>% 
  mutate(VPC = ifelse(model == "null_m_SR", paste0(VPC,"_SR"), VPC),
         lmm = ifelse(endsWith(model, 'SR'), "AE~SR", 
                      ifelse(grepl("null",model), "AE(null)", model)),
         value = ifelse(VPC == "Residual", NA,value))

#prepare for plotting
level_order = c(
"Residual",
"Stimulus",
"Stimulus_SR",
"Individual",
"Individual_SR",
"Stimulus*Individual",
"Stimulus*Individual_SR"
)
level_lmm = c(
  "AE(null)",
  "AE~SR"
)

#color for plotting
color_rcVCA = c(viridis::viridis(7))
color_rcVCA_explained = wesanderson::wes_palette("GrandBudapest2")

#Rename VPC for ease of plotting
#Final VPC
p1 = rcvca_comparison %>% 
  mutate(value = round(value,2)) %>% 
  filter(value >0) %>% 
  mutate(VPC = factor(VPC, levels = c(level_order))) %>% 
  mutate(lmm = factor(lmm, levels = c(level_lmm))) %>% 
  ggplot(aes(x = lmm, y = value, fill = VPC, label = round(value,2))) + 
  geom_bar(stat = "identity", color = "black",  width = 0.5)  +
  geom_text(size = 3, position = position_stack(vjust = 0.5), color = "white")+
  scale_fill_manual(values = rev(color_rcVCA[1:6])) +
  theme_classic(base_size = 12)+
  ylim(0,1)+
  geom_hline(yintercept = sum(round(vca_null[1:3,]$total_null,2)), linetype = "dashed")+
  geom_hline(yintercept = sum(round(vca_null[2:3,]$total_null,2)))+
  annotate("text", x = 1.5, y = (1-vca_null[4,]$total_null) + (vca_null[4,]$total_null/2), label= "residual")+
  annotate("text", x = 1.5, y = (sum(vca_null[2:3,]$total_null)) + (vca_null[1,]$total_null/2), label= "shared")+
  annotate("text", x = 1.5, y = (sum(vca_null[2:3,]$total_null)) - (sum(vca_null[2:3,]$total_null)/2), label= "unique")+
  labs(x = "Model",
       y = "Proportion \nof Variance",
       fill = "VPC") +
  theme(legend.spacing.y = unit(.1, 'cm'))  +
  ## important additional element
  guides(fill = guide_legend(byrow = TRUE))

#save output in the output folder
write_csv(rcvca_comparison,sprintf("%s/%s/02_rcVCA.csv", wd,wd_output))

#save image in the image folder
pdf(sprintf("%s/%s/02_fig1_rcVCA.pdf", wd,wd_image),
height = 3,
width = 5.5
)
p1
dev.off()

#CHECK####
AESR_data_avg = AESR_data %>% group_by(Obj) %>% summarise_all(mean)
##Quality checks
#chek if VPC shared explained match with a simple linear model
summary(lm(AE ~ SR, AESR_data_avg))
#percentage of variance in the shared component accounted for by the shared SR (this should be roughly comparable with the lm above)
rcvca_comparison %>% filter(lmm == "AE~SR") %>% filter(VPC == "Stimulus_SR" ) %>% pull(value) / rcvca_comparison %>% filter(lmm == "AE(null)") %>% filter(VPC  == "Stimulus" ) %>% pull(value)