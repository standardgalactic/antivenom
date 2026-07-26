//! attestal_photonic.rs
//!
//! A single-file, dependency-free Rust prototype for provenance-preserving
//! scientific claims.
//!
//! ---------------------------------------------------------------------------
//! PURPOSE
//! ---------------------------------------------------------------------------
//!
//! This program illustrates a simple principle:
//!
//!     A result is not epistemically equivalent to its value alone.
//!
//! The number
//!
//!     P(|1,1>) = 0
//!
//! does not tell us whether it came from:
//!
//!   * an analytic derivation,
//!   * an exact simulator,
//!   * a Monte-Carlo simulator,
//!   * a real photonic QPU,
//!   * a copied paper,
//!   * or somebody simply typing "0".
//!
//! If that history is discarded, later consumers must reconstruct it.
//! That reconstruction problem is what we can call increased "repair entropy."
//!
//! So this prototype treats provenance as part of the result.
//!
//! The key invariant is:
//!
//!     result = value + generating history
//!
//! rather than:
//!
//!     result = value
//!
//! ---------------------------------------------------------------------------
//! STRUCTURAL HONESTY
//! ---------------------------------------------------------------------------
//!
//! This is NOT:
//!
//!   * a real quantum-hardware execution,
//!   * Perceval,
//!   * Quandela hardware,
//!   * OVHcloud,
//!   * a cryptographically signed attestation,
//!   * or a production implementation of attestal.ai.
//!
//! It IS:
//!
//!   * ordinary Rust,
//!   * running a small deterministic linear-optical simulator,
//!   * on whatever machine executes this binary,
//!   * with provenance attached explicitly to the resulting claims.
//!
//! The program intentionally refuses to call simulated evidence a hardware run.
//!
//! ---------------------------------------------------------------------------
//! BUILD
//! ---------------------------------------------------------------------------
//!
//!     rustc --edition=2021 -O attestal_photonic.rs
//!     ./attestal_photonic
//!
//! No Cargo project or external crates are required.
//!
//! ---------------------------------------------------------------------------
//! WHY THE HASH IS NOT A SIGNATURE
//! ---------------------------------------------------------------------------
//!
//! For portability this prototype implements FNV-1a 64-bit as a deterministic
//! fingerprint over each canonical provenance record.
//!
//! FNV-1a is NOT a cryptographic hash and MUST NOT be represented as one.
//!
//! A production Attestal-style implementation should replace it with a
//! cryptographic content digest such as SHA-256 or BLAKE3 and, where authorship
//! or machine identity matters, authenticate that digest using an appropriate
//! signature scheme such as Ed25519.
//!
//! Calling this FNV fingerprint a "signature" would defeat the point of the
//! prototype.

use std::error::Error;
use std::fmt;

// ===========================================================================
// 1. A MINIMAL COMPLEX NUMBER TYPE
// ===========================================================================
//
// Linear optical interferometers are naturally represented by complex-valued
// unitary matrices.
//
// We implement only the operations needed here rather than hiding the
// calculation behind an external numerical package.

#[derive(Clone, Copy, Debug, PartialEq)]
struct Complex {
    re: f64,
    im: f64,
}

impl Complex {
    const ZERO: Self = Self { re: 0.0, im: 0.0 };

    const fn new(re: f64, im: f64) -> Self {
        Self { re, im }
    }

    fn abs_squared(self) -> f64 {
        self.re * self.re + self.im * self.im
    }
}

impl std::ops::Add for Complex {
    type Output = Self;

    fn add(self, rhs: Self) -> Self {
        Self::new(self.re + rhs.re, self.im + rhs.im)
    }
}

impl std::ops::Mul for Complex {
    type Output = Self;

    fn mul(self, rhs: Self) -> Self {
        Self::new(
            self.re * rhs.re - self.im * rhs.im,
            self.re * rhs.im + self.im * rhs.re,
        )
    }
}

// ===========================================================================
// 2. EVIDENCE TYPES
// ===========================================================================
//
// This is the conceptual heart of the prototype.
//
// Instead of recording "quantum" as an undifferentiated status flag, we retain
// the mechanism that generated the evidence.
//
// Importantly, `Simulation` and `Hardware` are different enum variants.
// Software consuming the record therefore has something stronger than prose
// convention to work with.

#[derive(Clone, Debug)]
enum EvidenceKind {
    /// A deterministic computation performed by software.
    Simulation {
        simulator: String,
        method: String,
    },

