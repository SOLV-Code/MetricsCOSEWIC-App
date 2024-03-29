# FUNCTIONS USED ON THE SERVER SIDE OF THE GUI

# KEEPING THIS AROUND FOR NOW, SEE IF WE NEED SOMETHING LIKE IT


extractSettings <- function(model.type,avg.years,BoxCox,int.avg,pred.var =NULL,rate.avg = NULL,last.n = NULL,
max.pool = NULL,tol.AIC = NULL,tol.r.sq = NULL){

	if(model.type %in% c("Naive")){ settings.out <- list(avg.yrs = avg.years) }
	if(model.type %in% c("TimeSeriesArima","TimeSeriesExpSmooth")){ settings.out <- list(BoxCox = BoxCox) }
	if(model.type %in% c("SibRegSimple","SibRegLogPower")){ settings.out <- NULL }
	if(model.type %in% c( "SibRegKalman")){ settings.out <- list(int.avg = int.avg) }
	if(model.type %in% c( "ReturnRate")){ settings.out <- list(pred.label = pred.var,avg = rate.avg,last.n = last.n)
												#print(settings.out)
												#stop()
												}
    if(model.type %in% c( "SibRegPooledSimple","SibRegPooledLogPower")){ settings.out <- list(max.pool = max.pool) }
	if(model.type %in% c( "SibRegComplex")){ settings.out <- list(tol.AIC = tol.AIC,tol.r.sq = tol.r.sq,incl.base.eq = FALSE) }

#print(settings.out)
#	stop()


return(settings.out)
}



