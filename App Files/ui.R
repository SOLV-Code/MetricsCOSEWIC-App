

# Think it needs these here for the server deployment
# shiny deployment looks for library(), so need that too in order to get the dependencies)
source("R/3c_HelperFunctions_ModelSetup.R")
source.modules("R/")
load_or_install(c("ggplot2","DT","markdown","rmarkdown","shiny","shinydashboard","shinyjqui","shinyFiles"))
library("ggplot2")
library("DT")
library("markdown")
library("rmarkdown")
library("shiny")
library("shinydashboard")
library("shinyjqui")
library("shinyFiles")
library("shinybusy")








navbarPage("MetricsCOSEWIC", id = "MainTab",


	 tabPanel("Disclaimer",

fluidPage(

  titlePanel("Disclaimer"),

  fluidRow(
    column(8,
	  includeMarkdown("Markdown/disclaimer.md")
    )
  )
)



	  ),  # end Help tab panel




#######
 tabPanel("Data Loading", value= "data.loading",

pageWithSidebar(
  headerPanel("Data Loading"),

  sidebarPanel(
			  tags$h4("Data File"),
			  tags$hr(),
			  fileInput("file.name.2", "Choose CSV File", accept = c("text/csv","text/comma-separated-values,text/plain", ".csv")    ),
			  tags$hr() ,
			  tags$a("Get Some Sample Data",href="https://drive.google.com/drive/folders/1y1d0TF8v2kWWbHXkTaK0mb3BQjUc7xrZ?usp=sharing",target="_blank")
			) # end sidebar
  ,

     mainPanel(

			div(style = "height:500px; overflow-y: scroll;overflow-x: scroll;",
					tableOutput("inputheader.table"),height = "400px",width = "200px")


		) # end main panel

		) #end page with side bar for  data loading
  ),  # end  second tab panel





#######
tabPanel("General Settings", value= "general.settings",

				 tags$h4("Any overarching settings we want to put here?"),

				 #tags$h4("Data Treatment Settings"),
				 #	checkboxInput("cov.rescale", label="SibReg Complex: Rescale Covariates?", value = TRUE ),
				 #tags$h4("Display Settings"),
				 #numericInput("table.decimals", label=h5("Number of Decimals shown in tables and figures (NOT YET LINKED)"),
				 #						 value = 0 , min = 0, max = 10, step = 1,   width = "40%"),
				 #textInput("axis.label", label=h5("Forecasted Variable"), value = "Abundance", width = "40%"),
				 #checkboxInput("show.equ","Show model equations in figures (not linked yet)",value=FALSE)
				 #uiOutput("axis.label.sel")

),  # end  general settings panel



####################################


tabPanel("Explore Annual Estimates", value= "probdecl",


				 pageWithSidebar(
				 	headerPanel("Explore Annual Estimates"),

				 	sidebarPanel(
				 		add_busy_spinner(spin = "fading-circle"),
				 		uiOutput("du.list.menu"),
				 		numericInput("abd.rescale", "Scalar", value=1),
				 		textInput("abd.label", "Abd Label", value = "Abundance", width = "80%"),
				 		uiOutput("time.window.slider"),
				 		uiOutput("endyr.slider")

				 	) # end sidebar
				 	,


				 	mainPanel(


				 		tabsetPanel(type = "tabs",
				 								tabPanel("Full Time Series",
				 												 plotOutput("plot.full.series",width = "100%", height = "600px")),
				 								tabPanel("Fitted Trend"),
				 								tabPanel("Probability of Decline"),
				 								tabPanel("MCMC Diagnostics")



				 		) # end tabsetpanel
				 	) # end main panel

				 ) #end page with side bar for model pre-check



),


######################################




tabPanel("Run Retrospective Test", value= "retrospective",


				 pageWithSidebar(
				 	headerPanel("Retrospective"),

				 	sidebarPanel(

				 	) # end sidebar
				 	,


				 	mainPanel(


				 	) # end main panel

				 ) #end page with side bar for model pre-check



),

####################################


	 tabPanel("Help",  value= "help.panel",

fluidPage(

  titlePanel("Help Page"),

  fluidRow(
    column(8,
	  includeMarkdown("Markdown/help.md")
    )
  )
)



	  ),  # end Help tab panel

	tabPanel("About",

fluidPage(

  titlePanel("About ForecastR"),

  fluidRow(
    column(8,
      includeMarkdown("Markdown/about.md")
    )
  )
)
	  )  # end about tab panel



) # end navbar Page

