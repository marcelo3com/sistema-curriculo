# Contrato de Credenciais e Ciclo de Sessão

- **Referência:** Task `[F12.2] #418` (Documentar o contrato de credenciais e o ciclo de sessão depois da conclusão dos cards #80–#82)
- **Fatias Técnicas Relacionadas:** Cards `#80` (Armazenamento de Sessões), `#81` (Middleware de Autenticação) e `#82` (Endpoints de Sessão)
- **Documentador Oficial:** Marcelo Aparecido da Rosa ([@marcelo-3com](https://github.com/marcelo-3com))
- **Líder Técnico e QA Arquitetural:** Rodolpho P. M. Ferreira
- **Responsável por CI/CD e Middleware de Segurança:** Kelly Daiane Miranda Mendes
- **Versão:** 1.1.0
- **Data:** Novembro de 2026

---

## 1. Objetivo e Escopo

Este documento define formalmente como o **Sistema Currículo (Grupo 1)** emite, transporta, valida, renova e revoga as credenciais que representam uma sessão autenticada de estudante. Ele consolida as implementações realizadas nos cards **#80, #81 e #82**, complementando o planejamento de autenticação e a segurança de rotas protegidas da plataforma.

O contrato cobre exclusivamente as sessões de usuários da aplicação web. Integrações entre sistemas (como a comunicação com o Grupo 2) utilizam contratos de serviços específicos.

---

## 2. Diagrama do Ciclo de Vida da Sessão (Mermaid)

O ciclo de vida da sessão — desde o login, validação em cada requisição protegida via middleware até a revogação no logout — é detalhado no diagrama abaixo:

```mermaid
sequenceDiagram
    autonumber
    actor Aluno as Estudante
    participant UI as Frontend Web
    participant MW as MiddlewareAutenticacaoSessao
    participant API as Endpoints / Controllers
    participant DB as Banco de Dados (Tabela sessao)

    %% 1. Criação de Sessão
    Note over Aluno,DB: 1. Criação de Sessão (Login - Card #82)
    Aluno->>UI: Informa email e senha
    UI->>API: POST /acessos (JSON: email, senha)
    API->>DB: Valida hash de senha do estudante
    alt Credenciais Válidas
        API->>API: Gera token opaco (32 bytes cryptosafe)
        API->>DB: Salva SHA-256(token), usuario_id, expira_em (+8h)
        API-->>UI: HTTP 204 No Content + Set-Cookie (__Host-sessao; HttpOnly; Secure; SameSite=Lax)
        UI-->>Aluno: Acesso liberado ao painel
    else Credenciais Inválidas
        API-->>UI: HTTP 401 Unauthorized (Mensagem uniforme)
        UI-->>Aluno: Exibe erro de autenticação
    end

    %% 2. Validação Contínua
    Note over Aluno,DB: 2. Requisição em Rota Privada (Middleware - Card #81)
    Aluno->>UI: Acessa rota privada (ex: GET /curriculo)
    UI->>MW: Requisição HTTP com Cookie: __Host-sessao
    MW->>MW: Calcula SHA-256 do token recebido
    MW->>DB: Busca registro onde token_hash = SHA-256 e revogada_em IS NULL
    alt Sessão Válida e Ativa
        MW->>MW: Injeta request.state.usuario_id e X-Correlation-ID
        MW->>API: Prossegue execução do caso de uso
        API-->>UI: HTTP 200 OK com dados do estudante
    else Sessão Expirada ou Inexistente
        MW-->>UI: HTTP 401 Unauthorized ("Sessão ausente ou inválida.")
        UI-->>Aluno: Redireciona para tela de login
    end

    %% 3. Encerramento
    Note over Aluno,DB: 3. Encerramento de Sessão (Logout - Card #82)
    Aluno->>UI: Clica em "Sair da Conta"
    UI->>API: DELETE /sessao/atual
    API->>DB: Atualiza revogada_em = NOW()
    API-->>UI: HTTP 204 No Content + Set-Cookie (__Host-sessao=deleted; Max-Age=0)
    UI-->>Aluno: Sessão encerrada com segurança
```

---

## 3. Decisões Arquiteturais Fundamentais

1. **Sessão Opaca e no Servidor:**  
   A sessão **não é um JWT** legível pelo cliente. É um identificador opaco aleatório de alta entropia. Nenhum dado do estudante (`usuario_id`, papéis, permissões) trafega dentro do token.
2. **Transporte Estritamente por Cookie:**  
   A credencial trafega exclusivamente via cookie HTTP. A API **não aceita** tokens de sessão em cabeçalhos `Authorization`, parâmetros de URL (*query string*) ou corpos de requisição.
3. **Tempo de Vida Fixo (TTL de 8 Horas):**  
   A sessão expira em exatamente **8 horas** a partir da criação (`criada_em + 8 horas`). Não há renovação deslizante automática por inatividade, forçando reautenticação periódica segura.
4. **Múltiplas Sessões Permitidas:**  
   O estudante pode estar logado simultaneamente no computador e no celular. O logout revoga apenas a sessão do dispositivo que enviou a requisição.

---

## 4. Estrutura de Persistência e Armazenamento (Card #80)

A persistência do banco de dados relacional **nunca armazena o token em texto claro**. Apenas o resumo criptográfico **SHA-256** com índice único é salvo:

| Campo | Tipo | Restrição | Descrição |
| :--- | :--- | :--- | :--- |
| `sessao_id` | UUID | Chave Primária | Identificador interno do registro. |
| `usuario_id` | UUID | Chave Estrangeira | ID do estudante proprietário da sessão. |
| `token_hash` | String(64) | Único, Not Null | Hash SHA-256 do token recebido via cookie. |
| `criada_em` | Timestamp UTC | Not Null | Data e hora exata de emissão. |
| `expira_em` | Timestamp UTC | Not Null | Data e hora de expiração (`criada_em + 8 horas`). |
| `revogada_em` | Timestamp UTC | Nullable | Data/hora em que o usuário fez logout (nulo se ativa). |

---

## 5. Diretivas do Cookie HTTP de Produção

Em conformidade com as recomendações da OWASP e o padrão do navegador:

```http
Set-Cookie: __Host-sessao=<token-opaco-32bytes>; Path=/; Max-Age=28800; Secure; HttpOnly; SameSite=Lax
```

* **`__Host-` Prefix:** Impede sobrescrita por subdomínios e exige envio exclusivo por HTTPS e caminho raiz (`Path=/`).
* **`HttpOnly`:** Bloqueia qualquer leitura do cookie via JavaScript (`document.cookie`), prevenindo ataques de roubo de sessão via Cross-Site Scripting (XSS).
* **`Secure`:** Garante que o cookie só trafegue em conexões criptografadas por TLS/HTTPS.
* **`SameSite=Lax`:** Protege contra ataques de Cross-Site Request Forgery (CSRF) em navegação comum.

---

## 6. Especificação dos Endpoints de Sessão (Card #82)

Implementação: [`src/backend/api/cadastro_acesso.py`](file:///c:/Users/marce/Documents/GitHub/sistema-curriculo/src/backend/api/cadastro_acesso.py) e [`src/backend/api/sessoes.py`](file:///c:/Users/marce/Documents/GitHub/sistema-curriculo/src/backend/api/sessoes.py)

### 6.1. `POST /acessos` — Criar Sessão (Login)
* **Status Público:** Rota pública (não exige sessão prévia).
* **Payload de Envio:**
  ```json
  {
    "email": "estudante@fatec.sp.gov.br",
    "senha": "senha-segura-informada"
  }
  ```
* **Respostas:**
  * `HTTP 204 No Content` + `Set-Cookie` com o token em caso de sucesso.
  * `HTTP 401 Unauthorized` uniforme (para e-mail inexistente ou senha incorreta, sem detalhar qual falhou para evitar enumeração de contas).
  * `HTTP 422 Unprocessable Entity` para formato de e-mail inválido.

### 6.2. `GET /sessao/atual` — Consultar Sessão Ativa
* **Respostas:**
  * `HTTP 200 OK`: `{"usuario_id": "c1f2e3d4-5678-90ab-cdef-1234567890ab"}`
  * `HTTP 401 Unauthorized`: Caso o cookie esteja ausente, expirado ou revogado.

### 6.3. `DELETE /sessao/atual` — Encerrar Sessão (Logout)
* **Comportamento:** Marca `revogada_em = NOW()` no banco de dados e retorna `Set-Cookie` com `Max-Age=0` para remoção do cookie no navegador.
* **Idempotência:** Responde `HTTP 204 No Content` mesmo que a sessão já tenha expirado.

---

## 7. Funcionamento do Middleware em Rotas Privadas (Card #81)

Implementação: [`src/backend/api/middleware_autenticacao.py`](file:///c:/Users/marce/Documents/GitHub/sistema-curriculo/src/backend/api/middleware_autenticacao.py)

1. **Lista Branca de Rotas Públicas (`ROTAS_PUBLICAS`):**
   * Acesso liberado sem checagem de cookie para: `POST /estudantes`, `POST /acessos`, `DELETE /sessao/atual`, `/health`, `/ready`, `/docs` e `/openapi.json`.
2. **Intercepção de Rotas Privadas:**
   * O middleware intercepta toda requisição privada, extrai o cookie `__Host-sessao`, calcula o SHA-256 e valida o registro no banco.
   * Se a sessão estiver ativa, injeta `request.state.usuario_id` e atribui um código de rastreamento em `request.state.correlation_id` (devolvido no cabeçalho `X-Correlation-ID`).
   * Se for inválida, responde imediatamente com `HTTP 401 Unauthorized` e mensagem `"Sessão ausente ou inválida."` sem acionar o banco de dados desnecessariamente.

---

## 8. Rastreabilidade com as Fatias do Projeto

* **Card #418 (`[F12.2]`):** Documentação consolidada do contrato de credenciais e ciclo de sessão entregue e alinhada à arquitetura do sistema.
* **Cards #80, #81 e #82:** Rastreabilidade direta com os componentes de armazenamento de sessão, middleware de segurança e endpoints REST desenvolvidos pela Kelly Mendes.
