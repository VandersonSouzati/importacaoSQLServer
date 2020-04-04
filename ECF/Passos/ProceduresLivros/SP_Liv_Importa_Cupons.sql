Set Quoted_Identifier Off
Set Ansi_Nulls ON
Set Ansi_Warnings ON
GO

If Exists (Select 'x' from sysobjects where name='SP_Liv_Importa_Cupons')
 drop PROCEDURE dbo.SP_Liv_Importa_Cupons
go
CREATE PROCEDURE dbo.SP_Liv_Importa_Cupons
  @Empresa char(2),
  @DtIni datetime,
  @DtFin datetime,
  @CNPJ_Cliente varchar(18),
  @Usuario int,
  @Aliq_Fixa decimal(16,4)=0,
  @Aliq_PIS decimal(16,4)=0,
  @Aliq_COFINS decimal(16,4)=0,
  @ST_PIS char(02)='',
  @ST_COFINS char(02)='',
  @CO varchar(5),
  @T01 varchar(5), 
  @T02 varchar(5), 
  @T03 varchar(5), 
  @T04 varchar(5),
  @Mod_Dcto int
AS
begin
/*************************************************************************************************
   Criada em: 
  Criada por: 
    Objetivo: Importação dos cupons do SIMLoja para o Livros
 Alterada em: 05/03/2012
Alterada por: Marcia
  Alterações: Importar informação de item cancelado, não importar aliq icms para os serviços
  Alterada em: 10/01/2013
  Alterações: Corrigi para importar corretamente os valores do CRZ e COO_Reducao no Liv_Reducaoz,
              pois estava invertido, desde a versao 1.1 dessa stored procedure.
  Alterada em: 26/08/2013 - cupom com coo 000000 dava erro de FK na hora de inserir os itens.            
  Alterada em: 08/04/2014 - Marcia - permitir parametro @Aliq_Fixa null
  Alterada em: 12/01/2015 - Marcia - verificar somente Venda_Dev do Loj_Cupons
  Alterada em: 18/06/2015 - Marcia - alterações referente ao CF-e 
  Alterada em: 25/09/2015 - Fábio Lima - Alteração no case que retornava o COO ou Incremento (SAT)
  Alterada em: 27/01/2016 - Marcelo Botardo - Alteração na variável @Mod_Dcto em casos de cupons Cfe-Sat
  Alterada em: 02/09/2016 - Marcelo Botardo - Adicionado um LEFT Join com a tabela	Credenciadoras_Cartao
  no momento da inserção da Liv_Cupons_Finalizadores para preencher corretamente o campo CNPJ da Credenciadora
  registro 1600 do SPED FISCAL branch [40815] - Importação de cupons SimLivros
  Credenciadoras_Cartao
  Parâmetros: 
   Variáveis: 
 Observações: 
**************************************************************************************************/

 SELECT EmpProd, Produto
 INTO #TmpConsig2
 FROM CFC_EstoquePadrao
 WHERE Empresa= @Empresa
 GROUP BY EmpProd, Produto

  -- Insere REDUÇÃO
  INSERT INTO Liv_ReducaoZ(Empresa, Maquina, Data, CRO, CRZ, COO_Reducao, Grande_Total, Venda_Bruta,
                           ECF_MOD, ECF_FAB )
  SELECT        
    Lo.EMPRESA,
    IsNull(Lml.Maq_Liv,Lo.Maquina) Maquina,
    Lo.Data,
    Lo.Qtde_Reinicio,
    Lo.Reducao,
    Lo.Operacao,
    Lo.GRANDE_TOTAL,
    Lo.Venda_Bruta,  
    Li.Modelo,
    Li.Numero_Serie
  FROM loj_operacoes Lo
   LEFT JOIN Loj_Impressoras Li on Li.Empresa=Lo.Empresa and Li.Codigo=Lo.Maquina
   LEFT JOIN Liv_Maq_Loj Lml on Lml.Empresa=Lo.Empresa AND Lml.Maq_Loj=Lo.Maquina
  where Lo.Empresa = @Empresa and 
        Lo.Data between @DtIni and @DtFin and 
        Lo.Tipo = 3
        and Not Exists(Select 'X' from Liv_ReducaoZ R where R.Empresa=Lo.Empresa and R.Maquina=IsNull(Lml.Maq_Liv,Lo.Maquina) and R.Data=Lo.Data)
  Group by Lo.Empresa, Lo.Data, Lo.Qtde_Reinicio, Lo.Operacao, Lo.Reducao, Lo.Grande_Total, 
           Lo.Venda_Bruta, Li.Modelo, Li.Numero_Serie, IsNull(Lml.Maq_Liv,Lo.Maquina)

  -- Monta Temp dos CUPONS
  SELECT 
    C.Empresa, 
    Lr.COO_Reducao Documento,   
    'ECF' + RIGHT(IsNULL(L.Maq_Liv,C.Maquina),2) as Serie,
    identity(int,1,1) as Incremento,
    c.Nome_Adquirente,
    c.CPF_CNPJ_Consumidor as CPF_CNPJ,
    CASE WHEN IsNULL(C.Cancelado,'N')='N' THEN 1 ELSE 3 END as Cod_Sit,
    c.Cancelado,
    Lr.CRZ COO_Reducao,
    SUM(c.Valor_Acrescimo) as Valor_Acrescimo,
    IsNULL(Maq_Liv,C.Maquina) as Maquina,
    c.COO as COO_Cupom,
    C.Data, 
    SUM(I.Sub_Total) as Valor_Total,
    SUM(i.Valor_Desconto) as Valor_Desconto_Item,
    c.Valor_Desconto as Valor_Desconto_Cupom,
    E.Numero_Serie,
    E.Modelo,
    Lr.Venda_Bruta,
    Lr.Grande_Total,
    Lr.CRO,
    SUM(i.Preco_Unitario) as Vr_Unitario,
    --@Mod_Dcto COD_MOD,    
	Case when(PE.SAT = 1) then 
			(Select top 1 Cod_Liv_SPED_Modelo_Dcto from Liv_SPED_Modelo_Dcto where Codigo_Modelo = '59') --Feito dessa forma para pegar um documento do tipo SAT tchelo
	else @Mod_Dcto end COD_MOD,
    SAT.Numero_Serie Nr_Sat,
    SUBSTRING(Cfe.ChaveConsulta,4,44) Chave_CFE,
    Cfe.HoraEmissao Data_Cupom,
    C.Maquina Maquina_Cup,
    C.Controle,
    Cfe.ChaveConsulta_Cancelamento,
    Cfe.Hora_Cancelamento 
  INTO #TMP_Cupons
  FROM Loj_Cupons C 
  LEFT JOIN Loj_Itens_Cupons I On C.Empresa=I.Empresa AND C.Maquina=I.Maquina AND C.Data=I.Data AND C.Controle=I.Controle 
  LEFT JOIN Loj_Cupons_Dados_Cfe Cfe On Cfe.Empresa=C.Empresa and Cfe.Maquina=C.Maquina and Cfe.Data=C.Data and Cfe.Controle=C.Controle
  LEFT JOIN Loj_Impressoras SAT on SAT.Empresa = C.Empresa and SAT.Codigo=Cfe.Cod_SAT
  LEFT JOIN Loj_Impressoras E On E.Empresa=C.Empresa AND E.Codigo=C.MAquina 
  Left Join Loj_Param_Empresa PE on(Pe.Empresa = C.Empresa and PE.Maquina = C.Maquina)
  LEFT JOIN Liv_Maq_Loj L on L.Empresa = c.Empresa AND l.Maq_Loj=c.Maquina
  INNER JOIN Liv_ReducaoZ Lr on Lr.Empresa=C.Empresa and Lr.Maquina=IsNull(L.Maq_Liv,C.Maquina) and Lr.Data=C.Data
  WHERE 
    C.Empresa = @Empresa 
    AND C.Data BETWEEN @DtIni AND @DtFin 
    AND IsNull(C.Venda_Dev,'V') = 'V' 
    AND IsNULL(C.Flag,'')<>''
    AND IsNull(C.COO,'')<>'' 
    AND Not Exists(Select 'X' from Liv_Cupons Lc where Lc.Empresa=C.Empresa and Lc.Maquina=IsNull(L.Maq_Liv,C.Maquina) and Lc.COO=C.COO
        and Lc.Documento=Lr.COO_Reducao)
  GROUP BY C.Empresa, C.Maquina, C.Data, C.COO, Lr.COO_Reducao , Lr.CRZ, E.Numero_Serie, E.Modelo, Lr.Venda_Bruta, Lr.Grande_Total,
           Lr.CRO, PE.SAT, L.Maq_Liv, C.Nome_Adquirente, C.CPF_CNPJ_Consumidor, C.Cancelado, c.Valor_Desconto, SAT.Numero_Serie,Cfe.ChaveConsulta,
           Cfe.HoraEmissao, C.Maquina, C.Data, C.Controle,Cfe.ChaveConsulta_Cancelamento,cfe.Hora_Cancelamento

