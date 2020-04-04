If Exists(Select 0 from SysObjects where name='SP_Liv_ImpCupons_LivSaida')
  Drop Procedure dbo.SP_Liv_ImpCupons_LivSaida
GO
Create Procedure dbo.SP_Liv_ImpCupons_LivSaida (  
  @Empresa Char(02),  
  @Data_I SmallDateTime,  
  @Data_F SmallDateTime,  
  @Cliente Char(18))  
As Begin  
/************************************************************************************************  
  Author:      Rodrigo Consolmagno  
  Create Data: 11/09/2013  
  Description: Procedure Criada para importaçao do cupom fiscal para o livros de saida, foi   
      removido o codigo que ficava dentro do fonte do sistema e passado para procedures.                       
  Alterada em: 12/02/2015 - Marcia - verificar Venda_Dev somente do loj_Cupons        
  Alterada em: 17/06/2015 - Marcia - alterações referente ao CF-e  
  
  Alterado em: 04/12/2015
 Alterado poe: Lucas Rosseto
	  Alteração: Implementado para Enviar os Valores de Desconto e Acrescimo na Capa do Cupom LIV_CUPONS
	  
	Alterado em: 11/03/2016
 Alterado poe: Lucas Rosseto
	  Alteração: Alterado para poder Agrupar Corretamente LM.Maq_Liv nas Versões do SQL 2000 e 2012 E 
				 Incompatibilidade no Create de uma Temporaria que esta '' Campo para ' ' Doc_Final (SQL 2000)
*************************************************************************************************/    
  Delete Liv_SaiProd   
   From Liv_Saidas S  
    Inner Join Liv_SaiNatOp N on N.Empresa=S.Empresa and N.Documento=S.Documento and N.Serie=S.Serie  
    Inner Join Liv_SaiProd P on P.Empresa=N.Empresa and P.Documento=N.Documento and P.Serie=N.Serie and P.NatOp=N.NatOp and P.Seq=N.Seq  
  Where S.Empresa = @Empresa And S.Data_Emissao Between @Data_I and @Data_F and Left(S.Serie,3) = 'ECF' and S.Tipo_Doc = 'CUP'  
  
  Delete Liv_SaiNatOP   
   From Liv_Saidas S  
    Inner Join Liv_SaiNatOp N on N.Empresa=S.Empresa and N.Documento=S.Documento and N.Serie=S.Serie   
  Where S.Empresa = @Empresa And S.Data_Emissao Between @Data_I and @Data_F and Left(S.Serie,3) = 'ECF' and S.Tipo_Doc = 'CUP'  
  
  Delete Liv_Saidas  
  Where Empresa = @Empresa And Data_Emissao Between @Data_I and @Data_F and Left(Serie,3) = 'ECF' and Tipo_Doc = 'CUP'  
    
  /*Seleciona as maquinas que sao sat e que nao tem o loj_operacoes com o nro da ReducaoZ*/  
  Select Distinct C.Maquina, C.Data, identity(int,1,1) as Incremento   
  into #Tmp_Maquinas  
  From Loj_Cupons C  
    Inner Join Loj_Param_Empresa LPE on (LPE.Empresa=C.Empresa and LPE.Maquina=C.Maquina)  
    Left Join Loj_Operacoes LO on (LO.Empresa=C.Empresa and LO.Maquina=C.Maquina and LO.Data=C.Data and Tipo=3)  
  Where C.Empresa = @Empresa and C.Data between @Data_I and @Data_F and C.Venda_Dev = 'V'   
        and IsNull(C.Cancelado,'N')='N'  And IsNull(C.Flag,'')<>'' And LPE.SAT=1  
        and ISNULL(LO.Reducao,'')=''  
  Group By C.Empresa, C.Maquina, C.Data, LPE.SAT  
  
  Insert into Loj_Operacoes(Empresa,Maquina,Data,Controle,Tipo,Reducao,Operacao)  
  Select @Empresa,Maquina,Data,(select isnull(max(controle),0)+Incremento from Loj_Operacoes Where Empresa=@Empresa and Maquina=T.Maquina and Data=T.Data),3,  
     Right('000000'+CAST( (Select ISNULL(max(reducao),0)+Incremento from Loj_Operacoes Where Empresa=@Empresa and Maquina=T.Maquina and Tipo=3) as varchar),6),  
     Right('000000'+CAST( (Select ISNULL(max(reducao),0)+Incremento from Loj_Operacoes Where Empresa=@Empresa and Maquina=T.Maquina and Tipo=3) as varchar),6)  
  From #Tmp_Maquinas T  
  
