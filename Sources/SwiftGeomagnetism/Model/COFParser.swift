internal import Foundation

/// The contents of a coefficient (COF) file in NOAA's WMM format.
struct COFContents {
  let epoch: Double
  let name: String
  let releaseDate: Date
  let coefficients: SphericalHarmonicCoefficients
}

/**
 Parses NOAA's WMM coefficient-file format: a header line of epoch, model name, and release date,
 then one `n m g h ġ ḣ` line per degree and order, then a line of 9s. Any maximum degree is
 accepted, provided every degree and order up to it appears exactly once.
 */
enum COFParser {
  private static let headerFieldCount = 3,
    coefficientFieldCount = 6,
    releaseDateFieldCount = 3

  private static let utcGregorian: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .gmt
    return calendar
  }()

  static func parse(_ text: String) throws(COFParseError) -> COFContents {
    var lines = numberedLines(of: text).makeIterator()
    guard let header = lines.next() else { throw .malformedHeader("") }
    let (epoch, name, releaseDate) = try parseHeader(header.line)

    var entries: [CoefficientEntry] = []
    var terminated = false
    while let next = lines.next() {
      if isTerminator(next.line) {
        terminated = true
        break
      }
      entries.append(try parseCoefficientLine(next.line, lineNumber: next.lineNumber))
    }
    guard terminated else { throw .missingTerminator }

    return COFContents(
      epoch: epoch,
      name: name,
      releaseDate: releaseDate,
      coefficients: try assemble(entries)
    )
  }

  private static func numberedLines(of text: String) -> [(lineNumber: UInt, line: Substring)] {
    text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
      .enumerated()
      .map {
        (UInt($0.offset + 1), $0.element.trimmingCharacters(in: .whitespacesAndNewlines)[...])
      }
      .filter { !$0.line.isEmpty }
  }

  private static func fields(of line: Substring) -> [Substring] {
    line.split(whereSeparator: \.isWhitespace)
  }

  private static func isTerminator(_ line: Substring) -> Bool {
    line.allSatisfy { $0 == "9" }
  }

  private static func parseHeader(
    _ line: Substring
  ) throws(COFParseError) -> (epoch: Double, name: String, releaseDate: Date) {
    let fields = fields(of: line)
    guard fields.count == headerFieldCount,
      let epoch = Double(fields[0]), epoch.isFinite,
      let releaseDate = parseReleaseDate(fields[2])
    else { throw .malformedHeader(String(line)) }
    return (epoch, String(fields[1]), releaseDate)
  }

  private static func parseReleaseDate(_ field: Substring) -> Date? {
    let parts = field.split(separator: "/", omittingEmptySubsequences: false).map { Int($0) }
    guard parts.count == releaseDateFieldCount,
      let month = parts[0], let day = parts[1], let year = parts[2]
    else { return nil }

    let components = DateComponents(
      calendar: utcGregorian,
      timeZone: .gmt,
      year: year,
      month: month,
      day: day
    )
    guard components.isValidDate else { return nil }
    return components.date
  }

  private static func parseCoefficientLine(
    _ line: Substring,
    lineNumber: UInt
  ) throws(COFParseError) -> CoefficientEntry {
    let fields = fields(of: line)
    guard fields.count == coefficientFieldCount,
      let n = Int(fields[0]), let m = Int(fields[1])
    else { throw .malformedCoefficientLine(lineNumber: lineNumber, line: String(line)) }

    let values = fields[2...].compactMap { Double($0) }.filter(\.isFinite)
    guard values.count == coefficientFieldCount - 2 else {
      throw .malformedCoefficientLine(lineNumber: lineNumber, line: String(line))
    }
    guard n >= 1, (0...n).contains(m) else {
      throw .invalidDegreeOrOrder(lineNumber: lineNumber, degree: n, order: m)
    }
    return CoefficientEntry(
      lineNumber: lineNumber,
      n: n,
      m: m,
      g: values[0],
      h: values[1],
      ġ: values[2],
      ḣ: values[3]
    )
  }

  private static func assemble(
    _ entries: [CoefficientEntry]
  ) throws(COFParseError) -> SphericalHarmonicCoefficients {
    guard let maximumDegree = entries.map(\.n).max() else {
      throw .missingCoefficient(degree: 1, order: 0)
    }

    let count = SphericalHarmonicCoefficients.count(maximumDegree: maximumDegree)
    var g = [Double](repeating: 0, count: count),
      h = g,
      ġ = g,
      ḣ = g,
      isPresent = [Bool](repeating: false, count: count)

    for entry in entries {
      let index = SphericalHarmonicCoefficients.index(degree: entry.n, order: entry.m)
      guard !isPresent[index] else {
        throw .duplicateCoefficient(lineNumber: entry.lineNumber, degree: entry.n, order: entry.m)
      }
      isPresent[index] = true
      (g[index], h[index], ġ[index], ḣ[index]) = (entry.g, entry.h, entry.ġ, entry.ḣ)
    }

    try requireEveryTerm(isPresent, maximumDegree: maximumDegree)
    return SphericalHarmonicCoefficients(maximumDegree: maximumDegree, g: g, h: h, ġ: ġ, ḣ: ḣ)
  }

  private static func requireEveryTerm(
    _ isPresent: [Bool],
    maximumDegree: Int
  ) throws(COFParseError) {
    for n in 1...maximumDegree {
      for m in 0...n where !isPresent[SphericalHarmonicCoefficients.index(degree: n, order: m)] {
        throw .missingCoefficient(degree: n, order: m)
      }
    }
  }
}

/// One parsed `n m g h ġ ḣ` line.
private struct CoefficientEntry {
  let lineNumber: UInt
  let n: Int  // degree
  let m: Int  // order
  let g: Double  // Gauss coefficient gₙᵐ at the epoch (nT)
  let h: Double  // Gauss coefficient hₙᵐ at the epoch (nT)
  let ġ: Double  // secular variation of gₙᵐ (nT/yr)
  let ḣ: Double  // secular variation of hₙᵐ (nT/yr)
}
