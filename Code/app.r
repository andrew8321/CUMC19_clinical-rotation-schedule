library(shiny)
library(readxl)
library(dplyr)

# Load the Excel file
df <- read_excel("Turn.xlsx")

# Create a mapping of last characters to specific values
last_char_mapping <- list(
  "서" = "서울",
  "여" = "여의도",
  "은" = "은평",
  "빈" = "빈센트",
  "대" = "대전",
  "의" = "의정부",
  "부" = "부천",
  "인" = "인천"
)

get_weekly_values <- function(df, id_value) {
  id_row <- df %>% filter(ID == id_value)
  if (nrow(id_row) == 0) {
    return(NULL)
  }
  weekly_values <- id_row %>% select(starts_with("Week")) %>% as.list()
  return(weekly_values)
}

find_exact_match <- function(df, week, value) {
  df %>% filter(!!sym(week) == value) %>% pull(Name)
}

find_last_char_match <- function(df, week, value) {
  last_char <- substr(value, nchar(value), nchar(value))
  df %>% filter(grepl(paste0(last_char, "$"), !!sym(week))) %>% pull(Name)
}

ui <- fluidPage(
  titlePanel("턴표 요약"),
  sidebarLayout(
    sidebarPanel(
      textInput("input_id", "학번을 입력하세요", value = ""),
      actionButton("submit", "Find Matches")
    ),
    mainPanel(
      h3("턴표, 짝턴, 같은 병원 학우"),
      uiOutput("matches_output")
    )
  )
)

server <- function(input, output) {
  observeEvent(input$submit, {
    id_value <- as.numeric(input$input_id)
    weekly_values <- get_weekly_values(df, id_value)
    
    if (is.null(weekly_values)) {
      output$matches_output <- renderUI({
        div("ID not found", style = "color: red;")
      })
      return()
    }
    
    input_name <- df %>% filter(ID == id_value) %>% pull(Name)
    
    exact_matches <- list()
    last_char_matches <- list()
    
    for (week in names(weekly_values)) {
      value <- weekly_values[[week]]
      exact_matches[[week]] <- find_exact_match(df, week, value)
      exact_matches[[week]] <- exact_matches[[week]][exact_matches[[week]] != input_name]
      
      last_char_match_names <- find_last_char_match(df, week, value)
      last_char_match_names <- last_char_match_names[last_char_match_names != input_name]
      last_char_matches[[week]] <- list(
        Male = last_char_match_names[df %>% filter(Name %in% last_char_match_names) %>% pull(Gender) == "남"],
        Female = last_char_match_names[df %>% filter(Name %in% last_char_match_names) %>% pull(Gender) == "여"]
      )
    }
    
    output$matches_output <- renderUI({
      matches_output <- lapply(names(weekly_values), function(week) {
        value <- weekly_values[[week]]
        matches <- exact_matches[[week]]
        match_str <- ifelse(length(matches) > 0, paste(matches, collapse = ", "), "없음")
        last_char <- substr(value, nchar(value), nchar(value))
        mapped_last_char <- last_char_mapping[[last_char]] %>% coalesce(last_char)
        male_matches <- last_char_matches[[week]]$Male
        female_matches <- last_char_matches[[week]]$Female
        male_str <- ifelse(length(male_matches) > 0, paste(male_matches, collapse = ", "), "없음")
        female_str <- ifelse(length(female_matches) > 0, paste(female_matches, collapse = ", "), "없음")
        
        div(
          h3(week),
          div(paste0("병원: ", mapped_last_char)),
          div(paste0("과: ", value, " - 짝턴: ", match_str)),
          h3("같은 병원턴 학우들"),
          div(paste0("남자: ", male_str)),
          div(paste0("여자: ", female_str)),
          hr()
        )
      })
      do.call(tagList, matches_output)
    })
  })
}

shinyApp(ui = ui, server = server)

