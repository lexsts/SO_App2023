DECLARE @P0 nvarchar(4000),
     @P1 varchar(255),
     @P2 varchar(255),
     @P3 nvarchar(4000),
     @P4 nvarchar(4000),
     @P5 nvarchar(4000),
     @P6 nvarchar(4000)

WITH PARANS AS
  (SELECT @P0 AS DATA_CALC ,
          @P1 AS COD_PAR ,
          @P2 AS COD_CATG_PAR)
INSERT INTO TTEMLANC_FINA (COD_CRAC_LANC_FINA, DATA_LIQC, SIGL_SIST_ORIG_LANC_FINA, DATA_REF_GERA_LANC_FINA, DTHR_LANC_FINA_SIST_ORIG, VAL_BASE_CALC_LANC_FINA, COD_SIST_NEG, VAL_LANC_FINA, COD_MOED, DESC_LANC_FINA, DTHR_PROS, COD_CAMR_COMN, COD_MC, COD_CATG_PAR, COD_PAR, COD_TIPO_CON, NUM_IDT_CON, COD_ISIN, COD_SITU_LANC_FINA, DTHR_ENV_SLF, COD_NEG, COD_SEGM, COD_MERC, IND_DAYT, DATA_CALC, DATA_NEG, IND_NEG_DEFV, COD_SUB_LOTE)

SELECT COD_CRAC_LANC_FINA ,
       DATA_LIQC ,
       SIGL_SIST_ORIG_LANC_FINA ,
       DATA_REF_GERA_LANC_FINA ,
       DTHR_LANC_FINA_SIST_ORIG ,
       CASE WHEN CONVERT(DATE, SUBSTRING(NUM_COTR_BTB, 1, 8)) >@P3 
	   THEN ROUND(SUM(VAL_BASE_CALC_LANC_FINA), 2) ELSE ROUND(SUM(VAL_BASE_CALC_LANC_FINA), 2, 1) END AS VAL_BASE_CALC_LANC_FINA ,
       COD_SIST_NEG ,
       CASE WHEN CONVERT(DATE, SUBSTRING(NUM_COTR_BTB, 1, 8)) >@P4 
	   THEN ROUND(SUM(VAL_LANC_FINA), 2) ELSE ROUND(SUM(VAL_LANC_FINA), 2, 1) END AS VAL_LANC_FINA ,
       COD_MOED ,
       DESC_LANC_FINA ,
       DTHR_PROS ,
       COD_CAMR_COMN ,
       COD_MC ,
       COD_CATG_PAR ,
       COD_PAR ,
       COD_TIPO_CON ,
       NUM_IDT_CON ,
       COD_ISIN ,
       COD_SITU_LANC_FINA ,
       DTHR_ENV_SLF ,
       COD_NEG ,
       COD_SEGM ,
       COD_MERC ,
       IND_DAYT ,
       DATA_CALC ,
       DATA_NEG ,
       IND_NEG_DEFV ,
       COD_SUB_LOTE
