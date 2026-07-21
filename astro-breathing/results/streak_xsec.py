#!/usr/bin/env python3
"""Cross-track streak super-resolution: the actual astro-breathing test.

For a night's dark hour:
  * find the brightest star STREAK in the sky band (top third, away from
    the wind-blown trees on the right).
  * in EACH frame, the star is a ~11 px trail (60 s exposure). Extract a
    rotated crop aligned to the trail so 'x' runs ALONG the streak and
    'y' runs ACROSS it (cross-track).
  * collapse along-track to get each frame's 1-D CROSS-TRACK PROFILE.
  * stack the per-frame cross-track profiles two ways:
      - before/naive: align by centroid only -> native sampling.
      - drizzle: place each frame's profile on a 4x-finer grid at its
        measured sub-pixel centroid -> if breathing supplies cross-track
        sub-pixel dither, the stacked profile is NARROWER / better sampled.
  * 'heat plot' = per-frame cross-track profile vs frame index (a
    waterfall). Sub-pixel wander of the centroid row-to-row is the
    breathing dither made visible.

Outputs: <label>_heat.png (waterfall) and a combined profile compare.
"""
import glob
import sys
from pathlib import Path

import numpy as np
from astropy.io import fits
from scipy import ndimage

BAND = (0, 560, 0, 1950)   # sky band (y0,y1,x0,x1) in mono px
DRIZZLE = 4
HALF_ALONG = 12            # crop half-length along track (px)
HALF_ACROSS = 8            # crop half-width across track (px)


