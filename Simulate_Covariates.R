
library(spatstat)
library(ggplot2)
library(dplyr)
library(ggpubr)
library(viridis)

set.seed(42)

outpath <- getwd()

# Simulate Continuous Covariates ------------------------------------------

# Create a bounded domain on [0, 300] x [0, 300]

dim <- c(300, 300)

win <- owin(c(0,dim[1]), c(0,dim[2])) 

# set number of pixels
spatstat.options(npixel=c(dim[1],dim[2]))

# Create an artificial covariate
# create y0 and x0 separately as rectangle
y0 <- seq(win$yrange[1], win$yrange[2],
          length=spatstat.options()$npixel[2])
x0 <- seq(win$xrange[1], win$xrange[2],
          length=spatstat.options()$npixel[1])

# Covariate is a continuous gradient from the bottom to the top with values from 0 to 1
multiplier <- 1/dim[2]

gridcov1 <- outer(y0,x0, function (x,y) multiplier*x + 0*y)

gridcov2 <- outer(y0,x0, function (x,y) multiplier*y + 0*x)


c1 <- gridcov1 %>% 
  reshape2::melt(c("y", "x"), value.name = "cov") %>% 
  ggplot() + 
  geom_tile(aes(x = x, y = y, fill = cov)) + 
  scale_fill_viridis() +
  coord_fixed() + 
  theme_bw() + 
  theme(axis.title.x = element_blank(),
        axis.title.y = element_blank(),
        legend.ticks = element_blank(),
        legend.title = element_blank()) +
  ggtitle('Covariate 1')

c2 <- gridcov2 %>% 
  reshape2::melt(c("y", "x"), value.name = "cov") %>% 
  ggplot() + 
  geom_tile(aes(x = x, y = y, fill = cov)) + 
  scale_fill_viridis() +
  coord_fixed() + 
  theme_bw() + 
  theme(axis.title.x = element_blank(),
        axis.title.y = element_blank(),
        legend.ticks = element_blank(),
        legend.title = element_blank()) +
  ggtitle('Covariate 2')

plot1 <- ggarrange(c1, c2)
plot1
ggsave(plot = plot1, filename = paste0(outpath, "/output/Covariates_cont.png"), w = 21.5, h = 18, units = "cm", dpi = 400, device = "png")


# Simulate Spatial Covariates ---------------------------------------------

# library(geoR)
# 
# # cov.model is the covariance model, cov.pars is the parameters (partial sill, range parameter)
# # Currently using partial sill and range values from Muff et al., 2019 and default kappa / nugget
# cov1 <- grf(n = ncell(r), grid = "reg", nx = 300, ny = 300, xlims = c(0,300), ylims = c(0,300), cov.model = "matern", cov.pars=c(50,0.1), kappa = 0.5, nugget = 0)


# Following the approach of Fletcher Jr. et al. (2023) and Grimmett et al. (2021), we use the NLMR package.
# Create simulated habitat using Gaussian random fields within a 100 x 100 grid


# First install NLMR
# remotes::install_github("ropensci/NLMR")
# install.packages("landscapetools")

library(NLMR)
library(landscapetools)
library(RandomFields) # Note that RandomFields is no longer on CRAN. Downloaded archived file.
library(terra)

cov1 <- nlm_gaussianfield(ncol = 300,
                          nrow = 300,
                          resolution = 1,
                          autocorr_range = 50, # Maximum range (raster units) of spatial autocorrelation
                          mag_var = 1, # Magnitude of variation over the landscape
                          nug = 0.01, # Magnitude of variation in the scale of the autocorr_range (smaller values = more homogenous)
                          mean = 0.5, # Mean value over the field
                          user_seed = 2L, # Set random seed for the simulation
                          rescale = T # If T, the values are rescaled between 0 and 1
                          ) %>% 
  rast()

cov2 <- nlm_gaussianfield(ncol = 300,
                          nrow = 300,
                          resolution = 1,
                          autocorr_range = 50, # Maximum range (raster units) of spatial autocorrelation
                          mag_var = 1, # Magnitude of variation over the landscape
                          nug = 0.01, # Magnitude of variation in the scale of the autocorr_range (smaller values = more homogenous)
                          mean = 0.5, # Mean value over the field
                          user_seed = 3L, # Set random seed for the simulation
                          rescale = T # If T, the values are rescaled between 0 and 1
) %>% 
  rast()


c1 <- cov1 %>% 
  as.data.frame(xy = T) %>%  
  ggplot() + 
  geom_tile(aes(x = x, y = y, fill = layer)) + 
  scale_fill_viridis() +
  coord_fixed() + 
  theme_bw() + 
  theme(axis.title.x = element_blank(),
        axis.title.y = element_blank(),
        legend.ticks = element_blank(),
        legend.title = element_blank()) +
  ggtitle('Covariate 1')

c2 <- cov2 %>% 
  as.data.frame(xy = T) %>%  
  ggplot() + 
  geom_tile(aes(x = x, y = y, fill = layer)) + 
  scale_fill_viridis() +
  coord_fixed() + 
  theme_bw() + 
  theme(axis.title.x = element_blank(),
        axis.title.y = element_blank(),
        legend.ticks = element_blank(),
        legend.title = element_blank()) +
  ggtitle('Covariate 2')

plot2 <- ggarrange(c1, c2)
plot2 
ggsave(plot = plot2, filename = paste0(outpath, "/output/Covariates_GRF.png"), w = 21.5, h = 18, units = "cm", dpi = 400, device = "png")