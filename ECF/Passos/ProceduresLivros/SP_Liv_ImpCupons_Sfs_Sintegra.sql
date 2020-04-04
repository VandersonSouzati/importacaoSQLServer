If Exists(Select 0 from SysObjects where name='SP_Liv_ImpCupons_Sfs_Sintegra')
  Drop Procedure dbo.SP_Liv_ImpCupons_Sfs_Sintegra
GO
Create Procedure dbo.SP_Liv_ImpCupons_Sfs_Sintegra (
  @Empresa Char(02),
  @Data_I SmallDateTime,
  @Data_F SmallDateTime,
  @AliqFixa Decimal(16,4)=null,
  @RelMResumo VarChar(20),      
  @T01 varChar(05),
  @T02 varChar(05),
  @T03 varChar(05),
  @T04 varChar(05))
As begin
/************************************************************************************************
  Author:      Rodrigo Consolmagno
  Create Data: 11/09/2013
  Description: Procedure Criada para importaçao do cupom fiscal para o Sfc_Sintegra, foi 
			   removido o codigo que ficava dentro do fonte do sistema e passado para procedures.		                   
*************************************************************************************************/
  Declare @Aliq_Fixa varChar(3)

  Set @Aliq_Fixa = CAST(@AliqFixa as varChar)
  
  Delete Sfc_Sintegra_Totalizadores
  Where Empresa = @Empresa And Data between @Data_I and @Data_F

  Delete Sfc_Sintegra
  Where Empresa = @Empresa And Data between @Data_I and @Data_F
  
  Create Table #Temp(
      /*01*/Empresa Char(02) Null,
      /*02*/Maquina Char(04) Null,
      /*03*/Data SmallDateTime Null,
      /*04*/NatOp Char(05) Null,
      /*05*/Num_Reducao Char(06) Null,
      /*06*/Num_Operacao Char(06) Null,
      /*07*/Valor_Cupom Decimal(16,4) Null,
      /*08*/Valor_Cancelado Decimal(16,4) Null,
      /*09*/Valor_Desconto Decimal(16,4) Null,
      /*10*/Valor_Acrescimo Decimal(16,4) Null,
      /*11*/Valor_18PC Decimal(16,4) Null,
      /*12*/Valor_25PC Decimal(16,4) Null,
      /*13*/Valor_FIXOPC Decimal(16,4) Null,
      /*14*/Valor_PCS Decimal(16,4) Null,
      /*15*/Valor_DSF Decimal(16,4) Null,
      /*16*/Valor_INR Decimal(16,4) Null,
      /*17*/Valor_7 Decimal(16,4) Null,
      /*18*/Valor_12 Decimal(16,4) Null,
      /*19*/Valor_18 Decimal(16,4) Null,
      /*20*/Valor_FIXO Decimal(16,4) Null,
      /*21*/Valor_25 Decimal(16,4) Null,
      /*22*/Valor_BPC Decimal(16,4) Null)
      
Insert into #Temp
Exec sp_Con_MapaResumoPDV 
     @Data_I, 
     @Data_F, 
     @Empresa,
     @T01,
     @T02,  
     @T03, 
     @T04, 
     @Aliq_Fixa,
     @T01, 
     @T02,  
     @T03, 
     @T04, 
     @Aliq_Fixa, 
     @RelMResumo
    
Insert Into Sfc_Sintegra(
     /*01*/Empresa, 
     /*02*/Maquina, 
     /*03*/Data, 
     /*04*/COO_Inicial, 
     /*05*/COO_Final, 
     /*06*/Contador_ReducaoZ, 
     /*07*/Venda_Bruta, 
     /*08*/Venda_Geral, 
     /*09*/Valor_ICMS7, 
     /*10*/Valor_ICMS12, 
     /*11*/Valor_ICMS18, 
     /*12*/Valor_ICMS25, 
     /*13*/Numero_Serie, 
     /*14*/Valor_Descontos, 
     /*15*/Valor_Cancelado, 
     /*16*/Contador_Reinicio, 
     /*17*/Valor_ICMS0)
  Select DISTINCT 
	/*01*/T.Empresa, 
         /*02*/IsNull(LM.Maq_Liv, T.Maquina), 
         /*03*/T.Data,
         /*04*/Case when IsNull(LO.COO_Inicial,'') <> '' then LO.COO_Inicial else 0 end COO_Inicial,
         /*05*/Case when IsNull(LO.Operacao,'') <> '' then LO.Operacao else 0 end COO_Final,
         /*06*/Case when IsNull(LO.Reducao,'') <> '' then LO.Reducao else 0 end Contador_ReducaoZ,
         /*07*/Case when IsNull(T.Valor_Cupom,0) <> 0 then T.Valor_Cupom else 0 end + 
               Case when IsNull(T.Valor_Cancelado,0) <> 0 then T.Valor_Cancelado else 0 end +
               Case when IsNull(T.Valor_Desconto,0) <> 0 then T.Valor_Desconto else 0 end Venda_Bruta,
         /*08*/IsNull(LO.Grande_Total,0) Venda_Geral,
         /*09*/IsNull(T.Valor_7,0) Valor_ICMS7,
         /*10*/IsNull(T.Valor_12,0) Valor_ICMS12,
         /*11*/IsNull(T.Valor_18,0) Valor_ICMS18,
         /*12*/IsNull(T.Valor_25,0) Valor_ICMS25,
         /*13*/IsNull(LO.Numero_Serie,'') Numero_Serie,
         /*14*/Case when IsNull(T.Valor_Desconto,0) <> 0 then T.Valor_Desconto else 0 end Valor_Descontos,
         /*15*/Case when IsNull(T.Valor_Cancelado,0) <> 0 then T.Valor_Cancelado else 0 end Valor_Cancelado,
         /*16*/IsNull(LO.Qtde_Reinicio,0) Contador_Reinicio,
         /*17*/ISNULL(T.Valor_DSF,0)+ISNULL(T.Valor_INR,0) Valor_ICMS0
  from #Temp T
    Left Join Loj_Param_Empresa LPE on T.Empresa = LPE.Empresa and T.Maquina=LPE.Maquina
    Left Join Loj_Operacoes LO on LPE.Empresa = LO.Empresa and LPE.Maquina = LO.Maquina and LO.Tipo=3 and T.Data = LO.Data and
                                  LO.Controle = (Select MAX(Controle) from Loj_Operacoes where Empresa=LO.Empresa and Maquina=LO.Maquina and Data=LO.Data and Tipo=3)
    Left Join Liv_Maq_Loj LM on (LM.Maq_Loj = T.Maquina)  

End
GO