If Object_Id('TEMPDB..#DadosProdutos') Is Not Null 
Drop Table #DadosProdutos

Select 
c.*
into #DadosProdutos
From Loj_ECF_E15 C


Update #DadosProdutos set CodigoProduto = 
    Case When Len(CodigoProduto) < 6
    Then REPLICATE('0', 6 - LEN(codigoProduto)) +   RTrim(codigoProduto)
	Else Substring(codigoProduto,1,6)
	End


 
--- INSERE NOVOS PRODUTOS 
SELECT DISTINCT * from #DadosProdutos c
where not exists (select 'y' from produtos y where y.codigo = codigoProduto )
  

INSERT INTO PRODUTOS (CODIGO,UNIDADE,COD_CLASSFISC,EMPRESA,GRUPO_FISCAL,Id_Liv_ProdutosOrigem,DESCRICAO,SIT_TRIB)
SELECT 
Distinct
C.CodigoProduto,
'UN' AS UNIDADE,
'7117.19.00' AS COD_CLASSFISC,--Verificar
'01' AS EMPRESA,
'2',
'1',
c.DescricaoProduto AS DESCRICAO,
'0' AS SIT_TRIB
FROM #DadosProdutos c
left join produtos p on p.codigo = c.CodigoProduto
--where CPROD IS NOT NULL AND
 where not exists (select 'y' from produtos y where y.codigo = codigoProduto)

-----INSERE PRODUTOS FISCAIS
INSERT INTO PRODUTOS_COD_CONCAT_EFD(EMPRESA, COD_PRODUTO, CODIGO_CONCATENADO, Tipo_Item, Descricao, Unidade, ClassFisc, Genero, ID_LIV_PRODUTOSORIGEM)
select DISTINCT 
d.Empresa, D.CODIGO, D.CODIGO, g.Tipo_Item,D.Descricao, D.unidade, D.COD_ClassFisc, SUBSTRING(D.COD_ClassFisc,1,2), D.Id_Liv_ProdutosOrigem
from PRODUTOS D
    inner join Fig_GrupoFiscal g on (g.Codigo = D.Grupo_Fiscal)
where  Not exists (select 'x' from Produtos_Cod_Concat_EFD x where D.Empresa=x.Empresa and D.CODIGO = x.CODIGO_CONCATENADO) 





