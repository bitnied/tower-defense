# Deploy no GitHub Pages

O build web fica em `docs/` (gerado pelo preset "Web" do Godot).

## Publicação (uma vez)

1. Crie um repositório no GitHub (ex.: `tower-defense`).
2. Envie este projeto para o repositório:
   ```sh
   git remote add origin git@github.com:SEU_USUARIO/tower-defense.git
   git push -u origin main
   ```
3. No GitHub: **Settings → Pages → Build and deployment**
   - Source: *Deploy from a branch*
   - Branch: `main`, pasta `/docs`
4. O jogo ficará em `https://SEU_USUARIO.github.io/tower-defense/`

## Atualizar o build

Sempre que alterar o jogo:

```sh
"/Applications/Godot.app/Contents/MacOS/Godot" --headless --export-release "Web" docs/index.html
git add -A && git commit -m "Update web build" && git push
```

## Notas técnicas

- Export **sem threads** (`variant/thread_support=false`): funciona no GitHub Pages
  (que não envia headers COOP/COEP) e no Safari do iOS.
- Renderer **GL Compatibility**: obrigatório para web e ideal para GPUs mobile.
- PWA habilitado: no iPhone/iPad, use **Compartilhar → Adicionar à Tela de Início**
  para jogar em tela cheia, sem a barra do Safari.
- Stretch `canvas_items` + aspect `expand`: preenche qualquer proporção de tela
  (iPhone 11/13/17e ~19.5:9, iPad Air ~4.3:3) sem barras pretas.
