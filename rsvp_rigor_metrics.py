"""
======================================================================
RSVP Rigor Metrics Module
======================================================================

Purpose
-------
Implements the Epistemic Energy Functional
    𝓡[f, φ] = α·logdet(JᵀJ) − β·‖∇φ‖² − γ·ΔS
as defined in the Relativistic Scalar–Vector Plenum (RSVP) framework.

This module provides computational tools for evaluating theoretical
rigor within RSVP lattice simulations. It estimates the following
quantities at each simulation step:

    • Work of Understanding (W)        — energy of phase gradients
    • Phase Coherence (P)              — canonical correlation metric
    • Entropy Gap (ΔS)                 — thermodynamic dissipation
    • Jacobian Log-Determinant         — information-preserving capacity
    • Epistemic Energy Functional (𝓡)  — composite measure of rigor

All results are recorded as JSON Lines (JSONL) entries, suitable for
time-series analysis or post-simulation Lyapunov diagnostics.

Dependencies
------------
NumPy, SciPy, json, pathlib

Reference
---------
See Appendices F–G of the accompanying manuscript for theoretical
derivation and interpretation of 𝓡[f, φ] as a Lyapunov functional
governing the energetic stability of theoretical mappings.

Example Usage
-------------
from rsvp_rigor_metrics import compute_step_metrics, log_step_metrics

# Parameter configuration
params = dict(
    alpha = 1.0,      # weight for structural coherence
    beta  = 0.5,      # weight for phase-gradient penalty
    gamma = 1.0,      # weight for entropic cost
    entropy_mode = "spectral",
    h = 1.0           # lattice spacing
)

# Stepwise evaluation across simulation states
for k, (sim_state, ref_state) in enumerate(zip(sim_sequence, ref_sequence)):
    metrics = compute_step_metrics(sim_state, ref_state, params)
    log_step_metrics(metrics, t=k*dt, regime="active", band=[4, 7])

Outputs
-------
Each call to `log_step_metrics` appends a JSONL record of the form:

    {"t": 12.50,
     "P": 0.84,
     "W": 1.73e+02,
     "DeltaS": 0.12,
     "logdet": 23.41,
     "R": 18.66,
     "regime": "active",
     "band": [4,7]}

Interpretation
--------------
• Monotonic increase of 𝓡 indicates sustained epistemic coupling
  (active regime, Lyapunov ascent).
• Monotonic decrease of 𝓡 corresponds to passive drift or dissipation.
• The ratio W / (k_B T ΔS) ≈ 1 characterizes Landauer-optimal efficiency.

----------------------------------------------------------------------
"""

import json, math, numpy as np
from scipy.signal import hilbert, welch, windows
from scipy.linalg import svd, eigh, det, logm
from pathlib import Path

kB = 1.380649e-23  # Boltzmann constant (for optional physical scaling)

# --------------------------------------------------------------
# Core phase and gradient utilities
# --------------------------------------------------------------

def analytic_phase(x):
    """Return instantaneous phase via Hilbert transform along last axis."""
    return np.angle(hilbert(x, axis=-1))

def phase_difference(phi_T, phi_R):
    """Wrapped difference in (-π, π]."""
    dphi = np.angle(np.exp(1j*(phi_T - phi_R)))
    return dphi

def grad_sq(phi, h=1.0):
    """Sum of squared central differences (|∇φ|²)."""
    grad2 = np.zeros_like(phi)
    for axis in range(phi.ndim-1):  # exclude time axis
        fwd = np.roll(phi, -1, axis) - phi
        bwd = phi - np.roll(phi, 1, axis)
        grad2 += ((fwd - bwd) / (2*h))**2
    return np.mean(grad2)

# --------------------------------------------------------------
# Coherence via principal angles
# --------------------------------------------------------------

def coherence_P(ref, target):
    """Compute mean squared canonical correlation between ref and target."""
    # Flatten spatial dims, keep time as last
    R = ref.reshape(-1, ref.shape[-1])
    T = target.reshape(-1, target.shape[-1])
    R -= R.mean(0);  T -= T.mean(0)
    cov = (R.T @ T) / (R.shape[0]-1)
    _, s, _ = svd(cov, full_matrices=False)
    return np.mean(s**2)

# --------------------------------------------------------------
# Entropy estimators
# --------------------------------------------------------------

