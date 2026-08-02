#!/usr/bin/env python3
"""bayer_heatmap + per-channel R/G/B histograms over the STAR PATCH.

Reuses splay/apps/bayer_heatmap.py's bayer_channel + assume_white so the
patch selection and parity are identical to the existing tool. Adds a third
panel: histograms of the RAW (un-white-balanced) photosite values, split by
Bayer channel, over the star patch (pixels > thresh*peak). The point is to
SEE whether R/G/B are balanced, not just read the two scalar WB ratios.

Shows the correction factors AND their reciprocals:
  WB factor  = Gmean / Xmean   (what assume_white multiplies channel X by)
  reciprocal = Xmean / Gmean   (channel X's brightness relative to G)
"""
import argparse
import sys
from pathlib import Path

import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

SPLAY_APPS = Path.home() / "splay" / "apps"
sys.path.insert(0, str(SPLAY_APPS))
from bayer_heatmap import bayer_channel, DOT  # identical parity + colours

from astropy.io import fits


def load_crop(path, x, y, size, pattern):
    hd = fits.open(path)
    hdu = hd[1] if len(hd) > 1 and hd[1].data is not None else hd[0]
    d = hdu.data.astype(float)
    if pattern is None:
        pattern = hdu.header.get("BAYERPAT") or "RGGB"
    b = size // 2
    crop = d[y - b:y + b, x - b:x + b]
    return crop, x - b, y - b, pattern


def render(crop, x0, y0, pattern, out, thresh=0.15, title=""):
    h, w = crop.shape
    ys, xs = np.mgrid[y0:y0 + h, x0:x0 + w]
    sub = crop - np.median(crop)            # background-subtracted, like the app
    chan = bayer_channel(ys, xs, pattern)
    patch = sub > thresh * sub.max()        # the STAR patch (same rule as assume_white)

    # Per-channel means on the patch -> WB factors and reciprocals.
    means = {c: (sub[patch & (chan == c)].mean()
                 if (patch & (chan == c)).any() else np.nan) for c in "RGB"}
    g = means["G"]
    wb = {c: (g / means[c] if means[c] and means[c] > 0 else np.nan) for c in "RGB"}
    recip = {c: (means[c] / g if g else np.nan) for c in "RGB"}

    # --- assume-white z for the heat-map panel (reuse the same maths) ---
    z = sub.copy()
    if means["R"] > 0:
        z[chan == "R"] *= g / max(means["R"], 1.0)
    if means["B"] > 0:
        z[chan == "B"] *= g / max(means["B"], 1.0)
    z = np.clip(z, 0, None)

    fig = plt.figure(figsize=(20, 7))

    # Panel 1: top-down heat-map + Bayer dots (as before, assume-white applied).
    ax1 = fig.add_subplot(1, 3, 1)
    im = ax1.imshow(z, origin="lower", cmap="inferno", aspect="equal",
                    extent=[x0 - .5, x0 + w - .5, y0 - .5, y0 + h - .5])
    for i in range(h):
        for j in range(w):
            ax1.plot(xs[i, j], ys[i, j], "o", ms=3, color=DOT[chan[i, j]],
                     alpha=0.7, mec="k", mew=0.2)
    # outline the star patch used for the histogram
    ax1.contour(xs, ys, patch.astype(float), levels=[0.5],
                colors="white", linewidths=0.8, alpha=0.6)
    ax1.set_title("assume-white heat-map + Bayer dots\n"
                  "(white contour = star patch)", fontsize=10)
    plt.colorbar(im, ax=ax1, shrink=0.7)

    # Panel 2: RAW per-channel histograms over the star patch.
    ax2 = fig.add_subplot(1, 3, 2)
    vals = {c: sub[patch & (chan == c)] for c in "RGB"}
    allv = np.concatenate([v for v in vals.values() if v.size]) if any(
        v.size for v in vals.values()) else np.array([0.0])
    bins = np.linspace(0, np.percentile(allv, 99.5) if allv.size else 1, 30)
    for c in "RGB":
        if vals[c].size:
            ax2.hist(vals[c], bins=bins, color=DOT[c], alpha=0.55,
                     label=f"{c} (n={vals[c].size}, mean={means[c]:.0f})",
                     histtype="stepfilled", edgecolor="k", linewidth=0.3)
            ax2.axvline(means[c], color=DOT[c], lw=1.4, ls="--")
    ax2.set_title(f"RAW photosite value by channel — star patch "
                  f"(>{thresh:.0%} peak)", fontsize=10)
    ax2.set_xlabel("background-subtracted counts")
    ax2.set_ylabel("photosite count")
    ax2.legend(fontsize=8)

    # Panel 3: the correction factors + reciprocals, as a small bar chart.
    ax3 = fig.add_subplot(1, 3, 3)
    chans = list("RGB")
    xpos = np.arange(3)
    ax3.bar(xpos - 0.18, [wb[c] for c in chans], width=0.34,
            color=[DOT[c] for c in chans], edgecolor="k",
            label="WB factor (G/X)")
    ax3.bar(xpos + 0.18, [recip[c] for c in chans], width=0.34,
            color=[DOT[c] for c in chans], edgecolor="k", alpha=0.45,
            hatch="//", label="reciprocal (X/G)")
    ax3.axhline(1.0, color="w", lw=0.8, ls=":")
    for i, c in enumerate(chans):
        ax3.text(i - 0.18, wb[c], f"{wb[c]:.2f}", ha="center", va="bottom",
                 fontsize=9)
        ax3.text(i + 0.18, recip[c], f"{recip[c]:.2f}", ha="center",
                 va="bottom", fontsize=9)
    ax3.set_xticks(xpos)
    ax3.set_xticklabels(chans)
    ax3.set_title("channel balance factors\n"
                  "WB = multiply raw X by this to match G", fontsize=10)
    ax3.legend(fontsize=8)

    sup = title or "Bayer heat-map + channel histograms"
    fig.suptitle(f"{sup}  |  WB  R×{wb['R']:.2f}  G×1.00  B×{wb['B']:.2f}  "
                 f"|  peak {z.max():.0f}", fontsize=13)
    plt.tight_layout(rect=[0, 0, 1, 0.95])
    plt.savefig(out, dpi=110)
    plt.close(fig)
    print(f"wrote {out}")
    print(f"  means  R={means['R']:.1f} G={means['G']:.1f} B={means['B']:.1f}")
    print(f"  WB     R×{wb['R']:.3f} B×{wb['B']:.3f}   "
          f"recip R={recip['R']:.3f} B={recip['B']:.3f}")
    return wb, recip, means


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("frame")
    ap.add_argument("--x", type=int, required=True)
    ap.add_argument("--y", type=int, required=True)
    ap.add_argument("--size", type=int, default=24)
    ap.add_argument("--pattern", default=None)
    ap.add_argument("--thresh", type=float, default=0.15)
    ap.add_argument("--out", default="heatmap_hist.png")
    a = ap.parse_args(argv)
    crop, x0, y0, pat = load_crop(a.frame, a.x, a.y, a.size, a.pattern)
    render(crop, x0, y0, pat, a.out, thresh=a.thresh,
           title=f"{Path(a.frame).name} @({a.x},{a.y}) {pat}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