-- select * from #TMP_Cupons

--select * from #TMP_Cupons

  -- Insere Cupons
  INSERT INTO Liv_Cupons (Empresa, Documento, Serie, COO, Maquina, Cod_Sit, CPF_CNPJ, Nome_Adquirente, Cancelado, COD_MOD, Nr_Sat, Chave_CFE, Data_Cupom,
    Chave_CFE_Cancelamento, Data_Cupom_Cancelamento )
  SELECT 
    t.Empresa,
    t.Documento, 
    t.Serie,
    CASE WHEN ISNULL(t.COO_Cupom,'')='000SAT' THEN CAST(t.Incremento AS VARCHAR(6)) ELSE t.COO_Cupom END,
    t.Maquina,
    t.Cod_Sit,
    t.CPF_CNPJ,
    t.Nome_Adquirente,
    t.Cancelado,
    t.COD_MOD,
    t.Nr_Sat,
    t.Chave_CFE,
    t.Data_Cupom,
    t.ChaveConsulta_Cancelamento,
    t.Hora_Cancelamento
  FROM #Tmp_Cupons t
  where t.coo_cupom is not null

-- INSERE ITENS DO CUPOM
/******* Cupom Fiscal - ECF *********/ 
  INSERT INTO Liv_Itens_Cupons ( Empresa, Documento, Serie, COO, Num_Item, Codigo_Produto, Descricao_Produto,
               Qtde, Unidade, Vr_Total_Item, ST_ICMS, CFOP, Vr_BC_ICMS, Vr_ICMS, Aliq_ICMS, Vr_BC_ICMS_ST, 
               Vr_ICMS_ST, BC_PIS, Porc_PIS ,Vr_PIS, ST_PIS, BC_COFINS, Porc_COFINS, Vr_COFINS, ST_COFINS, 
             Vr_Contabil, Vr_Desconto, Vr_Desconto_Rateio, Vr_Acrescimo_Rateio, Vr_INR, Vr_DSF, Vr_Unitario, 
             Totalizador_SPED, Cod_EAN_GTIN, Codigo_Produto_Concat, Cancelado )
  SELECT 
    C.Empresa, 
    --rz.CRZ,
    Lr.COO_Reducao,
    'ECF' + RIGHT(IsNULL(L.Maq_Liv,C.Maquina),2) as Serie,
    C.COO,
    I.Item AS Num_Item, 
    i.Produto, 
    IsNULL(i.Descricao_Impressa,'***'),
    i.Quantidade,
    IsNULL(i.Unidade_Impressa,'***'),
    i.Sub_Total - IsNULL(i.Desconto_Rateio,0) + ISNULL(i.Acrescimo_Rateio,0),
    Substring(p2.Sit_Trib,1,1),	--st_icms
    IsNull( ( SELECT Distinct REPLACE(Codigo,'.','') 
	      FROM Liv_Natureza 
	      WHERE ( replace(Codigo,'.','') = REPLACE( CASE WHEN CN.Produto is Null THEN T.CFOP Else @CO END ,'.','') ) 
        	    AND Aliq_ICMS = (CASE WHEN @Aliq_Fixa is null THEN isnull(re.Aliq_ImpIFiscal,r.Aliq_ICMS) ELSE @Aliq_Fixa END)  ), ''), --  CFOP,

    case when Substring(isnull(isnull(re.cod_Impressora,r.Cod_Impressora), ' '),1,3) in (@T01, @T02, @T03, @T04) then
        i.Sub_Total - IsNULL(i.Desconto_Rateio,0) + ISNULL(i.Acrescimo_Rateio,0) 
    else 0.00 end, -- BC ICMS

    case when Substring(isnull(isnull(re.cod_impressora,r.Cod_Impressora), ' '),1,3) in (@T01, @T02, @T03, @T04) then
             Round( (CASE WHEN @Aliq_Fixa is null THEN isnull(re.Aliq_ImpIFiscal,r.Aliq_ICMS) ELSE @Aliq_Fixa END) * ( IsNull(i.Sub_Total,0) - IsNULL(i.Desconto_Rateio,0)  + ISNULL(i.Acrescimo_Rateio,0)) /100 ,2)
    else 0.00 end, -- ICMS

    CASE WHEN @Aliq_Fixa is null THEN (CASE WHEN IsNull(D.Servico,'N')='N' THEN isnull(re.Aliq_ImpIFiscal,r.Aliq_ICMS) ELSE 0 END ) ELSE @Aliq_Fixa END, -- Aliq_ICMS
    case when Substring(isnull(isnull(re.cod_Impressora,r.Cod_Impressora), ' '),1,3) = 'F' then
      i.Sub_Total - IsNULL(i.Desconto_Rateio,0) + ISNULL(i.Acrescimo_Rateio,0)
    else 0.00 end, -- BC ICMS ST
    case when Substring(isnull(isnull(re.cod_impressora,r.Cod_Impressora), ' '),1,3) = 'F' then
       Round( (CASE WHEN @Aliq_Fixa is null THEN isnull(re.Aliq_ImpIFiscal,r.Aliq_ICMS) ELSE @Aliq_Fixa END) * ( IsNull(i.Sub_Total,0) - IsNULL(i.Desconto_Rateio,0) + ISNULL(i.Acrescimo_Rateio,0) ) /100 ,2)
    else 0.00 end, -- ST
 -- PIS
    i.Sub_Total - IsNULL(i.Desconto_Rateio,0) + ISNULL(i.Acrescimo_Rateio,0), 
    @Aliq_PIS,
    CASE WHEN @Aliq_PIS=0 THEN 0 ELSE round((@Aliq_PIS * ( i.Sub_Total - IsNULL(i.Desconto_Rateio,0) + ISNULL(i.Acrescimo_Rateio,0))) / 100,2) END,     
    @ST_PIS,
 -- PIS  
 -- COFINS
    i.Sub_Total - IsNULL(i.Desconto_Rateio,0) + ISNULL(i.Acrescimo_Rateio,0),  
    @Aliq_COFINS,
    CASE WHEN @Aliq_COFINS=0 THEN 0 ELSE round((@Aliq_COFINS * ( i.Sub_Total - IsNULL(i.Desconto_Rateio,0) + ISNULL(i.Acrescimo_Rateio,0))) / 100,2) END, 
    @ST_COFINS,
 -- COFINS   
    i.Sub_Total - IsNULL(i.Desconto_Rateio,0) + ISNULL(i.Acrescimo_Rateio,0), -- AS Vr_Contabil,
    ISNULL(i.Valor_Desconto,0),
    ISNULL(i.Desconto_Rateio,0),
    ISNULL(i.Acrescimo_Rateio,0), 
    case when Substring(isnull(isnull(re.cod_impressora,r.Cod_Impressora), ' '),1,3) in ('I','N','R') then
           ( IsNull(i.Sub_Total,0) - IsNULL(i.Desconto_Rateio,0) + ISNULL(i.Acrescimo_Rateio,0) )
    else 0.00 end, -- INR
    case when Substring(isnull(isnull(re.cod_impressora,r.Cod_Impressora), ' '),1,3) in ('D','S','F') then
           ( IsNull(i.Sub_Total,0) - IsNULL(i.Desconto_Rateio,0) + ISNULL(i.Acrescimo_Rateio,0) )
    else 0.00 end,  -- DSF
    i.Preco_Unitario,
    IsNull(isnull(re.Totalizador_Sped,r.Totalizador_SPED),''),
	/* Rotina para pegar o codigo barras da tabela concat utilizado para o sped */
    IsNull(PEFD.CodBarras,''),
    IsNull(i.Codigo_Produto_Concat,'') Codigo_Produto_Concat,
    Case when ISNULL(C.Cancelado,'N')='S' then 1
    	When IsNull(I.Cancelado,'N')= 'S' Then 1 Else 0 End
  FROM Loj_Cupons C
  INNER JOIN Loj_Itens_Cupons I On C.Empresa=I.Empresa AND C.Maquina=I.Maquina AND C.Data=I.Data AND C.Controle=I.Controle
  Left Join Loj_Param_Empresa LPE On LPE.Empresa=C.Empresa and LPE.Maquina=C.Maquina
  LEFT JOIN CFC_DIVISOES D ON D.Codigo=I.Divisao
  INNER JOIN Ret_Tributacoes r on r.Codigo = i.tributacao
  LEFT JOIN Cfc_Produtos P On P.Empresa=I.Empresa_Produto AND P.Codigo=I.Produto
  LEFT JOIN Produtos P2 On P.Empresa=P2.Empresa AND P.Codigo=P2.Codigo
  LEFT JOIN Cfc_Grade_Tamanho G ON I.Grade_Cupom=G.Codigo and I.Grade_Tam_Cupom=G.Item  
  LEFT JOIN #TmpConsig2 CN On CN.EmpProd=I.Empresa_Produto AND CN.Produto=I.Produto
  Left Join #TmpCFOP T On (T.Divisao=I.Divisao)
  LEFT JOIN Liv_Maq_Loj L on L.Empresa = c.Empresa AND l.Maq_Loj=c.Maquina
  INNER JOIN Liv_ReducaoZ Lr on C.Empresa=Lr.Empresa and Lr.Maquina=IsNull(L.Maq_Liv,C.Maquina) and C.Data=Lr.Data
  LEFT JOIN Clientes_Principal CP on C.Cliente=CP.Codigo_Cliente
  LEFT JOIN Clientes_Informacoes CI on C.Cliente=CI.Cliente
  LEFT JOIN Empresas E on E.Codigo_Empresas=C.Empresa
  LEFT JOIN Ret_Emp_Tributacoes re on re.ID_Empresa=e.id_empresa and re.Cod_Tributacao=i.tributacao
  LEFT JOIN Produtos_Cod_Concat_EFD PEFD on PEFD.Empresa=(Select Empresa_produto from Liv_Diario where empresa=C.Empresa) and PEFD.Cod_Produto=I.Produto
                                            and PEFD.Codigo_Concatenado=I.Codigo_Produto_Concat  
  WHERE 
	C.Empresa = @Empresa 
	AND C.Data between @DtIni AND @DtFin 
	AND IsNull(C.Venda_Dev,'V') = 'V' 
	AND IsNULL(C.Flag,'')<>''
    AND IsNull(C.COO,'')<>''  AND ISNULL(LPE.SAT,0)=0
    AND Not Exists(Select 'X' from Liv_Itens_Cupons Li where Li.Empresa=C.Empresa and Li.Serie='ECF' + RIGHT(IsNULL(L.Maq_Liv,C.Maquina),2) 
                   and Li.Documento=Lr.COO_Reducao and Li.COO=C.COO)


