# Especificação Técnica — Validação de Tipo e Tamanho de Documentos Antes do Armazenamento

- **Referência:** Task `[F4.13] #203` (Validar tipo e tamanho do documento antes de encaminhá-lo ao armazenamento)
- **Fatia Técnica:** Armazenamento de Documentos Complementares (`[F4]`) / Segurança e Integridade
- **Documentador Oficial:** Marcelo Aparecido da Rosa ([@marcelo-3com](https://github.com/marcelo-3com))
- **Líder Técnico e QA Arquitetural:** Rodolpho P. M. Ferreira
- **Desenvolvedora Responsável pelo Módulo:** Maria Carolina Cardozo Yamamoto
- **Versão:** 1.0.0
- **Data:** Novembro de 2026

---

## 1. Objetivo

Este documento formaliza as regras de segurança, os critérios de validação estrita e o mecanismo de barreira (*pre-storage validation gate*) para o upload e armazenamento de documentos complementares (certificados, diplomas, comprovantes e portfólios) dos estudantes no **Sistema Currículo (Grupo 1)**.

A regra primordial é a **validação antecipada**: nenhum arquivo binário pode ser encaminhado ao serviço de armazenamento físico (storage em nuvem ou disco local) ou persistido no banco de dados antes que seu tipo MIME, tamanho em bytes, integridade do Base64 e nomenclatura sejam rigorosamente validados.

---

## 2. Princípio da Validação Antecipada (*Pre-Storage Gate*)

Para evitar sobrecarga de storage, custos desnecessários de I/O e ataques de negação de serviço (DoS) ou upload malicioso (como injeção de executáveis ou Path Traversal), a arquitetura adota a seguinte esteira em camadas:

```
[ Cliente HTTP ]
       │  (JSON com Base64)
       ▼
1. Camada de API (FastAPI)
       │  Valida autenticação da sessão (request.state.usuario_id)
       ▼
2. Camada de Aplicação (Caso de Uso: ArmazenarDocumento)
       │  a) Validação sintática do Base64
       │  b) Decodificação segura em memória
       │  c) Verificação do limite máximo de bytes (<= 10 MB)
       ▼
3. Camada de Domínio (Entidade: Documento)
       │  d) Validação do tipo MIME permitido (PDF, PNG, JPEG)
       │  e) Sanitização contra Path Traversal ('..', '/', '\')
       ▼
4. [ APROVADO ] ──► Encaminha ao Armazenador (Storage) e Salva Metadados
       │
   [ REPROVADO ] ──► Rejeita imediatamente com HTTP 422 (Sem tocar no Storage)
```

---

## 3. Regras de Validação de Tipo (*MIME Type Whitelist*)

Apenas tipos estritamente documentados e seguros são aceitos. Arquivos com extensões executáveis (`.exe`, `.sh`, `.bat`, `.js`) ou arquivos compactados (`.zip`, `.rar`) são bloqueados.

| Formato Permitido | Tipo MIME Homologado | Finalidade Comum |
| :--- | :--- | :--- |
| **PDF** | `application/pdf` | Diplomas, certificados e histórico escolar oficial. |
| **PNG** | `image/png` | Imagens de certificados e crachás com transparência/alta resolução. |
| **JPEG / JPG** | `image/jpeg` | Fotos de certificados e declarações digitalizadas. |

* **Constante de Domínio:** `TIPOS_ARQUIVO_PERMITIDOS = frozenset({"application/pdf", "image/png", "image/jpeg"})`.
* **Tratamento:** O tipo informado é normalizado para minúsculas aparadas (`tipo.strip().lower()`).
* **Comportamento em Violação:** Lança `RegraDeDominioViolada("Tipo de arquivo não permitido: '{tipo}'. Tipos aceitos: PDF, PNG, JPEG.")` convertida em `HTTP 422 Unprocessable Entity`.

---

## 4. Regras de Validação de Tamanho (*Size Gate*)

* **Tamanho Máximo Permitido:** **10 MB** (`10.485.760 bytes` — constante `TAMANHO_MAXIMO_DOCUMENTO_BYTES`).
* **Tamanho Mínimo Permitido:** Maior que 0 bytes (arquivos vazios ou strings em branco são rejeitados).
* **Mecanismo de Verificação:**
  1. O payload JSON transporta o conteúdo codificado em Base64 (`conteudo_base64`).
  2. A aplicação decodifica o Base64 com validação estrita (`base64.b64decode(validate=True)`).
  3. O tamanho real decodificado em memória (`len(conteudo_bytes)`) é checado contra `TAMANHO_MAXIMO_DOCUMENTO_BYTES`.
  4. Se `len(conteudo_bytes) > 10 MB`, o caso de uso aborta a operação antes de invocar o `armazenador.armazenar()`.

---

## 5. Regras de Sanitização de Nome de Arquivo (Prevenção a Path Traversal)

Para impedir vulnerabilidades de substituição de arquivos no servidor ou gravação fora do diretório autorizado:

* **Tamanho do Nome:** Mínimo de 1 e máximo de 255 caracteres (`TAMANHO_MINIMO_NOME_ARQUIVO` e `TAMANHO_MAXIMO_NOME_ARQUIVO`).
* **Bloqueio de Path Traversal:** O nome é rejeitado se contiver:
  * Referências relativas: `..`
  * Barras de diretório: `/` ou `\`
* **Bloqueio de Caracteres de Controle:** Rejeita caracteres invisíveis ou de controle (`category(c) == "Cc"`).

---

## 6. Contrato do Endpoint de Upload

Implementação: [`src/backend/api/documento.py`](file:///c:/Users/marce/Documents/GitHub/sistema-curriculo/src/backend/api/documento.py)

### `POST /documentos`

Cadastra e armazena um novo documento complementar para o estudante autenticado.

#### Payload de Requisição (Request Body)
```json
{
  "nome_arquivo": "certificado_curso_java_spring.pdf",
  "tipo_arquivo": "application/pdf",
  "conteudo_base64": "JVBERi0xLjQKJcTl8uXr...[Base64 do arquivo]..."
}
```

#### Resposta de Sucesso (HTTP 201 Created)
```json
{
  "id": "e9a1b2c3-4d5e-6f70-8192-a1b2c3d4e5f6",
  "usuario_id": "c1f2e3d4-5678-90ab-cdef-1234567890ab",
  "nome_arquivo": "certificado_curso_java_spring.pdf",
  "tipo_arquivo": "application/pdf",
  "url_armazenamento": "http://localhost:3000/storage/documentos/e9a1b2c3-4d5e.pdf"
}
```

#### Catálogo de Erros de Validação
| Código HTTP | Causa | Mensagem Retornada |
| :---: | :--- | :--- |
| **`401`** | Usuário não autenticado | `"Sessão ausente ou inválida."` |
| **`422`** | Tipo MIME não permitido | `"Tipo de arquivo não permitido: 'application/zip'. Tipos aceitos: PDF, PNG, JPEG."` |
| **`422`** | Arquivo excede 10 MB | `"O tamanho do arquivo excede o limite máximo permitido de 10 MB."` |
| **`422`** | Conteúdo vazio ou Base64 inválido | `"O conteúdo do documento deve ser uma string Base64 válida."` |
| **`422`** | Tentativa de Path Traversal | `"O nome do arquivo não pode conter barras ou referências relativas de diretório."` |

---

## 7. Rastreabilidade com o Projeto

* **Card #203 (`[F4.13]`):** Cumpre integralmente o requisito de validação rigorosa de tipo e tamanho antes de acionar a camada de persistência física.
* **Componentes Validados:** [`src/backend/domain/itens_perfil.py`](file:///c:/Users/marce/Documents/GitHub/sistema-curriculo/src/backend/domain/itens_perfil.py), [`src/backend/application/cadastro_documento.py`](file:///c:/Users/marce/Documents/GitHub/sistema-curriculo/src/backend/application/cadastro_documento.py) e [`src/backend/api/documento.py`](file:///c:/Users/marce/Documents/GitHub/sistema-curriculo/src/backend/api/documento.py).
* **Equipe de Testes:** Fornece os casos de teste para injeção de arquivos maliciosos, estouro de cota e validação de MIME types.
