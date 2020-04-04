IF EXISTS(Select 'X' from SysObjects where name='SP_Liv_Aj_ICM_Cupons')
  DROP Procedure dbo.SP_Liv_Aj_ICM_Cupons
GO
Create procedure dbo.SP_Liv_Aj_ICM_Cupons
(
  @Empresa char(02),
  @DataI SmallDateTime,
  @DataF SmallDateTime
)
As
/****************************************************************************************************************************
  Criada em: 14/06/2011
  Craido por: Rodrigo
  Alterada em: 27/09/2011
  Alterado por: Danuza - alterado tamanho campo documento
  Alterada em: 25/06/201
  Alterada por: Marcia - Acertar a diferença somente nos cupons que não estão cancelados, 
                        Acertar o update no Liv_SaiProd, onde o documento é a CRZ, e não o Coo da Reducao
 Alterada em : 25/06/206
 Alteradda Por: Marcelo Botardo, Adicionada nova condição para realizar os ajustes de 0,01 centavos apenas
 para documentos de Cupons Fiscais.
   "and C.COD_MOD <> (Select top 1 Cod_Liv_SPED_Modelo_Dcto from Liv_SPED_Modelo_Dcto where Codigo_Modelo = ''59'')"

  Criado em DBMicrodata
    Objetivo: Acertar o valor de icms dos itens para bater com o valor da Reduçao Z impressa:
              Quando a somatorioa do valor de icms dos itens nao for igual ao valor da base pela aliquota,achar diferença ,
              achar a quantidade de item para ser acertado e acrescentar ou diminuir 0.01 no valor do icms de cada item de 
              cupons e livros de saida, depois de acertar todos os itens, executar update na tabela Liv_SaiNatop  com a 
              somatoria do icms dos itens.
    Parametros: @Empresa = Empresa do movimento dos cupons
                @DataI = Data inicial do movimento dos cupons
                @DataF = Data Final do movimento dos cupons
****************************************************************************************************************************/
Begin
  Create Table #TMP_Acerta2(Empresa char(02),Documento Varchar(20), Serie char(05), coo char(06),Num_Item int,Produto char(06),
                            vr_total_item decimal(16,4),aliq_icms decimal(16,4),vr_bc_icms decimal(16,4),vr_icms decimal(16,4))

  Create Table #TMP_LivSaiProd (Empresa char(02),Documento Varchar(20),Serie Char(05), NatOp Char(05),Seq char(01),Produto char(06),
                                Incremento int, Atualizado char(01))

  select C.EMpresa,C.Documento,C.Serie,sum(i.vr_bc_icms) Vr_Bc_Icms,i.aliq_icms,sum(i.vr_icms) Vr_Icms,round((sum(i.vr_bc_icms)*i.aliq_icms)/100,2,1) Vr_Icms2
  ,round((sum(i.vr_bc_icms)*i.aliq_icms)/100,2,1) - sum(i.vr_icms) Diferenca,i.Cfop, r.CRZ
   into #TMP_Acerta1
  from liv_reducaoz r
   inner join liv_cupons c on r.empresa=c.empresa and r.maquina=c.maquina and c.documento=r.cOO_reducao
   inner join liv_itens_cupons i on c.empresa=i.empresa and c.documento=i.documento and c.serie=i.serie and c.coo=i.coo
  where c.empresa=@Empresa and r.data between @DataI and @DataF and C.Cod_Sit not in (3,4,5,6) 
	and C.COD_MOD <> (Select top 1 Cod_Liv_SPED_Modelo_Dcto from Liv_SPED_Modelo_Dcto where Codigo_Modelo = '59') -- condição colocada para ignorar esses ajustes caso o documento for Cfe-Sat (Tchelo)
  --and c.documento='000921'
    and isnull(i.Cancelado,0)=0 and isnull(c.Cancelado,'N')='N'
  Group By C.Empresa,C.Documento,i.aliq_icms,C.Serie,i.cfop, r.CRZ
  having sum(i.vr_icms)<>round((sum(i.vr_bc_icms)*i.aliq_icms)/100,2,1)

  --select * from #TMP_Acerta1

  declare @Emp char(02),@Doc char(06),@Serie char(05),@Dif nvarchar(04), @Operador decimal(16,4),
          @EmpI char(02),@DocI char(06),@SerieI char(05), @CooI Char(06),@Num_Item int, @Prod char(06),
          @Inc int, @Cfop char(05), @CRZ char(06)

  while (Select Count(*) from #TMP_Acerta1)>0 begin
   select top 1 @Emp=Empresa,@Doc=Documento,@Serie=Serie,@Operador=Diferenca,@Cfop=Cfop,
    @Dif=cast(case when (Diferenca*100)<0 then (Diferenca*100)*-1 else (Diferenca*100) end as int),
	@CRZ=ISNULL(CRZ,'')
   from #TMP_Acerta1 order by Documento

   Exec('Insert INto #TMP_Acerta2 (Empresa,Documento,Serie,Coo,Num_Item,Produto,vr_total_item,aliq_icms,vr_bc_icms,vr_icms)
         Select top '+@Dif+' I.Empresa,I.Documento,I.Serie,I.Coo,I.Num_Item,I.Codigo_Produto,I.Vr_Total_Item,I.Aliq_Icms,
         I.Vr_BC_Icms,I.Vr_Icms 
         from Liv_Cupons C
           Inner Join Liv_Itens_Cupons I on C.Empresa=I.Empresa and C.Documento=I.Documento and C.Serie=I.Serie and C.COO=I.COO
         Where I.Empresa='''+@Emp+''' and I.Documento='''+@Doc+''' and I.Serie='''+@Serie+''' and C.Cod_Sit not in (3,4,5,6)
         and I.Vr_Icms<>0 and I.Vr_BC_Icms<>0 and I.Aliq_Icms<>0 and I.Cfop='''+@Cfop+'''
         and isnull(i.Cancelado,0)=0 and isnull(c.Cancelado,'''+'N'+''')='''+'N'+'''
		 and C.COD_MOD <> (Select top 1 Cod_Liv_SPED_Modelo_Dcto from Liv_SPED_Modelo_Dcto where Codigo_Modelo = ''59'')
        ')

   while (Select count(*) from #TMP_Acerta2)>0 begin
  
    Select Top 1 @EmpI=Empresa,@DocI=Documento,@SerieI=Serie,@CooI=Coo,@Num_Item=Num_Item,@Prod=Produto from #TMP_Acerta2

    --select case when @Operador<0 then Vr_Icms-0.01 else Vr_Icms+0.01 end,vr_icms,coo,num_item from liv_itens_cupons
    update Liv_Itens_Cupons Set Vr_ICMS = case when @Operador<0 then Vr_Icms-0.01 else Vr_Icms+0.01 end
    where Empresa=@EmpI and Documento=@DocI and Serie=@SerieI and Coo=@CooI and Num_Item=@Num_Item and Cfop=@Cfop

    Insert Into #TMP_LivSaiProd (Empresa,Documento,Serie,Natop,Seq,Produto,Incremento,Atualizado)
    Select Top 1 Empresa,Documento,Serie,Natop,Seq,Produto,Incremento,'N' from Liv_saiprod L1
    where Empresa=@Emp and Documento = @CRZ --Documento=@Doc 
						and Serie=@Serie and Produto=@Prod and 
    not exists(Select 'X' from #TMP_LivSaiProd L2 where L1.Empresa=L2.Empresa and L1.Documento=L2.Documento and L1.Serie=L2.Serie
               and L1.Natop=L2.Natop and L1.Seq=L2.Seq and L1.Produto=L2.Produto and L1.Incremento=L2.Incremento)

    --Select L1.Produto,L1.Incremento,case when @Operador<0 then Vr_Icms-0.01 else Vr_Icms+0.01 end
	
	update Liv_SaiProd set Vr_Icms = case when @Operador<0 then Vr_Icms-0.01 else Vr_Icms+0.01 end
    from Liv_SaiProd L1
    where Empresa=@Emp and Documento =@CRZ-- Documento=@Doc o documento da liv_sai_prod não é o mesmo que o documento da liv_cupons
						and Serie=@Serie and Produto=@Prod and 
    exists(Select 'X' from #TMP_LivSaiProd L2 where L1.Empresa=L2.Empresa and L1.Documento=L2.Documento and L1.Serie=L2.Serie
           and L1.Natop=L2.Natop and L1.Seq=L2.Seq and L1.Produto=L2.Produto and L1.Incremento=L2.Incremento and IsNull(L2.Atualizado,'N')='N')

    update #TMP_LivSaiProd set Atualizado='S'
    from #TMP_LivSaiProd L1
    where Empresa=@Emp and Documento = @CRZ --Documento=@Doc 
	and Serie=@Serie and Produto=@Prod and 
    exists(Select 'X' from #TMP_LivSaiProd L2 where L1.Empresa=L2.Empresa and L1.Documento=L2.Documento and L1.Serie=L2.Serie
              and L1.Natop=L2.Natop and L1.Seq=L2.Seq and L1.Produto=L2.Produto and L1.Incremento=L2.Incremento)

    Delete from #TMP_Acerta2 where Empresa=@EmpI and Documento=@DocI and Serie=@SerieI 
                      and Coo=@CooI and Num_Item=@Num_Item
 
   end

  delete from #TMP_Acerta1 where Empresa=@Emp and Documento=@Doc and Serie=@Serie and Cfop=@Cfop
 end

Drop Table #TMP_Acerta2
Drop Table #TMP_Acerta1
Drop Table #TMP_LivSaiProd

/*Acerta icms da natureza com o dos produto*/

Update Liv_SaiNatOp Set ICM_BC=P.Vr_BCICMS,
                        ICM_Valor=P.Vr_ICMS,
                        ICM_Isento= P.Vr_ICMS_Isento,
                        ICM_Outras=P.Vr_ICMS_Outras,
                        ICM_Subst=P.Vr_ICMS_Subst,
                        IPI_BC=P.Vr_BCIPI,
                        IPI_Valor=P.Vr_IPI,
                        IPI_Isento=P.Vr_IPI_Isento,
                        IPI_Outras=P.Vr_IPI_Outras,   
                        Vr_Contabil=P.Valor_Total,
                        ICM_Subst_BC=P.Vr_BCICMS_Subst
FROM Liv_Saidas S
  INNER JOIN Liv_SaiNatOP N on N.Empresa=S.Empresa and N.Documento=S.Documento and N.Serie=S.Serie
  INNER JOIN (Select S1.Empresa,P2.Documento,P2.Serie,P2.NatOp,P2.Seq,SUM(IsNull(P2.Vr_BCICMS,0)) Vr_BCICMS,SUM(IsNull(Vr_ICMS,0)) Vr_ICMS,SUM(IsNull(Vr_ICMS_Isento,0)) Vr_ICMS_Isento,
              SUM(IsNull(Vr_ICMS_Outras,0)) Vr_ICMS_Outras, SUM(IsNull(Vr_ICMS_Subst,0)) Vr_ICMS_Subst,
              SUM(IsNull(Vr_BCIPI,0)) Vr_BCIPI,SUM(IsNull(Vr_IPI,0)) Vr_IPI,SUM(IsNull(Vr_IPI_Isento,0)) Vr_IPI_Isento,SUM(IsNull(Vr_IPI_Outras,0)) Vr_IPI_Outras,
              SUM(IsNull(Valor_Total,0)) Valor_Total,SUM(IsNull(Vr_BCICMS_Subst,0)) Vr_BCICMS_Subst
              FROM  Liv_Saidas S1
               INNER JOIN Liv_SaiProd P2 ON P2.Empresa=S1.Empresa and P2.Documento=S1.Documento and P2.Serie=S1.Serie
              Where S1.Empresa=@Empresa and S1.Data_Emissao Between @DataI and @DataF and LEFT(S1.serie,3)='ECF'
					and S1.COD_MOD <> (Select top 1 Cod_Liv_SPED_Modelo_Dcto from Liv_SPED_Modelo_Dcto where Codigo_Modelo = '59') 
              Group By S1.Empresa,P2.Documento,P2.Serie,P2.NatOp,P2.Seq) P
          on P.Empresa=N.Empresa and P.Documento=N.Documento and P.Serie=N.Serie and P.NatOp=N.NatOp and P.Seq=N.Seq
WHERE S.Empresa=@Empresa and S.Data_Emissao Between @DataI and @DataF and LEFT(S.serie,3)='ECF'
and S.COD_MOD <> (Select top 1 Cod_Liv_SPED_Modelo_Dcto from Liv_SPED_Modelo_Dcto where Codigo_Modelo = '59') -- condição colocada para ignorar esses ajustes caso o documento for Cfe-Sat (Tchelo)
End
GO