    /// Reserved for an actual physical-device execution.
    ///
    /// Nothing in this prototype constructs this variant during normal
    /// execution.
    Hardware {
        provider: String,
        device: String,
        job_id: String,
    },
}

impl EvidenceKind {
    fn label(&self) -> &'static str {
        match self {
            Self::Simulation { .. } => "simulation",
            Self::Hardware { .. } => "hardware",
        }
    }

    fn is_hardware(&self) -> bool {
        matches!(self, Self::Hardware { .. })
    }
}

impl fmt::Display for EvidenceKind {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Simulation { simulator, method } => {
                write!(
                    f,
                    "simulation; simulator={simulator}; method={method}"
                )
            }

            Self::Hardware {
                provider,
                device,
                job_id,
            } => {
                write!(
                    f,
                    "hardware; provider={provider}; device={device}; job_id={job_id}"
                )
            }
        }
    }
}

// ===========================================================================
// 3. EXECUTION PROVENANCE
// ===========================================================================
//
// A numerical result without these fields is much cheaper to store.
//
// That is exactly the temptation.
//
// But removing them changes what future observers are able to establish about
// the result.
//
// In the language of the Compression–Repair Tradeoff:
//
//     smaller retained trace
//         ->
//     larger reconstruction burden
//         ->
//     greater repair entropy.
//
// This struct therefore retains mundane-looking details intentionally.

#[derive(Clone, Debug)]
struct Provenance {
    evidence: EvidenceKind,

    /// What software implementation actually produced the result.
    implementation: String,

    /// A human-readable description of where computation occurred.
    compute: String,

    /// Cost as actually incurred by this demonstration.
    ///
    /// This is text because accounting provenance is not the object being
    /// formalized here.
    cost: String,

    /// Whether the calculation is deterministic given the same program/input.
    deterministic: bool,

    /// Important negative claims can be as useful as positive ones.
    ///
    /// Stating what this execution was NOT prevents later semantic inflation.
    exclusions: Vec<String>,
}

impl Provenance {
    fn canonical_text(&self) -> String {
        format!(
            concat!(
                "evidence={}\n",
                "implementation={}\n",
                "compute={}\n",
                "cost={}\n",
                "deterministic={}\n",
                "exclusions={}\n"
            ),
            self.evidence,
            self.implementation,
            self.compute,
            self.cost,
            self.deterministic,
            self.exclusions.join(" | "),
        )
    }
}

// ===========================================================================
// 4. PROVENANCE-PRESERVING RESULT
// ===========================================================================
//
// `Attested<T>` makes a result and its provenance travel together.
//
// The name "Attested" here means only "accompanied by an explicit record."
// It does NOT mean cryptographically signed.
//
// Production software should choose an even more precise name if that
// distinction could be misunderstood.

#[derive(Clone, Debug)]
struct Attested<T> {
    experiment: String,
    result: T,
    provenance: Provenance,

    /// Demonstration-only deterministic fingerprint.
    fingerprint_fnv1a64: u64,
}

impl<T: fmt::Display> Attested<T> {
    fn new(experiment: impl Into<String>, result: T, provenance: Provenance) -> Self {
        let experiment = experiment.into();

        let canonical = format!(
            "experiment={}\n{}",
            experiment,
            provenance.canonical_text()
        );

        let fingerprint_fnv1a64 = fnv1a64(canonical.as_bytes());

        Self {
            experiment,
            result,
            provenance,
            fingerprint_fnv1a64,
        }
    }

    /// Generate a public textual record.
    ///
    /// Notice that the numerical output is not printed alone.
    fn public_record(&self) -> String {
        format!(
            concat!(
                "experiment: {}\n",
                "evidence: {}\n",
                "result:\n{}\n",
                "implementation: {}\n",
                "compute: {}\n",
                "cost: {}\n",
                "deterministic: {}\n",
                "fingerprint: fnv1a64-demo-only:{:016x}\n"
            ),
            self.experiment,
            self.provenance.evidence,
            indent(&self.result.to_string(), 2),
            self.provenance.implementation,
            self.provenance.compute,
            self.provenance.cost,
            self.provenance.deterministic,
            self.fingerprint_fnv1a64,
        )
    }

