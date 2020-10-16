
library(shiny)
library(leaflet)
library(lubridate)
library(tidycensus)
library(dplyr)
library(sf)
library(shinycssloaders)

# Define UI for application that draws a histogram
ui <- fluidPage(
    HTML("<body style='background-color:powderblue;'>"),
    # Application title
    titlePanel("Evolution of the COVID-19 Pandemic in the US"),
    # Sidebar with a slider input for number of bins 
    sidebarLayout(
        sidebarPanel(
            dateInput("date",
                        label = "Choose a date",
                        value = lubridate::today()-days(1),
                        min = "2020-03-01",
                        max = lubridate::today()-days(1)),
      tags$br(),
      tags$p(tags$b("Hover over the icon at the top right of the
                         map to choose figures to display. 
                     Click on a state to view its information.")),
      tags$p('For the information that the map is currently displaying,
             a darker shade of red indicates higher ',
             tags$em('case '), '(not death) numbers.',
             style="color:red")
        ),
        # Show a plot of the generated distribution
        mainPanel(
           leafletOutput("leaf") %>% withSpinner(color="#0dc5c1"),
           HTML(paste0(tags$a(href = "https://covidtracking.com/data/api", "Source: Covid Tracking Project"))),
           tags$br(),
           HTML(paste0(tags$a(href = "https://github.com/jacgoldsm/Jacob-Goldsmith/tree/master/webbrCovid", "Code (GitHub)")))
         
           
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
    covid <- readr::read_csv("https://api.covidtracking.com/v1/states/daily.csv")
    covid <- covid %>%
        mutate(date = lubridate::ymd(date)) %>%
        mutate(state = usdata::abbr2state(state))
    
    total_pop <- st_read("total_pop.shp")
    
    comb1 <- left_join(total_pop, covid, by = c("NAME" = "state")) %>%
        mutate(Confirmed_cap = (positive / estimate) * 1000000, 
               Deaths_cap = (death / estimate)*1000000) %>%
        mutate(positiveIncrease_cap = (positiveIncrease / estimate) * 1000000, 
               deathIncrease_cap = (deathIncrease / estimate)*1000000) %>%
        st_sf()
    
    comb <- reactive({
        comb1 %>% filter(date == input$date)
    })
    
    content1 <- reactive({
        paste(
        comb()$NAME, '<br>',
        "Total Confirmed Cases per Million People: ",
        round(comb()$Confirmed_cap,0), '<br>',
        "Total Deaths per Million People: ",
        round(comb()$Deaths_cap,0))
    })
    
    content2 <- reactive({
        paste(
            comb()$NAME, '<br>',
            "Total Confirmed Cases: ",
            round(comb()$positive,0), '<br>',
            "Total Deaths: ",
            round(comb()$death,0))
    })
    
    content3 <- reactive({
        paste(
            comb()$NAME, '<br>',
            "New Confirmed Cases per Million People: ",
            round(comb()$positiveIncrease_cap,0), '<br>',
            "New Deaths per Million People: ",
            round(comb()$deathIncrease_cap,0))
    })
    
    content4 <- reactive({
        paste(
            comb()$NAME, '<br>',
            "New Confirmed Cases: ",
            round(comb()$positiveIncrease,0), '<br>',
            "New Deaths: ",
            round(comb()$deathIncrease,0))
    })
    
    pal <- colorNumeric(palette = "Reds", domain = NULL)
    
    
    
output$leaf <- renderLeaflet({
    comb() %>%
        sf::st_transform(crs = "+init=epsg:4326") %>%
        leaflet() %>%
        addProviderTiles(provider = "CartoDB.Positron",
                         options = providerTileOptions(minZoom = 3, maxZoom = 7)) %>%
        addPolygons(popup = content1(), group = "Cumulative, Per Million", fillColor= ~pal(Confirmed_cap),
                    stroke = FALSE, fillOpacity = 0.9,  smoothFactor = 0) %>%
        addPolygons(popup = content2(), group = "Cumulative, Absolute Numbers", fillColor= ~pal(positive),
                    stroke = FALSE, fillOpacity = 0.9,  smoothFactor = 0) %>%
        addPolygons(popup = content3(), group = "New Figures, Per Million", fillColor= ~pal(positiveIncrease_cap),
                    stroke = FALSE, fillOpacity = 0.9,  smoothFactor = 0) %>%
        addPolygons(popup = content4(), group = "New Figures, Absolute Numbers", fillColor= ~pal(positiveIncrease),
                    stroke = FALSE, fillOpacity = 0.9,  smoothFactor = 0) %>%
        addLayersControl(baseGroups = c("Cumulative, Per Million",
                                           "Cumulative, Absolute Numbers",
                                           "New Figures, Per Million",
                                           "New Figures, Absolute Numbers"))
        
})
   
}

# Run the application 
shinyApp(ui = ui, server = server)
