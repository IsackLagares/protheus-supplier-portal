// ============================================================
//  PFNF001.PRW
//  Portal Fornecedor - Endpoint de Notas Fiscais
//  Protheus 12
//
//  Tabelas consultadas: SF1 (NF Entrada Header) + SD1 (Itens)
//  Filtro base: F1_FORNECE + F1_LOJA do token autenticado
// ============================================================

#Include 'TOTVS.ch'
#Include 'RESTFUL.ch'
#Include 'PFCONST.ch'

// ------------------------------------------------------------
//  GET /portalfornecedor/v1/notas
//  QueryParams opcionais:
//    ?status=pendente|pago|todos   (default: todos)
//    ?dtinicio=YYYYMMDD
//    ?dtfim=YYYYMMDD
//    ?pagina=1&itens=20
// ------------------------------------------------------------
WSMETHOD GET notasFiscais WSSERVICE portalFornecedor

    Local cToken    := ::GetHeader("X-PF-Token")
    Local cCodFor   := ""
    Local cLoja     := ""
    Local cStatus   := Lower(AllTrim(::GetQueryParam("status", "todos")))
    Local cDtIni    := AllTrim(::GetQueryParam("dtinicio", DToS(Date() - 90)))
    Local cDtFim    := AllTrim(::GetQueryParam("dtfim", DToS(Date())))
    Local nPagina   := Val(::GetQueryParam("pagina", "1"))
    Local nItens    := Val(::GetQueryParam("itens", "20"))
    Local nOffset   := (nPagina - 1) * nItens
    Local oResp     := JsonObject():New()
    Local aNotas    := {}
    Local oNota

    // -- Valida token
    If !PF_ValidaToken(cToken, @cCodFor, @cLoja)
        ::SetStatus(401)
        oResp['erro'] := "Token inválido ou expirado"
        ::SetResponse(oResp:ToJson())
        Return .F.
    EndIf

    // -- Embedded SQL: busca NFs de entrada do fornecedor
    BeginSQL Alias "QNF"
        SELECT
            SF1.F1_DOC       AS NF_NUMERO,
            SF1.F1_SERIE     AS NF_SERIE,
            SF1.F1_EMISSAO   AS NF_EMISSAO,
            SF1.F1_DTDIGIT   AS NF_ENTRADA,
            SF1.F1_VALBRUT   AS NF_VALOR,
            SF1.F1_CHVNFE    AS NF_CHAVE,
            SF1.F1_SITUAC    AS NF_SITUAC,
            -- Status calculado: verifica se existe título em aberto (SE2)
            CASE
                WHEN EXISTS (
                    SELECT 1 FROM %Table:SE2% SE2
                    WHERE SE2.E2_FORNECE = SF1.F1_FORNECE
                      AND SE2.E2_LOJA    = SF1.F1_LOJA
                      AND SE2.E2_DOCUMEN = SF1.F1_DOC
                      AND SE2.E2_SALDO   > 0
                      AND SE2.D_E_L_E_T_ = ' '
                ) THEN 'PENDENTE'
                ELSE 'PAGO'
            END AS NF_STATUS
        FROM
            %Table:SF1% SF1
        WHERE
            SF1.%NotDel%
            AND SF1.F1_FORNECE = %Exp:cCodFor%
            AND SF1.F1_LOJA    = %Exp:cLoja%
            AND SF1.F1_EMISSAO BETWEEN %Exp:cDtIni% AND %Exp:cDtFim%
            AND SF1.D_E_L_E_T_ = ' '
        ORDER BY
            SF1.F1_EMISSAO DESC
        LIMIT  %Exp:nItens%
        OFFSET %Exp:nOffset%
    EndSQL

    // -- Monta array de resposta
    (QNF)->(DbGoTop())
    While !(QNF)->(Eof())

        // Aplica filtro de status se informado
        If cStatus == "todos" .Or. ;
           (cStatus == "pendente" .And. (QNF)->NF_STATUS == "PENDENTE") .Or. ;
           (cStatus == "pago"     .And. (QNF)->NF_STATUS == "PAGO")

            oNota := JsonObject():New()
            oNota['numero']   := AllTrim((QNF)->NF_NUMERO)
            oNota['serie']    := AllTrim((QNF)->NF_SERIE)
            oNota['emissao']  := PF_FormatData((QNF)->NF_EMISSAO)   // YYYYMMDD -> DD/MM/YYYY
            oNota['entrada']  := PF_FormatData((QNF)->NF_ENTRADA)
            oNota['valor']    := (QNF)->NF_VALOR
            oNota['valorFmt'] := PF_FormatMoeda((QNF)->NF_VALOR)    // -> "R$ 1.234,56"
            oNota['chaveNFe'] := AllTrim((QNF)->NF_CHAVE)
            oNota['status']   := PF_StatusAmigavel((QNF)->NF_STATUS) // -> "Pagamento Pendente"
            oNota['statusCod']:= AllTrim((QNF)->NF_STATUS)

            AAdd(aNotas, oNota)
        EndIf

        (QNF)->(DbSkip())
    EndDo
    (QNF)->(DbCloseArea())

    ::SetStatus(200)
    oResp['dados']   := aNotas
    oResp['pagina']  := nPagina
    oResp['total']   := Len(aNotas)
    ::SetResponse(oResp:ToJson())
