
select * from Loj_Param_Empresa
Select * into #dados from Loj_Param_Empresa
--01,05,06,07,13,15,16
update #dados set empresa= '16', sat=1
insert into Loj_Param_Empresa
select * from #dados

delete from Loj_CFE_XML_pgto
delete from Loj_CFE_XML_item
delete from Loj_CFE_XML

select CGC_Empresas,* from empresas

select * 
from Loj_CFE_XML
Where Isnull(_TIPO_XML_,'') <> ''

where assinaturaQRCODE like 'KR5%'
order by demi

SELECT * FROM Loj_Cupons_Dados_Cfe
WHERE EMPRESA='13'



