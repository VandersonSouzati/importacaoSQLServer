Set Quoted_Identifier Off
Set Ansi_Nulls ON
Set Ansi_Warnings ON
GO

If Exists(Select 0 from SysObjects where name='SP_Liv_ImpCupons_LivSaida_Prod')
  Drop Procedure dbo.SP_Liv_ImpCupons_LivSaida_Prod
GO
Create Procedure dbo.SP_Liv_ImpCupons_LivSaida_Prod (
  @Empresa Char(02),
  @Data_I SmallDateTime,
  @Data_F SmallDateTime,
  @TipoComerc int,
  @AliqFixa Decimal(16,4)=null,
  @AliqPIS Decimal(16,4),
  @AliqCOFINS Decimal(16,4),
  @TmpCFOp VarChar(20),      
  @CO varChar(5),
  @T01 varChar(05),
  @T02 varChar(05),
  @T03 varChar(05),
  @T04 varChar(05))
As Begin
/************************************************************************************************
  Author:      Rodrigo Consolmagno
  Create Data: 11/09/2013
  Description: Procedure Criada para importaçao do cupom fiscal para o livros de saida, foi 
			   removido o codigo que ficava dentro do fonte do sistema e passado para procedures.		                   
  Alterada em: 08/04/2014 - Marcia - permitir parametro @AliqFixa null			   
  Alterada em: 29/09/2014 - Marcia - valores Porc_Cofins e Vr_Confins estava invertido
  Alterada em: 12/02/2015 - Marcia - verificar Venda_Dev somente do loj_Cupons
  Alterada em: 18/06/2015 - Marcia - alterações referente ao CF-e
*************************************************************************************************/
  Declare @DataIn VarChar(10), @DataFn VarChar(10),@Tipo_Comerc varChar(04),
					@Aliq_Fixa varChar(04), @Aliq_PIS varChar(04),@Aliq_COFINS varChar(04)

  select @DataIn      = Right('0000'+CAST(Year(@Data_I) as varchar),4)+'-'+Right('00'+CAST(Month(@Data_I) as varchar),2)+'-'+Right('00'+CAST(Day(@Data_I) as varchar),2)
  select @DataFn      = Right('0000'+CAST(Year(@Data_F) as varchar),4)+'-'+Right('00'+CAST(Month(@Data_F) as varchar),2)+'-'+Right('00'+CAST(Day(@Data_F) as varchar),2)  

  Select @Tipo_Comerc = CAST(@TipoComerc AS nchar)
  Select @Aliq_Fixa   = cAST(ISNULL(@AliqFixa,0) AS VarChar(20))
  Select @Aliq_PIS    = CAST(@AliqPIS AS nchar) 
  Select @Aliq_COFINS = CAST(@AliqCOFINS AS nchar)  
  
  Delete Liv_SaiProd 
  From Liv_Saidas S
    Inner Join Liv_SaiNatOp N on N.Empresa=S.Empresa and N.Documento=S.Documento and N.Serie=S.Serie
    Inner Join Liv_SaiProd P on P.Empresa=N.Empresa and P.Documento=N.Documento and P.Serie=N.Serie and P.NatOp=N.NatOp and P.Seq=N.Seq
  Where S.Empresa = @Empresa And S.Data_Emissao Between @Data_I and @Data_F and Left(S.Serie,3) = 'ECF' and S.Tipo_Doc = 'CUP'

 SELECT EmpProd, Produto  
 INTO #TmpConsig2  
 FROM CFC_EstoquePadrao  
 WHERE Empresa = @Empresa 
 GROUP BY EmpProd, Produto
 
 Create Table #TmpLiv_SaiProd(
 	  	/*01*/Empresa Char(02) Null, 
		/*02*/Documento Char(06) Null, 
		/*03*/Serie Char(05) Null, 
		/*04*/NatOp Char(05) null, 
		/*05*/Seq char(1) Null, 
		/*06*/EmpProd Char(02) Null, 
		/*07*/Produto Char(06) Null, 
		/*08*/Incremento int Null,  
		/*09*/Qtde Decimal(16,4) Null, 
		/*10*/Peso Decimal(16,4) Null,  
		/*11*/T Char(1) Null, 
		/*12*/Valor_Total Decimal(16,4) Null, 
		/*13*/vr_obs_ipi Decimal(16,4) Null,
		/*14*/ClassFisc Char(15) Null, 
		/*15*/Tipo_Comercializacao int Null, 
		/*16*/Codigo_Grupo int Null,
		/*17*/Vr_Unitario Decimal(19,10) Null,
		/*18*/Vr_BCICMS Decimal(16,4) Null,
		/*19*/ST_ICMS Char(03) Null,
		/*20*/Vr_ICMS Decimal(16,4) Null,
		/*21*/Porc_ICMS Decimal(16,4) Null,
		/*22*/Vr_BCICMS_Subst Decimal(16,4) Null,
		/*23*/Vr_ICMS_Subst Decimal(16,4) Null,
		/*24*/BC_PIS Decimal(16,4) Null,
		/*25*/Porc_PIS Decimal(16,4) Null,
		/*26*/Vr_PIS Decimal(16,4) Null,
		/*27*/ST_PIS Char(3) Null,
		/*28*/BC_COFINS Decimal(16,4) Null,
		/*29*/Porc_COFINS Decimal(16,4) Null,
		/*30*/Vr_COFINS Decimal(16,4) Null,
		/*31*/ST_COFINS Char(3) Null,
		/*32*/Vr_IPI Decimal(16,4) Null,
		/*33*/Vr_BCIPI Decimal(16,4) Null,
		/*34*/IPI Decimal(16,4) Null,
		/*35*/ST_IPI Char(03) Null,
		/*36*/Vr_Desconto Decimal(16,4) Null,
		/*37*/Totalizador_SPED Char(07) Null, 
		/*38*/Unidade Char(04) Null, 
		/*39*/Vr_IPI_Outras Decimal(16,4) Null, 
		/*40*/Vr_IPI_Isento Decimal(16,4) Null, 
		/*41*/Vr_ICMS_Isento Decimal(16,4) Null, 
		/*42*/Vr_ICMS_Outras Decimal(16,4) Null, 
		/*43*/Cod_EAN_GTIN char(14) Null,
		/*44*/Codigo_Produto_Concat Char(60) Null,
		/*45*/Vr_DSF Decimal(16,4) Null,
		/*46*/Vr_DSF2 Decimal(16,4) Null,
		/*47*/COO Char(6) NULL,
		/*48*/Vr_Despesa Decimal(19,10) Null)
