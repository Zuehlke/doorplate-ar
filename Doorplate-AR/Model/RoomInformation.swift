//
//  RoomInformation.swift
//  Doorplate-AR
//
//  Created by Robin Wiegand on 03.05.18.
//  Copyright © 2018 Jonas Wisplinghoff. All rights reserved.
//

import Foundation

class RoomInformation{
    
    static let validRooms: [String] = ["bolgheri", "brunello", "chianti", "elba", "monte", "caldara", "leonardo", "michelangelo", "paganini", "verdi", "vivaldi", "bellini", "dante", "giotto", "parma", "rossini", "sienna", "tuna", "donatello", "puccini", "raffaello", "serra"]
    
    static func getTopicTeamsByRoom(roomName: String) -> String {
        switch roomName {
        case "bolgheri":
            return "BLOX, WEB"
        case "brunello":
            return "EMX, QTQML"
        case "chianti":
            return "AZURE, APRG, DEVOPS, SEC"
        case "elba":
            return "IoTE, AR"
        case "monte":
            return "DSC"
        case "caldara":
            return "BLOX, MTMC, SEC, OM"
        case "leonardo":
            return "SERVICES"
        case "michelangelo":
            return "SERVICES"
        case "paganini":
            return "Marktteam Konsümgüter; PTA; BD"
        case "verdi":
            return "LADD, Filmteam, TLP Lagerfeuer"
        case "vivaldi":
            return "ZUX, COP, CRAFT"
        case "bellini":
            return "PMP"
        case "dante":
            return "ATS, BIT"
        case "giotto":
            return "Lagerfeuer, HR"
        case "parma":
            return "SERVICES"
        case "rossini":
            return "EMP"
        case "sienna":
            return "MCPP, TLP"
        case "tuna":
            return "CRAFT"
        case "donatello":
            return "EWI, EEP"
        case "puccini":
            return "AIS, Sandbox"
        case "raffaello":
            return "SRP, PTT"
        case "serra":
            return "PROJEKT"
        default:
            return "No topic found"
        }
    }
    
}
