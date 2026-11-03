# Especificação Técnica — Limites de Desempenho, Volume de Dados e Forma de Medição para Operações Críticas

- **Referência:** Task `[F1.4] #171` (Definir limites de desempenho, volume de dados e forma de medição para operações críticas)
- **Fatia Técnica:** Fundação Arquitetural (`[F1]`) / Requisitos Não Funcionais (`RNF08`)
- **Documentador Oficial:** Marcelo Aparecido da Rosa ([@marcelo-3com](https://github.com/marcelo-3com))
- **Líder Técnico e QA Arquitetural:** Rodolpho P. M. Ferreira
- **Responsável por Testes e Qualidade:** Daniel Lacerda Xavier / Gustavo Minoru Haga
- **Responsável por CI/CD e Observabilidade:** Kelly Daiane Miranda Mendes
- **Versão:** 1.0.0
- **Data:** Novembro de 2026

---

## 1. Objetivo e Contexto

Este documento resolve a pendência arquitetural mapeada no requisito **RNF08 (Desempenho)** do Sistema Currículo, estabelecendo **metas quantitativas e auditáveis** de:
1. **Tempo de Resposta (SLA / SLO de Latência):** Metas de latência percentilar ($p_{95}$ e $p_{99}$) para cada operação crítica.
2. **Capacidade e Volume de Dados:** Limites de carga, cotas de armazenamento por estudante e limites de payload JSON.
3. **Metodologia de Medição e Telemetria:** Protocolo de instrumentação por logs estruturados e procedimentos reprodutíveis de testes de carga.

---

## 2. Catálogo de Operações Críticas e Limites de Desempenho (SLO)

As operações da plataforma foram classificadas em três níveis de criticidade e seus limites foram estabelecidos para garantir fluidez no uso interativo do estudante:

| Operação Crítica | Tipo | Rota / Endpoint | Meta $p_{95}$ | Limite Máximo $p_{99}$ | Timeout de Segurança |
| :--- | :---: | :--- | :---: | :---: | :---: |
| **Autenticação e Sessão** | Leitura/Escrita | `POST /login`, `GET /sessao` | **$\le$ 200 ms** | **$\le$ 500 ms** | 2.0 s |
| **Consulta de Perfil / Currículo** | Leitura | `GET /estudantes/{id}`, `GET /curriculo` | **$\le$ 150 ms** | **$\le$ 400 ms** | 1.5 s |
| **Cadastro / Edição de Dados** | Escrita | `POST` ou `PUT` em formações, experiências e competências | **$\le$ 300 ms** | **$\le$ 700 ms** | 3.0 s |
| **Integração de Vagas (Grupo 2)**| Chamada Externa | `POST /api/v1/vagas/match` | **$\le$ 1.500 ms** | **$\le$ 3.000 ms** | 5.0 s |
| **Renderização de Prévia HTML** | Processamento | `GET /curriculo/previa` | **$\le$ 400 ms** | **$\le$ 800 ms** | 2.5 s |
| **Geração de PDF / DOCX** | Processamento I/O| `POST /curriculo/exportar` | **$\le$ 2.500 ms** | **$\le$ 4.500 ms** | 8.0 s |

> **Nota sobre Falha Degradada (Grupo 2):** Se a chamada externa ao CV Matcher do Grupo 2 ultrapassar **5,0 segundos (timeout)**, o sistema deve interromper a espera, registrar log de alerta e responder ao estudante com as últimas vagas em cache local ou mensagem explicativa amigável, sem travar o restante da aplicação.

---

## 3. Limites de Volume de Dados e Cotas por Estudante

Para impedir degradação de desempenho do banco de dados relacional e ataques de negação de serviço (DoS) por sobrecarga de memória, ficam estabelecidas as seguintes cotas:

### 3.1. Cotas Estruturais por Currículo

| Seção do Perfil | Quantidade Máxima Permitida | Justificativa de Engenharia |
| :--- | :---: | :--- |
| **Formações Acadêmicas** | Até 10 registros | Cobre ensino técnico, graduação, pós-graduação e cursos superiores. |
| **Experiências Profissionais** | Até 15 registros | Suficiente para toda a trajetória profissional relevante do estudante. |
| **Competências Técnicas** | Até 30 competências | Evita dispersão semântica no algoritmo de matching. |
| **Projetos Acadêmicos** | Até 10 projetos | Limita o volume de texto no gerador de PDF. |
| **Idiomas** | Até 8 idiomas | Cobre a totalidade de idiomas conhecidos. |
| **Cursos e Certificações** | Até 20 registros | Volume adequado para cursos extracurriculares. |
| **Links Profissionais** | Até 5 links | GitHub, LinkedIn, Lattes, Portfólio e Site pessoal. |

### 3.2. Limites de Tamanho de Payloads e Arquivos

* **Payloads de Requisição JSON (API REST):** Limite máximo de **256 KB** por corpo de requisição HTTP. Requisições maiores são rejeitadas pelo middleware com `HTTP 413 Payload Too Large`.
* **Upload de Documentos Complementares (Certificados / Diplomas):**
  * Limite máximo por arquivo: **5 MB** (`5.242.880 bytes`).
  * Formatos aceitos: `PDF`, `PNG`, `JPEG`.
* **Tamanho Máximo do PDF/DOCX Gerado:** O documento final exportado não deve exceder **2 MB**.

---

## 4. Capacidade e Carga Simultânea Alvo

O dimensionamento da infraestrutura conteinerizada com Docker baseia-se no público-alvo acadêmico da FATEC-SP:

* **Usuários Ativos Simultâneos (*Concurrency*):** Suporte estável a **100 usuários simultâneos** em navegação e preenchimento concorrente sem degradação de latência ($p_{95} \le 500\text{ ms}$).
* **Throughput Nominal da API:** Capacidade de processamento de pelo menos **50 requisições por segundo (RPS)** no nó de backend local.
* **Pool de Conexões de Banco de Dados (PostgreSQL):** Mínimo de 5 e máximo de 20 conexões assíncronas no pool do SQLAlchemy (`pool_size=10`, `max_overflow=10`, `pool_timeout=30s`).

---

## 5. Forma de Medição e Telemetria

A aderência aos limites não deve ser teórica, mas verificável através de métricas automatizadas:

### 5.1. Instrumentação por Middleware ASGI
O backend deve incorporar logging estruturado em formato JSON para todas as requisições HTTP, contendo os campos obrigatórios de telemetria:

```json
{
  "timestamp": "2026-11-02T22:30:00.123Z",
  "trace_id": "req-9a8b7c6d5e4f",
  "metodo": "POST",
  "rota": "/formacoes-academicas",
  "status_code": 201,
  "tempo_execucao_ms": 42.8,
  "tamanho_resposta_bytes": 312,
  "usuario_id": "usr_123456"
}
```

### 5.2. Procedimento de Teste de Carga e Medição
Para homologação dos limites pelas equipes de Testes (Daniel e Gustavo):
1. **Ferramenta Recomendada:** [k6](https://k6.io/) ou [Locust](https://locust.io/) via script Python.
2. **Cenário de Teste Padrão:**
   * Rampa de subida de 0 a 100 usuários virtuais (VUs) em 60 segundos.
   * Manutenção de carga contínua por 5 minutos exercitando leitura (`GET /curriculo`), escrita (`POST /competencias`) e busca de vagas (`POST /api/v1/vagas/match`).
3. **Critério de Aceite da Homologação:**
   * Taxa de sucesso de requisições: $\ge 99,5\%$ (HTTP 2xx).
   * Percentil $p_{95}$ geral do sistema abaixo do teto de cada operação crítica definido na tabela da Seção 2.

---

## 6. Rastreabilidade com o Projeto

* **Card #171 (`[F1.4]`):** Entrega formal da definição quantitativa de desempenho, volume e métricas de observabilidade.
* **Requisito Não Funcional RNF08:** Resolve integralmente as metas e condições de verificação pendentes no documento de requisitos de arquitetura.
* **Equipe de QA e Testes:** Fornece as métricas numéricas necessárias para a elaboração da suíte de testes de estresse e regressão de desempenho.
