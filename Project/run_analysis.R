# Package
library(data.table)

# Set path for fread
path <- file.path(getwd(), "UCI HAR Dataset")

# Read files
dtSubjectTrain <- fread(file.path(path, "train", "subject_train.txt"))
dtSubjectTest <- fread(file.path(path, "test", "subject_test.txt"))
dtTrainingLabels <- fread(file.path(path, "train", "y_train.txt"))
dtTestLabels <- fread(file.path(path, "test", "y_test.txt"))
dtTrainingSet <- fread(file.path(path, "train", "X_train.txt"))
dtTestSet <- fread(file.path(path, "test", "X_test.txt")) 

# Merge test and training subjects
dtSubject <- rbind(dtSubjectTrain, dtSubjectTest)
setnames(dtSubject, "V1", "subject")

# Merge test and training labels
dtLabels <- rbind(dtTrainingLabels, dtTestLabels)
setnames(dtLabels, "V1", "activity")

# Merge test and training sets
dtSet <- rbind(dtTrainingSet, dtTestSet)

# Merge subjects, activity labels, and sets
dtSubjectLabels <- cbind(dtSubject, dtLabels)
dtSet <- cbind(dtSubjectLabels, dtSet)

# Features names
features <- fread(file.path(path, "features.txt"))
setnames(features, c("V1", "V2"), c("index", "feature"))

# Extract mean and SD
features <- features[grepl("mean\\(\\)|std\\(\\)", features$feature)]
features$index <- paste0("V", features$index)
dtSet <- dtSet[, c("subject","activity",features$index), with = FALSE]

# Descriptive activity labels
activity.labels <- fread(file.path(path, "activity_labels.txt"))
setnames(activity.labels, names(activity.labels), c("index", "name"))
dtSet <- dtSet[, activity:=activity.labels$name[dtSet$activity]]
dtSet$activity <- factor(dtSet$activity)
dtSet$subject <- factor(dtSet$subject)

# Names of measurement variables
setnames(dtSet, c("subject", "activity", features$feature[1:66]))
setnames(dtSet, names(dtSet), gsub("^t", "Time", names(dtSet)))
setnames(dtSet, names(dtSet), gsub("^f", "Freq", names(dtSet)))
setnames(dtSet, names(dtSet), gsub("-mean\\(\\)", "Mean", names(dtSet)))
setnames(dtSet, names(dtSet), gsub("-std\\(\\)", "SD", names(dtSet)))
setnames(dtSet, names(dtSet), gsub("-", "", names(dtSet)))

# Tidy dateset
dtTidy <- dtSet[, lapply(.SD, mean), by=c("subject","activity")]

# Write to file
write.table(dtTidy, "tidydataset.txt", row.names = FALSE)