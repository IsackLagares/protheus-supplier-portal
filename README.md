# Portal de Autoatendimento para Fornecedores — Backend ADVPL

Serviço REST em ADVPL para Protheus 12, expondo dados financeiros e de notas fiscais
para o portal de autoatendimento de fornecedores.

---

## Estrutura de arquivos

```
src/
├── rest/
│   ├── PFREST001.prw   ← Definição do serviço (WSRESTFUL) — compile primeiro
│   ├── PFAUTH001.prw   ← POST /login · POST /logout
│   ├── PFNF001.prw     ← GET /notas · GET /notas/{doc}/{serie}
│   ├── PFTIT001.prw    ← GET /titulos · GET /titulos/{num}/{parcela}
│   └── PFFOR001.prw    ← GET /fornecedor
├── business/
│   └── PFBIZ001.prw    ← Token, status amigável, formatadores
└── utils/
    └── PFCONST.ch      ← Constantes (#Define) — inclua em todos os PRW
```

---

## Pré-requisitos

### 1. Campo customizado no SA2

Criar via **Configurações > Dicionário de Dados > SX3** (ou script ADVPL):

| Campo     | Tipo | Tamanho | Descrição                        |
|-----------|------|---------|----------------------------------|
| A2_CHVPF  | C    | 20      | Chave de acesso do portal        |

> Sugestão: gerar a chave com um hash SHA-1 do CNPJ + salt interno.
> Exemplo: `SubStr(SHA1(A2_CGC + "PF2025"), 1, 16)`

### 2. Tabela de controle de tokens (Z01PF)

Criar via **SX2 + SX3**:

| Campo    | Tipo | Tam | Descrição           |
|----------|------|-----|---------------------|
| Z1_FILIAL| C    | 2   | Filial              |
| Z1_TOKEN | C    | 40  | Token UUID          |
| Z1_CODFOR| C    | 6   | Código fornecedor   |
| Z1_LOJA  | C    | 2   | Loja                |
| Z1_EXPIRA| C    | 8   | Data expira YYYYMMDD|
| Z1_HORA  | C    | 8   | Hora criação HH:MM:SS|

**Índice principal:** Z1_FILIAL + Z1_TOKEN (único)

### 3. Configuração do AppServer (appserver.ini)

```ini
[HTTPREST]
Port=8484
URIRoot=/rest
Ssl=1
SslCertificate=certs/server.crt
SslKey=certs/server.key

[ONSTART]
JOBS=HTTPJOB

[HTTPJOB]
MAIN=HTTP_START
Environment=SEU_AMBIENTE
```

---

## Compilação

Ordem de compilação obrigatória:

```
1. PFCONST.ch      (include — não gera .erp)
2. PFBIZ001.prw    (funções utilitárias)
3. PFREST001.prw   (definição do serviço)
4. PFAUTH001.prw
5. PFNF001.prw
6. PFTIT001.prw
7. PFFOR001.prw
```

No **TDS (VS Code ou Eclipse)**: compile todos de uma vez após garantir que o
`PFCONST.ch` está no mesmo diretório dos `.prw` ou no `include path` do projeto.

---

## Endpoints

### Autenticação

#### `POST /rest/portalfornecedor/v1/login`

```json
// Request body
{
  "cnpj": "12345678000199",
  "chave": "XPTO12345678"
}

// Response 200
{
  "token": "550e8400-e29b-41d4-a716-446655440000",
  "fornecedor": "000001",
  "loja": "01",
  "expira": "20260325 23:59:59"
}

// Response 401
{ "erro": "CNPJ ou chave inválidos" }
```

---

#### `POST /rest/portalfornecedor/v1/logout`

```
Header: X-PF-Token: <token>
```

---

### Notas Fiscais

#### `GET /rest/portalfornecedor/v1/notas`

```
Header: X-PF-Token: <token>
Query:  ?status=pendente|pago|todos  (default: todos)
        &dtinicio=20260101
        &dtfim=20260325
        &pagina=1
        &itens=20
```

```json
// Response 200
{
  "dados": [
    {
      "numero": "001847",
      "serie": "1",
      "emissao": "03/03/2026",
      "entrada": "04/03/2026",
      "valor": 18900.00,
      "valorFmt": "R$ 18.900,00",
      "chaveNFe": "35260312345678000199550010018470011234567890",
      "status": "Pagamento Pendente",
      "statusCod": "PENDENTE"
    }
  ],
  "pagina": 1,
  "total": 1
}
```

---

#### `GET /rest/portalfornecedor/v1/notas/{numero}/{serie}`

Retorna header + itens (SD1) da NF.

---

### Títulos Financeiros

#### `GET /rest/portalfornecedor/v1/titulos`

```
Header: X-PF-Token: <token>
Query:  ?status=pendente|vencido|pago|todos
        &dtinicio=20260101
        &dtfim=20260430
```

```json
// Response 200
{
  "dados": [...],
  "totais": {
    "pendente": "R$ 48.200,00",
    "vencido":  "R$ 5.300,00"
  },
  "quantidade": 7
}
```

**Lógica de status (SE2):**

| Condição                              | statusCod | status amigável         |
|---------------------------------------|-----------|-------------------------|
| E2_SALDO = 0                          | PAGO      | "Liquidado"             |
| E2_SALDO > 0 e E2_VENCTO >= hoje      | PENDENTE  | "Aguardando pagamento"  |
| E2_SALDO > 0 e E2_VENCTO < hoje       | VENCIDO   | "Título vencido"        |

---

### Dados do Fornecedor

#### `GET /rest/portalfornecedor/v1/fornecedor`

Retorna campos cadastrais da SA2 com CNPJ e CEP formatados.

---

## Tabelas utilizadas

| Tabela | Uso                              | Campos-chave lidos            |
|--------|----------------------------------|-------------------------------|
| SA2    | Autenticação + dados cadastrais  | A2_COD, A2_CGC, A2_CHVPF     |
| SF1    | NFs de entrada (header)          | F1_DOC, F1_SERIE, F1_VALBRUT |
| SD1    | Itens das NFs                    | D1_DOC, D1_SERIE, D1_TOTAL   |
| SE2    | Contas a pagar / status          | E2_SALDO, E2_VENCTO, E2_NUM  |
| Z01PF  | Tokens de sessão (custom)        | Z1_TOKEN, Z1_EXPIRA           |

---

## Segurança

- Toda rota (exceto `/login`) exige o header `X-PF-Token`
- Token expira em 1 dia (configurável em `PFCONST.ch → PF_TOKEN_EXPIRE`)
- Dados retornados sempre filtrados pelo `cCodFor + cLoja` extraídos do token
  → um fornecedor **nunca** acessa dados de outro
- Protocolo HTTPS obrigatório (configurar certificado no `appserver.ini`)

---

## Próximos passos sugeridos

- [ ] Criar campo `A2_CHVPF` no SX3
- [ ] Criar tabela `Z01PF` (SX2 + SX3)
- [ ] Configurar HTTPREST no appserver.ini
- [ ] Compilar na ordem indicada acima
- [ ] Testar `/login` com Postman/Insomnia
- [ ] Conectar frontend Next.js nos endpoints

---

## Evoluções futuras

- **Upload de XML**: endpoint `POST /notas/xml` com validação SEFAZ antes de
  gravar no Protheus
- **Notificações Push**: job ADVPL que monitora SE2 e dispara Telegram/WhatsApp
  quando `E2_BAIXA` é preenchido
