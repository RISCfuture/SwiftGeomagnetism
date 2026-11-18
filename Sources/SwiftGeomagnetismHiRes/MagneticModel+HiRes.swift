internal import Foundation
public import SwiftGeomagnetism

extension MagneticModel {
  /**
   World Magnetic Model High Resolution 2025 (degree 133), valid from 2025.0 through 2029.

   Degrees 1–15 describe the core field and its secular variation. Degrees 16–133 add the static
   crustal field, resolving features down to about 300 km.
   */
  public static let wmmHiRes2025 = bundled(resource: "WMMHR2025", in: .module)
}
