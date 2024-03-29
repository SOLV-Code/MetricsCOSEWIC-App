
#' @title Calculate a forecast from a single statistical model
#'
#' @param fit.obj A list, created by \code{\link{fitModel}}, with model fitting details for each age class.
#' @param data A list. Equal to the element named \code{data} from output of \code{\link{prepData}}.
#' @param data.sibreg A data frame. Equal to the element named \code{sibreg.in} from output of \code{\link{prepData}}. NOTE: all the functions and subroutines should be rewritten to just use the full \code{\link{prepData}} output, but priority now is to get the new sibreg variations working
#' @param predictors A list. Optional input needed for return rate model. Equal to the element named \code{predictors} from output of \code{\link{prepData}}. Default is NULL.
#' @param covariates A list. Optional input needed for covariate model. Equal to the element named \code{covariates} from output of \code{\link{prepData}}. Default is NULL.
#' @param fc.yr An integer of length one. The forecast year. If NULL (the default), then calculate as the year after the last run year in the data set.
#' @param settings A list. The model-specific list of settings used in \code{\link{fitModel}}. NOTE: This is now part of the list object created by \code{\link{fitModel}}, so should streamline the input.
#' @param tracing A Boolean. Default is FALSE
#'
#' @return
#' @export
#'
#' @examples
calcFC <- function(fit.obj= NULL, data = NULL, data.sibreg = NULL, fc.yr= NULL, settings = NULL, tracing=FALSE, predictors = NULL, covariates = NULL ){
# Check inputs

	# GP 2021: I think the predictors and covariates arguments are no longer used, need to verify!!!!!!!!!!!!!!!

	if(any(is.null(c(fit.obj,data)))){warning("Some inputs are missing");stop()}
	if(is.null(fc.yr)){ warning("automatic fc.yr determination not implemented yet");stop()}


	# Given different models for each age class, how to check here?
	#if(!(model %in% c("SibRegSimple","SibRegKalman","SibRegLogPower"))){
	#					warning("Specified model not part of current inventory")
	#					stop()
	#					}


	# any other check needed here?


	#  create empty list to store outputs
	out.list <- list()


	# do the point forecast (for all age classes, have set up NoAge to work with the same function)
 #print(predictors)
	out.list <- sub.pt.fc(fit=fit.obj,
												data.source=data ,
												 data.sibreg = data.sibreg,
												fc.yr = fc.yr,
												fit.settings=settings,
												pred. = predictors,
												cov. = covariates)

	return(out.list)

}# end calcFC()


##########################################################################################################

