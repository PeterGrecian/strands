#!/usr/bin/env python3
"""Before/after 'assume-white' streak mosaic + heat plots for the
focus-breathing (astro-breathing) experiment.

'Assume white': collapse the raw RGGB Bayer to a monochrome luminance field
(2x2 superpixel sum) rather than debayering. Faint star streaks carry no
useful colour, so summing the four photosites maximises SNR and gives a
clean single-channel image to super-resolve.

For one dark hour of a night we:
  1. Load all frames -> mono luminance stacks.
  2. Coadd (simple sum) to find the brightest, cleanest star STREAKS
     (60 s exposure => stars trail ~11 px).
  3. Pick the N best streaks (bright, isolated, away from optical axis).
  4. For each streak, extract a crop from every frame and DRIZZLE them
     onto a 4x-finer grid, registered by the streak's bright centroid.
     - 'before' night (fixed focus): the only sub-pixel diversity is
       sky drift along-track -> streak sharpens ALONG its length only.
     - 'after' night (breathing): the per-frame radial magnification
       change adds CROSS-track sub-pixel offsets wherever the radial
       direction has a component perpendicular to drift -> the streak
       cross-section is super-resolved.
  5. Render a mosaic of the drizzled crops (heat colormap) so the two
     nights can be compared side by side.

Output: before.png, after.png (mosaics) + a combined compare.png.
"""
import glob
import sys
from pathlib import Path

import numpy as np
from astropy.io import fits

DRIZZLE = 4          # super-resolution factor
CROP = 40            # mono-px half-window around a streak centroid
N_STREAKS = 16       # streaks per mosaic (4x4 grid)
PIXFRAC = 0.5        # drizzle drop shrink factor


