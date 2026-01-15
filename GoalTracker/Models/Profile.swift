//
//  Profile.swift
//  GoalTracker
//
//  Created by Joshua Browning on 1/14/26.
//

import Foundation

struct Profile: Codable, Identifiable {
    let id: UUID
    var username: String
    var password: String
    var fullName: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case password
        case fullName = "Joshua Browning"
    }
}
