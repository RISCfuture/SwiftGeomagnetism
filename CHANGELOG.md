# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-11-18

### Added

- Initial release of SwiftGeomagnetism
- `MagneticModel.wmm2025`, the World Magnetic Model 2025, bundled as a resource
- Loading of any NOAA-format coefficient (COF) file, of any degree, from a URL or text
- The `SwiftGeomagnetismHiRes` library with `MagneticModel.wmmHiRes2025`, the degree-133 WMMHR2025
- Field components, declination, inclination, polar grid variation, and secular variation
- Foundation `Measurement` arguments and results, including `UnitMagneticFluxDensity`
- A `CLLocation` convenience on Apple platforms
- Linux support
