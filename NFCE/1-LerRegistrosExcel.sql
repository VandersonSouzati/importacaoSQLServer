/*USE [master]
GO

EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1
GO

EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1
GO

--CONFIGURANDO À INSTÂNCIA SQL PARA ACEITAR OPÇÕES AVANÇADAS
EXEC sp_configure 'show advanced options', 1
RECONFIGURE
GO

--HABILITANDO O USO DE CONSULTAS DISTRIBUÍDAS
EXEC sp_configure 'Ad Hoc Distributed Queries', 1
RECONFIGURE
GO
*/


IF OBJECT_ID('DadosExcel') Is Not Null 
Drop Table DadosExcel
IF OBJECT_ID('DadosTabela') Is Not Null 
Drop Table DadosTabela
IF OBJECT_ID('NFCE') Is Not Null 
Drop Table NFCE


SELECT * 
  Into DadosExcel 
FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
'Excel 12.0; Database=D:\NFCE12.xlsx; HDR=YES; IMEX=1',
'SELECT * FROM [NFCE$]') 
GO

Delete From DadosExcel
Where Isnull(Id,'') =''

--Declare @SQL Varchar(Max)

Create Table DadosTabela(
    Id   int identity,
	Linha Varchar(Max)
)

Insert into DadosTabela
Select '['+Column_Name+'] As '+Replace(Replace(Column_name,'ns1:',''),'ns2:','')+','
From Information_Schema.Columns 
Where Table_Name ='DadosExcel'
	
	update DadosTabela set linha = 'Select '+Linha 
	From DadosTabela Where id ='1'

	update DadosTabela set linha = replace(Linha,',','')+ ' Into NFCE FROM DadosExcel' 
	From DadosTabela 
	Where id =(Select Max(Id) From DadosTabela)

		

Declare @Contador int, @Total Int, @SQL Varchar(Max)
Set @SQL =''

select @SQL = @SQL+ ' '+Linha  From DadosTabela  


print @SQL
Exec(@SQL)

