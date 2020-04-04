


 SELECT identity(int,1,1) id,* 
 into #copia
 FROM Loj_Itens_Cupons
 WHERE EMPRESA='09' 
 and data> '20180501' 

 
 declare @total int, @contador int, @data Smalldatetime, @controle int
 set @total = (select count(*) from #copia)
 set @contador =1
 while(@contador <= @total) 
 begin 
 set @data =    (select top 1 data from #copia where id = @contador )
 set @controle= (select top 1 controle from #copia where id = @contador )
 exec SP_Loj_Rateio_Desc_Acres '09','0001',@data, @controle
 --select @controle
 set @contador = @contador+1
 end

 

