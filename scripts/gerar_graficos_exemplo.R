# Gera os graficos ilustrativos (dados ficticios) usados na secao "Sobre mim"
# do site. Nao usa nenhum dado real de cliente.

library(ggplot2)
library(scales)

out_dir <- "assets/img/examples"
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

azul  <- "#7c5cff"
verde <- "#22d3ee"
texto <- "#eef0f6"
mutedcolor <- "#9aa0b4"
grade <- "#ffffff"

tema_site <- theme_minimal(base_size = 15) +
  theme(
    plot.background   = element_rect(fill = NA, colour = NA),
    panel.background  = element_rect(fill = NA, colour = NA),
    panel.grid.major  = element_line(colour = alpha(grade, 0.09), linewidth = 0.4),
    panel.grid.minor  = element_blank(),
    axis.line         = element_line(colour = alpha(grade, 0.35), linewidth = 0.5),
    axis.ticks        = element_line(colour = alpha(grade, 0.35), linewidth = 0.4),
    axis.text         = element_text(colour = mutedcolor, size = 12),
    axis.title        = element_text(colour = mutedcolor, size = 13),
    legend.position   = "top",
    legend.title      = element_blank(),
    legend.text       = element_text(colour = mutedcolor, size = 12),
    legend.key        = element_rect(fill = NA, colour = NA),
    plot.margin       = margin(10, 14, 6, 6)
  )

salvar <- function(p, nome, w = 5.6, h = 3.9) {
  ggsave(file.path(out_dir, nome), p, width = w, height = h, dpi = 220,
         bg = "transparent", device = "svg")
}

# Poe degrade + cantos arredondados nas barras de um SVG do ggplot2, sem tocar
# na posicao/altura calculada (preserva os dados reais do grafico).
aplicar_degrade_barras <- function(path, cor_fill, cor_topo, cor_base, raio = 6) {
  txt <- paste(readLines(path, warn = FALSE), collapse = "\n")

  grad_id <- "barGradExemplo"
  grad_def <- sprintf(
    "<defs><linearGradient id='%s' x1='0' y1='0' x2='0' y2='1'><stop offset='0%%' stop-color='%s'/><stop offset='100%%' stop-color='%s'/></linearGradient></defs>",
    grad_id, cor_topo, cor_base
  )
  txt <- sub("(<svg[^>]*>)", paste0("\\1", grad_def), txt)

  pattern <- "<rect x='([0-9.]+)' y='([0-9.]+)' width='([0-9.]+)' height='([0-9.]+)' style='([^']*)' />"
  ms <- gregexpr(pattern, txt, perl = TRUE)
  matches <- regmatches(txt, ms)[[1]]

  for (full in matches) {
    if (!grepl(cor_fill, full, fixed = TRUE)) next
    g <- regmatches(full, regexec(pattern, full, perl = TRUE))[[1]]
    x <- as.numeric(g[2]); y <- as.numeric(g[3]); w <- as.numeric(g[4]); h <- as.numeric(g[5])
    x0 <- x; x1 <- x + w; ytop <- y; ybase <- y + h; r <- min(raio, w / 2, h / 2)
    d <- sprintf(
      "M%.2f,%.2f L%.2f,%.2f Q%.2f,%.2f %.2f,%.2f L%.2f,%.2f Q%.2f,%.2f %.2f,%.2f L%.2f,%.2f Z",
      x0, ybase, x0, ytop + r, x0, ytop, x0 + r, ytop,
      x1 - r, ytop, x1, ytop, x1, ytop + r, x1, ybase
    )
    replacement <- sprintf("<path d='%s' style='stroke-width: 1.45; stroke: none; fill: url(#%s);' />", d, grad_id)
    txt <- sub(full, replacement, txt, fixed = TRUE)
  }

  writeLines(txt, path)
}

## 1) Barras com erro + letras (Tukey) ---------------------------------
set.seed(1)
df1 <- data.frame(
  dose = factor(c("0", "50", "100", "150"), levels = c("0", "50", "100", "150")),
  media = c(18.2, 24.1, 30.8, 27.3),
  se = c(1.6, 1.9, 2.1, 1.8),
  letra = c("c", "b", "a", "ab")
)

