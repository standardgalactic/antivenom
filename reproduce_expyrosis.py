"""Reproduces every number quoted in the Computations section of the essay.
Run:  python3 reproduce_expyrosis.py     (about 2-4 minutes, numpy only)
Writes results.json and diagnostics.npz next to the script."""
import json, sys, numpy as np
SEED=7
P=dict(seed=SEED, numpy=np.__version__)

# ------------------------------------------------------------------ common 3D grid
def grid3(N,L):
    k1=2*np.pi*np.fft.fftfreq(N,d=L/N)
    KX,KY,KZ=np.meshgrid(k1,k1,k1,indexing='ij')
    return np.sqrt(KX**2+KY**2+KZ**2)
def gfield(rng,Kk,Pfun):
    w=np.fft.fftn(rng.normal(size=Kk.shape)); amp=np.sqrt(Pfun(Kk)); amp[Kk==0]=0   # zero mean
    return w*amp
def coh(a,b): return float(np.real(np.sum(a*np.conj(b)))/np.sqrt(np.sum(abs(a)**2)*np.sum(abs(b)**2)))
nrm=lambda x: float(np.sqrt(np.sum(abs(x)**2)))

# ------------------------------------------------------------------ Computation 1: linear stationary response
rng=np.random.default_rng(SEED)
A=dict(N=48,L=2*np.pi*48/16,D=1.0,gamma=1.0,Sbar=0.5,alpha=1.0,ell=0.6,dt=0.02,steps=3000)
Kk=grid3(A['N'],A['L']); K2=Kk**2; pos=Kk>0
eps=A['alpha']*A['gamma']*A['Sbar']                 # unit gain at k->0+
hhat=np.exp(-K2*A['ell']**2/2)                      # normalized memory profile
PB=lambda k: np.where(k>0,np.maximum(k,1e-12)**-3.0,0.0)
Bk=gfield(rng,Kk,PB)
def evolve(Bk,hhat,eps,gam,phi0=None,steps=A['steps'],dt=A['dt']):
    a=A['D']*K2+gam*A['Sbar']; ea=np.exp(-a*dt); ealpha=np.exp(-A['alpha']*dt)
    f=np.where(a>0,(1-ea)/np.where(a>0,a,1),dt)
    phi=np.zeros_like(Bk) if phi0 is None else phi0.copy(); R=np.zeros_like(Bk)
    for n in range(steps):
        R=ealpha*R+(1-ealpha)/A['alpha']*hhat*Bk          # exact update for data held constant over a step
        phi=ea*phi+f*eps*R
    return phi
a=A['D']*K2+A['gamma']*A['Sbar']
Tan=np.where(pos,eps*hhat/A['alpha']/np.where(a>0,a,1),0)
phi=evolve(Bk,hhat,eps,A['gamma'])
R1={}
R1['epsilon']=float(eps)
R1['max_rel_err_transfer']=float(np.max(np.abs(np.abs(phi[pos])/np.abs(Bk[pos])-Tan[pos])/Tan[pos]))
R1['C_direct']=coh(phi,Bk)
w=np.abs(Bk)**2
R1['C_from_this_realization_spectrum']=float(np.sum(Tan*w)/np.sqrt(np.sum(Tan**2*w)*np.sum(w)))
wens=PB(Kk)
R1['C_ensemble_spectrum']=float(np.sum(Tan*wens)/np.sqrt(np.sum(Tan**2*wens)*np.sum(wens)))
R1['amp_ratio_forced']=nrm(phi)/nrm(Bk)
B2=gfield(rng,Kk,PB); R1['C_independent_template']=coh(phi,B2)
Bs=np.abs(Bk)*np.exp(1j*np.angle(np.fft.fftn(rng.normal(size=Kk.shape)))); R1['C_phase_scrambled']=coh(phi,Bs)
for t in (5.0,20.0,60.0):
    pu=Bk*np.exp(-a*t); R1[f'unforced_from_template_t{t:g}_amp_ratio']=nrm(pu)/nrm(Bk); R1[f'unforced_from_template_t{t:g}_C']=coh(pu,Bk)
phd=evolve(Bk,hhat,eps,0.0); R1['pure_diffusion_gamma0_C']=coh(phd,Bk); R1['pure_diffusion_gamma0_amp_ratio']=nrm(phd)/nrm(Bk)
phs=evolve(Bs,hhat,eps,A['gamma']); R1['forced_by_scrambled_amp_ratio']=nrm(phs)/nrm(Bk); R1['forced_by_scrambled_C_vs_true']=coh(phs,Bk)

