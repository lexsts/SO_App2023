USE [CS]
GO

/****** Object:  StoredProcedure [dbo].[SPCS_CO_CONV_DISSID_SOLIC_CANCEL]    Script Date: 20/07/2017 10:18:15 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



/************************************************************************************************
* Objetivo  :  Consulta de Solicita��o e Cancelamento de Convers�o e Dissid�ncia de Eventos Volunt�rios *
* Par�metros:	@P_COD_AGCT          -   C�digo do Agente de Cust�dia                           *
                @P_COD_INVS          -   C�digo do Investidor                                   *
                @P_NUM_PROC          -   N�mero de Processo                                     *  
                @P_COD_ISIN          -   C�digo do ISIN                                         *
                @P_NUM_DIST          -   N�mero de Distribui��o                                 *  
                @P_TIPO_OPERACAO     -   C�digo do Tipo de Solicita��o                          *
     S - Solicita��o,  pega dados das Carteiras Livres
     C - Cancelamento, pega dados da Carteira de Bloqueio de Convers�o
     T - Pega Quando � chamado por uma Consulta, excluindo o filtro de Data de Vig�ncia
     A - Pega tudo que est� no Saldo do Investidor
     Menos as carteiras de Bloqueios, por elas representarem a parte "Solicitada"
     Isso quer dizer que pega al�m da carteira livre, as carteiras de Garantias entre outras

                @P_COD_TIP_EVEN      -   C�digo do Tipo de Evento                               *
                @P_COD_ESTD_CALC_DIR -   C�digo de Estado de Direito                            *    
                @P_COD_RET           -  Retorno(Erro)                                           *
                @P_MSG_RET           - 	Retorno(Mensagem)                                       *
*                                                                                               *
* Autor     : Leandro Trujillo (G&P)                                                            *
* Cria��o   : 16/01/2007                                                                        *
* Vers�o    : {1.0}                                                                             *
*                                                                                               *
* Altera��o : 20/03/2007                                                                        *
* Repons�vel: Kleber Boldrin de Almeida                                                         *
* Motivo    : Adicionar o @P_TIPO_OPERACAO = 'T', para trazer todos os Eventos                  *
*                                                                                               *
* Altera��o : 09/04/2007                                                                        *
* Repons�vel: Kleber Boldrin de Almeida                                                         *
* Motivo    : Ajustando para novo modelo de Funcionamento                                       *
*                                                                                               *
* Altera��o : 11/10/2007                                                                        *
* Repons�vel: Kleber Boldrin de Almeida                                                         *
* Motivo    : Incluir filtro por Tipo de Evento                                                 *
*                                                                                               *
* Altera��o : 20/10/2007                                                                        *
* Repons�vel: Rodrigo Felipe Fernandes                                                          *
* Motivo    : implementa��es para obter a carteira de bloquei correta                           *
*                                                                                               *
* Altera��o : 10/11/2007                                                                        *
* Repons�vel: Kleber Boldrin de Almeida                                                         *
* Motivo    : Inclus�o de mais um Tipo de Opera��o (A), para pegar tudo que for Saldo, menos    *
*             as contas de bloqueios de Convers�o e Dissid�ncia                                 *
*                                                                                               *
* Altera��o : 07/12/2007                                                                        *
* Repons�vel: Kleber Boldrin de Almeida                                                         *
* Motivo    : Novo modelo de Convers�o e Dissid�ncia, com a mudan�a da tabela TCSSALD_SOLI      *
*                                                                                               *
* Altera��o : 28/03/2008                                                                        *
* Repons�vel: Rodrigo Felipe Fernandes                                                          *
* Motivo    : Implementa��o da chamada da carteira livre 51012,                                 *
*                                                                                               *
* Altera��o : 19/08/2008                                                                        *
* Repons�vel: Kleber Almeida                                                                    *
* Motivo    : Ajuste no @P_TIPO_OPERACAO = 'T'                                                  *
*                                                                                               *
* Altera��o...: 04/02/2011                                                                      *
* Motivo......: Ajustes no tratamento N pra N                                                   *
* Repons�vel..: Vinicius Lodi Vasconcellos                                                      *
*                                                                                               *
* Altera��o...: 13/04/2012                                                                      *
* Motivo......: Ajustes casas decimais do campo VAL_DINH_RES(DE 2 para 11)                      *
* Repons�vel..: Jean Carlos Lima                                                                *
*                                                                                               *
* ATEN��O: Esta procedure est� sendo usada no Solicita��o e Cancelamento de Convers�o / Dissid�ncia
*          e tamb�m no tratamento dos Arquivos IEVL e CEVL (Eventos Volunt�rios)
*          Qualquer altera��o, por favor replicar nas procedures:
*                 ->  SPCS_PR_CONV_DISSID_SOLIC_CANCEL
*                 ->  SPCS_PR_CEVL
*                 ->  SPCS_PR_IEVL_GRAVA_REGISTRO_07
*                 ->  SPCS_PR_IEVL_GRAVA_REGISTRO_08
*                 ->  SPCS_CO_EVEN_GER_ATIV_RES_VOLUNT
*                 ->  SPCS_CO_EVEN_GER_ATIV_RES_VOLUNT
*                 ->  SPCS_CO_EVEN_GER_ATIV_VOL_AGCT
*                 ->  SPCS_CO_EVEN_GER_ATIV_VOL_AGCTIN
*                 ->  SPCS_CO_INVS_PROC
*                 ->  SPCS_CO_INVS_PROC_DET_INVS
*                 ->  SPCS_CO_PROCESSOS_EVENTOS
*          Kleber Almeida ::::   07/12/2007
*
* Altera��o...: 07/03/2013                                                                      *
* Motivo......: Implementada Retrata��o                                                         *
* Repons�vel..: Juliano Valeta                                                                  *
*                                                                                               *
**************************************************************************************************/
CREATE PROCEDURE [SPCS_CO_CONV_DISSID_SOLIC_CANCEL_TEMP] (@P_COD_AGCT           decimal(6,0)
                                                 , @P_COD_INVS           decimal(7,0)
                                                 , @P_NUM_PROC           decimal(9,0)
                                                 , @P_COD_ISIN           char(12)
                                                 , @P_NUM_DIST           smallint
                                                 , @P_TIPO_OPERACAO      char(1)
                                                 , @P_COD_TIP_EVEN       integer 
                                                 , @P_COD_ESTD_CALC_DIR  decimal(1)   = NULL
                                                 , @P_COD_RET            integer      = NULL  OUTPUT
                                                 , @P_MSG_RET            varchar(200) = NULL  OUTPUT)