sub.fcdata <- function(fit,data = NULL ,data.sibreg = NULL, fc.yr,pred = NULL, cov.in = NULL){
	# This function uses the fitted model parameters to calculate a forecast
	# with optional bootstrap distribution

	# GP 2021: I think the predictors and covariates arguments are no longer used, need to verify!!!!!!!!!!!!!!!

#print("starting sub.fcdata()")

data.list <- list()

age.classes <- names(data)
ages <- as.numeric(gsub("\\D", "", age.classes)) # as per https://stat.ethz.ch/pipermail/r-help/2011-February/267946.html
age.prefix <- gsub(ages[1],"",age.classes[1])


#################
# No Age

# for now this handles the "noage" version, need to test to ensure robustness
# also: should be able to combine the 2 versions into 1 generic, but for now just make it work
if(any(is.na(ages))){

	model.type <- fit[["Total"]]$model.type

	#print(model.type)

	if(model.type %in% c("Naive")){
		coeff <- fit[["Total"]]$coefficients
		data.tmp <-  data[["Total"]]
		data.list[["Total"]] <-  data.tmp[data.tmp[,"Run_Year"] %in% (fc.yr - seq(1,coeff)),2] # get the run years used in the avg
		}

	if(model.type %in% c("TimeSeriesArima","TimeSeriesExpSmooth")){
		# The arima/ets object has all the pieces it needs for forecast(), but
		# we are using the data later for the boxcox back conversion, so need to include it here
		# PATCH WARNING: HARDWIRED COLUMN SUBSET NEEDS TO BE FIXED
		data.list[["Total"]] <-  data[["Total"]][,2]


		}


	if(model.type %in% c("ReturnRate")){

		warning("ReturnRate FC for noAge data not yet implemented")
		stop()
	}


} # end if no age classes



#################
# WITH AGE

if(!any(is.na(ages))){  # if have age classes, loop through them

#PATCH WARNING: HARDWIRED COLUMN SUBSET THROUGHOUT NEEDS TO BE FIXED


for(age.use in names(data)){
	#print("age.use")
	age.num <- as.numeric(gsub("\\D", "", age.use)) # as per https://stat.ethz.ch/pipermail/r-help/2011-February/267946.html
	age.prefix <- gsub(age.num,"",age.use)
	model.type <- fit[[age.use]]$model.type
	coeff <- fit[[age.use]]$coefficients


	if(model.type %in% c("Naive")){
		data.tmp <-  data[[paste(age.prefix,age.num,sep="")]] # get the same age class
		data.list[[age.use]] <-  data.tmp[data.tmp[,"Run_Year"] %in% (fc.yr - seq(1,coeff)),3] # get the run years used in the avg
		}



	if(model.type %in% c("SibRegSimple","SibRegKalman","SibRegLogPower","SibRegPooledSimple","SibRegPooledLogPower")){
	# have separate prep step for complex sib (as in estimation function)

		# OLD
		# there must be a way to streamline this step
		#data.tmp <-  data[[paste(age.prefix,age.num-1,sep="")]] # get the previous age class
		#data.sub <-  data.tmp[data.tmp[,"Run_Year"] == fc.yr -1,3] # get the previous run year from that age class
		#data.df	 <-  as.data.frame(data.sub)     # turn it into data frame, so can feed it into predict.lm()
		#names(data.df) <- fit[[age.use]]$var.names # need to verify that this works for all the sib reg models
		#data.list[[age.use]] <-  data.df

		br.yr.use <- fc.yr - age.num



		data.tmp <-  data.sibreg # new object with all the age classes
		data.sub <- data.tmp %>% dplyr::filter(Brood_Year == br.yr.use) %>% select(all_of(fit[[age.use]]$sib.pred.used))

		data.df	 <-  as.data.frame(data.sub)     # turn it into data frame, so can feed it into predict.lm()
		names(data.df) <- fit[[age.use]]$var.names # need to verify that this works for all the sib reg models
		data.list[[age.use]] <-  data.df

		}


	if(model.type %in% c("SibRegComplex")){

		# should be able to streamline this chunk a lot!
		print("---------- INSIDE sub.fcdata > model.type == SibRegComplex -------------")
		print(age.use)

		br.yr.use <- fc.yr - age.num
		
		
		
		pred.var.all <- names(fit[[age.use]]$coefficients)
		print("pred.var.all")
		print(pred.var.all)
		age.idx <- grepl("Age_",pred.var.all)
		interaction.idx <- grepl(":",pred.var.all)
		pred.var.age <- pred.var.all[age.idx]
		pred.var.cov<- pred.var.all[!age.idx & !interaction.idx]
		print("pred.var.cov")
		print(pred.var.cov)

		age.sib <- paste(age.prefix,age.num-1,sep="")

		data.sib<-  data[[age.sib]] %>%
										select(Brood_Year, all_of(pred.var.age)) %>%
										dplyr::filter(Brood_Year == br.yr.use)
		print("data.sib")
		print(data.sib)
		print("data[[age.use]]")
		print(data[[age.use]] )

		print(pred.var.cov)
		print("head(cov.in)")
		print(head(cov.in))
		print(head(cov.in[[age.use]]))

		data.cov <-	cov.in[[age.use]] %>%
									select(Brood_Year, all_of(pred.var.cov)) %>%
										dplyr::filter(Brood_Year == br.yr.use)
		print(data.cov)

		data.df	 <-  left_join(data.sib,data.cov, by = "Brood_Year") #%>% as.data.frame()
		print(data.df)

		data.list[[age.use]] <-  data.df

	}



	if(model.type %in% c("TimeSeriesArima","TimeSeriesExpSmooth")){

		# The arima/ets object has all the pieces it needs for forecast(), but
		# we are using the data later for the boxcox back conversion, so need to include it here
		data.list[[age.use]] <-  data[[paste(age.prefix,age.num,sep="")]][,3] # get the same age class
	}


	if(model.type %in% c("ReturnRate")){
		# return rate model needs only the predictor variable for the fc year (already lined up with appropriate lag in input data)
		data.pre <-  pred[[paste(age.prefix,age.num,sep="")]]
		data.list[[age.use]] <- data.pre[data.pre$Run_Year == fc.yr,fit[[age.use]]$var.names] #

	}




}} # end looping through age classes if have them / need them

print("data.list ----------------------------------")
print(data.list)

print("ending sub.fcdata()")


return(data.list)

} # end sub.fcdata



