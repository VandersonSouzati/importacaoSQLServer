if not exists(select null from sysobjects where name = 'Loj_ECF_E01')
	Create table Loj_ECF_E01(
		TipoRegistro	varchar(max) null ,
		NrFabricacaoECF	varchar(max) null ,
		LetraIndicativa	varchar(max) null ,
		TipoECF	varchar(max) null ,
		MarcaECF	varchar(max) null ,
		ModeloECF	varchar(max) null ,
		VersaoAtualSoftwareBasico	varchar(max) null ,
		DataGravacaoMF	varchar(max) null ,
		HoraGravacao	varchar(max) null ,
		NrOrdemSequencialECF	varchar(max) null ,
		CNPJEstabelecimento	varchar(max) null ,
		CodigoComandoGerarArquivo	varchar(max) null ,
		ContadorReducaoInicioCapturado	varchar(max) null ,
		ContadorReducaoFimCapturado	varchar(max) null ,
		DataInicioCapturado	varchar(max) null ,
		DataFimCapturado	varchar(max) null ,
		VersaoBibliotecaFabricante	varchar(max) null ,
		VersaoAtoCotebe	varchar(max) null 

	)

if not exists(select null from sysobjects where name = 'Loj_ECF_E02')	
	Create table 	Loj_ECF_E02	(
		TipoRegistro varchar(max) null,
		NrFabricacaoECF varchar(max) null,
		LetraIndicativa varchar(max) null,
		ModeloECF varchar(max) null,
		CNPJEstabelecimento varchar(max) null,
		InscricaiEstadualEstabelecimento varchar(max) null,
		RazaoSocialEstabelecimento varchar(max) null,
		EnderecoEstabelecimento varchar(max) null,
		DataCadastroUsuarioECF varchar(max) null,
		HoraCadastroUsuarioECF varchar(max) null,
		CRORelativoAoCadastro varchar(max) null,
		ValorAcumuladoGT varchar(max) null,
		NroOrdemUsuarioECF varchar(max) null
	)
if not exists(select null from sysobjects where name = 'Loj_ECF_E04')	
	Create table 	Loj_ECF_E04	(
		TipoRegistro	varchar(max) null ,
		NrFabricacaoECF	varchar(max) null ,
		LetraIndicativa	varchar(max) null ,
		ModeloECF	varchar(max) null ,
		NrOrdemUsuarioECF	varchar(max) null ,
		DataCadastroUsuarioECF	varchar(max) null ,
		HoraCadastroUsuarioECF	varchar(max) null ,
		CNPJUsuarioECF	varchar(max) null ,
		InscricaoEstadualUsuarioECF	varchar(max) null ,
		CROCadastroUsuarioECF	varchar(max) null ,
		ValorGT	varchar(max) null 
	)
if not exists(select null from sysobjects where name = 'Loj_ECF_E05')	
	Create table 	Loj_ECF_E05	(
		TipoRegistro	varchar(max) null ,
		NrFabricacaoECF	varchar(max) null ,
		LetraIndicativa	varchar(max) null ,
		ModeloECF	varchar(max) null ,
		CNPJUsuarioECF	varchar(max) null ,
		DataCadastroUsuarioECF	varchar(max) null ,
		HoraCadastroUsuarioECF	varchar(max) null ,
		CO	varchar(max) null ,
		C1	varchar(max) null ,
		C2	varchar(max) null ,
		C3	varchar(max) null ,
		C4	varchar(max) null ,
		C5	varchar(max) null ,
		C6	varchar(max) null ,
		C7	varchar(max) null ,
		C8	varchar(max) null ,
		C9	varchar(max) null 
	)
if not exists(select null from sysobjects where name = 'Loj_ECF_E06')	
	Create table 	Loj_ECF_E06	(
		TipoRegistro	varchar(max) null ,
		NrFabricacaoECF	varchar(max) null ,
		LetraIndicativa	varchar(max) null ,
		ModeloECF	varchar(max) null ,
		CNPJUsuarioECF	varchar(max) null ,
		DataCadastroUsuarioECF	varchar(max) null ,
		HoraCadastroUsuarioECF	varchar(max) null ,
		SimboloMoeda	varchar(max) null 
	)
