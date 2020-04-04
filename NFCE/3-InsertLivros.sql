
--DROP TABLE NFCE

------- mudar empresa
declare @emp char(02)
set @emp = '08'

alter table ImpLiv_Saidas alter column serie char(02)
alter table ImpLiv_SaiProd alter column serie char(02)

if OBJECT_ID('tempdb..#TOTAIS_CUPONS') is not null
drop table #TOTAIS_CUPONS


SELECT 
 I.EMPRESA,I.DOCUMENTO,I.SERIE, SUM(QTDE) AS QTDE, 
 SUM(VR_TOTAL_ITEM) AS VALOR_NOTA, SUM(VR_DESCONTO) AS VR_DESCONTO, sum(Vr_BC_ICMS) as bc_icms, sum(vr_icms) as vr_icms,
 sum(cast(vr_bc_icms_st as decimal(16,4))) as vr_bc_icms_st, 
 sum(cast(vr_icms_st as decimal(16,4)) ) as vr_icms_st, 
 sum(vr_pis) as vr_pis, 
 sum(vr_cofins) as vr_cofins, sum(vr_contabil) as vr_contabil, sum(bc_pis) as bc_pis, sum(bc_cofins) as bc_cofins
INTO #TOTAIS_CUPONS
FROM ImpLiv_SaiProd I
where i.Empresa = @emp
GROUP BY I.EMPRESA,I.DOCUMENTO,I.SERIE



INSERT INTO Liv_Saidas (
EMPRESA,
DOCUMENTO,
SERIE,
CLIENTE,
TIPO_DOC,
Data_Emissao,
Valor_Nota,
Link_CR,
Emp_Origem,
Data_Hora,
COD_SIT,
Finalidade_NF,
Tipo_Parcela,
IND_EMIT,
Tipo_Frete,
Chave_NFe,
Valor_Frete,
Valor_Desconto,
Valor_Seguro,
Valor_Outras_Despesas,
Vr_Tot_DescProd,
Vr_DescontoGeral,
Ind_Pres,
COD_MOD
)

SELECT DISTINCT 
C.EMPRESA,
C.DOCUMENTO,
'1' AS SERIE,
C.CPF_CNPJ AS CLIENTE,
'NFCE' AS TIPO_DOC,
DATA_CUPOM AS Data_Emissao,
T.VALOR_NOTA AS Valor_Nota,
'0' AS Link_CR,
C.EMPRESA AS Emp_Origem,
DATA_CUPOM AS Data_Hora,
'1' AS COD_SIT,
'1' AS Finalidade_NF,
'9' AS Tipo_Parcela,
'0' AS IND_EMIT,
'9' AS Tipo_Frete,
CHAVE_CFE AS Chave_NFe,
'0' AS Valor_Frete,
T.VR_DESCONTO AS Valor_Desconto,
'0' AS Valor_Seguro,
'0' AS Valor_Outras_Despesas,
T. VR_DESCONTO AS Vr_Tot_DescProd,
T.VR_DESCONTO AS Vr_DescontoGeral,
'0' AS Ind_Pres,
'32' AS COD_MOD
FROM ImpLiv_Saidas C
INNER JOIN #TOTAIS_CUPONS T
ON T.EMPRESA = C.EMPRESA AND T.DOCUMENTO = C.DOCUMENTO AND T.SERIE = C.SERIE
WHERE NOT EXISTS (SELECT 'X' FROM LIV_SAIDAS X WHERE X.EMPRESA = C.EMPRESA AND X.DOCUMENTO = C.DOCUMENTO AND X.SERIE = C.SERIE)
AND C.EMPRESA = @emp


insert into liv_sainatop (
empresa,
documento,
serie,
natop,
seq,
icm_bc,
icm_porc,
icm_valor,
icm_isento,
icm_outras,
icm_subst,
ipi_bc,
ipi_valor,
ipi_isento,
ipi_outras,
vr_contabil,
icm_subst_bc)

select distinct 
t.empresa,
t.documento,
t.serie as serie,
'5.102' as natop,
'1' as seq,
bc_icms as icm_bc,
( Select Top 1 i.aliq_icms From ImpLiv_SaiProd i  Where i.empresa = t.empresa and i.documento = t.documento and i.serie = t.serie) as aliq_icms,
t.vr_icms,
'0' as icm_isento,
'0' as icms_outras,
t.vr_icms_st as icm_subst,
'0' as ipi_bc,
'0' as ipi_valor,
'0' as ipi_isento,
valor_nota as ipi_outras,
valor_nota as vr_contabil,
t.vr_bc_icms_st as icm_subst_bc
from  #TOTAIS_CUPONS t
where t.empresa = @emp
And Not Exists(Select 'x' From Liv_SaiNatOp O Where O.Empresa = T.Empresa And O.Documento = T.Documento and O.Serie = T.Serie)