##########################################################################################################

sub.pt.fc <- function(fit,data.source,
											data.sibreg = NULL,
											fc.yr,fit.settings = NULL,
											pred. = NULL, cov.= NULL){

# extract data needed for the fc (one element for each age class)

	#MF: this is an unsatisfactory method to handle boxcox true/false
	#GP: not fixing the issue, so commenting out
	#if("lambda" %in% tolower(names(fit[[1]]))) fit.settings$BoxCox <- TRUE

# had to change argument names because of error: "promise already under evaluation: recursive default argument reference or earlier problems?"
# solution as per: https://stackoverflow.com/questions/4357101/promise-already-under-evaluation-recursive-default-argument-reference-or-earlie

	# GP 2021: I think the predictors and covariates arguments are no longer used, need to very!!!!!!!!!!!!!!!

data <- sub.fcdata(fit = fit , data = data.source, data.sibreg = data.sibreg , fc.yr=fc.yr,pred = pred.,cov.in = cov.)

print("output from sub.fcdata()-----------------------")
print(data)

#generate output matrix
out.mat <-  matrix(NA,nrow=1,ncol=length(names(data)),dimnames = list(paste("FC",fc.yr,sep=""),
						names(data)  ))

out.mat.lower <- out.mat.upper <- out.mat
 #print("out.mat template --------------------------------")
 #print(out.mat)

# loop through the age classes

for(age.use in names(data)){
  # print("-------------------------------------------------")
  # print(age.use)

	age.num <- as.numeric(gsub("\\D", "", age.use)) # as per https://stat.ethz.ch/pipermail/r-help/2011-February/267946.html
	age.prefix <- gsub(age.num,"",age.use)

	model.type <- fit[[age.use]]$model.type
	#print(model.type)
	#coeff <- fit[[age.use]]$model.fit$coefficients  # see note re: model.fit at beginnig of Module_Sub_EstimationFunctions.R
	coeff <- fit[[age.use]]$coefficients
  #print(coeff)
	#print(names(fit[[age.use]]))
	fit.obj <- fit[[age.use]]#$model.fit   # see note re: model.fit at beginnig of Module_Sub_EstimationFunctions.R
  #print("fit.obj feeding into pt fc")
 # print(fit.obj)
	#print(age.use)
	#print(model.type)
	#print(data[[age.use]])
	#print(fit.settings)
#	browser()
	pt.fc.tmp <-  estimation.functions[[model.type]]$pt.fc(fit.obj=fit.obj, data = data[[age.use]],settings=fit.settings)

	#print(pt.fc.tmp)

	out.mat[,age.use] <- pt.fc.tmp[1]
	out.mat.lower[,age.use] <- pt.fc.tmp[2]
	out.mat.upper[,age.use] <- pt.fc.tmp[3]

} # end looping through age

 #print("out.mat after calcs --------------------------------")
#print(out.mat)

#### TEMPORARY! See https://github.com/avelez-espino/forecastR_phase4/issues/121
###

	out.mat[out.mat < 0] <- 0
	out.mat.lower[out.mat.lower < 0] <- 0
	out.mat.upper[out.mat.upper < 0] <- 0

# add total if have more than 1 age class (1 "age class" typically = "Total")
# NOTE: simply adding up lower and upper bounds for now (See https://github.com/avelez-espino/forecastR_phase4/issues/124)
if(length(names(data))>1) {
		out.mat <- cbind(out.mat,Total=rowSums(out.mat))
		out.mat.lower <- cbind(out.mat.lower,Total=rowSums(out.mat.lower))
		out.mat.upper <- cbind(out.mat.upper,Total=rowSums(out.mat.upper))

		}

return(list(pt.fc = out.mat, lower = out.mat.lower, upper = out.mat.upper))


}# end sub.pt.fc






#' yrs.extract
#'
#' @param mat.in
#' @param col.use
#'
#' @return
#' @export
#'
#' @examples
yrs.extract <- function(mat.in,col.use="Run_Year"){
	# used inside of retrospective piece
			range.out <- range(mat.in[,col.use])
		return(range.out)
}#END yrs.extract



