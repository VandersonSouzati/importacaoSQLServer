
--exec SP_LojImportaECF 'D:\Arquivos\LojCuponsECF.txt'

If OBJECT_ID('ImpLoj_CuponsCopia') Is Not Null
Drop Table ImpLoj_CuponsCopia

If OBJECT_ID('Tempdb..#DadosCliente') Is Not Null
Drop Table #DadosCliente
GO


Declare @Cliente Varchar(16), @Estado Varchar(02)
Set @Estado = (
                Select Estado_Empresas 
                From empresas
                Where CGC_Empresas = (Select top 1 CGC_Empresas From Loj_ECF_E99)
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
	      


/***Insert na Cfc-Prod_Colecoes*********/
Insert Into Cfc_Prod_Colecoes (
	Empresa,
	Codigo,
	Colecao,
	Cod_Etq,
    Status
)

Select 
  '01' Empresa,
  P.Codigo, 
  '0001' Colecao,
  NULL As Cod_Etq,
  NULL As Status
From Produtos P
Where Not Exists (
			Select 'x' 
			From Cfc_Prod_Colecoes C 
			Where C.Empresa = P.Empresa 
			And   C.Codigo = P.Codigo
			And   C.Colecao = '0001'
)
/***************************************/

/***Insert CFC_CodBarras**************/
Insert Into Cfc_CodBarras ( 
	Empresa,
	Produto,
	Colecao,
	Grade,
	Grade_Tam,
	Item,
	Codigo_Barra,
	Qtde
)
Select 
 /*01*/ '01' Empresa,
 /*02*/ P.Codigo As Produto,
 /*03*/ '0001' As Colecao,
 /*04*/ '001'  As Grade, 
 /*05*/ 1  As Grade_Tam,
 /*06*/ 1    As Item,
 /*07*/ P.Codigo As Codigo_Barra,
 /*08*/ NULL Qtde 
From 
Produtos P
Where Not Exists(
   Select 'x' 
   From Cfc_CodBarras CB 
   Where CB.Empresa = P.Empresa 
   And   CB.Produto = P.Codigo
   And   CB.Codigo_Barra = P.Codigo
   And   CB.Colecao = '0001'
   And   CB.Grade ='001' 
   And   CB.Grade_Tam =1
   And   CB.Item =1 
)
/*****************************************/ 


/**Insert Cfc_Produtos*********************************************/
Insert Into Cfc_Produtos (
	Empresa,
	Codigo,
	Descr_Tabela,
	Area,
	Marca,
	Tamanho,
	Local_Padrao,
	Composicao,
	TecidoCruOrigem,
	Produto2aQual,
	Data_Inclusao,
	Data_Alteracao,
	Usuario_Incl,
	Usuario_Alt,
	Colecao,
	Tecido,
	Gramatura,
	Grade,
	Usar_Colecao,
	Usar_Grade,
	Pr_Reposicao,
	Estacao,
	Inativo,
	Tipo_Etiqueta,
	Permitir_Desconto,
	Divisao,
	SubMarca,
	Tipo,
	Cod_Tecido,
	Ordem_Corte,
	Codigo_Antigo,
	MarkUp,
	Estoque_Seguranca,
	PESO,
	Sinonimo1,
	Sinonimo2,
	Sinonimo3,
	Sinonimo4,
	Aplicacao,
	Cod_Fabricante,
	Obs_Venda,
	Descricao_Tecnica,
	Casco,
	Garantia_Km,
	Garantia_Dias,
	Pr_Custo,
	Produto_Base,
	Diretorio_Doc,
	Acondicionamento,
	Endereco_Estoque
)
Select  
 /*01*/ P.Empresa,
 /*02*/ P.Codigo, 
 /*03*/ P.Descricao As Descr_Tabela,
 /*04*/ '0001' As Area,
 /*05*/ '0001' As Marca,
 /*06*/ NULL   As Tamanho,
 /*07*/ '0001' As Local_Padrao,
 /*08*/ NULL   As Composicao,
 /*09*/ NULL   As TecidoCruOrigem,
 /*10*/ NULL   As Produto2aQual,
 /*11*/ (select cast(getdate() as smalldatetime)) As Data_Inclusao,
 /*12*/ (select cast(getdate() as smalldatetime)) As Data_Alteracao,
 /*13*/ 'Master' As Usuario_Incl,
 /*14*/ 'Master' As Usuario_Alt,
 /*15*/ NULL     As Colecao,
 /*16*/ 'N'    As Tecido,
 /*17*/ NULL   As Gramatura,
 /*18*/ '001'  As Grade,
 /*19*/ 'N'    As Usar_Colecao,--Confirmar,
 /*20*/ 'N'    As Usar_Grade, --Confirmar,
 /*21*/ Cast( 0 As Decimal(16,4)) As Pr_Reposicao,--Confirmar,
 /*22*/ '01'   As Estacao,
 /*23*/ P.Inativo,
 /*24*/ '0'    As Tipo_Etiqueta,
 /*25*/ 'S'    As Permitir_Desconto, --Confirmar,
 /*26*/ '02'   As Divisao, --Confirmar 
 /*27*/ '0001' As SubMarca,
 /*28*/ '00'   As Tipo, --Confirmar
 /*29*/ NULL   As Cod_Tecido,
 /*30*/ NULL   As Ordem_Corte,
 /*31*/ NULL   As Codigo_Antigo,
 /*32*/ NULL   As MarkUP,
 /*33*/ NULL   As Estoque_Seguranca,
 /*34*/ NULL   As PESO,
 /*35*/ NULL   As Sinonimo1,
 /*36*/ NULL   As Sinonimo2,
 /*37*/ NULL   As Sinonimo3,
 /*38*/ NULL   As Sinonimo4,
 /*39*/ NULL   As Aplicacao,
 /*40*/ NULL   As Cod_Fabricante,
 /*41*/ NULL   As Obs_Venda,
 /*42*/ NULL   As Descricao_Tecnica,
 /*43*/ NULL   As Casco,
 /*44*/ NULL   As Garantia_KM,
 /*45*/ NULL   As Garantia_Dias,
 /*46*/ Cast(0 As Decimal(16,4)) As Pr_Custo, --Verificar
 /*47*/ NULL   As Produto_Base,
 /*48*/ NULL   As Diretorio_Doc,
 /*49*/ NULL   As Acondicionamento,
 /*50*/ NULL   As Endereco_Estoque
From Produtos P
Where Not Exists(
   Select 'x' From Cfc_Produtos CP Where CP.Empresa = P.Empresa And CP.Codigo = P.Codigo
) 
/******************************************************************/



/***Insert Loj_Cupons*********************************************/
Select  
 Distinct
   Identity(Int, 1,1) Id,
  /*01*/ (
            Select Top 1 E99.Codigo_Empresas 
			From Loj_ECF_E99 E99 
		   -- Where E99.CNPJEstabelecimento = E14.CPF_CNPJ_Adquirente
		 ) Empresa,
  /*02*/ '0001' As Maquina,
  /*03*/ E14.DataEmissao As Data,
  /*04*/ '00' As Controle, --Gerar 
  /*05*/ Cast(Cast(E14.VrTotalLiquido As Decimal(16,4))/100 As Decimal(16,4)) As Sub_Total,
  /*06*/ Cast(Cast(E14.Desconto As Decimal(16,4))/100 As Decimal(16,4))  As Valor_Desconto,
  /*07*/ Cast(Cast(E14.Acrescimo As Decimal(16,4))/100 As Decimal(16,4)) As Valor_Acrescimo,
  /*08*/ Cast(Cast(E14.SubTotal As Decimal(16,4))/100 As Decimal(16,4))  As Total_Cupom,
  /*09*/ Cast(0 As Decimal(16,4)) As Troco_Dinheiro, --Confirmar Troco
  /*10*/ Cast(0 As Decimal(16,4)) As Troco_Vale,  --Confirmar Vale
  /*11*/ '0001' As Operador,
  /*12*/ NULL As Hora,
  /*13*/ @Cliente As Cliente, ---Cadastrar(Tratar CNPJ)
  /*14*/ E14.IndicadorCancelamento As Cancelado,
  /*15*/ Case when E14.IndicadorCancelamento='S' Then 'C' Else 'F'  End Status,
  /*16*/ NULL As Operador_CupomCancel,
  /*17*/ 'Insert ECF' As Observacao,
  /*18*/ NULL  As Estado_Impressao,
  /*19*/ NULL  As Null_Parcela,
  /*20*/ NULL  As Cond_Pagto_Extenso,
  /*21*/ NULL  As Cod_Parcela,
  /*22*/ '000' As Convenio,
  /*23*/ NULL  As Desc_Convenio,
  /*24*/ NULL  As Observacao2, 
  /*25*/ NULL  As Observacao3,
  /*26*/ E14.CCF As Flag,
  /*27*/ 'V'   As Venda_Dev,
  /*28*/ NULL  As Maquina_Ref,
  /*29*/ NULL  As Controle_Ref,
  /*30*/ '07'  As Tipo_Venda, --Cadastrar Tipo de Venda
  /*31*/ '0'   As Imp_Orcamento,
  /*32*/ E14.DataEmissao As Data_Hora_Cupom,
  /*33*/ '000000000000' As Controle_Interno,--Gerar o controleInterno
  /*34*/ '001' As Tabela,
  /*35*/ NULL  As Contrl_Int_Devol,
  /*36*/ NULL  As Entrega,
  /*37*/ NULL  As Controle_Condicional,
  /*38*/ Cast( 0 As Decimal(16,2)) As Margem_Venda,--Confirmar
  /*39*/ NULL As Tipo_Impressao_CF,
  /*40*/ '0'  As Status_Bloq, --Confirmar
  /*41*/ NULL As Flag_Estoque,
  /*42*/ NULL As Pedido_Fat,
  /*43*/ NULL As Fech_Crediario,
  /*44*/ NULL As Ficha,
  /*45*/ NULL As Tipo_Venda_Ref,
  /*46*/ NULL As Data_Ref,
  /*47*/ NULL As Nr_Nota,
  /*48*/ NULL As Serie,
  /*49*/ NULL As Vendedor_Externo,
  /*50*/ NULL As CPF_CNPJ_Consumidor,
  /*51*/ NULL As Empresa_Pedido,
  /*52*/ E14.COO ,
  /*53*/ NULL As Nome_Adquirente,
  /*54*/ NULL As SubTotal_Seguro,
  /*55*/ NULL As Total_Seguro,
  /*56*/ NULL As Nro_Nota_Manual,
  /*57*/ NULL As Serie_Nota_Manual,
  /*58*/ '0'  As COO_Nfce, --Confirmar
  /*59*/ NULL As Endereco_Adquirente,
  /*60*/ NULL As Obs_SAT,
  /*61*/ 'N'  As Aguarda_Fat 
Into ImpLoj_CuponsCopia 
From Loj_ECF_E12 E12
Inner Join Loj_ECF_E14 E14 ON (E12.NrFabricacaoECF = E14.NrFabricacaoECF and E12.DataMovimentoZ = E14.DataEmissao)
Inner Join Loj_ECF_E15 E15 ON (E14.NrFabricacaoECF = E15.NrFabricacaoECF and E14.COO = E15.COO and E14.CCF = E15.CCF)
LEFT Join Loj_ECF_E21 E21 ON (E14.NrFabricacaoECF = E21.NrFabricacaoECF and E14.COO = E21.COO and E21.CCF = E15.CCF)
/***********************************************************************************************************************/


/***********************************************************************************************/
--Atualizar o  controle, 31/01/2018 alterar para alterar o controle_interno tambem 
Declare @total int, @contador int,@Data SmallDateTime, @Controle int,
 @Empresa Char(02), @Maquina Varchar(04)
 
Set @total = (Select COUNT(*) From ImpLoj_CuponsCopia) 
Set @contador =1
Set @Controle =0
While(@contador <= @total) 
Begin 
  Set @Data = (Select Top 1 DATA From ImpLoj_CuponsCopia Where Id= @Contador)
  Set @Controle = @Controle +1
  
  If(@Data) <> (Select Top 1 DATA From ImpLoj_CuponsCopia Where Id = @contador-1)
    begin 
      Set @Controle = 1
    End
   
    Update ImpLoj_CuponsCopia Set Controle = @Controle 
    Where Id = @contador
    
  Set @contador = @contador +1
End
alter table ImpLoj_CuponsCopia drop column id

/*********************************************************************************************/


/*****Insert Loj_Cupons*******************************/
Insert into Loj_Cupons
Select * from ImpLoj_CuponsCopia C 
Where Not Exists (
  Select 'x' 
  From Loj_Cupons CT 
  Where CT.Empresa = C.Empresa 
  And   CT.Maquina = C.Maquina 
  And   CT.Data = C.Data 
  And   CT.Controle = C.Controle
)
/****************************************************/


/**Insert Loj_Itens_Cupons****************************************/
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
	Operador_CupomCancel,
	Codigo_Barra,
	Vendedor,
	COLECAO_CUPOM,
	GRADE_CUPOM,
	GRADE_TAM_CUPOM,
	CB_ITEM_CUPOM,
	Justificativa,
	Venda_Dev,
	Desc_Prod,
	Produto_Kit,
	Garantia_Km,
	Garantia_Dias,
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
	Nr_Lancamento,
	Porc_FaixaDesc,
	Vr_FaixaDesc,
	Total_FaixaDesc,
	Preco_Unitario_Original,
	Promocao,
	Porc_Trib_Federal,
	Porc_Trib_Estadual,
	Porc_Trib_Municipal,
	Vr_Trib_Federal,
	Vr_Trib_Estadual,
	Vr_Trib_Municipal,
	Codigo_Produto_Concat,
	Preco_Unitario_Liquido,
	ID_Promo,
	Tabela,
	Preco_Dev,
	Dev_Cons_Prod,
	Dev_Empresa,
	Dev_Maquina,
	Dev_Data,
	Dev_Controle,
	Dev_Item
)
Select --Top 1 
  /*01*/ L.Empresa,
  /*02*/ L.Maquina,
  /*03*/ L.Data,
  /*04*/ L.Controle, 
  /*05*/ E15.NrItem As Item,
  /*06*/ (Select Top 1 Empresa_Produtos From Liv_Diario Where Empresa = L.Empresa)  As Empresa_Produto,
  /*07*/ P.Codigo As Produto,
  /*08*/ Cast(E15.Quantidade As Int)/1000 As Quantidade, --Verificar,
  /*09*/ Cast(E15.ValorUnitario As Decimal(16,4)) /100  As Preco_Unitario,
  /*10*/ Cast(E15.VrTotalLiquido As decimal(16,4)) /100  As Sub_Total,
  /*11*/ Cast(E15.Desconto As Decimal(16,4)) /100 As Valor_Desconto,
  /*12*/ Cast(E15.Acrescimo As Decimal(16,4)) /100 As Valor_acrescimo,
  /*13*/ (Cast(E15.Quantidade As Int)/1000 )  * 
         (Cast(E15.ValorUnitario As Decimal(16,4))/100 ) As Valor_Total,
  /*14*/ Cast(0 As Decimal(16,4)) As Porc_Desconto,
  /*15*/ Cast(0 As Decimal(16,4)) As Porc_Acrescimo,
  /*16*/ (
		   Select Top 1 T.Codigo 
		   From Ret_Tributacoes T 
		   Where T.Aliq_ICMS = Substring(E15.TotalizadorParcial,4,2) 
		 ) As Tributacao,
  /*17*/ NULL As Cancelado,
  /*18*/ NULL As Operador_CupomCancel,
  /*19*/ CB.Codigo_Barra,
  '01' As Vendedor,
  CB.Colecao    As Colecao_Cupom,
  CB.Grade      As Grade_Cupom,
  CB.Grade_Tam  As Grade_Tam_Cupom,
  CB.Item       As CB_Item_Cupom,
  NULL  As Justificativa,
  L.Venda_Dev,
  E15.DescricaoProduto As Desc_Prod,
  'N'  As Produto_Kit, --Inserido valor de 'N', conferir
  NULL As Garantia_Km,
  NULL As Garantia_Dias,
  CP.Divisao, --Divisao do produto
  CAST(0 As Decimal(16,4)) As Desconto_Rateio,--Confirmar
  CAST(0 As Decimal(16,4)) As Acrescimo_Rateio,--Confirmar
  P.Descricao As Descricao_Impressa,--Confirmar
  P.Unidade As Unidade_Impressa,
  CAST(0 As Decimal(16,4)) As IPI,
  CAST(0 As Decimal(16,4)) As Porc_IPI,
  NULL As Tipo_Comerc,
  CAST(0 As Decimal(16,4)) As Porc_TotTributos,
  CAST(0 As Decimal(16,4)) As Vr_TotTributos,
  '0000000' As Nr_Lancamento, --Confirmar Valores
  NULL As Porc_FaixaDesc,
  NULL As Vr_FaixaDesc,
  NULL As Total_FaixaDesc,
  NULL As Preco_Unitario_Original,
  NULL As Promocao,
  PC.Porc_Trib_Federal, 
  PC.Porc_Trib_Estadual,
  PC.Porc_Trib_Municipal,
  CAST(0 As Decimal(16,4)) As Vr_Trib_Federal,
  CAST(0 As Decimal(16,4)) As Vr_Trib_Estadual,
  CAST(0 As Decimal(16,4)) As Vr_Trib_Municipal,
  PC.Codigo_Concatenado As Codigo_Produto_Concat,
  NULL As Preco_Unitario_Liquido,
  NULL As ID_Promo,--,
  NULL As Tabela,
  NULL As  Preco_Dev,
  NULL As Dev_Cons_Prod,
  NULL As Dev_Empresa,
  NULL As Dev_Maquina,
  NULL As Dev_Data,
  NULL As Dev_Controle,
  NULL As Dev_Item
  --E15.*  
