


newdat <- as.data.frame(with(StriperAll[StriperAll$Sex %in% 'M' & StriperAll$Age > 2,], table(RelYear, Age)),
                        stringsAsFactors = F)



head(newdat)

plot(Freq ~ Age, data = newdat, col = "grey80")
ss <- smooth.spline(newdat$Age, newdat$Freq)
lw <- loess(formula = Freq ~ Age, data = newdat)
mod <- glm(Freq ~ as.numeric(Age), family = poisson, data = newdat)
lines(predict(ss, Age = 3:20), col = 4)
lines(predict(lw, data.frame(Age = 3:20)), col = 3)
lines(exp(predict(mod, data.frame(Age = 3:20))), col = 2)

scatter.smooth(newdat$Age, newdat$Freq)

yx <- function(lx) 0.5 * log((1 - lx) / lx)

testDat <- rbind(data.frame(Sex = "M", Map(LifeTable, nx)$`1982.GN.M`[, c("x", "nx")]),
                 data.frame(Sex = "F", Map(LifeTable, nx)$`1982.GN.F`[, c("x", "nx")]))

testDat$x <- as.numeric(testDat$x)

# ********************************************************************

# code between ** written 06-Jul-2017 - trying to understand difference in
# various models or smoothers; smoother.spline could work but need to educate
# myself more on usage & function parameters

sex <- 'M'
mod_form <- as.formula(nx ~ x)

# loess model
mod_loess <- loess(mod_form, data = testDat, subset = Sex %in% sex)
summary(mod_loess)
residuals(mod_loess)
fitted(mod_loess)

(rss_loess <- sum(residuals(mod_loess)^2))
predict(mod_loess, newdata = data.frame(x = 4:16))

# smoother spline model - need to play with df & other args
# df = 11 overfits data
mod_spline <- smooth.spline(
  x = testDat$x[testDat$Sex %in% sex],
  y = testDat$nx[testDat$Sex %in% sex],
  df = 10
)

summary(mod_spline)
residuals(mod_spline)
fitted(mod_spline)

(rss_spline <- sum(residuals(mod_spline)^2))
predict(mod_spline, newdata = data.frame(x = 4:16))

# glm model with family = poisson
mod_glm <- glm(
  mod_form,
  family = poisson,
  data = testDat,
  subset = Sex %in% sex
)

summary(mod_glm)
residuals(mod_glm)
fitted(mod_glm)

(rss_glm <- sum(residuals(mod_glm)^2))
exp(predict(mod_glm, newdata = data.frame(x = 4:16)))

# display data points & model fits
plot(mod_form, data = testDat, subset = Sex %in% sex, col = "grey60")
lines(testDat$x[testDat$Sex %in% sex], fitted(mod_loess), col = 3)
lines(mod_spline, col = 4)
lines(testDat$x[testDat$Sex %in% sex], fitted(mod_glm), col = "orange")

# ********************************************************************





yx(testDat$lx)

ggplot(data = testDat, mapping = aes(x = x, y = lx, group = Sex)) +
  geom_point(mapping = aes(colour = Sex), alpha = 1/2, size = 4) +
  geom_smooth(mapping = aes(colour = Sex), method = "gam", se = FALSE)

plot(nx ~ x, data = testDat)
lines(fitted(loess(formula = nx ~ x, data = testDat[testDat$Sex %in% 'F', ])), col = 4)
lines(fitted(loess(formula = nx ~ x, data = testDat[testDat$Sex %in% 'M', ])), col = 3)

testgam <- mgcv::gam(lx ~ s(x), data = testDat)

testglm <- glm(lx ~ x, data = testDat)

plot(testgam, residuals = T, all.terms = T, shade = T, shade.col = 2)


HazFun <- function(q, x) {
  
  i <- seq_along(x)
  
  x <- as.numeric(x)
  
  b <- x[i + 1] - x[i]
  
  b[is.na(b)] <- 1
  
  (q * 2) / (b * (1 + (1 - q)))

}

test <- Map(LifeTable, nx)$`1969.GN.M`[, c("x", "qx")]

plot(test$x, HazFun(test$qx, x = test$x))