if not exists(select null from sysobjects where name = 'Loj_ECF_E07')	
	Create table 	Loj_ECF_E07	(
		TipoRegistro	varchar(max) null ,
		NrFabricacaoECF	varchar(max) null ,
		LetraIndicativa	varchar(max) null ,
		ModeloECF	varchar(max) null ,
		VersaoSB	varchar(max) null ,
		DataGravacaoVersaoSB	varchar(max) null 
	)
if not exists(select null from sysobjects where name = 'Loj_ECF_E08')	
	Create table 	Loj_ECF_E08	(
		TipoRegistro	varchar(max) null ,
		NrFabricacaoECF	varchar(max) null ,
		LetraIndicativa	varchar(max) null ,
		ModeloECF	varchar(max) null ,
		CNPJUsuario	varchar(max) null ,
		NrMDF	varchar(max) null 
	)
if not exists(select null from sysobjects where name = 'Loj_ECF_E09')	
	Create table 	Loj_ECF_E09	(
		TipoRegistro	varchar(max) null ,
		NrFabricacaoECF	varchar(max) null ,
		LetraIndicativa	varchar(max) null ,
		ModeloECF	varchar(max) null ,
		CROIntervencaoTecnica	varchar(max) null ,
		DataGravacaoCRO	varchar(max) null ,
		HoraGravacao	varchar(max) null ,
		IndicadorPerdaDado	varchar(max) null ,
		TipoIntervencao	varchar(max) null ,
		CRZ	varchar(max) null ,
		COO	varchar(max) null 
	)
if not exists(select null from sysobjects where name = 'Loj_ECF_E10')	
	Create table 	Loj_ECF_E10	(
		TipoRegistro	varchar(max) null ,
		NrFabricacaoECF	varchar(max) null ,
		LetraIndicativa	varchar(max) null ,
		ModeloECF	varchar(max) null ,
		ContadorFitaDetalhe	varchar(max) null ,
		DtEmissaoFitaDetalhe	varchar(max) null ,
		COOInicialFitaDetalhe	varchar(max) null ,
		COOFinalFitaDetalhe	varchar(max) null ,
		CNPFJUsuario	varchar(max) null 
	)
if not exists(select null from sysobjects where name = 'Loj_ECF_E11')	
	Create table 	Loj_ECF_E11	(
		TipoRegistro	varchar(max) null ,
		NrFabricacaoECF	varchar(max) null ,
		LetraIndicativa	varchar(max) null ,
		ModeloECF	varchar(max) null ,
		ValorAcumuladoCRZ	varchar(max) null ,
		ValorAcumuladoCRO	varchar(max) null ,
		ValorAcumuladoCOO	varchar(max) null ,
		ValorAcumuladoGNF	varchar(max) null ,
		ValorAcumuladoCCF	varchar(max) null ,
		ValorAcumuladoCVC	varchar(max) null ,
		ValorAcumuladoCBP	varchar(max) null ,
		ValorAcumuladoGRG	varchar(max) null ,
		ValorAcumuladoCMV	varchar(max) null ,
		ValorAcumuladoCFD	varchar(max) null ,
		ValorAcumuladoGT	varchar(max) null ,
		DataGeracaoArquivo	varchar(max) null ,
		HoraGeracaoArquivo	varchar(max) null 
	)
if not exists(select null from sysobjects where name = 'Loj_ECF_E12')	
	Create table 	Loj_ECF_E12	(
		TipoRegistro	varchar(max) null ,
		NrFabricacaoECF	varchar(max) null ,
		LetraIndicativa	varchar(max) null ,
		ModeloECF	varchar(max) null ,
		NrUsuarioECF	varchar(max) null ,
		NrContadorCRZ	varchar(max) null ,
		NrContadorCOO	varchar(max) null ,
		NrContadorCRO	varchar(max) null ,
		DataMovimentoZ	varchar(max) null ,
		DataEmissaoZ	varchar(max) null ,
		HoraEmissaoZ	varchar(max) null ,
		VendaBrutaDiaria	varchar(max) null ,
		IncidenciaDesconto	varchar(max) null 
	)
