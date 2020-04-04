If Object_Id('TEMPDB..#DadosProdutos') Is Not Null 
Drop Table #DadosProdutos

Select 
C.Empresa As EMP,
I.*
into #DadosProdutos
From loJ_cfe_xml C
INNER JOIN loJ_cfe_xml_ITEM I ON I.FK_Loj_CFE_XML = C.ID


 
 
--- INSERE NOVOS PRODUTOS 
SELECT DISTINCT CPROD,XPROD,NCM,UCOM from #DadosProdutos c
where not exists (select 'y' from produtos y where y.codigo = REPLICATE('0', 6 - LEN(CPROD)) + RTrim(CPROD) )
  

INSERT INTO PRODUTOS (CODIGO,UNIDADE,COD_CLASSFISC,EMPRESA,GRUPO_FISCAL,Id_Liv_ProdutosOrigem,DESCRICAO,SIT_TRIB)
SELECT 
Distinct
REPLICATE('0', 6 - LEN(CPROD)) + RTrim(CPROD)  AS CODIGO,
UCOM AS UNIDADE,
SUBSTRING(NCM,1,4)+'.'+SUBSTRING(NCM,5,2)+'.'+SUBSTRING(NCM,7,2) AS COD_CLASSFISC,
'01' AS EMPRESA,
'2',
'1',
SUBSTRING(XPROD,1,50) AS DESCRICAO,
'0' AS SIT_TRIB
FROM #DadosProdutos c
where CPROD IS NOT NULL AND
 not exists (select 'y' from produtos y where y.codigo = REPLICATE('0', 6 - LEN(CPROD)) + RTrim(CPROD))

-----INSERE PRODUTOS FISCAIS
INSERT INTO PRODUTOS_COD_CONCAT_EFD(EMPRESA, COD_PRODUTO, CODIGO_CONCATENADO, Tipo_Item, Descricao, Unidade, ClassFisc, Genero, ID_LIV_PRODUTOSORIGEM)
select DISTINCT 
d.Empresa, D.CODIGO, D.CODIGO, g.Tipo_Item,D.Descricao, D.unidade, D.COD_ClassFisc, SUBSTRING(D.COD_ClassFisc,1,2), D.Id_Liv_ProdutosOrigem
from PRODUTOS D
    inner join Fig_GrupoFiscal g on (g.Codigo = D.Grupo_Fiscal)
where  Not exists (select 'x' from Produtos_Cod_Concat_EFD x where D.Empresa=x.Empresa and D.CODIGO = x.CODIGO_CONCATENADO) 




 /*
UPDATE #DadosProdutos SET EMP =  REPLICATE('0', 14 - LEN(EMP)) + RTrim(EMP)

UPDATE #DadosProdutos SET EMP = SUBSTRING(EMP,1,2)+'.'+SUBSTRING(EMP,3,3)+'.'+SUBSTRING(EMP,6,3)+'/'+SUBSTRING(EMP,9,4)+'-'+SUBSTRING(EMP,13,2)

 UPDATE #DadosProdutos SET ST_PIS = '01', ST_COFINS = '01' , PPIS = '0.65', PCOFINS = '3.00', Vbcpis = VITEM, vBCcofins = VITEM, VPIS = ROUND(VITEM*'0.0065',2), VCOFINS = ROUND(VITEM*'0.03',2)
 FROM #DadosProdutos C
 INNER JOIN EMPRESAS E
 ON E.CGC_EMPRESAS = C.EMP
 WHERE Regime_Trib NOT IN ( '1') AND VICMS > 0

  UPDATE #DadosProdutos SET ST_PIS = '99', ST_COFINS = '99' , PPIS = '0', PCOFINS = '0', Vbcpis = '0', vBCcofins = '0', VPIS = '0', VCOFINS = '0', VICMS = '0', PICMS = '0'
 FROM #DadosProdutos C
 INNER JOIN EMPRESAS E
 ON E.CGC_EMPRESAS = C.EMP
 WHERE Regime_Trib  IN ( '1') 
*/