AS
BEGIN
    --INICIA O AMBIENTE
    SET NOCOUNT ON

    DECLARE @COD_CART_LIVRE INTEGER             -- Carteira Livre
    DECLARE @COD_CART_LIVRE_BALCAO  INTEGER     -- Carteira Livre Balcao
    DECLARE @COD_CART_BLOQ_CONV  INTEGER        -- Carteira Bloqueio Convers�o
    DECLARE @COD_CART_BLOQ_DISS  INTEGER        -- Carteira Bloqueio Dissid�ncia
    DECLARE @COD_CART_BLOQ_RETR  INTEGER        -- Carteira Bloqueio Retratacao

    DECLARE @COD_TIPO_EVEN_CONVERSAO      smallint    -- Tipo de Evento Convers�o
    DECLARE @COD_TIPO_EVEN_DISSIDENCIA    smallint    -- Tipo de Evento Dissid�ncia

    DECLARE @DATA_ATUAL                   datetime    -- DATA ATUAL
    DECLARE @PERMITE_DISSIDENCIA_PARCIAL  tinyint     --Permite Dissidencia Parcial
    DECLARE @TOTAL_REG   INTEGER        -- TOTAL REGISTRO

    -- Tabela com ISINs v�lidos para Convers�o
    CREATE TABLE #CS_PROCESSOS_CONVERSAO (COD_ISIN         char(12)
                                         , NUM_DIST         smallint
                                         , COD_CART_BLOQ    integer
                                         , NUM_PROC         decimal(9)
                                         , COD_TIPO_EVEN    smallint
                                         , DESC_TIPO_EVEN   varchar(60)
                                         , VAL_DINH_RES     decimal(18,11)
                                         , DATA_PRAZO       datetime
                                         , FAT_COT_PAC      decimal(18,11)
                                         , QTE_PARC_SUBS    decimal(3,0)
                                         , IND_DIR_DTBA     char(1)
                                         , PRIMARY KEY (NUM_PROC
                                                      , COD_ISIN
                                                      , NUM_DIST)) -- Tabela com Saldo Totalizado

    -- Tabela com Saldo Totalizado
    CREATE TABLE #CS_SALDO_INVS_PAPEL (COD_AGCT     decimal(6,0)
                                      , COD_INVS     decimal(7,0)
                                      , COD_CART     integer
                                      , COD_ISIN     char(12)
                                      , NUM_DIST     smallint
                                      , QTE_SALD     decimal(18,3)
                                      , PRIMARY KEY (COD_AGCT
                                                   , COD_INVS
                                                   , COD_CART
                                                   , COD_ISIN
                                                   , NUM_DIST)) -- Tabela com Saldo Totalizado

    -- Tabela com Saldo Totalizado
    CREATE TABLE #CS_PEGAR_SALDO_HCA (NUM_PROC          decimal(9)
                                     , COD_AGCT          decimal(6,0)
                                     , COD_INVS          decimal(7,0)
                                     , COD_ISIN          char(12)
                                     , NUM_DIST          smallint
                                     , QTE_DIR_DISP      decimal(18,3)
                                     , QTE_DIR_ORIG      decimal(18,3)
                                     , QTE_DIR_SOLT      decimal(18,3)
                                     , QTE_DIR_EXER      decimal(18,3)
                                     , PRIMARY KEY (NUM_PROC
                                                  , COD_AGCT
                                                  , COD_INVS)) -- Tabela com Saldo Totalizado

    -- Tabela com Saldo Apurado
    CREATE TABLE #CS_SALDO_APURADO (COD_AGCT          decimal(6,0)
                                   , COD_INVS          decimal(7,0)
                                   , COD_ISIN          char(12)
                                   , NUM_DIST          smallint
                                   , NUM_PROC          decimal(9)
                                   , COD_TIPO_EVEN     smallint
                                   , DESC_TIPO_EVEN    varchar(60)
                                   , VAL_DINH_RES      decimal(18,11)
                                   , DATA_PRAZO        datetime
                                   , FAT_COT_PAC       decimal(18,11)
                                   , QTE_PARC_SUBS     decimal(3,0)
                                   , QTE_SALD_DISP     decimal(18,3)
                                   , QTE_SOLT_ACUM     decimal(18,3)
                                   , QTE_SOLT_PERI     decimal(18,3)
                                   , QTE_DIR_SOLT      decimal(18,3)
                                   , QTE_DIR_EXER      decimal(18,3)
                                   , QTE_DIR_DISP      decimal(18,3)
                                   , QTE_DIR_ORIG      decimal(18,3)
                                   , QTE_SALD          decimal(18,3)
                                   , OPERACAO          varchar(20)
                                   , TEM_HCA           bit  /* Veririca se tem dados na HCS (0 - Canc, 1 - Solic) */
                                   , PRIMARY KEY (COD_AGCT
                                                , COD_INVS
                                                , COD_ISIN
                                                , NUM_DIST
                                                , NUM_PROC)) -- Tabela com Saldo Apurado

    -- Default � permitir dissidencia parcial
    SET @PERMITE_DISSIDENCIA_PARCIAL = 1

    -- Busca Cateira Livre do Investidor
    SELECT  @COD_CART_LIVRE = COD_CART
    FROM    dbo.TCSCTRL_CON_INT_CUST  with(nolock)
    WHERE   COD_PAD_CON_INT_CUST = 'CART_LIVRE'

    SELECT  @COD_CART_LIVRE_BALCAO = COD_CART
    FROM    dbo.TCSCTRL_CON_INT_CUST  with(nolock)
    WHERE   COD_PAD_CON_INT_CUST = 'CART_LIVRE_BALCAO'

    -- Obtem a carteira de bloqueio
    SELECT  @COD_CART_BLOQ_CONV  = COD_CART
    FROM    DBO.TCSCTRL_CON_INT_CUST  with(nolock)
    WHERE   COD_PAD_CON_INT_CUST = 'CART_BLOQ_CONVERSAO'

    SELECT  @COD_CART_BLOQ_DISS  = COD_CART
    FROM    DBO.TCSCTRL_CON_INT_CUST  with(nolock)
    WHERE   COD_PAD_CON_INT_CUST = 'CART_BLOQ_DISSIDENCIA'

    SELECT  @COD_CART_BLOQ_RETR  = COD_CART
    FROM    DBO.TCSCTRL_CON_INT_CUST  with(nolock)
    WHERE   COD_PAD_CON_INT_CUST = 'CART_BLOQ_RETRATACAO'

    -- Ajusta Tipos de Eventos
    SET @COD_TIPO_EVEN_CONVERSAO   = 95
    SET @COD_TIPO_EVEN_DISSIDENCIA = 96

    /* Tratamento de Erro */  
    SET @P_COD_RET = @@ERROR  
    IF @P_COD_RET != 0 
    BEGIN  
       SET @P_MSG_RET = 'Erro ao consultar conta para cr�dito'  
       GOTO TRATA_ERRO  
    END  

    SELECT @DATA_ATUAL = DAT.DATA_PREG
    FROM DBO.VDTDATA_PREG DAT
    WHERE DAT.TIPO_PROC = 'ONL'
      AND DAT.TIPO_DATA = 'D+0'
      AND DAT.SIGL_SIST = 'CAC'

    /* Tratamento de Erro */  
    SET @P_COD_RET = @@ERROR  
    IF @P_COD_RET != 0 
    BEGIN  
       SET @P_MSG_RET = 'Erro na Data Atual '  
       GOTO TRATA_ERRO  
    END  

    -- Pega os N�meros de Processos usados para Convers�o
    BEGIN
        INSERT INTO #CS_PROCESSOS_CONVERSAO (NUM_PROC
                                           , COD_ISIN
                                           , NUM_DIST
                                           , COD_CART_BLOQ
                                           , COD_TIPO_EVEN
                                           , DESC_TIPO_EVEN
                                           , VAL_DINH_RES
                                           , DATA_PRAZO
                                           , FAT_COT_PAC
                                           , QTE_PARC_SUBS
                                           , IND_DIR_DTBA)
        SELECT DISTINCT PED.NUM_PROC
                      , VC2.COD_ISIN_RES
                      , VC2.NUM_DIST_RES
                      , PAR.COD_CART_BLOQ
                      , VCP.COD_TIPO_EVEN
                      , VCP.DESC_TIPO_EVEN
                      , ISNULL(VCO.VAL_DINH_RES, 0)
                      , VCO.DATA_FIM_OPC
                      , VCP.FAT_COT_PAC
                      , ISNULL(VCP.QTE_PARC_SUBS, 0)
                      , ISNULL(PAR.IND_DIR_DTBA, 'N')
        FROM dbo.TCSPEDI_CALC_EVEN                    PED WITH(NOLOCK)
            INNER JOIN dbo.VCPPROV VCP      WITH(NOLOCK)
                ON VCP.NUM_PROC_PARC = PED.NUM_PROC
            INNER JOIN dbo.VCPPROV_OPC                VCO  WITH(NOLOCK)
                ON VCP.NUM_PROC_PARC = VCO.NUM_PROC_PARC
            INNER JOIN dbo.VCPPROV_OPC                VC2  WITH(NOLOCK)
                ON VCP.NUM_PROC_PARC = VC2.NUM_PROC_PARC
            INNER JOIN dbo.TCSPARM_PROC_EVEN_VOLU     PAR  WITH(NOLOCK)   -- J� VERIFICA O TIPO DO EVENTO
                ON PED.NUM_PROC = PAR.NUM_PROC
        WHERE (PED.NUM_PROC      = @P_NUM_PROC     OR @P_NUM_PROC     IS NULL)
          AND (VC2.COD_ISIN_RES  = @P_COD_ISIN     OR @P_COD_ISIN     IS NULL)
          AND (VC2.NUM_DIST_RES  = @P_NUM_DIST     OR @P_NUM_DIST     IS NULL) 
          AND (VCP.COD_TIPO_EVEN = @P_COD_TIP_EVEN OR @P_COD_TIP_EVEN IS NULL)  -- C�digo do Evento
          AND VCP.COD_TIPO_EVEN != 91                                           -- Excluindo N pra N
          AND VCP.IND_SITU_EVEN_PARC = 1                                           -- ATIVO
          AND VCO.IND_RES            = 1
          AND VC2.IND_RES            = 0
          AND (
                /*
                Quando Consulta, possibilita a Op��o por filtro do Estado de Direito
                    Caso n�o tenha, desconsidera.
                    Tamb�m desconsidera a Consulta
                */
                (@P_TIPO_OPERACAO = 'T' AND (PED.COD_ESTD_CALC_DIR = @P_COD_ESTD_CALC_DIR OR  @P_COD_ESTD_CALC_DIR IS NULL) )
                    OR 
                /*
                Quando N�O Consulta, For�a estado de Direito como Definitivo ou Pendente, e avalia a vig�ncia para solicita��o.
                */
                (PED.COD_ESTD_CALC_DIR IN (2,4) AND @DATA_ATUAL BETWEEN VCO.DATA_INIC_OPC AND VCO.DATA_FIM_OPC)
              )             -- Estado de C�lculo de Direito

        /* Tratamento de Erro */  
        SELECT @TOTAL_REG = @@ROWCOUNT, @P_COD_RET = @@ERROR  
        IF @P_COD_RET != 0 
        BEGIN  
           SET @P_MSG_RET = 'Erro ao inserir na tabela #CS_PROCESSOS_CONVERSAO'  
           GOTO TRATA_ERRO  
        END
        
        IF @TOTAL_REG = 1
        BEGIN
            SELECT @P_COD_ISIN = COD_ISIN
                ,  @P_NUM_DIST = NUM_DIST
            FROM #CS_PROCESSOS_CONVERSAO 
        END
    END

    -- Saldo do HCA
    IF @P_TIPO_OPERACAO <> 'C'
    BEGIN
        INSERT INTO #CS_PEGAR_SALDO_HCA (NUM_PROC
                                       , COD_AGCT
                                       , COD_INVS
                                       , COD_ISIN
                                       , NUM_DIST
                                       , QTE_DIR_DISP
                                       , QTE_DIR_ORIG
                                       , QTE_DIR_SOLT
                                       , QTE_DIR_EXER)
        SELECT SLD.NUM_PROC
             , SLD.COD_AGCT
             , SLD.COD_INVS
             , CON.COD_ISIN
             , CON.NUM_DIST
             , SLD.QTE_DIR_ORIG - SLD.QTE_DIR_SOLT - SLD.QTE_DIR_EXER
             , SLD.QTE_DIR_ORIG
             , SLD.QTE_DIR_SOLT
             , SLD.QTE_DIR_EXER
        FROM dbo.TCSSALD_DIR_INVS  SLD    WITH(NOLOCK)   -- TABELA DE DIREITO DE INVESTIDOR
            INNER JOIN #CS_PROCESSOS_CONVERSAO CON
                ON SLD.NUM_PROC = CON.NUM_PROC
        WHERE (SLD.NUM_PROC = @P_NUM_PROC OR @P_NUM_PROC IS NULL) --  ISNULL(@P_NUM_PROC, SLD.NUM_PROC)
          AND (SLD.COD_AGCT = @P_COD_AGCT OR @P_COD_AGCT IS NULL) -- ISNULL(@P_COD_AGCT, SLD.COD_AGCT)
          AND (SLD.COD_INVS = @P_COD_INVS OR @P_COD_INVS IS NULL) -- ISNULL(@P_COD_INVS, SLD.COD_INVS)
          AND (CON.COD_ISIN = @P_COD_ISIN OR @P_COD_ISIN IS NULL) -- ISNULL(@P_COD_ISIN, CON.COD_ISIN)