Select /*01*/C.Empresa,   
        /*02*/IsNull(M.Reducao,'000000')  Documento,   
        /*03*/'ECF'+IsNull(Substring(LM.Maq_Liv,3,2),Substring(C.Maquina,3,2)) Serie,  
        /*04*/' ' Doc_Final,  
        /*05*/@Cliente Cliente,  
        /*06*/'CUP' Tipo_Doc,  
        /*07*/C.Data Data_Emissao,    
        /*08*/CASE WHEN IsNull(C.Cancelado,'N') = 'S' THEN 0 ELSE (Sum(I.Sub_Total)+Sum(IsNull(Acrescimo_Rateio,0)))-Sum(IsNull(Desconto_Rateio,0)) END Valor_Nota ,  
        /*09*/'0' Link_CR,  
        /*10*/C.Empresa Emp_Origem,  
        /*11*/CASE WHEN ISNULL(LPE.SAT,0)=0 THEN (Select Cod_Liv_SPED_Modelo_Dcto from Liv_SPED_Modelo_Dcto where Codigo_Modelo='2D') ELSE (Select Cod_Liv_SPED_Modelo_Dcto from Liv_SPED_Modelo_Dcto where Codigo_Modelo='59') END Cod_Mod,  
        /*12*/(Select Cod_Liv_SPED_Situacao_Dcto from Liv_SPED_Situacao_Dcto where Codigo_Situacao='00') Cod_Sit,  
        /*13*/'9' Tipo_Parcela,  
        /*14*/'9' Tipo_Frete,  
        /*15*/'1' Finalidade_NF,  
        /*16*/'0' Ind_Emit,  
        /*17*/ISNULL(C.Valor_Desconto,0) Valor_Desconto,  
        /*18*/ISNULL(C.Valor_Acrescimo,0)Valor_Outras_Despesas  
   Into #Tmp_Cupons       
 From Loj_Cupons C  
   Inner Join Loj_Itens_Cupons I On (C.Empresa=I.Empresa And C.Maquina=I.Maquina And C.Data=I.Data And C.Controle=I.Controle)  
   Left Join Loj_Operacoes M On (M.Empresa=C.Empresa And M.Data=C.Data And M.MAquina=C.MAquina And M.Tipo=3 And M.Controle=(Select Max(Controle) from Loj_Operacoes Where Empresa=M.Empresa And Maquina=M.Maquina And Data=M.Data And Tipo=3))  
   Left Join Liv_Maq_Loj LM On LM.Empresa = C.Empresa and LM.Maq_loj = C.Maquina  
   Left Join Loj_Param_Empresa LPE On (LPE.Empresa=C.Empresa and LPE.Maquina=C.Maquina)  
  Where C.Empresa = @Empresa and C.Data between @Data_I and @Data_F and C.Venda_Dev = 'V'   
        and IsNull(C.Cancelado,'N')='N' and IsNull(I.Cancelado,'N')='N' And IsNull(C.Flag,'')<>''  
  Group By C.Empresa, C.Maquina, C.Data, M.Reducao,'ECF'+IsNull(Substring(LM.Maq_Liv,3,2),Substring(C.Maquina,3,2)),  
      LPE.SAT, IsNull(C.Cancelado,'N'), C.Valor_Acrescimo, C.Valor_Desconto  
  
  
  
	Insert Into Liv_Saidas(  
   /*01*/Empresa,   
   /*02*/Documento,   
   /*03*/Serie,   
   /*04*/Doc_Final,   
   /*05*/Cliente,   
   /*06*/Tipo_Doc,   
   /*07*/Data_Emissao,     
   /*08*/Valor_Nota,   
   /*09*/Link_CR,   
   /*10*/Emp_Origem,  
   /*11*/Cod_Mod,  
   /*12*/Cod_Sit,  
   /*13*/Tipo_Parcela,  
   /*14*/Tipo_Frete,  
   /*15*/Finalidade_NF,  
   /*16*/Ind_Emit,  
   /*17*/Valor_Desconto,  
   /*18*/Valor_Outras_Despesas,  
   /*19*/Vr_DescontoGeral)  
     
   Select   
     /*01*/Empresa,   
     /*02*/Documento,   
     /*03*/Serie,   
     /*04*/Doc_Final,   
     /*05*/Cliente,   
     /*06*/Tipo_Doc,   
     /*07*/Data_Emissao,     
     /*08*/SUM(Valor_Nota),   
     /*09*/Link_CR,   
     /*10*/Emp_Origem,  
     /*11*/Cod_Mod,  
     /*12*/Cod_Sit,  
     /*13*/Tipo_Parcela,  
     /*14*/Tipo_Frete,  
     /*15*/Finalidade_NF,  
     /*16*/Ind_Emit,  
     /*17*/Sum(Valor_Desconto),  
     /*18*/Sum(Valor_Outras_Despesas),  
     /*19*/Sum(Valor_Desconto)  
   From #Tmp_Cupons  
   Group By Empresa, Documento, Serie, Doc_Final, Cliente, Tipo_Doc, Data_Emissao,     
      Link_CR, Emp_Origem, Cod_Mod, Cod_Sit, Tipo_Parcela, Tipo_Frete,  
      Finalidade_NF, Ind_Emit  
   
        
End  
GO