FROM
  (SELECT DISTINCT TT.COD_CRAC_LANC_DEFV 'COD_CRAC_LANC_FINA' ,
                                         DN1.DATA_NEG 'DATA_LIQC' ,
                                                      'TEM' 'SIGL_SIST_ORIG_LANC_FINA' ,
     (SELECT DATA_CALC
      FROM PARANS) 'DATA_REF_GERA_LANC_FINA' ,
                   SYSDATETIME() 'DTHR_LANC_FINA_SIST_ORIG' ,
                                 MN.VAL_VOL_ALOC 'VAL_BASE_CALC_LANC_FINA' ,
                                                 0 'COD_SIST_NEG' ,
                                                   TC.VAL_CALC_TAXA 'VAL_LANC_FINA' ,
                                                                    LF.COD_MOED_LANC_FINA 'COD_MOED' ,
                                                                                          MN.NUM_COTR_BTB 'DESC_LANC_FINA' ,
                                                                                                          NULL 'DTHR_PROS' ,
                                                                                                               9997 'COD_CAMR_COMN' ,
                                                                                                                    MN.COD_MEMB_COMN 'COD_MC' ,
                                                                                                                                     MN.COD_CATG_PAR 'COD_CATG_PAR' ,
                                                                                                                                                     MN.COD_PAR 'COD_PAR' ,
                                                                                                                                                                MN.COD_TIPO_CON 'COD_TIPO_CON' ,
                                                                                                                                                                                MN.NUM_IDT_CON 'NUM_IDT_CON' ,
                                                                                                                                                                                               AOBT.COD_ISIN 'COD_ISIN' ,
                                                                                                                                                                                                             CASE
                                                                                                                                                                                                                 WHEN INST.COD_MERC IN (@P5) THEN 8
                                                                                                                                                                                                                 ELSE 0
                                                                                                                                                                                                             END AS 'COD_SITU_LANC_FINA' ,
                                                                                                                                                                                                             NULL 'DTHR_ENV_SLF' ,
                                                                                                                                                                                                                  AOBT.COD_SMB_NEG 'COD_NEG' ,
                                                                                                                                                                                                                                   INST.COD_SEGM 'COD_SEGM' ,
                                                                                                                                                                                                                                                 INST.COD_MERC 'COD_MERC' ,
                                                                                                                                                                                                                                                               'N' 'IND_DAYT' ,
     (SELECT DATA_CALC
      FROM PARANS) 'DATA_CALC' ,
                   MN.DATA_NEG 'DATA_NEG' ,
                               MN.IND_NEG_DEFV 'IND_NEG_DEFV' ,
                                               'BTB' 'COD_SUB_LOTE' ,
                                                     MN.NUM_COTR_BTB ,
                                                     MN.NUM_SEQ_MVTO
   FROM TTEMTAXA TT WITH(NOLOCK)
   INNER JOIN TTEMMVTO_CALC_BTB TC WITH(NOLOCK) ON TT.COD_TAXA = TC.COD_TAXA
   INNER JOIN TTEMCRAC_LANC_FINA LF WITH(NOLOCK) ON TT.COD_CRAC_LANC_DEFV = LF.COD_CRAC_LANC
   INNER JOIN TTEMMVTO_NEG_BTB MN WITH(NOLOCK) ON TC.DATA_CALC = MN.DATA_CALC
   AND TC.NUM_SEQ_MVTO = MN.NUM_SEQ_MVTO
   INNER JOIN TTEMCTRL_DATA_NEG DN1 WITH(NOLOCK) ON MN.DATA_NEG = DN1.DATA_CALC
   AND DN1.COD_TIPO_PROS = 'BAT'
   AND LF.COD_TIPO_DATA = DN1.COD_TIPO_DATA
   INNER JOIN TTEMNEG_BTB NEG WITH(NOLOCK) ON NEG.DATA_CALC = MN.DATA_CALC
   AND NEG.NUM_COTR_BTB = MN.NUM_COTR_BTB
   AND NEG.COD_NAT_NEG = MN.COD_NAT_NEG
   AND NEG.COD_PAR = MN.COD_PAR
   AND NEG.COD_CATG_PAR = MN.COD_CATG_PAR
   AND NEG.NUM_IDT_CON = MN.NUM_IDT_CON
   INNER JOIN ATEMIMTO INST WITH(NOLOCK) ON NEG.COD_IMTO = INST.COD_IMTO
   AND NEG.COD_ORIG_IDT_IMTO = INST.COD_ORIG_IDT_IMTO
   AND NEG.COD_BV = INST.COD_BV
   INNER JOIN ATEMIMTO AOBT WITH(NOLOCK) ON NEG.COD_IMTO_AOBT = AOBT.COD_IMTO
   AND NEG.COD_ORIG_IDT_AOBT = AOBT.COD_ORIG_IDT_IMTO
   AND NEG.COD_BV_AOBT = AOBT.COD_BV
   INNER JOIN PARANS ON PARANS.DATA_CALC = MN.DATA_CALC
   AND (PARANS.COD_PAR IS NULL
        OR PARANS.COD_PAR = MN.COD_PAR)
   AND (PARANS.COD_CATG_PAR IS NULL
        OR PARANS.COD_CATG_PAR = MN.COD_CATG_PAR)) AS T
GROUP BY COD_CRAC_LANC_FINA ,
         DATA_LIQC ,
         SIGL_SIST_ORIG_LANC_FINA ,
         DATA_REF_GERA_LANC_FINA ,
         DTHR_LANC_FINA_SIST_ORIG ,
         COD_SIST_NEG ,
         COD_MOED ,
         DESC_LANC_FINA ,
         DTHR_PROS ,
         COD_CAMR_COMN ,
         COD_MC ,
         COD_CATG_PAR ,
         COD_PAR ,
         COD_TIPO_CON ,
         NUM_IDT_CON ,
         COD_ISIN ,
         COD_SITU_LANC_FINA ,
         DTHR_ENV_SLF ,
         COD_NEG ,
         COD_SEGM ,
         COD_MERC ,
         IND_DAYT ,
         DATA_CALC ,
         DATA_NEG ,
         IND_NEG_DEFV ,
         COD_SUB_LOTE ,
         NUM_COTR_BTB
HAVING CASE WHEN CONVERT(DATE, SUBSTRING(NUM_COTR_BTB, 1, 8)) > @P6 
THEN ROUND(SUM(VAL_LANC_FINA), 2) ELSE ROUND(SUM(VAL_LANC_FINA), 2, 1) END > 0 
OPTION (MAXDOP 1)

--select NUM_COTR_BTB from TTEMMVTO_NEG_BTB
sp_spaceused TTEMMVTO_NEG_BTB
sp_spaceused TTEMNEG_BTB