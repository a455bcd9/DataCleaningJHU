# Packages
packages <- c("data.table")
sapply(packages, require, character.only=TRUE, quietly=TRUE)

# Set path
path <- getwd()

# Load files
dtSubjectTrain <- fread(file.path(path, "train", "subject_train.txt"))
dtSubjectTest  <- fread(file.path(path, "test" , "subject_test.txt" ))

dtTrainingLabels <- fread(file.path(path, "train", "y_train.txt"))
dtTestLabels  <- fread(file.path(path, "test" , "y_test.txt" ))

dtTraingSet <- fread(file.path(path, "train", "X_train.txt")) 
dtTestSet <- fread(file.path(path, "test" , "X_test.txt" ))

# Merge
dtSubject <- rbind(dtSubjectTrain, dtSubjectTest)
setnames(dtSubject, "V1", "subject")
dtActivity <- rbind(dtTrainingLabels, dtTestLabels)
setnames(dtActivity, "V1", "activityNum")
dt <- rbind(dtTraingSet, dtTestSet)

# Merge columns
dtSubject <- cbind(dtSubject, dtActivity)
dt <- cbind(dtSubject, dt)

# Key
setkey(dt, subject, activityNum)

dtFeatures <- fread(file.path(path, "features.txt"))
setnames(dtFeatures, names(dtFeatures), c("featureNum", "featureName"))

dtFeatures <- dtFeatures[grepl("mean\\(\\)|std\\(\\)", featureName)]

dtFeatures$featureCode <- dtFeatures[, paste0("V", featureNum)]
# head(dtFeatures)
# dtFeatures$featureCode

select <- c(key(dt), dtFeatures$featureCode)
dt <- dt[, select, with=FALSE]

dtActivityNames <- fread(file.path(path, "activity_labels.txt"))
setnames(dtActivityNames, names(dtActivityNames), c("activityNum", "activityName"))

dt <- merge(dt, dtActivityNames, by="activityNum", all.x=TRUE)

setkey(dt, subject, activityNum, activityName)

dt <- data.table(melt(dt, key(dt), variable.name="featureCode"))

dt <- merge(dt, dtFeatures[, list(featureNum, featureCode, featureName)], by="featureCode", all.x=TRUE)

dt$activity <- factor(dt$activityName)
dt$feature <- factor(dt$featureName)

easygrep <- function (expression) {
  grepl(expression, dt$feature)
}
## Features with 2 categories
n <- 2
y <- matrix(seq(1, n), nrow=n)
x <- matrix(c(easygrep("^t"), easygrep("^f")), ncol=nrow(y))
dt$featDomain <- factor(x %*% y, labels=c("Time", "Freq"))
x <- matrix(c(easygrep("Acc"), easygrep("Gyro")), ncol=nrow(y))
dt$featInstrument <- factor(x %*% y, labels=c("Accelerometer", "Gyroscope"))
x <- matrix(c(easygrep("BodyAcc"), easygrep("GravityAcc")), ncol=nrow(y))
dt$featAcceleration <- factor(x %*% y, labels=c(NA, "Body", "Gravity"))
x <- matrix(c(easygrep("mean()"), easygrep("std()")), ncol=nrow(y))
dt$featVariable <- factor(x %*% y, labels=c("Mean", "SD"))
## Features with 1 category
dt$featJerk <- factor(easygrep("Jerk"), labels=c(NA, "Jerk"))
dt$featMagnitude <- factor(easygrep("Mag"), labels=c(NA, "Magnitude"))
## Features with 3 categories
n <- 3
y <- matrix(seq(1, n), nrow=n)
x <- matrix(c(easygrep("-X"), easygrep("-Y"), easygrep("-Z")), ncol=nrow(y))
dt$featAxis <- factor(x %*% y, labels=c(NA, "X", "Y", "Z"))

setkey(dt, subject, activity, featDomain, featAcceleration, featInstrument, featJerk, featMagnitude, featVariable, featAxis)
dtTidy <- dt[, list(count = .N, average = mean(value)), by=key(dt)]

write.table(dtTidy, "tidytable.txt", row.name=FALSE)