def load_mono(p):
    d = fits.getdata(p, 1).astype(np.float32)
    h, w = d.shape
    d = d[:h // 2 * 2, :w // 2 * 2]
    return d[0::2, 0::2] + d[0::2, 1::2] + d[1::2, 0::2] + d[1::2, 1::2]


def lens_meta(p):
    h = fits.getheader(p, 1)
    return h.get("LENSPOS"), h.get("LENSPREP")


def brightest_streak_xy(frames):
    """Locate the single brightest star trail in the sky band using the
    residual-max image; return its (x,y) in mono coords and the streak
    angle from a local PCA of the max-residual trail."""
    stack = np.array(frames)
    med = np.median(stack, axis=0)
    mover = (stack - med).max(axis=0)
    y0, y1, x0, x1 = BAND
    sky = np.full_like(mover, mover.min())
    sky[y0:y1, x0:x1] = mover[y0:y1, x0:x1]
    bg = np.median(sky[y0:y1, x0:x1])
    sig = sky - bg
    y, x = np.unravel_index(np.argmax(sig), sig.shape)
    # angle: fit a line to bright pixels in a window around the peak
    win = 60
    ys, xs = np.mgrid[max(0, y - win):y + win, max(0, x - win):x + win]
    patch = sig[max(0, y - win):y + win, max(0, x - win):x + win]
    m = patch > 0.15 * patch.max()
    if m.sum() > 5:
        pts = np.c_[xs[m].ravel(), ys[m].ravel()].astype(float)
        pts -= pts.mean(0)
        _, _, vt = np.linalg.svd(pts, full_matrices=False)
        ang = np.degrees(np.arctan2(vt[0, 1], vt[0, 0]))
    else:
        ang = 0.0
    return x, y, ang, med


def per_frame_profiles(frames, x, y, ang, med):
    """For each frame, rotate a crop so the streak is horizontal, subtract
    the static median, collapse ALONG track -> cross-track profile.
    Returns (profiles[N, W], centroids[N])."""
    profs = []
    cents = []
    for f in frames:
        r = f - med  # remove static foreground/sky
        crop = r[y - 40:y + 40, x - 40:x + 40]
        if crop.shape != (80, 80):
            profs.append(None); cents.append(None); continue
        rot = ndimage.rotate(crop, ang, reshape=False, order=1)
        cy = rot.shape[0] // 2
        cx = rot.shape[1] // 2
        band = rot[cy - HALF_ACROSS:cy + HALF_ACROSS,
                   cx - HALF_ALONG:cx + HALF_ALONG]
        prof = band.sum(axis=1)          # collapse along-track
        prof = prof - np.median(prof)
        prof[prof < 0] = 0
        if prof.sum() <= 0:
            profs.append(None); cents.append(None); continue
        idx = np.arange(len(prof))
        c = (prof * idx).sum() / prof.sum()
        profs.append(prof); cents.append(c)
    return profs, cents


def drizzle_profiles(profs, cents, f=DRIZZLE):
    """Stack cross-track profiles onto an f-finer grid at sub-pixel
    centroid -> super-resolved profile IF the centroids dither sub-px."""
    W = next(p.shape[0] for p in profs if p is not None)
    ref = W / 2.0
    acc = np.zeros(W * f)
    wt = np.zeros(W * f)
    for prof, c in zip(profs, cents):
        if prof is None:
            continue
        shift = (ref - c)
        idx = (np.arange(W) + shift) * f
        gi = np.round(idx).astype(int)
        ok = (gi >= 0) & (gi < len(acc))
        acc[gi[ok]] += prof[ok]
        wt[gi[ok]] += 1
    return np.where(wt > 0, acc / np.maximum(wt, 1e-9), 0)


def analyse(label, base):
    files = sorted(glob.glob(f"{base}/{label}/*.fits.fz"))
    if not files:
        print(f"{label}: no frames"); return None
    frames = [load_mono(f) for f in files]
    x, y, ang, med = brightest_streak_xy(frames)
    lp = [lens_meta(f)[1] for f in files]   # reported lens (LENSPREP)
    profs, cents = per_frame_profiles(frames, x, y, ang, med)
    valid = [(p, c, l) for p, c, l in zip(profs, cents, lp)
             if p is not None and c is not None]
    print(f"{label}: streak at ({x},{y}) ang={ang:.1f} deg, "
          f"{len(valid)}/{len(files)} frames usable")
    # centroid wander (cross-track) — the dither signature
    cs = np.array([c for _, c, _ in valid])
    print(f"{label}: cross-track centroid rms wander = "
          f"{np.std(cs):.3f} px (range {cs.max()-cs.min():.2f} px)")
    driz = drizzle_profiles([p for p, _, _ in valid],
                            [c for _, c, _ in valid])
    return dict(label=label, x=x, y=y, ang=ang, profs=profs, cents=cents,
                lp=lp, valid=valid, driz=driz)


def fwhm(prof, oversample=1):
    prof = prof - prof.min()
    if prof.max() <= 0:
        return float("nan")
    half = prof.max() / 2
    above = np.where(prof >= half)[0]
    if len(above) < 2:
        return float("nan")
    return (above[-1] - above[0]) / oversample


def render(results, base):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    fig = plt.figure(figsize=(13, 8))
    fig.patch.set_facecolor("black")

    # --- top row: per-frame cross-track waterfall (heat plot) per night ---
    for i, res in enumerate(results):
        ax = fig.add_subplot(2, 2, i + 1)
        wf = np.array([p for p, _, _ in res["valid"]])
        ax.imshow(wf, aspect="auto", cmap="inferno",
                  interpolation="nearest")
        ax.set_title(f"{res['label']}: cross-track profile per frame\n"
                     f"(streak {res['x']},{res['y']} @ {res['ang']:.0f} deg)",
                     color="w", fontsize=10)
        ax.set_xlabel("cross-track px", color="w")
        ax.set_ylabel("frame index", color="w")
        ax.tick_params(colors="w")

    # --- bottom: drizzled super-res profile compare + FWHM ---
    ax = fig.add_subplot(2, 1, 2)
    for res in results:
        driz = res["driz"]
        xs = np.arange(len(driz)) / DRIZZLE
        norm = driz / (driz.max() or 1)
        fw = fwhm(driz, oversample=DRIZZLE)
        ax.plot(xs, norm, label=f"{res['label']} "
                f"(drizzle x{DRIZZLE}, FWHM {fw:.2f} px)", lw=1.5)
    ax.set_title("cross-track streak profile — drizzled super-resolution",
                 color="w")
    ax.set_xlabel("cross-track px (native scale)", color="w")
    ax.set_ylabel("normalised flux", color="w")
    ax.tick_params(colors="w")
    ax.legend(facecolor="#222", labelcolor="w")
    ax.set_facecolor("#111")

    plt.tight_layout()
    out = f"{base}/compare.png"
    plt.savefig(out, dpi=120, facecolor="black")
    print("wrote", out)


if __name__ == "__main__":
    base = str(Path(__file__).resolve().parent)
    results = []
    for label in ("before", "after"):
        r = analyse(label, base)
        if r:
            results.append(r)
    if results:
        render(results, base)
