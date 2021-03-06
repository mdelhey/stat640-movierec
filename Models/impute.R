# Attempt at matrix completion
library(softImpute)

# i/o params
f_out <- "Submissions/softimpute_cv_01.csv"
d_in <- "Data/train_ratings.csv"

# Working directory (for cloud)
setwd("~/stat640-movierec")
source("Models/functions.R")

# Load in data
trmat <- as.matrix(read.csv(d_in, header = TRUE))

###
### Model Fitting
###
# Center data
X <- biScale(trmat, maxit = 50, thresh = 1e-10)

# Find best lambda
lam <- lambda0(X, lambda = 0, maxit = 1000,
               trace.it = FALSE, thresh = 1e-06)

# Fit & Complete
X_fit <- softImpute(X, rank.max = min(dim(X)), lambda = 50,
                    type = "svd", thresh = 1e-06, maxit = 1000)

X_out <- complete(trmat, X_fit)

# Fix values less than 1, greater than 5
X_out <- force_bounds(X_out)

# Write to file
write_predmat(X_out, f_out = f_out)

###
### Imputation package
###
#library(imputation)
#lam_imp <- cv.SVDImpute(trmat, k = dim(trmat)[2]/2)
#lam_imp <- cv.SVDImpute(trmat, k = 5)

###
### Model Validation
###
# Create train and test partitions
#test_rows <- sample(nrow(trmat), nrow(trmat)*0.4, replace = FALSE) 
#test_cols <- sample(ncol(trmat), ncol(trmat)*0.4, replace = FALSE)

#train_rows <- setdiff(1:nrow(trmat), test_rows)
#train_cols <- setdiff(1:ncol(trmat), test_cols)


full <- which(!(is.na(trmat)))
jumbled <- sample(full, length(full))
q <- length(full) / 10
# Run cv over lambda's
lam_cv <- 1:2
rmse_cv <- rep(NA, 100)

i <- 0
for (l in lam_cv) {
  i <- i + 1
  rmse_cv[i] <- 0
  
  for(j in 1:10) {
    
    CV_err <- 0
    X_trn <- X
    X_trn[jumbled[j * (1:q)]] <- NA
    
    X_cv <- softImpute(X_trn, rank.max = 40, lambda = 98,
                       type = "svd", thresh = 1e-05, maxit = 10)
    
    X_pred <- complete(X_trn, X_cv)
    X_pred <- force_bounds(X_pred)
    
    x <- as.vector(X_pred)
    
    rmse_cv[i] <- rmse_cv[i] + 
                  rmse(x[jumbled[j * (1:q)]], 
                       trmat[jumbled[j * (1:q)]])
    
  }
  
  rmse_cv[i] <- rmse_cv[i] / 10
  
}

## X_val <- trmat[!is.na(trmat)]
## X_val <- complete(trmat, X_fit)

## # Generate training (true) values (review id, true)
## train <- cbind(c(1:(n*p)), c(trmat))
## train <- train[!is.na(train[, 2]), ]  # remove NA's

## # Convert data-matricies to dataframes
## bench_eval <- as.data.frame(cbind(c(1:(n*p)), c(predmat_eval)))
## names(bench_eval) <- c("ID", "Pred.Rating")
## train <- as.data.frame(train)
## names(train) <- c("ID", "True.Rating")

## # Evaluate on training data
## bench_eval <- subset(bench_eval, ID %in% train$ID)
## bench_eval$True.Rating <- train$True.Rating# train_rmse <- rmse(bench_eval$True.Rating, bench_eval$Pred.Rating)
