con = url("http://stats.wikimedia.org/wikimedia/squids/SquidReportPageViewsPerCountryBreakdown.htm")
htmlCode = readLines(con)
n <- length(htmlCode)
countries <- c()
first <- c()
second <- c()

# encoding error reunion sao tome curacao aland

for (i in 1:n) {
	if(grepl('^<tr><th co', htmlCode[i])){
    	# if starts with
    	country  <- strsplit(htmlCode[i], "<tr><th colspan=99 class=lh3><a id='")
    	# print(country[[1]][2])
    	country  <- strsplit(country[[1]][2], "' name='")
    	# print(country[[1]][1])
    	countries <- c(countries, country[[1]][1])
    	if(grepl('^<tr><th class=l class=small nowrap>French Wp', htmlCode[i+1])){
    		first <- c(first, country[[1]][1])
    	} else if(grepl('^<tr><th class=l class=small nowrap>French Wp', htmlCode[i+2])){
    		second <- c(second, country[[1]][1])
    	}
	}
}

j <- length(countries)
k <- length(first)
m <- length(second)

print("French Wp first:")
first

print("French Wp second:")
second

# first
# second

# library(XML)
# theurl <- "http://en.wikipedia.org/wiki/Brazil_national_football_team"
# tables <- readHTMLTable(theurl)
# n.rows <- unlist(lapply(tables, function(t) dim(t)[1]))
# the picked table is the longest one on the page

# tables[[which.max(n.rows)]]