if not exists(select null from sysobjects where name = 'Loj_ECF_E13')	
	Create table 	Loj_ECF_E13	(
		TipoRegistro	varchar(max) null ,
		NrFabricacaoECF	varchar(max) null ,
		LetraIndicativa	varchar(max) null ,
		ModeloECF	varchar(max) null ,
		NrUsuarioECF	varchar(max) null ,
		NrContadorCRZ	varchar(max) null ,
		TotalizadorParcial	varchar(max) null ,
		ValorAcumulado	varchar(max) null 
	)
if not exists(select null from sysobjects where name = 'Loj_ECF_E14')	
	Create table 	Loj_ECF_E14	(
		TipoRegistro	varchar(max) null ,
		NrFabricacaoECF	varchar(max) null ,
		LetraIndicativa	varchar(max) null ,
		ModeloECF	varchar(max) null ,
		NrUsuarioECF	varchar(max) null ,
		CCF	varchar(max) null ,
		COO	varchar(max) null ,
		DataEmissao	varchar(max) null ,
		SubTotal	varchar(max) null ,
		Desconto	varchar(max) null ,
		IndicadorDesconto	varchar(max) null ,
		Acrescimo	varchar(max) null ,
		IndicadorAcrescimo	varchar(max) null ,
		VrTotalLiquido	varchar(max) null ,
		IndicadorCancelamento	varchar(max) null ,
		CancelamentoAcrescimo	varchar(max) null ,
		OrdemDescontoAcrescimo	varchar(max) null ,
		NomeAdquirente	varchar(max) null ,
		CPF_CNPJ_Adquirente	varchar(max) null 
	)
if not exists(select null from sysobjects where name = 'Loj_ECF_E15')	
	Create table 	Loj_ECF_E15	(
		TipoRegistro	varchar(max) null ,
		NrFabricacaoECF	varchar(max) null ,
		LetraIndicativa	varchar(max) null ,
		ModeloECF	varchar(max) null ,
		NrOrdemUsuario	varchar(max) null ,
		COO	varchar(max) null ,
		CCF	varchar(max) null ,
		NrItem	varchar(max) null ,
		CodigoProduto	varchar(max) null ,
		DescricaoProduto	varchar(max) null ,
		Quantidade	varchar(max) null ,
		Unidade	varchar(max) null ,
		ValorUnitario	varchar(max) null ,
		Desconto	varchar(max) null ,
		Acrescimo	varchar(max) null ,
		VrTotalLiquido	varchar(max) null ,
		TotalizadorParcial	varchar(max) null ,
		IndcadorCancelamento	varchar(max) null ,
		QtdeCancelada	varchar(max) null ,
		ValorCancelado	varchar(max) null ,
		CancelamentoAcrescimo	varchar(max) null ,
		IndicadorArredondamento	varchar(max) null ,
		CasasDecimaisQuantidade	varchar(max) null ,
		CasasDecimaisVrUnitario	varchar(max) null 
	)
if not exists(select null from sysobjects where name = 'Loj_ECF_E16')	
	Create table 	Loj_ECF_E16	(
		TipoRegistro	varchar(max) null ,
		NrFabricacaoECF	varchar(max) null ,
		LetraIndicativa	varchar(max) null ,
		ModeloECF	varchar(max) null ,
		NrOrdemUsuario	varchar(max) null ,
		COO	varchar(max) null ,
		GNF	varchar(max) null ,
		GRG	varchar(max) null ,
		CDC	varchar(max) null ,
		CRZ	varchar(max) null ,
		DenominacaoTipoDocumento	varchar(max) null ,
		DataFinalEmissao	varchar(max) null ,
		HoraFinalemissao	varchar(max) null 
	)
