
/*
 Colocar qual natureza a inserir caso não exista na tabela
 e qual aliquota.
*/
declare @AliqNova decimal (15,2), @NatOP varchar(5)
	set @aliqNova = 25.00
	set @NatOp = '5.102'
	

if not exists( select * from Liv_Natureza
				where codigo =@NatOp and 
				aliq_icms = @AliqNova
				 )
begin

  if OBJECT_ID('TempDB..#t') is not null
    drop table #T

	select top 1 * 
	  into #t
	from Liv_Natureza
	where codigo =@NatOP
	order by sequencia desc
	
	
	update #t set Aliq_ICMS = @AliqNova, Sequencia = Sequencia + 1

	insert into Liv_Natureza
	Select * from #t
				
end
Go 