/******* Cupom Fiscal Eletronico - SAT *********/ 
  INSERT INTO Liv_Itens_Cupons ( Empresa, Documento, Serie, COO, Num_Item, Codigo_Produto, Descricao_Produto,
               Qtde, Unidade, Vr_Total_Item, ST_ICMS, CFOP, Vr_BC_ICMS, Vr_ICMS, Aliq_ICMS, Vr_BC_ICMS_ST, 
               Vr_ICMS_ST, BC_PIS, Porc_PIS ,Vr_PIS, ST_PIS, BC_COFINS, Porc_COFINS, Vr_COFINS, ST_COFINS, 
             Vr_Contabil, Vr_Desconto, Vr_Desconto_Rateio, Vr_Acrescimo_Rateio, Vr_INR, Vr_DSF, Vr_Unitario, 
             Totalizador_SPED, Cod_EAN_GTIN, Codigo_Produto_Concat, Cancelado )
  SELECT 
    C.Empresa, 
    Lr.COO_Reducao,
    'ECF' + RIGHT(IsNULL(L.Maq_Liv,C.Maquina),2) as Serie,
    T.Incremento,
    I.Item AS Num_Item, 
    i.Produto, 
    IsNULL(i.Desc_Prod,'***'),
    i.Quantidade,
    IsNULL(i.Unidade_Impressa,'***'),
    i.Sub_Total - IsNULL(i.Desconto_Rateio,0) + ISNULL(i.Acrescimo_Rateio,0),
    Imp.Trib,	--st_icms
    REPLACE(imp.NatOp,'.',''), --  CFOP,
    Imp.Vr_BCICMS, -- BC ICMS
    Imp.Vr_ICMS, -- ICMS
    Imp.Aliq_ICMS, -- Aliq_ICMS
    Imp.Vr_BCICMS_Subst, -- BC ICMS ST
    Imp.Vr_ICMS_Subst, -- ST
 -- PIS
    Imp.BC_PIS, 
    Imp.Porc_PIS,
    Imp.Vr_PIS,     
    Imp.ST_PIS,
 -- PIS  
 -- COFINS
    Imp.BC_COFINS,  
    Imp.Porc_COFINS,
    Imp.Vr_COFINS, 
    Imp.ST_COFINS,
 -- COFINS   
    i.Sub_Total - IsNULL(i.Desconto_Rateio,0) + ISNULL(i.Acrescimo_Rateio,0), -- AS Vr_Contabil,
    ISNULL(i.Valor_Desconto,0),
    ISNULL(i.Desconto_Rateio,0),
    ISNULL(i.Acrescimo_Rateio,0), 
    Imp.Vr_ICMS_Isento, -- INR
    Imp.Vr_BCICMS_Subst,  -- DSF
    i.Preco_Unitario,
    '',
    IsNull(Imp.Cod_EAN_GTIN,''),
    IsNull(i.Codigo_Produto_Concat,'') Codigo_Produto_Concat,
    Case when ISNULL(C.Cancelado,'N')='S' then 1
    When IsNull(I.Cancelado,'N')= 'S' Then 1 Else 0 End
  FROM Loj_Cupons C
  INNER JOIN Loj_Itens_Cupons I On C.Empresa=I.Empresa AND C.Maquina=I.Maquina AND C.Data=I.Data AND C.Controle=I.Controle
  INNER JOIN Loj_Itens_Cupons_Imposto Imp On (Imp.Empresa=C.Empresa and Imp.Maquina=C.Maquina and Imp.Data=C.Data and Imp.Controle=C.Controle and Imp.Item=I.Item)
  LEFT JOIN #TMP_Cupons T on (T.Empresa=C.Empresa and T.Maquina_Cup=C.Maquina and T.Data=C.Data and T.Controle=C.Controle)
  Left Join Loj_Param_Empresa LPE On LPE.Empresa=C.Empresa and LPE.Maquina=C.Maquina
  LEFT JOIN Liv_Maq_Loj L on L.Empresa = c.Empresa AND l.Maq_Loj=c.Maquina
  INNER JOIN Liv_ReducaoZ Lr on C.Empresa=Lr.Empresa and Lr.Maquina=IsNull(L.Maq_Liv,C.Maquina) and C.Data=Lr.Data
  LEFT JOIN Empresas E on E.Codigo_Empresas=C.Empresa
  WHERE 
	C.Empresa = @Empresa 
	AND C.Data between @DtIni AND @DtFin 
	AND IsNull(C.Venda_Dev,'V') = 'V' 
	AND IsNULL(C.Flag,'')<>''
    AND IsNull(C.COO,'')<>'' AND ISNULL(LPE.SAT,0) = 1
    AND Not Exists(Select 'X' from Liv_Itens_Cupons Li where Li.Empresa=C.Empresa and Li.Serie='ECF' + RIGHT(IsNULL(L.Maq_Liv,C.Maquina),2) 
                   and Li.Documento=Lr.COO_Reducao and Li.COO=C.COO)

  DROP TABLE #TmpConsig2

  -- Importa FINALIZADORES dos cupons
  INSERT INTO Liv_Cupons_Finalizadores(Empresa, Documento, Serie, COO, Cod_Finalizador, Finalizador, Valor, Credito_Debito, CNPJ)
  SELECT 
	c.Empresa,
	R.COO_Reducao as Documento,   
	'ECF' + RIGHT(IsNULL(L.Maq_Liv,C.Maquina),2) as Serie,	
	CASE WHEN ISNULL(t.COO_Cupom,'')='000SAT' THEN CAST(t.Incremento AS VARCHAR(6)) ELSE t.COO_Cupom END,
	f.Finalizador,
	p.Nome_Finalizador,
	f.Valor,
	IsNuLL(CB.Credito_Debito,''),
	IsNull(CB.Cliente_Crediario,'')
	/*Comentado esse trecho para pegar do campo Cliente_Crediario, deve existir o cadastro na tabela clientes_Principal
		Pedido de Janaína Santoandrea - Marcelo Botardo 2016-09-14
	*/
	--IsNull(CC.CNPJ,'')
  FROM Loj_Cupons c
  INNER JOIN Loj_Cupons_Finalizadores f ON c.Empresa = f.Empresa AND c.Maquina = f.Maquina AND c.Data = f.Data AND c.Controle = f.Controle 
  LEFT JOIN #TMP_Cupons T on (T.Empresa=C.Empresa and T.Maquina_Cup=C.Maquina and T.Data=C.Data and T.Controle=C.Controle)
  INNER JOIN Loj_Parametros_Finalizadores p ON p.Empresa = f.Empresa AND p.Maquina = f.Maquina AND p.Cod_Finalizador = f.Finalizador
  LEFT JOIN Liv_Maq_Loj L on L.Empresa = c.Empresa AND l.Maq_Loj=c.Maquina
  INNER JOIN Liv_ReducaoZ R on R.Empresa=C.Empresa and R.Maquina=IsNull(L.Maq_Liv,C.Maquina) and R.Data=C.Data
  LEFT JOIN Cartao_Bandeira CB on CB.ID=Case When ISNull(p.id_grupo_Cartao_bandeira,0)<>0 then (Select top 1 CGI.ID_Cartao_Bandeira From Cfc_Grupo_Cartao_Bandeira_Itens CGI where CGI.id=P.id_grupo_Cartao_bandeira) else (p.ID_Cartao_Bandeira) End
  /*Trocado este join do Cartao_bandeira pois foi agora existe tambem a tabela de grupo de cartao bandeira*/
  --LEFT JOIN Cartao_Bandeira CB on CB.ID=p.ID_Cartao_Bandeira
  /*Comentado esse trecho para pegar do campo Cliente_Crediario, deve existir o cadastro na tabela clientes_Principal*/
  --LEFT JOIN Credenciadoras_Cartao CC on CB.ID_Credenciadora_Cartao = CC.ID 
  WHERE 
	C.Empresa = @Empresa 
	AND C.Data between @DtIni AND @DtFin 
	AND C.Venda_Dev = 'V' 
	AND IsNULL(C.Flag,'')<>''
    AND IsNull(C.COO,'')<>''
    AND Not Exists(Select 'X' from Liv_Cupons_Finalizadores Lf where Lf.Empresa=C.Empresa and Lf.Documento=R.COO_Reducao and 
                   Lf.Serie='ECF' + RIGHT(IsNULL(L.Maq_Liv,C.Maquina),2) and LF.COO=C.COO)
    AND Exists (Select 'X' From Loj_Itens_Cupons i  Where i.Empresa=C.Empresa and i.Maquina=C.Maquina and i.Data=C.Data and 
                   i.Controle=C.Controle)
end
GO