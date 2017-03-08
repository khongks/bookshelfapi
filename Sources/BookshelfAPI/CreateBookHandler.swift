//
//  CreateBookHandler.swift
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

func createBookHandler(request: RouterRequest, response: RouterResponse, next: ()->Void) -> Void {
    Log.info("Handling a post to /books")
    
    guard let body = request.body else {
        response.status(.badRequest)
        Log.error("No body found in request")
        return
    }
    
    guard case let .json(jsonData) = body else {
        response.status(.badRequest)
        Log.error("Body contains invalid JSON")
        return
    }
    
    let contentType = request.headers["Content-Type"] ?? ""    
    guard contentType.hasPrefix("application/json") else {
        response.status(.badRequest).send(json: JSON(["error": "Invalid data"]))
        next()
        return
    }
    
    do {
        let book = try booksMapper.insertBook(json: jsonData)
        
        var json = book.toJSON()
        
        let baseURL = "http://" + (request.headers["Host"] ?? "localhost:8090")
        let links = JSON(["self": baseURL + "/books/" + book.id])
        json["_links"] = links
        
        response.status(.OK).send(json: json)
        response.headers["Content-Type"] = "applicaion/hal+json"
    } catch BooksMapper.RetrieveError.Invalid(let message) {
        response.status(.badRequest).send(json: JSON(["error": message]))
    } catch {
        response.status(.internalServerError).send(json: JSON(["error": "Could not service request"]))
    }
    
    next()
}
