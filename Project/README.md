Assignment: Getting and Cleaning Data Course Project
===================================================
Analysis file: run_analysis.R
-----------------------------

Steps:
------

* Load packages
```r
packages <- c("data.table")
sapply(packages, require, character.only=TRUE, quietly=TRUE)
```

* Set path
```r
path <- getwd()
```

* Load subjects
```r
dtSubjectTrain <- fread(file.path(path, "train", "subject_train.txt"))
dtSubjectTest  <- fread(file.path(path, "test" , "subject_test.txt" ))
```

* Load labels
```
dtTrainingLabels <- fread(file.path(path, "train", "y_train.txt"))
dtTestLabels  <- fread(file.path(path, "test" , "y_test.txt" ))
```

* Load sets
```r
dtTraingSet <- fread(file.path(path, "train", "X_train.txt")) 
dtTestSet <- fread(file.path(path, "test" , "X_test.txt" ))
```

* Concatenation of data tables
```r
dtSubject <- rbind(dtSubjectTrain, dtSubjectTest)
setnames(dtSubject, "V1", "subject")
dtActivity <- rbind(dtTrainingLabels, dtTestLabels)
setnames(dtActivity, "V1", "activityNum")
dt <- rbind(dtTraingSet, dtTestSet)
```

* Merge columns
```r
dtSubject <- cbind(dtSubject, dtActivity)
dt <- cbind(dtSubject, dt)
```

* Need to set key
```r
setkey(dt, subject, activityNum)
```

* Read ```features.txt``` to know the relevant variables (mean and standard deviation)
```r
dtFeatures <- fread(file.path(path, "features.txt"))
setnames(dtFeatures, names(dtFeatures), c("featureNum", "featureName"))
```

* Take only mean and standard deviation
```r
dtFeatures <- dtFeatures[grepl("mean\\(\\)|std\\(\\)", featureName)]
```

* Conversion to a vector of variable names
```r
dtFeatures$featureCode <- dtFeatures[, paste0("V", featureNum)]
```

* Subset
```r
select <- c(key(dt), dtFeatures$featureCode)
dt <- dt[, select, with=FALSE]
```

* Read ```activity_labels.txt``` to get descriptive names
```r
dtActivityNames <- fread(file.path(path, "activity_labels.txt"))
setnames(dtActivityNames, names(dtActivityNames), c("activityNum", "activityName"))
```

* Merge labels
```r
dt <- merge(dt, dtActivityNames, by="activityNum", all.x=TRUE)
```

* Set key
```r
setkey(dt, subject, activityNum, activityName)
```

* Melt data
```r
dt <- data.table(melt(dt, key(dt), variable.name="featureCode"))
```

* Merge
```r
dt <- merge(dt, dtFeatures[, list(featureNum, featureCode, featureName)], by="featureCode", all.x=TRUE)
```

* Create two variables, factor of ```activityName``` and ```featureName```
```r
dt$activity <- factor(dt$activityName)
dt$feature <- factor(dt$featureName)
```

* Grep using ```easygrep``` function
```r
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
```

* New data set with the mean of each variable
```r
setkey(dt, subject, activity, featDomain, featAcceleration, featInstrument, featJerk, featMagnitude, featVariable, featAxis)
dtTidy <- dt[, list(count = .N, average = mean(value)), by=key(dt)]
```

* Write the tidy table in a new file ```tidytable.txt```
```r
write.table(dtTidy, "tidytable.txt", row.name=FALSE)
```
