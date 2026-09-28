# =============================================================================
# Biomarker Explorer - Interactive Shiny Dashboard (Multi-Panel & Multi-Timepoint)
# Author: Giulia Clas
# Description: Explore proteomic biomarker levels (NPX) across treatment groups
#              with dynamic selection of Panel (Inflammation, Cardiometabolic)
#              and Timepoint (Baseline, Week 6, Week 12).
# Data source: OlinkAnalyze R package (npx_data1).
# =============================================================================

library(shiny)
library(bslib)
library(ggplot2)
library(dplyr)

# --- Load data ---------------------------------------------------------------
# Olink Inflammation & Cardiometabolic panels across Baseline, Week 6, Week 12
data <- read.csv("data/olink_multipanel_data.csv")

# Available panels, timepoints, and default proteins
panels           <- c("Inflammation", "Cardiometabolic")
timepoints       <- c("Baseline", "Week 6", "Week 12")
initial_proteins <- sort(unique(data$Assay[data$Panel == "Inflammation"]))

# --- UI ----------------------------------------------------------------------
ui <- page_sidebar(
  title = "Biomarker Explorer",
  theme = bs_theme(
    bootswatch = "flatly",
    base_font  = font_google("Inter")
  ),

  sidebar = sidebar(
    title = "Options",

    # 1. Panel selector
    selectInput(
      "panel", "Select Panel:",
      choices  = panels,
      selected = "Inflammation"
    ),

    # 2. Timepoint selector
    selectInput(
      "timepoint", "Select Timepoint:",
      choices  = timepoints,
      selected = "Baseline"
    ),

    # 3. Protein selector (updated dynamically when panel changes)
    selectInput(
      "protein", "Select Protein:",
      choices  = initial_proteins,
      selected = "IL6"
    ),

    # 4. Plot type toggle
    radioButtons(
      "plot_type", "Plot Type:",
      choices = c("Boxplot" = "box", "Violin" = "violin")
    ),

    hr(),
    p(
      strong("Data source:"), "OlinkAnalyze R package",
      br(),
      strong("Panels:"), "Inflammation & Cardiometabolic",
      br(),
      strong("Timepoints:"), "Baseline, Week 6, Week 12",
      br(),
      "92 proteins/panel \u2022 52 subjects \u2022 NPX (log2) scale",
      style = "font-size: 0.85em; color: #888;"
    )
  ),

  # Main content
  card(
    card_header(textOutput("plot_title")),
    plotOutput("main_plot", height = "420px")
  ),
  layout_columns(
    col_widths = c(8, 4),
    card(
      card_header("Summary Statistics"),
      tableOutput("summary_table")
    ),
    card(
      card_header("Group Comparison"),
      verbatimTextOutput("test_result")
    )
  )
)

# --- Server ------------------------------------------------------------------
server <- function(input, output, session) {

  # Update protein choices whenever panel changes
  observeEvent(input$panel, {
    avail_proteins <- sort(unique(data$Assay[data$Panel == input$panel]))
    default_selected <- if (input$panel == "Inflammation" && "IL6" %in% avail_proteins) {
      "IL6"
    } else {
      avail_proteins[1]
    }

    updateSelectInput(
      session, "protein",
      choices  = avail_proteins,
      selected = default_selected
    )
  }, ignoreInit = TRUE)

  # Reactive: filtered data for selected panel, timepoint, and protein
  protein_data <- reactive({
    req(input$panel, input$timepoint, input$protein)

    data %>%
      filter(
        Panel == input$panel,
        Time  == input$timepoint,
        Assay == input$protein
      )
  })

  # Plot title
  output$plot_title <- renderText({
    req(input$protein, input$panel, input$timepoint)
    paste0(input$protein, " \u2014 NPX Distribution by Treatment (",
           input$panel, " | ", input$timepoint, ")")
  })

  # Main plot
  output$main_plot <- renderPlot({
    df <- protein_data()
    req(nrow(df) > 0)

    p <- ggplot(df, aes(x = Treatment, y = NPX, fill = Treatment)) +
      labs(y = paste0(input$protein, " (NPX)"), x = NULL) +
      scale_fill_manual(values = c(Untreated = "#3498DB", Treated = "#E74C3C")) +
      theme_minimal(base_size = 15) +
      theme(legend.position = "none")

    if (input$plot_type == "box") {
      p <- p + geom_boxplot(alpha = 0.7, outlier.shape = NA, width = 0.5)
    } else {
      p <- p + geom_violin(alpha = 0.7, trim = FALSE)
    }

    p + geom_jitter(width = 0.12, alpha = 0.5, size = 2.5, color = "#2C3E50")
  })

  # Summary statistics table
  output$summary_table <- renderTable({
    df <- protein_data()
    req(nrow(df) > 0)

    df %>%
      group_by(Treatment) %>%
      summarise(
        N      = n(),
        Mean   = round(mean(NPX, na.rm = TRUE), 2),
        SD     = round(sd(NPX, na.rm = TRUE), 2),
        Median = round(median(NPX, na.rm = TRUE), 2),
        .groups = "drop"
      )
  }, striped = TRUE, hover = TRUE)

  # Wilcoxon rank-sum test
  output$test_result <- renderText({
    df <- protein_data()
    req(nrow(df) > 0)

    ctrl <- df %>% filter(Treatment == "Untreated") %>% pull(NPX)
    trt  <- df %>% filter(Treatment == "Treated")   %>% pull(NPX)

    ctrl <- ctrl[!is.na(ctrl)]
    trt  <- trt[!is.na(trt)]

    if (length(ctrl) < 3 || length(trt) < 3) {
      return("Insufficient data points to perform test.")
    }

    test <- wilcox.test(ctrl, trt)

    paste0(
      "Wilcoxon rank-sum test\n",
      "Protein: ", input$protein, "\n",
      "Panel: ", input$panel, " | Timepoint: ", input$timepoint, "\n\n",
      "W = ", test$statistic, "\n",
      "p-value = ", format(test$p.value, digits = 3, scientific = TRUE), "\n\n",
      if (test$p.value < 0.05) {
        "Result: Significant (p < 0.05)"
      } else {
        "Result: Not significant (p >= 0.05)"
      }
    )
  })
}

# --- Run app -----------------------------------------------------------------
shinyApp(ui, server)
