######################################################################################
##################              Jayhawks - Read Me file             ##################
####     This file provides:                                                      ####
####         INSTRUCTIONS to run our R code/prediction algorithm    ##################
######################################################################################


#### INSTRUCTIONS ####

In order to make the main script work you first have to download and setup the JayhawksProstateDream project which can be found here: https://github.com/richard-meier/JayhawksProstateDream
Follow the instructions in the README.txt and make sure that the scripts are working properly.

Next you have to make sure that the paths to files in the main script are setup correctly. Open the script:
main_Q2.R
... and change setwd(".../GitHub/JayhawksProstateDream") so that it points to where the JayhawksProstateDream directory is located on your hard-drive.
Also change setwd(".../Prostate_DREAM/data") so that it points to the directory where the data provided for the challenge is located. The program assumes that the training data is inside this directory, that the data for the leader board rounds is located in a sub-folder with the name "leaderboard data" and that the data for the final scoring round is located in a sub-folder with the name "finalScoringSet".

After you have made and saved these changes, you can use... 
source(".../main_Q2.R") to run the main program