def spectral_entropy(x, fs=1.0):
    """Shannon entropy of normalized power spectrum."""
    f, Pxx = welch(x, fs=fs, window=windows.hann(len(x)), nperseg=len(x)//2)
    Pxx /= np.sum(Pxx)
    return -np.sum(Pxx * np.log(Pxx + 1e-12))

def histogram_entropy(samples, bins=32):
    """Histogram-based entropy for multivariate data."""
    hist, _ = np.histogramdd(samples, bins=bins)
    p = hist / np.sum(hist)
    p = p[p > 0]
    return -np.sum(p * np.log(p))

# --------------------------------------------------------------
# Jacobian determinant proxies
# --------------------------------------------------------------

def jacobian_logdet_fd(obs_fn, base_inputs, eps=1e-6):
    """
    Finite-difference estimate of logdet(JᵀJ).
    obs_fn(y) -> observable vector, y = control parameters.
    """
    y0 = np.array(base_inputs, dtype=float)
    x0 = np.array(obs_fn(y0))
    q = len(y0); p = len(x0)
    J = np.zeros((p, q))
    for a in range(q):
        dy = np.zeros(q); dy[a] = eps
        x1 = np.array(obs_fn(y0 + dy))
        J[:, a] = (x1 - x0) / eps
    F = J.T @ J + 1e-9*np.eye(q)
    w, _ = eigh(F)
    return np.sum(np.log(w + 1e-12))

def fisher_logdet(grad_list):
    """Given list of gradients ∇θxᵢ, form Fisher proxy."""
    G = np.stack(grad_list, axis=0)
    F = G.T @ G / G.shape[0] + 1e-9*np.eye(G.shape[1])
    w, _ = eigh(F)
    return np.sum(np.log(w + 1e-12))

# --------------------------------------------------------------
# Energy functional and logger
# --------------------------------------------------------------

def rigor_index(logdet, grad_phi_sq, DeltaS, alpha=1, beta=1, gamma=1):
    return alpha*logdet - beta*grad_phi_sq - gamma*DeltaS

def compute_step_metrics(sim_state, ref_state, params):
    """
    Compute W, P, ΔS, logdet, R for one timestep.
    sim_state/ref_state must provide arrays:
      Phi, v (vector), S  of identical shape.
    """
    phi_T = analytic_phase(sim_state["Phi"])
    phi_R = analytic_phase(ref_state["Phi"])
    phi = phase_difference(phi_T, phi_R)
    grad_phi_sq = grad_sq(phi, h=params.get("h",1.0))
    W = params["gamma"] * grad_phi_sq

    # Coherence
    P = coherence_P(ref_state["Phi"], sim_state["Phi"])

    # Entropy
    if params.get("entropy_mode","spectral") == "spectral":
        S_T = spectral_entropy(sim_state["Phi"].ravel())
        S_R = spectral_entropy(ref_state["Phi"].ravel())
    else:
        X_T = np.stack([sim_state["Phi"].ravel(),
                        np.linalg.norm(sim_state["v"].reshape(-1,sim_state["v"].shape[-1]),axis=1),
                        sim_state["S"].ravel()], axis=1)
        X_R = np.stack([ref_state["Phi"].ravel(),
                        np.linalg.norm(ref_state["v"].reshape(-1,ref_state["v"].shape[-1]),axis=1),
                        ref_state["S"].ravel()], axis=1)
        S_T = histogram_entropy(X_T)
        S_R = histogram_entropy(X_R)
    DeltaS = S_T - S_R

    # Jacobian proxy (user-provided)
    if "grad_list" in sim_state:
        logdet = fisher_logdet(sim_state["grad_list"])
    elif "obs_fn" in params and "y0" in params:
        logdet = jacobian_logdet_fd(params["obs_fn"], params["y0"])
    else:
        logdet = 0.0

    R = rigor_index(logdet, grad_phi_sq, DeltaS,
                    alpha=params.get("alpha",1),
                    beta=params.get("beta",1),
                    gamma=params.get("gamma",1))

    return dict(W=W, P=P, DeltaS=DeltaS, logdet=logdet, R=R)

def log_step_metrics(metrics, t, path="rigor_log.jsonl", **meta):
    """Append metrics and metadata as one JSON line."""
    record = dict(t=float(t), **metrics, **meta)
    with open(path, "a") as f:
        f.write(json.dumps(record)+"\n")