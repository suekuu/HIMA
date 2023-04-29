#' Advanced High-dimensional Mediation Analysis
#' 
#' \code{hima2} is an upgraded version of hima for estimating and testing high-dimensional mediation effects.
#' 
#' @param formula an object of class \code{formula}: a symbolic description of the overall effect model, i.e., 
#' \code{outcome ~ exposure + covariates}, to be fitted. Make sure the "exposure" is the variable of interest, which
#' must be listed as the first variable in the right hand side of the formula.
#' independent variable in the formula. The same covariates will be used in screening and penalized regression.
#' @param data.pheno a data frame containing all the variables listed in the right hand side of the \code{formula}.
#' \code{hima2} will scale \code{data.pheno}.
#' @param data.M a \code{data.frame} or \code{matrix} of high-dimensional mediators. Rows represent samples, columns 
#' represent variables. \code{hima2} will scale \code{data.M}.
#' @param outcome.family either \code{'gaussian'} (default, for normally distributed continuous outcome), \code{'binomial'} 
#' (for binay outcome), or \code{'survival'} (for time-to-event outcome), depending on the data type of outcome.
#' @param mediator.family either \code{'gaussian'} (default, for continuous mediators), \code{'negbin'} (i.e., negative binomial, 
#' for RNA-seq data as mediators), or \code{'compositional'} (for microbiome data as mediators), depending on the data type of 
#' high-dimensional mediators (\code{data.M}).
#' @param penalty the penalty to be applied to the model. Either \code{'DBlasso'} (De-biased LASSO, default), 
#' \code{'MCP'}, \code{'SCAD'}, or \code{'lasso'}.
#' @param topN an integer specifying the number of top markers from sure independent screening. 
#' Default = \code{NULL}. If \code{NULL}, \code{topN} will be either \code{ceiling(n/log(n))} if 
#' \code{outcome.family = 'gaussian'}, or \code{ceiling(n/(2*log(n)))} if \code{outcome.family = 'binomial'}, 
#' where \code{n} is the sample size. If the sample size is greater than topN (pre-specified or calculated), all 
#' mediators will be included in the test (i.e. low-dimensional scenario).
#' @param scale logical. Should the function scale the data? Default = \code{TRUE}.
#' @param verbose logical. Should the function be verbose and shows the progression? Default = \code{FALSE}.
#' 
#' @return A data.frame containing mediation testing results of selected mediators. 
#' 
#' @references Zhang H, Zheng Y, Zhang Z, Gao T, Joyce B, Yoon G, Zhang W, Schwartz J, Just A, Colicino E, Vokonas P, Zhao L, 
#' Lv J, Baccarelli A, Hou L, Liu L. Estimating and Testing High-dimensional Mediation Effects in Epigenetic Studies. 
#' Bioinformatics. 2016. DOI: 10.1093/bioinformatics/btw351. PMID: 27357171. PMCID: PMC5048064
#' 
#' Perera C, Zhang H, Zheng Y, Hou L, Qu A, Zheng C, Xie K, Liu L. 
#' HIMA2: high-dimensional mediation analysis and its application in epigenome-wide DNA methylation data. 
#' BMC Bioinformatics. 2022. DOI: 10.1186/s12859-022-04748-1. PMID: 35879655. PMCID: PMC9310002
#' 
#' Zhang H, Zheng Y, Hou L, Zheng C, Liu L. Mediation Analysis for Survival Data with High-Dimensional Mediators. 
#' Bioinformatics. 2021. DOI: 10.1093/bioinformatics/btab564. PMID: 34343267. PMCID: PMC8570823
#' 
#' Zhang H, Chen J, Feng Y, Wang C, Li H, Liu L. Mediation effect selection in high-dimensional and compositional microbiome data. 
#' Stat Med. 2021. DOI: 10.1002/sim.8808. PMID: 33205470; PMCID: PMC7855955.
#' 
#' Zhang H, Chen J, Li Z, Liu L. Testing for mediation effect with application to human microbiome data. 
#' Stat Biosci. 2021. DOI: 10.1007/s12561-019-09253-3. PMID: 34093887; PMCID: PMC8177450.
#' 
#' @examples
#' \dontrun{
#' # Example 1 (continous outcome): 
#' data(Example1)
#' head(Example1$PhenoData)
#' 
#' e1 <- hima2(Outcome ~ Treatment + Sex + Age, 
#'       data.pheno = Example1$PhenoData, 
#'       data.M = Example1$Mediator,
#'       outcome.family = "gaussian",
#'       mediator.family = "gaussian",
#'       penalty = "MCP",
#'       scale = FALSE)
#' e1
#' attributes(e1)$variable.labels
#' 
#' # Example 2 (binary outcome): 
#' data(Example2)
#' head(Example2$PhenoData)
#' 
#' e2 <- hima2(Disease ~ Treatment + Sex + Age, 
#'       data.pheno = Example2$PhenoData, 
#'       data.M = Example2$Mediator,
#'       outcome.family = "binomial",
#'       mediator.family = "gaussian",
#'       penalty = "MCP",
#'       scale = FALSE)
#' e2
#' attributes(e2)$variable.labels
#' 
#' # Example 3 (time-to-event outcome): 
#' data(Example3)
#' head(Example3$PhenoData)
#' 
#' e3 <- hima2(Surv(Status, Time) ~ Treatment + Sex + Age, 
#'       data.pheno = Example3$PhenoData, 
#'       data.M = Example3$Mediator,
#'       outcome.family = "survival",
#'       mediator.family = "gaussian",
#'       penalty = "DBlasso",
#'       scale = FALSE)
#' e3
#' attributes(e3)$variable.labels
#' 
#' # Example 4 (compositional data as mediator, e.g., microbiome): 
#' data(Example4)
#' head(Example4$PhenoData)
#' 
#' e4 <- hima2(Outcome ~ Treatment + Sex + Age, 
#'       data.pheno = Example4$PhenoData, 
#'       data.M = Example4$Mediator,
#'       outcome.family = "gaussian",
#'       mediator.family = "compositional",
#'       penalty = "DBlasso",
#'       scale = FALSE)
#' e4
#' attributes(e4)$variable.labels
#' }
#'                   
#' @export
hima2 <- function(formula, 
                  data.pheno, 
                  data.M,  
                  outcome.family = c("gaussian", "binomial", "survival"), 
                  mediator.family = c("gaussian", "negbin", "compositional"), 
                  penalty = c("DBlasso", "MCP", "SCAD", "lasso"), 
                  topN = NULL, 
                  scale = TRUE,
                  verbose = FALSE) 
{
  outcome.family <- match.arg(outcome.family)
  mediator.family <- match.arg(mediator.family)
  penalty <- match.arg(penalty)
  
  if (outcome.family %in% c("gaussian", "binomial"))
  {
    if(mediator.family %in% c("gaussian", "negbin"))
    {
      response_var <- as.character(formula[[2]]) 
      ind_vars <- all.vars(formula)[-1]
      
      Y <- data.pheno[,response_var]
      X <- data.pheno[,ind_vars[1]]
      
      if(length(ind_vars) > 1)
        COV <- data.pheno[,ind_vars[-1]] else COV <- NULL
      
      results <- hima(X = X, Y = Y, M = data.M, COV.XM = COV, 
                      Y.family = outcome.family, penalty = penalty, topN = topN,
                      parallel = FALSE, ncore = 1, scale = scale, verbose = verbose)
      
      attr(results, "variable.labels") <- c("Effect of exposure on mediator", 
                                            "Effect of mediator on outcome",
                                            "Total effect of exposure on outcome",
                                            "Mediation effect",
                                            "Percent of mediation effect out of the total effect",
                                            "Bonferroni adjusted p value",
                                            "Benjamini-Hochberg False Discovery Rate")
    }
    
    if(mediator.family == "compositional")
    {
      response_var <- as.character(formula[[2]]) 
      ind_vars <- all.vars(formula)[-1]
      
      Y <- data.pheno[,response_var]
      X <- data.pheno[,ind_vars[1]]
      
      if(length(ind_vars) > 1)
        COV <- data.pheno[,ind_vars[-1]] else COV <- NULL
      
      res <- microHIMA(X = X, Y = Y, OTU = data.M, COV = COV, FDPcut = 0.05, scale)
      results <- data.frame(alpha = res$alpha, alpha_se = res$alpha_se, 
                            beta = res$beta, beta_se = res$beta_se,
                            p = res$p_FDP, check.names = FALSE)
      rownames(results) <- res$ID
      attr(results, "variable.labels") <- c("Effect of exposure on mediator", 
                                            "Standard error of the effect of exposure on mediator",
                                            "Effect of mediator on outcome",
                                            "Standard error of the effect of mediator on outcome",
                                            "p value")
    }
    
    
  } else if (outcome.family == "survival") {
    response_vars <- as.character(formula[[2]])[c(2,3)]
    ind_vars <- all.vars(formula)[-c(1,2)]
    
    X <- data.pheno[,ind_vars[1]]
    status <- data.pheno[, response_vars[1]]
    OT <- data.pheno[, response_vars[2]]
    
    if(length(ind_vars) > 1)
      COV <- data.pheno[,ind_vars[-1]] else COV <- NULL
    
    res <- survHIMA(X, COV, data.M, OT, status, FDRcut = 0.05, scale, verbose)
    
    results <- data.frame(alpha = res$alpha, alpha_se = res$alpha_se, 
                          beta = res$beta, beta_se = res$beta_se,
                          p = res$pvalue, check.names = FALSE)
    rownames(results) <- res$ID
    attr(results, "variable.labels") <- c("Effect of exposure on mediator", 
                                          "Standard error of the effect of exposure on mediator",
                                          "Effect of mediator on outcome",
                                          "Standard error of the effect of mediator on outcome",
                                          "p value")
  }
  
  return(results)
}