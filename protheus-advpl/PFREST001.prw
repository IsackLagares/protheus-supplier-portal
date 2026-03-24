// ============================================================
//  PFREST001.PRW
//  Portal Fornecedor - Definição do Serviço REST
//  Protheus 12 | WSRESTFUL
//
//  Registra todos os endpoints do portal.
//  Compile este arquivo + todos os PRW do projeto.
// ============================================================

#Include 'TOTVS.ch'
#Include 'RESTFUL.ch'

// ------------------------------------------------------------
//  Serviço principal
//  URL base: /rest/portalfornecedor/v1
// ------------------------------------------------------------
WSRESTFUL portalFornecedor DESCRIPTION "Portal de Autoatendimento - Fornecedores" ;
    FORMAT JSON

    // -- Autenticação
    WSMETHOD POST login     DESCRIPTION "Autentica fornecedor via CNPJ + chave"        WSSYNTAX "/login"
    WSMETHOD POST logout    DESCRIPTION "Invalida token de sessão"                      WSSYNTAX "/logout"

    // -- Notas Fiscais
    WSMETHOD GET  notasFiscais   DESCRIPTION "Lista NFs do fornecedor autenticado"      WSSYNTAX "/notas"
    WSMETHOD GET  notaDetalhe    DESCRIPTION "Detalhe de uma NF específica"             WSSYNTAX "/notas/{nNota}/{sSerie}"

    // -- Financeiro / Títulos (SE2)
    WSMETHOD GET  titulos        DESCRIPTION "Lista títulos a pagar do fornecedor"      WSSYNTAX "/titulos"
    WSMETHOD GET  tituloDetalhe  DESCRIPTION "Detalhe de um título"                     WSSYNTAX "/titulos/{sTitulo}/{sParcela}"

    // -- Dados Cadastrais
    WSMETHOD GET  dadosFornecedor DESCRIPTION "Retorna dados cadastrais (SA2)"          WSSYNTAX "/fornecedor"

END WSRESTFUL
