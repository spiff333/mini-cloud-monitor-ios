//
//  AwsHelper.swift
//  minicloudmonitor
//
//  Created by Marc Plassmeier on 6/3/17.
//  Copyright © 2017 Marc Plassmeier. All rights reserved.
//

import AWSIoT



// why doesn't this work?
protocol CaseCountable: RawRepresentable {}
extension CaseCountable where RawValue == Int {
    static var count: RawValue {
        var i: RawValue = 0
        while let _ = Self(rawValue: i) { i += 1 }
        return i
    }
}

extension AWSRegionType : CaseCountable {
    var description: String {
        return String(reflecting: self)
    }
}


var awsRegions: [AWSRegionType: String] = [
    .Unknown: "Unknown",
    .USEast1: "US-East-1",
    .USEast2: "US-East-2",
    .USWest1: "US-West-1",
    .USWest2: "US-West-2",
    .EUWest1: "EU-West-1",
    .EUWest2: "EU-West-2",
    .EUCentral1: "EU-Central-1",
    .APSoutheast1: "AP-Southeast-1",
    .APNortheast1: "AP-Northeast-1",
    .APNortheast2: "AP-Northeast-2",
    .APSoutheast2: "AP-Southeast-2",
    .APSouth1: "AP-South-1",
    .SAEast1: "SA-East-1",
    .CNNorth1: "CN-North-1",
    .CACentral1: "CA-Central-1",
    .USGovWest1: "US-GovWest-1"
]

