#Author: Giacomo Bignardi
#Adapted from: Bignardi et al.(under review) https://psyarxiv.com/79nbq 
#Date: 02-05-2023
#Description:
#Apply Variance Component Analysis (VCA) to partition sources of variance in aesthetic ratings
#Partially adapted from:  Martinez et al., 2020; Sutherland, Burton et al., 2020
#Program: VCA ------------------------------------------------------------------------------------------------------------------------------
#load packages
library(readr)
library(tidyverse)
library(tidylog)
library(lme4) #this is needed for MLM
library(patchwork) #this is needed for pretty plotting

#clean working environment 
rm(list = ls())

#set Open Access working directories
wd = getwd()
wd_data = "01_data"
wd_Rfunction = "02_scripts/R/functions"
wd_output = "03_outputs"
wd_image = "04_images"

#load dataFrames:
#this data are a sampled version of cleaned data used by Bignardi et al.(under review) https://psyarxiv.com/79nbq
#the data were originally collected by Germine et al. (2015, Current Biology) and made available at https://osf.io/c3hz6/
sce_MLM_TwinLong  = read_csv(sprintf("%s/%s/00_sce_Twin1_Germine2015.csv", wd,wd_data))
abs_MLM_TwinLong  = read_csv(sprintf("%s/%s/00_abs_Twin1_Germine2015.csv", wd,wd_data))
#load functions:
source(sprintf("%s/%s/vca_exposure.R", wd,wd_Rfunction))
source(sprintf("%s/%s/VCA_exposure_tidyCI.R", wd,wd_Rfunction))

#parameters:
#simulations (NOTE: run initially with 5 to simulate computation time on your device)
NSim = 2000 #n sim based on Sutherland et al., 2020; PNAS
set.seed(42)
#N simulation for the semi-parametric bootstraping (NB if a model takes time=t to fit, n simulations will take t=n*t)
#rename first 4 columns to fit entry requirements for VCA function
names(sce_MLM_TwinLong) = c("Obj","Rating","Sub","Block")
names(abs_MLM_TwinLong) = c("Obj","Rating","Sub","Block")

##MLM####
old =  Sys.time() # get start time
#fit multilevel models (based on Martinez et al., 2020; https://pubmed.ncbi.nlm.nih.gov/31898288/)
Opt = lmerControl(optimizer = "bobyqa", calc.derivs = F)
sce_MLM = lmer(Rating ~ 1 + ((1 | Sub) + (1 | Obj) + (1|Sub:Obj) + (1|Block) + (1|Block:Sub) + (1|Block:Obj)), data=sce_MLM_TwinLong, control = Opt)
abs_MLM = lmer(Rating ~ 1 + ((1 | Sub) + (1 | Obj) + (1|Sub:Obj) + (1|Block) + (1|Block:Sub) + (1|Block:Obj)), data=abs_MLM_TwinLong, control = Opt)

#semi parametric bootstraping to estimate CIs
options(nwarnings = NSim) #set warning to see how many model did not converged during the simulations
sce_bootVCA = bootMer(sce_MLM, VCA_exposure, nsim=NSim, .progress = "txt")
sce_boot_Warn = warnings()
abs_bootVCA = bootMer(abs_MLM, VCA_exposure, nsim=NSim, .progress = "txt")
abs_boot_Warn = warnings()
# print elapsed time
new <- Sys.time() - old # calculate difference
new*(2000/NSim) #time needed for CI based on 2000 simulation
print(old)
print(new)

#VCA####
##no CI####
VCA_sce = VCA_exposure(sce_MLM, ci = F)
VCA_abs = VCA_exposure(abs_MLM, ci = F)
##CI####
#Create a summuary of the VCA
sce_VCAsummary = VCA_exposure_tidyCI(sce_bootVCA,sce_MLM, "Scenes")
abs_VCAsummary = VCA_exposure_tidyCI(abs_bootVCA,abs_MLM, "Abstract")
#bind to an unique df
VCAsummary = rbind(sce_VCAsummary,abs_VCAsummary)

#PLOTTING####
#set color for plotting
color_VA = c(viridis::viridis(7),c("#D3D3D3"))
p1 = VCAsummary%>%
  #remove repeated variance and composite VPC
  filter(!grepl("_rep",Component)) %>% 
  filter(!grepl("Unique",Component)) %>% 
  filter(!grepl("Shared",Component)) %>% 
  filter(!grepl("Repeatable",Component)) %>% 
  #order factor for plotting
  mutate(Component = factor(Component, levels = c("Stimulus", "Individual", "Exposure", "Stimulus*Individual", "Exposure*Individual", "Stimulus*Exposure", "Residual")),
        Domain = factor(Domain, levels = c("Abstract","Scenes"))) %>% 
  ggplot(aes(x=Domain, y=Value, fill = Component)) +
  #plot variance components
  geom_bar(stat="identity", position=position_dodge(), color = "black", alpha = .9) +
  #plot 95% CI
  geom_errorbar(aes(ymin=CI_low, ymax=CI_high), position=position_dodge(.9), width = .5) +
  #plot "sigificance" of the VPC
  scale_fill_manual(values = color_VA) +
  scale_y_continuous(limits = c(0,1), breaks = seq(0,1,by = .1))+
  labs(y= "Proportion\nof variance", x = "" ,fill = "Variance Component")+
  theme_classic(base_size = 12)

#create a summary VPC (similar to Honekopp Beholder Index type 2; Honekopp 2006, Journal of Experimental Psychology)
#set color for plotting
color_Bi = c(color_VA[1],"#334970")

p2 = VCAsummary%>%
  filter(grepl("Unique_rep",Component)| grepl("Shared_rep",Component)) %>% 
    ggplot(aes(x=Domain, y= Value, fill = Component)) +
    geom_bar(stat="identity", position=position_dodge(), alpha = .9, width = 2/4, color = "black") +
    geom_errorbar(aes(ymin=CI_low, ymax=CI_high), position=position_dodge(.5), width = .25) +
    scale_fill_manual(values = c(color_Bi)) +
    scale_y_continuous(limits = c(0,1), breaks = seq(0,1,by = .1))+
    labs(y= "Proportion of\nrepeatable variance", x = "Domain" ,fill = "Summary") +
    theme_classic(base_size = 12)
  
VCAsummary
#SAVING####
#save output in the output folder
write_csv(VCAsummary,sprintf("%s/%s/01_VCA_wci.csv", wd,wd_output))

#save image in the image folder
pdf(sprintf("%s/%s/01_fig1_VCA.pdf", wd,wd_image),
    height = 6,
    width = 5.5
)
(p1/p2) +plot_layout(guides = "collect") + plot_annotation(tag_levels = "a")
dev.off()

