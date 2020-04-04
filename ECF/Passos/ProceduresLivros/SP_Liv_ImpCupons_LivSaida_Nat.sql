Set Quoted_Identifier Off
Set Ansi_Nulls ON
Set Ansi_Warnings ON
GO

If Exists(Select 0 from SysObjects where name='SP_Liv_ImpCupons_LivSaida_Nat')
  Drop Procedure dbo.SP_Liv_ImpCupons_LivSaida_Nat
GO
Create Procedure dbo.SP_Liv_ImpCupons_LivSaida_Nat (
  @Empresa Char(02),
  @Data_I SmallDateTime,
  @Data_F SmallDateTime,
  @AliqFixa Decimal(16,4)=null,
  @TmpCFOp VarChar(20),
  @CO varChar(5))
As Begin
/************************************************************************************************
  Author:      Rodrigo Consolmagno
  Create Data: 11/09/2013
  Description: Procedure Criada para importaçao do cupom fiscal para o livros de saida, foi 
			   removido o codigo que ficava dentro do fonte do sistema e passado para procedures.	
  Alterada em: 08/04/2014 - Marcia - permitir @AliqFixa null /gerar Base ST e valor ST zerados			   	                   
  Alterada em: 12/02/2015 - Marcia - verificar Venda_Dev somente do loj_Cupons
  Alterada em: 17/06/2015 - Marcia - alterações referente ao CF-e
  Alterada em: 10/09/2015 - Fábio Lima - postagem segundo orientações do chamado
  
   Alterado em: 28/03/2016
  Alterado por: Lucas Rosseto
     Alteração: Alterado a Rotina que estava Comentado para pegar a Sequencia Padrão quando se Usa Figura Fiscal
                e Caso a Sequencia Padrão esteja vazio irá pegar a Menor Sequencia da Natureza de Operacao
                e Caso não Utiliza Figura Fiscal irá manter a Forma Antiga
                Conforme Conversa com Isaac e Janaina SantoAndrea

  Alterado me: 30/03/2016
 Alterado por: Lucas Rosseto
    Alteração: Alterado para Pegar a Maior Aliquota da Venda quando é Utilizado a Figura Fiscal, pois conforme o Isaac me
                passou na Tabela Liv_SaiNatOP não Importa a Tributação para agrupar por tributação, já existe chamado para
                ele retirar este campo, portanto eu mudei a procedure para Somar os valores de Base e de Imposto pegando sempre
                a Maior Aliquota do Item. Nos Itens que é necessário ter o Agrupamento pela aliquota, pois o Speed pega da tabela
                Liv_SaiProd

	 Alterado em: 08-06-2017
	Alterado Por: Marcelo Botardo
	   Alteração: Alterado update da Sequência, condição estava errada. Quando o Cliente não usa Figura Fiscao Sequencia padrão está em Branco, ele pega sequencia errada
     
*************************************************************************************************/
   Declare @DataIn VarChar(10), @DataFn VarChar(10)
  
   Delete Liv_SaiProd 
   From Liv_Saidas S
    Inner Join Liv_SaiNatOp N on N.Empresa=S.Empresa and N.Documento=S.Documento and N.Serie=S.Serie
    Inner Join Liv_SaiProd P on P.Empresa=N.Empresa and P.Documento=N.Documento and P.Serie=N.Serie and P.NatOp=N.NatOp and P.Seq=N.Seq
  Where S.Empresa = @Empresa And S.Data_Emissao Between @Data_I and @Data_F and Left(S.Serie,3) = 'ECF' and S.Tipo_Doc = 'CUP'

  Delete Liv_SaiNatOP 
   From Liv_Saidas S
    Inner Join Liv_SaiNatOp N on N.Empresa=S.Empresa and N.Documento=S.Documento and N.Serie=S.Serie 
  Where S.Empresa = @Empresa And S.Data_Emissao Between @Data_I and @Data_F and Left(S.Serie,3) = 'ECF' and S.Tipo_Doc = 'CUP'

  Select EmpProd, Produto
  Into #TmpConsig2
  From CFC_EstoquePadrao
  Where Empresa = @Empresa
  Group By EmpProd, Produto
  
  select @DataIn = Right('0000'+CAST(Year(@Data_I) as varchar),4)+'-'+Right('00'+CAST(Month(@Data_I) as varchar),2)+'-'+Right('00'+CAST(Day(@Data_I) as varchar),2)
  select @DataFn = Right('0000'+CAST(Year(@Data_F) as varchar),4)+'-'+Right('00'+CAST(Month(@Data_F) as varchar),2)+'-'+Right('00'+CAST(Day(@Data_F) as varchar),2)  

  Create Table #Temp (Empresa Char(02) Null,Maquina Char(04) Null,Data SmallDateTime Null,Controle Int Null, Item Int Null, Num_Reducao Char(06) Null, Divisao varChar(05) Null,
                      Tributacao Char(03) Null, Empresa_Produto Char(02) Null,Produto Char(06) Null, Cod_ClassFisc Char(15) Null,Quantidade Decimal(16,4) Null,Total Decimal(16,4) Null, 
                      Valor_Desconto Decimal(16,4) Null, Valor_Desconto_Rateado Decimal(16,4) Null,Valor_Acrescimo Decimal(16,4) Null,Valor_Acrescimo_Rateado Decimal(16,4) Null,
                      Aliq_ICMS Decimal(16,4) Null, VrTotCompra Decimal(16,4) Null)


  
