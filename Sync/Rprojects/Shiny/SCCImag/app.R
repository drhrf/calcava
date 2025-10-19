# app.R

library(shiny)
library(tidyverse)
library(readxl)
library(DescTools)
library(gridExtra)

ui <- fluidPage(
  titlePanel("Análise de Dados de Cálcio - Picos e Intervalos"),
  
  sidebarLayout(
    sidebarPanel(
      fileInput("file", "Selecione o arquivo Excel (.xlsx)",
                accept = c(".xlsx")),
      tags$hr(),
      helpText("O arquivo deve conter a coluna de tempo na 1ª coluna (ex.: 'Time (sec)')."),
      
      # Entrada para seleção do intervalo de tempo
      numericInput("tstart", "Início do intervalo (sec)", value = 0, min = 0),
      numericInput("tend",   "Fim do intervalo (sec)",   value = 300, min = 0),
      helpText("Defina o intervalo de tempo que deseja analisar mais detalhadamente.")
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("Gráficos", 
                 plotOutput("gridPlots", height = "800px")),
        
        # Removemos a aba de "Resultados Gerais"
        
        tabPanel("Estatística descritiva (por intervalo)",
                 tableOutput("resultsTableSubset"))
      )
    )
  )
)

server <- function(input, output) {
  
  ##############################################################################
  # 1) LEITURA E PROCESSAMENTO DOS DADOS (COMPLETOS)
  ##############################################################################
  data_processed <- reactive({
    req(input$file)  # só prossegue se o arquivo foi carregado
    
    # 1.1 Ler o arquivo e remover linhas com NA
    df <- read_excel(input$file$datapath) %>%
      drop_na()
    
    # 1.2 Converter df para formato longo (tidy)
    dmelt <- df %>%
      pivot_longer(cols = -1, names_to = "variable", values_to = "value") %>%
      rename(`Time (sec)` = 1)
    
    # 1.3 Calcular baseline e cut com as primeiras 30 linhas do dataset completo
    #     (excluindo a coluna de tempo)
    a <- df %>%
      slice(1:30) %>%
      select(-1) %>%
      pivot_longer(cols = everything(), names_to = "variable", values_to = "value")
    
    baseline <- mean(a$value, na.rm = TRUE)
    cut <- baseline + 5 * sd(a$value, na.rm = TRUE)
    
    # 1.4 Definir dcut e dbase (sem recorte de tempo)
    dcut  <- dmelt %>% filter(value >= cut)
    dbase <- dmelt %>% filter(value <= cut)
    
    # 1.5 Resposta média ao longo do tempo (completo)
    avg <- dmelt %>%
      group_by(`Time (sec)`) %>%
      summarise(sd  = sd(value, na.rm = TRUE),
                len = mean(value, na.rm = TRUE))
    
    # Retorna lista com o que precisamos para gráficos
    list(
      df      = df,
      dmelt   = dmelt,
      dcut    = dcut,
      dbase   = dbase,
      avg     = avg
    )
  })
  
  ##############################################################################
  # 2) GRÁFICOS COMPLETOS (SEM RECORTE DE TEMPO)
  ##############################################################################
  # Gráfico 1: Dados completos
  plot_p1 <- reactive({
    data <- data_processed()
    ggplot(data$dmelt, aes(x = `Time (sec)`, y = value, 
                           color = variable, group = variable)) +
      geom_line() +
      labs(title = "Gráfico Completo",
           x = "Time (sec)",
           y = "F340/380") +
      theme_minimal() +
      theme(legend.position = "none")
  })
  
  # Gráfico 2: Dados pós-cut (>= cut), com quebra em gaps
  plot_p2 <- reactive({
    data <- data_processed()
    dcut_grouped <- data$dcut %>%
      group_by(variable) %>%
      arrange(`Time (sec)`) %>%
      mutate(
        gap = `Time (sec)` - lag(`Time (sec)`, default = first(`Time (sec)`)),
        group_id = cumsum(if_else(gap > 1, 1, 0))
      ) %>%
      ungroup()
    
    ggplot(dcut_grouped, aes(x = `Time (sec)`, y = value, 
                             color = variable, 
                             group = interaction(variable, group_id))) +
      geom_line() +
      labs(title = "Pós-Cut (>= cut)",
           x = "Time (sec)",
           y = "F340/380") +
      theme_minimal() +
      theme(legend.position = "none")
  })
  
  # Gráfico 3: Baseline (<= cut)
  plot_p3 <- reactive({
    data <- data_processed()
    ggplot(data$dbase, aes(x = `Time (sec)`, y = value, 
                           color = variable, group = variable)) +
      geom_line() +
      labs(title = "Baseline (<= cut)",
           x = "Time (sec)",
           y = "F340/380") +
      coord_cartesian(ylim = c(0, 1.5)) +
      theme_minimal() +
      theme(legend.position = "none")
  })
  
  # Gráfico 4: Resposta média (todo o experimento)
  plot_p4 <- reactive({
    data <- data_processed()
    ggplot(data$avg, aes(x = `Time (sec)`, y = len)) +
      geom_line(color = "lightblue") +
      geom_point(color = "lightblue") +
      labs(title = "Resposta Média",
           x = "Time (sec)",
           y = "F340/380") +
      theme_minimal()
  })
  
  # Renderiza o grid de gráficos
  output$gridPlots <- renderPlot({
    req(data_processed())
    grid.arrange(
      plot_p1(),
      plot_p2(),
      plot_p4(),
      plot_p3(),
      ncol = 2, nrow = 2
    )
  })
  
  ##############################################################################
  # 3) ANÁLISE POR INTERVALO DE TEMPO (CÁLCULOS APENAS DENTRO DO RECORTE)
  ##############################################################################
  subset_analysis <- reactive({
    data_all <- data_processed()
    if (is.null(data_all)) return(NULL)
    
    # Filtrar o dmelt para o intervalo especificado
    subset_dmelt <- data_all$dmelt %>%
      filter(`Time (sec)` >= input$tstart,
             `Time (sec)` <= input$tend)
    
    # Se não houver dados no intervalo, retorna NULL
    if (nrow(subset_dmelt) == 0) {
      return(NULL)
    }
    
    # Número total de células (colunas - 1)
    totcells <- ncol(data_all$df) - 1
    
    # Baseline e cut dentro do intervalo (primeiras 30 linhas do subset, ou todas se < 30)
    subset_a <- subset_dmelt %>% slice(1:min(30, n()))
    baseline <- mean(subset_a$value, na.rm = TRUE)
    cut <- baseline + 5 * sd(subset_a$value, na.rm = TRUE)
    
    # dcut e dbase no intervalo
    dcut  <- subset_dmelt %>% filter(value >= cut)
    dbase <- subset_dmelt %>% filter(value <= cut)
    
    # Número e % de células responsivas neste intervalo
    nmbresp <- dcut %>% pull(variable) %>% unique() %>% length()
    percresp <- (nmbresp * 100) / totcells
    
    # Resposta média no intervalo
    avg <- subset_dmelt %>%
      group_by(`Time (sec)`) %>%
      summarise(sd  = sd(value, na.rm = TRUE),
                len = mean(value, na.rm = TRUE))
    
    # Percentual de aumento e área sob a curva (no intervalo)
    percmax <- (max(avg$len, na.rm = TRUE) * 100) / baseline
    
    if (nrow(avg) < 2) {
      aucmed <- NA
    } else {
      aucmed <- AUC(x = avg$`Time (sec)`, y = avg$len)
    }
    
    # Duração efetiva do intervalo
    exp_duration_sec <- input$tend - input$tstart
    
    # Monta dataframe final (wide)
    results_subset_wide <- data.frame(
      "Total_de_celulas"         = totcells,
      "Celulas_responsivas"    = nmbresp,
      "Duracao_do_experimento"    = exp_duration_sec,
      "Intensidade_no_baseline"  = baseline,
      "Ponto_de_corte"            = cut,
      "Percentual_de_celulas_responsivas"  = percresp,
      "Percentual_de_aumento_de_calcio" = percmax,
      "Area_abaixo_da_curva"    = aucmed
    )
    
    # Converte para formato long (duas colunas: Variable, Value)
    results_subset_long <- results_subset_wide %>%
      pivot_longer(cols = everything(),
                   names_to = "Variavel",
                   values_to = "Valor")
    
    results_subset_long
  })
  
  # Renderiza a tabela de resultados para o intervalo escolhido
  output$resultsTableSubset <- renderTable({
    subset_analysis()
  }, digits = 6)
}

shinyApp(ui, server)
