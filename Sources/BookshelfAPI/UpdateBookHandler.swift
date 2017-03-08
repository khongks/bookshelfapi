//
//  UpdateBookHandler.swift
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


func updateBookHandler(request: RouterRequest, response: RouterResponse, next: ()->Void) -> Void {
    Log.info("Handling a put to /books")
    
    guard let id: String = request.parameters["id"] else {
        response.status(.notFound).send(json: JSON(["error": "Not Found"]))
        next()
        return
    }
    
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
    
    //let title = jsonData["title"].stringValue
    //let author = jsonData["author"].stringValue
    let contentType = request.headers["Content-Type"] ?? ""
    
    guard contentType.hasPrefix("application/json") else {
        response.status(.badRequest).send(json: JSON(["error": "Invalid data"]))
        next()
        return
    }
    
    do {
        let book = try booksMapper.updateBook(withId: id, json: jsonData)
        var json = book.toJSON()
        
        let baseURL = "http://" + (request.headers["Host"] ?? "localhost:8090")
        let links = JSON(["self": baseURL + "/books/" + book.id])
        json["_links"] = links
        
        response.status(.OK).send(json: json)
    } catch BooksMapper.UpdateError.NotFound {
        response.status(.notFound).send(json: JSON(["error": "Not found"]))
    } catch {
        response.status(.internalServerError).send(json: JSON(["error": "Could not service request"]))
    }
    next()
}