    /// A claim requiring hardware provenance must pass through this gate.
    ///
    /// This is the structural equivalent of saying:
    ///
    ///     "Do not merely ask whether the output looks plausible.
    ///      Ask whether the generating history warrants the claim."
    fn require_hardware(&self) -> Result<(), ProvenanceError> {
        if self.provenance.evidence.is_hardware() {
            Ok(())
        } else {
            Err(ProvenanceError {
                attempted_claim: "real photonic hardware execution".into(),
                actual_evidence: self.provenance.evidence.label().into(),
            })
        }
    }
}

// ===========================================================================
// 5. FAILURE TO OVERCLAIM IS A FIRST-CLASS OUTCOME
// ===========================================================================

#[derive(Debug)]
struct ProvenanceError {
    attempted_claim: String,
    actual_evidence: String,
}

impl fmt::Display for ProvenanceError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            f,
            "claim rejected: attempted to assert {:?}, but retained provenance says {:?}",
            self.attempted_claim,
            self.actual_evidence
        )
    }
}

impl Error for ProvenanceError {}

// ===========================================================================
// 6. PHOTONIC OUTPUT REPRESENTATION
// ===========================================================================

#[derive(Clone, Debug)]
struct Outcome {
    occupation: Vec<usize>,
    probability: f64,
}

#[derive(Clone, Debug)]
struct Distribution {
    outcomes: Vec<Outcome>,
}

impl Distribution {
    fn total_probability(&self) -> f64 {
        self.outcomes.iter().map(|x| x.probability).sum()
    }
}

impl fmt::Display for Distribution {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        for outcome in &self.outcomes {
            writeln!(
                f,
                "|{}> = {:.12}",
                occupation_string(&outcome.occupation),
                outcome.probability
            )?;
        }

        write!(f, "total = {:.12}", self.total_probability())
    }
}

// ===========================================================================
// 7. EXACT SMALL-N BOSONIC TRANSITION PROBABILITIES
// ===========================================================================
//
// For an interferometer U and Fock states:
//
//     |n_1, ..., n_m>  ->  |s_1, ..., s_m>
//
// the transition probability for indistinguishable bosons is:
//
//               |Perm(U_sub)|²
//     P = ------------------------------
//          Π_i n_i!  ·  Π_j s_j!
//
// U_sub is formed by repeating input columns and output rows according to the
// respective occupation numbers.
//
// This implementation computes the permanent using a naive permutation
// recursion.
//
// Complexity is factorial in photon number.
//
// That is acceptable here because the point is transparency on tiny examples,
// not high-performance boson sampling.

fn bosonic_probability(
    unitary: &[Vec<Complex>],
    input: &[usize],
    output: &[usize],
) -> f64 {
    let photons_in: usize = input.iter().sum();
    let photons_out: usize = output.iter().sum();

    assert_eq!(
        photons_in, photons_out,
        "photon number must be conserved"
    );

    if photons_in == 0 {
        return 1.0;
    }

    let input_modes = repeated_indices(input);
    let output_modes = repeated_indices(output);

    let n = photons_in;

    let mut submatrix = vec![vec![Complex::ZERO; n]; n];

    for row in 0..n {
        for col in 0..n {
            submatrix[row][col] =
                unitary[output_modes[row]][input_modes[col]];
        }
    }

    let permanent = permanent(&submatrix);

    let input_factor =
        input.iter().map(|&n| factorial(n) as f64).product::<f64>();

    let output_factor =
        output.iter().map(|&n| factorial(n) as f64).product::<f64>();

    permanent.abs_squared() / (input_factor * output_factor)
}

/// Naive permanent:
///
///     Perm(A) = Σ_σ Π_i A[i, σ(i)]
///
/// Unlike a determinant, a permanent has no alternating sign.
fn permanent(matrix: &[Vec<Complex>]) -> Complex {
    let n = matrix.len();

    let mut used = vec![false; n];

    fn visit(
        row: usize,
        matrix: &[Vec<Complex>],
        used: &mut [bool],
        product: Complex,
        sum: &mut Complex,
    ) {
        if row == matrix.len() {
            *sum = *sum + product;
            return;
        }

        for col in 0..matrix.len() {
            if !used[col] {
                used[col] = true;

                visit(
                    row + 1,
                    matrix,
                    used,
                    product * matrix[row][col],
                    sum,
                );

                used[col] = false;
            }
        }
    }

    let mut sum = Complex::ZERO;

    visit(
        0,
        matrix,
        &mut used,
        Complex::new(1.0, 0.0),
        &mut sum,
    );

    sum
}

