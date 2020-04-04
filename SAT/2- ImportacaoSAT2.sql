

/*
DELETE FROM Loj_CFE_XML_PGTO
DELETE FROM Loj_CFE_XML_ITEM
DELETE FROM Loj_CFE_XML
*/

--CONFIRMAR TRIB LOJ_ITENS_CUPONS_IMPOSTO UPDATE
If Object_Id('DadosExcel') Is Not Null 
Drop Table DadosExcel
GO
If Object_Id('ImpLoj_CuponsSAT') Is Not Null 
Drop Table ImpLoj_CuponsSAT
go
If Object_Id('ImpLoj_Itens_CuponsSAT') Is Not Null 
Drop Table ImpLoj_Itens_CuponsSAT
GO
If Object_Id('ImpLoj_Itens_Cupons_ImpostoSAT') Is Not Null 
Drop Table ImpLoj_Itens_Cupons_ImpostoSAT
go
If Object_Id('ImpLoj_Cupons_Dados_CFESAT') Is Not Null 
Drop Table ImpLoj_Cupons_Dados_CFESAT 
Go
If Object_Id('ImpLoj_Cupons_FinalizadoresSAT') Is Not Null 
Drop Table ImpLoj_Cupons_FinalizadoresSAT
Go

Declare @Cliente Varchar(14), @Empresa Varchar(02), @CNPJEmpresa Varchar(20), @Estado Varchar(02)

Set @CNPJEmpresa =(
                     Select  Top 1
                       SUBSTRING(emiCNPJ,1,2)+'.'+SUBSTRING(emiCNPJ,3,3)+'.'+SUBSTRING(emiCNPJ,6,3)
                       +'/'+SUBSTRING(emiCNPJ,9,4)+'-'+SUBSTRING(emiCNPJ,13,2)
                     From Loj_CFE_XML
                   )

Set @Empresa = ( 
                 Select Top 1 Codigo_Empresas 
                 From Empresas 
                 Where Cgc_Empresas = @CNPJEmpresa 
               )

Set @Estado = (
                Select Estado_Empresas 
                From Empresas
                Where CGC_Empresas = @CNPJEmpresa
              )

Set @Cliente = (
                Select  
                 CASE 
		   WHEN @Estado = 'SP' THEN '111.111.111-11'
		   WHEN @Estado = 'PE' THEN '222.222.222-22'
		   WHEN @Estado = 'RJ' THEN '333.333.333-33'
		   WHEN @Estado = 'MG' THEN '444.444.444-44'
		   WHEN @Estado = 'DF' THEN '555.555.555-55'
		   WHEN @Estado = 'PR' THEN '666.666.666-66'
		   WHEN @Estado NOT IN ('SP', 'PE', 'RJ', 'MG', 'DF', 'PR') THEN ''
	        END
              )



/**Loj_Cupons**************************************************************************/
Select 
--Distinct
  Identity(Int, 1,1) Id,
   @Empresa As Empresa, 
   '0001'   As Maquina, 
   CAST(demi As SmallDateTime) As Data,                             --Acertar
   '01' As Controle,
   Round(Cast(Isnull(vCFE,0) As Decimal(16,4)),2) As Sub_Total,
   Round(Cast(Isnull(C.vDescSubtot,0) As Decimal(16,4)),2) As Valor_Desconto,
   Cast(0 As Decimal(16,4)) As Valor_Acrescimo,
   Round(Round(Cast(iSNULL(C.vProd,0) As Decimal(16,4)),2),2) As Total_Cupom,
   Round(Cast(0 As Decimal(16,4)),2) As Troco_Dinheiro,
   Round(Cast(0 As Decimal(16,4)),2) As Troco_Vale,  
   '0001' As Operador,
   NULL As Hora,
   @Cliente As Cliente, ---Cadastrar(Tratar CNPJ)
   'N' As Cancelado, --Verificar
   'F' As Status,
   '000' As Convenio,
   '000SAT' As Flag,
   'V'   As Venda_Dev,
   '07'  As Tipo_Venda, --Cadastrar Tipo de Venda
   '0'   As Imp_Orcamento,
   Demi As Data_Hora_Cupom,                            --Acertar
   '000000000000' As Controle_Interno,--Gerar o controleInterno
   '001' As Tabela,
   Cast( 0 As Decimal(16,2)) As Margem_Venda,--Confirmar
   '0'  As Status_Bloq, --Confirmar
   '000SAT' As COO ,
   '0'  As COO_Nfce, --Confirmar
   'N'  As Aguarda_Fat,
   C.ID ID_XML
