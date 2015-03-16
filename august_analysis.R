rm(list=ls())
library(ROCR)
library(party)
library(gbm)
library(pROC)
library(mobForest)

setwd("/Users/bensfisher/PITF")

data = read.csv("full_data_lagged.csv")

# a little cleaning

data$iso = as.character(data$iso)
data$YearWithHalf = as.numeric(data$YearWithHalf)
data$polxnew[data$polxnew==-66] = NA
data$partdemfac[data$sftptv2a == "Partial democracy with factionalism"] = 1
data$partdemfac[data$sftptv2a != "Partial democracy with factionalism"] = 0
data$partaut[data$sftptv2a == "Partial autocracy"] = 1
data$partaut[data$sftptv2a != "Partial autocracy"] = 0
data$elceleth = as.factor(data$elceleth)
data$cirspeec = as.factor(data$cirspeec)
data$partdemfac = as.factor(data$partdemfac)
data$partaut = as.factor(data$partaut)
data$sftpval = as.factor(data$sftpval)
data$wlkcflt = as.factor(data$wlkcflt)
data$wtogatt = as.factor(data$wtogatt)
data$bnnyroff_log = log(data$bnnyroff)
data$pop_log = log(data$bnkv4)
data$couany[data$couscess>=1] = 1
data$couany[data$coufaild>=1] = 1
data$couany[data$couscess <1] = 0
data$couany[data$coufaild <1] = 0
data$couany=as.factor(data$couany)

data$MAany = data$MAonset+data$MAcontinuation
data$MAany[data$MAany>=1] = 1

# try dummy observations for each country

#iso.dummies = dummy(data$iso)
#data = cbind(data, iso.dummies)

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

#### Splitting data into train and test ####
set.seed(1989)
indexes = sample(1:nrow(data), size=0.25*nrow(data))
full.test = data[indexes,]
full.train = data[-indexes,]

#############################
## Using Only Pertinent Variables ##
#############################
#train = full.train[c(1,2,30,32,7,22,148,171:174,176:179,181:184,196:199)]
#test = full.test[c(1,2,30,32,7,22,148,171:174,176:179,181:184,196:199)]

train = full.train[c(1,2,30,32,7,22,148,174,179,199,189,184)]
test = full.test[c(1,2,7,29,30,32,22,148,174,179,199,189,184)]

## remove rows where MAcontinuation = 1 ##
train$MAcontinuation[train$MAonset==1] = 0
train = train[which(train$MAcontinuation==0),]
test$MAcontinuation[test$MAonset==1] = 0
test = test[which(test$MAcontinuation==0),]

train$MAcontinuation = NULL
test$MAcontinuation = NULL

train = na.omit(train)
test = na.omit(test)

train$YearWithHalf = NULL
train$iso=NULL
test_id = test[1:2]
test_id = as.data.frame(test_id)
test_onset = test$MAonset
test_deaths = test$deaths
test$MAonset=NULL
test$YearWithHalf = NULL
test$iso=NULL
test$deaths = NULL

logit.mod = glm(MAonset~., data=train, family="binomial")
logit.probs.in = predict(logit.mod, train[c(2:9)],type="response")
logit.probs.out = predict(logit.mod, test, type="response")

logit.auc.in = roc(train$MAonset, logit.probs.in)
logit.auc.out = roc(test_onset, logit.probs.out)

gbm.mod = gbm(MAonset~., data=train, n.trees=100000, distribution="bernoulli")
gbm.probs.in = predict(gbm.mod, train[c(2:9)], n.trees=100000, type="response")
gbm.probs.out = predict(gbm.mod, test, n.trees=100000, type="response")

gbm.auc.in = roc(train$MAonset, gbm.probs.in)
gbm.auc.out = roc(test_onset, gbm.probs.out)

mod.forest = cforest(MAonset~., data=train, control=cforest_unbiased(ntree=1000))
forest.probs.in = predict(mod.forest, train[c(2:9)], OOB=TRUE)
forest.probs.out = predict(mod.forest, test, OOB=TRUE)

forest.auc.in = roc(train$MAonset, forest.probs.in)
forest.auc.out = roc(test_onset, forest.probs.out)

### Plotting P-R curves ###

logit.pred.in = prediction(logit.probs.in, as.factor(train$MAonset))
logit.perf.in = performance(logit.pred.in, "prec","rec")

logit.pred.out = prediction(logit.probs.out, as.factor(test_onset))
logit.perf.out = performance(logit.pred.out,"prec","rec")

gbm.pred.in = prediction(gbm.probs.in, as.factor(train$MAonset))
gbm.perf.in = performance(gbm.pred.in, "prec","rec")

gbm.pred.out = prediction(gbm.probs.out, as.factor(test_onset))
gbm.perf.out = performance(gbm.pred.out,"prec","rec")

forest.pred.in = prediction(forest.probs.in, as.factor(train$MAonset))
forest.perf.in = performance(forest.pred.in, "prec","rec")

forest.pred.out = prediction(forest.probs.out, as.factor(test_onset))
forest.perf.out = performance(forest.pred.out,"prec","rec")

average.probs.in = (logit.probs.in+gbm.probs.in+forest.probs.in)/3
average.pred.in = prediction(average.probs.in, as.factor(train$MAonset))
average.perf.in = performance(average.pred.in, "prec", "rec")