fn repeated_indices(occupation: &[usize]) -> Vec<usize> {
    let mut result = Vec::new();

    for (mode, &count) in occupation.iter().enumerate() {
        for _ in 0..count {
            result.push(mode);
        }
    }

    result
}

fn factorial(n: usize) -> usize {
    (1..=n).product()
}

// ===========================================================================
// 8. ENUMERATE FOCK OUTPUT STATES
// ===========================================================================

fn occupations(modes: usize, photons: usize) -> Vec<Vec<usize>> {
    fn recurse(
        mode: usize,
        modes: usize,
        remaining: usize,
        current: &mut Vec<usize>,
        output: &mut Vec<Vec<usize>>,
    ) {
        if mode + 1 == modes {
            current.push(remaining);
            output.push(current.clone());
            current.pop();
            return;
        }

        for n in 0..=remaining {
            current.push(n);

            recurse(
                mode + 1,
                modes,
                remaining - n,
                current,
                output,
            );

            current.pop();
        }
    }

    let mut output = Vec::new();

    recurse(
        0,
        modes,
        photons,
        &mut Vec::new(),
        &mut output,
    );

    output
}

fn simulate_distribution(
    unitary: &[Vec<Complex>],
    input: &[usize],
) -> Distribution {
    let photons: usize = input.iter().sum();
    let modes = input.len();

    let mut outcomes = occupations(modes, photons)
        .into_iter()
        .map(|occupation| Outcome {
            probability: bosonic_probability(
                unitary,
                input,
                &occupation,
            ),
            occupation,
        })
        .collect::<Vec<_>>();

    // Most interesting outcomes first.
    outcomes.sort_by(|a, b| {
        b.probability
            .partial_cmp(&a.probability)
            .unwrap_or(std::cmp::Ordering::Equal)
    });

    Distribution { outcomes }
}

// ===========================================================================
// 9. EXPERIMENT 01 — HONG–OU–MANDEL INTERFERENCE
// ===========================================================================
//
// Two indistinguishable photons enter opposite ports of a balanced beam
// splitter:
//
//     input = |1,1>
//
// Using one conventional real-valued beamsplitter representation:
//
//            1     [ 1   1 ]
//     U = ------- [         ]
//          sqrt 2 [ 1  -1 ]
//
// For the |1,1> -> |1,1> transition, the relevant permanent is:
//
//     Perm(U)
//       = U00 U11 + U01 U10
//!      = (-1/2) + (1/2)
//!      = 0
//!
//! so coincidence detection is suppressed.
//
// The photons instead bunch:
//!
//!     P(|2,0>) = 1/2
//!     P(|0,2>) = 1/2
//!     P(|1,1>) = 0
//!
//! The cancellation occurs at the level of amplitudes before probabilities
//! are taken.

fn hong_ou_mandel(provenance: Provenance) -> Attested<Distribution> {
    let s = 1.0 / 2.0_f64.sqrt();

    let beam_splitter = vec![
        vec![
            Complex::new(s, 0.0),
            Complex::new(s, 0.0),
        ],
        vec![
            Complex::new(s, 0.0),
            Complex::new(-s, 0.0),
        ],
    ];

    let input = [1, 1];

    let distribution = simulate_distribution(
        &beam_splitter,
        &input,
    );

    Attested::new(
        "Hong-Ou-Mandel two-photon interference",
        distribution,
        provenance,
    )
}

// ===========================================================================
// 10. EXPERIMENT 02 — THREE-MODE BOSON SAMPLING
// ===========================================================================
//
// We use the 3×3 discrete Fourier interferometer:
//
//                 1
//     U_jk = ----------- exp(2πijk/3)
//              sqrt(3)
//
// with one photon entering each input mode:
//
//     |1,1,1>
//
// This is a small but genuine bosonic interference calculation: every output
// probability is obtained from a matrix permanent.
//
// It is still only a local numerical simulation.

fn three_mode_boson_sampling(
    provenance: Provenance,
) -> Attested<Distribution> {
    let n = 3usize;
    let norm = 1.0 / (n as f64).sqrt();

    let mut fourier = vec![vec![Complex::ZERO; n]; n];

    for row in 0..n {
        for col in 0..n {
            let theta =
                2.0 * std::f64::consts::PI
                * (row * col) as f64
                / n as f64;

            fourier[row][col] =
                Complex::new(
                    norm * theta.cos(),
                    norm * theta.sin(),
                );
        }
    }

    let input = [1, 1, 1];

    let distribution =
        simulate_distribution(&fourier, &input);

    Attested::new(
        "Three-photon / three-mode Fourier boson sampling",
        distribution,
        provenance,
    )
}

