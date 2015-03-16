##### Analysis for February Conference #####

rm(list=ls())
library(ROCR)
library(party)
library(gbm)
library(pROC)
library(mobForest)
library(dplyr)

setwd("/Users/bensfisher/PITF")

data = read.csv("full_data_lagged.csv")

# a little cleaning

data$iso = as.character(data$iso)
data$YearWithHalf = as.numeric(data$YearWithHalf)
data$sftptv2a = as.factor(data$sftptv2a)
data$elceleth = as.factor(data$elceleth)
data$sftpval = as.factor(data$sftpval)
data$wtogatt = as.factor(data$wtogatt)
data$bnnyroff_log = log(data$bnnyroff)
data$bnnyroff_log[data$bnnyroff_log==-Inf] = 0
data$pop_log = log(data$bnkv4)
data$couany=data$couscess+data$coufaild
data$rosogvp0_log = log(data$rosogvp0+1)

data$MAany = data$MAonset+data$MAcontinuation
data$MAany[data$MAany>=1] = 1


# Reformatting to undirected event variables to reduce dimensions, this seems to improve accuracy

data$gov_gov_vercpu = data$gov_gov_vercp
data$gov_gov_matcpu = data$gov_gov_matcp
data$gov_gov_vercfu = data$gov_gov_vercf
data$gov_gov_matcfu = data$gov_gov_matcf
data$gov_gov_goldu = data$gov_gov_gold

data$opp_opp_vercpu = data$opp_opp_vercp
data$opp_opp_matcpu = data$opp_opp_matcp
data$opp_opp_vercfu = data$opp_opp_vercf
data$opp_opp_matcfu = data$opp_opp_matcf
data$opp_opp_goldu = data$opp_opp_gold

data$reb_reb_vercpu = data$reb_reb_vercp
data$reb_reb_matcpu = data$reb_reb_matcp
data$reb_reb_vercfu = data$reb_reb_vercf
data$reb_reb_matcfu = data$reb_reb_matcf
data$reb_reb_goldu = data$reb_reb_gold

data$soc_soc_vercpu = data$soc_soc_vercp
data$soc_soc_matcpu = data$soc_soc_matcp
data$soc_soc_vercfu = data$soc_soc_vercf
data$soc_soc_matcfu = data$soc_soc_matcf
data$soc_soc_goldu = data$soc_soc_gold

data$gov_opp_vercpu=data$gov_opp_vercp + data$opp_gov_vercp
data$gov_opp_matcpu=data$gov_opp_matcp + data$opp_gov_matcp
data$gov_opp_vercfu=data$gov_opp_vercf + data$opp_gov_vercf
data$gov_opp_matcfu=data$gov_opp_matcf + data$opp_gov_matcf
data$gov_opp_goldu=data$gov_opp_gold + data$opp_gov_gold

data$gov_reb_vercpu=data$gov_reb_vercp + data$reb_gov_vercp
data$gov_reb_matcpu=data$gov_reb_matcp + data$reb_gov_matcp
data$gov_reb_vercfu=data$gov_reb_vercf + data$reb_gov_vercf
data$gov_reb_matcfu=data$gov_reb_matcf + data$reb_gov_matcf
data$gov_reb_goldu=data$gov_reb_gold + data$reb_gov_gold

data$opp_reb_vercpu=data$opp_reb_vercp + data$opp_gov_vercp
data$opp_reb_matcpu=data$opp_reb_matcp + data$opp_gov_matcp
data$opp_reb_vercfu=data$opp_reb_vercf + data$opp_gov_vercf
data$opp_reb_matcfu=data$opp_reb_matcf + data$opp_gov_matcf
data$opp_reb_goldu=data$opp_reb_gold + data$opp_gov_gold

data$gov_soc_vercpu=data$gov_soc_vercp + data$soc_gov_vercp
data$gov_soc_matcpu=data$gov_soc_matcp + data$soc_gov_matcp
data$gov_soc_vercfu=data$gov_soc_vercf + data$soc_gov_vercf
data$gov_soc_matcfu=data$gov_soc_matcf + data$soc_gov_matcf
data$gov_soc_goldu=data$gov_soc_gold + data$soc_gov_gold

data$opp_soc_vercpu=data$opp_soc_vercp + data$soc_opp_vercp
data$opp_soc_matcpu=data$opp_soc_matcp + data$soc_opp_matcp
data$opp_soc_vercfu=data$opp_soc_vercf + data$soc_opp_vercf
data$opp_soc_matcfu=data$opp_soc_matcf + data$soc_opp_matcf
data$opp_soc_goldu=data$opp_soc_gold + data$soc_opp_gold

