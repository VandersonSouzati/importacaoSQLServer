If Exists(Select 0 from SysObjects where name='SP_Liv_ImpCupons_Sfs_Sintegra_Tot')
  Drop Procedure dbo.SP_Liv_ImpCupons_Sfs_Sintegra_Tot
GO
Create Procedure dbo.SP_Liv_ImpCupons_Sfs_Sintegra_Tot (
  @Empresa Char(02),
  @Data_I SmallDateTime,
  @Data_F SmallDateTime)
As begin
/************************************************************************************************
  Author:      Rodrigo Consolmagno
  Create Data: 11/09/2013
  Alterada em: 22/06/2015 - Marcia
  Alterações: No Sintegra não podem entrar os Cupons Fiscais Eletrônicos (SAT)
  Description: Procedure Criada para importaçao do cupom fiscal para o Sfc_Sintegra_Totalizadores, 
               foi removido o codigo que ficava dentro do fonte do sistema e passado para procedures.
*************************************************************************************************/
  Create Table #Temp(
		/*01*/Incremento Int Null,
		/*02*/Empresa char(02) Null,
		/*03*/Maquina char(04) Null,
		/*04*/Data SmallDateTime Null,
		/*05*/Aliq_ICMS Decimal(16,4) Null,
		/*06*/Vr_BC_ICMS Decimal(16,4) Null 
  )
  Insert into #Temp(
		/*01*/Incremento,
		/*02*/Empresa,
		/*03*/Maquina,
		/*04*/Data,
		/*05*/Aliq_ICMS,
		/*06*/Vr_BC_ICMS  
  )
  Select /*01*/null Incremento,
         /*02*/CI.Empresa,
         /*03*/CI.Maquina,
         /*04*/CI.data,
         /*05*/IsNull(TE.Aliq_ImpIFiscal,T.Aliq_ICMS) Aliq_ICMS,
         /*06*/Sum((I.Sub_Total+IsNull(I.Acrescimo_Rateio,0))-IsNull(I.Desconto_Rateio,0)) Vr_BC_ICMS
  From Loj_Cupons CI
    Inner Join Loj_Itens_Cupons I ON (I.Empresa=CI.Empresa and I.Maquina=CI.Maquina and I.Data=CI.Data and I.Controle=CI.Controle)
    Inner Join Ret_Tributacoes T ON (I.Tributacao = T.Codigo)
    Inner Join Empresas E on E.Codigo_Empresas=CI.Empresa
    Left Join Ret_Emp_Tributacoes TE on TE.ID_Empresa=E.Id_Empresa and TE.Cod_Tributacao=T.Codigo
    Left Join Loj_Param_Empresa LPE on (LPE.Empresa=CI.Empresa and LPE.Maquina=CI.Maquina)
  Where CI.Empresa = @Empresa and CI.data Between @Data_I and @Data_F
      AND IsNull(CI.COO,'')<>'' And CI.Venda_Dev='V' and ISNULL(CI.Cancelado,'N')='N' and ISNULL(I.Cancelado,'N')='N'
      And ISNULL(LPE.SAT,0)=0
  Group by CI.Empresa,CI.Maquina,CI.data,IsNull(TE.Aliq_ImpIFiscal,T.Aliq_ICMS)
  
  Declare @Inc int
   
  Select @Inc=IsNull(MAX(Incremento),0) from Sfc_Sintegra_Totalizadores 
  update #Temp set Incremento = @Inc,
                   @Inc = @Inc + 1                     
  
  Insert Into Sfc_Sintegra_Totalizadores(
		/*01*/Incremento,
		/*02*/Empresa,
		/*03*/Maquina,
		/*04*/Data,
		/*05*/Aliq_ICMS,
		/*06*/Vr_BC_ICMS
  )
 Select DISTINCT
		/*01*/T.Incremento,
		/*02*/T.Empresa,
		/*03*/IsNull(LM.Maq_Liv, T.Maquina),
		/*04*/T.Data,
		/*05*/T.Aliq_ICMS,
		/*06*/T.Vr_BC_ICMS
 from #Temp T
 left join Liv_Maq_Loj LM on (LM.Maq_Loj = T.Maquina) 
 
 Drop Table #Temp
End
GO