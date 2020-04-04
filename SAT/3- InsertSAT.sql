/*
 
De1lete From Loj_Cupons_Dados_Cfe
Where Empresa = '01'
De1lete from loj_cupons_Finalizadores
Where Empresa = '01'
del1ete from loj_itens_cupons_imposto
Where Empresa = '01'
del1ete from loj_itens_cupons 
Where Empresa = '01'
del1ete from loj_cupons
Where Empresa = '01'
*/

/*****Insert Loj_Cupons*******************************/
Insert into Loj_Cupons(
   Empresa, Maquina, Data, Controle, Sub_Total,Valor_Desconto,Valor_Acrescimo,
   Total_Cupom, Troco_Dinheiro,Troco_Vale,Operador,Hora, Cliente,Cancelado,
   Status, Convenio, Flag,Venda_Dev,tipo_Venda,imp_Orcamento, Data_Hora_Cupom,
   Controle_Interno,Tabela,Margem_Venda,Status_Bloq,COO, COO_Nfce,Aguarda_Fat
)
Select 
   Empresa, 
   Maquina, Data, Controle, Sub_Total,Valor_Desconto,Valor_Acrescimo,
   Total_Cupom, Troco_Dinheiro,Troco_Vale,Operador,Hora, Cliente,Cancelado,
   Status, Convenio, Flag,Venda_Dev,tipo_Venda,imp_Orcamento, Data_Hora_Cupom,
   Controle_Interno,Tabela,Margem_Venda,Status_Bloq,COO, COO_Nfce,Aguarda_Fat
from ImpLoj_CuponsSAT C 
Where Not Exists (
  Select 'x' 
  From Loj_Cupons CT 
  Where CT.Empresa = C.Empresa 
  And   CT.Maquina = C.Maquina 
  And   CT.Data = C.Data 
  And   CT.Controle = C.Controle
)
/****************************************************/

/***Insert Loj_Itens_Cupons*****************************************/
Insert Into Loj_Itens_Cupons (
	Empresa,
	Maquina,
	Data,
	Controle,
	Item,
	Empresa_Produto,
	Produto,
	Quantidade,
	Preco_Unitario,
	Sub_Total,
	Valor_Desconto,
	Valor_Acrescimo,
	Valor_Total,
	Porc_Desconto,
	Porc_Acrescimo,
	Tributacao,
	Cancelado,
	Codigo_Barra,
	Vendedor,
	Colecao_Cupom,
	Grade_Cupom,
	Grade_Tam_Cupom,
	CB_Item_Cupom,
	Venda_Dev,
	Desc_Prod,
	Produto_Kit,
	Divisao,
	Desconto_Rateio,
	Acrescimo_Rateio,
	Descricao_Impressa,
	Unidade_Impressa,
	IPI,
	Porc_IPI,
	Tipo_Comerc,
	Porc_TotTributos,
	Vr_TotTributos,
	Porc_Trib_Federal,
	Porc_Trib_Estadual,
	Porc_Trib_Municipal,
	Vr_Trib_Federal,
	Vr_Trib_Estadual,
	Vr_Trib_Municipal,
	Codigo_Produto_Concat
)
Select
	I.Empresa,
	I.Maquina,
	I.Data,
	I.Controle,
	I.Item,
	I.Empresa_Produto,
	I.Produto,
	I.Quantidade,
	I.Preco_Unitario,
	I.Sub_Total,
	I.Valor_Desconto,
	I.Valor_Acrescimo,
	I.Valor_Total,
	I.Porc_Desconto,
	I.Porc_Acrescimo,
	I.Tributacao,
	I.Cancelado,
	I.Codigo_Barra,
	I.Vendedor,
	I.Colecao_Cupom,
	I.Grade_Cupom,
	I.Grade_Tam_Cupom,
	I.CB_Item_Cupom,
	I.Venda_Dev,
	I.Desc_Prod,
	I.Produto_Kit,
	I.Divisao,
	I.Desconto_Rateio,
	I.Acrescimo_Rateio,
	I.Descricao_Impressa,
	I.Unidade_Impressa,
	I.IPI,
	I.Porc_IPI,
	I.Tipo_Comerc,
	I.Porc_TotTributos,
	I.Vr_TotTributos,
	I.Porc_Trib_Federal,
	I.Porc_Trib_Estadual,
	I.Porc_Trib_Municipal,
	I.Vr_Trib_Federal,
	I.Vr_Trib_Estadual,
	I.Vr_Trib_Municipal,
	I.Codigo_Produto_Concat
