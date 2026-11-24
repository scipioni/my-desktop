# COSMIC: applet system monitor nel pannello (minimon)

COSMIC System Monitor (`cosmic-monitor`) è un'app, non un applet del pannello.
Per avere CPU/memoria/rete/disco/GPU nel pannello si usa
[minimon](https://github.com/cosmic-utils/cosmic-ext-applet-minimon) (AUR `cosmic-ext-applet-minimon`,
compila da sorgente con cargo; esiste anche `-bin`).

```sh
task cosmic:minimon
```

La task:

1. installa `cosmic-ext-applet-minimon` con yay (rimuove poi le makedepends);
2. aggiunge `io.github.cosmic_utils.minimon-applet` come primo applet della parte destra del pannello,
   in `~/.config/cosmic/com.system76.CosmicPanel.Panel/v1/plugins_wings`
   (se il file manca parte dal default in `/usr/share/cosmic/...`; non fa nulla se c'è già).

Il pannello rilegge la configurazione da solo: l'applet compare senza logout.
Cosa mostrare si sceglie cliccando sull'applet; la posizione da
Impostazioni → Desktop → Pannello → Configura applet.

## GPU NVIDIA: usare la versione nativa, non il Flatpak

Esiste anche un Flatpak con lo stesso id (`io.github.cosmic_utils.minimon-applet`, remote `cosmic`).
Se sono installati entrambi, il pannello avvia il **Flatpak** (`~/.local/share/flatpak/exports/share` viene
prima di `/usr/share` in `XDG_DATA_DIRS`). Il Flatpak vede la GPU NVIDIA solo se l'estensione
`org.freedesktop.Platform.GL.nvidia-<versione>` corrisponde esattamente al driver del sistema; altrimenti
nel journal compare `libnvidia-ml.so.1: cannot open shared object file` e la GPU non appare.

Soluzione: tenere solo il pacchetto nativo, che usa la `libnvidia-ml.so` del sistema.

```sh
flatpak uninstall --user io.github.cosmic_utils.minimon-applet
pkill -x cosmic-panel   # cosmic-session lo riavvia e lancia l'applet nativo
```

Verifica: `journalctl --user -b | grep -i 'minimon.*NVML'` → `Successfully connected to NVML`.

## Stato (2026-11-24, lenovo)

- Verificato: rimosso il Flatpak, l'applet nativo trova la RTX 3060 via NVML.

- Verificato: minimon 1.3.0 compilato e in esecuzione nel pannello.
- Verificato: la modifica di `plugins_wings` funziona sia sul formato del default di sistema sia sul file
  già personalizzato (prova su copie). La task completa non è stata rieseguita da zero.

## Stato (2026-11-24, hp)

- Verificato: task completa eseguita; rimosso il Flatpak (non era nel pannello), applet nativo nel pannello.
- GPU AMD: nel journal l'errore NVML è normale (nessuna NVIDIA); visualizzazione della GPU AMD non verificata.

## Stato (2026-11-24, t14)

- Verificato: task completa eseguita; rimosso il Flatpak (non era nel pannello), applet nativo nel pannello.
- Tolto a mano `io.github.cosmic_utils.sysinfo-applet` dal pannello: minimon lo sostituisce.
- GPU AMD (Renoir integrata): visualizzazione della GPU non verificata.