Return .T.


// ------------------------------------------------------------
//  GET /portalfornecedor/v1/notas/{nNota}/{sSerie}
//  Retorna detalhe completo + itens da NF
// ------------------------------------------------------------
WSMETHOD GET notaDetalhe WSRECEIVE nNota, sSerie WSSERVICE portalFornecedor

    Local cToken  := ::GetHeader("X-PF-Token")
    Local cCodFor := ""
    Local cLoja   := ""
    Local oResp   := JsonObject():New()
    Local oNota   := JsonObject():New()
    Local aItens  := {}
    Local oItem

    If !PF_ValidaToken(cToken, @cCodFor, @cLoja)
        ::SetStatus(401)
        oResp['erro'] := "Token inválido ou expirado"
        ::SetResponse(oResp:ToJson())
        Return .F.
    EndIf

    // -- Header da NF (SF1)
    BeginSQL Alias "QNFH"
        SELECT
            SF1.F1_DOC, SF1.F1_SERIE, SF1.F1_EMISSAO,
            SF1.F1_VALBRUT, SF1.F1_VALDESC, SF1.F1_VALIPI,
            SF1.F1_ICMS, SF1.F1_CHVNFE, SF1.F1_SITUAC,
            SF1.F1_DTDIGIT, SF1.F1_CONTFIS
        FROM %Table:SF1% SF1
        WHERE SF1.%NotDel%
          AND SF1.F1_FORNECE = %Exp:cCodFor%
          AND SF1.F1_LOJA    = %Exp:cLoja%
          AND SF1.F1_DOC     = %Exp:nNota%
          AND SF1.F1_SERIE   = %Exp:sSerie%
          AND SF1.D_E_L_E_T_ = ' '
    EndSQL

    If (QNFH)->(Eof())
        (QNFH)->(DbCloseArea())
        ::SetStatus(404)
        oResp['erro'] := "NF não encontrada"
        ::SetResponse(oResp:ToJson())
        Return .F.
    EndIf

    oNota['numero']    := AllTrim((QNFH)->F1_DOC)
    oNota['serie']     := AllTrim((QNFH)->F1_SERIE)
    oNota['emissao']   := PF_FormatData((QNFH)->F1_EMISSAO)
    oNota['entrada']   := PF_FormatData((QNFH)->F1_DTDIGIT)
    oNota['valorBruto']:= PF_FormatMoeda((QNFH)->F1_VALBRUT)
    oNota['desconto']  := PF_FormatMoeda((QNFH)->F1_VALDESC)
    oNota['ipi']       := PF_FormatMoeda((QNFH)->F1_VALIPI)
    oNota['icms']      := PF_FormatMoeda((QNFH)->F1_ICMS)
    oNota['chaveNFe']  := AllTrim((QNFH)->F1_CHVNFE)
    oNota['contfis']   := AllTrim((QNFH)->F1_CONTFIS)
    (QNFH)->(DbCloseArea())

    // -- Itens da NF (SD1)
    BeginSQL Alias "QNFI"
        SELECT
            D1_ITEM, D1_DESCRI, D1_COD, D1_UM,
            D1_QUANT, D1_VUNIT, D1_TOTAL
        FROM %Table:SD1% SD1
        WHERE SD1.%NotDel%
          AND SD1.D1_DOC    = %Exp:nNota%
          AND SD1.D1_SERIE  = %Exp:sSerie%
          AND SD1.D1_FORNECE= %Exp:cCodFor%
          AND SD1.D_E_L_E_T_ = ' '
        ORDER BY D1_ITEM
    EndSQL

    (QNFI)->(DbGoTop())
    While !(QNFI)->(Eof())
        oItem := JsonObject():New()
        oItem['item']    := AllTrim((QNFI)->D1_ITEM)
        oItem['codigo']  := AllTrim((QNFI)->D1_COD)
        oItem['descricao']:= AllTrim((QNFI)->D1_DESCRI)
        oItem['unidade'] := AllTrim((QNFI)->D1_UM)
        oItem['quantidade']:= (QNFI)->D1_QUANT
        oItem['valorUnit']:= PF_FormatMoeda((QNFI)->D1_VUNIT)
        oItem['valorTotal']:= PF_FormatMoeda((QNFI)->D1_TOTAL)
        AAdd(aItens, oItem)
        (QNFI)->(DbSkip())
    EndDo
    (QNFI)->(DbCloseArea())

    oNota['itens'] := aItens

    ::SetStatus(200)
    oResp['dados'] := oNota
    ::SetResponse(oResp:ToJson())
Return .T.