/******* Importando os cupons Fiscais ************/  
insert into #TmpLiv_SaiProd
exec('
 SELECT
  /*01*/C.Empresa,
  /*02*/IsNull(M.Reducao,''000000'') Num_Reducao,
  /*03*/''ECF'' + RIGHT(IsNULL(L.Maq_Liv,C.Maquina),2) Serie,
  /*04*/IsNull( ( SELECT Distinct Codigo  FROM Liv_Natureza
	                 WHERE ( Codigo = CASE WHEN CN.Produto is Null THEN LEFT(T.CFOP,1)+''.''+RIGHT(T.CFOP,3) Else LEFT('''+@CO+''',1)+''.''+RIGHT('''+@CO+''',3) END  )
                  AND IsNull(Aliq_ICMS,0) = (CASE WHEN '+@Aliq_Fixa+'=0 THEN IsNull(RTE.Aliq_ImpIFiscal,r.Aliq_ICMS) ELSE '+@Aliq_Fixa+' END)
              ) , '''') CFOP,    
  /*05*/Case when (FP2.Usar_Figura_Fiscal = ''S'') and (IsNull(FP2.Seq_Padrao_FigFisc,'''') <> '''') then FP2.Seq_Padrao_FigFisc else 
			  IsNull( ( SELECT Min(Sequencia)   FROM Liv_Natureza
      					    WHERE ( Codigo = CASE WHEN CN.Produto is Null THEN LEFT(T.CFOP,1)+''.''+RIGHT(T.CFOP,3) Else LEFT('''+@CO+''',1)+''.''+RIGHT('''+@CO+''',3) END  )
						       		AND IsNull(Aliq_ICMS,0) = (CASE WHEN '+@Aliq_Fixa+'=0 THEN IsNull(RTE.Aliq_ImpIFiscal,r.Aliq_ICMS) ELSE '+@Aliq_Fixa+' END) ) , '''') end Sequencia,              
  /*06*/i.Empresa_Produto,
  /*07*/i.Produto,
  /*08*/Null Num_Item,    
  /*09*/i.Quantidade,    
  /*10*/0 Peso,
  /*11*/'''' T,
  /*12*/(i.Sub_Total + IsNull(i.Acrescimo_Rateio,0)) - IsNULL(i.Desconto_Rateio,0) Vr_Total_Item,    
	 /*13*/0 vr_obs_ipi,    
  /*14*/P2.Cod_ClassFisc,
  /*15*/'+@Tipo_Comerc+' Tipo_Comerc,
  /*16*/P2.Grupo_Fiscal,
  /*17*/I.Preco_Unitario,
  /*18*/Case when (CASE WHEN '+@Aliq_Fixa+'=0 THEN IsNull(RTE.Aliq_ImpIFiscal,r.Aliq_ICMS) ELSE '+@Aliq_Fixa+' END) <> 0 then
                  case when Substring(isnull(r.Cod_Impressora, '' ''),1,3) in ('''+@T01+''', '''+@T02+''', '''+@T03+''', '''+@T04+''') then  (i.Sub_Total + IsNull(i.Acrescimo_Rateio,0)) - IsNULL(i.Desconto_Rateio,0)  
                  else 0.00 end
        else 0 end Vr_BC_ICMS,
  /*19*/''''  SitTrib,
  /*20*/case when Substring(isnull(r.Cod_Impressora, '' ''),1,3) in ('''+@T01+''', '''+@T02+''', '''+@T03+''', '''+@T04+''') then
             Round( (CASE WHEN '+@Aliq_Fixa+'=0 THEN IsNull(RTE.Aliq_ImpIFiscal,r.Aliq_ICMS) ELSE '+@Aliq_Fixa+' END) * ( (IsNull(i.Sub_Total,0) + IsNull(i.Acrescimo_Rateio,0)) - IsNULL(i.Desconto_Rateio,0) ) /100 ,2)
          else 0.00 end Vr_ICMS,
  /*21*/CASE WHEN '+@Aliq_Fixa+'=0 THEN IsNull(RTE.Aliq_ImpIFiscal,r.Aliq_ICMS) ELSE '+@Aliq_Fixa+' END Aliq_ICMS, 
	 /*22*/ /*CASE WHEN (SELECT Regime_Trib FROM Empresas WHERE Codigo_Empresas = E.Codigo_Empresas) <> 3 THEN
	           0
	        ELSE (case when Substring(isnull(r.Cod_Impressora, '' ''),1,1) = ''F'' then (i.Sub_Total + IsNull(i.Acrescimo_Rateio,0)) - IsNULL(i.Desconto_Rateio,0)  else 0.00 end) END Vr_BC_ICMS_ST,
		*/ -- Comentado a posição 22 alterado pela modificação do willian. chamado 301784  abaixo - 27-09-2016 - Marcelo Botardo branch[47178]
	 /*22*/ CASE WHEN (SELECT Regime_Trib FROM Empresas WHERE Codigo_Empresas = E.Codigo_Empresas) <> 3 THEN
	           0
	        ELSE (case when Substring(isnull(r.Cod_Impressora, '' ''),1,1) = ''F'' then 
	          (CASE WHEN (('+@Aliq_Fixa+' = 0)and(IsNull(RTE.Aliq_ImpIFiscal,r.Aliq_ICMS)=0)) THEN 0 ELSE 1 END) *( (i.Sub_Total + IsNull(i.Acrescimo_Rateio,0)) - IsNULL(i.Desconto_Rateio,0) )  else 0.00 end) END Vr_BC_ICMS_ST,
	 /*23*/ CASE WHEN (SELECT Regime_Trib FROM Empresas WHERE Codigo_Empresas = E.Codigo_Empresas) <> 3 THEN
	           0
	        ELSE
	           (case when Substring(isnull(r.Cod_Impressora, '' ''),1,1) = ''F'' then
                Round( (CASE WHEN '+@Aliq_Fixa+' = 0 THEN IsNull(RTE.Aliq_ImpIFiscal,r.Aliq_ICMS) ELSE '+@Aliq_Fixa+' END) * ( (IsNull(i.Sub_Total,0) + IsNull(i.Acrescimo_Rateio,0)) - IsNULL(i.Desconto_Rateio,0) ) /100 ,2)
             else 0.00 end) END Vr_ICMS_ST,
	 /* PIS */
  /*24*/(i.Sub_Total + IsNull(i.Acrescimo_Rateio,0)) - IsNULL(i.Desconto_Rateio,0) BC_PIS,
  /*25*/'+@Aliq_PIS+' Porc_PIS,
  /*26*/CASE WHEN '+@Aliq_PIS+' = 0 THEN 0 ELSE round(('+@Aliq_PIS+' * ( (i.Sub_Total + IsNull(i.Acrescimo_Rateio,0)) - IsNULL(i.Desconto_Rateio,0))) / 100,2) END Vr_PIS,
  /*27*/'''' ST_PIS,	
	 /* COFINS */
  /*28*/(i.Sub_Total + IsNull(i.Acrescimo_Rateio,0)) - IsNULL(i.Desconto_Rateio,0) BC_COFINS,
  /*29*/'+@Aliq_COFINS+' Porc_COFINS,
  /*30*/CASE WHEN '+@Aliq_COFINS+' = 0 THEN 0 ELSE round(('+@Aliq_COFINS+' * ( (i.Sub_Total + IsNull(i.Acrescimo_Rateio,0)) - IsNULL(i.Desconto_Rateio,0))) / 100,2) END  Vr_COFINS,
  /*31*/'''' ST_COFINS,
	 /* IPI */
	 /*32*/0.00 BC_IPI,
	 /*33*/0.00 Porc_IPI,
	 /*34*/0.00 Vr_IPI,
	 /*35*/'''' ST_IPI,
	 /*36*/i.Valor_Desconto+i.Desconto_Rateio Vr_Desconto,
	 /*37*/IsNull(r.Totalizador_SPED,'''') Totalizador_SPED,
	 /*38*/IsNULL(i.Unidade_Impressa,''***'') Unidade,
  /*39*/0.00 Vr_IPI_Outras,  
  /*40*/0.00 Vr_IPI_Isento,  
  /*41*/case when Substring(isnull(r.Cod_Impressora, '' ''),1,1) in (''I'',''N'',''R'') then  ( (IsNull(i.Sub_Total,0) + IsNull(i.Acrescimo_Rateio,0)) - IsNULL(i.Desconto_Rateio,0) )  else 0.00 end Vr_ICMS_Isento,
  /*42*/0.00 Vr_ICMS_Outras,    
	 /*43*/IsNull(PEFD.CodBarras,'''') Cod_EAN_GTIN,
	 /*44*/IsNull(i.Codigo_Produto_Concat,'''') Codigo_Produto_Concat,
  /*45*/case when Substring(isnull(r.Cod_Impressora, '' ''),1,1) in (''D'',''S'',''F'') then  ( (IsNull(i.Sub_Total,0) + IsNull(i.Acrescimo_Rateio,0)) - IsNULL(i.Desconto_Rateio,0) )  else 0.00 end Vr_DSF,
  /*46*/case when Substring(isnull(r.Cod_Impressora, '' ''),1,3) in ('''+@T01+''', '''+@T02+''', '''+@T03+''', '''+@T04+''') then  (i.Sub_Total + IsNull(i.Acrescimo_Rateio,0)) - IsNULL(i.Desconto_Rateio,0)  else 0.00 end Vr_DSF2,
  /*47*/C.COO,
  /*48*/ IsNull(i.Acrescimo_Rateio,0) + IsNull(i.Valor_Acrescimo,0) Vr_Despesa
 FROM Loj_Cupons C
	   INNER JOIN Loj_Itens_Cupons I On C.Empresa=I.Empresa AND C.Maquina=I.Maquina AND C.Data=I.Data AND C.Controle=I.Controle
	   INNER Join Fat_ParamEmp2 FP2 on FP2.Empresa = C.Empresa
	   INNER JOIN Empresas E on E.Codigo_Empresas=C.Empresa
	   INNER JOIN Ret_Tributacoes r on r.Codigo = i.tributacao
	   LEFT JOIN Ret_Emp_Tributacoes RTE on RTE.ID_Empresa=E.ID_Empresa and RTE.Cod_Tributacao=R.Codigo
	   LEFT JOIN Cfc_Produtos P On P.Empresa=I.Empresa_Produto AND P.Codigo=I.Produto
	   LEFT JOIN Produtos P2 On P.Empresa=P2.Empresa AND P.Codigo=P2.Codigo
	   LEFT JOIN Cfc_Grade_Tamanho G ON I.Grade_Cupom=G.Codigo and I.Grade_Tam_Cupom=G.Item
	   LEFT JOIN #TmpConsig2 CN On CN.EmpProd=I.Empresa_Produto AND CN.Produto=I.Produto
	   LEFT JOIN '+@TmpCFOP+' T On (T.Divisao=I.Divisao)
	   LEFT JOIN Liv_Maq_Loj L on L.Empresa = c.Empresa AND l.Maq_Loj=c.Maquina
	   LEFT JOIN Loj_Operacoes M On (M.Empresa=C.Empresa And M.Data=C.Data And M.MAquina=C.MAquina And M.Tipo=3 And M.Controle=(Select Max(Controle) from Loj_Operacoes Where Empresa=M.Empresa And Maquina=M.Maquina And Data=M.Data And Tipo=3))
	   LEFT JOIN Clientes_Principal CP on C.Cliente=CP.Codigo_Cliente
	   LEFT JOIN Clientes_Informacoes CI on C.Cliente=CI.Cliente
	   /* Rotina para pegar o codigo barras da tabela concat utilizado para o sped */
	   LEFT JOIN Produtos_Cod_Concat_EFD PEFD on PEFD.Empresa=(Select Empresa_produtos from Liv_Diario where empresa=C.Empresa) and PEFD.Cod_Produto=I.Produto and PEFD.Codigo_Concatenado=i.Codigo_Produto_Concat
	   LEFT JOIN Loj_Param_Empresa LPE on (LPE.Empresa=C.Empresa and LPE.Maquina=C.Maquina)
  WHERE	C.Empresa = '''+@Empresa+''' AND C.Data between '''+@DataIn+''' AND '''+@DataFn+''' AND C.Venda_Dev = ''V''	AND IsNULL(C.Flag,'''')<>'''' AND C.COO is not Null
    and IsNull(C.Cancelado,''N'')=''N'' and IsNull(I.Cancelado,''N'')=''N''  And IsNull(LPE.Sat,0)=0
  ORDER BY C.Empresa, M.Reducao,RIGHT(IsNULL(L.Maq_Liv,C.Maquina),2),
      IsNull( ( SELECT Distinct Codigo  FROM Liv_Natureza
  	            WHERE ( Codigo = CASE WHEN CN.Produto is Null THEN LEFT(T.CFOP,1)+''.''+RIGHT(T.CFOP,3) Else '''+@CO+''' END  )
        	         AND IsNull(Aliq_ICMS,0) = (CASE WHEN '+@Aliq_Fixa+'=0 THEN IsNull(RTE.Aliq_ImpIFiscal,r.Aliq_ICMS) ELSE '+@Aliq_Fixa+' END)  ), ''''),
      IsNull( ( SELECT Min(Sequencia)   FROM Liv_Natureza
	            WHERE ( Codigo = CASE WHEN CN.Produto is Null THEN LEFT(T.CFOP,1)+''.''+RIGHT(T.CFOP,3) Else '''+@CO+''' END  )	         
        	         AND IsNull(Aliq_ICMS,0) = (CASE WHEN '+@Aliq_Fixa+'=0 THEN IsNull(RTE.Aliq_ImpIFiscal,r.Aliq_ICMS) ELSE '+@Aliq_Fixa+' END)  ), '''')
')

  Declare @Emp char(02), @Num_Reducao Char(06), @Serie Char(05), @NatOp Char(05), @Seq Char(01), @Inc int, @Produto Char(06)
  
  Select Top 1 @Emp = Empresa, @Num_Reducao = Documento, @Serie = Serie, @NatOp = NatOp, @Seq = Seq, @Inc = 0 from #TmpLiv_SaiProd 
  
  update #TmpLiv_SaiProd set /*11*/T = dbo.Fnc_Liv_Sit_Trib(EmpProd,Produto,NatOp,Seq,'IPI_Tipo_Trib'),
                             /*19*/ST_ICMS = dbo.Fnc_Liv_Sit_Trib(EmpProd,Produto,NatOp,Seq,'Sit_Trib_ICMS'),
                             /*27*/ST_PIS = dbo.Fnc_Liv_Sit_Trib(EmpProd,Produto,NatOp,Seq,'Sit_Trib_PIS'),
                             /*31*/ST_COFINS = dbo.Fnc_Liv_Sit_Trib(EmpProd,Produto,NatOp,Seq,'Sit_Trib_COFINS'),
                             /*35*/ST_IPI = dbo.Fnc_Liv_Sit_Trib(EmpProd,Produto,NatOp,Seq,'Sit_Trib_IPI'),
                             /*39*/Vr_IPI_Outras = case when dbo.Fnc_Liv_Sit_Trib(EmpProd,Produto,NatOp,Seq,'IPI_Tipo_Trib') = 3 then Valor_Total else 0.00 end,
                             /*40*/Vr_IPI_Isento = case when dbo.Fnc_Liv_Sit_Trib(EmpProd,Produto,NatOp,Seq,'IPI_Tipo_Trib') = 2 then Valor_Total else 0.00 end,
                             /*42*/Vr_ICMS_Outras = case when (IsNull(Porc_ICMS,0) = 0) and (IsNull(Vr_DSF,0) = 0) then Vr_DSF2 else Vr_DSF end,
								   /*Faz o update incremental do campo incremento de cada item respeitando a chamve*/	
                                   @Inc = case when ((Empresa <> @Emp) or (@Num_Reducao <> Documento) or (@Serie <> Serie) or (@NatOp <> NatOp) or (@Seq <> Seq)) 
                                               then 0 else @Inc end+1,  
                                   @Emp = Empresa,                                                  
								   @Num_Reducao = Documento,                                   
								   @Serie = Serie,
								   @NatOp = NatOp,
								   @Seq = Seq,
     /*08*/Incremento = @Inc


  Insert Into Liv_SaiProd(
	  /*01*/Empresa, 
		 /*02*/Documento, 
 		/*03*/Serie,  
		 /*04*/NatOp, 
		 /*05*/Seq, 
		 /*06*/EmpProd,
		 /*07*/Produto, 
		 /*08*/Incremento,  
		 /*09*/Qtde, 
		 /*10*/Peso,  
		 /*11*/T, 
		 /*12*/Valor_Total, 
		 /*13*/vr_obs_ipi,
		 /*14*/ClassFisc,
		 /*15*/Tipo_Comercializacao, 
		 /*16*/Codigo_Grupo,
		 /*17*/Vr_Unitario,
		 /*18*/Vr_BCICMS,
		 /*19*/ST_ICMS,
		 /*20*/Vr_ICMS,
		 /*21*/Porc_ICMS,
		 /*22*/Vr_BCICMS_Subst,
		 /*23*/Vr_ICMS_Subst,
		 /*24*/BC_PIS,
		 /*25*/Porc_PIS,
		 /*26*/Vr_PIS,
		 /*27*/ST_PIS,
		 /*28*/BC_COFINS,
		 /*29*/Vr_COFINS,
		 /*30*/Porc_COFINS,
		 /*31*/ST_COFINS,
		 /*32*/Vr_IPI,
		 /*33*/Vr_BCIPI,
		 /*34*/IPI,
		 /*35*/ST_IPI,
		 /*36*/Vr_Desconto,
		 /*37*/Totalizador_SPED, 
		 /*38*/Unidade, 
		 /*39*/Vr_IPI_Outras, 
		 /*40*/Vr_IPI_Isento, 
		 /*41*/Vr_ICMS_Isento, 
		 /*42*/Vr_ICMS_Outras, 
		 /*43*/Cod_EAN_GTIN,
		 /*44*/Codigo_Produto_Concat,
		 /*45*/COO,
		 /*46*/Id_Liv_ProdutosOrigem,
		 /*47*/Ind_Mov,
		 /*48*/Vr_Despesa)
  Select
   /*01*/Empresa, 
		 /*02*/Documento, 
		 /*03*/Serie, 
		 /*04*/NatOp, 
		 /*05*/Seq, 
		 /*06*/EmpProd, 
		 /*07*/Produto, 
		 /*08*/Incremento,  
		 /*09*/Qtde, 
		 /*10*/Peso,  
		 /*11*/T, 
		 /*12*/Valor_Total, 
		 /*13*/vr_obs_ipi,
		 /*14*/ClassFisc, 
		 /*15*/Tipo_Comercializacao, 
		 /*16*/Codigo_Grupo,
		 /*17*/Vr_Unitario,
		 /*18*/Vr_BCICMS,
		 /*19*/ST_ICMS,
		 /*20*/Vr_ICMS,
		 /*21*/Porc_ICMS,
		 /*22*/Vr_BCICMS_Subst,
		 /*23*/Vr_ICMS_Subst,
		 /*24*/BC_PIS,
		 /*25*/Porc_PIS,
		 /*26*/Vr_PIS,
		 /*27*/ST_PIS,
		 /*28*/BC_COFINS,
		 /*29*/Vr_COFINS,
		 /*30*/Porc_COFINS,
		 /*31*/ST_COFINS,
		 /*32*/Vr_IPI,
		 /*33*/Vr_BCIPI,
		 /*34*/IPI,
		 /*35*/ST_IPI,
		 /*36*/Vr_Desconto,
		 /*37*/Totalizador_SPED, 
		 /*38*/Unidade, 
		 /*39*/Vr_IPI_Outras, 
		 /*40*/Vr_IPI_Isento,
		 /*41*/Vr_ICMS_Isento, 
		 /*42*/Vr_ICMS_Outras, 
		 /*43*/Cod_EAN_GTIN,
		 /*44*/Codigo_Produto_Concat,
		 /*45*/COO,
		 /*46*/CASE WHEN ISNULL((SELECT CC.Id_liv_ProdutosOrigem FROM Produtos_Cod_Concat_EFD CC WHERE CC.Empresa = EmpProd AND CC.Cod_Produto = Produto and CC.Codigo_Concatenado = Codigo_Produto_Concat),'') = '' THEN
		         (SELECT P.Id_Liv_ProdutosOrigem FROM Produtos P WHERE P.Codigo = Produto AND P.Empresa = EmpProd)
		       ELSE
		         (SELECT CC.Id_liv_ProdutosOrigem FROM Produtos_Cod_Concat_EFD CC WHERE CC.Empresa = EmpProd AND CC.Cod_Produto = Produto and CC.Codigo_Concatenado = Codigo_Produto_Concat) --tchelo
		       END,
		 /*47*/'0',
		 /*48*/Vr_Despesa
  From #TmpLiv_SaiProd 
  Group By 	 /*01*/Empresa, 
						 /*02*/Documento, 
 						 /*03*/Serie,  
						 /*04*/NatOp, 
						 /*05*/Seq, 
						 /*06*/EmpProd,
						 /*07*/Produto, 
						 /*08*/Incremento,  
						 /*09*/Qtde, 
						 /*10*/Peso,  
						 /*11*/T, 
						 /*12*/Valor_Total, 
						 /*13*/vr_obs_ipi,
						 /*14*/ClassFisc,
						 /*15*/Tipo_Comercializacao, 
						 /*16*/Codigo_Grupo,
						 /*17*/Vr_Unitario,
						 /*18*/Vr_BCICMS,
						 /*19*/ST_ICMS,
						 /*20*/Vr_ICMS,
						 /*21*/Porc_ICMS,
						 /*22*/Vr_BCICMS_Subst,
						 /*23*/Vr_ICMS_Subst,
						 /*24*/BC_PIS,
						 /*25*/Porc_PIS,
						 /*26*/Vr_PIS,
						 /*27*/ST_PIS,
						 /*28*/BC_COFINS,
						 /*29*/Vr_COFINS,
						 /*30*/Porc_COFINS,
						 /*31*/ST_COFINS,
						 /*32*/Vr_IPI,
						 /*33*/Vr_BCIPI,
						 /*34*/IPI,
						 /*35*/ST_IPI,
						 /*36*/Vr_Desconto,
						 /*37*/Totalizador_SPED, 
						 /*38*/Unidade, 
						 /*39*/Vr_IPI_Outras, 
						 /*40*/Vr_IPI_Isento, 
						 /*41*/Vr_ICMS_Isento, 
						 /*42*/Vr_ICMS_Outras, 
						 /*43*/Cod_EAN_GTIN,
						 /*44*/Codigo_Produto_Concat,
						 /*45*/COO,						 
						 /*48*/Vr_Despesa		
  
 
/******* Importando os cupons Fiscais eletronicos************/
  delete from #TmpLiv_SaiProd

  Insert Into #TmpLiv_SaiProd(
	  	 /*01*/Empresa, 
		 /*02*/Documento, 
 		 /*03*/Serie,  
		 /*04*/NatOp, 
		 /*05*/Seq, 
		 /*06*/EmpProd, 
		 /*07*/Produto, 
		 /*08*/Incremento,  
		 /*09*/Qtde, 
		 /*10*/Peso,  
		 /*11*/T, 
		 /*12*/Valor_Total, 
		 /*13*/vr_obs_ipi,
		 /*14*/ClassFisc, 
		 /*15*/Tipo_Comercializacao, 
		 /*16*/Codigo_Grupo,
		 /*17*/Vr_Unitario,
		 /*18*/Vr_BCICMS,
		 /*19*/ST_ICMS,
		 /*20*/Vr_ICMS,
		 /*21*/Porc_ICMS,
		 /*22*/Vr_BCICMS_Subst,
		 /*23*/Vr_ICMS_Subst,
		 /*24*/BC_PIS,
		 /*25*/Porc_PIS,
		 /*26*/Vr_PIS,
		 /*27*/ST_PIS,
		 /*28*/BC_COFINS,
		 /*29*/Vr_COFINS,
		 /*30*/Porc_COFINS,
		 /*31*/ST_COFINS,
		 /*32*/Vr_IPI,
		 /*33*/Vr_BCIPI,
		 /*34*/IPI,
		 /*35*/ST_IPI,
		 /*36*/Vr_Desconto,
		 /*37*/Totalizador_SPED, 
		 /*38*/Unidade, 
		 /*39*/Vr_IPI_Outras, 
		 /*40*/Vr_IPI_Isento, 
		 /*41*/Vr_ICMS_Isento,
		 /*42*/Vr_ICMS_Outras, 
		 /*43*/Cod_EAN_GTIN,
		 /*44*/Codigo_Produto_Concat,
		 /*45*/COO,
		 /*48*/Vr_Despesa)
  Select
   /*01*/C.Empresa, 
		 /*02*/IsNull(M.Reducao,'000000'),
		 /*03*/'ECF'+ISNULL(SUBSTRING(LM.Maq_Liv,3,2),SUBSTRING(C.Maquina,3,2)),  
		 /*04*/Imp.NatOp, 
		 /*05*/Imp.Seq, 
		 /*06*/LIC.Empresa_Produto, 
		 /*07*/LIC.Produto, 
		 /*08*/NULL,  
		 /*09*/LIC.Quantidade, 
		 /*10*/0 Peso,
		 /*11*/Imp.T, 
		 /*12*/LIC.Sub_Total + IsNull(LIC.Acrescimo_Rateio,0) - IsNULL(LIC.Desconto_Rateio,0) Vr_Total_Item,   
		 /*13*/0 vr_obs_ipi,
		 /*14*/Imp.ClassFisc, 
		 /*15*/LIC.Tipo_Comerc, 
		 /*16*/P2.Grupo_Fiscal,
		 /*17*/LIC.Preco_Unitario,
		 /*18*/Imp.Vr_BCICMS,
		 /*19*/Imp.Trib,
		 /*20*/Imp.Vr_ICMS,
		 /*21*/Imp.Aliq_ICMS,
		 /*22*/Imp.Vr_BCICMS_Subst,
		 /*23*/Imp.Vr_ICMS_Subst,
		 /*24*/Imp.BC_PIS,
		 /*25*/Imp.Porc_PIS,
		 /*26*/Imp.Vr_PIS,
		 /*27*/Imp.ST_PIS,
		 /*28*/Imp.BC_COFINS,
		 /*29*/Imp.Vr_COFINS,
		 /*30*/Imp.Porc_COFINS,
		 /*31*/Imp.ST_COFINS,
		 /*32*/Imp.Valor_IPI,
		 /*33*/Imp.BC_IPI,
		 /*34*/Imp.Aliq_IPI,
		 /*35*/Imp.ST_IPI,
		 /*36*/LIC.Valor_Desconto+LIC.Desconto_Rateio Vr_Desconto,
		 /*37*/'' Totalizador_SPED, 
		 /*38*/LIC.Unidade_Impressa, 
		 /*39*/Imp.Vr_IPI_Outras, 
		 /*40*/Imp.Vr_IPI_Isento, 
		 /*41*/Imp.Vr_ICMS_Isento, 
		 /*42*/Imp.Vr_ICMS_Outras, 
		 /*43*/Imp.Cod_EAN_GTIN,
		 /*44*/Imp.Codigo_Produto_Concat,
		 /*45*/C.COO,
		 /*48*/IsNull(LIC.Acrescimo_Rateio,0) + IsNull(LIC.Valor_Acrescimo,0) Vr_Despesa
    From Loj_Cupons C
    Inner Join Loj_Itens_Cupons_Imposto Imp On (Imp.Empresa=C.Empresa and Imp.Maquina=C.Maquina and Imp.Data=C.Data and Imp.Controle=C.Controle)
    Left Join Loj_Itens_Cupons LIC On (LIC.Empresa=C.Empresa and LIC.Maquina=C.Maquina and LIC.Data=C.Data and LIC.Controle=C.Controle and LIC.Item=Imp.Item)
    Left JOIN Produtos P2 On P2.Empresa=LIC.Empresa_Produto AND P2.Codigo=LIC.Produto
    Left Join Liv_Maq_Loj LM On LM.Empresa = C.Empresa and LM.Maq_loj = C.Maquina
    Left Join Loj_Operacoes M On (M.Empresa=C.Empresa And M.Data=C.Data And M.MAquina=C.MAquina And M.Tipo=3 And M.Controle=(Select Max(Controle) from Loj_Operacoes Where Empresa=M.Empresa And Maquina=M.Maquina And Data=M.Data And Tipo=3))
    Left Join Fat_Parametros_Nat_Oper LNO on (LNO.Empresa = C.Empresa and LNO.N_Oper=Imp.NatOp and LNO.Seq = Imp.Seq)
    Left Join Loj_Param_Empresa LPE on (LPE.Empresa=C.Empresa and LPE.Maquina=C.Maquina)
  Where C.Empresa=@Empresa and C.Data between @DataIn and @DataFn and C.Venda_Dev = 'V' 
        and IsNull(C.Cancelado,'N')='N' And IsNull(C.Flag,'')<>''  And IsNull(LPE.SAT,0)=1

  Select Distinct Empresa, Documento, Serie, NatOp, Seq, EmpProd, Produto 
  into #Tmp_Incremento
  From #TmpLiv_SaiProd
  Order by Empresa,Documento,Serie,NatOp,Seq,EmpProd,Produto

  
  While exists(Select 'x' from #Tmp_Incremento) 
  begin

    Select Top 1 @Emp = Empresa, @Num_Reducao = Documento, @Serie = Serie, @NatOp = NatOp, @Seq = Seq, @Produto=Produto,@Inc = 0 
    from #Tmp_Incremento
    Order by Empresa,Documento,Serie,NatOp,Seq,EmpProd,Produto
  
    
    Update #TmpLiv_SaiProd set /*Faz o update incremental do campo incremento de cada item respeitando a chamve*/	
                            @Inc =  @Inc +1,  
                            /*08*/Incremento = @Inc
    Where Empresa=@Emp and Documento=@Num_Reducao and Serie=@Serie and NatOp=@NatOp and Seq=@Seq and Produto=@Produto

    Delete From #Tmp_Incremento
    Where Empresa=@Emp and Documento=@Num_Reducao and Serie=@Serie and NatOp=@NatOp and Seq=@Seq and Produto=@Produto
        
  end
  
  Insert Into Liv_SaiProd(
	  	 /*01*/Empresa, 
		 /*02*/Documento, 
 		 /*03*/Serie,  
		 /*04*/NatOp, 
		 /*05*/Seq, 
		 /*06*/EmpProd, 
		 /*07*/Produto, 
		 /*08*/Incremento,  
		 /*09*/Qtde, 
		 /*10*/Peso,  
		 /*11*/T, 
		 /*12*/Valor_Total, 
		 /*13*/vr_obs_ipi,
		 /*14*/ClassFisc, 
		 /*15*/Tipo_Comercializacao, 
		 /*16*/Codigo_Grupo,
		 /*17*/Vr_Unitario,
		 /*18*/Vr_BCICMS,
		 /*19*/ST_ICMS,
		 /*20*/Vr_ICMS,
		 /*21*/Porc_ICMS,
		 /*22*/Vr_BCICMS_Subst,
		 /*23*/Vr_ICMS_Subst,
		 /*24*/BC_PIS,
		 /*25*/Porc_PIS,
		 /*26*/Vr_PIS,
		 /*27*/ST_PIS,
		 /*28*/BC_COFINS,
		 /*29*/Vr_COFINS,
		 /*30*/Porc_COFINS,
		 /*31*/ST_COFINS,
		 /*32*/Vr_IPI,
		 /*33*/Vr_BCIPI,
		 /*34*/IPI,
		 /*35*/ST_IPI,
		 /*36*/Vr_Desconto,
		 /*37*/Totalizador_SPED, 
		 /*38*/Unidade, 
		 /*39*/Vr_IPI_Outras, 
		 /*40*/Vr_IPI_Isento, 
		 /*41*/Vr_ICMS_Isento, 
		 /*42*/Vr_ICMS_Outras, 
		 /*43*/Cod_EAN_GTIN,
		 /*44*/Codigo_Produto_Concat,
		 /*45*/COO,
		 /*46*/Id_Liv_ProdutosOrigem,
		 /*47*/ Ind_Mov,
		 /*48*/Vr_Despesa)
  Select /*01*/Empresa, 
		 /*02*/Documento, 
		 /*03*/Serie, 
		 /*04*/NatOp, 
		 /*05*/Seq, 
		 /*06*/EmpProd, 
		 /*07*/Produto, 
		 /*08*/Incremento,  
		 /*09*/Qtde, 
		 /*10*/Peso,  
		 /*11*/T, 
		 /*12*/Valor_Total, 
		 /*13*/vr_obs_ipi,
		 /*14*/ClassFisc, 
		 /*15*/Tipo_Comercializacao, 
		 /*16*/Codigo_Grupo,
		 /*17*/Vr_Unitario,
		 /*18*/Vr_BCICMS,
		 /*19*/ST_ICMS,
		 /*20*/Vr_ICMS,
		 /*21*/Porc_ICMS,
		 /*22*/Vr_BCICMS_Subst,
		 /*23*/Vr_ICMS_Subst,
		 /*24*/BC_PIS,
		 /*25*/Porc_PIS,
		 /*26*/Vr_PIS,
		 /*27*/ST_PIS,
		 /*28*/BC_COFINS,
		 /*29*/Vr_COFINS,
		 /*30*/Porc_COFINS,
		 /*31*/ST_COFINS,
		 /*32*/Vr_IPI,
		 /*33*/Vr_BCIPI,
		 /*34*/IPI,
		 /*35*/ST_IPI,
		 /*36*/Vr_Desconto,
		 /*37*/Totalizador_SPED, 
		 /*38*/Unidade, 
		 /*39*/Vr_IPI_Outras, 
		 /*40*/Vr_IPI_Isento, 
		 /*41*/Vr_ICMS_Isento, 
		 /*42*/Vr_ICMS_Outras, 
		 /*43*/Cod_EAN_GTIN,
		 /*44*/Codigo_Produto_Concat,
		 /*45*/COO,
		 /*46*/CASE WHEN ISNULL((SELECT CC.Id_liv_ProdutosOrigem FROM Produtos_Cod_Concat_EFD CC WHERE CC.Empresa = EmpProd AND CC.Cod_Produto = Produto and CC.Codigo_Concatenado = Codigo_Produto_Concat),'') = '' THEN
		         (SELECT P.Id_Liv_ProdutosOrigem FROM Produtos P WHERE P.Codigo = Produto AND P.Empresa = EmpProd)
		       ELSE
		         (SELECT CC.Id_liv_ProdutosOrigem FROM Produtos_Cod_Concat_EFD CC WHERE CC.Empresa = EmpProd AND CC.Cod_Produto = Produto and CC.Codigo_Concatenado = Codigo_Produto_Concat)
		       END,
		 /*47*/'0',
		 /*48*/Vr_Despesa
  From #TmpLiv_SaiProd 
  Group By /*01*/Empresa, 
					 /*02*/Documento, 
 					 /*03*/Serie,  
					 /*04*/NatOp, 
					 /*05*/Seq, 
					 /*06*/EmpProd,
					 /*07*/Produto, 
					 /*08*/Incremento,  
					 /*09*/Qtde, 
					 /*10*/Peso,  
					 /*11*/T, 
					 /*12*/Valor_Total, 
					 /*13*/vr_obs_ipi,
					 /*14*/ClassFisc,
					 /*15*/Tipo_Comercializacao, 
					 /*16*/Codigo_Grupo,
					 /*17*/Vr_Unitario,
					 /*18*/Vr_BCICMS,
					 /*19*/ST_ICMS,
					 /*20*/Vr_ICMS,
					 /*21*/Porc_ICMS,
					 /*22*/Vr_BCICMS_Subst,
					 /*23*/Vr_ICMS_Subst,
					 /*24*/BC_PIS,
					 /*25*/Porc_PIS,
					 /*26*/Vr_PIS,
					 /*27*/ST_PIS,
					 /*28*/BC_COFINS,
					 /*29*/Vr_COFINS,
					 /*30*/Porc_COFINS,
					 /*31*/ST_COFINS,
					 /*32*/Vr_IPI,
					 /*33*/Vr_BCIPI,
					 /*34*/IPI,
					 /*35*/ST_IPI,
					 /*36*/Vr_Desconto,
					 /*37*/Totalizador_SPED, 
					 /*38*/Unidade, 
					 /*39*/Vr_IPI_Outras, 
					 /*40*/Vr_IPI_Isento, 
					 /*41*/Vr_ICMS_Isento, 
					 /*42*/Vr_ICMS_Outras, 
					 /*43*/Cod_EAN_GTIN,
					 /*44*/Codigo_Produto_Concat,
					 /*45*/COO,					 
					 /*48*/Vr_Despesa

  /*Update para acertar o valor das Naturezas se houver diferença com o total dos itens, esse erro pode acontecer devido a conta da natureza de icms
  ser feita no valor total dos produto(Valor total vezes a aliquota) e nos produto o valor de ICMS ser feito produto a produto(valor total produto vezes aliquota),
  com isso o valor da somatorio depois pode ser diferentes*/
  Update Liv_SaiNatOp  Set
		ICM_BC=P.Vr_BCICMS,
		ICM_Valor=P.Vr_ICMS,
		ICM_Isento= P.Vr_ICMS_Isento,
		ICM_Outras=P.Vr_ICMS_Outras,
		ICM_Subst=P.Vr_ICMS_Subst,
		IPI_BC=P.Vr_BCIPI,
		IPI_Valor=P.Vr_IPI,
		IPI_Isento=P.Vr_IPI_Isento,
		IPI_Outras=P.Vr_IPI_Outras,   
		Vr_Contabil=P.Valor_Total,
  		ICM_Subst_BC=P.Vr_BCICMS_Subst
  FROM Liv_Saidas S
    INNER JOIN Liv_SaiNatOP N on N.Empresa=S.Empresa and N.Documento=S.Documento and N.Serie=S.Serie
    INNER JOIN (Select S1.Empresa,P2.Documento,P2.Serie,P2.NatOp,P2.Seq,SUM(IsNull(P2.Vr_BCICMS,0)) Vr_BCICMS,SUM(IsNull(Vr_ICMS,0)) Vr_ICMS,SUM(IsNull(Vr_ICMS_Isento,0)) Vr_ICMS_Isento,
              SUM(IsNull(Vr_ICMS_Outras,0)) Vr_ICMS_Outras, SUM(IsNull(Vr_ICMS_Subst,0)) Vr_ICMS_Subst,
              SUM(IsNull(Vr_BCIPI,0)) Vr_BCIPI,SUM(IsNull(Vr_IPI,0)) Vr_IPI,SUM(IsNull(Vr_IPI_Isento,0)) Vr_IPI_Isento,SUM(IsNull(Vr_IPI_Outras,0)) Vr_IPI_Outras,
              SUM(IsNull(Valor_Total,0)) Valor_Total,SUM(IsNull(Vr_BCICMS_Subst,0)) Vr_BCICMS_Subst
              FROM  Liv_Saidas S1
              INNER JOIN Liv_SaiProd P2 ON P2.Empresa=S1.Empresa and P2.Documento=S1.Documento and P2.Serie=S1.Serie
              Where S1.Empresa = @Empresa and S1.Data_Emissao Between @Data_I and @Data_F and LEFT(S1.serie,3)='ECF'
              Group By S1.Empresa,P2.Documento,P2.Serie,P2.NatOp,P2.Seq) P
            on P.Empresa=N.Empresa and P.Documento=N.Documento and P.Serie=N.Serie and P.NatOp=N.NatOp and P.Seq=N.Seq
  WHERE S.Empresa = @Empresa and S.Data_Emissao Between @Data_I and @Data_F and LEFT(S.serie,3)='ECF'
     
  Drop Table #TmpLiv_SaiProd   
  Drop Table #TmpConsig2
End
GO