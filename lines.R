library(data.table)
library(caret)
library(lubridate)
library(SciViews)

#Read in line_pairings and skaters tables from MoneyPuck
lines <- fread("./lines.csv")
teams <- fread("./teams.csv")

#Filter to include only 5on5 data for teams dataset
teams <- teams[which(situation=="5on5")]
teams <- teams[,.(team,iceTime,xGoalsPercentage)]
setnames(teams,old=c("team","iceTime","xGoalsPercentage"),new=c("team","gameMins","teamGoalPct"))
lines <- merge(lines,teams,all.x=T,by="team")
lines <- lines[,':='(iceTimePct=icetime/gameMins)]


#Separate into forward lines and defense pairings
pairings <- lines[which(position=="pairing")]
lines <- lines[which(position=="line")]

#######################################
##### Most dominant forward lines #####
#######################################

lines <- lines[,':='(flurryScoreVenueAdjustedxGoalsFor = flurryScoreVenueAdjustedxGoalsFor*3600/icetime,
                     flurryScoreVenueAdjustedxGoalsAgainst = flurryScoreVenueAdjustedxGoalsAgainst*3600/icetime)]
xGoals_lines <- lines[,.(lineId,season,name,team,teamGoalPct,games_played,icetime,iceTimePct,flurryScoreVenueAdjustedxGoalsFor,flurryScoreVenueAdjustedxGoalsAgainst,
                  flurryScoreVenueAdjustedxGoalDiff = flurryScoreVenueAdjustedxGoalsFor-flurryScoreVenueAdjustedxGoalsAgainst)]
xGoals_lines <- xGoals_lines[which(iceTimePct >= 0.05)]
xGoals_lines <- xGoals_lines[which(flurryScoreVenueAdjustedxGoalDiff > 0)]
xGoals_lines$icetimeAdjustedxGoalDiff <- xGoals_lines$flurryScoreVenueAdjustedxGoalDiff*(xGoals_lines$icetime)^(1/2)/150

possession_lines <- lines[,.(lineId,season,name,team,games_played,icetime,iceTimePct,corsiPercentage,fenwickPercentage)]
possession_lines <- possession_lines[which(iceTimePct >= 0.05)]

topLines <- merge(xGoals_lines,possession_lines,by=c("lineId","season","name","team","games_played",
                                                     "icetime","iceTimePct"),all.x=T)
topLines <- topLines[,':='(DominanceRating=icetimeAdjustedxGoalDiff*(corsiPercentage)^2/(teamGoalPct*2))]

# Reformat icetime so that it is more readable
topLines$icetimeClean <- seconds_to_period(topLines$icetime)
topLines$icetimeClean <- topLines[,':='(icetimeClean=sprintf('%02d:%02d:%02d', icetimeClean@hour, minute(icetimeClean), second(icetimeClean)))]

# Create top 20 forward lines table
topLines <- topLines[,.(name,team,icetimeClean,icetimeAdjustedxGoalDiff,
                      corsiPercentage,DominanceRating)]
top25_FLines <- head(topLines[order(DominanceRating,decreasing=TRUE),],111)

############################################
##### Most dominant defensive pairings #####
############################################

pairings <- pairings[,':='(flurryScoreVenueAdjustedxGoalsFor = flurryScoreVenueAdjustedxGoalsFor*3600/icetime,
                     flurryScoreVenueAdjustedxGoalsAgainst = flurryScoreVenueAdjustedxGoalsAgainst*3600/icetime)]
xGoals_pairings <- pairings[,.(lineId,season,name,team,teamGoalPct,games_played,icetime,iceTimePct,flurryScoreVenueAdjustedxGoalsFor,flurryScoreVenueAdjustedxGoalsAgainst,
                         flurryScoreVenueAdjustedxGoalDiff = flurryScoreVenueAdjustedxGoalsFor-flurryScoreVenueAdjustedxGoalsAgainst)]
xGoals_pairings <- xGoals_pairings[which(iceTimePct >= 0.05 & flurryScoreVenueAdjustedxGoalDiff > 0)]
xGoals_pairings$icetimeAdjustedxGoalDiff <- xGoals_pairings$flurryScoreVenueAdjustedxGoalDiff*(xGoals_pairings$icetime)^(1/2)/150

possession_pairings <- pairings[,.(lineId,season,name,team,games_played,icetime,iceTimePct,corsiPercentage,fenwickPercentage)]
possession_pairings <- possession_pairings[which(iceTimePct >= 0.05)]

topPairings <- merge(xGoals_pairings,possession_pairings,by=c("lineId","season","name","team","games_played",
                                                     "icetime","iceTimePct"),all.x=T)
topPairings <- topPairings[,':='(DominanceRating=icetimeAdjustedxGoalDiff*(corsiPercentage))]
topPairings <- topPairings[,':='(TeamAdjDominanceRating=DominanceRating/(teamGoalPct*2))]

# Reformat icetime so that it is more readable
topPairings$icetimeClean <- seconds_to_period(topPairings$icetime)
topPairings$icetimeClean <- topPairings[,':='(icetimeClean=sprintf('%02d:%02d:%02d', icetimeClean@hour, minute(icetimeClean), second(icetimeClean)))]

# Create top 10 defensive pairings table
topPairings <- topPairings[,.(name,team,icetimeClean,icetimeAdjustedxGoalDiff,
                      corsiPercentage,TeamAdjDominanceRating)]
top25_DPairs <- head(topPairings[order(TeamAdjDominanceRating,decreasing=TRUE),],25)


##############################
##### Write as CSV files #####
##############################

fwrite(top25_FLines,"./topFLines.csv")
fwrite(top20_DPairs,"./topDPairs.csv")



