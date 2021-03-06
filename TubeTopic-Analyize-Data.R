# Author: Clinton Daniel
# Date: 11/5/2018
# Description: This is sample code for ISM 4402. This code
# creates several reports with various distributions in .csv files.
# Additionally, it will create some visualizations of Topic Models generated by LDA
# Read all comments above code to determine if you want to change various relevant parameters.


# Load text mining library
library(tm)

params <- list(minDocFreq = 1,removeNumbers = TRUE,stopwords = TRUE,stemming = TRUE,weighting = weightTf) 

# Set working directory - CHANGE THIS TO YOUR DIRECTORY
setwd("C:/Users/Public/TubeTopicData")

# Load files into corpus
filenames <- list.files(getwd(),pattern = "*.txt")

# Read files into a character vector
files <- lapply(filenames, readLines)

# Create corpus from vector
docs <- Corpus(VectorSource(files))

# Remove common English stopwords
docs <- tm_map(docs,removeWords,stopwords("english"))

# Remove punctuation
docs <- tm_map(docs,removePunctuation)

# Remove numbers
docs <- tm_map(docs,removeNumbers)

# Remove whitespace
docs <- tm_map(docs,stripWhitespace)

# Stem document - remove word suffixes
# docs <- tm_map(docs,stemDocument)

# Define and eliminate all custom stopwords
myStopwords <- c("logsdon","baab","baabs","baabre","can","one","and","like","just","gonna","know",
                 "really","right","going","get","well","lot","actually","new",
                 "will","much","way","and","see","make","look",
                 "also","able","say","back","got","take","great",
                 "many","next","using","around","thing","two",
                 "looking","said","kind","come","put","yeah",
                 "even","still","ago","every","three","five","gonna",
                 "okay","whether","seen","you","six","there","this",
                 "and","but","you","want","thats","but","you",
                 "folks","sure","run","and")
docs <- tm_map(docs,removeWords,myStopwords)

# Create document-term matrix
dtm <- DocumentTermMatrix(docs, control = params)
# Convert rownames to filenames
rownames(dtm) <- filenames
# Collapse matrix by summing over columns
freq <- colSums(as.matrix(dtm))
# Length should be total number of terms
length(freq)
# Create sort order (descending)
ord <- order(freq,decreasing=TRUE)
# List all terms in decreasing order of freq and write to disk
freq[ord]
write.csv(freq[ord],"word_freq.csv")

# Load topic models library
library(topicmodels)

# Set parameters for Gibbs sampling
burnin <- 4000
iter <- 2000
thin <- 500
seed <-list(2003,5,63,100001,765)
nstart <- 5
best <- TRUE

# Number of topics
k <- 10

# Run LDA using Gibbs sampling
ldaOut <-LDA(dtm,k, method="Gibbs", control=list(nstart=nstart, seed = seed, best=best, burnin = burnin, iter = iter, thin=thin))

# write out results
# docs to topics

ldaOut.topics <- as.matrix(topics(ldaOut))
write.csv(ldaOut.topics,file=paste("LDAGibbs",k,"DocsToTopics.csv"))

# Top N terms in each topic
ldaOut.terms <- as.matrix(terms(ldaOut,100))
write.csv(ldaOut.terms,file=paste("LDAGibbs",k,"TopicsToTerms.csv"))

# Probabilities associated with each topic assignment
topicProbabilities <- as.data.frame(ldaOut@gamma)
write.csv(topicProbabilities,file=paste("LDAGibbs",k,"TopicProbabilities.csv"))

#Find relative importance of top 2 topics
topic1ToTopic2 <- lapply(1:nrow(dtm),function(x)
  sort(topicProbabilities[x,])[k]/sort(topicProbabilities[x,])[k-1])

#Find relative importance of second and third most important topics
topic2ToTopic3 <- lapply(1:nrow(dtm),function(x)
  sort(topicProbabilities[x,])[k-1]/sort(topicProbabilities[x,])[k-2])

#write to file
write.csv(topic1ToTopic2,file=paste("LDAGibbs",k,"Topic1ToTopic2.csv"))
write.csv(topic2ToTopic3,file=paste("LDAGibbs",k,"Topic2ToTopic3.csv"))

# create the visualization
library(tidytext)

ap_topics <- tidy(ldaOut, matrix = "beta")

library(ggplot2)
library(dplyr)

ap_top_terms <- ap_topics %>%
  group_by(topic) %>%
  top_n(20, beta) %>%
  ungroup() %>%
  arrange(topic, -beta)

ap_top_terms %>%
  mutate(term = reorder(term, beta)) %>%
  ggplot(aes(term, beta, fill = factor(topic))) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~ topic, scales = "free") +
  coord_flip()
library(tidyr)

beta_spread <- ap_topics %>%
  mutate(topic = paste0("topic", topic)) %>%
  spread(topic, beta) %>%
  filter(topic1 > .001 | topic2 > .001) %>%
  mutate(log_ratio = log2(topic2 / topic1))

write.csv(beta_spread,"beta_spread.csv")