From ImpLoj_Itens_CuponsSAT I 
Where Not Exists 
        (
           Select 'x' 
		   From Loj_Itens_Cupons im 
		   Where Im.Empresa = I.Empresa 
		   And Im.Maquina = I.Maquina
           And Im.Data = I.Data
		   And Im.Controle = I.Controle And Im.Item = I.Item 
        )

/**************************************************************************/

/****Insert LOJ_ITENS_CUPONS_IMPOSTO*******************************/
INSERT INTO LOJ_ITENS_CUPONS_IMPOSTO (
	Id_Empresa,
	Id,
	Empresa,
	Maquina,
	Data,
	Controle,
	Item,
	Aliq_ICMS,
	Vr_ICMS,
	Aliq_Reducao,
	Aliq_IPI,
	Valor_IPI,
	NatOP,
	Seq,
	ClassFisc,
	Vr_Frete,
	Vr_Seguro,
	Vr_Despesa,
	Porc_PIS,
	Vr_PIS,
	Porc_COFINS,
	Vr_COFINS,
	Porc_CSLL,
	Vr_CSLL,
	Porc_ISS,
	Vr_ISS,
	Porc_ReducaoISS,
	Porc_INSS,
	Vr_INSS,
	Porc_IR,
	Vr_IR,
	Porc_Suframa,
	Vr_Suframa,
	Vr_BCICMS,
	Vr_IPI_Isento,
	Vr_IPI_Outras,
	Vr_ICMS_Isento,
	Vr_ICMS_Outras,
	T,
	BC_PIS,
	BC_COFINS,
	PorcDescICMSSuf,
	VrDescICMSSuframa,
	PorcDescIPISuf,
	VrDescIPISuframa,
	PorcDescPISSuf,
	VrDescPISSuframa,
	PorcDescCOFINSSuf,
	VrDescCOFINSSuframa,
	Porc_Bonificacao,
	Valor_Bonificacao,
	Trib,
	ST_PIS,
	ST_IPI,
	ST_COFINS,
	ModBCST,
	BC_IPI,
	Porc_ICMS_Subst,
	Vr_ICMS_Subst,
	Vr_BCICMS_Subst,
	Porc_ICMS_Antes_ST,
	ICMS_Subst,
	Porc_IVA,
	Vr_BC_ISSQN,
	CSOSN,
	ST_ISSQN,
	Porc_ICMS_SN,
	Vr_ICMS_SN,
	Cod_EAN_GTIN,
	Codigo_Produto_Concat,
	Descricao_Produto_Concat,
	Id_Cod_DIPAM,
	Vr_Red_BC,
	Ctrl_Emprest_Terceiros,
	ID_Fat_FCI,
	Id_Liv_ProdutosOrigem,
	Nao_Calcular_Reducao,
	ISS_cMunFG,
	Dest_CodIBGECidade,
	CEST
) 