INSERT INTO LIV_SAIPROD (
EMPRESA,
DOCUMENTO,
SERIE,
NATOP,
SEQ,
EmpProd,
PRODUTO,
INCREMENTO,
Codigo_Produto_Concat,
qtde,
CLASSFISC,
T,
Valor_Total,
Vr_Unitario,
Vr_Desconto,
Vr_Despesa,
Vr_IPI,
Vr_Frete,
Vr_Seguro,
Tipo_Comercializacao,
Codigo_Grupo,
VR_ICMS,
Vr_BCICMS,
Vr_BCIPI,
Vr_BCICMS_Subst, 
Vr_ICMS_Subst,
Porc_PIS,
Porc_ICMS,
Vr_PIS,
Porc_COFINS,
Vr_COFINS,
ST_ICMS,
ST_IPI,
ST_PIS,
ST_COFINS,
Vr_IPI_Isento,
Vr_IPI_Outras,
Vr_ICMS_Isento,
Vr_ICMS_Outras,
BC_PIS,
BC_COFINS,
Descricao_Produto_Concat,
Unidade,
Ind_Mov,
Id_Liv_ProdutosOrigem,
COO)

SELECT
S.EMPRESA,
S.DOCUMENTO,
S.SERIE,
'5.102' as NATOP,
'1' AS SEQ,
'01' AS EmpProd,
I.CODIGO_PRODUTO AS PRODUTO,
nitem AS INCREMENTO,
i.codigo_produto as codigo_produto_concat,
QTDE,
E.CLASSFISC AS CLASSFISC,
'3' AS T,
VR_TOTAL_ITEM AS Valor_Total,
VR_UNITARIO AS Vr_Unitario,
Vr_Desconto,
'0' Vr_Despesa,
'0' AS Vr_IPI,
'0' AS Vr_Frete,
'0' AS Vr_Seguro,
'1' AS Tipo_Comercializacao,
GRUPO_FISCAL AS Codigo_Grupo,
VR_ICMS,
VR_BC_ICMS AS Vr_BCICMS,
'0' AS Vr_BCIPI,
'0' AS Vr_BCICMS_Subst, 
'0' AS Vr_ICMS_Subst,
Porc_PIS,
ALIQ_icms as Porc_ICMS,
Vr_PIS,
Porc_COFINS,
Vr_COFINS,
ST_ICMS,
'53' as ST_IPI,
ST_PIS,
ST_COFINS,
'0' as Vr_IPI_Isento,
VR_TOTAL_ITEM  as Vr_IPI_Outras,
'0' Vr_ICMS_Isento,
case when i.vr_icms > '0' then 0 
when i.vr_icms = 0 then vr_total_item
end Vr_ICMS_Outras,
BC_PIS,
BC_COFINS,
e.descricao as Descricao_Produto_Concat,
i.Unidade,
'0' as Ind_Mov,
e.Id_Liv_ProdutosOrigem,
i.COO
from ImpLiv_SaiProd i
inner join produtos_cod_concat_efd e
on e.Cod_Produto = i.Codigo_Produto
inner join produtos pr
on pr.codigo = i.Codigo_Produto
inner join liv_saidas s
on s.empresa = i.empresa and s.documento = i.documento and s.serie = i.serie
where not exists (select 'x' from liv_saiprod x where x.empresa = s.empresa and x.documento = s.documento and x.serie = s.serie)
and s.empresa = @emp


if object_id('dados3') is not null
drop table dados3

select 
distinct 
id,
@emp  empresa, 
Right('000000'+cast(cNF as varchar(06)) ,6) As documento ,
'1' serie,
INFCPL descricao
into dados3
from nfce

Insert Into Liv_SaiObs (
Cod_Liv_SaiObs, 
Empresa, 
Documento,
Serie,
Descricao
)
select 
distinct 
(Select max(cod_liv_saiobs)+1 from Liv_SaiObs)+ row_number() over(order by id ) Cod_Liv_saiobs,
@Emp empresa, 
d.documento,
'1' serie,
Descricao
--into dados3
from dados3 d
 inner join liv_saidas s on s.empresa = d.empresa and s.documento = d.documento and s.serie = d.serie 
 where not exists (Select 'x' from liv_SaiObs o Where O.Empresa = d.empresa and O.documento = d.documento and o.serie = d.serie)





