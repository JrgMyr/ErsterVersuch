# Bild 001
# Joerg Meyer, 2011-08-15

b <- function(n) {
    source(paste("Bild_", substr(as.character(1000 + n), 2, 4), ".R", sep=""))
}

origmar = par(bg = "wheat",
              oma = c(1, 1, 0, 0),
              mar = c(0, 0, 0, 0))

plot(x = 1:1000, y = 1:1000, type = "n",
     xlab = "", ylab = "", axes = FALSE)

xl <- c( 50,  45)
yu <- c(150, 148)
xr <- c(970, 960)
yo <- c(190, 185)
cl <- c("black", "olivedrab")

rect(xl, yu, xr, yo, col = cl, border = NA)

n <- 15

xl <- seq(0, 60 * n, by=60)
yu <- sin(c(0:n) * 0.1 * pi - 0.3) * 200 + 100
xr <- xl + 40
yo <- c(7, 8, 10, 9, 7, 5, 5.1, 6, 7, 8, 10, 9, 7, 5, 3, 0) * 100
# cl <- rainbow(n)
cl <- heat.colors(n)

rect(xl, yu, xr, yo, col = cl, border = NA)

text(950, 1000, "Bild 1\nJMy '11", cex = 0.8)

par(origmar)

