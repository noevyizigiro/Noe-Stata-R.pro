
# function created by Noe Vyizigiro
## this is a created function package that will be used in the labs. You can
# call this function by referencing to its directory or just copy the package to the directory you are working in
# this is still in development

library(tidyverse)
library(haven)
if(!require("purrr")) install.packages("purrr")
library(purrr) #this will help in summarizing the variable
library(rlang)

# 1. Function to compute summary statistics

nv_sum<-function(datax,..., weight, condition=NULL){
  vars<-enquos(...) # capture multiple variables and assign them to the variable vars
  if(!is.logical(weight)){
    stop("The input must be TRUE or FALSE")
  }
  if (!is.null(condition)) {
    expr_cond<-enquo(condition)
    datax <- datax %>% filter(!!expr_cond) # apply the condition if provided
  }
  map_dfr(vars, function(varx){ # iterate over the variables in vars to compute summary statistics
    var_name<-as_label(varx)
    
    if(weight){
      datax%>%
        summarise(variable =var_name,
                  Obs =n(),
                  min =min({{varx}}, na.rm = TRUE),
                  mean=sum({{varx}} * perwt, na.rm = TRUE) / sum(perwt,na.rm = TRUE), 
                  median =median(!!varx, na.rm =TRUE),
                  St.dev = sqrt(sum(perwt * (!!varx - sum(!!varx * perwt, na.rm = TRUE) / sum(perwt, na.rm = TRUE))^2, na.rm = TRUE) / sum(perwt, na.rm = TRUE)),
                  max=max(!!varx, na.rm = TRUE),
                  .groups = 'drop'
                  
        )  
    }
    else{
      datax%>%
        summarise(variable =var_name,
                  Obs =n(),
                  min =min({{varx}}, na.rm = TRUE),
                  mean =mean({{varx}}, na.rm=TRUE),
                  median =median(!!varx, na.rm =TRUE),
                  st.dev =sd(!!varx, na.rm =TRUE),
                  max=max(!!varx, na.rm = TRUE),
                  .groups = 'drop'
                  
        ) 
    }
  })
}
comment="
#still figuring this out:

 nv_sum<-function(datax,..., filter_vars=NULL, group_vars =NULL ){

   vars<-enquos(...) # capture multiple variables and assign them to the variable vars

#   # Apply filtering if filter_vars is provided
   if (!is.null(filter_vars)) {
     filter_exprs <- enquos(filter_vars)
     datax <- datax %>%
       filter(!!!filter_exprs)
   }
   # Apply grouping if group_vars is provided


  result<-map_dfr(vars, function(varx){ # iterate over the variables in vars to compute summary statistics
     var_name<-as_label(varx)

     if (!is.null(group_vars)) {
       group_exprs <- enquos(group_vars)
       datax <- datax %>%
         group_by(!!!group_exprs)
    }
    datax%>%
       summarise(variable =var_name,
                 min =min(!!varx, na.rm = TRUE),
                 mean =mean(!!varx, na.rm=TRUE),
                 median =median(!!varx, na.rm =TRUE),
                 st.dev =sd(!!varx, na.rm =TRUE),
                 max=max(!!varx, na.rm = TRUE),
                 n =n()
       )
   })
   return(result)
 }


 # varx can be either between {{}} or start with !! to ensure that the column name passed to the function is correctly referenced within summarise
 nv_sum(usa21_0, incwage, group_vars = educCode)

"
 #load function package "NV.R"
 #source("/Volumes/middfiles/Classes/Fall23/ECON0211A/Noe_Labs/NV.R") 
