# Guia Prático de Execução, Uso e Testes da API

- **Projeto:** `sistema-curriculo` (Plataforma de Apoio Profissional — FATEC-SP)
- **Documentador Oficial:** Marcelo Aparecido da Rosa ([@marcelo-3com](https://github.com/marcelo-3com))
- **Líder Técnico:** Rodolpho P. M. Ferreira
- **Versão:** 1.0.0
- **Data:** Novembro de 2026

---

## 1. Visão Geral

Este guia ensina, de forma prática e passo a passo, como inicializar a plataforma, acessar a documentação interativa visual (**Swagger UI**) e realizar o teste completo de ponta a ponta da jornada do estudante na API.

---

## 2. Como Inicializar o Sistema

### Método Recomendado: Docker Compose (1 comando)

Se você possui o Docker instalado (Windows, Linux, macOS ou WSL2):

1. Abra o terminal na pasta raiz do projeto (`sistema-curriculo`).
2. Execute o comando de inicialização:
   ```bash
   docker compose up -d --build
   ```
3. O Docker fará o download da imagem do PostgreSQL, instalará as dependências da API e colocará o banco e o servidor no ar.
4. Para acompanhar os logs em tempo real:
   ```bash
   docker compose logs -f app
   ```

---

### Método Alternativo: Execução Direta com Python Local

Caso prefira rodar diretamente no Python do Windows ou WSL (sem Docker):

1. Na raiz do projeto, instale as dependências:
   ```bash
   pip install -r requirements.txt
   ```
2. Inicie o servidor FastAPI na porta 3000:
   ```bash
   uvicorn backend.main:app --host 0.0.0.0 --port 3000 --reload
   ```

---

## 3. Acessando a Interface Visual de Testes (Swagger UI)

Assim que a aplicação estiver em execução, abra o seu navegador de internet e acesse:

👉 **`http://localhost:3000/docs`**

Você verá o painel interativo do **Swagger**. Nele, todas as rotas estão categorizadas. Para testar qualquer rota:
1. Clique na rota desejada para expandir.
2. Clique no botão **"Try it out"** (canto superior direito da rota).
3. Ajuste os campos do JSON e clique no botão azul **"Execute"**.
4. A resposta da API aparecerá logo abaixo com o código HTTP e o resultado.

---

## 4. Roteiro Passo a Passo de Teste da Jornada do Estudante

Siga a sequência abaixo para testar o fluxo de ponta a ponta:

```
[ 1. Healthcheck ] ──► [ 2. Cadastro de Aluno ] ──► [ 3. Login e Sessão ]
                                                            │
[ 6. Busca de Vagas G2 ] ◄── [ 5. Criar Currículo ] ◄── [ 4. Preencher Perfil ]
```

---

### Passo 1: Verificar a Saúde da API (*Healthcheck*)
* **Rota:** `GET /health`
* **Finalidade:** Garante que o servidor web e a conectividade com o banco estão operacionais.
* **Resposta Esperada:** `HTTP 200 OK`
  ```json
  {
    "status": "UP",
    "banco_de_dados": "conectado",
    "versao": "1.0.0"
  }
  ```

---

### Passo 2: Criar a Conta do Estudante
* **Rota:** `POST /estudantes`
* **Payload de Envio:**
  ```json
  {
    "nome": "Marcelo Aparecido da Rosa",
    "email": "estudante@fatec.sp.gov.br",
    "senha": "FATEC@2026!Segura"
  }
  ```
* **Resposta Esperada:** `HTTP 201 Created`
  ```json
  {
    "id": "c1f2e3d4-5678-90ab-cdef-1234567890ab",
    "nome": "Marcelo Aparecido da Rosa",
    "email": "estudante@fatec.sp.gov.br"
  }
  ```

---

### Passo 3: Realizar o Login (Obter Cookie de Sessão)
* **Rota:** `POST /acessos`
* **Payload de Envio:**
  ```json
  {
    "email": "estudante@fatec.sp.gov.br",
    "senha": "FATEC@2026!Segura"
  }
  ```
* **Resposta Esperada:** `HTTP 204 No Content`
* **O que acontece por trás dos panos:** O servidor define o cookie seguro `__Host-sessao` no seu navegador. A partir deste momento, todas as rotas privadas estarão autenticadas automaticamente!

---

### Passo 4: Cadastrar Formação Acadêmica na FATEC
* **Rota:** `POST /formacoes-academicas`
* **Payload de Envio:**
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
* **Resposta Esperada:** `HTTP 201 Created` com o ID da formação gerada.

---

### Passo 5: Cadastrar Experiência Profissional
* **Rota:** `POST /experiencias-profissionais`
* **Payload de Envio:**
  ```json
  {
    "empresa": "Tech Solutions Brasil",
    "cargo": "Estagiário de Desenvolvimento Backend",
    "descricao": "Desenvolvimento de APIs RESTful com Python e modelagem de dados.",
    "data_inicio": "2025-01-10",
    "data_fim": null
  }
  ```
* **Resposta Esperada:** `HTTP 201 Created`.

---

### Passo 6: Cadastrar Competências Técnicas
* **Rota:** `POST /competencias`
* **Payload de Envio:**
  ```json
  {
    "nome": "Python",
    "nivel": "intermediario"
  }
  ```
* **Resposta Esperada:** `HTTP 201 Created`.

---

### Passo 7: Criar uma Versão de Currículo e Visualizar Prévia
1. **Criar Currículo:** `POST /curriculos` com título (ex: `"Currículo para Vagas de Estágio"`).
2. **Consultar Prévia HTML:** `GET /curriculos/{id}/previa`.
   * Retorna a estrutura montada pronta para visualização na tela do estudante.

---

### Passo 8: Testar a Busca de Vagas Integrada (Grupo 2)
* **Rota:** `POST /api/v1/vagas/match?limit=10`
* **Payload de Envio:** Envia o JSON do currículo com as competências cadastradas.
* **Resposta Esperada:** `HTTP 200 OK` trazendo até 10 vagas ordenadas pelo percentual de compatibilidade (*score*), com links de candidatura e requisitos aderentes.

---

### Passo 9: Encerrar Sessão (*Logout*)
* **Rota:** `DELETE /sessao/atual`
* **Resposta Esperada:** `HTTP 204 No Content`.
* **Comportamento:** O cookie de sessão é revogado e apagado do navegador.

---

## 5. Comandos Úteis do Docker para o Dia a Dia

| Objetivo | Comando |
| :--- | :--- |
| **Iniciar o sistema em segundo plano** | `docker compose up -d` |
| **Ver logs da API em tempo real** | `docker compose logs -f app` |
| **Ver logs do Banco de Dados** | `docker compose logs -f db` |
| **Reiniciar a API** | `docker compose restart app` |
| **Parar todos os serviços** | `docker compose stop` |
| **Derrubar e remover contêineres** | `docker compose down` |
| **Limpeza total (incluindo dados do banco)** | `docker compose down -v` |

---

## 6. Solução de Problemas Comuns (*Troubleshooting*)

* **Erro "Port 3000 already in use":**  
  Outro aplicativo está usando a porta 3000. Você pode alterar a porta no arquivo `.env` para `APP_PORT=3001` ou derrubar o processo anterior com `docker compose down`.
* **Erro de conexão com o Banco de Dados:**  
  O Docker Compose aguarda o PostgreSQL ficar saudável (*healthy*) antes de subir a API. Se o banco demorar para responder, verifique os logs com `docker compose logs db`.
* **Alterações no código não aparecem:**  
  O volume `./src:/app/src` já está configurado no `docker-compose.yml`. Certifique-se de salvar o arquivo no editor para que o Uvicorn recarregue automaticamente (*hot-reload*).
