// ============================================================
//  PFAUTH001.PRW
//  Portal Fornecedor - Autenticação
//  Protheus 12
//
//  Fluxo:
//    1. Recebe CNPJ + chave do fornecedor (SA2.A2_CHVPF)
//    2. Valida contra SA2 com Embedded SQL
//    3. Gera token temporário gravado em SXE/tabela custom
//    4. Retorna token para o frontend usar no header X-PF-Token
// ============================================================

#Include 'TOTVS.ch'
#Include 'RESTFUL.ch'
#Include 'PFCONST.ch'

// ------------------------------------------------------------
//  POST /portalfornecedor/v1/login
//  Body: { "cnpj": "12345678000199", "chave": "XPTO1234" }
// ------------------------------------------------------------
WSMETHOD POST login WSRECEIVE oReq WSSERVICE portalFornecedor

    Local cCNPJ    := ""
    Local cChave   := ""
    Local cToken   := ""
    Local cCodFor  := ""
    Local cLoja    := ""
    Local lOk      := .F.
    Local oResp    := JsonObject():New()

    // -- Lê e valida payload
    If ValType(oReq) <> 'O' .Or. oReq == Nil
        ::SetStatus(400)
        oResp['erro'] := "Payload inválido"
        ::SetResponse(oResp:ToJson())
        Return .F.
    EndIf

    cCNPJ  := AllTrim(oReq['cnpj'])
    cChave := AllTrim(oReq['chave'])

    If Empty(cCNPJ) .Or. Empty(cChave)
        ::SetStatus(400)
        oResp['erro'] := "CNPJ e chave são obrigatórios"
        ::SetResponse(oResp:ToJson())
        Return .F.
    EndIf

    // -- Autenticação via Embedded SQL (SA2)
    // Nota: A2_CHVPF é campo customizado a ser criado em SA2
    // sugestão: X2_CHVPF (texto, 20 chars) via SX3
    BeginSQL Alias "QAUTH"
        SELECT
            A2_COD,
            A2_LOJA,
            A2_NOME
        FROM
            %Table:SA2% SA2
        WHERE
            SA2.%NotDel%
            AND REPLACE(SA2.A2_CGC, '.', '')
                    = REPLACE(REPLACE(%Exp:cCNPJ%, '.', ''), '/', '') 
                    -- remove máscaras para comparar
            AND SA2.A2_CHVPF = %Exp:cChave%
            AND SA2.A2_MSBLQL <> '1'
            AND SA2.D_E_L_E_T_ = ' '
    EndSQL

    If !(QAUTH)->(Eof())
        cCodFor := AllTrim((QAUTH)->A2_COD)
        cLoja   := AllTrim((QAUTH)->A2_LOJA)
        cToken  := PF_GeraToken(cCodFor, cLoja)
        lOk     := .T.
    EndIf

    (QAUTH)->(DbCloseArea())

    If lOk
        ::SetStatus(200)
        oResp['token']    := cToken
        oResp['fornecedor'] := cCodFor
        oResp['loja']     := cLoja
        oResp['expira']   := DToS(Date() + PF_TOKEN_EXPIRE) + " 23:59:59"
    Else
        ::SetStatus(401)
        oResp['erro'] := "CNPJ ou chave inválidos"
    EndIf

    ::SetResponse(oResp:ToJson())
Return lOk


// ------------------------------------------------------------
//  POST /portalfornecedor/v1/logout
//  Header: X-PF-Token: <token>
// ------------------------------------------------------------
WSMETHOD POST logout WSSERVICE portalFornecedor

    Local cToken := ::GetHeader("X-PF-Token")
    Local oResp  := JsonObject():New()

    If !Empty(cToken)
        PF_InvalidaToken(cToken)
        ::SetStatus(200)
        oResp['mensagem'] := "Sessão encerrada"
    Else
        ::SetStatus(400)
        oResp['erro'] := "Token não informado"
    EndIf

    ::SetResponse(oResp:ToJson())
Return .T.