Into ImpLoj_CuponsSAT
FROM Loj_CFE_XML C 

/***********************************************************************************************/


--Atualizar o  controle, 31/01/2018 alterar para alterar o controle_interno tambem 
Declare @total int, @contador int,@Data SmallDateTime, @Controle int, @Maquina Varchar(04)
 
Set @total = (Select COUNT(*) From ImpLoj_CuponsSAT) 
Set @contador =1
Set @Controle =0
While(@contador <= @total) 
Begin 
  Set @Data = (Select Top 1 DATA From ImpLoj_CuponsSAT Where Id= @Contador)
  Set @Controle = @Controle +1
  
  If(@Data) <> (Select Top 1 DATA From ImpLoj_CuponsSAT Where Id = @contador-1)
    begin 
      Set @Controle = 1
    End
   
    Update ImpLoj_CuponsSAT Set Controle = @Controle 
    Where Id = @contador
    
  Set @contador = @contador +1
End
alter table ImpLoj_CuponsSAT drop column id
/***********************************************************************************/


/*****Loj_Itens_cupons***************************************************************************/

--select top 1 * from loj_itens_cupons
Select 
--top 2
distinct
	C.Empresa, 
	C.Maquina,
	C.Data,
	C.Controle,
	I.Item As Item,
	(Select Empresa_Produtos from Liv_Diario Where Empresa = @Empresa) As Empresa_Produto,
	P.Codigo As Produto,
	I.qCom As Quantidade,
	Round(Cast(Isnull(I.vUnCom,0) As Decimal(16,4)),2)  As Preco_Unitario,
	Case When Cast(Isnull(I.VDesc,0 ) As  Decimal(16,4)) > 0 Then --Desconto no Item
			Round(Cast(Isnull(I.vItem,0 ) As Decimal(16,4)),2)
		 Else 
		    Round(Cast(Isnull(I.vProd,0 ) As Decimal(16,4)),2)--Desconto na capa do cupom
	End Sub_Total,
	Round(Cast(Isnull(I.VDesc,0 ) As  Decimal(16,4)),2)  As Valor_Desconto,
	Round(Cast( 0 As Decimal(16,4)),2) As Valor_Acrescimo,
	Case When Cast(Isnull(I.VDesc,0 ) As  Decimal(16,4)) > 0 
		 Then --Desconto no Item
			Round(Cast(Isnull(I.vItem,0 ) As Decimal(16,4)),2) 
		 Else     --Desconto na capa do cupom
			Round(Cast(Isnull(I.vProd,0 ) As Decimal(16,4)),2)
	End Valor_Total,

	Case When Cast(Isnull(I.VDesc,0 ) As  Decimal(16,4)) > 0 
		 Then --Desconto no Item
			(Cast(Isnull(I.vDesc,0 ) As Decimal(16,4))*100 )/
			(Cast(Isnull(I.vProd,0)  As Decimal(16,4)))
		 Else     --Desconto na capa do cupom
			Cast(0 As Decimal(16,4))
	End Porc_Desconto,
	Round(Cast(0 As Decimal(16,4)),2) As Porc_Acrescimo,
	I.ICMSorig+I.ICMSCST As Tributacao, --Confirmar
	C.Cancelado,
    (Select Top 1 B.Codigo_barra From Cfc_CodBarras B Where B.Produto = P.codigo) As Codigo_Barra,
    '01' As Vendedor,
    (Select Top 1 B.Colecao   From Cfc_CodBarras B Where B.Produto = P.codigo)  As Colecao_Cupom,
    (Select Top 1 B.Grade     From Cfc_CodBarras B Where B.Produto = P.codigo)  As Grade_Cupom,
    (Select Top 1 B.Grade_Tam From Cfc_CodBarras B Where B.Produto = P.codigo)  As Grade_Tam_Cupom,
    (Select Top 1 B.Item      From Cfc_CodBarras B Where B.Produto = P.codigo)  As CB_Item_Cupom,
    C.Venda_Dev,
	P.Descricao As Desc_Prod,
	'N'  As Produto_Kit, --Inserido valor de 'N', conferir
    CP.Divisao, --Divisao do produto
	Round(Cast(Isnull(vRatDesc,0) As Decimal(16,4)),2) As Desconto_Rateio,
	Round(CAST(0 As Decimal(16,4)),2) As Acrescimo_Rateio,--Confirmar
	P.Descricao As Descricao_Impressa,
	P.Unidade As Unidade_Impressa,
	CAST(0 As Decimal(16,4)) As IPI,
    CAST(0 As Decimal(16,4)) As Porc_IPI,
	'1' As Tipo_Comerc,
	PF.Porc_TotTributos,
	Cast( 0 As Decimal(16,4)) As Vr_TotTributos, --Confirmar
	PF.Porc_Trib_Federal, 
    PF.Porc_Trib_Estadual,
    PF.Porc_Trib_Municipal,
    Round(
	      ISNULL(PF.Porc_Trib_Federal,0)* ( Cast(Isnull(I.vItem,0) As Decimal(16,4)) / 100)
		 ,2 
	     ) As Vr_Trib_Federal,
    Round(
	      ISNULL(PF.Porc_Trib_Estadual,0)* ( Cast(Isnull(I.vItem,0) As Decimal(16,4)) / 100)
		 ,2 
	     ) As Vr_Trib_Estadual,
    Round(
	      ISNULL(PF.Porc_Trib_Municipal,0)* ( Cast(Isnull(I.vItem,0) As Decimal(16,4)) / 100)
		 ,2 
	     ) As Vr_Trib_Municipal,
    PF.Codigo_Concatenado As Codigo_Produto_Concat
