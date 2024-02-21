

#### Packages 
library(data.table)
library(ggplot2)
library(tidyverse)
if (! require(BenfordTests, quietly =T)) install.packages("BenfordTests")
library(BenfordTests)

### Daten laden
file="../simulated_data.csv"
a1 <- fread(file) %>% mutate( typ=factor(typ),typ=relevel(typ, "Private test center"),typ=relevel(typ, "Pharmacy"))%>% rename(TeststelleNr=tnr,Date=date)



### Method Last digit ####


gl <- function(d) 1/10
digits <- 0:9
df <- data.frame(x = digits, y =gl(digits)) 
lastDigit <- function(x) substr(gsub('', '', x), nchar(gsub('', '', x)), nchar(gsub('', '', x)))
pctLastDigit <- function(x) data.frame(table(lastDigit(x)) / length(x))

a2<-a1 %>% filter(getestet>=10) 

df1 <- pctLastDigit(a2$getestet)



df %>% 
  ggplot(aes(x = factor(x), y = round(y*100,1))) + 
geom_bar(stat = "identity", fill="lightblue", color = "black") +
  xlab("Last figure") + ylab("Percent")+  
  geom_line(data = df1, 
            aes(x = Var1, y = round(Freq*100,1), group = 1), 
            colour = "darkred", 
            size = 1) +
  geom_point(data = df1, 
            aes(x = Var1, y = round(Freq*100,1), group = 1), 
            colour = "black", 
            size = 2, pch = 21, fill = "darkred") +
  theme_minimal() + ylim(0	,15)
  


TestID= unique(a1$TeststelleNr) 

for (i in 1:length(TestID)) {

  a2<- a1[TeststelleNr==TestID[[i]]]
a2 <-a2[getestet>9]

  ## mindestens 30 Meldungen####
  if (length(a2$getestet)>=30){
       chq=chisq.test(table(lastDigit(a2$getestet)))
    } 
    else {
    chq$statistic=-1
    chq$p.value=-1
    }       
  if (i==1) result=c(TestID[[i]],length(a2$getestet),chq$p.value,chq$statistic )
  if (i>1) result=rbind(result,c(TestID[[i]],length(a2$getestet),chq$p.value,chq$statistic))
}

result=as.data.frame(result)


names(result)=c("TeststelleNr","AnzahlMeldungen","getestet_Pwert","getestet_chisq")


result_t=subset(result,getestet_chisq>-1)

result_t=result_t[order(-result_t$getestet_chisq),] 

p90_last<-result_t %>% group_by()%>% summarise(p90 = quantile(getestet_chisq , c(0.9))) 
result_last<-result_t %>% add_column(p90_last)%>% mutate(suspicious_last=ifelse(getestet_chisq>=p90,1,0))

### select 5 mit der größten chisq
result_5max<-result_last %>% arrange(-getestet_chisq)%>% head(5)%>% select(TeststelleNr)%>%pull()
last_5max<-a1 %>% filter(TeststelleNr %in% result_5max & getestet>9) %>%  group_by(TeststelleNr)%>% reframe(last=pctLastDigit(getestet), mean=mean(getestet)) %>% mutate(`Test center ID`=factor(TeststelleNr))

g1<-df %>% 
  ggplot(aes(x = factor(x), y = round(y*100,1))) + 
geom_bar(stat = "identity", fill="lightblue", color = "black") +
  xlab("Last figure") + ylab("Percent")+  
  geom_line(data = last_5max, 
            aes(x =  last$Var1, y = round(last$Freq*100,1), col =  `Test center ID` ,group= `Test center ID` ),  
            size = 1) +
  geom_point(data = last_5max, 
            aes(x = last$Var1, y = round(last$Freq*100,1),col =   `Test center ID` ,group= `Test center ID` ), 
            size = 2, pch = 21, fill = "darkred") +  
  theme_minimal() 
 
g1
 