data$reb_soc_vercpu=data$reb_soc_vercp + data$soc_reb_vercp
data$reb_soc_matcpu=data$reb_soc_matcp + data$soc_reb_matcp
data$reb_soc_vercfu=data$reb_soc_vercf + data$soc_reb_vercf
data$reb_soc_matcfu=data$reb_soc_matcf + data$soc_reb_matcf
data$reb_soc_goldu=data$reb_soc_gold + data$soc_reb_gold


#### Model Validation ####
library(caret)
set.seed(1989)

f.expanded = formula(MAonset ~ elceleth + dispota4 + macnciv + sftptv2a + cnsimr + bnnyroff_log + couany + rosogvp0_log + pop_log + gov_opp_matcfu + gov_reb_matcfu + reb_soc_matcfu + gov_soc_matcfu+ opp_reb_matcfu)

f.original = formula(MAonset ~ elceleth + cnsimr + pop_log + gov_opp_matcfu + gov_reb_matcfu + reb_soc_matcfu + gov_soc_matcfu+ opp_reb_matcfu)

valdat = data[c(1,2,5,6,30,32,7,10,16,18,20,22,145,146,147,148,173,178,198,188,183)]
valdat$MAcontinuation[valdat$MAonset==1] = 0
valdat = filter(valdat, MAcontinuation==0)
valdat = filter(valdat, bnkv4>500000)
#valdat = filter(valdat, sftgreg2 != 'WE')
valdat$sftgreg1 = valdat$sftgreg2 = NULL
valdat = na.omit(valdat)

y = valdat$MAonset
valdat$k = createFolds(y, k = 5, list=FALSE)

# Cross Validation using different models #

predit <- function(x) {
	train = subset(valdat, k != x)
	test = subset(valdat, k == x)
	test$logit.p = predict(glm(f.original, family = binomial, data = train), newdata = test, type = "response")
	test$rf.p = predict(cforest(f.original, data=train, control=cforest_unbiased(ntree=1000)), test, OOB=TRUE)
	test$gbm.p = predict(gbm(f.original, data=train, n.trees=100000, distribution="bernoulli"), test, n.trees=100000, type="response")
	test$mean.p = (test$logit.p + test$rf.p + test$gbm.p)/3
	out = subset(test, select = c(iso, YearWithHalf, MAonset, logit.p, rf.p, gbm.p, mean.p, k))
	return(out)
}

test1 = predit(1)
test2 = predit(2)
test3 = predit(3)
test4 = predit(4)
test5 = predit(5)
out = rbind(test1, test2, test3, test4, test5)


#### ROC Curves and PR curves #### 
library(ROCR)
library(caTools)

mean.pred = prediction(out$mean.p, out$MAonset)
mean.roc = performance(mean.pred, 'tpr', 'fpr')
mean.auc = performance(mean.pred, measure = 'auc')
logit.pred = prediction(out$logit.p, out$MAonset)
logit.roc = performance(logit.pred, 'tpr', 'fpr')
logit.auc = performance(logit.pred, measure = 'auc')
gbm.pred = prediction(out$gbm.p, out$MAonset)
gbm.roc = performance(gbm.pred, 'tpr', 'fpr')
gbm.auc = performance(gbm.pred, measure = 'auc')
rf.pred = prediction(out$rf.p, out$MAonset)
rf.roc = performance(rf.pred, 'tpr', 'fpr')
rf.auc = performance(rf.pred, measure = 'auc')

mean.perf = performance(prediction(out$mean.p, out$MAonset), "prec", "rec")
mean.prec = mean.perf@y.values[[1]]
mean.prec[is.na(mean.prec)] = 0
pr.mean.auc = trapz(mean.perf@x.values[[1]], mean.prec)
logit.perf = performance(prediction(out$logit.p, out$MAonset), "prec", "rec")
logit.prec = logit.perf@y.values[[1]]
logit.prec[is.na(logit.prec)] = 0
pr.logit.auc = trapz(logit.perf@x.values[[1]], logit.prec)
gbm.perf = performance(prediction(out$gbm.p, out$MAonset), "prec", "rec")
gbm.prec = gbm.perf@y.values[[1]]
gbm.prec[is.na(gbm.prec)] = 0
pr.gbm.auc = trapz(gbm.perf@x.values[[1]], gbm.prec)
rf.perf = performance(prediction(out$rf.p, out$MAonset), "prec", "rec")
rf.prec = rf.perf@y.values[[1]]
rf.prec[is.na(rf.prec)] = 0
pr.rf.auc = trapz(rf.perf@x.values[[1]], rf.prec)

mean.auc
logit.auc
gbm.auc
rf.auc

pr.mean.auc
pr.logit.auc
pr.gbm.auc
pr.rf.auc