// ===========================================================================
// 11. EXPERIMENT 03 — A MINIMAL BELL-STATE CALCULATION
// ===========================================================================
//
// We represent:
//
//             |HH> + |VV>
//     |Phi+> = -------------
//                sqrt(2)
//
// This section intentionally does NOT claim to simulate an entire physical
// source, detector chain, loophole-free Bell test, or photonic QPU.
//
// It verifies only the state-vector consequences written below.
//
// Again: retaining that limitation is part of provenance.

#[derive(Clone, Debug)]
struct BellResult {
    p_hh: f64,
    p_hv: f64,
    p_vh: f64,
    p_vv: f64,
    normalization: f64,
    zz_correlation: f64,
    xx_correlation: f64,
}

impl fmt::Display for BellResult {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        writeln!(f, "P(HH) = {:.12}", self.p_hh)?;
        writeln!(f, "P(HV) = {:.12}", self.p_hv)?;
        writeln!(f, "P(VH) = {:.12}", self.p_vh)?;
        writeln!(f, "P(VV) = {:.12}", self.p_vv)?;
        writeln!(
            f,
            "normalization = {:.12}",
            self.normalization
        )?;
        writeln!(
            f,
            "<Z x Z> = {:.12}",
            self.zz_correlation
        )?;
        write!(
            f,
            "<X x X> = {:.12}",
            self.xx_correlation
        )
    }
}

fn bell_state(provenance: Provenance) -> Attested<BellResult> {
    let a = 1.0 / 2.0_f64.sqrt();

    // Basis ordering:
    //
    //     |HH>, |HV>, |VH>, |VV>
    //
    let state = [
        Complex::new(a, 0.0),
        Complex::ZERO,
        Complex::ZERO,
        Complex::new(a, 0.0),
    ];

    let probabilities = state.map(Complex::abs_squared);

    let normalization: f64 =
        probabilities.iter().sum();

    // For |Phi+>, HH and VV have equal Z parity.
    let zz_correlation =
        probabilities[0]
        - probabilities[1]
        - probabilities[2]
        + probabilities[3];

    // |Phi+> is also a +1 eigenstate of X⊗X.
    //
    // X⊗X swaps HH <-> VV and HV <-> VH.
    // The expectation is:
    //
    //   2 Re(a_HH* a_VV + a_HV* a_VH)
    //
    let xx_correlation =
        2.0 * (
            state[0].re * state[3].re
            + state[0].im * state[3].im
            + state[1].re * state[2].re
            + state[1].im * state[2].im
        );

    let result = BellResult {
        p_hh: probabilities[0],
        p_hv: probabilities[1],
        p_vh: probabilities[2],
        p_vv: probabilities[3],
        normalization,
        zz_correlation,
        xx_correlation,
    };

    Attested::new(
        "Bell state |Phi+> state-vector calculation",
        result,
        provenance,
    )
}

// ===========================================================================
// 12. DEMONSTRATION-ONLY FINGERPRINT
// ===========================================================================
//
// FNV-1a is used solely because it is tiny enough to include transparently in
// one dependency-free file.
//
// It detects ordinary accidental differences reasonably well.
//
// It DOES NOT provide:
//
//   * collision resistance appropriate for security,
//   * authenticity,
//   * non-repudiation,
//   * machine identity,
//   * or tamper-proof provenance.
//
// Never describe this field as a cryptographic signature.

fn fnv1a64(bytes: &[u8]) -> u64 {
    const OFFSET_BASIS: u64 = 0xcbf29ce484222325;
    const PRIME: u64 = 0x100000001b3;

    let mut hash = OFFSET_BASIS;

    for byte in bytes {
        hash ^= u64::from(*byte);
        hash = hash.wrapping_mul(PRIME);
    }

    hash
}

// ===========================================================================
// 13. HUMAN-READABLE HELPERS
// ===========================================================================

fn occupation_string(occupation: &[usize]) -> String {
    occupation
        .iter()
        .map(usize::to_string)
        .collect::<Vec<_>>()
        .join(",")
}

