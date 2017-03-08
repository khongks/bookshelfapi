//
//  DeleteBookHandler.swift
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


func deleteBookHandler(request: RouterRequest, response: RouterResponse, next: ()->Void) -> Void {
    guard let id: String = request.parameters["id"] else {
        response.status(.notFound).send(json: JSON(["error": "Not Found"]))
        next()
        return
    }
    Log.info("Handling /books/\(id)")
    
    do {
        
        let book = try booksMapper.removeBook(withId: id)
        var json = book.toJSON()
        
        let baseURL = "http://" + (request.headers["Host"] ?? "localhost:8090")
        let links = JSON(["self": baseURL + "/books/" + book.id])
        json["_links"] = links
        
        response.status(.OK).send(json: json)
    } catch BooksMapper.RetrieveError.NotFound {
        response.status(.notFound).send(json: JSON(["error": "Not found"]))
    } catch {
        response.status(.internalServerError).send(json: JSON(["error": "Could not service request"]))
    }
    next()
}