Into ImpLoj_Itens_CuponsSAT
From ImpLoj_CuponsSAT C
LEFT JOIN Loj_CFE_XML_ITEM I ON I.FK_Loj_CFE_XML = C.ID_XML
LEFT JOIN Loj_CFE_XML_PGTO PG ON PG.FK_Loj_CFE_XML = C.ID_XML
left Join Produtos P On P.Codigo = Right('000000'+I.cProd,6)
left Join CFC_Produtos cp on cp.Empresa = p.Empresa and cp.Codigo = p.Codigo
Inner Join Produtos_Cod_Concat_EFD PF ON PF.Empresa = P.Empresa And pf.Cod_Produto = P.Codigo
/*********************************************************************************************************/



/****Loj_Itens_Cupons_Imposto****************************************************************************/

Select
	(Select Top 1 Id_Empresa From Empresas Where Codigo_Empresas =@Empresa) As Id_Empresa,
	Isnull((Select Max(Id) From Loj_Itens_Cupons_Imposto),0) +Row_Number() Over (Order By C.Empresa) As Id,
	C.Empresa,
	C.Maquina,
	C.Data,
	C.Controle,
	I.Item,
	Round(Cast(Isnull(I.pICMS,0) As Decimal(16,4)),2) As Aliq_ICMS,
	Round(Cast(Isnull(I.vICMS,0) As Decimal(16,4)),2) As Vr_ICMS,
	Cast( 0 As Decimal(16,4)) As Aliq_Reducao,
	Cast( 0 As Decimal(16,4)) As Aliq_IPI,
	Cast( 0 As Decimal(16,4)) As Valor_IPI,
	Substring(I.CFOP,1,1)+'.'+Substring(I.CFOP,2,3) As NatOP,
    (Select Top 1 L.Sequencia From Liv_Natureza L Where REPLACE(L.Codigo,'.','') = i.CFOP And L.Aliq_ICMS = I.pICMS)
     As Seq,--Confirmar --7117.11.00     
	SUBSTRING(I.NCM,1,4)+'.'+SUBSTRING(I.NCM,5,2)+'.'+SUBSTRING(I.NCM,7,2) As ClassFisc,
	Cast(0 As Decimal(16,4)) As Vr_Frete,
	Cast(0 As Decimal(16,4)) As Vr_Seguro,
	Cast(0 As Decimal(16,4)) As Vr_Despesa,
	Round(Cast(Isnull(I.pPIS,0) As Decimal(16,4)),2) As Porc_PIS,
	Round(Cast(Isnull(I.vPIS,0) As Decimal(16,4)),2) As Vr_PIS,
	Round(Cast(Isnull(I.pCOFINS,0) As Decimal(16,4)),2) As Porc_COFINS,
	--Cast(0 As Decimal(16,4)) As Porc_COFINS,
	Round(Cast(Isnull(I.vCOFINS,0) As Decimal(16,4)),2) As Vr_COFINS,
	Cast(0 As Decimal(16,4)) As Porc_CSLL,
	Cast(0 As Decimal(16,4)) As Vr_CSLL,
	Cast(0 As Decimal(16,4)) As Porc_ISS,
	Cast(0 As Decimal(16,4)) As Vr_ISS,
	Cast(0 As Decimal(16,4)) As Porc_ReducaoISS,
	Cast(0 As Decimal(16,4)) As Porc_INSS,
	Cast(0 As Decimal(16,4)) As Vr_INSS,
	Cast(0 As Decimal(16,4)) As Porc_IR,
	Cast(0 As Decimal(16,4)) As Vr_IR,
	Cast(0 As Decimal(16,4)) As Porc_Suframa,
	Cast(0 As Decimal(16,4)) As Vr_Suframa,
	Round(Cast(Isnull(I.vITEM,0) As Decimal(16,4)),2) As Vr_BCICMS,
	Round( Cast(Isnull(I.Vr_IPI_Isento,0) As Decimal(16,4)),2 )  As Vr_IPI_Isento,
    Round( Cast(Isnull(I.Vr_IPI_Outras,0) As Decimal(16,4)),2 )  As Vr_IPI_Outras,
    Round( Cast(Isnull(I.Vr_ICMS_Isento,0) As Decimal(16,4)),2 ) As Vr_ICMS_Isento,
    Round( Cast(Isnull(I.Vr_ICMS_Outras,0) As Decimal(16,4)),2 ) As Vr_ICMS_Outras,
    '3' As T,
	Round( Cast(Isnull(I.PISvBC,0) As Decimal(16,4)),2 ) As BC_PIS,
    Round( Cast(Isnull(I.COFINSvBC,0) As Decimal(16,4)),2 ) As BC_COFINS,
	Cast(0 As Decimal(16,4)) As PorcDescICMSSuf,
	Cast(0 As Decimal(16,4)) As VrDescICMSSuframa,
	Cast(0 As Decimal(16,4)) As PorcDescIPISuf,
	Cast(0 As Decimal(16,4)) As VrDescIPISuframa,
	Cast(0 As Decimal(16,4)) As PorcDescPISSuf,
	Cast(0 As Decimal(16,4)) As VrDescPISSuframa,
	Cast(0 As Decimal(16,4)) As PorcDescCOFINSSuf,
	Cast(0 As Decimal(16,4)) As VrDescCOFINSSuframa,
	Cast(0 As Decimal(16,4)) As Porc_Bonificacao,
	Cast(0 As Decimal(16,4)) As Valor_Bonificacao,
	I.ICMSorig+I.ICMSCST As Trib,
	I.PISCST    As ST_PIS,
	I.IPICST    As ST_IPI,
    I.COFINSCST As ST_COFINS,
	'4' As ModBCST, --Confirmar
	Round( Cast(Isnull(I.IPIvBC,0) As Decimal(16,4)),2 ) As BC_IPI,
	Cast(0 As Decimal(16,4)) As Porc_ICMS_Subst,
	Cast(0 As Decimal(16,4)) As Vr_ICMS_Subst,
	Cast(0 As Decimal(16,4)) As Vr_BCICMS_Subst,
	Cast(0 As Decimal(16,4)) As Porc_ICMS_Antes_ST,
	Cast(0 As Decimal(16,4)) As ICMS_Subst,
	Cast(0 As Decimal(16,4)) As Porc_IVA,
	Round( Cast(Isnull(I.vIssQN,0) As Decimal(16,4)),2 ) As Vr_BC_ISSQN,
	I.CSOSN As CSOSN,
	NULL As ST_ISSQN,
	Cast(0 As Decimal(16,4)) As Porc_ICMS_SN,
	Cast(0 As Decimal(16,4)) As Vr_ICMS_SN,
	Cast(0 As Decimal(16,4)) As Cod_EAN_GTIN,
	I.Codigo_Produto_Concat As Codigo_Produto_Concat,
	P.Descricao As Descricao_Produto_Concat,
	Cast(0 As Decimal(16,4)) As Id_Cod_DIPAM,
	Cast(0 As Decimal(16,4)) As Vr_Red_BC,
	'N' As Ctrl_Emprest_Terceiros,
	0 As ID_Fat_FCI,
	PF.Id_Liv_ProdutosOrigem As Id_Liv_ProdutosOrigem,
	'N'  As Nao_Calcular_Reducao, 	
	NULL As ISS_cMunFG, --Confirmar
	NULL As Dest_CodIBGECidade, --Confirmar
	NULL As CEST --Confirmar