# ------------------------------------------------------------------ Computation 2: admissible kernel and recursion
p=3.035; kst=2.0; xi2=A['D']/(A['gamma']*A['Sbar'])
hadm=(1+xi2*K2)*np.exp(-0.5*(Kk/kst)**p)           # h-hat = (1 + xi^2 k^2) exp(-(k/k*)^p / 2),  h-hat(0)=1
Tadm=np.where(pos,np.exp(-0.5*(Kk/kst)**p),0)
phia=evolve(Bk,hadm,eps,A['gamma'])
R2={'p':p,'kstar':kst}
R2['recursion_params']={'grid':64,'box_side':60.0,'kstar':1.0,'cycles':200,'bins':'14 geometric edges 0.12 to 2.0'}
R2['max_rel_err_transfer_admissible_kernel']=float(np.max(np.abs(np.abs(phia[pos])/np.abs(Bk[pos])-Tadm[pos])/Tadm[pos]))
h_real=np.real(np.fft.ifftn(hadm)); R2['kernel_sum']=float(h_real.sum()); R2['kernel_min_over_max']=float(h_real.min()/h_real.max())
# mode-wise recursion on a larger box; fresh unit-variance complex Gaussian noise each cycle
rng2=np.random.default_rng(SEED+1); N2=64; L2=60.0
K2k=grid3(N2,L2); m=K2k>0
T2=np.where(m,np.exp(-0.5*(K2k/1.0)**p),0)      # kstar=1 for the large box
n=200; x=np.zeros(K2k.shape,complex)
for it in range(n):
    x=T2*x+(rng2.normal(size=x.shape)+1j*rng2.normal(size=x.shape))/np.sqrt(2)*m
bins=np.geomspace(0.12,2.0,14); idx=np.digitize(K2k.ravel(),bins); kc_=[];sim=[];ex=[];cnt=[];sd=[]
for i in range(1,len(bins)):
    s=idx==i
    if s.sum()<50: continue
    kb=K2k.ravel()[s].mean(); cnt.append(int(s.sum())); kc_.append(kb); sim.append(np.mean(abs(x.ravel()[s])**2))
    t2=np.exp(-(K2k.ravel()[s]/1.0)**p); Pj=(1-t2**n)/(1-t2); ex.append(np.mean(Pj)); sd.append(np.sqrt(np.sum(Pj**2))/s.sum())
kc_,sim,ex,cnt,sd=map(np.array,(kc_,sim,ex,cnt,sd))
R2['recursion_n']=n; R2['recursion_max_rel_dev_vs_exact_Pn']=float(np.max(np.abs(sim/ex-1)))
R2['recursion_bin_centers']=kc_.tolist(); R2['recursion_rel_dev_per_bin']=(sim/ex-1).tolist(); R2['recursion_modes_per_bin']=cnt.tolist(); R2['recursion_max_abs_z']=float(np.max(np.abs(sim/ex-1)*np.sqrt(cnt)))
R2['recursion_z_exact_variance']=((sim-ex)/sd).tolist(); R2['recursion_max_abs_z_exact_variance']=float(np.max(np.abs((sim-ex)/sd)))
R2['recursion_kc_predicted']=float(1.0*n**(-1/p))
R2['recursion_bins_used']=int(len(kc_))

# ------------------------------------------------------------------ Computation 3: 2D reference gradient flow and dissipation identity
rng3=np.random.default_rng(SEED+2); N3=64; Lb=2*np.pi; dx=Lb/N3
kx=2*np.pi*np.fft.fftfreq(N3,d=dx); KX2,KY2=np.meshgrid(kx,kx,indexing='ij'); K22=KX2**2+KY2**2
Dp=dict(D=1.0,gam=1.0,eta=0.4,Ds=0.3,ell=0.5,eps=1.0,dt=1.5e-4,steps=8000)
ghat=np.exp(-K22*Dp['ell']**2/2); ghat[0,0]=0.0                # zero-mean coupling: g-hat(0)=0
conv=lambda f: np.real(np.fft.ifft2(ghat*np.fft.fft2(f)))
Rf=conv(rng3.normal(size=(N3,N3)))*0.5
fwd=lambda f,ax:(np.roll(f,-1,axis=ax)-f)/dx
lap=lambda f:(np.roll(f,1,0)+np.roll(f,-1,0)+np.roll(f,1,1)+np.roll(f,-1,1)-4*f)/dx**2
def Ffun(Phi,S):
    gr=0.5*Dp['D']*(fwd(Phi,0)**2+fwd(Phi,1)**2)
    return float(np.sum(gr+0.5*Dp['gam']*S*Phi**2-Dp['eps']*Rf*Phi+0.5*S**2+Dp['Ds']*S*np.log(S)-Dp['eta']*S*conv(Phi))*dx*dx)
