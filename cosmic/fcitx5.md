# COSMIC: tasti morti (us+intl) in Ghostty con fcitx5

## Problema

Desktop COSMIC (Wayland), layout `us` variante `intl` (tasti morti: `` ` `` + spazio → `` ` ``, `` ` `` + e → è).
In Ghostty il backtick non usciva; in COSMIC Terminal sì.

## Causa

- COSMIC Terminal (iced/winit) compone i tasti morti da sé con libxkbcommon.
- Ghostty (GTK4) delega la composizione al modulo di input GTK: su Wayland, dato che
  cosmic-comp espone `text-input-v3`, GTK sceglie il modulo `wayland`, che si aspetta un
  input method lato compositor. Senza ibus/fcitx attivi il tasto morto si perde.

## Soluzione: fcitx5

cosmic-comp supporta `input-method-v2`, quindi fcitx5 si aggancia in modo nativo
(log: `Using Wayland native input method protocol`). ibus su Wayland fuori da GNOME è più fragile.

```sh
task cosmic:fcitx5   # poi logout/login
```

La task fa:

1. `sudo pacman -S --needed fcitx5 fcitx5-gtk fcitx5-qt fcitx5-configtool`
   (l'autostart arriva dal pacchetto: `/etc/xdg/autostart/org.fcitx.Fcitx5.desktop`)
2. copia [`fcitx5/profile`](fcitx5/profile) in `~/.config/fcitx5/profile`
   (metodi di input `keyboard-us-intl` e `keyboard-it`, gli stessi layout di COSMIC;
   si passa dall'uno all'altro con Ctrl+Space o dall'icona di fcitx5, non dal selettore
   dei layout di COSMIC, perché fcitx5 prende in carico la tastiera)
3. copia [`fcitx5/fcitx5.conf`](fcitx5/fcitx5.conf) in `~/.config/environment.d/fcitx5.conf`:
   - **niente `GTK_IM_MODULE`**: GTK3/GTK4 usano il protocollo Wayland `text-input-v3`
   - `QT_IM_MODULES=wayland;fcitx`, `QT_IM_MODULE=fcitx` (Qt)
   - `XMODIFIERS=@im=fcitx` (app X11/XWayland), `SDL_IM_MODULE=fcitx`
4. toglie `~/.config/environment.d/gtk-im.conf` se presente (vedi sotto)

Prova senza logout: `fcitx5 -d --replace`, poi `ghostty --gtk-single-instance=false`
(l'istanza unica di Ghostty già aperta conserva il vecchio ambiente).

## Verifica dopo il login

```sh
pgrep -a fcitx5
systemctl --user show-environment | grep -E 'IM_MODULE|XMODIFIERS'
```

Se fcitx5 non parte, COSMIC non ha eseguito l'autostart di sistema: copiare il `.desktop`
in `~/.config/autostart/`.

## Alternative

- **Senza input method**: `GTK_IM_MODULE=simple` in `~/.config/environment.d/gtk-im.conf`
  (GTK compone da sé i tasti morti). Basta se servono solo gli accenti; incompatibile con fcitx5.
- **Ripiego GTK con fcitx5**: `GTK_IM_MODULE=fcitx` (modulo di `fcitx5-gtk`) se il percorso
  Wayland nativo dà problemi.

## Stato (2026-11-24, lenovo)

- Verificato: Ghostty e COSMIC Terminal compongono i tasti morti con fcitx5 avviato a mano.
- Da verificare: avvio automatico di fcitx5 e variabili caricate dopo logout/login.

## Stato (2026-11-24, hp)

- Layout COSMIC `us` intl + `it`: profile con `keyboard-us-intl` e `keyboard-it`.
- Verificato: tasti morti e passaggio a `it` con Ctrl+Space, con fcitx5 avviato a mano.

## Stato (2026-11-24, t14)

- Non applicato: in COSMIC c'è solo il layout `it`, quindi niente tasti morti da comporre.
  Il `profile` del repo metterebbe `us-intl` come predefinito.
