library(data.table)
library(ggplot2)
library(dplyr)
library(tidytext)
library(tidyr)
library(stringr)
library(magrittr)
library(readr)
library(ggjoy)


# This code was adapted from these two threads:
# https://www.tidytextmining.com/sentiment.html
# https://www.edgarsdatalab.com/2017/09/04/sentiment-analysis-using-tidytext/

# read in CSV from python data
reddit <- read_csv("data/reddit.csv", col_names = c("title", "num_comments", "selftext", "created_utc", "subreddit", "title_selftext"))

#convert into tibble
text_df <- tibble(line = 1:20001, text = reddit$title_selftext, subreddit = reddit$subreddit)


#analyze bigrams
text_bigrams <- text_df %>%
  unnest_tokens(bigram, text, token = "ngrams", n = 2)

# read in afinn library
AFINN <- get_sentiments("afinn")

# get bigrams that start with the word "Christmas" in LAN
lan_bigrams_separated <- text_bigrams %>%
  filter(subreddit == "LifeAfterNarcissism") %>%
  separate(bigram, c("word1", "word2"), sep = " ") %>% 
  filter(word1 == "christmas") %>% 
  count(word1, word2, sort = TRUE)


#get family words
lan_xmas_words <- lan_bigrams_separated %>%
  filter(word1=="christmas") %>%
  inner_join(AFINN, by = c(word2="word")) %>%
  count(word2, value, sort= TRUE)

# graph positive v. negative words after Christmas in LAN
lan_xmas_words %>%
  mutate(contribution = n * value) %>%
  arrange(desc(abs(contribution))) %>%
  head(20) %>%
  mutate(word2 = reorder(word2, contribution)) %>%
  ggplot(aes(word2, n * value, fill = n * value > 0)) +
  geom_col(show.legend = FALSE) +
  ggtitle("Words preceded by \"Christmas\" in Life After Narcissism Subreddit") +
  xlab("Word after Christmas") +
  ylab("Sentiment value * number of occurrences") +
  coord_flip()


# get bigrams that start with the word "Christmas" in RBN
rbn_bigrams_separated <- text_bigrams %>%
  filter(subreddit == "raisedbynarcissists") %>%
  separate(bigram, c("word1", "word2"), sep = " ") %>% 
  filter(word1 == "christmas") %>% 
  count(word1, word2, sort = TRUE)


rbn_family_words <- rbn_bigrams_separated %>%
  filter(word1=="christmas") %>%
  inner_join(AFINN, by = c(word2="word")) %>%
  count(word2, value, sort= TRUE)

# graph positive v. negative words after Christmas in RBN
rbn_family_words %>%
  mutate(contribution = n * value) %>%
  arrange(desc(abs(contribution))) %>%
  head(20) %>%
  mutate(word2 = reorder(word2, contribution)) %>%
  ggplot(aes(word2, n * value, fill = n * value > 0)) +
  geom_col(show.legend = FALSE) +
  ggtitle("Words preceded by \"Christmas\" in Raised by Narcissists Subreddit") +
  xlab("Word after Christmas") +
  ylab("Sentiment value * number of occurrences") +
  coord_flip()

##################
##################

## emotion analysis

# get the words in my text
tidy_text <- text_df %>%
  unnest_tokens(word,text) 

# import nrc library
# this library has emotional categories
nrc <- get_sentiments("nrc")

# join the words with library
nrc_words <- tidy_text %>%
  inner_join(get_sentiments("nrc"), by = "word")

# graph the distribution of each sentiment by subreddit
ggplot(nrc_words) +
  geom_joy(aes(
    x = subreddit,
    y = sentiment, 
    fill = sentiment),
    rel_min_height = 0.01,
    alpha = 0.7,
    scale = 3) +
  theme_joy() +
  labs(title = "Reddit Sentiment Analysis",
       x = "Subreddit",
       y = "Sentiment") + 
  scale_fill_discrete(guide=FALSE)

