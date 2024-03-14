## Gauge fixing

- cgpt gauge fixing function is in lib/cgpt/lib/gauge_fix.cc
    - "err_on_no_converge" controls whether to throw an error if the gauge fixing does not converge
    - "alpha" is the initial step size

- The corresponding gpt function gauge_fix is in lib/gpt/core/transform.py;

- Added Coulomb gauge fixing function in the folder lib/gpt/qcd/gauge/fix;