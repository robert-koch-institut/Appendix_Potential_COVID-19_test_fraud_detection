library(data.table)
library(lme4)


simDat = fread(file = '../simulated_data.csv')
m2 = glmer(positiv~offset(log(getestet)) 
           + typ + (1|week_yr)+ (1|tnr), 
           data=simDat,family = poisson(link = "log"))
summary(m2)
(appendix.Table2 = tab2(m2,simDat,CutW = -6))

tab2 = function(m2,A,CutW){#CutW=-6;A=simDat
  TestVal = function(m2,A,CutW){
    tt = as.data.table(ranef(m2))[grpvar=='tnr']
    setnames(tt,'grp','tnr')
    vv = tt[,.(tnr,condval,condsd,term)]
    vv[, testwert := round(condval/condsd,2)]
    xx = A[,.(PosRate = round(sum(positiv)*100/sum(getestet),2),
              sumTested = sum(getestet),
              sumPositiv  = sum(positiv),
              MeanNrOfTests=round(mean(getestet),1),
              centerN  = .N),
           keyby=.(tnr,typ,investigation)]
    xx[,tnr := as.factor(tnr)]
    vvv =merge(vv,xx,by='tnr')[order(testwert)]
    vvv[,nr := c(1:.N)]
    #  vvv[,signifikant:= ifelse(nr %in%  c(1:nn),1,0)]
    vvv[,conspicuous:= ifelse(testwert < CutW,1,0)]
    return(vvv[,.(nr,tnr,condval,condsd,term,testwert,conspicuous,typ,
                  investigation,PosRate,sumPositiv,sumTested,MeanNrOfTests,centerN)])
  }
  tt =TestVal(m2,A,CutW)
  uu = tt[,.(N=.N,PosRate=round(sum(sumPositiv)*100/sum(sumTested),2)),.(typ,conspicuous)]
  u1 = tt[,.(N=.N,PosRate=round(sum(sumPositiv)*100/sum(sumTested),2)),.(conspicuous)]
  u1[,typ := 'total']
  uuu = rbind(uu,u1)
  u2 = tt[,.(N=.N,PosRate=round(sum(sumPositiv)*100/sum(sumTested),2)),.(typ)]
  u2[,conspicuous := 'total']
  rbind(uuu,u2)
}
