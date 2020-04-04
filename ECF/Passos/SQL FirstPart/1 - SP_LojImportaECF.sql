--Exemplo de execução da procedure.
--exec SP_LojImportaECF '\\192.168.0.111\Trabalho\Desenvolvedores\teste\BEE59190.O9H'

if exists(select null from sysobjects where name = 'SP_LojImportaECF')
  drop procedure dbo.SP_LojImportaECF
GO
create procedure dbo.SP_LojImportaECF(@Arquivo varchar(500))
as begin
/********************************************
  Data Criação: 30-01-2018
  Autor: Vanderson / Marcelo Botardo
  Objetivo: Criar estrutura de tabelas, espelhando
			or aquivos "ATO COTEPE" com o banco de dados, para simular uma migração de dados
			e geração de Livros Fiscais visando contemplar a geração do SPED.
  Cliente Alvo: Camila Klein
********************************************/
  set @Arquivo = ''''+@Arquivo+''''

/*** Tabelas ********/
-- Alterar procedure para manter os registros já existentes, e apagar os demais via parâmetro
	If Object_Id('TempDB..#ImpCuponsECF') Is Not Null
	Drop Table #ImpCuponsECF

	If Object_Id('TempDB..#ImpCupons') Is Not Null
	Drop Table #ImpCupons

