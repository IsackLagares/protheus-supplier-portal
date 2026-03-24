// ============================================================
//  PFTIT001.PRW
//  Portal Fornecedor - Endpoint de Títulos Financeiros
//  Protheus 12
//
//  Tabela principal: SE2 (Contas a Pagar)
//  Lógica de negócio:
//    E2_SALDO > 0  + E2_VENCTO >= Hoje -> "Pagamento Pendente"
//    E2_SALDO > 0  + E2_VENCTO <  Hoje -> "Vencido"
//    E2_SALDO = 0                       -> "Pago"
// ============================================================

#Include 'TOTVS.ch'
#Include 'RESTFUL.ch'
#Include 'PFCONST.ch'

// ------------------------------------------------------------
//  GET /portalfornecedor/v1/titulos
//  QueryParams:
//    ?status=pendente|vencido|pago|todos
//    ?dtinicio=YYYYMMDD  (vencimento)
//    ?dtfim=YYYYMMDD
// ------------------------------------------------------------
WSMETHOD GET titulos WSSERVICE portalFornecedor

    Local cToken    := ::GetHeader("X-PF-Token")
    Local cCodFor   := ""
    Local cLoja     := ""
    Local cStatus   := Lower(AllTrim(::GetQueryParam("status", "todos")))
    Local cDtIni    := AllTrim(::GetQueryParam("dtinicio", DToS(Date() - 90)))
    Local cDtFim    := AllTrim(::GetQueryParam("dtfim", DToS(Date() + 60)))
    Local cHoje     := DToS(Date())
    Local oResp     := JsonObject():New()
    Local aTitulos  := {}
    Local oTit
    Local cStatusCalc
    Local cStatusAmig

    If !PF_ValidaToken(cToken, @cCodFor, @cLoja)
        ::SetStatus(401)
        oResp['erro'] := "Token inválido ou expirado"
        ::SetResponse(oResp:ToJson())
        Return .F.
    EndIf

    // -- Embedded SQL: SE2 com lógica de status
    BeginSQL Alias "QTIT"
        SELECT
            SE2.E2_NUM        AS TIT_NUM,
            SE2.E2_PARCELA    AS TIT_PARC,
            SE2.E2_TIPO       AS TIT_TIPO,
            SE2.E2_EMISSAO    AS TIT_EMISSAO,
            SE2.E2_VENCTO     AS TIT_VENCTO,
            SE2.E2_VENCREA    AS TIT_VENCREAL,
            SE2.E2_VALOR      AS TIT_VALOR,
            SE2.E2_SALDO      AS TIT_SALDO,
            SE2.E2_BAIXA      AS TIT_BAIXA,
            SE2.E2_HSALDO     AS TIT_HISTORICO,
            SE2.E2_PORTADO    AS TIT_PORTADOR,
            SE2.E2_DOCUMEN    AS TIT_NF,
            -- Status calculado no SQL para permitir filtro eficiente
            CASE
                WHEN SE2.E2_SALDO = 0                              THEN 'PAGO'
                WHEN SE2.E2_SALDO > 0 AND SE2.E2_VENCTO < %Exp:cHoje% THEN 'VENCIDO'
                ELSE                                                    'PENDENTE'
            END AS TIT_STATUS
        FROM
            %Table:SE2% SE2
        WHERE
            SE2.%NotDel%
            AND SE2.E2_FORNECE = %Exp:cCodFor%
            AND SE2.E2_LOJA    = %Exp:cLoja%
            AND SE2.E2_VENCTO  BETWEEN %Exp:cDtIni% AND %Exp:cDtFim%
            AND SE2.D_E_L_E_T_ = ' '
        ORDER BY
            SE2.E2_VENCTO ASC
    EndSQL

    (QTIT)->(DbGoTop())
    While !(QTIT)->(Eof())

        cStatusCalc := AllTrim((QTIT)->TIT_STATUS)

        // Filtra por status se solicitado
        If cStatus == "todos" .Or. Lower(cStatusCalc) == cStatus

            cStatusAmig := PF_StatusTituloAmigavel(cStatusCalc)

            oTit := JsonObject():New()
            oTit['numero']      := AllTrim((QTIT)->TIT_NUM)
            oTit['parcela']     := AllTrim((QTIT)->TIT_PARC)
            oTit['tipo']        := AllTrim((QTIT)->TIT_TIPO)
            oTit['emissao']     := PF_FormatData((QTIT)->TIT_EMISSAO)
            oTit['vencimento']  := PF_FormatData((QTIT)->TIT_VENCTO)
            oTit['vencimentoReal']:= PF_FormatData((QTIT)->TIT_VENCREAL)
            oTit['valor']       := (QTIT)->TIT_VALOR
            oTit['valorFmt']    := PF_FormatMoeda((QTIT)->TIT_VALOR)
            oTit['saldo']       := (QTIT)->TIT_SALDO
            oTit['saldoFmt']    := PF_FormatMoeda((QTIT)->TIT_SALDO)
            oTit['dataBaixa']   := PF_FormatData((QTIT)->TIT_BAIXA)
            oTit['historico']   := AllTrim((QTIT)->TIT_HISTORICO)
            oTit['notaFiscal']  := AllTrim((QTIT)->TIT_NF)
            oTit['portador']    := AllTrim((QTIT)->TIT_PORTADOR)
            oTit['status']      := cStatusAmig
            oTit['statusCod']   := cStatusCalc
            // Flag para vencimento próximo (7 dias)
            oTit['venceEm7d']   := ((QTIT)->TIT_VENCTO <= DToS(Date() + 7) .And. cStatusCalc == "PENDENTE")

            AAdd(aTitulos, oTit)
        EndIf

        (QTIT)->(DbSkip())
    EndDo
    (QTIT)->(DbCloseArea())

    // -- Totalizadores
    Local nTotalPendente := 0
    Local nTotalVencido  := 0
    Local oTotais        := JsonObject():New()

    AEval(aTitulos, {|o| ;
        iif(o['statusCod'] == "PENDENTE", nTotalPendente += o['saldo'], Nil), ;
        iif(o['statusCod'] == "VENCIDO",  nTotalVencido  += o['saldo'], Nil)  ;
    })

    oTotais['pendente'] := PF_FormatMoeda(nTotalPendente)
    oTotais['vencido']  := PF_FormatMoeda(nTotalVencido)

    ::SetStatus(200)
    oResp['dados']     := aTitulos
    oResp['totais']    := oTotais
    oResp['quantidade']:= Len(aTitulos)
    ::SetResponse(oResp:ToJson())
