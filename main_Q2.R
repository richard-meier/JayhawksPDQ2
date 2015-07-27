setwd(".../GitHub/JayhawksProstateDream")

source("src/modelCombination.R")
source("dataCleaningMain.R")

setwd(".../Prostate_DREAM/data")

#### load data ####
train_data <- clean_all_data(
	coreFileName="CoreTable_training.csv", 
	lesionFileName="LesionMeasure_training.csv", 
	priorMedFile="PriorMed_training.csv", 
	isTraining=TRUE
)
test_data <- clean_all_data(
	coreFileName="leaderboard data/CoreTable_leaderboard.csv", 
	lesionFileName="leaderboard data/LesionMeasure_leaderboard.csv", 
	priorMedFile="leaderboard data/PriorMed_leaderboard.csv", 
	isTraining=FALSE
)
validation_data <- clean_all_data(
	coreFileName="finalScoringSet/CoreTable_validation.csv", 
	lesionFileName="finalScoringSet/LesionMeasure_validation.csv", 
	priorMedFile="finalScoringSet/PriorMed_validation.csv", 
	isTraining=FALSE
)

# ensemble model fit and prediction
emod = fitModelCombination(
  models=c(
    "Surv(time = LKADT_P, event = DEATH) ~ pspline(pc1,df=2) + AGE + rr_MI + AGE*rr_MI + ECOG + metastases_sum + RACE_NEW + metastases_sum*RACE_NEW + rr_protective + rm_NA. + metastases_sum*rm_NA. + sg_ESTROGENS + rm_HB + metastases_sum*rm_HB",
    "Surv(time = LKADT_P, event = DEATH) ~ pspline(pc1, df = 2) + rm_NEU + rr_z_score_weighted_medHistory + AGE + rr_MI + AGE*rr_MI + ECOG + metastases_sum + RACE_NEW + metastases_sum*RACE_NEW + rr_ormedHistory + tlv + sg_ESTROGENS + sg_BISPHOSPHONATE + rm_NEU*sg_BISPHOSPHONATE",
    "Surv(time = LKADT_P, event = DEATH) ~ tlv + harm_pro2 + pc1 + rr_z_score_weighted_medHistory + rr_ormedHistory + PROSTATE + ECOG_C + sg_ESTROGENS + rm_PHOS + rr_ormedHistory:rm_PHOS + rm_ALP:sg_GLUCOCORTICOID",
    "Surv(time = LKADT_P, event = DEATH) ~ rm_AST + rm_ALP + tlv + rm_HB + rr_z_score_weighted_medHistory + rm_LDH + rr_ormedHistory + rm_NEU + rm_PHOS + rr_ormedHistory*rm_PHOS + ECOG + rm_ALP*ECOG + harm_pro + metastases_sum",
    "Surv(time = LKADT_P, event = DEATH) ~ pc1 + rr_z_score_weighted_medHistory + sg_z_score_weighted_priorMed + tlv + rm_NEU:tlv + rr_ormedHistory + rm_PHOS + rr_ormedHistory*rm_PHOS + rm_ALP + pc1*rm_ALP + rm_HB + sg_z_score_weighted_priorMed*rm_HB"
  ),
  mWeights=c(0.2,0.2,0.2,0.2,0.2),
  train_data = train_data
)

### Make predictions for train, test, validation data ###
train_scores = predictEnsembleRisk(emod, t_data=train_data)
test_scores = predictEnsembleRisk(emod, t_data=test_data)
val_scores = predictEnsembleRisk(emod, t_data=validation_data)

### index for only discont
idx_discont <-which(is.na(as.numeric(as.character(train_data$DISCONT))) == FALSE)

################################################################################
### Use the models submitted in question 1a
### and get the risk score of all observaions in training data from those models
################################################################################

##### use the variables selected in question 1a submissions and predict scores
variables=c("RPT","STUDYID","DISCONT","rm_AST","rm_NEU", "metastases_sum","harm_pro2", "harm_pro",
            "rr_z_score_weighted_medHistory",  "rm_LDH",   "rm_PHOS", "rm_HB", "rm_ALP", "rm_NA.", 
            "tlv", "AGE", "rr_MI","RACE_NEW", "ECOG", "PROSTATE", "rr_protective", "rr_ormedHistory",
            "sg_z_score_weighted_priorMed","sg_ESTROGENS", "sg_BISPHOSPHONATE", "sg_GLUCOCORTICOID")

### append ensemble risk scores
ens <- train_scores
data_final=cbind(train_data[variables], ens)
data_final = data_final[idx_discont,] ## subset to subj with discont
data_final$DISCONT = as.factor(as.character(data_final$DISCONT))

#### the ensemble of risk scores is strongly associated with DISCNOT result
### so final model built with stepwise selection model on whole final data 
### final models were selected based on CV of auc from score_q2
### ensemble of risk scores were not included due to interpretability

final_model1 =  glm(formula = DISCONT ~ rr_ormedHistory + ECOG + rm_LDH + sg_ESTROGENS + rm_PHOS + AGE, 
                    family = binomial(link = "logit"), data = data_final, na.action = na.exclude)

final_model2 = glm(formula = DISCONT ~ ens + rr_ormedHistory + sg_ESTROGENS + ECOG + rm_PHOS + AGE + rr_ormedHistory:ECOG + rr_ormedHistory:AGE, 
                   family = binomial(link = "logit"), data = data_final, na.action = na.exclude)

#### Append risk scores from test and validation ###
ens <- test_scores
test_data <- cbind(test_data[c(variables)], ens)

ens <- val_scores
validation_data <- cbind(validation_data[c(variables)], ens)

### Create final Astrazeneca data set ###
final_test_data = rbind(test_data,validation_data)

#### get predict score ens of final test data
pred1 = predict( final_model1, newdata = final_test_data, type = "response" )
pred2 = predict( final_model2, newdata = final_test_data, type = "response" )

# get final DISCONT result
y1 = ifelse(pred1>0.5,1,0)
y2 = ifelse(pred2>0.5,1,0)

q2_submission1 = data.frame(final_test_data$RPT, pred1, y1)
q2_submission2 = data.frame(final_test_data$RPT, pred2, y2)

colnames(q2_submission1) = colnames(q2_submission2) = c("RPT","RISK","DISCONT")

# write.csv(q2_submission1,"SUBMISSIONS/final/JayHwaks_q2_submission1.csv",row.names=F)
# write.csv(q2_submission2,"SUBMISSIONS/final/JayHwaks_q2_submission2.csv",row.names=F)