p1 <- ggplot(df1, aes(dose, media)) +
  geom_col(fill = azul, width = 0.6) +
  geom_errorbar(aes(ymin = media - se, ymax = media + se), width = 0.16, colour = texto, linewidth = 0.6) +
  geom_text(aes(y = media + se + 1.6, label = letra), colour = texto, fontface = "bold", size = 4.6) +
  scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.12))) +
  labs(x = "Dose (kg ha⁻¹)", y = "Produtividade (t ha⁻¹)") +
  tema_site
salvar(p1, "chart-barras-erro.svg")
aplicar_degrade_barras(file.path(out_dir, "chart-barras-erro.svg"),
                        cor_fill = toupper(azul), cor_topo = verde, cor_base = azul)

## 2) Linhas com erro, dois grupos --------------------------------------
set.seed(2)
semana <- 1:6
df2 <- data.frame(
  semana = rep(semana, 2),
  grupo = rep(c("Tratamento A", "Tratamento B"), each = 6),
  media = c(12, 15.5, 19, 23.5, 27, 30.2,   11, 13, 15.4, 17.1, 18.6, 19.8),
  se = c(0.9, 1.1, 1.0, 1.3, 1.2, 1.4,      0.8, 0.9, 1.0, 1.0, 1.1, 1.2)
)

p2 <- ggplot(df2, aes(semana, media, colour = grupo, group = grupo)) +
  geom_errorbar(aes(ymin = media - se, ymax = media + se), width = 0.12, linewidth = 0.6, alpha = 0.85) +
  geom_line(linewidth = 1.1) +
  geom_point(size = 2.6) +
  scale_colour_manual(values = c("Tratamento A" = azul, "Tratamento B" = verde)) +
  scale_x_continuous(breaks = semana) +
  labs(x = "Semana", y = "Altura de planta (cm)") +
  tema_site
salvar(p2, "chart-linhas-erro.svg")

## 3) Regressao com equacao e R2 -----------------------------------------
set.seed(3)
dose_c <- c(0, 50, 100, 150, 200, 250)
resp <- c(15.0, 19.4, 24.7, 27.2, 26.4, 22.8)
mod <- lm(resp ~ dose_c + I(dose_c^2))
b <- coef(mod)
r2 <- summary(mod)$r.squared
curva <- data.frame(dose_c = seq(0, 250, length.out = 200))
curva$pred <- predict(mod, newdata = curva)
eq_lbl <- sprintf("y = %.1f + %.3fx - %.5fx^2   R^2 = %.2f", b[1], b[2], abs(b[3]), r2)

p3 <- ggplot() +
  geom_line(data = curva, aes(dose_c, pred), colour = azul, linewidth = 1.1) +
  geom_point(data = data.frame(dose_c, resp), aes(dose_c, resp), colour = verde, size = 3.2) +
  annotate("text", x = 125, y = max(curva$pred) * 1.09, label = eq_lbl, colour = mutedcolor, size = 4.1) +
  scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.18))) +
  labs(x = "Dose (kg ha⁻¹)", y = "Produtividade (t ha⁻¹)") +
  tema_site
salvar(p3, "chart-regressao.svg")

## 4) PCA (scores PC1 x PC2 com elipses) ---------------------------------
set.seed(4)
n <- 18
grp <- rep(c("Grupo 1", "Grupo 2"), each = n / 2)
X <- data.frame(
  v1 = c(rnorm(n/2, 10, 1.4), rnorm(n/2, 13.5, 1.4)),
  v2 = c(rnorm(n/2, 5, 1),    rnorm(n/2, 7.6, 1)),
  v3 = c(rnorm(n/2, 20, 2.4), rnorm(n/2, 17.5, 2.2)),
  v4 = c(rnorm(n/2, 3, 0.6),  rnorm(n/2, 4.4, 0.7))
)
pca <- prcomp(X, scale. = TRUE)
scores <- as.data.frame(pca$x[, 1:2])
scores$grupo <- grp
ve <- round(100 * summary(pca)$importance[2, 1:2], 1)

p4 <- ggplot(scores, aes(PC1, PC2, colour = grupo, fill = grupo)) +
  stat_ellipse(geom = "polygon", alpha = 0.12, colour = NA, level = 0.8) +
  geom_point(size = 3) +
  scale_colour_manual(values = c("Grupo 1" = azul, "Grupo 2" = verde)) +
  scale_fill_manual(values = c("Grupo 1" = azul, "Grupo 2" = verde)) +
  labs(x = paste0("PC1 (", ve[1], "%)"), y = paste0("PC2 (", ve[2], "%)")) +
  tema_site
salvar(p4, "chart-pca.svg")

cat("OK\n")