Return .T.


// ------------------------------------------------------------
//  GET /portalfornecedor/v1/titulos/{sTitulo}/{sParcela}
// ------------------------------------------------------------
WSMETHOD GET tituloDetalhe WSRECEIVE sTitulo, sParcela WSSERVICE portalFornecedor

    Local cToken  := ::GetHeader("X-PF-Token")
    Local cCodFor := ""
    Local cLoja   := ""
    Local oResp   := JsonObject():New()
    Local oTit    := JsonObject():New()

    If !PF_ValidaToken(cToken, @cCodFor, @cLoja)
        ::SetStatus(401)
        oResp['erro'] := "Token inválido ou expirado"
        ::SetResponse(oResp:ToJson())
        Return .F.
    EndIf

    BeginSQL Alias "QTITD"
        SELECT
            E2_NUM, E2_PARCELA, E2_TIPO, E2_EMISSAO,
            E2_VENCTO, E2_VENCREA, E2_VALOR, E2_SALDO,
            E2_BAIXA, E2_HSALDO, E2_PORTADO, E2_DOCUMEN,
            E2_NATUREZ, E2_MOEDA, E2_NUMBCO, E2_AGENCIA
        FROM %Table:SE2% SE2
        WHERE SE2.%NotDel%
          AND SE2.E2_FORNECE = %Exp:cCodFor%
          AND SE2.E2_LOJA    = %Exp:cLoja%
          AND SE2.E2_NUM     = %Exp:sTitulo%
          AND SE2.E2_PARCELA = %Exp:sParcela%
          AND SE2.D_E_L_E_T_ = ' '
    EndSQL

    If (QTITD)->(Eof())
        (QTITD)->(DbCloseArea())
        ::SetStatus(404)
        oResp['erro'] := "Título não encontrado"
        ::SetResponse(oResp:ToJson())
        Return .F.
    EndIf

    oTit['numero']       := AllTrim((QTITD)->E2_NUM)
    oTit['parcela']      := AllTrim((QTITD)->E2_PARCELA)
    oTit['tipo']         := AllTrim((QTITD)->E2_TIPO)
    oTit['emissao']      := PF_FormatData((QTITD)->E2_EMISSAO)
    oTit['vencimento']   := PF_FormatData((QTITD)->E2_VENCTO)
    oTit['vencimentoReal']:= PF_FormatData((QTITD)->E2_VENCREA)
    oTit['valorFmt']     := PF_FormatMoeda((QTITD)->E2_VALOR)
    oTit['saldoFmt']     := PF_FormatMoeda((QTITD)->E2_SALDO)
    oTit['dataBaixa']    := PF_FormatData((QTITD)->E2_BAIXA)
    oTit['historico']    := AllTrim((QTITD)->E2_HSALDO)
    oTit['portador']     := AllTrim((QTITD)->E2_PORTADO)
    oTit['notaFiscal']   := AllTrim((QTITD)->E2_DOCUMEN)
    oTit['natureza']     := AllTrim((QTITD)->E2_NATUREZ)
    oTit['moeda']        := AllTrim((QTITD)->E2_MOEDA)
    oTit['banco']        := AllTrim((QTITD)->E2_NUMBCO)
    oTit['agencia']      := AllTrim((QTITD)->E2_AGENCIA)
    (QTITD)->(DbCloseArea())

    ::SetStatus(200)
    oResp['dados'] := oTit
    ::SetResponse(oResp:ToJson())
Return .T.
