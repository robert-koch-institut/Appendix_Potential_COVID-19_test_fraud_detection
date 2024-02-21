

#### Packages 
library(data.table)
library(ggplot2)
library(tidyverse)
if (! require(BenfordTests, quietly =T)) install.packages("BenfordTests")
library(BenfordTests)

### Daten laden
file="../simulated_data.csv"
a1 <- fread(file) %>% mutate( typ=factor(typ),typ=relevel(typ, "Private test center"),typ=relevel(typ, "Pharmacy"))%>% rename(TeststelleNr=tnr,Date=date)


##### Method 1 Deskription


a1 <- a1 %>% filter(getestet>0)
a1 <- a1  %>% mutate(typ_1=factor(as.numeric(typ),levels=c(1,3,2),labels=c("Pharmacy","Doctor's or dentist's office","Private test center")))


per_day<-a1 %>% group_by(TeststelleNr,Date,typ_1)%>% summarise(n=sum(getestet))%>% group_by(TeststelleNr,typ_1)%>% summarise(mean=mean(n))

per_day_m<-per_day %>% group_by(typ_1)%>% summarise(p90 = quantile(mean , c(0.9))) 
per_day<- per_day %>%left_join(per_day_m,by="typ_1")%>% mutate(suspicious_des=ifelse(mean>=p90,1,0))


### Grafik ####
ggplot(per_day, aes(x = mean,  color=typ_1, fill=typ_1)) +
    geom_histogram(   color = "black", size = .3,show.legend = FALSE)  +facet_wrap(typ_1 ~ ., scales = "free") +theme_minimal()+
    geom_vline(aes(xintercept = p90),   color = "black", linetype="dashed", size=1)+  labs( x = "Mean number of tests per day", 
       y = "Number of testcenters")  +
stat_bin(  geom="text", aes(label=ifelse(..count.. > 0, ..count.., "")) , vjust = -1, color = "black", size =3)  
  
  
  

