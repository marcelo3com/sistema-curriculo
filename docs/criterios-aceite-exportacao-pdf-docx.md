# Critérios de Aceite para Exportação em PDF e DOCX e Matriz de Validação

- **Referência:** Task `[F1.5] #172` (Definir critérios de aceite da exportação PDF e DOCX, incluindo os aplicativos de validação)
- **Fatia Técnica:** Fundação Arquitetural (`[F1]`) / Qualidade da Exportação (`RNF07`)
- **Documentador Oficial:** Marcelo Aparecido da Rosa ([@marcelo-3com](https://github.com/marcelo-3com))
- **Líder Técnico e QA Arquitetural:** Rodolpho P. M. Ferreira
- **Desenvolvedor Responsável pelo Módulo:** Vinicius Regazio Farias
- **Responsáveis por Testes e Homologação:** Daniel Lacerda Xavier / Gustavo Minoru Haga
- **Versão:** 1.0.0
- **Data:** Novembro de 2026

---

## 1. Objetivo

Este documento define formalmente os **critérios de aceitação de qualidade**, as **regras de formatação visual** e a **matriz de aplicativos de validação** para os documentos de currículo gerados nos formatos **PDF** e **DOCX**, sanando as pendências arquiteturais registradas no requisito **RNF07 (Qualidade da Exportação)**.

O objetivo é assegurar que o estudante receba um currículo com estética profissional, compatível com os principais leitores de mercado, legível por sistemas ATS (Applicant Tracking Systems) de recrutadores e sem falhas de diagramação.

---

## 2. Requisitos Gerais de Formatação e Layout

### 2.1. Padrão de Página e Margens
* **Dimensão do Papel:** Padrão A4 ($210\text{ mm} \times 297\text{ mm}$).
* **Margens:**
  * Superior e Inferior: $15\text{ mm}$ a $20\text{ mm}$.
  * Esquerda e Direita: $15\text{ mm}$ a $20\text{ mm}$.
* **Orientação:** Retrato (*Portrait*).

### 2.2. Tipografia e Hierarquia Visual
* **Famílias Tipográficas Homologadas:**
  * Modelo Clássico: Fontes serifadas/neutras universais (`Times New Roman`, `Georgia`, `Liberation Serif`).
  * Modelo Moderno / Compacto: Fontes sem serifa universais (`Arial`, `Calibri`, `Roboto`, `Liberation Sans`).
* **Hierarquia de Tamanhos:**
  * Nome do Estudante (Título Principal): 18 a 22 pt (Negrito).
  * Títulos de Seção (H2): 12 a 14 pt (Negrito ou Caixa Alta).
  * Cargos, Cursos e Instituições: 10,5 a 11 pt (Seminegrito).
  * Corpo de Texto e Descrições: 9,5 a 10 pt (Regular).
  * Metadados e Datas: 9 pt (Itálico ou cor secundária de alto contraste).
* **Contraste de Cor:** Proporção mínima de contraste de **4.5:1** (conformidade com WCAG AA) entre o texto e o fundo. Fundo estritamente branco puro (`#FFFFFF`) para garantir impressão econômica.

---

## 3. Critérios de Aceite Específicos por Formato

### 3.1. Exportação em PDF (Portable Document Format)

O PDF destina-se ao envio direto a recrutadores e plataformas de vagas.

* **[CA-PDF-01] Texto Selecionável e Cópia Fiel:** O arquivo PDF deve conter texto vetorial real (nunca imagem rasterizada de texto). O usuário deve conseguir selecionar e copiar qualquer linha sem caracteres corrompidos (*encoding UTF-8*).
* **[CA-PDF-02] Compatibilidade ATS (Robôs de Recrutamento):** A ordem de leitura do fluxo de texto deve ser linear e lógica, permitindo que analisadores sintáticos extraiam nome, competências e histórico na sequência correta.
* **[CA-PDF-03] Ausência de Sobreposição (*No Clipping/Overlapping*):** Não é permitido corte de linhas, sobreposição de caixas de texto ou invasão de margens em nenhum modelo.
* **[CA-PDF-04] Quebra de Página Inteligente (*Pagination Rules*):**
  * Títulos de seção **nunca** podem ficar órfãos no rodapé da página (deve haver ao menos 2 linhas de conteúdo abaixo do título ou forçar quebra de página).
  * O bloco de uma experiência ou formação deve preferencialmente se manter coeso na mesma página.
* **[CA-PDF-05] Links Clicáveis:** Links de LinkedIn, GitHub, e-mail e portfólio devem ser exportados com hiperlinks funcionais.
* **[CA-PDF-06] Limite de Tamanho:** O arquivo PDF final não deve ultrapassar **2,0 MB**.

---

### 3.2. Exportação em DOCX (Microsoft Word OpenXML)

O DOCX destina-se a permitir que o estudante realize edições finas no processador de textos de sua preferência.

* **[CA-DOCX-01] Uso de Estilos Nativos (*Headings*):** A geração deve mapear os títulos para os estilos semânticos do Word (`Título 1`, `Título 2`, `Normal`), facilitando a navegação estruturada.
* **[CA-DOCX-02] Diagramação Estável:** O layout deve utilizar tabelas invisíveis ou tabulações nativas para alinhamento de datas à direita, impedindo que edições de texto quebrem a estrutura do documento.
* **[CA-DOCX-03] Fidelidade Visual:** As fontes, tamanhos, espaçamentos e marcadores de tópicos (*bullet points*) devem refletir com precisão a pré-visualização web exibida na plataforma.
* **[CA-DOCX-04] Editabilidade Limpa:** O documento não deve conter formas flutuantes ou caixas de texto absolutas complexas que dificultem a digitação do estudante.
* **[CA-DOCX-05] Limite de Tamanho:** O arquivo DOCX gerado não deve exceder **1,5 MB**.

---

## 4. Matriz de Aplicativos e Ambientes de Validação

Para que uma versão do módulo de exportação seja considerada aceita pelo QA, ela deve ser obrigatoriamente testada e aprovada na seguinte matriz de suítes de escritório e leitores:

### 4.1. Validação de Arquivos DOCX

| Aplicativo de Validação | Versão Mínima Homologada | Sistema Operacional | Critério Específico de Inspeção |
| :--- | :--- | :--- | :--- |
| **Microsoft Word (Desktop)** | Microsoft 365 / Word 2019+ | Windows 10/11 e macOS | Abertura sem alertas de "arquivo corrompido" ou necessidade de recuperação. Preservação exata de margens e alinhamentos. |
| **Microsoft Word Online** | Versão Web oficial (gratuita) | Qualquer navegador | Renderização perfeita na nuvem (uso comum por estudantes sem licença local). |
| **LibreOffice Writer** | v7.5+ / v24+ | Ubuntu Linux e Windows | Renderização correta em software livre (padrão de laboratórios FATEC). |
| **Google Documentos (Docs)**| Versão Web oficial | Navegadores modernos | Importação limpa do `.docx` mantendo tópicos, negritos e quebras de linha. |

### 4.2. Validação de Arquivos PDF

| Aplicativo de Validação | Versão Mínima Homologada | Ambiente | Critério Específico de Inspeção |
| :--- | :--- | :--- | :--- |
| **Adobe Acrobat Reader** | DC / Versão mais recente | Windows / macOS / Android | Renderização sem aviso de erro de fontes embutidas; links ativos e funcionais. |
| **Google Chrome / Chromium**| Versões Evergreen (atuais) | Web Desktop | Visualizador nativo padrão do navegador abre sem distorção. |
| **Mozilla Firefox** | v115+ (ESR e Release) | Web Desktop | Visualizador PDF.js exibe o documento com fidelidade de cores e fontes. |
| **Impressão Virtual / Física**| Driver Microsoft Print to PDF | Windows | Verificação de área imprimível sem corte de bordas. |

---

## 5. Roteiro de Testes e Homologação de Qualidade (Checklist do QA)

Antes da aprovação de qualquer PR referente à exportação:

- [ ] **Massa de Dados Completa:** Gerar exportação com currículo contendo todas as seções preenchidas no limite máximo de volume (10 formações, 15 experiências, 30 competências).
- [ ] **Massa de Dados Mínima:** Gerar exportação de estudante sem experiência profissional e sem cursos complementares, verificando a ausência de espaços em branco anômalos.
- [ ] **Abertura em Cascata:** Abrir o mesmo arquivo DOCX no Microsoft Word, LibreOffice e Google Docs, confirmando estabilidade visual em todos.
- [ ] **Teste de Cópia e Cola:** Copiar parágrafo do PDF e colar em bloco de notas para garantir que não há caracteres ilegíveis ou junções incorretas de palavras.
- [ ] **Teste de Links:** Clicar em cada link exportado e verificar o redirecionamento correto.

---

## 6. Rastreabilidade com o Projeto

* **Card #172 (`[F1.5]`):** Cumpre integralmente a entrega de definição de critérios de aceite e matriz de aplicativos de validação para PDF e DOCX.
* **Requisito Não Funcional RNF07:** Elimina as pendências detalhadas na Seção de pendências do documento de requisitos de arquitetura.
* **Equipe de Desenvolvimento:** Orienta a implementação dos geradores em Python (`ReportLab` / `WeasyPrint` para PDF e `python-docx` para DOCX).