--          AND CON.NUM_DIST = ISNULL(@P_NUM_DIST, CON.NUM_DIST) -- N�O TRABALHA COM N�MERO DE DISTRIBUI��O

        /* Tratamento de Erro */  
        SET @P_COD_RET = @@ERROR  
        IF @P_COD_RET != 0 
        BEGIN  
           SET @P_MSG_RET = 'Erro ao inserir na tabela #CS_PEGAR_SALDO_HCA'  
           GOTO TRATA_ERRO  
        END
    END

    -- Saldo de Investidor
    /*
    Este Group By � feito ap�s o #CS_PEGAR_SALDO_HCA, para Filtrar o acesso ao Saldo Invs Cust
    */ 
    BEGIN
        INSERT INTO #CS_SALDO_INVS_PAPEL (COD_AGCT
                                        , COD_INVS
                                        , COD_CART
                                        , COD_ISIN
                                        , NUM_DIST
                                        , QTE_SALD)
        SELECT SAL.COD_AGCT
             , SAL.COD_INVS
             , SAL.COD_CART
             , SAL.COD_ISIN
             , SAL.NUM_DIST
             , SAL.QTE_ATIV_SALD_INVS_CUST - SAL.QTE_BLOQ_SALD_INVS_CUST
        FROM dbo.TCSSALD_INVS_CUST                 SAL  WITH (NOLOCK)
        WHERE (SAL.COD_AGCT = @P_COD_AGCT OR @P_COD_AGCT IS NULL)    -- ISNULL(@P_COD_AGCT, SAL.COD_AGCT)
          AND (SAL.COD_INVS = @P_COD_INVS OR @P_COD_INVS IS NULL)    -- ISNULL(@P_COD_INVS, SAL.COD_INVS)
          AND (SAL.COD_ISIN = @P_COD_ISIN OR @P_COD_ISIN IS NULL)    -- ISNULL(@P_COD_ISIN, SAL.COD_ISIN)
          AND (SAL.NUM_DIST = @P_NUM_DIST OR @P_NUM_DIST IS NULL)    -- ISNULL(@P_NUM_DIST, SAL.NUM_DIST)
          AND (SAL.QTE_ATIV_SALD_INVS_CUST - SAL.QTE_BLOQ_SALD_INVS_CUST) > 0
          AND (
                /* 
                   Caso S - Solicita��o,  pega dados das Carteiras Livres
                   Caso C - Cancelamento, pega dados da Carteira de Bloqueio de Convers�o
                   Caso T - Pega Quando � chamado por uma Consulta
                   Caso A - Pega tudo que est� no Saldo do Investidor
                            Menos as carteiras de Bloqueios, por elas representarem a parte "Solicitada"
                            Isso quer dizer que pega al�m da carteira livre, as carteiras de Garantias entre outras
                   Na Solicita��o:
                        - N�o pode ser carteira que Usu�rio Externo n�o possa transferir
                        - N�o pode ser carteira de Derivativos (Garantias, por exemplo)
                */
                (@P_TIPO_OPERACAO IN ('S', 'T') AND (SAL.COD_CART = @COD_CART_LIVRE OR SAL.COD_CART = @COD_CART_LIVRE_BALCAO))
                    OR
                (@P_TIPO_OPERACAO = 'C' AND SAL.COD_CART = @COD_CART_BLOQ_CONV)
                    OR
                (@P_TIPO_OPERACAO = 'C' AND SAL.COD_CART = @COD_CART_BLOQ_DISS)
                    OR
                (@P_TIPO_OPERACAO = 'C' AND SAL.COD_CART = @COD_CART_BLOQ_RETR)
                    OR
                (@P_TIPO_OPERACAO = 'A' AND SAL.COD_CART <> @COD_CART_BLOQ_CONV AND SAL.COD_CART <> @COD_CART_BLOQ_DISS)
               ) 
          AND EXISTS (SELECT TOP 1 1 
                      FROM #CS_PROCESSOS_CONVERSAO CON
                      WHERE CON.COD_ISIN = SAL.COD_ISIN
                        AND CON.NUM_DIST = SAL.NUM_DIST)

        /* Tratamento de Erro */  
        SET @P_COD_RET = @@ERROR  
        IF @P_COD_RET != 0 
        BEGIN  
           SET @P_MSG_RET = 'Erro ao inserir na tabela #CS_SALDO_INVS_PAPEL'  
           GOTO TRATA_ERRO  
        END
    END

    -- Consulta Geral
    -- #CS_SALDO_APURADO_AGCT
    BEGIN
        INSERT INTO #CS_SALDO_APURADO (COD_AGCT
                                     , COD_INVS
                                     , COD_ISIN
                                     , NUM_DIST
                                     , NUM_PROC
                                     , COD_TIPO_EVEN
                                     , DESC_TIPO_EVEN
                                     , VAL_DINH_RES
                                     , DATA_PRAZO
                                     , FAT_COT_PAC
                                     , QTE_PARC_SUBS
                                     , QTE_SALD_DISP
                                     , QTE_SOLT_ACUM
                                     , QTE_SOLT_PERI
                                     , QTE_DIR_DISP
                                     , QTE_DIR_SOLT
                                     , QTE_DIR_EXER
                                     , QTE_DIR_ORIG
                                     , QTE_SALD
                                     , OPERACAO
                                     , TEM_HCA)
        SELECT PAP.COD_AGCT
             , PAP.COD_INVS
             , CON.COD_ISIN
             , CON.NUM_DIST
             , CON.NUM_PROC
             , CON.COD_TIPO_EVEN
             , CON.DESC_TIPO_EVEN
             , CON.VAL_DINH_RES
             , CON.DATA_PRAZO
             , CON.FAT_COT_PAC
             , CON.QTE_PARC_SUBS
             /*
                Se n�o possuir HCA, mostra total Dispon�vel no Saldo
                Caso contr�rio, pega o Menor entre o Saldo e o HCA
             */
             , CASE WHEN CON.IND_DIR_DTBA = 'N'               THEN SUM(ISNULL(PAP.QTE_SALD, 0))
                    WHEN SUM(ISNULL(PAP.QTE_SALD, 0)) > HCA.QTE_DIR_DISP THEN HCA.QTE_DIR_DISP
                    ELSE SUM(ISNULL(PAP.QTE_SALD, 0))
               END QTE_SALD_DISP
             /*
                Esta s� ser� usado no Cancelamento:
                    Em Cancelamento, indenpendente de possuir no HCA (IND_DIR_DTBA = 'N')
                    Pega sempre do Saldo de Bloqueio
             */
             , ISNULL(SOL.QTE_SOLT_ACUM, 0) QTE_SOLT_ACUM
             , ISNULL(SOL.QTE_SOLT_PERI, 0) QTE_SOLT_PERI
             , ISNULL(HCA.QTE_DIR_DISP, 0)
             , ISNULL(HCA.QTE_DIR_SOLT, 0)
             , ISNULL(HCA.QTE_DIR_EXER, 0)
             , ISNULL(HCA.QTE_DIR_ORIG, 0)
             , ISNULL(SUM(PAP.QTE_SALD), 0)
             , 'CONVER_DISSID'               OPERACAO
             , CASE WHEN HCA.COD_AGCT IS NULL THEN 0 ELSE 1 END
        FROM #CS_PROCESSOS_CONVERSAO        CON
            INNER JOIN  #CS_SALDO_INVS_PAPEL PAP
                ON PAP.COD_ISIN = CON.COD_ISIN
               AND PAP.NUM_DIST = CON.NUM_DIST
               AND (
                    (@P_TIPO_OPERACAO = 'C' AND PAP.COD_CART = CON.COD_CART_BLOQ) 
                    OR
                    (@P_TIPO_OPERACAO <> 'C') 
                   )
            LEFT JOIN DBO.TCSSALD_SOLI SOL WITH (NOLOCK)
                ON SOL.NUM_PROC = CON.NUM_PROC
               AND SOL.COD_AGCT = PAP.COD_AGCT
               AND SOL.COD_INVS = PAP.COD_INVS
            LEFT JOIN #CS_PEGAR_SALDO_HCA HCA
                ON CON.NUM_PROC = HCA.NUM_PROC
               AND PAP.COD_AGCT = HCA.COD_AGCT
               AND PAP.COD_INVS = HCA.COD_INVS
               AND PAP.COD_ISIN = HCA.COD_ISIN
