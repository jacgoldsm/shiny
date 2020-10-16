library(shiny)
library(dplyr)
library(readr)
library(glue)
library(DescTools)

ui <- fluidPage(
    
    # Application title
    titlePanel("How High Should Taxes Be (To Fund UBI)?"),
    
    sidebarLayout(
        sidebarPanel(
            selectInput("init",
                        label = "Initial Income Distribution",
                        choices = c("United States" = "US",
                                    "United Kingdom" = "UK"),
                        selected = "US"),
            sliderInput("loss",
                        label = "Average Deadweight Loss per Dollar Taxed",
                        min = 0, max = 3, step = 0.05, value = 0.6),
            selectInput("custom", 
                        label = "Preset or Custom SWF?",
                        choices = c("Preset" = "pre",
                                    "Custom" = "custom"),
                        selected = "pre"),
            conditionalPanel(condition = "input.custom == 'pre'",
                            selectInput("dim",
                                label = "Pre-made Social Welfare Function",
                                choices = c("Linear" = 'linear',
                                            "Log" = 'log',
                                            "Square Root" = 'sqrt',
                                           "Max-Min (Rawls)" = 'min',
                                            "Gini (Sen)" = 'gini'),
                                selected = "log")),
            conditionalPanel(condition = "input.custom == 'custom'",
                             textInput("cust", "Custom SWF"),
                tags$p("In this text box, enter an R function whose
                       domain is the incomes of the 100 simulated
                       particpants and whose range is a single
                       real number. Write the expression as a function
                       of a single variable 'x', representing the income
                       of a particular individual. The {base}
                       and {DescTools} packages are installed and loaded
                       for use in generating functions. Do not enclose the
                       function in quotes."),
                tags$p("Example: mean(x)^2 / Gini(x)"))
            
        ),
        
        mainPanel(
            tags$p("This app allows the user to explore the possibility of a
                   Universal Basic Income (UBI) funded by a progressive income 
                   tax. The user is offered three inputs to fill in, at which
                   point the app will give the optimal marginal tax rate 
                   associated with the user's choices."),
            tags$p("First, choose the initial distribution of wealth from one
                    of the three regions listed. Next, decide how much you think
                    real national income decreases as tax rates increase. Finally,
                    how much do you value equality versus efficiency? In other
                    words, how much less valuable do you think the 10,000th dollar
                    is than the tenth? Choose a social welfare function that matches
                    your intuition, or make your own (see sidebar for advice). Note: do not attempt to compare utility across
                    different social welfare functions -- that does not work!"), 
            tags$b(textOutput("max")), 
            plotOutput("plot"),
            tags$p("For a complete explanation of the algorithm and the 
                        complete source code for the app, see ",
                   HTML(paste0(tags$a(href = "https://github.com/jacgoldsm/Jacob-Goldsmith/tree/master/webbr", "source."))))
        )
    )
)

server <- function(input, output, session) {
    usdata <- read_csv("sh1.csv")
    usdata <- usdata %>%
        rename("recent" = `2019`) %>%
        mutate(recent = stringr::str_replace_all(recent, '[$,]', '')) %>%
        mutate(recent = as.numeric(recent)) 
    
    ukdata <- read_csv("ukdata.csv")
    
    init <- reactive({
        if (input$init == "US"){
            nat <- usdata$recent
        }
  
        if (input$init == "UK"){
            nat <- ukdata$uk_data
        }
        return(nat)
    })
    
    rates <- seq(0,0.99, by = 0.01)
    
    post_inc <- reactive({
        after <- data.frame(row.names = 1:99)
        for (j in 1:length(rates)) {
            after_loss <- numeric(length = 99)
            after_tax <- numeric(length = 99)
            for (i in 1:nrow(after)) {
                #indiv tax rate
                a <- c(75 < i, 50 < i & i <= 75, 25 < i & i <= 50, i <= 25)
                if (a[1]) indiv <- rates[j]
                if (a[2]) indiv <- rates[j] / 2
                if (a[3]) indiv <- rates[j] / 4
                if (a[4]) indiv <- 0
                
                #deadweight loss
                after_loss[i] <- (init()[i]) / (1 + input$loss*indiv)
                #individual tax
                after_tax[i] <- after_loss[i] - after_loss[i]*(indiv) 
            }
            #transfer -- means-blind UBI amount
            after[,j] <- after_tax + (mean(after_loss) - mean(after_tax))
        }
        return(after)
    })
    
    post_tot_ut <- reactive({
        #total utility
      if (input$custom == 'pre') {
        if (input$dim == "linear") {
            aft_ut <- sapply(post_inc(),sum)
        }
        if (input$dim == "log") {
            aft_ut <- sapply(post_inc(),function(x) sum(log(x)))
        }
        
        if (input$dim == "sqrt") {
            aft_ut <- sapply(post_inc(),function(x) sum(x^0.5))
        }
        
        if (input$dim == "min") {
            aft_ut <- sapply(post_inc(),min)

        }
        
        if (input$dim == "gini") {
            aft_ut <- sapply(post_inc(),
                function(x) mean(x)/DescTools::Gini(x))
        }
      }
      
      if (input$custom == "custom") {
        validate(
          need(try(length(sapply(post_inc(),
                          function(x) eval(rlang::parse_expr(input$cust)))) == 100), 
               "Enter a valid R function")
          )
        ex <- rlang::parse_expr(input$cust) 
        aft_ut <- sapply(post_inc(),
                         function(x) eval(ex))
      }
        return(aft_ut)
    })
    output$max <- renderText({
       glue("Maximum utility is achieved at a maximum 
       tax rate of ", (rates[which.max(post_tot_ut())])*100
       , "%. The average tax rate faced by the 100 simulated participants
             in that scenario is ", 
       round((rates[which.max(post_tot_ut())])*100*(7/16), 2), "%.")
  })
      output$plot <- renderPlot({
        plot(x = rates, y = post_tot_ut(),
             xlab = "Tax Rates",
             ylab = "Total Utility",
             main = "Tax Rate on Highest Earners vs. Total Utility")
 })
}

# Run the application 
shinyApp(ui = ui, server = server)
