# site-marlenildo

Site pessoal de Marlenildo — galeria dos apps em R/Shiny publicados no
[Posit Connect Cloud](https://connect.posit.cloud): Plota, Calibra, Ranova,
Minhas Entregas e Croma.

Site estático (HTML + CSS + JS puro, sem build), publicado no domínio
`marlenildo.online` via GitHub Pages.

## Estrutura

- `index.html`: página única (hero, galeria de apps, sobre, contato).
- `assets/css/style.css`: tema dark com glassmorphism e gradientes.
- `assets/js/main.js`: menu mobile e animação de entrada dos cards.
- `assets/img/`: logos dos apps e favicon.
- `CNAME`: domínio customizado do GitHub Pages.

## Desenvolvimento local

Basta abrir `index.html` no navegador, ou servir a pasta com qualquer
servidor estático:

```bash
python -m http.server 8000
```

## Publicação

GitHub Pages publica direto da branch `main`, raiz do repositório.
O domínio `marlenildo.online` aponta para o GitHub Pages via DNS (registros
A/AAAA para apex + CNAME para `www`).
