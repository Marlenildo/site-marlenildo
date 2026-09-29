# Gera os graficos ilustrativos (dados ficticios) usados na secao "Sobre mim"
# do site. Nao usa nenhum dado real de cliente.

library(ggplot2)
library(scales)
library(ggdendro)

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

## 3) Regressao: ajuste linear x quadratico, com equacao e R2 -------------
set.seed(3)
dose_c <- c(0, 50, 100, 150, 200, 250)
resp <- c(15.0, 19.4, 24.7, 27.2, 26.4, 22.8)

mod_quad <- lm(resp ~ dose_c + I(dose_c^2))
b_quad <- coef(mod_quad)
r2_quad <- summary(mod_quad)$r.squared
curva_quad <- data.frame(dose_c = seq(0, 250, length.out = 200))
curva_quad$pred <- predict(mod_quad, newdata = curva_quad)
curva_quad$tipo <- "Quadrática"
eq_quad <- sprintf("Quadrática: y = %.1f + %.3fx − %.5fx²  (R² = %.2f)", b_quad[1], b_quad[2], abs(b_quad[3]), r2_quad)

mod_lin <- lm(resp ~ dose_c)
b_lin <- coef(mod_lin)
r2_lin <- summary(mod_lin)$r.squared
curva_lin <- data.frame(dose_c = seq(0, 250, length.out = 200))
curva_lin$pred <- predict(mod_lin, newdata = curva_lin)
curva_lin$tipo <- "Linear"
eq_lin <- sprintf("Linear: y = %.1f + %.3fx  (R² = %.2f)", b_lin[1], b_lin[2], r2_lin)

curvas <- rbind(curva_quad, curva_lin)

p3 <- ggplot() +
  geom_point(data = data.frame(dose_c, resp), aes(dose_c, resp), colour = texto, size = 3, alpha = 0.85) +
  geom_line(data = curvas, aes(dose_c, pred, colour = tipo, linetype = tipo), linewidth = 1.05) +
  annotate("text", x = 125, y = max(curvas$pred) * 1.22, label = eq_quad, colour = azul, size = 3.6) +
  annotate("text", x = 125, y = max(curvas$pred) * 1.13, label = eq_lin, colour = verde, size = 3.6) +
  scale_colour_manual(values = c("Quadrática" = azul, "Linear" = verde)) +
  scale_linetype_manual(values = c("Quadrática" = "solid", "Linear" = "22")) +
  scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.3))) +
  labs(x = "Dose (kg ha⁻¹)", y = "Produtividade (t ha⁻¹)", colour = NULL, linetype = NULL) +
  tema_site
salvar(p3, "chart-regressao.svg")

## 4) PCA — biplot com autovetores (loadings) -----------------------------
set.seed(4)
n <- 18
grp <- rep(c("Grupo 1", "Grupo 2"), each = n / 2)
X <- data.frame(
  Altura   = c(rnorm(n/2, 10, 1.4), rnorm(n/2, 13.5, 1.4)),
  Diametro = c(rnorm(n/2, 5, 1),    rnorm(n/2, 7.6, 1)),
  Brix     = c(rnorm(n/2, 20, 2.4), rnorm(n/2, 17.5, 2.2)),
  Massa    = c(rnorm(n/2, 3, 0.6),  rnorm(n/2, 4.4, 0.7))
)
pca <- prcomp(X, scale. = TRUE)
scores <- as.data.frame(pca$x[, 1:2])
scores$grupo <- grp
ve <- round(100 * summary(pca)$importance[2, 1:2], 1)

esc <- 4.4
loadings <- as.data.frame(pca$rotation[, 1:2]) * esc
loadings$var <- rownames(loadings)

p4 <- ggplot(scores, aes(PC1, PC2)) +
  stat_ellipse(aes(colour = grupo, fill = grupo), geom = "polygon", alpha = 0.10, colour = NA, level = 0.8) +
  geom_point(aes(colour = grupo), size = 3) +
  geom_segment(data = loadings, aes(x = 0, y = 0, xend = PC1, yend = PC2), inherit.aes = FALSE,
               colour = texto, linewidth = 0.6, arrow = arrow(length = unit(0.16, "cm"), type = "closed")) +
  geom_text(data = loadings, aes(x = PC1 * 1.18, y = PC2 * 1.18, label = var), inherit.aes = FALSE,
            colour = texto, fontface = "bold", size = 3.7) +
  scale_colour_manual(values = c("Grupo 1" = azul, "Grupo 2" = verde)) +
  scale_fill_manual(values = c("Grupo 1" = azul, "Grupo 2" = verde)) +
  labs(x = paste0("PC1 (", ve[1], "%)"), y = paste0("PC2 (", ve[2], "%)")) +
  tema_site