def AB(Phi,S):
    Aa=-Dp['D']*lap(Phi)+Dp['gam']*S*Phi-Dp['eps']*Rf-Dp['eta']*conv(S)
    mu=S+0.5*Dp['gam']*Phi**2-Dp['eta']*conv(Phi); Bb=mu+Dp['Ds']*(np.log(S)+1)
    return Aa,Bb
def divS(S,Bb):
    div=0
    for ax in (0,1):
        Sf=0.5*(S+np.roll(S,-1,axis=ax)); fl=Sf*fwd(Bb,ax); div=div+(fl-np.roll(fl,1,axis=ax))/dx
    return div
def rhs(Phi,S,etaPhi,sig,rho,J):
    Aa,Bb=AB(Phi,S); d=(etaPhi-Dp['eta'])*conv(S)
    gr2=0.25*((fwd(Phi,0)**2+np.roll(fwd(Phi,0),1,0)**2)+(fwd(Phi,1)**2+np.roll(fwd(Phi,1),1,1)**2))
    Q=sig*gr2-rho*S+J
    return -Aa+d, divS(S,Bb)+Q, Aa, Bb, d, Q
Phi=0.1*rng3.normal(size=(N3,N3)); S=0.5+0.1*rng3.random((N3,N3)); M0=S.sum()*dx*dx
Fs=[Ffun(Phi,S)]; Smin=S.min()
for it in range(Dp['steps']):
    dP,dS,_,_,_,_=rhs(Phi,S,Dp['eta'],0,0,0); Phi=Phi+Dp['dt']*dP; S=S+Dp['dt']*dS; Smin=min(Smin,S.min())
    if it%20==0: Fs.append(Ffun(Phi,S))
Fs=np.array(Fs); dF=np.diff(Fs)
R3=dict(F_initial=float(Fs[0]),F_final=float(Fs[-1]),max_single_sample_change=float(dF.max()),num_increases=int((dF>1e-9).sum()),S_min=float(Smin),mass_rel_drift=float(abs(S.sum()*dx*dx-M0)/M0),steps=Dp['steps'],dt=Dp['dt'])
# dissipation identity for the FULL system (nonreciprocal coupling, production, collapse, source)
etaPhi,sig,rho,J=3.0,0.8,0.5,0.3
Phi=0.1*rng3.normal(size=(N3,N3)); S=0.3+1.0*rng3.random((N3,N3))
for it in range(300):
    dP,dS,_,_,_,_=rhs(Phi,S,etaPhi,sig,rho,J); Phi=Phi+5e-5*dP; S=S+5e-5*dS
dP,dS,Aa,Bb,d,Q=rhs(Phi,S,etaPhi,sig,rho,J); h=1e-7
num=(Ffun(Phi+h*dP,S+h*dS)-Ffun(Phi-h*dP,S-h*dS))/(2*h)
Sf=[0.5*(S+np.roll(S,-1,axis=ax)) for ax in (0,1)]
corr=-np.sum(Aa**2)*dx*dx-sum(np.sum(Sf[ax]*fwd(Bb,ax)**2) for ax in (0,1))*dx*dx+np.sum(Aa*d)*dx*dx+np.sum(Bb*Q)*dx*dx
old=-np.sum(Aa**2)*dx*dx-sum(np.sum(Sf[ax]*fwd(Bb,ax)**2) for ax in (0,1))*dx*dx+np.sum(Bb*(sig*0+(-rho*S+J)+0))*dx*dx+np.sum(Bb*sig*np.zeros_like(S))*dx*dx  # omits d and the production term
R3['identity_numerical_dFdt']=float(num); R3['identity_corrected_formula']=float(corr)
R3['identity_rel_err_corrected']=float(abs(corr-num)/abs(num)); R3['identity_rel_err_without_d_term']=float(abs(corr-np.sum(Aa*d)*dx*dx-num)/abs(num))
R3['int_BS_in_this_state']=float(np.sum(Bb*S)*dx*dx)
Sd=0.02+0.05*rng3.random((N3,N3)); Pd=0.1*rng3.normal(size=(N3,N3)); _,Bd=AB(Pd,Sd)
R3['dilute_state_int_BS']=float(np.sum(Bd*Sd)*dx*dx); R3['dilute_state_collapse_term_minus_rho_int_BS']=float(-rho*np.sum(Bd*Sd)*dx*dx)

out=dict(params=dict(A=A,Dp=Dp,seed=SEED,numpy=np.__version__),computation1=R1,computation2=R2,computation3=R3)
json.dump(out,open('results.json','w'),indent=1)
np.savez('diagnostics.npz',F_series=Fs,recursion_k=kc_,recursion_sim=sim,recursion_exact=ex)
print(json.dumps(out,indent=1))
