# site-marlenildo

Site pessoal de Marlenildo — galeria dos apps em R/Shiny publicados no
[Posit Connect Cloud](https://connect.posit.cloud): Plota, Calibra, Ranova,
Minhas Entregas e Croma.

Site estático (HTML + CSS + JS puro, sem build), publicado no domínio
`marlenildo.online` via GitHub Pages.

## Estrutura

- `index.html`: página inicial (hero, galeria de apps, chamada do guia, sobre, contato).
- `guia.html` e `guia-*.html`: guia prático de estatística experimental, em etapas.
- `r-para-pesquisa.html`: primeiros passos no R (parte do guia).
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

O GitHub Pages é publicado pelo workflow `.github/workflows/pages.yml`
(Settings → Pages → Source: **GitHub Actions**):

| Branch | Endereço | Uso |
|---|---|---|
| `main` | https://marlenildo.online/ | site publicado |
| `dev`  | https://marlenildo.online/dev/ | pré-visualização (fora dos buscadores, sem anúncios) |

Fluxo: trabalho numa branch de feature → merge na `dev` → conferir em `/dev/` →
merge da `dev` na `main`. Qualquer push em `main` ou `dev` reconstrói as duas versões.

O domínio `marlenildo.online` aponta para o GitHub Pages via DNS (registros
A/AAAA para apex + CNAME para `www`).