SELECT
 --TOP 1  
    I.Id_Empresa,
	I.Id,
	I.Empresa,
	I.Maquina,
	I.Data,
	I.Controle,
	I.Item,
	I.Aliq_ICMS,
	I.Vr_ICMS,
	I.Aliq_Reducao,
	I.Aliq_IPI,
	I.Valor_IPI,
	I.NatOP,
	I.Seq,
	I.ClassFisc,
	I.Vr_Frete,
	I.Vr_Seguro,
	I.Vr_Despesa,
	I.Porc_PIS,
	I.Vr_PIS,
	I.Porc_COFINS,
	I.Vr_COFINS,
	I.Porc_CSLL,
	I.Vr_CSLL,
	I.Porc_ISS,
	I.Vr_ISS,
	I.Porc_ReducaoISS,
	I.Porc_INSS,
	I.Vr_INSS,
	I.Porc_IR,
	I.Vr_IR,
	I.Porc_Suframa,
	I.Vr_Suframa,
	I.Vr_BCICMS,
	I.Vr_IPI_Isento,
	I.Vr_IPI_Outras,
	I.Vr_ICMS_Isento,
	I.Vr_ICMS_Outras,
	I.T,
	I.BC_PIS,
	I.BC_COFINS,
	I.PorcDescICMSSuf,
	I.VrDescICMSSuframa,
	I.PorcDescIPISuf,
	I.VrDescIPISuframa,
	I.PorcDescPISSuf,
	I.VrDescPISSuframa,
	I.PorcDescCOFINSSuf,
	I.VrDescCOFINSSuframa,
	I.Porc_Bonificacao,
	I.Valor_Bonificacao,
	I.Trib,
	I.ST_PIS,
	I.ST_IPI,
	I.ST_COFINS,
	I.ModBCST,
	I.BC_IPI,
	I.Porc_ICMS_Subst,
	I.Vr_ICMS_Subst,
	I.Vr_BCICMS_Subst,
	I.Porc_ICMS_Antes_ST,
	I.ICMS_Subst,
	I.Porc_IVA,
	I.Vr_BC_ISSQN,
	I.CSOSN,
	I.ST_ISSQN,
	I.Porc_ICMS_SN,
	I.Vr_ICMS_SN,
	I.Cod_EAN_GTIN,
	I.Codigo_Produto_Concat,
	I.Descricao_Produto_Concat,
	I.Id_Cod_DIPAM,
	I.Vr_Red_BC,
	I.Ctrl_Emprest_Terceiros,
	I.ID_Fat_FCI,
	I.Id_Liv_ProdutosOrigem,
	I.Nao_Calcular_Reducao,
	I.ISS_cMunFG,
	I.Dest_CodIBGECidade,
	I.CEST
FROM ImpLoj_Itens_Cupons_ImpostoSAT I 
Where Not exists (
      Select 'x' From Loj_Itens_Cupons_Imposto IM 
	             Where IM.Empresa  = I.Empresa 
				 And   Im.Maquina  = I.Maquina 
				 And   Im.Data     = I.Data 
				 And   Im.Controle = I.Controle
				 And   Im.Item     = I.Item
)
/************************************************************************************************************/




/*****Insert Loj_Cupons_Finalizadores*************************************/
Insert Into Loj_Cupons_Finalizadores (
  Empresa, 
  Maquina, 
  Data, 
  Controle,
  Finalizador,
  Valor,
  Data_Finalizador
)
Select 
  F.Empresa, 
  F.Maquina, 
  F.Data, 
  F.Controle,
  F.Finalizador, --Confirmar
  F.Valor,
  F.Data_Finalizador
From ImpLoj_Cupons_FinalizadoresSAT F
Where Not Exists (
           Select 'x' From Loj_Cupons_Finalizadores FI 
		              Where FI.Empresa = F.Empresa 
					  And Fi.Maquina = F.Maquina 
					  And Fi.Data = F.Data 
					  And Fi.Controle = F.Controle 
					  And FI.Finalizador = F.Finalizador
)
/*********************************************************************************/


/*****Insert Loj_Cupons_Dados_CFE********************************/
Insert Into Loj_Cupons_Dados_Cfe( 
	Empresa,
	Maquina,
	Data,
	Controle,
	ChaveConsulta,
	HoraEmissao,
	nCfe,
	Cod_SAT,
	tpAMP,
	assinaturaQRCODE,
	ID_SAT,
	ID_Transacao,
	ChaveConsulta_Cancelamento,
	Hora_Cancelamento,
	ID_Transacao_Cancelamento,
	assinaturaQRCODE_Cancelamento
)

Select 
	D.Empresa,
	D.Maquina,
	D.Data,
	D.Controle,
	D.ChaveConsulta,
	D.HoraEmissao,
	D.nCfe,
	D.Cod_SAT,
	D.tpAMP,
	D.assinaturaQRCODE,
	D.ID_SAT,
	D.ID_Transacao,
	D.ChaveConsulta_Cancelamento,
	D.Hora_Cancelamento,
	D.ID_Transacao_Cancelamento,
	D.assinaturaQRCODE_Cancelamento
From ImpLoj_Cupons_Dados_CFESAT D 
Where Not Exists 
 (
    Select 'x' From Loj_Cupons_Dados_Cfe E 
	Where E.Empresa  = D.Empresa And E.Maquina = D.Maquina 
	And E.Data = D.Data And E.Controle = D.Controle
 )

