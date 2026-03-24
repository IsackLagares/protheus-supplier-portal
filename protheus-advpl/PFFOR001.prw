// ============================================================
//  PFFOR001.PRW
//  Portal Fornecedor - Endpoint Dados Cadastrais (SA2)
//  Protheus 12
// ============================================================

#Include 'TOTVS.ch'
#Include 'RESTFUL.ch'
#Include 'PFCONST.ch'

// ------------------------------------------------------------
//  GET /portalfornecedor/v1/fornecedor
//  Header: X-PF-Token
//  Retorna dados cadastrais do fornecedor autenticado
// ------------------------------------------------------------
WSMETHOD GET dadosFornecedor WSSERVICE portalFornecedor

    Local cToken  := ::GetHeader("X-PF-Token")
    Local cCodFor := ""
    Local cLoja   := ""
    Local oResp   := JsonObject():New()
    Local oFor    := JsonObject():New()

    If !PF_ValidaToken(cToken, @cCodFor, @cLoja)
        ::SetStatus(401)
        oResp['erro'] := "Token inválido ou expirado"
        ::SetResponse(oResp:ToJson())
        Return .F.
    EndIf

    BeginSQL Alias "QSA2"
        SELECT
            A2_COD, A2_LOJA, A2_NOME, A2_NREDUZ,
            A2_CGC, A2_INSEST, A2_END, A2_NR,
            A2_COMPL, A2_BAIRRO, A2_CEP,
            A2_MUN, A2_EST, A2_PAIS,
            A2_TEL, A2_EMAIL, A2_CONTATO
        FROM %Table:SA2% SA2
        WHERE SA2.%NotDel%
          AND SA2.A2_COD  = %Exp:cCodFor%
          AND SA2.A2_LOJA = %Exp:cLoja%
          AND SA2.D_E_L_E_T_ = ' '
    EndSQL

    If (QSA2)->(Eof())
        (QSA2)->(DbCloseArea())
        ::SetStatus(404)
        oResp['erro'] := "Fornecedor não encontrado"
        ::SetResponse(oResp:ToJson())
        Return .F.
    EndIf

    oFor['codigo']    := AllTrim((QSA2)->A2_COD)
    oFor['loja']      := AllTrim((QSA2)->A2_LOJA)
    oFor['razaoSocial']:= AllTrim((QSA2)->A2_NOME)
    oFor['nomeReduz'] := AllTrim((QSA2)->A2_NREDUZ)
    oFor['cnpj']      := PF_FormatCNPJ((QSA2)->A2_CGC)   // -> "12.345.678/0001-99"
    oFor['ie']        := AllTrim((QSA2)->A2_INSEST)
    oFor['endereco']  := AllTrim((QSA2)->A2_END)
    oFor['numero']    := AllTrim((QSA2)->A2_NR)
    oFor['complemento']:= AllTrim((QSA2)->A2_COMPL)
    oFor['bairro']    := AllTrim((QSA2)->A2_BAIRRO)
    oFor['cep']       := PF_FormatCEP((QSA2)->A2_CEP)    // -> "01310-100"
    oFor['municipio'] := AllTrim((QSA2)->A2_MUN)
    oFor['estado']    := AllTrim((QSA2)->A2_EST)
    oFor['pais']      := AllTrim((QSA2)->A2_PAIS)
    oFor['telefone']  := AllTrim((QSA2)->A2_TEL)
    oFor['email']     := AllTrim((QSA2)->A2_EMAIL)
    oFor['contato']   := AllTrim((QSA2)->A2_CONTATO)
    (QSA2)->(DbCloseArea())

    ::SetStatus(200)
    oResp['dados'] := oFor
    ::SetResponse(oResp:ToJson())
Return .T.