Into ImpLoj_Itens_Cupons_ImpostoSAT
From ImpLoj_CuponsSAT C
LEFT JOIN Loj_CFE_XML_ITEM I ON I.FK_Loj_CFE_XML = C.ID_XML
LEFT JOIN Loj_CFE_XML_PGTO PG ON PG.FK_Loj_CFE_XML = C.ID_XML
left Join Produtos P On P.Codigo = I.Produto
Left Join CFC_Produtos cp on cp.Empresa = p.Empresa and cp.Codigo = p.Codigo
Left Join Produtos_Cod_Concat_EFD PF ON PF.Empresa = P.Empresa And pf.Cod_Produto = P.Codigo

/**************************************************************************************************/

/*******Loj_Cupons_Finalizadores**************************************/

--Select Top 1 * from Loj_Cupons_Finalizadores
Select 
DISTINCT
  C.Empresa, 
  C.Maquina, 
  C.Data, 
  C.Controle,
  PG.CMP As Finalizador, --Confirmar
  Pg.vMP As Valor,
  C.Data As Data_Finalizador
  --pg.*
Into ImpLoj_Cupons_FinalizadoresSAT
From ImpLoj_CuponsSAT C
LEFT JOIN Loj_CFE_XML_ITEM I ON I.FK_Loj_CFE_XML = C.ID_XML
LEFT JOIN Loj_CFE_XML_PGTO PG ON PG.FK_Loj_CFE_XML = C.ID_XML
/*********************************************************************/

/***Loj_Cupons_Dados_CFE**************************************************/
Select 
  C.Empresa, 
  C.Maquina, 
  C.Data, 
  C.Controle,
  REPLACE(X.Nome_Xml,'AD','') As ChaveConsulta,
  CAST(X.demi AS SmallDateTime) As HoraEmissao,
  X.nCfe,
  '0199' As Cod_SAT,
  '1' As tpAMP,
  X.assinaturaQRCODE,
  '1' ID_SAT,
  (Select MAX(Id_TRANSACAO) FROM Loj_Cupons_Dados_Cfe ) As ID_Transacao,
  NULL As ChaveConsulta_Cancelamento,
  NULL As Hora_Cancelamento,
  NULL As ID_Transacao_Cancelamento,
  NULL As assinaturaQRCODE_Cancelamento
Into ImpLoj_Cupons_Dados_CFESAT 
From ImpLoj_CuponsSAT C
Inner Join Loj_CFE_XML X ON X.ID = C.ID_XML

/*******************************************************************************/