average.probs.out = (logit.probs.out+gbm.probs.out+forest.probs.out)/3
average.pred.out = prediction(average.probs.out, as.factor(test_onset))
average.perf.out = performance(average.pred.out, "prec", "rec")


plot(logit.perf.in, col=1, lwd=1, ylim =c(0,1))
plot(gbm.perf.in, col=2, lwd=1, add=TRUE)
plot(forest.perf.in, col=3, lwd=1, add=TRUE)
plot(average.perf.in, col=4, lwd=1, add=TRUE)
legend(.7, .8, c("Logit","GBM","Forest","Average"), lwd=rep(2,1), col = c(1,2,3,4))

plot(logit.perf.out, col=1, lwd=1, ylim =c(0,1))
plot(gbm.perf.out, col=2, lwd=1, add=TRUE)
plot(forest.perf.out, col=3, lwd=1, add=TRUE)
plot(average.perf.out, col=4, lwd=1, add=TRUE)
legend(.7,.8, c("Logit","GBM","Forest","Average"), lwd=rep(2,1), col = c(1,2,3,4))

### combining predictions ###
avg.probs = (logit.probs.out+gbm.probs.out+forest.probs.out)/3
probabilities = cbind(test_id[1:2], logit.probs.out, gbm.probs.out, forest.probs.out, avg.probs, test_onset, test_deaths)
colnames(probabilities)[3:6] = c("logit.probs", "gbm.probs", "forest.probs", "average.probs")
probabilities = probabilities[order(-probabilities$test_onset),]

write.csv(probabilities,"probs2.csv")

### Isolate at risk regions ###

#############################
## Using Only Pertinent Variables ##
#############################
#train = full.train[c(1,2,30,32,7,22,148,171:174,176:179,181:184,196:199)]
#test = full.test[c(1,2,30,32,7,22,148,171:174,176:179,181:184,196:199)]

train = full.train[c(1,2,5,30,32,7,22,148,174,179,199,189,184)]
test = full.test[c(1,2,5,7,29,30,32,22,148,174,179,199,189,184)]

## Region check ##
train = train[which(train$sftgreg1 == "NE" | train$sftgreg1 == "AF" | train$sftgreg1 == "FS" | train$sftgreg1 == "EA", train$sftgreg1 == "LA"),]
test = test[which(test$sftgreg1 == "NE" | test$sftgreg1 == "AF" | test$sftgreg1 == "FS" | test$sftgreg1 == "EA", train$sftgreg1 == "LA"),]

## remove rows where MAcontinuation = 1 ##
train$MAcontinuation[train$MAonset==1] = 0
train = train[which(train$MAcontinuation==0),]
test$MAcontinuation[test$MAonset==1] = 0
test = test[which(test$MAcontinuation==0),]

train$MAcontinuation = NULL
test$MAcontinuation = NULL

train = na.omit(train)
test = na.omit(test)

train$YearWithHalf = NULL
train$iso=NULL
train$sftgreg1=NULL
test_id = test[1:2]
test_id = as.data.frame(test_id)
test_onset = test$MAonset
test_deaths = test$deaths
test$MAonset=NULL
test$YearWithHalf = NULL
test$iso=NULL
test$deaths = NULL
test$sftgreg1 = NULL

logit.mod = glm(MAonset~., data=train, family="binomial")
logit.probs.in = predict(logit.mod, train[c(2:9)],type="response")
logit.probs.out = predict(logit.mod, test, type="response")

logit.auc.in = roc(train$MAonset, logit.probs.in)
logit.auc.out = roc(test_onset, logit.probs.out)

gbm.mod = gbm(MAonset~., data=train, n.trees=100000, distribution="bernoulli")
gbm.probs.in = predict(gbm.mod, train[c(2:9)], n.trees=100000, type="response")
gbm.probs.out = predict(gbm.mod, test, n.trees=100000, type="response")

gbm.auc.in = roc(train$MAonset, gbm.probs.in)
gbm.auc.out = roc(test_onset, gbm.probs.out)

mod.forest = cforest(MAonset~., data=train, control=cforest_unbiased(ntree=1000))
forest.probs.in = predict(mod.forest, train[c(2:9)], OOB=TRUE)
forest.probs.out = predict(mod.forest, test, OOB=TRUE)

forest.auc.in = roc(train$MAonset, forest.probs.in)
forest.auc.out = roc(test_onset, forest.probs.out)


### Example Tree ###
library(plyr)

samp <- function(dataf){
    dataf[sample(1:dim(dataf)[1], size=250, replace=TRUE),]
}

subset = ddply (data, .(MAonset), samp)

tree = ctree(MAonset~pop_log+opp_reb_matcfu+cnsimr, data=subset)

plot(tree, inner_panel = node_barplot(tree, beside = FALSE),
     terminal_panel = node_barplot(tree, beside = FALSE))

plot(tree,  type="simple",         # no terminal plots
  inner_panel=node_inner(tree,
       abbreviate = FALSE,            # short variable names
       pval = FALSE,                 # no p-values
       id = FALSE),                  # no id of node
  terminal_panel=node_terminal(tree, 
       abbreviate = FALSE,
       digits = 1,                   # few digits on numbers
       fill = c("white"),            # make box white not grey
       id = FALSE)
   )