def load_mono(path):
    """Raw RGGB uint16 -> float32 mono luminance (2x2 superpixel sum)."""
    d = fits.getdata(path, 1).astype(np.float32)
    h, w = d.shape
    d = d[:h // 2 * 2, :w // 2 * 2]
    mono = (d[0::2, 0::2] + d[0::2, 1::2]
            + d[1::2, 0::2] + d[1::2, 1::2])
    return mono


def centroid(patch):
    """Intensity-weighted centroid of a background-subtracted patch."""
    p = patch - np.median(patch)
    p[p < 0] = 0
    if p.sum() == 0:
        return patch.shape[1] / 2, patch.shape[0] / 2
    ys, xs = np.mgrid[0:patch.shape[0], 0:patch.shape[1]]
    return (p * xs).sum() / p.sum(), (p * ys).sum() / p.sum()


def find_streaks(coadd, n, optical_axis, crop=CROP):
    """Find n bright, isolated local maxima, preferring ones far from the
    optical axis (where the breathing radial dither has amplitude)."""
    bg = np.median(coadd)
    sig = coadd - bg
    noise = 1.4826 * np.median(np.abs(sig))
    picks = []
    work = sig.copy()
    cy, cx = optical_axis
    while len(picks) < n:
        idx = np.argmax(work)
        y, x = np.unravel_index(idx, work.shape)
        if work[y, x] < 8 * noise:
            break
        # radius from optical axis (mono px), used to rank usefulness
        r = np.hypot(x - cx, y - cy)
        if (crop < x < coadd.shape[1] - crop
                and crop < y < coadd.shape[0] - crop):
            picks.append((x, y, float(sig[y, x]), float(r)))
        # suppress a wide neighbourhood so we don't re-pick the same streak
        y0, y1 = max(0, y - crop), min(coadd.shape[0], y + crop)
        x0, x1 = max(0, x - crop), min(coadd.shape[1], x + crop)
        work[y0:y1, x0:x1] = -1e9
    # prefer larger radius (more breathing dither) among the bright picks
    picks.sort(key=lambda p: p[3], reverse=True)
    return picks


def drizzle_streak(frames, x, y, crop=CROP, f=DRIZZLE, pixfrac=PIXFRAC):
    """Drizzle a per-frame crop around (x,y) onto an f-times finer grid,
    registering each frame by the crop's own bright centroid. Returns the
    drizzled (weight-normalised) image."""
    size = 2 * crop
    acc = np.zeros((size * f, size * f), np.float32)
    wt = np.zeros_like(acc)
    # reference centroid from the coadd position; align each frame to it
    ref_cx, ref_cy = crop, crop
    for mono in frames:
        patch = mono[y - crop:y + crop, x - crop:x + crop]
        if patch.shape != (size, size):
            continue
        cxf, cyf = centroid(patch)
        # shift so this frame's centroid lands on the reference centre
        dx, dy = ref_cx - cxf, ref_cy - cyf
        p = patch - np.median(patch)
        p[p < 0] = 0
        # deposit each input pixel as a shrunken drop on the fine grid
        ys, xs = np.nonzero(p > 0)
        for yy, xx in zip(ys, xs):
            fx = (xx + dx) * f
            fy = (yy + dy) * f
            gx, gy = int(round(fx)), int(round(fy))
            half = max(1, int(f * pixfrac))
            gy0, gy1 = max(0, gy - half), min(acc.shape[0], gy + half)
            gx0, gx1 = max(0, gx - half), min(acc.shape[1], gx + half)
            if gy1 > gy0 and gx1 > gx0:
                acc[gy0:gy1, gx0:gx1] += p[yy, xx]
                wt[gy0:gy1, gx0:gx1] += 1.0
    out = np.where(wt > 0, acc / np.maximum(wt, 1e-6), 0)
    return out


def build_mosaic(night_dir, optical_axis, label):
    files = sorted(glob.glob(f"{night_dir}/*.fits.fz"))
    if not files:
        print(f"{label}: no frames in {night_dir}")
        return None
    print(f"{label}: loading {len(files)} frames...")
    frames = [load_mono(f) for f in files]
    coadd = np.sum(frames, axis=0)
    picks = find_streaks(coadd, N_STREAKS, optical_axis)
    print(f"{label}: {len(picks)} streaks found "
          f"(radii {picks[-1][3]:.0f}-{picks[0][3]:.0f} mono-px)")
    tiles = []
    for (x, y, val, r) in picks:
        tiles.append(drizzle_streak(frames, x, y))
    return coadd, picks, tiles


def render(tiles, path, title):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    ncol = 4
    nrow = (len(tiles) + ncol - 1) // ncol
    fig, axes = plt.subplots(nrow, ncol, figsize=(ncol * 2.4, nrow * 2.4))
    fig.suptitle(title, color="w", fontsize=13)
    for ax, tile in zip(axes.ravel(), tiles):
        t = tile.copy()
        vmax = np.percentile(t[t > 0], 99.5) if (t > 0).any() else 1
        ax.imshow(t, cmap="inferno", vmin=0, vmax=vmax,
                  interpolation="nearest")
        ax.set_xticks([]); ax.set_yticks([])
    for ax in axes.ravel()[len(tiles):]:
        ax.axis("off")
    fig.patch.set_facecolor("black")
    plt.tight_layout(rect=[0, 0, 1, 0.96])
    plt.savefig(path, dpi=110, facecolor="black")
    plt.close()
    print("wrote", path)


if __name__ == "__main__":
    # optical axis in MONO pixels (full-res 4608x2592 -> mono 2304x1296);
    # assume frame centre until a proper distortion fit says otherwise.
    OA = (1296 // 2, 2304 // 2)  # (cy, cx) mono
    base = Path(__file__).resolve().parent
    results = {}
    for label in ("before", "after"):
        r = build_mosaic(str(base / label), OA, label)
        if r:
            coadd, picks, tiles = r
            results[label] = tiles
            render(tiles, str(base / f"{label}.png"),
                   f"astro-breathing 'assume-white' streaks — {label} "
                   f"(drizzle x{DRIZZLE})")
