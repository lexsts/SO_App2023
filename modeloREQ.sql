--SQLSERVER
SELECT 'GuardAppEvent:Start',
'GuardAppEventType:CRQ00000195339',
'GuardAppEventStrValue:Atendimento de requisição';

USE HOP
GO

select * 
into #HOPNEG
from hhopneg (nolock)
where data_neg = '2015-12-18'
and cod_par_neg_inic =  114
and cod_con_invs_inic = 195257

select * from #HOPNEG

select a.* 
  from hhopativ_neg as a (nolock)
 inner join #HOPNEG as b (nolock)
 on b.cod_idt_ativ_neg = a.cod_idt_ativ_neg
 

 
GO
SELECT 'GuardAppEvent:Released';





--ORACLE

select  'GuardAppEvent:Start'
       ,'GuardAppEventType:[Lastro]' 
       ,'GuardAppEventStrValue:Executar Scripts de Consultas' from dual;


--> INSIRA AQUI A QUERY


select  'GuardAppEvent:Released' from dual;
