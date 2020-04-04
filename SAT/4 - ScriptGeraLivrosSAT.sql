

Declare @Cliente Varchar(14), @Empresa Varchar(02), @CNPJEmpresa Varchar(20), @Estado Varchar(02),
 @DataIni smalldatetime, @DataFin smalldatetime

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


set @DataIni = '20180201'
set @DataFin = '20180228'


--select object_ID('TempDB..#Frm_RelMResumoPDV')
--select object_ID('TempDB..#TmpCFOP')
if object_ID('TempDB..#Frm_RelMResumoPDV') is not null
	drop table #Frm_RelMResumoPDV

if object_ID('TempDB..#TmpCFOP') is not null
	drop table #TmpCFOP

Create Table #TmpCFOP(Divisao Char(02), CFOP Char(04))

insert into #TmpCFOP(Divisao, CFOP)
Values ('02','5102') 

exec SP_Liv_ImpCupons_LivSaida @Empresa,@DataIni,@DataFin,@Cliente
exec SP_Liv_ImpCupons_LivSaida_Nat @Empresa,@DataIni,@DataFin,NULL,'#TmpCFOP',''
exec SP_Liv_ImpCupons_LivSaida_Prod @Empresa,@DataIni,@DataFin,1,0,0,0,'#TmpCFOP','','T01','T02','T03','T04'

Delete Liv_Cupons_Finalizadores from Liv_Cupons_Finalizadores Lf
 INNER JOIN Liv_Cupons Lc on Lf.Empresa=Lc.Empresa and Lf.Documento=Lc.Documento and Lf.Serie=Lc.Serie and Lf.COO=Lc.COO
 INNER JOIN Liv_ReducaoZ Lr on Lc.Empresa=Lr.Empresa and Lc.Documento=Lr.COO_Reducao and Lc.Maquina=Lr.Maquina
Where Lr.Empresa = @Empresa and Lr.Data between @DataIni and @DataFin

Delete Liv_Itens_Cupons from Liv_Itens_Cupons Li
 INNER JOIN Liv_Cupons Lc on Li.Empresa=Lc.Empresa and Li.Documento=Lc.Documento and Li.Serie=Lc.Serie and Li.COO=Lc.COO
 INNER JOIN Liv_ReducaoZ Lr on Lc.Empresa=Lr.Empresa and Lc.Documento=Lr.COO_Reducao and Lc.Maquina=Lr.Maquina
Where Lr.Empresa = @Empresa and Lr.Data between @DataIni and @DataFin

Delete Liv_Cupons from Liv_Cupons Lc
 INNER JOIN Liv_ReducaoZ Lr on Lc.Empresa=Lr.Empresa and Lc.Documento=Lr.COO_Reducao and Lc.Maquina=Lr.Maquina
Where Lr.Empresa = @Empresa and Lr.Data between @DataIni and @DataFin

Delete from Liv_ReducaoZ  Where Empresa = @Empresa and Data between @DataIni and @DataFin

exec SP_Liv_Importa_Cupons @Empresa,@DataIni,@DataFin,@Cliente,1,0,0,0,'','','','T01','T02','T03','T04',3

Select  Divisao, '     ' NatOp Into #Frm_RelMResumoPDV From  #TmpCFOP

exec SP_Liv_ImpCupons_Sfs_Sintegra @Empresa,@DataIni,@DataFin,0,'#Frm_RelMResumoPDV','T01','T02','T03','T04'
exec SP_Liv_ImpCupons_Sfs_Sintegra_Tot @Empresa,@DataIni,@DataFin

/*

select Empresa_Atual from Cont_Parametros
update Cont_Parametros set Empresa_Atual = 'Zerada'

	update Fat_PAramEmp set empresa_contabil = 'Zerada'
	*/