/******* Importando os cupons Fiscais ************/  
Insert into #Temp
Exec('
  Select C.Empresa, C.Maquina, C.Data, C.Controle, I.Item, IsNull(M.Reducao,''000000'') Num_Reducao, Case When CN.Produto is Null Then T.CFOP Else '''+@CO+''' End Divisao, I.Tributacao, I.Empresa_Produto, P.Codigo Produto, P2.Cod_ClassFisc, Sum(I.Quantidade) Quantidade,
         Sum(I.Sub_Total) Total, C.Valor_Desconto, 0*C.Valor_Desconto Valor_Desconto_Rateado, C.Valor_Acrescimo, 0*C.Valor_Acrescimo Valor_Acrescimo_Rateado,IsNull(RTE.Aliq_ImpIFiscal,RT.Aliq_ICMS) Aliq_ICMS,
        (SELECT SUM(IT.Sub_Total) FROM Loj_Itens_Cupons IT WHERE C.Empresa = IT.Empresa and C.Maquina = IT.Maquina and C.Data = IT.Data and C.Controle = IT.Controle AND IsNull(IT.Cancelado,''N'')=''N'') VrTotCompra
  From Loj_Cupons C
   Inner Join Loj_Itens_Cupons I On (C.Empresa=I.Empresa And C.Maquina=I.Maquina And C.Data=I.Data And C.Controle=I.Controle)
   Left Join Loj_Operacoes M On (M.Empresa=C.Empresa And M.Data=C.Data And M.MAquina=C.MAquina And M.Tipo=3 And M.Controle=(Select Max(Controle) from Loj_Operacoes Where Empresa=M.Empresa And Maquina=M.Maquina And Data=M.Data And Tipo=3))
   Left Join Cfc_Produtos P On (P.Empresa=I.Empresa_Produto and P.Codigo=I.Produto)
   Left Join Produtos P2 On (P.Empresa=P2.Empresa And P.Codigo=P2.Codigo)
   Left Join #TmpConsig2 CN On (CN.EmpProd=I.Empresa_Produto And CN.Produto=I.Produto)
   Inner Join Empresas E on E.Codigo_Empresas=C.Empresa
   Left Join Ret_Tributacoes RT On (RT.Codigo=I.Tributacao)
   Left Join Ret_Emp_Tributacoes RTE on (RTE.ID_Empresa=E.ID_Empresa and RTE.Cod_Tributacao=RT.Codigo)
   Left Join '+@TmpCFOP+' T On (T.Divisao=I.Divisao)
   Left Join Loj_Param_Empresa LPE On (LPE.Empresa=C.Empresa and LPE.Maquina=C.Maquina)
  Where C.Empresa = '''+@Empresa+''' and C.Data between '''+@DataIn+''' and '''+@DataFn+''' and C.Venda_Dev = ''V'' 
        and IsNull(C.Cancelado,''N'')=''N'' and IsNull(I.Cancelado,''N'')=''N'' And IsNull(C.Flag,'''')<>''''  And IsNull(LPE.SAT,0)=0
  Group By C.Empresa, C.Maquina, C.Data, C.Controle, I.Item, M.Reducao, Case When CN.Produto is Null Then T.CFOP Else '''+@CO+''' End, I.Tributacao, I.Empresa_Produto, P.Codigo, P2.Cod_ClassFisc, C.Valor_Desconto,
           C.Valor_Acrescimo, IsNull(RTE.Aliq_ImpIFiscal,RT.Aliq_ICMS)
')

  Select Empresa, Maquina, Data, Controle, Round(Valor_Desconto/Count(*),2,1) Valor_Desconto
  into #Temp_Desconto
  from #Temp
  Group by Empresa, Maquina, Data, Controle, Valor_Desconto

  Select Empresa, Maquina, Data, Controle, Tributacao, Valor_Desconto, Round((Valor_Desconto*Sum(Total))/VrTotCompra,2,1) DescRateado
  into #TmpTribCupom
  from #Temp
  Group by Empresa, Maquina, Data, Controle, Tributacao, Valor_Desconto, VrTotCompra


  Update #Temp Set Total = T.Total - C.DescRateado, 
                   Valor_Desconto_Rateado = C.DescRateado
  from #Temp T
    inner join #TmpTribCupom C on C.Empresa = T.Empresa and C.Maquina = T.Maquina and C.Data = T.Data and C.Controle = T.Controle and C.Tributacao = T.Tributacao
  Where T.Item = (Select Max(Item) From #Temp X
                  Where X.Empresa = T.Empresa and X.Maquina = T.Maquina
                  and X.Data = T.Data and X.Controle = T.Controle and X.Tributacao = C.Tributacao)

  Update #Temp Set Total = (T.Total +(Select Valor_Acrescimo - Sum(Valor_Acrescimo_Rateado)
                                      From #Temp X Where X.Empresa = T.Empresa and X.Maquina = T.Maquina
                                           and X.Data = T.Data and X.Controle = T.Controle
                                      Group By Valor_Acrescimo))
                                   - (Select Valor_Desconto - Sum(Valor_Desconto_Rateado)
                                      From #Temp X Where X.Empresa = T.Empresa and X.Maquina = T.Maquina
                                           and X.Data = T.Data and X.Controle = T.Controle
                                      Group By Valor_Desconto),
                   Valor_Desconto_Rateado = T.Valor_Desconto_Rateado + (Select Valor_Desconto - Sum(Valor_Desconto_Rateado)
                                      From #Temp X Where X.Empresa = T.Empresa and X.Maquina = T.Maquina
                                           and X.Data = T.Data and X.Controle = T.Controle
                                      Group By Valor_Desconto)
  from #Temp T
  Where T.Item = (Select TOP 1 Item From #Temp X
                  Where X.Empresa = T.Empresa and X.Maquina = T.Maquina
                  and X.Data = T.Data and X.Controle = T.Controle AND X.Tributacao =
                  (Select TOP 1 Tributacao FROM #Temp X
                  INNER JOIN Empresas E on E.Id_Empresa=X.Empresa
                  INNER JOIN Ret_Tributacoes RT ON RT.Codigo = Tributacao
                  Left Join Ret_Emp_Tributacoes RTE on RTE.ID_Empresa=E.Id_Empresa and RTE.Cod_Tributacao=RT.Codigo
                  INNER JOIN (
                    Select Max(ISNULL(RTE.Aliq_ImpIFiscal,RT.Aliq_ICMS)) Aliq_ICMS FROM #Temp
                    Inner Join Empresas E on Empresa=E.Codigo_Empresas
                    INNER JOIN Ret_Tributacoes RT ON RT.Codigo = Tributacao
                    Left Join Ret_Emp_Tributacoes RTE on E.Id_Empresa=RTE.ID_Empresa and RT.Codigo=RTE.Cod_Tributacao
                    WHERE Empresa = X.Empresa AND Maquina = X.Maquina AND Data = X.Data AND Controle = X.Controle
                    group by Empresa, Maquina, Data, Controle) X3 ON X3.Aliq_ICMS = ISNULL(RTE.Aliq_ImpIFiscal,RT.Aliq_ICMS)
                  Where X.Empresa = T.Empresa and X.Maquina = T.Maquina
                  and X.Data = T.Data and X.Controle = T.Controle
                  )
                )

   
  Select /*01*/T.Empresa Empresa, 
         /*02*/T.Num_Reducao Documento, 
         /*03*/'ECF'+ISNULL(SUBSTRING(LM.Maq_Liv,3,2),SUBSTRING(T.Maquina,3,2)) Serie, 
         /*04*/LN.Codigo NatOp,
         /*05*/' ' Seq,
         /*06*/Case when ISNULL(LN.Aliq_ICMS,0) <> 0 then SUM(Total) else 0 end ICM_BC,
         /*07*/LN.Aliq_ICMS ICM_Porc,
         /*08*/ROUND((LN.Aliq_ICMS * SUM(Total))/100,2,1) ICM_Valor,
         /*09*/case when (Select Regra_SitTrib from Fat_Parametros)<>'S' then 
                 case when (F1.IPI_IO = 'S') then case when (IsNull(LN.Aliq_ICMS,0) = 0) then SUM(Total) else 0 end 
                 else 0 end                 
               else
                 case when LN.Sit_Trib IN ('30','40','41') then case when (IsNull(LN.Aliq_ICMS,0) = 0) then SUM(Total) else 0 end 
                 else 0 end 
               end ICM_Isento,  
         /*10*/case when (Select Regra_SitTrib from Fat_Parametros)<>'S' then 
                 case when (F1.IPI_IO = 'S') then 0  
                 else case when (IsNull(LN.Aliq_ICMS,0) = 0) then SUM(Total) else 0 end end                 
               else
                 case when LN.Sit_Trib IN ('30','40','41') then 0
                 else case when (IsNull(LN.Aliq_ICMS,0) = 0) then SUM(Total) else 0 end  end 
               end ICM_Outras, 
         /*11*/0 ICM_Subst,
         /*12*/0 IPI_BC,
         /*13*/0 IPI_Valor,
         /*14*/case when (Select Regra_SitTrib from Fat_Parametros)<>'S' then 
                 case when (F1.IPI_IO = 'S') then SUM(Total) else 0 end                 
               else
                 case when LN.Sit_Trib IN ('30','40','41') then SUM(Total) else 0 end  
               end IPI_Isento,  
         /*15*/case when (Select Regra_SitTrib from Fat_Parametros)<>'S' then 
                 case when (F1.IPI_IO = 'S') then 0 else SUM(Total) end                 
               else
                 case when LN.Sit_Trib IN ('30','40','41') then 0 else SUM(Total) end  
               end IPI_Outras,  
         /*16*/SUM(Total) Vr_Contabil,
         /*17*/LNO.DIPI DIPI,
         /*18*/IsNUll(LNO.Cod_Contabil,'')+IsNull(LNO.Dig_Verificador,'') CContabil,
         /*19*/IsNull(T.Aliq_ICMS,0) T_Aliq_ICMS
    Into #Tmp_Liv_SaiNatOP     
  From #Temp T
    Left Join Fat_ParamEmp F1 on F1.Empresa = T.Empresa
    Left Join Fat_ParamEmp2 F2 on F2.Empresa = T.Empresa
    Left Join Liv_Maq_Loj LM On LM.Empresa = T.Empresa and LM.Maq_loj = T.Maquina
    Left Join (Select Codigo,Min(Sequencia) Sequencia, Aliq_ICMS,(Select Sit_Trib from Liv_Natureza where codigo=ln.Codigo and Sequencia=Min(ln.Sequencia) and Aliq_ICMS=ln.Aliq_ICMS) Sit_Trib from Liv_Natureza LN Group by Codigo, Aliq_ICMS )LN on 
                             LN.Codigo = SUBSTRING(T.Divisao,1,1)+'.'+SUBSTRING(T.Divisao,2,3) and IsNull(LN.Aliq_ICMS,0) = Case when @AliqFixa is null then IsNull(T.Aliq_ICMS,0) else @AliqFixa end
                             and IsNull(LN.Aliq_ICMS,0) = Case when ISNULL(@AliqFixa,0) = 0 then IsNull(T.Aliq_ICMS,0) else @AliqFixa end
    Left Join Fat_Parametros_Nat_Oper LNO on LNO.Empresa = T.Empresa and LNO.N_Oper=LN.Codigo and LNO.Seq =  Case When (IsNull(F2.Seq_Padrao_FigFisc,'') <> '') then
																															F2.Seq_Padrao_FigFisc else LN.Sequencia end	
  Group by T.Empresa, T.Maquina, T.Data, T.Num_Reducao, T.Divisao, T.Aliq_ICMS, 'ECF'+ISNULL(SUBSTRING(LM.Maq_Liv,3,2),SUBSTRING(T.Maquina,3,2)), LN.Sit_Trib,
        F1.IPI_IO, LN.Codigo, LN.Aliq_ICMS,LNO.DIPI,IsNUll(LNO.Cod_Contabil,'')+IsNull(LNO.Dig_Verificador,''), T.Aliq_ICMS

	/*Pegando e Atualizando a Sequencia Correta*/
	Update #Tmp_Liv_SaiNatOP Set Seq = Case When ((F2.Usar_Figura_Fiscal = 'S') and (IsNull(F2.Seq_Padrao_FigFisc,'') <> '') ) then
																				Case When (IsNull(F2.Seq_Padrao_FigFisc,'') <> '') then
																					F2.Seq_Padrao_FigFisc 
																				Else 
																					(Select Min(Sequencia) From Liv_Natureza Where Codigo = T.NatOP)
																				End	
																		 Else	
																				 LN.Sequencia
																		 End
	From #Tmp_Liv_SaiNatOP T
  Left Join Fat_ParamEmp2 F2 on F2.Empresa = T.Empresa
  Left Join (Select  Codigo,Min(Sequencia) Sequencia, Aliq_ICMS from Liv_Natureza LN Group by Codigo, Aliq_ICMS ) LN on 
                             LN.Codigo = T.NatOp and IsNull(LN.Aliq_ICMS,0) = Case when @AliqFixa is null then IsNull(T.T_Aliq_ICMS,0) else @AliqFixa end
                             and IsNull(LN.Aliq_ICMS,0) = Case when ISNULL(@AliqFixa,0) = 0 then IsNull(T.T_Aliq_ICMS,0) else @AliqFixa end						 

	Declare @Usa_Figura Char(01)

	Set @Usa_Figura = (Select Usar_Figura_Fiscal From Fat_ParamEmp2 Where Empresa = @Empresa)


	if IsNull(@Usa_Figura,'N') = 'S'
	begin
		Print 'Usa Figura Fiscal'			

		Insert Into Liv_SaiNatOp(
			 /*01*/Empresa, 
			 /*02*/Documento, 
			 /*03*/Serie, 
			 /*04*/NatOp, 
			 /*05*/Seq, 
			 /*06*/ICM_BC, 
			 /*07*/ICM_PORC, 
			 /*08*/ICM_Valor, 
			 /*09*/ICM_Isento, 
			 /*10*/ICM_Outras, 
			 /*11*/ICM_Subst, 
			 /*12*/IPI_BC, 
			 /*13*/IPI_Valor, 
			 /*14*/IPI_Isento, 
			 /*15*/IPI_Outras, 
			 /*16*/Vr_Contabil, 
			 /*17*/DIPI, 
			 /*18*/CContabil)
			Select /*01*/Empresa, 
						 /*02*/Documento, 
						 /*03*/Serie, 
						 /*04*/NatOp, 
						 /*05*/Seq, 
						 /*06*/SUM(ICM_BC), 
						 /*07*/MAX(ICM_Porc), 
						 /*08*/SUM(ICM_Valor), 
						 /*09*/SUM(ICM_Isento), 
						 /*10*/SUM(ICM_Outras), 
						 /*11*/SUM(ICM_Subst), 
						 /*12*/SUM(IPI_BC), 
						 /*13*/SUM(IPI_Valor), 
						 /*14*/SUM(IPI_Isento), 
						 /*15*/SUM(IPI_Outras), 
						 /*16*/SUM(Vr_Contabil), 
						 /*17*/DIPI, 
						 /*18*/CContabil
				From #Tmp_Liv_SaiNatOP 												  
			Group By /*01*/Empresa, 
							 /*02*/Documento, 
							 /*03*/Serie, 
							 /*04*/NatOp, 
							 /*05*/Seq, 							
							 /*17*/DIPI, 
							 /*18*/CContabil			       
	end
	else
	begin
		Print 'Não Usa Figura Fiscal'
			
		Insert Into Liv_SaiNatOp(
			 /*01*/Empresa, 
			 /*02*/Documento, 
			 /*03*/Serie, 
			 /*04*/NatOp, 
			 /*05*/Seq, 
			 /*06*/ICM_BC, 
			 /*07*/ICM_PORC, 
			 /*08*/ICM_Valor, 
			 /*09*/ICM_Isento, 
			 /*10*/ICM_Outras, 
			 /*11*/ICM_Subst, 
			 /*12*/IPI_BC, 
			 /*13*/IPI_Valor, 
			 /*14*/IPI_Isento, 
			 /*15*/IPI_Outras, 
			 /*16*/Vr_Contabil, 
			 /*17*/DIPI, 
			 /*18*/CContabil)
			Select /*01*/Empresa, 
						 /*02*/Documento, 
						 /*03*/Serie, 
						 /*04*/NatOp, 
						 /*05*/Seq, 
						 /*06*/ICM_BC, 
						 /*07*/ICM_Porc, 
						 /*08*/ICM_Valor, 
						 /*09*/ICM_Isento, 
						 /*10*/ICM_Outras, 
						 /*11*/ICM_Subst, 
						 /*12*/IPI_BC, 
						 /*13*/IPI_Valor, 
						 /*14*/IPI_Isento, 
						 /*15*/IPI_Outras, 
						 /*16*/Vr_Contabil, 
						 /*17*/DIPI, 
						 /*18*/CContabil
				From #Tmp_Liv_SaiNatOP 												  
			Group By /*01*/Empresa, 
							 /*02*/Documento, 
							 /*03*/Serie, 
							 /*04*/NatOp, 
							 /*05*/Seq,
							 /*06*/ICM_BC, 
							 /*07*/ICM_Porc, 
							 /*08*/ICM_Valor, 
							 /*09*/ICM_Isento, 
							 /*10*/ICM_Outras, 
							 /*11*/ICM_Subst, 
							 /*12*/IPI_BC, 
							 /*13*/IPI_Valor, 
							 /*14*/IPI_Isento, 
							 /*15*/IPI_Outras, 
							 /*16*/Vr_Contabil, 							
							 /*17*/DIPI, 
							 /*18*/CContabil	
	end

  Drop Table #Temp
  Drop Table #Temp_Desconto
  Drop Table #TmpConsig2
  Drop Table #TmpTribCupom
  Drop Table #Tmp_Liv_SaiNatOP
  
  /******* Importando os cupons Fiscais eletronicos************/

  if IsNull(@Usa_Figura,'N') = 'S'
  begin
    Print 'SAT - Usa Figura Fiscal'

    Insert Into Liv_SaiNatOp(
         /*01*/Empresa, 
         /*02*/Documento, 
         /*03*/Serie, 
         /*04*/NatOp, 
         /*05*/Seq, 
         /*06*/ICM_BC, 
         /*07*/ICM_Porc, 
         /*08*/ICM_Valor, 
         /*09*/ICM_Isento, 
         /*10*/ICM_Outras, 
         /*11*/ICM_Subst, 
         /*12*/IPI_BC, 
         /*13*/IPI_Valor, 
         /*14*/IPI_Isento, 
         /*15*/IPI_Outras, 
         /*16*/Vr_Contabil, 
         /*17*/DIPI, 
         /*18*/CContabil) 
	  Select /*01*/C.Empresa, 
         /*02*/IsNull(M.Reducao,'000000'), 
         /*03*/'ECF'+ISNULL(SUBSTRING(LM.Maq_Liv,3,2),SUBSTRING(C.Maquina,3,2)), 
         /*04*/Imp.NatOp,
         /*05*/Imp.Seq,
         /*06*/SUM(Imp.Vr_BCICMS),
         /*07*/MAX(Imp.Aliq_ICMS),
         /*08*/SUM(Imp.Vr_ICMS),
         /*09*/SUM(Imp.Vr_ICMS_Isento),  
         /*10*/SUM(Imp.Vr_ICMS_Outras), 
         /*11*/SUM(Imp.Vr_ICMS_Subst),
         /*12*/SUM(Imp.BC_IPI),
         /*13*/SUM(Imp.Valor_IPI),
         /*14*/SUM(Imp.Vr_IPI_Isento),  
         /*15*/SUM(Imp.Vr_IPI_Outras),  
         /*16*/SUM(LIC.Sub_Total-LIC.Desconto_Rateio+LIC.Acrescimo_Rateio),
         /*17*/LNO.DIPI,
         /*18*/IsNUll(LNO.Cod_Contabil,'')+IsNull(LNO.Dig_Verificador,'')
	  From Loj_Cupons C
		Inner Join Loj_Itens_Cupons_Imposto Imp On (Imp.Empresa=C.Empresa and Imp.Maquina=C.Maquina and Imp.Data=C.Data and Imp.Controle=C.Controle)
		Left Join Loj_Itens_Cupons LIC On (LIC.Empresa=C.Empresa and LIC.Maquina=C.Maquina and LIC.Data=C.Data and LIC.Controle=C.Controle and LIC.Item=Imp.Item)
		Left Join Liv_Maq_Loj LM On LM.Empresa = C.Empresa and LM.Maq_loj = C.Maquina
		Left Join Loj_Operacoes M On (M.Empresa=C.Empresa And M.Data=C.Data And M.MAquina=C.MAquina And M.Tipo=3 And M.Controle=(Select Max(Controle) from Loj_Operacoes Where Empresa=M.Empresa And Maquina=M.Maquina And Data=M.Data And Tipo=3))
		Left Join Fat_Parametros_Nat_Oper LNO on (LNO.Empresa = C.Empresa and LNO.N_Oper=Imp.NatOp and LNO.Seq = Imp.Seq)
		Left Join Loj_Param_Empresa LPE on (LPE.Empresa=C.Empresa and LPE.Maquina=C.Maquina)
	  Where C.Empresa=@Empresa and C.Data between @DataIn and @DataFn and C.Venda_Dev = 'V' 
			and IsNull(C.Cancelado,'N')='N' And IsNull(C.Flag,'')<>''  And IsNull(LPE.SAT,0)=1
	  Group by C.Empresa, C.Maquina, C.Data, M.Reducao, Imp.NatOp, Imp.Seq, 'ECF'+ISNULL(SUBSTRING(LM.Maq_Liv,3,2),SUBSTRING(C.Maquina,3,2)), 
		       LNO.DIPI, LNO.Cod_Contabil, LNO.Dig_Verificador
  end
  else
  begin
    Print 'SAT - Não Usa Figura Fiscal'

    Insert Into Liv_SaiNatOp(
         /*01*/Empresa, 
         /*02*/Documento, 
         /*03*/Serie, 
         /*04*/NatOp, 
         /*05*/Seq, 
         /*06*/ICM_BC, 
         /*07*/ICM_Porc, 
         /*08*/ICM_Valor, 
         /*09*/ICM_Isento, 
         /*10*/ICM_Outras, 
         /*11*/ICM_Subst, 
         /*12*/IPI_BC, 
         /*13*/IPI_Valor, 
         /*14*/IPI_Isento, 
         /*15*/IPI_Outras, 
         /*16*/Vr_Contabil, 
         /*17*/DIPI, 
         /*18*/CContabil) 
	  Select /*01*/C.Empresa, 
         /*02*/IsNull(M.Reducao,'000000'), 
         /*03*/'ECF'+ISNULL(SUBSTRING(LM.Maq_Liv,3,2),SUBSTRING(C.Maquina,3,2)), 
         /*04*/Imp.NatOp,
         /*05*/Imp.Seq,
         /*06*/SUM(Imp.Vr_BCICMS),
         /*07*/Imp.Aliq_ICMS,
         /*08*/SUM(Imp.Vr_ICMS),
         /*09*/SUM(Imp.Vr_ICMS_Isento),  
         /*10*/SUM(Imp.Vr_ICMS_Outras), 
         /*11*/SUM(Imp.Vr_ICMS_Subst),
         /*12*/SUM(Imp.BC_IPI),
         /*13*/SUM(Imp.Valor_IPI),
         /*14*/SUM(Imp.Vr_IPI_Isento),  
         /*15*/SUM(Imp.Vr_IPI_Outras),  
         /*16*/SUM(LIC.Sub_Total-LIC.Desconto_Rateio+LIC.Acrescimo_Rateio),
         /*17*/LNO.DIPI,
         /*18*/IsNUll(LNO.Cod_Contabil,'')+IsNull(LNO.Dig_Verificador,'')
	  From Loj_Cupons C
		Inner Join Loj_Itens_Cupons_Imposto Imp On (Imp.Empresa=C.Empresa and Imp.Maquina=C.Maquina and Imp.Data=C.Data and Imp.Controle=C.Controle)
		Left Join Loj_Itens_Cupons LIC On (LIC.Empresa=C.Empresa and LIC.Maquina=C.Maquina and LIC.Data=C.Data and LIC.Controle=C.Controle and LIC.Item=Imp.Item)
		Left Join Liv_Maq_Loj LM On LM.Empresa = C.Empresa and LM.Maq_loj = C.Maquina
		Left Join Loj_Operacoes M On (M.Empresa=C.Empresa And M.Data=C.Data And M.MAquina=C.MAquina And M.Tipo=3 And M.Controle=(Select Max(Controle) from Loj_Operacoes Where Empresa=M.Empresa And Maquina=M.Maquina And Data=M.Data And Tipo=3))
		Left Join Fat_Parametros_Nat_Oper LNO on (LNO.Empresa = C.Empresa and LNO.N_Oper=Imp.NatOp and LNO.Seq = Imp.Seq)
		Left Join Loj_Param_Empresa LPE on (LPE.Empresa=C.Empresa and LPE.Maquina=C.Maquina)
	  Where C.Empresa=@Empresa and C.Data between @DataIn and @DataFn and C.Venda_Dev = 'V' 
			and IsNull(C.Cancelado,'N')='N' And IsNull(C.Flag,'')<>''  And IsNull(LPE.SAT,0)=1
	  Group by C.Empresa, C.Maquina, C.Data, M.Reducao, Imp.NatOp, Imp.Seq, 'ECF'+ISNULL(SUBSTRING(LM.Maq_Liv,3,2),SUBSTRING(C.Maquina,3,2)), 
		 Imp.Aliq_ICMS, LNO.DIPI, LNO.Cod_Contabil, LNO.Dig_Verificador
  end
     
End
GO
