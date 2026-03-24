// ============================================================
//  PFBIZ001.PRW
//  Portal Fornecedor - Funcoes de Negocio e Utilitarios
//  Protheus 12
//
//  Centraliza toda logica de negocio reutilizavel:
//    - Geracao / validacao / invalidacao de tokens
//    - Traducao de status internos para linguagem amigavel
//    - Formatacao de moeda, data, CNPJ, CEP
// ============================================================

#INCLUDE 'TOTVS.ch'
// #INCLUDE 'PFCONST.ch'

// ============================================================
//  TOKENS DE SESSaO
//  Estrategia simples: gravados na tabela Z01 (custom)
//  Alternativa: usar SXE ou memoria (cuidado com multicamadas)
// ============================================================

// ------------------------------------------------------------
//  PF_GeraToken(cCodFor, cLoja) -> cToken
//  Cria um token unico e grava na Z01PF
// ------------------------------------------------------------
Function PF_GeraToken(cCodFor, cLoja)

    Local cToken   := Lower(GetGUID())   // UUID v4 via funcao nativa P12
    Local cExpira  := DToS(Date() + PF_TOKEN_EXPIRE)
    Local oZ01

    // Grava token na tabela de controle
    // Campos sugeridos para Z01PF:
    //   Z1_TOKEN  (C, 40) - o token
    //   Z1_CODFOR (C, 06) - fornecedor
    //   Z1_LOJA   (C, 02) - loja
    //   Z1_EXPIRA (C, 08) - data expiracao YYYYMMDD
    //   Z1_HORA   (C, 08) - hora de criacao HH:MM:SS
    RecLock("Z01PF", .T.)   // .T. = novo registro
        Z01PF->Z1_FILIAL := xFilial("Z01PF")
        Z01PF->Z1_TOKEN  := cToken
        Z01PF->Z1_CODFOR := cCodFor
        Z01PF->Z1_LOJA   := cLoja
        Z01PF->Z1_EXPIRA := cExpira
        Z01PF->Z1_HORA   := Time()
    MsUnLock()

Return cToken


// ------------------------------------------------------------
//  PF_ValidaToken(cToken, @cCodFor, @cLoja) -> lValido
//  Verifica se o token existe e nao expirou
//  Preenche cCodFor e cLoja por referência
// ------------------------------------------------------------
Function PF_ValidaToken(cToken, cCodFor, cLoja)

    Local lValido := .F.

    If Empty(cToken)
        Return .F.
    EndIf

    BeginSQL Alias "QTOK"
        SELECT Z1_CODFOR, Z1_LOJA, Z1_EXPIRA
        FROM %Table:Z01PF% Z01PF
        WHERE Z01PF.%NotDel%
          AND Z01PF.Z1_TOKEN  = %Exp:cToken%
          AND Z01PF.Z1_FILIAL = %Exp:xFilial("Z01PF")%
          AND Z01PF.D_E_L_E_T_ = ' '
    EndSQL

    If !(QTOK)->(Eof())
        // Verifica expiracao
        If (QTOK)->Z1_EXPIRA >= DToS(Date())
            cCodFor := AllTrim((QTOK)->Z1_CODFOR)
            cLoja   := AllTrim((QTOK)->Z1_LOJA)
            lValido := .T.
        EndIf
    EndIf

    (QTOK)->(DbCloseArea())
Return lValido


// ------------------------------------------------------------
//  PF_InvalidaToken(cToken) -> Nil
//  Remove (deleta logico) o token da tabela
// ------------------------------------------------------------
Function PF_InvalidaToken(cToken)

    DbSelectArea("Z01PF")
    DbSetOrder(1)
    If DbSeek(xFilial("Z01PF") + cToken)
        RecLock("Z01PF", .F.)
            DeletE()
        MsUnLock()
    EndIf

Return Nil


// ============================================================
//  TRADUcaO DE STATUS (negocio -> linguagem amigavel)
// ============================================================

// ------------------------------------------------------------
//  PF_StatusAmigavel(cStatusCod) -> cTexto
//  Para NFs (baseado em SE2.E2_SALDO)
// ------------------------------------------------------------
Function PF_StatusAmigavel(cStatusCod)
    Local cTexto := ""

    Do Case
        Case cStatusCod == "PENDENTE" ; cTexto := "Pagamento Pendente"
        Case cStatusCod == "PAGO"     ; cTexto := "Pago"
        Case cStatusCod == "VENCIDO"  ; cTexto := "Vencido"
        Otherwise                     ; cTexto := "Em Processamento"
    EndCase

Return cTexto


// ------------------------------------------------------------
//  PF_StatusTituloAmigavel(cStatusCod) -> cTexto
//  Para titulos SE2 com contexto de prazo
// ------------------------------------------------------------
Function PF_StatusTituloAmigavel(cStatusCod)
    Local cTexto := ""

    Do Case
        Case cStatusCod == "PENDENTE" ; cTexto := "Aguardando pagamento"
        Case cStatusCod == "VENCIDO"  ; cTexto := "Titulo vencido"
        Case cStatusCod == "PAGO"     ; cTexto := "Liquidado"
        Otherwise                     ; cTexto := "Em analise"
    EndCase

Return cTexto


// ============================================================
//  FORMATADORES
// ============================================================

// ------------------------------------------------------------
//  PF_FormatMoeda(nValor) -> "R$ 1.234,56"
// ------------------------------------------------------------
Function PF_FormatMoeda(nValor)
    Local nVal := iif(ValType(nValor) == 'N', nValor, Val(nValor))
Return "R$ " + Transform(nVal, "@E 999,999,999.99")


// ------------------------------------------------------------
//  PF_FormatData(cDataStr) -> "DD/MM/YYYY"
//  Recebe string YYYYMMDD (padrao Protheus)
// ------------------------------------------------------------
Function PF_FormatData(cDataStr)
    Local cD := AllTrim(cDataStr)
    If Empty(cD) .Or. cD == "        " .Or. cD == "00000000"
        Return ""
    EndIf
    // YYYYMMDD -> DD/MM/YYYY
Return SubStr(cD,7,2) + "/" + SubStr(cD,5,2) + "/" + SubStr(cD,1,4)


// ------------------------------------------------------------
//  PF_FormatCNPJ(cCNPJ) -> "12.345.678/0001-99"
// ------------------------------------------------------------
Function PF_FormatCNPJ(cCNPJ)
    Local cC := AllTrim(StrTran(StrTran(StrTran(cCNPJ,".",""),"/",""),"-",""))
    If Len(cC) < 14
        cC := PadL(cC, 14, "0")
    EndIf
Return SubStr(cC,1,2)+"."+SubStr(cC,3,3)+"."+SubStr(cC,6,3)+"/"+SubStr(cC,9,4)+"-"+SubStr(cC,13,2)


// ------------------------------------------------------------
//  PF_FormatCEP(cCEP) -> "01310-100"
// ------------------------------------------------------------
Function PF_FormatCEP(cCEP)
    Local cC := AllTrim(StrTran(cCEP,"-",""))
    If Len(cC) < 8
        Return cCEP
    EndIf
Return SubStr(cC,1,5)+"-"+SubStr(cC,6,3)
