# Especificação de Contratos — Perfil, Formação Acadêmica e Experiência Profissional

- **Referência:** Task `[F12.5] #423` (Documentar contratos de perfil, formação e experiência após a conclusão das rotas correspondentes)
- **Documentador Oficial:** Marcelo Aparecido da Rosa ([@marcelo-3com](https://github.com/marcelo-3com))
- **Líder Técnico e QA Arquitetural:** Rodolpho P. M. Ferreira
- **Desenvolvedor Responsável pelo Módulo:** Matheus Gnann Cardoso
- **Front End / Consumidores da API:** Ricardo Galdino de Sampaio / Nathan Campos Nagano
- **Versão:** 1.0.0
- **Data:** Novembro de 2026

---

## 1. Visão Geral

Este documento formaliza os contratos HTTP das rotas fundamentais do **Sistema Currículo (Grupo 1)** referentes a:
1. **Perfil e Dados Pessoais do Estudante**
2. **Formação Acadêmica**
3. **Experiência Profissional**

Todas as rotas detalhadas neste documento encontram-se implementadas na camada de interface (`src/backend/api/`), validadas pelo domínio e integradas à fábrica ASGI FastAPI.

---

## 2. Autenticação e Segurança nas Rotas

* **Mecanismo de Segurança:** As rotas são protegidas por middleware de sessão (`MiddlewareAutenticacaoSessao`).
* **Credencial:** Cookie de sessão seguro HTTP-Only (`session_id`) ou cabeçalho de autorização.
* **Isolamento de Dados (*Multi-tenancy* Seguro):** O identificador do proprietário (`usuario_id`) é extraído diretamente do estado da sessão autenticada (`request.state.usuario_id`). Um estudante **não pode** consultar, alterar ou excluir dados pertencentes a outro estudante (retorno `403 Forbidden`).

---

## 3. Contratos de Perfil e Dados Pessoais

Implementação: [`src/backend/api/perfil_estudante.py`](file:///c:/Users/marce/Documents/GitHub/sistema-curriculo/src/backend/api/perfil_estudante.py)

### 3.1. `GET /estudantes/{usuario_id}` — Consulta de Perfil

Retorna as informações cadastrais e de contato do estudante autenticado.

#### Regra de Autorização
O `usuario_id` informado na rota deve ser idêntico ao `principal_id` autenticado na sessão. Caso contrário, a API rejeita com `403 Forbidden`.

#### Resposta de Sucesso (HTTP 200 OK)
```json
{
  "nome": "Marcelo Aparecido da Rosa",
  "email": "marcelo@fatec.sp.gov.br",
  "telefones": ["11988887777"],
  "cidade": "São Paulo",
  "linkedin": "https://linkedin.com/in/marcelo-fatec",
  "curriculo_lattes": "http://lattes.cnpq.br/1234567890123456"
}
```

---

### 3.2. `PUT /estudantes/{usuario_id}` — Edição de Perfil

Permite a atualização dos dados pessoais e de contato do estudante.

#### Payload de Envio (Request Body)
```json
{
  "nome": "Marcelo Aparecido da Rosa",
  "endereco": "Av. Tiradentes, 615 - Bom Retiro",
  "cidade": "São Paulo",
  "telefones": ["11988887777"],
  "linkedin": "https://linkedin.com/in/marcelo-fatec",
  "curriculo_lattes": "http://lattes.cnpq.br/1234567890123456"
}
```

| Campo | Tipo | Obrigatório? | Regras e Restrições |
| :--- | :--- | :--- | :--- |
| `nome` | String | **SIM** | Min: 2, Max: 120 caracteres. Sem caracteres de controle. |
| `endereco` | String | NÃO | Max: 200 caracteres. Pode ser nulo ou omitido. |
| `cidade` | String | NÃO | Max: 60 caracteres. Pode ser nulo. |
| `telefones` | Array[String] | **SIM** | Lista de números telefônicos válidos (mínimo 10 dígitos). |
| `linkedin` | String | NÃO | URL válida com esquema `http://` ou `https://`. |
| `curriculo_lattes`| String | NÃO | URL válida da plataforma Lattes. |

#### Resposta de Sucesso: `HTTP 200 OK` (retorna o perfil atualizado) ou `HTTP 204 No Content`.

---

### 3.3. `DELETE /estudantes/atual` — Exclusão de Perfil

Exclui permanentemente a conta e o perfil do estudante autenticado, invalidando a sessão.

* **Status de Sucesso:** `HTTP 204 No Content`.
* **Segurança:** O cookie de sessão é removido/expirado na resposta (`Max-Age=0`).

---

## 4. Contratos de Formação Acadêmica

Implementação: [`src/backend/api/formacao_academica.py`](file:///c:/Users/marce/Documents/GitHub/sistema-curriculo/src/backend/api/formacao_academica.py)

### 4.1. Enums de Domínio Utilizados

#### Nível de Formação (`nivel`):
* `"ensino_fundamental"`
* `"ensino_medio"`
* `"tecnico"`
* `"tecnologo"`
* `"graduacao"`
* `"especializacao"`
* `"mestrado"`
* `"doutorado"`

#### Status da Formação (`status`):
* `"em_andamento"`: `data_fim` representa a **previsão de conclusão**.
* `"concluido"`: `data_fim` é a **data efetiva de término** (obrigatória).
* `"interrompido"`: `data_fim` é a data de trancamento/interrupção.

---

### 4.2. `POST /formacoes-academicas` — Cadastro de Formação

Cadastra um novo curso ou grau acadêmico para o estudante da sessão.

#### Payload de Envio (Request Body)
```json
{
  "instituicao": "FATEC São Paulo",
  "curso": "Análise e Desenvolvimento de Sistemas",
  "nivel": "tecnologo",
  "data_inicio": "2024-02-01",
  "data_fim": "2026-12-15",
  "status": "em_andamento"
}
```

| Campo | Tipo | Obrigatório? | Regras e Validações |
| :--- | :--- | :--- | :--- |
| `instituicao` | String | **SIM** | Min: 2, Max: 100 chars. Espaços extras removidos. |
| `curso` | String | **SIM** | Min: 2, Max: 100 chars. Sem caracteres de controle. |
| `nivel` | String (Enum)| **SIM** | Deve corresponder a um dos valores canônicos. |
| `data_inicio` | Date (ISO) | **SIM** | Formato `YYYY-MM-DD`. |
| `data_fim` | Date (ISO) | NÃO | Obrigatório se `status="concluido"`. Deve ser posterior a `data_inicio`. |
| `status` | String (Enum)| **SIM** | `em_andamento`, `concluido` ou `interrompido`. |

#### Resposta de Sucesso (HTTP 201 Created)
```json
{
  "id": "b3e21894-39f1-4db8-b5b4-d5e683419bb1",
  "instituicao": "FATEC São Paulo",
  "curso": "Análise e Desenvolvimento de Sistemas",
  "nivel": "tecnologo",
  "data_inicio": "2024-02-01",
  "data_fim": "2026-12-15",
  "status": "em_andamento"
}
```

---

### 4.3. `PUT /formacoes-academicas/{id}` — Edição de Formação
* **Parâmetro de URL:** `id` (UUID da formação).
* **Payload:** Idêntico ao payload de criação.
* **Retorno:** `HTTP 200 OK` com os dados atualizados.

---

### 4.4. `DELETE /formacoes-academicas/{id}` — Exclusão de Formação
* **Parâmetro de URL:** `id` (UUID da formação).
* **Retorno:** `HTTP 204 No Content`.

---

## 5. Contratos de Experiência Profissional

Implementação: [`src/backend/api/experiencia_profissional.py`](file:///c:/Users/marce/Documents/GitHub/sistema-curriculo/src/backend/api/experiencia_profissional.py)

### 5.1. `POST /experiencias-profissionais` — Cadastro de Experiência

Cadastra uma passagem profissional, estágio ou atuação voluntária.

#### Payload de Envio (Request Body)
```json
{
  "empresa": "Tech Solutions Brasil",
  "cargo": "Estagiário de Desenvolvimento Backend",
  "descricao": "Atuação no desenvolvimento de microsserviços Python/FastAPI e manutenção de banco PostgreSQL.",
  "data_inicio": "2025-01-10",
  "data_fim": null
}
```

| Campo | Tipo | Obrigatório? | Regras e Validações |
| :--- | :--- | :--- | :--- |
| `empresa` | String | **SIM** | Min: 2, Max: 100 caracteres. |
| `cargo` | String | **SIM** | Min: 2, Max: 100 caracteres. |
| `descricao` | String | **SIM** | Resumo das atividades desempenhadas (Max: 2000 chars). |
| `data_inicio` | Date (ISO) | **SIM** | Data de admissão/início (`YYYY-MM-DD`). |
| `data_fim` | Date (ISO) | NÃO | Enviar `null` para emprego/estágio atual em andamento. |

#### Resposta de Sucesso (HTTP 201 Created)
```json
{
  "id": "7f8b91c2-3e4a-4a6f-9988-123456abcdef",
  "empresa": "Tech Solutions Brasil",
  "cargo": "Estagiário de Desenvolvimento Backend",
  "descricao": "Atuação no desenvolvimento de microsserviços Python/FastAPI e manutenção de banco PostgreSQL.",
  "data_inicio": "2025-01-10",
  "data_fim": null
}
```

---

### 5.2. `PUT /experiencias-profissionais/{id}` — Edição de Experiência
* **Regra Importante:** O campo `data_fim` é explícito. Enviar `null` preserva ou altera a experiência para "em andamento". Enviar uma data define o término.
* **Retorno:** `HTTP 200 OK` com os dados atualizados.

---

### 5.3. `DELETE /experiencias-profissionais/{id}` — Exclusão de Experiência
* **Retorno:** `HTTP 204 No Content`.

---

## 6. Catálogo Unificado de Respostas e Falhas HTTP

| Código HTTP | Significado | Causa Comum |
| :--- | :--- | :--- |
| **`200 OK`** | Sucesso | Consulta ou atualização bem-sucedida. |
| **`201 Created`** | Criado | Recurso de formação ou experiência cadastrado com novo ID. |
| **`204 No Content`** | Sem conteúdo | Exclusão executada com sucesso. |
| **`400 Bad Request`** | Erro de formato | JSON sintaticamente malformado ou campos com tipos incorretos. |
| **`401 Unauthorized`**| Não autenticado | Ausência de cookie de sessão válido. |
| **`403 Forbidden`** | Acesso negado | Tentativa de manipular registro pertencente a outro estudante. |
| **`404 Not Found`** | Não encontrado | ID de formação ou experiência inexistente no banco. |
| **`422 Unprocessable`**| Regra violada | Violação de cronologia (`data_fim < data_inicio`) ou enum inválido. |
| **`503 Unavailable`** | Indisponível | Falha de conexão com a persistência de dados. |

---

## 7. Rastreabilidade com as Fatias do Projeto

* **Card #423 (`[F12.5]`):** Documentação oficial dos contratos de perfil, formação e experiência entregue com base nas rotas ASGI reais.
* **Card #31 e #32:** Compatibilidade com as interfaces originais de cadastro de formação e experiência.
* **Frontend:** Fornece as definições de DTOs e limites de campos para o formulário de cadastro dos estudantes.