/*********************************************************/
Create Table #ImpCuponsECF (
   Linha Varchar(Max),  
)

	exec('

	Bulk Insert #ImpCuponsECF
	From '+@Arquivo+'
	With (
	   RowTerminator =''\n''
	)')

	Declare 
	 @Linha Varchar(04)

	Select 
	  Identity(Int,1,1) Id,* 
	Into #ImpCupons
	From #ImpCuponsECF 
	--where substring(linha,1,3)='E12'

	Set @Linha=''

	While (Select Count(*) From #ImpCupons )> 0 
	 Begin 
	   Set @Linha= (Select Top 1 Substring(Linha,1,3) From #ImpCupons)

	   If(@Linha = 'E01') 
		 Begin 
		 insert Into Loj_ECF_E01	 
		   Select --Linha E01
			 /*01*/ SUBSTRING(Linha, 1,3)    TipoRegistro,
			 /*02*/ SUBSTRING(Linha, 4,20)   NrFabricacaoECF,
			 /*03*/ SUBSTRING(Linha, 24,1)   LetraIndicativa,
			 /*04*/ SUBSTRING(Linha, 25,7)   TipoECF,
			 /*05*/ SUBSTRING(Linha, 32,20)  MarcaECF,
			 /*06*/ SUBSTRING(Linha, 52,20)  ModeloECF,
			 /*07*/ SUBSTRING(Linha, 72,10)  VersaoAtualSoftwareBasico,
			 /*08*/ SUBSTRING(Linha, 82,8)   DataGravacaoMF,
			 /*09*/ SUBSTRING(Linha, 90,6)   HoraGravacao,
			 /*10*/ SUBSTRING(Linha, 96,3)   NrOrdemSequencialECF,
			 /*11*/ SUBSTRING(Linha, 99,14)  CNPJEstabelecimento,
			 /*12*/ SUBSTRING(Linha, 113,3)  CodigoComandoGerarArquivo,
			 /*13*/ SUBSTRING(Linha, 116,6)  ContadorReducaoInicioCapturado,
			 /*14*/ SUBSTRING(Linha, 122,6)  ContadorReducaoFimCapturado,
			 /*15*/ SUBSTRING(Linha, 128,8)  DataInicioCapturado,
			 /*16*/ SUBSTRING(Linha, 136,8)  DataFimCapturado,
			 /*17*/ SUBSTRING(Linha, 144,8)  VersaoBibliotecaFabricante,
			 /*18*/ SUBSTRING(Linha, 152,15) VersaoAtoCotebe
		   --Into Loj_ECF_E01	 
		   From #ImpCupons 
		   Where Substring(Linha,1,3) = @Linha
		
		/***** Tabela de relacionamento intermediario com a tabela empresas ***/
		insert Into Loj_ECF_E99
			Select distinct
				E.Codigo_Empresas, 
				E.CGC_Empresas,
				E.Razao_Social_Empresas,
				E01.CNPJEstabelecimento
 
			From Loj_ECF_E01 E01 
				Left Join Empresas E On (Replace(Replace(Replace(E.CGC_Empresas,'.',''),'/',''),'-','') = E01.CNPJEstabelecimento) 
			where not exists(select null from Loj_ECF_E99 E99
								where E01.CNPJEstabelecimento = E99.CNPJEstabelecimento and 
									E.CGC_Empresas = E99.CGC_Empresas)

	  End

	  If(@Linha = 'E02') 
		 Begin 
		 INSERT Into Loj_ECF_E02
		   Select --Linha E02
			 /*01*/ SUBSTRING(Linha, 1,3)    TipoRegistro,
			 /*02*/ SUBSTRING(Linha, 4,20)   NrFabricacaoECF,
			 /*03*/ SUBSTRING(Linha, 24,1)   LetraIndicativa,
			 /*04*/ SUBSTRING(Linha, 25,20)  ModeloECF,
			 /*06*/ SUBSTRING(Linha, 45,14)  CNPJEstabelecimento,
			 /*06*/ SUBSTRING(Linha, 59,14)  InscricaiEstadualEstabelecimento,
			 /*07*/ SUBSTRING(Linha, 73,40)  RazaoSocialEstabelecimento,
			 /*08*/ SUBSTRING(Linha, 113,120)  EnderecoEstabelecimento,
			 /*09*/ SUBSTRING(Linha, 233,8)  DataCadastroUsuarioECF,
			 /*10*/ SUBSTRING(Linha, 241,6)  HoraCadastroUsuarioECF,
			 /*11*/ SUBSTRING(Linha, 247,6)  CRORelativoAoCadastro,
			 /*12*/ SUBSTRING(Linha, 253,18)  ValorAcumuladoGT,
			 /*13*/ SUBSTRING(Linha, 271,2) NroOrdemUsuarioECF
		   --Into Loj_ECF_E02
		   From #ImpCupons 
		   Where Substring(Linha,1,3) = @Linha
		 End   
     
	  If(@Linha = 'E03') 
		 Begin      
			--Linha E03 (Cotepe) 
			INSERT Into Loj_ECF_E03
			Select 
			 /*01*/ SUBSTRING(Linha, 1,3)     TipoRegistro,
			 /*02*/ SUBSTRING(Linha, 4,20)    NrFabricacaoECF,
			 /*03*/ SUBSTRING(Linha, 24,1)    LetraIndicativa,
			 /*04*/ SUBSTRING(Linha, 25,20)   ModeloECF,
			 /*05*/ SUBSTRING(Linha, 45,2)    NrPrestadorServico,
			 /*06*/ SUBSTRING(Linha, 47,8)    DataCadastroPrestador,
			 /*07*/ SUBSTRING(Linha, 55,6)    HoraCadastroServico,
			 /*08*/ SUBSTRING(Linha, 61,14)   CNPJPrestadorServico,
			 /*09*/ SUBSTRING(Linha, 75,14)   InscricaoEstadual,
			 /*10*/ SUBSTRING(Linha, 89,18)   SmatoriaVenda
		   --Into Loj_ECF_E03
		   From #ImpCupons 
		   Where Substring(Linha,1,3) = @Linha
		 End   
     
	  If(@Linha = 'E04') 
		 Begin
			--Linha E04 (Cotepe)
			INSERT Into Loj_ECF_E04
			Select 
			 /*01*/ SUBSTRING(Linha, 1,3)     TipoRegistro,
			 /*02*/ SUBSTRING(Linha, 4,20)    NrFabricacaoECF,
			 /*03*/ SUBSTRING(Linha, 24,1)    LetraIndicativa,
			 /*04*/ SUBSTRING(Linha, 25,20)   ModeloECF,
			 /*05*/ SUBSTRING(Linha, 45,2)    NrOrdemUsuarioECF,
			 /*06*/ SUBSTRING(Linha, 47,8)    DataCadastroUsuarioECF,
			 /*07*/ SUBSTRING(Linha, 55,6)    HoraCadastroUsuarioECF,
			 /*08*/ SUBSTRING(Linha, 61,14)   CNPJUsuarioECF,
			 /*09*/ SUBSTRING(Linha, 75,14)   InscricaoEstadualUsuarioECF,
			 /*10*/ SUBSTRING(Linha, 89,6)    CROCadastroUsuarioECF,
			 /*11*/ SUBSTRING(Linha, 95,18)   ValorGT
		   --Into Loj_ECF_E04
		   From #ImpCupons 
		   Where Substring(Linha,1,3) = @Linha
		 End
	
	   If(@Linha = 'E05') 
		 Begin
			 --Linha E05(Cotepe)
			 INSERT Into Loj_ECF_E05
			 Select 
			 /*01*/ SUBSTRING(Linha, 1,3)     TipoRegistro,
			 /*02*/ SUBSTRING(Linha, 4,20)    NrFabricacaoECF,
			 /*03*/ SUBSTRING(Linha, 24,1)    LetraIndicativa,
			 /*04*/ SUBSTRING(Linha, 25,20)   ModeloECF,
			 /*05*/ SUBSTRING(Linha, 45,14)   CNPJUsuarioECF,
			 /*06*/ SUBSTRING(Linha, 59,8)    DataCadastroUsuarioECF,
			 /*07*/ SUBSTRING(Linha, 67,6)    HoraCadastroUsuarioECF,
			 /*08*/ SUBSTRING(Linha, 73,1)    CO,
			 /*09*/ SUBSTRING(Linha, 74,1)    C1,
			 /*10*/ SUBSTRING(Linha, 75,1)    C2,
			 /*11*/ SUBSTRING(Linha, 76,1)    C3,
			 /*12*/ SUBSTRING(Linha, 77,1)    C4,
			 /*13*/ SUBSTRING(Linha, 78,1)    C5,
			 /*14*/ SUBSTRING(Linha, 79,1)    C6,
			 /*15*/ SUBSTRING(Linha, 80,1)    C7,
			 /*16*/ SUBSTRING(Linha, 81,1)    C8,
			 /*17*/ SUBSTRING(Linha, 82,1)    C9
		   --Into Loj_ECF_E05
		   From #ImpCupons 
		   Where Substring(Linha,1,3) = @Linha
		 End

	  If(@Linha = 'E06') 
		 Begin
			--Linha E06(Cotepe)
			INSERT Into Loj_ECF_E06
			Select 
			 /*01*/ SUBSTRING(Linha, 1,3)     TipoRegistro,
			 /*02*/ SUBSTRING(Linha, 4,20)    NrFabricacaoECF,
			 /*03*/ SUBSTRING(Linha, 24,1)    LetraIndicativa,
			 /*04*/ SUBSTRING(Linha, 25,20)   ModeloECF,
			 /*05*/ SUBSTRING(Linha, 45,14)   CNPJUsuarioECF,
			 /*06*/ SUBSTRING(Linha, 59,8)    DataCadastroUsuarioECF,
			 /*07*/ SUBSTRING(Linha, 67,6)    HoraCadastroUsuarioECF,
			 /*08*/ SUBSTRING(Linha, 73,4)    SimboloMoeda
		   --Into Loj_ECF_E06
		   From #ImpCupons 
		   Where Substring(Linha,1,3) = @Linha
		 End
	
	  If(@Linha = 'E07') 
		 Begin	--Linha E07(Cotepe)
		 INSERT Into Loj_ECF_E07
			Select 
			 /*01*/ SUBSTRING(Linha, 1,3)     TipoRegistro,
			 /*02*/ SUBSTRING(Linha, 4,20)    NrFabricacaoECF,
			 /*03*/ SUBSTRING(Linha, 24,1)    LetraIndicativa,
			 /*04*/ SUBSTRING(Linha, 25,20)   ModeloECF,
			 /*05*/ SUBSTRING(Linha, 45,10)   VersaoSB,
			 /*06*/ SUBSTRING(Linha, 55,8)    DataGravacaoVersaoSB
			--Into Loj_ECF_E07
			From #ImpCupons 
			Where Substring(Linha,1,3) = @Linha
		  End

	  If(@Linha = 'E08') 
		 Begin
			--Linha E08(Cotepe)
			INSERT Into Loj_ECF_E08
			Select 
			 /*01*/ SUBSTRING(Linha, 1,3)     TipoRegistro,
			 /*02*/ SUBSTRING(Linha, 4,20)    NrFabricacaoECF,
			 /*03*/ SUBSTRING(Linha, 24,1)    LetraIndicativa,
			 /*04*/ SUBSTRING(Linha, 25,20)   ModeloECF,
			 /*05*/ SUBSTRING(Linha, 45,14)   CNPJUsuario,
			 /*06*/ SUBSTRING(Linha, 59,20)   NrMDF
			--Into Loj_ECF_E08
			From #ImpCupons 
			Where Substring(Linha,1,3) = @Linha
		 End  
	
	  If(@Linha = 'E09') 
		 Begin	
			--Linha E09(Cotepe)
			INSERT Into Loj_ECF_E09
			Select 
			 /*01*/ SUBSTRING(Linha, 1,3)     TipoRegistro,
			 /*02*/ SUBSTRING(Linha, 4,20)    NrFabricacaoECF,
			 /*03*/ SUBSTRING(Linha, 24,1)    LetraIndicativa,
			 /*04*/ SUBSTRING(Linha, 25,20)   ModeloECF,
			 /*05*/ SUBSTRING(Linha, 45,6)    CROIntervencaoTecnica,
			 /*06*/ SUBSTRING(Linha, 51,8)    DataGravacaoCRO,
			 /*07*/ SUBSTRING(Linha, 59,6)    HoraGravacao,
			 /*08*/ SUBSTRING(Linha, 65,1)    IndicadorPerdaDado,
			 /*09*/ SUBSTRING(Linha, 66,1)    TipoIntervencao, --'I' Interveção física, 'L' Intervenção lógica
			 /*10*/ SUBSTRING(Linha, 67,4)    CRZ,
			 /*11*/ SUBSTRING(Linha, 71,9)    COO
			--Into Loj_ECF_E09
			From #ImpCupons 
			Where Substring(Linha,1,3) = @Linha
		 End

	  If(@Linha = 'E10') 
		 Begin
			 --Linha E10(Cotepe)
			 INSERT Into Loj_ECF_E10
			Select 
			 /*01*/ SUBSTRING(Linha, 1,3)     TipoRegistro,
			 /*02*/ SUBSTRING(Linha, 4,20)    NrFabricacaoECF,
			 /*03*/ SUBSTRING(Linha, 24,1)    LetraIndicativa,
			 /*04*/ SUBSTRING(Linha, 25,20)   ModeloECF,
			 /*05*/ SUBSTRING(Linha, 45,6)    ContadorFitaDetalhe,
			 /*06*/ SUBSTRING(Linha, 51,8)    DtEmissaoFitaDetalhe,
			 /*07*/ SUBSTRING(Linha, 59,6)    COOInicialFitaDetalhe,
			 /*08*/ SUBSTRING(Linha, 65,6)    COOFinalFitaDetalhe,
			 /*09*/ SUBSTRING(Linha, 71,14)   CNPFJUsuario
			--Into Loj_ECF_E10
			From #ImpCupons 
			Where Substring(Linha,1,3) = @Linha
		 End
  
	  If(@Linha = 'E11') 
		 Begin
			--Linha E11(Cotepe)
			INSERT Into Loj_ECF_E11
			Select 
			 /*01*/ SUBSTRING(Linha, 1,3)     TipoRegistro,
			 /*02*/ SUBSTRING(Linha, 4,20)    NrFabricacaoECF,
			 /*03*/ SUBSTRING(Linha, 24,1)    LetraIndicativa,
			 /*04*/ SUBSTRING(Linha, 25,20)   ModeloECF,
			 /*05*/ SUBSTRING(Linha, 45,6)    ValorAcumuladoCRZ,
			 /*06*/ SUBSTRING(Linha, 51,6)    ValorAcumuladoCRO,
			 /*07*/ SUBSTRING(Linha, 57,6)    ValorAcumuladoCOO,
			 /*08*/ SUBSTRING(Linha, 63,6)    ValorAcumuladoGNF,
			 /*09*/ SUBSTRING(Linha, 69,6)    ValorAcumuladoCCF,
			 /*10*/ SUBSTRING(Linha, 75,6)    ValorAcumuladoCVC,
			 /*11*/ SUBSTRING(Linha, 81,6)    ValorAcumuladoCBP,
			 /*12*/ SUBSTRING(Linha, 87,6)    ValorAcumuladoGRG,
			 /*13*/ SUBSTRING(Linha, 93,6)    ValorAcumuladoCMV,
			 /*14*/ SUBSTRING(Linha, 99,6)    ValorAcumuladoCFD,
			 /*15*/ SUBSTRING(Linha, 105,18)   ValorAcumuladoGT,
			 /*16*/ SUBSTRING(Linha, 123,8)   DataGeracaoArquivo,
			 /*17*/ SUBSTRING(Linha, 131,6)   HoraGeracaoArquivo
			--Into Loj_ECF_E11
			From #ImpCupons 
			Where Substring(Linha,1,3) = @Linha
		 End

	  If(@Linha = 'E12') 
		 Begin
			--Linha E12(Cotepe)
			INSERT Into Loj_ECF_E12
			Select 
			 /*01*/ SUBSTRING(Linha, 1,3)     TipoRegistro,
			 /*02*/ SUBSTRING(Linha, 4,20)    NrFabricacaoECF,
			 /*03*/ SUBSTRING(Linha, 24,1)    LetraIndicativa,
			 /*04*/ SUBSTRING(Linha, 25,20)   ModeloECF,
			 /*05*/ SUBSTRING(Linha, 45,2)    NrUsuarioECF,
			 /*06*/ SUBSTRING(Linha, 47,6)    NrContadorCRZ,
			 /*07*/ SUBSTRING(Linha, 53,6)    NrContadorCOO,
			 /*08*/ SUBSTRING(Linha, 59,6)    NrContadorCRO,
			 /*09*/ SUBSTRING(Linha, 65,8)    DataMovimentoZ,
			 /*10*/ SUBSTRING(Linha, 73,8)    DataEmissaoZ,
			 /*11*/ SUBSTRING(Linha, 81,6)    HoraEmissaoZ,
			 /*12*/ SUBSTRING(Linha, 87,14)   VendaBrutaDiaria,
			 /*13*/ SUBSTRING(Linha, 101,1)   IncidenciaDesconto
		   --Into Loj_ECF_E12
		   From #ImpCupons 
		   Where Substring(Linha,1,3) = @Linha
		 End

	  If(@Linha = 'E13') 
		 Begin
			--Linha E13(Cotepe)
			INSERT Into Loj_ECF_E13
			Select 
			 /*01*/ SUBSTRING(Linha, 1,3)     TipoRegistro,
			 /*02*/ SUBSTRING(Linha, 4,20)    NrFabricacaoECF,
			 /*03*/ SUBSTRING(Linha, 24,1)    LetraIndicativa,
			 /*04*/ SUBSTRING(Linha, 25,20)   ModeloECF,
			 /*05*/ SUBSTRING(Linha, 45,2)    NrUsuarioECF,
			 /*06*/ SUBSTRING(Linha, 47,6)    NrContadorCRZ,
			 /*07*/ SUBSTRING(Linha, 53,7)    TotalizadorParcial,
			 /*08*/ SUBSTRING(Linha, 60,13)   ValorAcumulado
		   --Into Loj_ECF_E13
		   From #ImpCupons 
		   Where Substring(Linha,1,3) = @Linha
		 End   
     

	  If(@Linha = 'E14') 
		 Begin
		 INSERT Into Loj_ECF_E14
			Select 
			 /*01*/ SUBSTRING(Linha, 1,3)     TipoRegistro,
			 /*02*/ SUBSTRING(Linha, 4,20)    NrFabricacaoECF,
			 /*03*/ SUBSTRING(Linha, 24,1)    LetraIndicativa,
			 /*04*/ SUBSTRING(Linha, 25,20)   ModeloECF,
			 /*05*/ SUBSTRING(Linha, 45,2)    NrUsuarioECF,
			 /*06*/ SUBSTRING(Linha, 47,6)    CCF,
			 /*07*/ SUBSTRING(Linha, 53,6)    COO,
			 /*08*/ SUBSTRING(Linha, 59,8)    DataEmissao,
			 /*09*/ SUBSTRING(Linha, 67,14)   SubTotal, --2 casas decimais
			 /*10*/ SUBSTRING(Linha, 81,13)   Desconto,
			 /*11*/ SUBSTRING(Linha, 94,1)    IndicadorDesconto, --'v' Valor monetário e 'P' para percentual
			 /*12*/ SUBSTRING(Linha, 95,13)   Acrescimo,
			 /*13*/ SUBSTRING(Linha, 108,1)   IndicadorAcrescimo, --'v' Valor monetário e 'P' para percentual
			 /*14*/ SUBSTRING(Linha, 109,14)  VrTotalLiquido,
			 /*15*/ SUBSTRING(Linha, 123,1)   IndicadorCancelamento, --'S' ou 'N'
			 /*16*/ SUBSTRING(Linha, 124,13)  CancelamentoAcrescimo,
			 /*17*/ SUBSTRING(Linha, 137,1)   OrdemDescontoAcrescimo,--'D' OU 'A'
			 /*18*/ SUBSTRING(Linha, 138,40)  NomeAdquirente,
			 /*19*/ SUBSTRING(Linha, 178,14)  CPF_CNPJ_Adquirente 
			--Into Loj_ECF_E14
			From #ImpCupons 
			Where Substring(Linha,1,3) = @Linha
		 End   
	 
	   If(@Linha = 'E15') 
		 Begin
			--Linha E15(Cotepe)
			INSERT Into Loj_ECF_E15
			Select 
			 /*01*/ SUBSTRING(Linha, 1,3)     TipoRegistro,
			 /*02*/ SUBSTRING(Linha, 4,20)    NrFabricacaoECF,
			 /*03*/ SUBSTRING(Linha, 24,1)    LetraIndicativa,
			 /*04*/ SUBSTRING(Linha, 25,20)   ModeloECF,
			 /*05*/ SUBSTRING(Linha, 45,2)    NrOrdemUsuario,
			 /*06*/ SUBSTRING(Linha, 47,6)    COO,
			 /*07*/ SUBSTRING(Linha, 53,6)    CCF,
			 /*08*/ SUBSTRING(Linha, 59,3)    NrItem,
			 /*09*/ SUBSTRING(Linha, 62,14)   CodigoProduto,
			 /*10*/ SUBSTRING(Linha, 76,100)  DescricaoProduto,
			 /*11*/ SUBSTRING(Linha, 176,7)   Quantidade,
			 /*12*/ SUBSTRING(Linha, 183,3)   Unidade,
			 /*13*/ SUBSTRING(Linha, 186,8)   ValorUnitario,
			 /*14*/ SUBSTRING(Linha, 194,8)   Desconto,
			 /*15*/ SUBSTRING(Linha, 202,8)   Acrescimo,
			 /*16*/ SUBSTRING(Linha, 210,14)  VrTotalLiquido,
			 /*17*/ SUBSTRING(Linha, 224,7)   TotalizadorParcial,
			 /*18*/ SUBSTRING(Linha, 231,1)   IndcadorCancelamento,-- 'S', 'N'
			 /*19*/ SUBSTRING(Linha, 232,7)   QtdeCancelada,
			 /*20*/ SUBSTRING(Linha, 239,13)  ValorCancelado,
			 /*21*/ SUBSTRING(Linha, 252,13)  CancelamentoAcrescimo,
			 /*22*/ SUBSTRING(Linha, 265,1)   IndicadorArredondamento, -- 'T' Trucamento, 'A' Arredondamento
			 /*23*/ SUBSTRING(Linha, 266,1)   CasasDecimaisQuantidade,
			 /*24*/ SUBSTRING(Linha, 267,1)   CasasDecimaisVrUnitario
		   --Into Loj_ECF_E15
		   From #ImpCupons 
		   Where Substring(Linha,1,3) = @Linha
		 End   
    
		If(@Linha = 'E16') 
		 Begin
			--Linha E16(Cotepe)
			INSERT Into Loj_ECF_E16
			Select 
			 /*01*/ SUBSTRING(Linha, 1,3)     TipoRegistro,
			 /*02*/ SUBSTRING(Linha, 4,20)    NrFabricacaoECF,
			 /*03*/ SUBSTRING(Linha, 24,1)    LetraIndicativa,
			 /*04*/ SUBSTRING(Linha, 25,20)   ModeloECF,
			 /*05*/ SUBSTRING(Linha, 45,2)    NrOrdemUsuario,
			 /*06*/ SUBSTRING(Linha, 47,6)    COO,
			 /*07*/ SUBSTRING(Linha, 53,6)    GNF,
			 /*08*/ SUBSTRING(Linha, 59,6)    GRG,
			 /*09*/ SUBSTRING(Linha, 65,4)    CDC,
			 /*10*/ SUBSTRING(Linha, 69,6)    CRZ,
			 /*11*/ SUBSTRING(Linha, 75,2)    DenominacaoTipoDocumento,
			 /*12*/ SUBSTRING(Linha, 77,8)    DataFinalEmissao,
			 /*13*/ SUBSTRING(Linha, 85,6)    HoraFinalemissao
		   --Into Loj_ECF_E16
		   From #ImpCupons 
		   Where Substring(Linha,1,3) = @Linha
		 End   
    
		If(@Linha = 'E17') 
		 Begin
			--Linha E17(Cotepe)
			INSERT Into Loj_ECF_E17
			Select 
			 /*01*/ SUBSTRING(Linha, 1,3)     TipoRegistro,
			 /*02*/ SUBSTRING(Linha, 4,20)    NrFabricacaoECF,
			 /*03*/ SUBSTRING(Linha, 24,1)    LetraIndicativa,
			 /*04*/ SUBSTRING(Linha, 25,20)   ModeloECF,
			 /*05*/ SUBSTRING(Linha, 45,2)    NrOrdemUsuario,
			 /*06*/ SUBSTRING(Linha, 47,6)    CRZ,
			 /*07*/ SUBSTRING(Linha, 53,15)   TotalizadorNaoFiscal,
			 /*08*/ SUBSTRING(Linha, 68,13)    ValorAcumulado--Duas Casas Decimais
		   --Into Loj_ECF_E17
		   From #ImpCupons 
		   Where Substring(Linha,1,3) = @Linha
		 End
	 
   
		If(@Linha = 'E18') 
		 Begin
			--Linha E18(Cotepe)
			INSERT Into Loj_ECF_E18
			Select 
			 /*01*/ SUBSTRING(Linha, 1,3)     TipoRegistro,
			 /*02*/ SUBSTRING(Linha, 4,20)    NrFabricacaoECF,
			 /*03*/ SUBSTRING(Linha, 24,1)    LetraIndicativa,
			 /*04*/ SUBSTRING(Linha, 25,20)   ModeloECF,
			 /*05*/ SUBSTRING(Linha, 45,2)    NrOrdemUsuario,
			 /*06*/ SUBSTRING(Linha, 47,6)    CRZ,
			 /*07*/ SUBSTRING(Linha, 53,15)   DescTotalizadorMeioPagamento,
			 /*08*/ SUBSTRING(Linha, 68,13)   ValorAcumulado--Duas Casas Decimais
		   --Into Loj_ECF_E18
		   From #ImpCupons 
		   Where Substring(Linha,1,3) = @Linha
		 End   
    
   
		If(@Linha = 'E19') 
		 Begin
			--Linha E19(Cotepe)
			INSERT Into Loj_ECF_E19
			Select 
			 /*01*/ SUBSTRING(Linha, 1,3)     TipoRegistro,
			 /*02*/ SUBSTRING(Linha, 4,20)    NrFabricacaoECF,
			 /*03*/ SUBSTRING(Linha, 24,1)    LetraIndicativa,
			 /*04*/ SUBSTRING(Linha, 25,20)   ModeloECF,
			 /*05*/ SUBSTRING(Linha, 45,2)    NrOrdemUsuario,
			 /*06*/ SUBSTRING(Linha, 47,6)    COO,
			 /*07*/ SUBSTRING(Linha, 53,6)    GNF,
			 /*08*/ SUBSTRING(Linha, 59,8)    DataEmissao,
			 /*09*/ SUBSTRING(Linha, 67,14)   SubTotal,
			 /*10*/ SUBSTRING(Linha, 81,13)   Desconto,
			 /*11*/ SUBSTRING(Linha, 94,1)    IndicadorDesconto, --'V' Valor Monetario, 'P' Percentual
			 /*12*/ SUBSTRING(Linha, 95,13)   Acrescimo,
			 /*13*/ SUBSTRING(Linha, 108,1)   IndicadorAcrescimo, --'V' Valor Monetario, 'P' Percentual
			 /*14*/ SUBSTRING(Linha, 109,14)  ValorTotalLiquido,
			 /*15*/ SUBSTRING(Linha, 123,1)   IndicadorCancelamento,
			 /*16*/ SUBSTRING(Linha, 124,13)  ValorCancelamento,
			 /*17*/ SUBSTRING(Linha, 137,1)   OrdemDesconto,
			 /*18*/ SUBSTRING(Linha, 138,40)  NomeAdquirente,
			 /*19*/ SUBSTRING(Linha, 178,14)  CPF_CNPJAdquirente
		   --Into Loj_ECF_E19
		   From #ImpCupons 
		   Where Substring(Linha,1,3) = @Linha
		 End
	 
	   If(@Linha = 'E20') 
		 Begin
			--Linha E20(Cotepe)
			INSERT Into Loj_ECF_E20
			Select 
			 /*01*/ SUBSTRING(Linha, 1,3)     TipoRegistro,
			 /*02*/ SUBSTRING(Linha, 4,20)    NrFabricacaoECF,
			 /*03*/ SUBSTRING(Linha, 24,1)    LetraIndicativa,
			 /*04*/ SUBSTRING(Linha, 25,20)   ModeloECF,
			 /*05*/ SUBSTRING(Linha, 45,2)    NrOrdemUsuario,
			 /*06*/ SUBSTRING(Linha, 47,6)    COO,
			 /*07*/ SUBSTRING(Linha, 53,6)    GNF,
			 /*08*/ SUBSTRING(Linha, 59,3)    NumeroItem,
			 /*09*/ SUBSTRING(Linha, 62,15)   DenominacaoOperacao,
			 /*10*/ SUBSTRING(Linha, 77,13)   ValorOperacao,
			 /*11*/ SUBSTRING(Linha, 90,13)   Desconto,
			 /*12*/ SUBSTRING(Linha, 103,13)  Acrescimo,
			 /*13*/ SUBSTRING(Linha, 116,13)  VrTotalLiquido,
			 /*14*/ SUBSTRING(Linha, 129,1)   IndicadorCancelamento,
			 /*15*/ SUBSTRING(Linha, 130,13)  ValorCancelamento
		   --Into Loj_ECF_E20
		   From #ImpCupons 
		   Where Substring(Linha,1,3) = @Linha
		 End

	  If(@Linha = 'E21') 
		 Begin
			--Linha E21Cotepe)
			INSERT Into Loj_ECF_E21
			Select 
			 /*01*/ SUBSTRING(Linha, 1,3)     TipoRegistro,
			 /*02*/ SUBSTRING(Linha, 4,20)    NrFabricacaoECF,
			 /*03*/ SUBSTRING(Linha, 24,1)    LetraIndicativa,
			 /*04*/ SUBSTRING(Linha, 25,20)   ModeloECF,
			 /*05*/ SUBSTRING(Linha, 45,2)    NrOrdemUsuario,
			 /*06*/ SUBSTRING(Linha, 47,6)    COO,
			 /*07*/ SUBSTRING(Linha, 53,6)    CCF,
			 /*08*/ SUBSTRING(Linha, 59,6)    GNF,
			 /*09*/ SUBSTRING(Linha, 65,15)   MeioPagamento,  
			 /*09*/ SUBSTRING(Linha, 80,13)   ValorPago,
			 /*09*/ SUBSTRING(Linha, 93,1)    IndicadorDesconto,--'S', 'N', 'P' Parcial
			 /*09*/ SUBSTRING(Linha, 94,13)   ValorEstornado --Duas casas decimais
		   --Into Loj_ECF_E21
		   From #ImpCupons 
		   Where Substring(Linha,1,3) = @Linha
		 End
	 
	  If(@Linha = 'E22') 
		 Begin
			--Linha E22Cotepe)
			INSERT Into Loj_ECF_E22
			Select 
			 /*01*/ SUBSTRING(Linha, 1,3)     TipoRegistro,
			 /*02*/ SUBSTRING(Linha, 4,20)    NrFabricacaoECF,
			 /*03*/ SUBSTRING(Linha, 24,20)   ModeloECF,
			 /*05*/ SUBSTRING(Linha, 44,4)    ContadorCTM,
			 /*06*/ SUBSTRING(Linha, 48,8)    DataGravacao
		   --Into Loj_ECF_E22
		   From #ImpCupons 
		   Where Substring(Linha,1,3) = @Linha
		 End

	   Delete From #ImpCupons Where Substring(Linha,1,3) = @Linha

	End -- FIM DO WHILE
   
end
GO