fn indent(text: &str, spaces: usize) -> String {
    let prefix = " ".repeat(spaces);

    text.lines()
        .map(|line| format!("{prefix}{line}"))
        .collect::<Vec<_>>()
        .join("\n")
}

// ===========================================================================
// 14. ONE PROVENANCE RECORD PER EXECUTION CLASS
// ===========================================================================
//
// In a larger system the provenance record would be constructed from actual
// runtime observations.
//
// Here we state exactly what this file can honestly know.

fn local_simulation_provenance() -> Provenance {
    Provenance {
        evidence: EvidenceKind::Simulation {
            simulator:
                "standalone Rust linear-optics prototype".into(),

            method:
                "deterministic state-vector/permanent calculation".into(),
        },

        implementation:
            concat!(
                "this single Rust source file; ",
                "standard library only; NOT Perceval"
            )
            .into(),

        compute:
            concat!(
                "local host executing this binary; ",
                "no external quantum service invoked"
            )
            .into(),

        cost:
            "no metered cloud/QPU charge recorded by this program".into(),

        deterministic: true,

        exclusions: vec![
            "not a Quandela QPU execution".into(),
            "not an OVHcloud QPU execution".into(),
            "not Perceval".into(),
            "not experimental detector data".into(),
            "not cryptographically signed".into(),
        ],
    }
}

// ===========================================================================
// 15. COMPRESSION AS AN EXPLICITLY LOSSY OPERATION
// ===========================================================================
//
// Here is the philosophical argument in code.
//
// Suppose someone wants a convenient dashboard and reduces the full record to:
//
//     experiment + result
//
// That object is smaller and still looks useful.
//
// But it cannot answer:
//
//     Was this hardware?
//     Which simulator?
//     Which backend?
//     Was it deterministic?
//     What was explicitly excluded?
//
// The bytes were saved.
//
// The ability to warrant later claims was lost.

#[derive(Debug)]
struct CompressedResult {
    experiment: String,
    result_text: String,
}

fn dangerously_compress<T: fmt::Display>(
    attested: &Attested<T>,
) -> CompressedResult {
    CompressedResult {
        experiment: attested.experiment.clone(),
        result_text: attested.result.to_string(),
    }
}

// ===========================================================================
// 16. MAIN
// ===========================================================================

fn main() {
    println!("ATTESTAL PHOTONIC — STRUCTURAL HONESTY PROTOTYPE");
    println!("================================================\n");

    let provenance = local_simulation_provenance();

    let hom = hong_ou_mandel(provenance.clone());

    let boson =
        three_mode_boson_sampling(provenance.clone());

    let bell = bell_state(provenance);

    println!("EXPERIMENT 01\n-------------");
    println!("{}", hom.public_record());
    println!();

    println!("EXPERIMENT 02\n-------------");
    println!("{}", boson.public_record());
    println!();

    println!("EXPERIMENT 03\n-------------");
    println!("{}", bell.public_record());
    println!();

    // ----------------------------------------------------------------------
    // THE CRUCIAL TEST
    // ----------------------------------------------------------------------
    //
    // Imagine downstream presentation code attempting to turn a successful
    // simulation into the more impressive statement:
    //
    //     "verified on real photonic hardware"
    //
    // The numerical values themselves cannot prevent that.
    //
    // Retained provenance can.

    println!("OVERCLAIM TEST");
    println!("--------------");

    match hom.require_hardware() {
        Ok(()) => {
            println!(
                "hardware claim permitted by provenance"
            );
        }

        Err(error) => {
            println!("{error}");
        }
    }

    println!();

    // ----------------------------------------------------------------------
    // THE COMPRESSION–REPAIR TRADEOFF
    // ----------------------------------------------------------------------

    println!("LOSSY COMPRESSION DEMONSTRATION");
    println!("-------------------------------");

    let compressed = dangerously_compress(&hom);

    println!("experiment: {}", compressed.experiment);
    println!(
        "retained result:\n{}",
        indent(&compressed.result_text, 2)
    );

    println!();
    println!(
        "After compression, ask: was this a QPU execution?"
    );

    println!(
        "Answer from compressed object: UNKNOWN."
    );

    println!(
        "Answer from retained provenance: {}.",
        hom.provenance.evidence
    );

    println!();

    println!(
        "The numerical result survived compression."
    );

    println!(
        "The warrant for interpreting that result did not."
    );

    println!();

    println!(
        "Compression saved representation; \
         provenance retention saved repair."
    );
}