--                AND PAP.NUM_DIST = HCA.NUM_DIST  -- N�O TRABALHAR COM N�MERO DE DISTRIBUI��O, QUANDO DATA BASE
        /*
            Se exige IND_DIR_DTBA = S ent�o precisa ter dados hist�ricos
            Caso contr�rio, n�o h� necessidade.
        */
        WHERE (
                -- Se solicita��o, e data base, precisa ter saldo no HCA
                (@P_TIPO_OPERACAO  IN ('S', 'T') AND CON.IND_DIR_DTBA = 'S' AND HCA.COD_AGCT IS NOT NULL)    
                   OR 
                -- Se Solicita��o, para n�o verificar a Data Base, n�o precisa de HCA.
                (@P_TIPO_OPERACAO  IN ('S', 'T') AND CON.IND_DIR_DTBA = 'N')
                   OR 
                -- Se Cancelamento, sendo ou n�o Data Base, n�o precisa ter na HCA.
                 @P_TIPO_OPERACAO  NOT IN ('S', 'T')
              )    
        GROUP BY PAP.COD_AGCT
               , PAP.COD_INVS
               , CON.COD_ISIN
               , CON.NUM_DIST
               , CON.NUM_PROC
               , CON.COD_TIPO_EVEN
               , CON.DESC_TIPO_EVEN
               , CON.VAL_DINH_RES
               , CON.DATA_PRAZO
               , CON.FAT_COT_PAC
               , CON.QTE_PARC_SUBS
               , CON.IND_DIR_DTBA
               , SOL.QTE_SOLT_ACUM
               , SOL.QTE_SOLT_PERI
               , HCA.QTE_DIR_DISP
               , HCA.QTE_DIR_SOLT
               , HCA.QTE_DIR_EXER
               , HCA.QTE_DIR_DISP
               , HCA.QTE_DIR_ORIG
               , HCA.COD_AGCT

        /* Tratamento de Erro */  
        SET @P_COD_RET = @@ERROR
        IF @P_COD_RET != 0 
        BEGIN  
           SET @P_MSG_RET = 'Erro ao inserir na tabela #CS_SALDO_INVS_PAPEL'  
           GOTO TRATA_ERRO  
        END
    END
    /* 
        Caso seja Consulta, e n�o possua Saldo na Carteira Livre (Dispon�vel)
        Nesse select ele pega os registros que n�o possuam Dispon�veis
    */

    IF (@P_TIPO_OPERACAO = 'T')
    BEGIN
        INSERT INTO #CS_SALDO_APURADO (COD_AGCT
                                     , COD_INVS
                                     , COD_ISIN
                                     , NUM_DIST
                                     , NUM_PROC
                                     , COD_TIPO_EVEN
                                     , DESC_TIPO_EVEN
                                     , VAL_DINH_RES
                                     , DATA_PRAZO
                                     , FAT_COT_PAC
                                     , QTE_PARC_SUBS
                                     , QTE_SALD_DISP
                                     , QTE_SOLT_ACUM
                                     , QTE_SOLT_PERI
                                     , QTE_DIR_DISP
                                     , QTE_DIR_SOLT
                                     , QTE_DIR_EXER
                                     , QTE_DIR_ORIG
                                     , QTE_SALD
                                     , OPERACAO
                                     , TEM_HCA)
        SELECT SOL.COD_AGCT
             , SOL.COD_INVS
             , CON.COD_ISIN
             , CON.NUM_DIST
             , CON.NUM_PROC
             , CON.COD_TIPO_EVEN
             , CON.DESC_TIPO_EVEN
             , CON.VAL_DINH_RES
             , CON.DATA_PRAZO
             , CON.FAT_COT_PAC
             , CON.QTE_PARC_SUBS
             , 0 QTE_SALD_DISP    -- N�o h� Saldo Dispon�vel, sen�o teria na TCSSALD_INVS_CUST
             , SOL.QTE_SOLT_ACUM    QTE_SOLT_ACUM
             , SOL.QTE_SOLT_PERI    QTE_SOLT_PERI
             , 0                    QTE_DIR_DISP
             , 0                    QTE_DIR_SOLT
             , 0                    QTE_DIR_EXER
             , 0                    QTE_DIR_ORIG
             , 0                    QTE_SALD
             , 'CONVER_DISSID'      OPERACAO
             , 0
        FROM #CS_PROCESSOS_CONVERSAO        CON
            INNER JOIN DBO.TCSSALD_SOLI SOL WITH (NOLOCK)
                ON SOL.NUM_PROC = CON.NUM_PROC
            LEFT JOIN  #CS_SALDO_INVS_PAPEL PAP
                ON PAP.COD_ISIN = CON.COD_ISIN
               AND PAP.NUM_DIST = CON.NUM_DIST
               AND (PAP.COD_CART = @COD_CART_LIVRE OR PAP.COD_CART = @COD_CART_LIVRE_BALCAO)--AQUI
               AND PAP.COD_AGCT = SOL.COD_AGCT
               AND PAP.COD_INVS = SOL.COD_INVS
        WHERE (SOL.NUM_PROC = @P_NUM_PROC OR @P_NUM_PROC IS NULL) -- (CASE when @P_NUM_PROC is null then SOL.NUM_PROC else @P_NUM_PROC end)
          AND (SOL.COD_AGCT = @P_COD_AGCT OR @P_COD_AGCT IS NULL) -- (CASE when @P_COD_AGCT is null then SOL.COD_AGCT else @P_COD_AGCT end)
          AND (SOL.COD_INVS = @P_COD_INVS OR @P_COD_INVS IS NULL) -- (CASE when @P_COD_INVS is null then SOL.COD_INVS else @P_COD_INVS end)
          AND PAP.COD_ISIN IS NULL

        /* Tratamento de Erro */  
        SET @P_COD_RET = @@ERROR
        IF @P_COD_RET != 0 
        BEGIN  
           SET @P_MSG_RET = 'Erro ao inserir na tabela #CS_SALDO_INVS_PAPEL - T '  
           GOTO TRATA_ERRO  
        END
    END

    -- Apenas apura quando Solicita��o, Cancelamento ou Todos
    SELECT COD_AGCT
         , COD_INVS
         , COD_ISIN
         , NUM_DIST
         , TSAL.NUM_PROC
         , TSAL.COD_TIPO_EVEN
         , DESC_TIPO_EVEN
         , VAL_DINH_RES
         , DATA_PRAZO
         , FAT_COT_PAC
         , QTE_PARC_SUBS
         , QTE_SALD_DISP            -- Saldo Dispon�vel
         , QTE_SOLT_ACUM            -- Solicitado Acumulado
         , QTE_SOLT_PERI            -- Solicitado No Per�odo
         , OPERACAO
    FROM #CS_SALDO_APURADO TSAL 
    WHERE (
            (@P_TIPO_OPERACAO = 'S' AND QTE_SALD_DISP > 0) 
                OR
            (@P_TIPO_OPERACAO = 'C' AND QTE_SOLT_PERI > 0) 
                OR
            (@P_TIPO_OPERACAO = 'A' AND QTE_SALD_DISP > 0) 
                OR
            (@P_TIPO_OPERACAO = 'T') 
          )
    ORDER BY COD_AGCT
           , COD_INVS
           , TSAL.NUM_PROC

    /* 
    ATEN��O: Esta procedure est� sendo usada no tratamento do Arquivo IEVL e CEVL (Eventos Volunt�rios)
             Qualquer altera��o, por favor replicar nas procedures:
                    ->  SPCS_CO_CON_DIS_SOL_CAN_PARAM
                    ->  SPCS_PR_CONV_DISSID_SOLIC_CANCEL
                    ->  SPCS_PR_CEVL
                    ->  SPCS_PR_IEVL_GRAVA_REGISTRO_07
                    ->  SPCS_PR_IEVL_GRAVA_REGISTRO_08
                    ->  SPCS_CO_EVEN_GER_ATIV_RES_VOLUNT
                    ->  SPCS_CO_EVEN_GER_ATIV_RES_VOLUNT
                    ->  SPCS_CO_EVEN_GER_ATIV_VOL_AGCT
                    ->  SPCS_CO_EVEN_GER_ATIV_VOL_AGCTIN
                    ->  SPCS_CO_INVS_PROC
                    ->  SPCS_CO_INVS_PROC_DET_INVS
                    ->  SPCS_CO_PROCESSOS_EVENTOS
             Kleber Almeida ::::   07/12/2007
    */

    /* Tratamento de Erro */  
    SET @P_COD_RET = @@ERROR  
    IF @P_COD_RET != 0 
    BEGIN  
       SET @P_MSG_RET = 'Erro ao consultar tabela tempor�ria'  
       GOTO TRATA_ERRO  
    END     

    
    BEGIN
        SELECT @P_COD_RET = 0
        SET @P_MSG_RET = 'Solicita��o de Convers�o executada com sucesso'
    END
    
    --ENCERRA O AMBIENTE
    SET NOCOUNT OFF
    RETURN @P_COD_RET

TRATA_ERRO:
    --ENCERRA O AMBIENTE
    SET NOCOUNT OFF
    RAISERROR (@P_MSG_RET,16,1)
    RETURN @P_COD_RET
END


GO