if not exists(select null from sysobjects where name = 'Loj_ECF_E17')	
	Create table 	Loj_ECF_E17	(
		TipoRegistro	varchar(max) null ,
		NrFabricacaoECF	varchar(max) null ,
		LetraIndicativa	varchar(max) null ,
		ModeloECF	varchar(max) null ,
		NrOrdemUsuario	varchar(max) null ,
		CRZ	varchar(max) null ,
		TotalizadorNaoFiscal	varchar(max) null ,
		ValorAcumulado	varchar(max) null 
	)
if not exists(select null from sysobjects where name = 'Loj_ECF_E18')	
	Create table 	Loj_ECF_E18	(
		TipoRegistro	varchar(max) null ,
		NrFabricacaoECF	varchar(max) null ,
		LetraIndicativa	varchar(max) null ,
		ModeloECF	varchar(max) null ,
		NrOrdemUsuario	varchar(max) null ,
		CRZ	varchar(max) null ,
		DescTotalizadorMeioPagamento	varchar(max) null ,
		ValorAcumulado	varchar(max) null 
	)
if not exists(select null from sysobjects where name = 'Loj_ECF_E19')	
	Create table 	Loj_ECF_E19	(
		TipoRegistro	varchar(max) null ,
		NrFabricacaoECF	varchar(max) null ,
		LetraIndicativa	varchar(max) null ,
		ModeloECF	varchar(max) null ,
		NrOrdemUsuario	varchar(max) null ,
		COO	varchar(max) null ,
		GNF	varchar(max) null ,
		DataEmissao	varchar(max) null ,
		SubTotal	varchar(max) null ,
		Desconto	varchar(max) null ,
		IndicadorDesconto	varchar(max) null ,
		Acrescimo	varchar(max) null ,
		IndicadorAcrescimo	varchar(max) null ,
		ValorTotalLiquido	varchar(max) null ,
		IndicadorCancelamento	varchar(max) null ,
		ValorCancelamento	varchar(max) null ,
		OrdemDesconto	varchar(max) null ,
		NomeAdquirente	varchar(max) null ,
		CPF_CNPJAdquirente	varchar(max) null 
	)
if not exists(select null from sysobjects where name = 'Loj_ECF_E20')	
	Create table 	Loj_ECF_E20	(
		TipoRegistro	varchar(max) null ,
		NrFabricacaoECF	varchar(max) null ,
		LetraIndicativa	varchar(max) null ,
		ModeloECF	varchar(max) null ,
		NrOrdemUsuario	varchar(max) null ,
		COO	varchar(max) null ,
		GNF	varchar(max) null ,
		NumeroItem	varchar(max) null ,
		DenominacaoOperacao	varchar(max) null ,
		ValorOperacao	varchar(max) null ,
		Desconto	varchar(max) null ,
		Acrescimo	varchar(max) null ,
		VrTotalLiquido	varchar(max) null ,
		IndicadorCancelamento	varchar(max) null ,
		ValorCancelamento	varchar(max) null 
	)
if not exists(select null from sysobjects where name = 'Loj_ECF_E21')	
	Create table 	Loj_ECF_E21	(
		TipoRegistro	varchar(max) null ,
		NrFabricacaoECF	varchar(max) null ,
		LetraIndicativa	varchar(max) null ,
		ModeloECF	varchar(max) null ,
		NrOrdemUsuario	varchar(max) null ,
		COO	varchar(max) null ,
		CCF	varchar(max) null ,
		GNF	varchar(max) null ,
		MeioPagamento	varchar(max) null ,
		ValorPago	varchar(max) null ,
		IndicadorDesconto	varchar(max) null ,
		ValorEstornado	varchar(max) null 
	)		
if not exists(select null from sysobjects where name = 'Loj_ECF_E99')	
	Create table 	Loj_ECF_E99	(
		Codigo_Empresas Emp null,
		CGC_Empresas CGC null,
		Razao_Social_Empresas Razao,
		CNPJEstabelecimento varchar(max)
	)			