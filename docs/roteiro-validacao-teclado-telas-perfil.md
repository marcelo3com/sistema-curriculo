# Roteiro de Validação e Evidências de Navegação por Teclado — Telas de Perfil e Informações Complementares

- **Referência:** Task `[F8.11] #367` (Validar as telas de perfil e informações complementares por teclado)
- **Fatia Técnica:** Front End / Acessibilidade (`[F8]`) / Requisito Não Funcional `RNF02`
- **Norma de Referência:** Diretrizes de Acessibilidade para Conteúdo Web (WCAG 2.1) — Nível AA
- **Documentador Oficial:** Marcelo Aparecido da Rosa ([@marcelo-3com](https://github.com/marcelo-3com))
- **Líder Técnico e QA Arquitetural:** Rodolpho P. M. Ferreira
- **Responsáveis por Front End / UI:** Ricardo Galdino de Sampaio / Nathan Campos Nagano
- **Responsáveis por Testes e Homologação:** Daniel Lacerda Xavier / Gustavo Minoru Haga
- **Versão:** 1.0.0
- **Data:** Novembro de 2026

---

## 1. Objetivo do Roteiro

Este documento estabelece o **roteiro de inspeção, critérios de conformidade e matriz de validação de acessibilidade por teclado** para a jornada completa do estudante no **Sistema Currículo (Grupo 1)**.

A validação assegura que estudantes que utilizam apenas o teclado (sem mouse) ou leitores de tela possam preencher, editar, navegar e excluir itens do seu perfil e informações complementares com total autonomia, sem bloqueios de navegação e em conformidade estrita com o padrão **WCAG 2.1 Nível AA** (requisito **RNF02**).

---

## 2. Padrões de Interação por Teclado Homologados

Para garantir previsibilidade ao usuário, todos os componentes interativos do frontend devem responder estritamente às convenções universais:

| Tecla / Combinação | Ação Esperada |
| :--- | :--- |
| **`Tab`** | Avança o foco para o próximo elemento interativo navegável na ordem lógica da página. |
| **`Shift + Tab`** | Retorna o foco para o elemento interativo imediatamente anterior. |
| **`Enter`** | Ativa botões de submissão, abre links e confirma ações de formulário. |
| **`Espaço` (`Space`)** | Alterna estados de *checkboxes*, ativa botões secundários e abre seletores suspensos (*dropdowns*). |
| **`Setas (↑ / ↓ / ← / →)`** | Navega entre opções de botões de rádio (*radio groups*), itens de menu e seletores de opções. |
| **`Escape` (`Esc`)** | Fecha caixas de diálogo modais, menus suspensos e painéis flutuantes, devolvendo o foco ao elemento disparador. |
| **`Delete` / `Backspace`** | Remove *chips* / tags de competências ou tecnologias quando o elemento estiver focado. |

---

## 3. Matriz de Telas e Componentes Avaliados

O escopo do Card #367 cobre a auditoria de 5 interfaces centrais:

1. **Tela 1 — Perfil e Dados Pessoais:** Formulário de cadastro de nome, e-mail, telefones, endereço, cidade e links profissionais (LinkedIn e Lattes).
2. **Tela 2 — Formação Acadêmica:** Formulário de criação/edição de cursos FATEC, seletores de enums (`nível`, `status`), campos de data e lista de formações cadastradas.
3. **Tela 3 — Experiências Profissionais:** Formulário de cargo, empresa, período (data de início e término), alternador de emprego atual (`checkbox`) e lista de cartões.
4. **Tela 4 — Competências e Idiomas:** Input dinâmico de competências com tags interativas removíveis e seleção de fluência em idiomas.
5. **Tela 5 — Documentos Complementares:** Botão de seleção de arquivo por teclado e tabela de comprovantes anexados com botão de exclusão.

---

## 4. Roteiro Passo a Passo de Teste e Validação

### 4.1. Ciclo de Foco e Ordem Lógica (WCAG 2.4.3 - *Focus Order*)
* **Procedimento:**
  1. Carregar a tela de Perfil com o cursor fora da janela.
  2. Pressionar `Tab` repetidamente até o rodapé da página.
* **Critério de Sucesso:**
  * O foco avança de forma natural e lógica: *Cabeçalho $\rightarrow$ Menu Superior $\rightarrow$ Título Principal $\rightarrow$ Primeiro Campo de Formulário $\rightarrow$ Campos Subsequentes $\rightarrow$ Botão Salvar / Cancelar $\rightarrow$ Rodapé*.
  * Nenhum elemento oculto ou decorativo recebe foco indevido.

---

### 4.2. Indicador Visual de Foco (WCAG 2.4.7 - *Focus Visible*)
* **Procedimento:**
  1. Percorrer cada input, botão, link e caixa de seleção com o teclado.
  2. Inspecionar visualmente o anel de foco (*focus ring*).
* **Critério de Sucesso:**
  * Todo elemento interativo exibe claramente um anel de foco com espessura mínima de **$2\text{ px}$** e contraste cromático $\ge 3:1$ em relação ao fundo da tela (proibido o uso de `outline: none` sem substituição visual evidente).

---

### 4.3. Ausência de Armadilha de Teclado (WCAG 2.1.2 - *No Keyboard Trap*)
* **Procedimento:**
  1. Navegar por `Tab` para dentro de listas de tags de competências, tabelas de documentos e campos com máscaras de data/telefone.
  2. Tentar avançar com `Tab` e retroceder com `Shift + Tab`.
* **Critério de Sucesso:**
  * O foco entra e sai livremente de qualquer área da página. Em nenhum momento o estudante fica "preso" sem conseguir avançar ou recuar.

---

### 4.4. Comportamento de Diálogos Modais e Retorno de Foco (Issue #396)
* **Procedimento de Teste de Exclusão:**
  1. Navegar via teclado até o botão "Excluir Formação" de um cartão e pressionar `Enter`.
  2. Verificar o comportamento do diálogo modal de confirmação.
  3. Pressionar `Escape` ou navegar até "Cancelar" e pressionar `Enter`.
* **Critério de Sucesso:**
  * **Captura de Foco no Modal:** Ao abrir, o foco salta imediatamente para o primeiro elemento interativo do modal (botão "Cancelar" por segurança).
  * **Restrição de Foco (*Focus Trap* Proposital no Modal):** Pressionar `Tab` dentro do modal mantém o foco circulando apenas entre "Cancelar" e "Confirmar Exclusão", sem vazar para a página de fundo.
  * **Retorno Obrigatório do Foco:** Ao fechar o modal, o foco **retorna exatamente para o botão "Excluir" que o disparou**, impedindo que o estudante seja jogado de volta ao topo da página.

---

### 4.5. Operação de Tags Dinâmicas de Competências
* **Procedimento:**
  1. Focar no campo de texto "Nova Competência", digitar `"Python"` e pressionar `Enter`.
  2. Pressionar `Tab` para focar na tag `"Python"` recém-criada.
  3. Pressionar `Delete` ou `Backspace` (ou focar no ícone `✕` e teclar `Enter`).
* **Critério de Sucesso:**
  * A tag é removida sem necessidade de clique com o mouse.
  * O foco é realocado suavemente para a próxima tag disponível ou devolvido ao campo de digitação de competências.

---

## 5. Checklist Consolidado de Evidências de Acessibilidade

| ID | Item Verificado | Critério WCAG | Status | Evidência Observada |
| :---: | :--- | :---: | :---: | :--- |
| **EV-01** | Todos os campos de perfil e contato navegáveis por `Tab` | 2.1.1 (Teclado) | **APROVADO** | Sequência linear `nome` $\rightarrow$ `email` $\rightarrow$ `telefones` $\rightarrow$ `cidade`. |
| **EV-02** | Indicador de foco evidente em todos os botões e inputs | 2.4.7 (Foco Visível) | **APROVADO** | Anel azul de $2\text{ px}$ com contraste $4.5:1$ sobre fundo branco. |
| **EV-03** | Alternador "Trabalho Atual" operável por tecla `Espaço` | 2.1.1 (Teclado) | **APROVADO** | Checkbox marca/desmarca e habilita/desabilita campo `data_fim`. |
| **EV-04** | Fechamento de modais com a tecla `Escape` | 2.1.2 (Sem Armadilha)| **APROVADO** | Tecla `Esc` fecha modal de confirmação de exclusão em todas as telas. |
| **EV-05** | Retorno de foco garantido após fechamento de modais | 2.4.3 (Ordem de Foco)| **APROVADO** | Foco retido no botão disparador original da lista. |
| **EV-06** | Adição e remoção de competências por teclado | 2.1.1 (Teclado) | **APROVADO** | Tecla `Enter` insere chip; `Delete` / botão `✕` remove sem mouse. |
| **EV-07** | Botão de upload de documentos operável via teclado | 2.1.1 (Teclado) | **APROVADO** | Tecla `Enter` aciona o seletor nativo de arquivos do sistema. |
| **EV-08** | Mensagens de validação e erro audíveis por leitores | 3.3.1 (Avisos de Erro)| **APROVADO** | Uso de `aria-describedby` e `role="alert"` em campos obrigatórios vazios. |

---

## 6. Rastreabilidade com o Backlog

* **Card #367 (`[F8.11]`):** Validação técnica das telas de perfil e informações complementares por teclado formalizada e aprovada.
* **Requisito Não Funcional RNF02:** Comprova a aderência da plataforma aos requisitos de Acessibilidade e Inclusão Digital da FATEC-SP.
* **Equipes de Front End e QA:** Fornece o gabarito oficial de conformidade para o Ricardo, Nathan, Daniel e Gustavo antes do fechamento da release.
