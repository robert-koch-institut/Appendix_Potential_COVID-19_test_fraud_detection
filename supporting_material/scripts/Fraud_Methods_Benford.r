

#### Packages 
library(data.table)
library(ggplot2)
library(tidyverse)
if (! require(BenfordTests, quietly =T)) install.packages("BenfordTests")
library(BenfordTests)

### Daten laden
file="../simulated_data.csv"
a1 <- fread(file) %>% mutate( typ=factor(typ),typ=relevel(typ, "Private test center"),typ=relevel(typ, "Pharmacy"))%>% rename(TeststelleNr=tnr,Date=date)



### Method  Benford####

benlaw <- function(d) log10(1 + 1 / d)
digits <- 1:9
df <- data.frame(x = digits, y = benlaw(digits)) 
firstDigit <- function(x) substr(gsub('[0.]', '', x), 1, 1)
pctFirstDigit <- function(x) data.frame(table(firstDigit(x)) / length(x))
df1 <- pctFirstDigit(a1$getestet)

df %>% 
  ggplot(aes(x = factor(x), y = round(y*100,1))) + 
  geom_bar(stat = "identity", fill="lightblue", color = "black")+  geom_text(aes(label = round(y*100,1)), vjust = 1.5, colour = "white")  +
  xlab("Leading Figure") + ylab("Percent") +
  geom_line(data = df1, 
            aes(x = Var1, y = round(Freq*100,1), group = 1), 
            colour = "darkred", 
            size = 1) +
  geom_point(data = df1, 
            aes(x = Var1, y = round(Freq*100,1), group = 1), 
            colour = "black", 
            size = 2, pch = 21, fill = "darkred") +
  theme_minimal()   +
  NULL



TestID= unique(a1$TeststelleNr) 
i=3
for (i in 1:length(TestID)) {

  a2 = a1[TeststelleNr==TestID[[i]]]

  ## mindestens 30 Meldungen####
  if (length(a2$getestet)>=30){
    chq=chisq.benftest(a2$getestet,pvalmethod ="simulate")
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

result1=result_t[order(-result_t$getestet_chisq),] 

p90_ben<-result_t %>% group_by()%>% summarise(p90 = quantile(getestet_chisq , c(0.9))) 
result_ben<-result_t %>% add_column(p90_ben)%>% mutate(suspicious_ben=ifelse(getestet_chisq>=p90,1,0))

### select 5 mit der größten chisq
result_5max<-result_ben %>% arrange(-getestet_chisq)%>% head(5)%>% select(TeststelleNr)%>%pull()

ben_5max<-a1 %>% filter(TeststelleNr %in% result_5max) %>%  group_by(TeststelleNr)%>% reframe(ben=pctFirstDigit(getestet)) 
 

df %>% 
  ggplot(aes(x = factor(x), y = round(y*100,1))) + 
  geom_bar(stat = "identity", fill="lightblue", color = "black")+  geom_text(aes(label = round(y*100,1)), vjust = 1.5, colour = "white")  +
  xlab("Leading Figure") + ylab("Percent") +
  geom_line(data = ben_5max, 
            aes(x =  ben$Var1, y = round(ben$Freq*100,1), col =  factor (TeststelleNr),group=factor (TeststelleNr)),  
            size = 1) +
  geom_point(data = ben_5max, 
            aes(x = ben$Var1, y = round(ben$Freq*100,1),col =  factor (TeststelleNr),group=factor (TeststelleNr)), 
            size = 2, pch = 21, fill = "darkred") +
  theme_minimal()   +
  NULL



