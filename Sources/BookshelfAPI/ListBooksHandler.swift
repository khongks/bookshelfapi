//
//  ListBooksHandler.swift
//  BookshelfAPI
//
//  Created by khongks on 7/3/17.
//
//

import Foundation
import CouchDB
import Kitura
import LoggerAPI
import SwiftyJSON

func listBooksHandler(request: RouterRequest, response: RouterResponse, next: ()->Void) -> Void {
    Log.info("Handling /books")
    if let books = booksMapper.fetchAll() {
        var json = JSON([:])
        
        let baseURL = "http://" + (request.headers["Host"] ?? "localhost:8090")
        Log.info("Handling /books baseURL=\(baseURL)")
        let links = JSON(["self": baseURL + "/books"])
        json["_links"] = links
        
        //json["books"] = JSON(books.map { $0.toJSON() })
        json["_embedded"] = JSON(books.map {
            var book = $0.toJSON()
            book["_links"] = JSON(["self": baseURL + "/books/" + $0.id])
            return book
        })
        json["count"].int = books.count
        
        response.headers["Content-Type"] = "application/hal+json"
        response.status(.OK).send(json: json)
    } else {
        response.status(.internalServerError).send(json: JSON(["error": "Could not service request"]))
    }
    next()
}