From Loj_Cupons L
Inner Join Loj_ECF_E15 E15 ON (E15.CCF = L.FLAG And E15.COO = L.COO)
inner  Join Produtos p On P.Empresa =
           (
               Select Top 1 Empresa_produtos 
               From Liv_Diario 
               Where Empresa= L.Empresa
           ) And P.Codigo = Case When Len(e15.CodigoProduto) < 6
    Then REPLICATE('0', 6 - LEN(e15.codigoProduto)) +   RTrim(e15.codigoProduto)
	Else Substring(codigoProduto,1,6)
	End --Vai ser alterado
inner Join Cfc_Produtos CP On CP.Empresa  = P.Empresa  And CP.Codigo = P.Codigo
Left Join Cfc_CodBarras CB On CB.Empresa = P.Empresa And CB.Produto = P.Codigo
Left Join Produtos_Cod_Concat_EFD PC ON PC.Empresa = P.Empresa And PC.Cod_Produto = P.Codigo
Where Not Exists (
  Select 'x' From Loj_Itens_Cupons CT Where CT.Empresa = L.Empresa And CT.Maquina = L.Maquina 
                                And Ct.Data = L.Data And CT.Controle = L.Controle
)

/*****************************************************************/



/*******Insert Loj_Cupons_Finalizadores****************************/
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
 distinct 
  C.Empresa, 
  C.Maquina,
  C.Data, 
  C.Controle,
  '01' Finalizador,
  Sum(CAST(E21.ValorPago As Decimal(16,4))/100) As Valor,
  C.Data As Data_Finaliador
From Loj_Cupons C
Inner Join Loj_ECF_E21 E21 ON E21.COO = C.COO And E21.CCF = C.Flag
Where Not Exists(
   Select 'x' 
   From Loj_Cupons_Finalizadores F 
   Where F.Empresa = C.Empresa 
   And   F.Maquina = C.Maquina 
   And   F.Data = C.Data 
   And   F.Controle = C.Controle
   And   (
    Select Top 1 Cod_Finalizador 
    From Loj_Parametros_Finalizadores F 
    Where F.Cod_Impressora = E21.MeioPagamento
    Order By F.Cod_Finalizador Desc
  ) = F.Finalizador
)
Group By C.Empresa, C.Maquina, C.Data, C.Controle
/******************************************************************/



/*
SELECT DIVISAO,  * FROM CFC_Produtos
SELECT * FROM CFC_DIVISOES

--dIVISAO 02 
tRIBUTACAO 05
liv_natureza
*/