# ``SwiftGeomagnetismHiRes``

@Metadata {
    @DisplayName("SwiftGeomagnetismHiRes")
}

The degree-133 World Magnetic Model High Resolution, WMMHR2025.

## Overview

This library adds `MagneticModel.wmmHiRes2025` to SwiftGeomagnetism. It extends the World
Magnetic Model's core field (degrees 1–15) with Earth's crustal field (degrees 16–133), which
resolves features down to about 300 km.

```swift
import SwiftGeomagnetism
import SwiftGeomagnetismHiRes

let field = try MagneticModel.wmmHiRes2025.field(latitude: 37.62, longitude: -122.38)
```

Its coefficient file is about 530 KB, and evaluating it takes about 50 times as long as the
standard model. Apps that link only `SwiftGeomagnetism` don't bundle it.
