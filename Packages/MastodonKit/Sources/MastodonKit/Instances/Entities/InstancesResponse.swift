//
//  InstancesRespones.swift
//  MastodonKit
//
//  Created by Nikita Prokhorchuk on 7.12.24.
//

import Foundation

struct InstancesResponse: Decodable {
    
    let instances: [Instance]
}
