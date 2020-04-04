
DECLARE @Empresa varchar(2), @Maquina varchar(4)
Set @Empresa = (Select top 1 Codigo_Empresas From Loj_Ecf_E99)
Set @Maquina = '0001'

/********************  INICIO CARGA IMPRESSORAS *********************************************/
insert into loj_Impressoras(
	/*01*/	Empresa, 
	/*02*/	Codigo, 
	/*03*/	Numero_Serie, 
	/*04*/	Marca,
	/*05*/	Modelo, 
	/*06*/	Cod_FF,
	/*07*/	Cod_M,
	/*08*/	Diretorio_Arq_Cat52,
	/*09*/	Versao_SB,
	/*10*/	Data_Gravacao_SB,
	/*11*/	Hora_Gravacao_SB,
	/*12*/	Numero_Usuario,
	/*13*/	Data_Cadastro_Usuario,
	/*14*/	Hora_Cadastro_Usuario
	)

select distinct
	/*01*/	E99.Codigo_Empresas, 
	/*02*/	@Maquina Codigo, 
	/*03*/	E01.NrFabricacaoECF, 
	/*04*/	E01.MarcaECF, 
	/*05*/	E01.ModeloECF,
	/*06*/	SUBSTRING(E01.NrFabricacaoECF,1,2)Cod_FF,
	/*07*/	SUBSTRING(E01.NrFabricacaoECF,1,1)Cod_M,
	/*08*/	'C:\'+E01.MarcaECF Diretorio_Arq_Cat52,
	/*09*/  E01.VersaoAtualSoftwareBasico,
	/*10*/ E01.DataGravacaoMF,
	/*11*/ E01.HoraGravacao,
	/*12*/ E02.NroOrdemUsuarioECF,
	/*13*/ E02.DataCadastroUsuarioECF,
	/*14*/ E02.HoraCadastroUsuarioECF
from Loj_ECF_E01 E01
	inner join Loj_ECF_E02 E02 on(E01.NrFabricacaoECF = E02.NrFabricacaoECF)
	inner join Loj_ECF_E99 E99 on( E01.CNPJEstabelecimento = E99.CNPJEstabelecimento)
where not exists(select null from loj_impressoras I where I.Empresa = E99.Codigo_Empresas and i.Numero_Serie = E01.NrFabricacaoECF)


/********************  FIM CARGA IMPRESSORAS *********************************************/
/********************  INICIO CARGA Loj_Operacoes *********************************************/
select 
	Empresa
	,Maquina
	,Data
	,Controle
	,Tipo
	,0.00 Valor_Cheque
	,0.00 Valor_Dinheiro
	,0.00 Valor_Finalizador1
	,0.00 Valor_Finalizador2
	,0.00 Valor_Finalizador3
	,0.00 Valor_Finalizador4
	,Hora
	,Reducao
	,Operacao
	,0 Status
	,0 Troco_Inicial
	,Numero_Serie
	,COO_Inicial
	,Qtde_Reinicio
	,Venda_Bruta
	,Grande_Total
	,'S' Destaca_Fechamento
from loj_Operacoes
where tipo = 3

insert into Loj_Operacoes(	
	 Empresa
	,Maquina
	,Data
	,Controle
	,Tipo
	,Valor_Cheque
	,Valor_Dinheiro
	,Valor_Finalizador1
	,Valor_Finalizador2
	,Valor_Finalizador3
	,Valor_Finalizador4
	,Hora
	,Reducao
	,Operacao
	,Status
	,Troco_Inicial
	,Numero_Serie
	,COO_Inicial
	,Qtde_Reinicio
	,Venda_Bruta
	,Grande_Total
	,Destaca_Fechamento)
	
Select distinct
	@Empresa Empresa
	,@Maquina Maquina
	,cast(E16.DataFinalEmissao as DateTime)
	,1 Controle
	,3 Tipo
	,0.00 Valor_Cheque
	,0.00 Valor_Dinheiro
	,0.00 Valor_Finalizador1
	,0.00 Valor_Finalizador2
	,0.00 Valor_Finalizador3
	,0.00 Valor_Finalizador4
	,cast(E16.DataFinalEmissao as DateTime)
	,E16.CRZ Reducao
	,E16.COO Operacao
	,0 Status
	,0 Troco_Inicial
	,E16.NrFabricacaoECF Numero_Serie
	,'000001' COO_Inicial --Pegar o acumulado do E11
	,1 Qtde_Reinicio
	,Cast( E12.VendaBrutaDiaria As DEcimal(16,4)) /100 As Venda_Bruta
	,Cast( E12.VendaBrutaDiaria As Decimal(16,4)) /100 As Grande_Total 
	,'S' Destaca_Fechamento 

from Loj_ECF_E16 E16
inner join Loj_ECF_E12 E12 on(E16.NrFabricacaoECF = E12.NrFabricacaoECF and E16.ModeloECF = E12.ModeloECF and E16.DataFinalEmissao = E12.DataEmissaoZ  )
--fazer o join com o E11 para pegar o granTotal
where E16.denominacaoTipoDocumento = 'RZ'
	 and not exists( select null from loj_operacoes 
						where empresa = @Empresa and maquina = @Maquina 
						and data = cast(E16.DataFinalEmissao as DateTime) 
						and controle = 1
						
					)

/********************  FIM CARGA Loj_Operacoes *********************************************/