salvar(p4, "chart-pca.svg")

## 5) Cluster — dendrograma de agrupamento --------------------------------
set.seed(5)
acessos <- data.frame(
  produtividade = rnorm(10, 22, 4),
  brix          = rnorm(10, 11, 1.6),
  firmeza       = rnorm(10, 6, 1.1)
)
rownames(acessos) <- paste("Acesso", 1:10)
hc <- hclust(dist(scale(acessos)), method = "ward.D2")
dd <- dendro_data(hc)

p5 <- ggplot() +
  geom_segment(data = dd$segments, aes(x = x, y = y, xend = xend, yend = yend), colour = azul, linewidth = 0.7) +
  geom_text(data = dd$labels, aes(x = x, y = -0.35, label = label), colour = mutedcolor,
            angle = 90, hjust = 1, size = 3.3) +
  scale_y_continuous(expand = expansion(mult = c(0.32, 0.08))) +
  labs(x = NULL, y = "Distância") +
  tema_site +
  theme(axis.text.x = element_blank(), axis.ticks.x = element_blank(), panel.grid.major.x = element_blank())
salvar(p5, "chart-cluster.svg", h = 4.15)

## 6) Regressao logistica (resposta sim/nao) ------------------------------
set.seed(6)
conc <- rep(seq(0, 140, by = 20), each = 6)
prob_real <- plogis(-3 + 0.055 * conc)
germinou <- rbinom(length(conc), 1, prob_real)
dfl <- data.frame(conc, germinou)
modl <- glm(germinou ~ conc, data = dfl, family = binomial)
curval <- data.frame(conc = seq(0, 140, length.out = 200))
curval$prob <- predict(modl, newdata = curval, type = "response")

p6 <- ggplot() +
  geom_point(data = dfl, aes(conc, germinou), colour = verde, size = 2.3, alpha = 0.6,
             position = position_jitter(height = 0.045, width = 2)) +
  geom_line(data = curval, aes(conc, prob), colour = azul, linewidth = 1.1) +
  scale_y_continuous(labels = percent_format(accuracy = 1), limits = c(-0.05, 1.05)) +
  labs(x = "Concentração (mg L⁻¹)", y = "Probabilidade de germinação") +
  tema_site
salvar(p6, "chart-logistica.svg")

## 7) Agrupamento k-means (com centroides) --------------------------------
set.seed(7)
n_por_grupo <- 20
kdf <- data.frame(
  brix   = c(rnorm(n_por_grupo, 9, 0.7),   rnorm(n_por_grupo, 13, 0.7),   rnorm(n_por_grupo, 16.5, 0.8)),
  acidez = c(rnorm(n_por_grupo, 1.15, 0.15), rnorm(n_por_grupo, 0.55, 0.12), rnorm(n_por_grupo, 0.32, 0.08))
)
mu <- colMeans(kdf); sdv <- apply(kdf, 2, sd)
kdf_s <- scale(kdf, center = mu, scale = sdv)
km <- kmeans(kdf_s, centers = 3, nstart = 10)
kdf$cluster <- factor(km$cluster)
centros <- as.data.frame(sweep(sweep(km$centers, 2, sdv, `*`), 2, mu, `+`))

cores3 <- setNames(c(azul, verde, "#ff5fa2"), levels(kdf$cluster))

p7 <- ggplot(kdf, aes(brix, acidez, colour = cluster, fill = cluster)) +
  stat_ellipse(geom = "polygon", alpha = 0.10, colour = NA, level = 0.8) +
  geom_point(size = 2.6, alpha = 0.85) +
  geom_point(data = centros, aes(brix, acidez), inherit.aes = FALSE, shape = 4, size = 5,
             stroke = 1.5, colour = texto) +
  scale_colour_manual(values = cores3, guide = "none") +
  scale_fill_manual(values = cores3, guide = "none") +
  labs(x = "Teor de sólidos solúveis (°Brix)", y = "Acidez titulável (%)") +
  tema_site
salvar(p7, "chart-kmeans.svg")

cat("OK\n")
